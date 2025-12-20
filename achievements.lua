local logger = require("logger")
local _ = require("gettext")
local Icons = require("icons")

local Achievements = {}

-- Achievement Definitions
Achievements.DEFINITIONS = {
    -- Time & Habit Badges
    early_bird = {
        id = "early_bird",
        name = "Early Bird",
        description = "Read between 4:00 AM and 7:00 AM",
        icon = Icons.ACH_EARLY_BIRD,
        category = "habit",
    },
    night_owl = {
        id = "night_owl",
        name = "Night Owl",
        description = "Read between 12:00 AM and 4:00 AM",
        icon = Icons.ACH_NIGHT_OWL,
        category = "habit",
    },
    weekend_warrior = {
        id = "weekend_warrior",
        name = "Weekend Warrior",
        description = "Read over 100 pages on a Saturday or Sunday",
        icon = Icons.ACH_WEEKEND,
        category = "habit",
    },
    
    -- Session Performance Badges
    centurion = {
        id = "centurion",
        name = "The Centurion",
        description = "Read 100 pages in a single session",
        icon = Icons.ACH_CENTURION,
        category = "session",
    },
    marathon = {
        id = "marathon",
        name = "Marathon",
        description = "Read for 3 hours continuously",
        icon = Icons.ACH_MARATHON,
        category = "session",
    },
    sprint = {
        id = "sprint",
        name = "Sprint",
        description = "Read 50 pages in under 30 minutes",
        icon = Icons.ACH_SPRINT,
        category = "session",
    },
    
    -- Discovery Badge
    format_explorer = {
        id = "format_explorer",
        name = "Format Explorer",
        description = "Read books in 3 different file formats",
        icon = Icons.ACH_EXPLORER,
        category = "discovery",
    },
    
    -- Milestone Badges
    book_slayer = {
        id = "book_slayer",
        name = "Book Slayer",
        description = "Finish a book (reach 95% completion)",
        icon = Icons.ACH_BOOK_SLAYER,
        category = "milestone",
    },
    paperback_hero = {
        id = "paperback_hero",
        name = "Paperback Hero",
        description = "Read 1,000 lifetime pages",
        icon = Icons.ACH_PAPERBACK,
        category = "milestone",
    },
    bibliophile = {
        id = "bibliophile",
        name = "Bibliophile",
        description = "Read 5,000 lifetime pages",
        icon = Icons.ACH_BIBLIOPHILE,
        category = "milestone",
    },
    literary_legend = {
        id = "literary_legend",
        name = "Literary Legend",
        description = "Read 10,000 lifetime pages",
        icon = Icons.ACH_LEGEND,
        category = "milestone",
    },
}

function Achievements:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Achievements:checkAllAchievements()
    self:checkTimeBasedAchievements()
    self:checkMilestoneAchievements()
    self:checkDiscoveryAchievements()
end

function Achievements:checkTimeBasedAchievements()
    local hour = tonumber(os.date("%H"))
    local day_of_week = tonumber(os.date("%w")) -- 0 = Sunday, 6 = Saturday
    
    -- Early Bird (4 AM - 7 AM)
    if hour >= 4 and hour < 7 then
        self:unlock("early_bird")
    end
    
    -- Night Owl (12 AM - 4 AM)
    if hour >= 0 and hour < 4 then
        self:unlock("night_owl")
    end
    
    -- Weekend Warrior (Saturday or Sunday, 100+ pages)
    if day_of_week == 0 or day_of_week == 6 then
        local today_pages = self.core:getDailyPages()
        if today_pages >= 100 then
            self:unlock("weekend_warrior")
        end
    end
end

function Achievements:checkSessionAchievements(session, duration)
    -- The Centurion (100 pages in single session)
    if session.pages_read >= 100 then
        self:unlock("centurion")
    end
    
    -- Marathon (3 hours continuous)
    if duration >= 10800 then -- 3 hours in seconds
        self:unlock("marathon")
    end
    
    -- Sprint (50 pages in under 30 minutes)
    if session.pages_read >= 50 and duration <= 1800 then
        self:unlock("sprint")
    end
end

function Achievements:checkMilestoneAchievements()
    local lifetime_pages = self.core:getLifetimePages()
    
    if lifetime_pages >= 1000 then
        self:unlock("paperback_hero")
    end
    
    if lifetime_pages >= 5000 then
        self:unlock("bibliophile")
    end
    
    if lifetime_pages >= 10000 then
        self:unlock("literary_legend")
    end
end

function Achievements:checkDiscoveryAchievements()
    local format_count = self.core:getFormatCount()
    
    if format_count >= 3 then
        self:unlock("format_explorer")
    end
end

function Achievements:unlock(id)
    if self.core:isAchievementUnlocked(id) then
        return false
    end
    
    if self.core:unlockAchievement(id) then
        local achievement = self.DEFINITIONS[id]
        
        -- Award bonus XP
        local XPEngine = require("xpengine")
        local xp_engine = XPEngine:new{ core = self.core }
        local bonus_xp = xp_engine:calculateBonusXP(id)
        self.core:addXP(bonus_xp, "achievement")
        
        -- Notify plugin
        if self.plugin and self.plugin.onAchievementUnlocked then
            self.plugin:onAchievementUnlocked(id, achievement)
        end
        
        self.core:save()
        logger.info("ReadMastery: Achievement unlocked:", id)
        return true
    end
    
    return false
end

function Achievements:getAll()
    local result = {}
    
    for id, def in pairs(self.DEFINITIONS) do
        local unlocked = self.core:isAchievementUnlocked(id) --or self.core:isDebugMode()
        table.insert(result, {
            id = id,
            name = def.name,
            description = def.description,
            icon = def.icon,
            category = def.category,
            unlocked = unlocked,
            unlocked_at = unlocked and self.core.data.achievements[id] and self.core.data.achievements[id].unlocked_at,
        })
    end
    
    -- Sort by category then name
    table.sort(result, function(a, b)
        if a.category == b.category then
            return a.name < b.name
        end
        return a.category < b.category
    end)
    
    return result
end

function Achievements:getUnlockedCount()
    local count = 0
    for id, _ in pairs(self.DEFINITIONS) do
        if self.core:isAchievementUnlocked(id) then
            count = count + 1
        end
    end
    return count, 11 -- total achievements
end

return Achievements