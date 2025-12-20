local InfoMessage = require("ui/widget/infomessage")
local MultiConfirmBox = require("ui/widget/multiconfirmbox")
local UIManager = require("ui/uimanager")
local _ = require("gettext")
local T = require("ffi/util").template

local Icons = require("icons")
local StatsView = require("ui/statsview")
local AchievementsView = require("ui/achievements_view")

local MainMenu = {}

function MainMenu:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function MainMenu:getMenuTable()
    return {
        {
            text = "View Stats",
            callback = function()
                self:showStats()
            end,
        },
        {
            text = "Achievements",
            callback = function()
                self:showAchievements()
            end,
        },
        {
            text = "Streak Info",
            callback = function()
                self:showStreakInfo()
            end,
        },
        {
            text = "Analytics",
            sub_item_table = self:getAnalyticsMenu(),
        },
        {
            text = "Settings",
            sub_item_table = self:getSettingsMenu(),
        },
    }
end

function MainMenu:showStats()
    local stats_view = StatsView:new{ plugin = self.plugin }
    stats_view:show()
end

function MainMenu:showAchievements()
    local achievements_view = AchievementsView:new{ plugin = self.plugin }
    achievements_view:show()
end

function MainMenu:showStreakInfo()
    local streak_info = self.plugin.streak_manager:getStreakInfo()
    local xp_info = self.plugin.core:getXPForNextLevel()
    
    local text = [[
====== STREAK INFO ======

Current Streak: ]] .. streak_info.current .. [[ days
Longest Streak: ]] .. streak_info.longest .. [[ days
Freeze Tokens:  ]] .. streak_info.freeze_tokens .. [[


======= PROGRESS ========

Level:          ]] .. self.plugin.core:getLevel() .. [[

XP:             ]] .. xp_info.current .. [[ / ]] .. xp_info.needed .. [[

Lifetime Pages: ]] .. self.plugin.core:getLifetimePages()
    
    UIManager:show(InfoMessage:new{
        text = text,
        timeout = 10,
    })
end

function MainMenu:getAnalyticsMenu()
    local feature_unlocks = self.plugin.feature_unlocks
    
    return {
        {
            text = "Session Stats (Lv.3)",
            enabled_func = function()
                return feature_unlocks:isFeatureUnlocked("session_stats")
            end,
            callback = function()
                self:showSessionStats()
            end,
        },
        {
            text = "7-Day Heatmap (Lv.5)",
            enabled_func = function()
                return feature_unlocks:isFeatureUnlocked("heatmap")
            end,
            callback = function()
                self:showHeatmap()
            end,
        },
        {
            text = "Weekly Digest (Lv.7)",
            enabled_func = function()
                return feature_unlocks:isFeatureUnlocked("weekly_digest")
            end,
            callback = function()
                self:showWeeklyDigest()
            end,
        },
        {
            text = "Speed Analytics (Lv.10)",
            enabled_func = function()
                return feature_unlocks:isFeatureUnlocked("speed_analytics")
            end,
            callback = function()
                self:showSpeedAnalytics()
            end,
        },
        {
            text = "Completion Rate (Lv.15)",
            enabled_func = function()
                return feature_unlocks:isFeatureUnlocked("completion_rate")
            end,
            callback = function()
                self:showCompletionRate()
            end,
        },
        {
            text = "Hall of Fame (Lv.20)",
            enabled_func = function()
                return feature_unlocks:isFeatureUnlocked("hall_of_fame")
            end,
            callback = function()
                self:showHallOfFame()
            end,
        },
    }
end

function MainMenu:showSessionStats()
    local stats = self.plugin.analytics:getSessionStats(self.plugin.session)
    
    if not stats then
        UIManager:show(InfoMessage:new{
            text = "No active reading session.\n\nOpen a book to start tracking!",
            timeout = 3,
        })
        return
    end
    
    local text = [[
===== SESSION STATS =====

Book:     ]] .. (stats.book or "Unknown") .. [[

Format:   ]] .. (stats.format or "Unknown") .. [[

Duration: ]] .. stats.duration_formatted .. [[

Pages:    ]] .. stats.pages_read .. [[

Speed:    ]] .. stats.pages_per_hour .. [[ pages/hour
]]
    
    UIManager:show(InfoMessage:new{
        text = text,
        timeout = 10,
    })
end

function MainMenu:showHeatmap()
    local heatmap_text = self.plugin.analytics:renderHeatmapText()
    
    UIManager:show(InfoMessage:new{
        text = heatmap_text,
        timeout = 15,
    })
end

function MainMenu:showWeeklyDigest()
    local digest = self.plugin.analytics:getWeeklyDigest()
    
    local text = [[
===== WEEKLY DIGEST =====

Total Pages:    ]] .. digest.total_pages .. [[

Active Days:    ]] .. digest.active_days .. [[/7

Average:        ]] .. digest.average_pages_per_day .. [[ pages/day

-------------------------

Weekly Rank:    ]] .. digest.rank_icon .. [[

                ]] .. digest.rank .. [[

]]
    
    UIManager:show(InfoMessage:new{
        text = text,
        timeout = 10,
    })
end

function MainMenu:showSpeedAnalytics()
    local speed = self.plugin.analytics:getSpeedAnalytics()
    
    local text = [[
==== SPEED ANALYTICS ====

Total Sessions: ]] .. speed.total_sessions .. [[

Total Pages:    ]] .. speed.total_pages .. [[

Total Hours:    ]] .. speed.total_hours .. [[

Average Speed:  ]] .. speed.average_pages_per_hour .. [[ pages/hour

-------------------------

Reading Style:  ]] .. speed.style_icon .. [[

                ]] .. speed.style .. [[


]] .. speed.style_description .. [[

]]
    
    UIManager:show(InfoMessage:new{
        text = text,
        timeout = 10,
    })
end

function MainMenu:showCompletionRate()
    local completion = self.plugin.analytics:getCompletionRate()
    
    local text = [[
===== LIBRARY STATS =====

Books Started:   ]] .. completion.books_started .. [[

Books Completed: ]] .. completion.books_completed .. [[

Completion Rate: ]] .. completion.completion_percentage .. [[%

-------------------------

Rank: ]] .. completion.rank_icon .. [[

      ]] .. completion.rank .. [[

]]
    
    UIManager:show(InfoMessage:new{
        text = text,
        timeout = 10,
    })
end

function MainMenu:showHallOfFame()
    local fame = self.plugin.analytics:getHallOfFame()
    local unlocked, total = self.plugin.achievements:getUnlockedCount()
    
    local text = [[
====== HALL OF FAME ======

Level:              ]] .. fame.current_level .. [[

Total XP:           ]] .. fame.total_xp .. [[

Lifetime Pages:     ]] .. fame.lifetime_pages .. [[

Books Completed:    ]] .. fame.books_completed .. [[

Longest Streak:     ]] .. fame.longest_streak .. [[ days

Best Day (pages):   ]] .. fame.most_pages_single_day .. [[

Achievements:       ]] .. unlocked .. [[/]] .. total .. [[

--------------------------

Member Since: ]] .. fame.member_since .. [[

]]
    
    UIManager:show(InfoMessage:new{
        text = text,
        timeout = 15,
    })
end

function MainMenu:getSettingsMenu()
    return {
        {
            text_func = function()
                local status = self.plugin.core:isSandboxMode() and "ON" or "OFF"
                return "Sandbox Mode (" .. status .. ")"
            end,
            callback = function()
                self.plugin:toggleSandboxMode()
            end,
            keep_menu_open = true,
        },
        --{
        --    text_func = function()
        --       local status = self.plugin.core:isDebugMode() and "ON" or "OFF"
        --        return "Debug Mode (" .. status .. ")"
        --    end,
        --    callback = function()
        --        self.plugin:toggleDebugMode()
        --    end,
        --    keep_menu_open = true,
        --},
        --},
        {
            text = "Reset All Progress",
            callback = function()
                self:confirmReset()
            end,
        },
        {
            text = "About ReadMastery",
            callback = function()
                self:showAbout()
            end,
        },
    }
end

function MainMenu:confirmReset()
    UIManager:show(MultiConfirmBox:new{
        text = [[
Are you sure you want to reset
ALL ReadMastery progress?

This will delete:
- All XP and Levels
- All Achievements  
- All Streaks and Tokens
- All Statistics

This action cannot be undone!
]],
        choice1_text = "Cancel",
        choice1_callback = function() end,
        choice2_text = "Reset Everything",
        choice2_callback = function()
            self.plugin:resetProgress()
        end,
    })
end

function MainMenu:showAbout()
    local text = [[
======= READMASTERY =======
         v1.0

Gamify your reading with:

* XP for every page & minute
* Level up to unlock features  
* Daily streaks with freeze tokens
* 11 unique achievements

Keep reading, keep growing!

===========================
]]
    
    UIManager:show(InfoMessage:new{
        text = text,
        timeout = 15,
    })
end

return MainMenu