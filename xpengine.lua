local logger = require("logger")

local XPEngine = {}

function XPEngine:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- XP Constants
XPEngine.XP_PER_PAGE = 5
XPEngine.XP_PER_MINUTE = 2
XPEngine.STREAK_MULTIPLIER_BASE = 1.0
XPEngine.STREAK_MULTIPLIER_INCREMENT = 0.05 -- 5% bonus per streak day
XPEngine.MAX_STREAK_MULTIPLIER = 2.0 -- Cap at 100% bonus

function XPEngine:calculatePageXP(pages_turned)
    local base_xp = pages_turned * self.XP_PER_PAGE
    local multiplier = self:getStreakMultiplier()
    
    return math.floor(base_xp * multiplier)
end

function XPEngine:calculateTimeXP(minutes)
    local base_xp = minutes * self.XP_PER_MINUTE
    local multiplier = self:getStreakMultiplier()
    
    return math.floor(base_xp * multiplier)
end

function XPEngine:getStreakMultiplier()
    local streak = self.core:getStreak()
    local multiplier = self.STREAK_MULTIPLIER_BASE + (streak * self.STREAK_MULTIPLIER_INCREMENT)
    
    return math.min(multiplier, self.MAX_STREAK_MULTIPLIER)
end

function XPEngine:calculateBonusXP(achievement_id)
    -- Bonus XP for achievements
    local bonuses = {
        early_bird = 50,
        night_owl = 50,
        weekend_warrior = 100,
        centurion = 150,
        marathon = 200,
        sprint = 100,
        format_explorer = 75,
        book_slayer = 250,
        paperback_hero = 300,
        bibliophile = 500,
        literary_legend = 1000,
    }
    
    return bonuses[achievement_id] or 50
end

return XPEngine