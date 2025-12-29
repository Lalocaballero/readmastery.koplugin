local DataStorage = require("datastorage")
local Dispatcher = require("dispatcher")
local Event = require("ui/event")
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local _ = require("gettext")
local T = require("ffi/util").template

local ReadMasteryCore = require("readmasterycore")
local XPEngine = require("xpengine")
local StreakManager = require("streakmanager")
local Achievements = require("achievements")
local Analytics = require("analytics")
local FeatureUnlocks = require("featureunlocks")
local MainMenu = require("ui/mainmenu")
local Notifications = require("ui/notifications")

local ReadMastery = WidgetContainer:extend{
    name = "readmastery",
    is_doc_only = false,
}

-- How long (in seconds) before we consider the user idle
local IDLE_TIMEOUT = 120  -- 2 minutes without page turn = idle

function ReadMastery:init()
    self.data_dir = DataStorage:getDataDir() .. "/readmastery"
    self:ensureDataDir()
    
    -- Initialize core systems
    self.core = ReadMasteryCore:new{
        data_dir = self.data_dir,
        plugin = self,
    }
    self.core:load()
    
    self.xp_engine = XPEngine:new{ core = self.core }
    self.streak_manager = StreakManager:new{ core = self.core }
    self.achievements = Achievements:new{ core = self.core, plugin = self }
    self.analytics = Analytics:new{ core = self.core }
    self.feature_unlocks = FeatureUnlocks:new{ core = self.core }
    self.notifications = Notifications:new{ plugin = self }
    self.main_menu = MainMenu:new{ plugin = self }
    
    -- Session tracking
    self.session = {
        start_time = nil,
        pages_read = 0,
        current_book = nil,
        current_format = nil,
        last_page = nil,
        is_active = false,
        -- NEW: Active reading tracking
        last_page_turn_time = nil,
        active_reading_seconds = 0,
        continuous_pages = 0,  -- Pages without long break
        continuous_start_time = nil,  -- When continuous reading started
    }
    
    -- Register menu
    self.ui.menu:registerToMainMenu(self)
    
    -- Check daily streak on init
    self.streak_manager:checkDailyStreak()
    
    logger.dbg("ReadMastery: Plugin initialized")
end

function ReadMastery:ensureDataDir()
    local lfs = require("libs/libkoreader-lfs")
    if lfs.attributes(self.data_dir, "mode") ~= "directory" then
        lfs.mkdir(self.data_dir)
    end
end

function ReadMastery:addToMainMenu(menu_items)
    menu_items.readmastery = {
        text = _("ReadMastery"),
        sorting_hint = "tools",
        sub_item_table = self.main_menu:getMenuTable(),
    }
end

-- Called when a document is opened
function ReadMastery:onReaderReady()
    self:startSession()
end

-- Called when document is closed
function ReadMastery:onCloseDocument()
    self:endSession()
end

function ReadMastery:startSession()
    if not self.ui.document then return end
    
    local props = self.ui.document:getProps()
    local file_path = self.ui.document.file
    local format = file_path:match("%.([^%.]+)$"):upper()
    
    local now = os.time()
    
    self.session = {
        start_time = now,
        pages_read = 0,
        current_book = props.title or file_path:match("([^/]+)$"),
        current_format = format,
        book_path = file_path,
        last_page = self.ui.document:getCurrentPage(),
        is_active = true,
        -- Active reading tracking
        last_page_turn_time = now,
        active_reading_seconds = 0,
        continuous_pages = 0,
        continuous_start_time = now,
    }
    
    -- Track format for Format Explorer achievement
    self.core:addFormat(format)
    
    -- Mark today as active reading day
    self.streak_manager:markTodayActive()
    
    logger.dbg("ReadMastery: Session started for", self.session.current_book)
end

function ReadMastery:endSession()
    if not self.session.is_active then return end
    
    -- Calculate final active reading time
    -- Add any remaining time since last page turn (up to IDLE_TIMEOUT)
    local now = os.time()
    if self.session.last_page_turn_time then
        local time_since_last_turn = now - self.session.last_page_turn_time
        if time_since_last_turn <= IDLE_TIMEOUT then
            self.session.active_reading_seconds = self.session.active_reading_seconds + time_since_last_turn
        end
    end
    
    local session_minutes = math.floor(self.session.active_reading_seconds / 60)
    
    -- Award time-based XP (only for ACTIVE reading time)
    local time_xp = self.xp_engine:calculateTimeXP(session_minutes)
    self.core:addXP(time_xp, "time")
    
    -- Update session stats
    self.core:recordSession({
        duration = self.session.active_reading_seconds,  -- Store active time, not total time
        pages = self.session.pages_read,
        book = self.session.current_book,
        format = self.session.current_format,
        date = os.date("%Y-%m-%d"),
    })
    
    -- Check session-based achievements with ACTIVE reading time
    self.achievements:checkSessionAchievements(self.session, self.session.active_reading_seconds)
    
    -- Check book completion
    if self.ui.document then
        local total_pages = self.ui.document:getPageCount()
        local current_page = self.ui.document:getCurrentPage()
        local completion = (current_page / total_pages) * 100
        
        if completion >= 95 then
            self.achievements:unlock("book_slayer")
            self.core:incrementBooksCompleted()
        end
        
        -- Track book started
        self.core:trackBookStarted(self.session.book_path)
    end
    
    -- Save all data
    self.core:save()
    
    self.session.is_active = false
    logger.dbg("ReadMastery: Session ended. Pages:", self.session.pages_read, 
               "Active Minutes:", session_minutes)
end

-- Called on every page turn
-- Maximum pages that count as "normal" reading
-- Anything above this is considered a jump (table of contents, random page, etc.)
local MAX_NORMAL_PAGE_JUMP = 5

-- Called on every page turn
function ReadMastery:onPageUpdate(page)
    if not self.session.is_active then return end
    
    local current_page = page or (self.ui.document and self.ui.document:getCurrentPage())
    if not current_page then return end
    
    local now = os.time()
    
    -- Track page turn
    if self.session.last_page and current_page ~= self.session.last_page then
        local pages_turned = math.abs(current_page - self.session.last_page)
        
        -- Check if this is a large jump (random page, TOC, bookmark, etc.)
        if pages_turned > MAX_NORMAL_PAGE_JUMP then
            -- Large jump detected - don't count pages, reset continuous reading
            logger.dbg("ReadMastery: Large page jump detected (", pages_turned, " pages) - not counting")
            self.session.last_page = current_page
            self.session.last_page_turn_time = now
            self.session.continuous_pages = 0
            self.session.continuous_start_time = now
            return
        end
        
        self.session.pages_read = self.session.pages_read + pages_turned
        
        -- Calculate active reading time since last page turn
        if self.session.last_page_turn_time then
            local time_since_last_turn = now - self.session.last_page_turn_time
            
            -- Only count time if within idle timeout (user was actively reading)
            if time_since_last_turn <= IDLE_TIMEOUT then
                self.session.active_reading_seconds = self.session.active_reading_seconds + time_since_last_turn
                
                -- Continue counting continuous pages
                self.session.continuous_pages = self.session.continuous_pages + pages_turned
            else
                -- User was idle - reset continuous reading
                self.session.continuous_pages = pages_turned
                self.session.continuous_start_time = now
            end
        else
            -- First page turn
            self.session.continuous_pages = pages_turned
            self.session.continuous_start_time = now
        end
        
        -- Update last page turn time
        self.session.last_page_turn_time = now
        
        -- Award page XP
        local page_xp = self.xp_engine:calculatePageXP(pages_turned)
        local old_level = self.core:getLevel()
        self.core:addXP(page_xp, "pages")
        
        -- Check for level up
        local new_level = self.core:getLevel()
        if new_level > old_level then
            self:onLevelUp(new_level)
        end
        
        -- Update lifetime pages
        self.core:addLifetimePages(pages_turned)
        
        -- Update daily pages for today
        self.core:addDailyPages(pages_turned)
        
        -- Check achievements
        self.achievements:checkAllAchievements()
        self:checkContinuousAchievements()
    end
    
    self.session.last_page = current_page
end

-- Check achievements that require continuous reading
function ReadMastery:checkContinuousAchievements()
    -- The Centurion: 100 pages in continuous reading
    if self.session.continuous_pages >= 100 then
        self.achievements:unlock("centurion")
    end
    
    -- Marathon: 3 hours of continuous active reading
    if self.session.continuous_start_time then
        local continuous_seconds = self.session.active_reading_seconds
        if continuous_seconds >= 10800 then  -- 3 hours
            self.achievements:unlock("marathon")
        end
    end
    
    -- Sprint: 50 pages in under 30 minutes of active reading
    if self.session.continuous_pages >= 50 then
        local continuous_time = os.time() - (self.session.continuous_start_time or os.time())
        if continuous_time <= 1800 then  -- 30 minutes
            self.achievements:unlock("sprint")
        end
    end
end

function ReadMastery:onLevelUp(new_level)
    -- Check for feature unlocks
    local unlocked_feature = self.feature_unlocks:checkUnlock(new_level)
    
    self.notifications:showLevelUp(new_level, unlocked_feature)
    
    logger.info("ReadMastery: Level up!", new_level)
end

function ReadMastery:onAchievementUnlocked(achievement_id, achievement_data)
    self.notifications:showAchievement(achievement_data)
    logger.info("ReadMastery: Achievement unlocked!", achievement_id)
end

-- Sandbox mode toggle
function ReadMastery:toggleSandboxMode()
    self.core.data.sandbox_mode = not self.core.data.sandbox_mode
    self.core:save()
    
    local status = self.core.data.sandbox_mode and _("enabled") or _("disabled")
    UIManager:show(InfoMessage:new{
        text = T(_("Sandbox Mode %1. All features temporarily %2."), 
                 status, 
                 self.core.data.sandbox_mode and _("unlocked") or _("locked to your level")),
        timeout = 3,
    })
end

-- Reset all progress
function ReadMastery:resetProgress()
    self.core:reset()
    UIManager:show(InfoMessage:new{
        text = _("All ReadMastery progress has been reset."),
        timeout = 3,
    })
end

-- Debug mode toggle
function ReadMastery:toggleDebugMode()
    self.core.data.debug_mode = not self.core.data.debug_mode
    self.core:save()
    
    local status = self.core.data.debug_mode and _("enabled") or _("disabled")
    UIManager:show(InfoMessage:new{
        text = T(_("Debug Mode %1."), status),
        timeout = 2,
    })
end

function ReadMastery:onTierUp(achievement_id, achievement, tier_info)
    self.notifications:showTierUp(achievement_id, achievement, tier_info)
    logger.info("ReadMastery: Tier up!", achievement_id, "->", tier_info.id)
end

return ReadMastery