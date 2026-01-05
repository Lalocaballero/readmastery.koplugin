local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")
local logger = require("logger")
local json = require("json")

local ReadMasteryCore = {
    data = nil,
    data_file = nil,
}

function ReadMasteryCore:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    
    o.data_file = o.data_dir .. "/readmastery_data.json"
    o.data = o:getDefaultData()
    
    return o
end

function ReadMasteryCore:getDefaultData()
    return {
        -- Core stats
        xp = 0,
        level = 1,
        lifetime_pages = 0,
        books_completed = 0,
        books_started = {},
        
        -- Streak data
        current_streak = 0,
        longest_streak = 0,
        last_active_date = nil,
        freeze_tokens = 0,
        
        -- Daily tracking
        daily_pages = {},
        daily_reading_time = {},
        
        -- Session history
        sessions = {},
        
        -- Achievements with counts and tiers
        achievements = {},
        
        -- Format tracking
        formats_read = {},
        
        -- Records
        most_pages_single_day = 0,
        
        -- Settings
        sandbox_mode = false,
        debug_mode = false,
        
        -- Overlay settings
        show_overlay = false,
        overlay_position = "top_right",
        overlay_format = "streak_level",
        
        -- Title bar settings
        tb_display_format = "streak_level",
        
        -- Timestamps
        created_at = os.time(),
        updated_at = os.time(),
    }
end

function ReadMasteryCore:load()
    local file = io.open(self.data_file, "r")
    if file then
        local content = file:read("*all")
        file:close()
        
        local decoded = json.decode(content)
        if decoded then
            -- Merge with defaults to handle new fields
            for k, v in pairs(self:getDefaultData()) do
                if decoded[k] == nil then
                    decoded[k] = v
                end
            end
            self.data = decoded
            
            -- Migrate old achievement format to new format with counts
            self:migrateAchievements()
            
            logger.dbg("ReadMastery: Data loaded successfully")
        end
    else
        logger.dbg("ReadMastery: No existing data, using defaults")
    end
end

-- Migrate old achievement format (just unlocked_at) to new format (with count and tier)
function ReadMasteryCore:migrateAchievements()
    for id, data in pairs(self.data.achievements) do
        if type(data) == "table" then
            -- Check if it's old format (only has unlocked_at)
            if data.unlocked_at and not data.count then
                self.data.achievements[id] = {
                    unlocked_at = data.unlocked_at,
                    count = 1,
                    tier = "bronze",
                }
                logger.dbg("ReadMastery: Migrated achievement", id, "to new format")
            end
        end
    end
end

function ReadMasteryCore:save()
    self.data.updated_at = os.time()
    
    local file = io.open(self.data_file, "w")
    if file then
        file:write(json.encode(self.data))
        file:close()
        logger.dbg("ReadMastery: Data saved")
    else
        logger.err("ReadMastery: Failed to save data")
    end
end

function ReadMasteryCore:reset()
    self.data = self:getDefaultData()
    self:save()
end

-- XP and Level Methods
function ReadMasteryCore:addXP(amount, source)
    self.data.xp = self.data.xp + amount
    self:updateLevel()
    logger.dbg("ReadMastery: Added", amount, "XP from", source)
end

function ReadMasteryCore:getXP()
    return self.data.xp
end

function ReadMasteryCore:getLevel()
    return self.data.level
end

function ReadMasteryCore:updateLevel()
    local new_level = self:calculateLevelFromXP(self.data.xp)
    self.data.level = new_level
end

function ReadMasteryCore:calculateLevelFromXP(xp)
    local level = 1
    local xp_needed = 0
    
    while xp >= xp_needed do
        level = level + 1
        xp_needed = xp_needed + (level * 50) + ((level - 1) * 25)
    end
    
    return level - 1
end

function ReadMasteryCore:getXPForNextLevel()
    local current_level = self.data.level
    local xp_for_current = self:getXPRequiredForLevel(current_level)
    local xp_for_next = self:getXPRequiredForLevel(current_level + 1)
    
    return {
        current = self.data.xp - xp_for_current,
        needed = xp_for_next - xp_for_current,
        total = self.data.xp,
    }
end

function ReadMasteryCore:getXPRequiredForLevel(level)
    local xp = 0
    for l = 2, level do
        xp = xp + (l * 50) + ((l - 1) * 25)
    end
    return xp
end

-- Lifetime Pages
function ReadMasteryCore:addLifetimePages(pages)
    self.data.lifetime_pages = self.data.lifetime_pages + pages
end

function ReadMasteryCore:getLifetimePages()
    return self.data.lifetime_pages
end

-- Daily Pages
function ReadMasteryCore:addDailyPages(pages)
    local today = os.date("%Y-%m-%d")
    self.data.daily_pages[today] = (self.data.daily_pages[today] or 0) + pages
    
    if self.data.daily_pages[today] > self.data.most_pages_single_day then
        self.data.most_pages_single_day = self.data.daily_pages[today]
    end
end

function ReadMasteryCore:getDailyPages(date)
    date = date or os.date("%Y-%m-%d")
    return self.data.daily_pages[date] or 0
end

function ReadMasteryCore:getWeeklyPages()
    local total = 0
    local active_days = 0
    
    for i = 0, 6 do
        local date = os.date("%Y-%m-%d", os.time() - (i * 86400))
        local pages = self.data.daily_pages[date] or 0
        total = total + pages
        if pages > 0 then
            active_days = active_days + 1
        end
    end
    
    return total, active_days
end

-- Sessions
function ReadMasteryCore:recordSession(session_data)
    table.insert(self.data.sessions, session_data)
    
    while #self.data.sessions > 100 do
        table.remove(self.data.sessions, 1)
    end
end

function ReadMasteryCore:getLastSession()
    return self.data.sessions[#self.data.sessions]
end

-- Formats
function ReadMasteryCore:addFormat(format)
    if not self.data.formats_read[format] then
        self.data.formats_read[format] = true
    end
end

function ReadMasteryCore:getFormatCount()
    local count = 0
    for _ in pairs(self.data.formats_read) do
        count = count + 1
    end
    return count
end

-- Books
function ReadMasteryCore:trackBookStarted(book_path)
    if not self.data.books_started[book_path] then
        self.data.books_started[book_path] = {
            started_at = os.time(),
            completed = false,
        }
    end
end

function ReadMasteryCore:incrementBooksCompleted()
    self.data.books_completed = self.data.books_completed + 1
end

function ReadMasteryCore:getBooksStarted()
    local count = 0
    for _ in pairs(self.data.books_started) do
        count = count + 1
    end
    return count
end

function ReadMasteryCore:getBooksCompleted()
    return self.data.books_completed
end

-- Achievement Methods (Updated for Tiers)
function ReadMasteryCore:isAchievementUnlocked(id)
    return self.data.achievements[id] ~= nil
end

function ReadMasteryCore:getAchievementData(id)
    return self.data.achievements[id]
end

function ReadMasteryCore:getAchievementCount(id)
    if self.data.achievements[id] then
        return self.data.achievements[id].count or 1
    end
    return 0
end

function ReadMasteryCore:getAchievementTier(id)
    if self.data.achievements[id] then
        return self.data.achievements[id].tier or "bronze"
    end
    return nil
end

function ReadMasteryCore:unlockAchievement(id)
    if not self.data.achievements[id] then
        self.data.achievements[id] = {
            unlocked_at = os.time(),
            count = 1,
            tier = "bronze",
        }
        return true
    end
    return false
end

function ReadMasteryCore:incrementAchievementCount(id)
    if self.data.achievements[id] then
        self.data.achievements[id].count = (self.data.achievements[id].count or 1) + 1
        return self.data.achievements[id].count
    end
    return 0
end

function ReadMasteryCore:setAchievementTier(id, tier)
    if self.data.achievements[id] then
        self.data.achievements[id].tier = tier
        return true
    end
    return false
end

function ReadMasteryCore:getUnlockedAchievements()
    return self.data.achievements
end

-- Streaks
function ReadMasteryCore:getStreak()
    return self.data.current_streak
end

function ReadMasteryCore:getLongestStreak()
    return self.data.longest_streak
end

function ReadMasteryCore:setStreak(value)
    self.data.current_streak = value
    if value > self.data.longest_streak then
        self.data.longest_streak = value
    end
end

function ReadMasteryCore:getFreezeTokens()
    return self.data.freeze_tokens
end

function ReadMasteryCore:addFreezeToken()
    self.data.freeze_tokens = self.data.freeze_tokens + 1
end

function ReadMasteryCore:useFreezeToken()
    if self.data.freeze_tokens > 0 then
        self.data.freeze_tokens = self.data.freeze_tokens - 1
        return true
    end
    return false
end

function ReadMasteryCore:getLastActiveDate()
    return self.data.last_active_date
end

function ReadMasteryCore:setLastActiveDate(date)
    self.data.last_active_date = date
end

-- Feature access check
function ReadMasteryCore:canAccessFeature(required_level)
    if self.data.sandbox_mode then
        return true
    end
    return self.data.level >= required_level
end

function ReadMasteryCore:isDebugMode()
    return self.data.debug_mode or false
end

function ReadMasteryCore:isSandboxMode()
    return self.data.sandbox_mode or false
end

return ReadMasteryCore