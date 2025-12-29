local logger = require("logger")
local _ = require("gettext")
local Icons = require("icons")

local Achievements = {}

-- Tier definitions
Achievements.TIERS = {
    { id = "bronze", name = "Bronze", icon = "(B)", order = 1 },
    { id = "silver", name = "Silver", icon = "(S)", order = 2 },
    { id = "gold", name = "Gold", icon = "(G)", order = 3 },
    { id = "platinum", name = "Platinum", icon = "(P)", order = 4 },
}

-- Achievement Definitions with Tier Thresholds
Achievements.DEFINITIONS = {
    -- Time & Habit Badges
    early_bird = {
        id = "early_bird",
        name = "Early Bird",
        description = "Read between 4:00 AM and 7:00 AM",
        icon = Icons.ACH_EARLY_BIRD,
        category = "habit",
        tiers = { bronze = 1, silver = 5, gold = 15, platinum = 30 },
        tier_descriptions = {
            bronze = "Read once at 4-7 AM",
            silver = "Read 5 times at 4-7 AM",
            gold = "Read 15 times at 4-7 AM",
            platinum = "Read 30 times at 4-7 AM",
        },
    },
    night_owl = {
        id = "night_owl",
        name = "Night Owl",
        description = "Read between 12:00 AM and 4:00 AM",
        icon = Icons.ACH_NIGHT_OWL,
        category = "habit",
        tiers = { bronze = 1, silver = 5, gold = 15, platinum = 30 },
        tier_descriptions = {
            bronze = "Read once at midnight-4 AM",
            silver = "Read 5 times at midnight-4 AM",
            gold = "Read 15 times at midnight-4 AM",
            platinum = "Read 30 times at midnight-4 AM",
        },
    },
    weekend_warrior = {
        id = "weekend_warrior",
        name = "Weekend Warrior",
        description = "Read over 100 pages on a Saturday or Sunday",
        icon = Icons.ACH_WEEKEND,
        category = "habit",
        tiers = { bronze = 1, silver = 4, gold = 12, platinum = 24 },
        tier_descriptions = {
            bronze = "100+ pages on 1 weekend day",
            silver = "100+ pages on 4 weekend days",
            gold = "100+ pages on 12 weekend days",
            platinum = "100+ pages on 24 weekend days",
        },
    },
    
    -- Session Performance Badges
    centurion = {
        id = "centurion",
        name = "The Centurion",
        description = "Read 100 pages in a single session",
        icon = Icons.ACH_CENTURION,
        category = "session",
        tiers = { bronze = 1, silver = 3, gold = 10, platinum = 25 },
        tier_descriptions = {
            bronze = "100-page session once",
            silver = "100-page session 3 times",
            gold = "100-page session 10 times",
            platinum = "100-page session 25 times",
        },
    },
    marathon = {
        id = "marathon",
        name = "Marathon",
        description = "Actively read for 3 hours",
        icon = Icons.ACH_MARATHON,
        category = "session",
        tiers = { bronze = 1, silver = 3, gold = 10, platinum = 20 },
        tier_descriptions = {
            bronze = "3-hour session once",
            silver = "3-hour session 3 times",
            gold = "3-hour session 10 times",
            platinum = "3-hour session 20 times",
        },
    },
    sprint = {
        id = "sprint",
        name = "Sprint",
        description = "Read 50 pages in under 30 minutes",
        icon = Icons.ACH_SPRINT,
        category = "session",
        tiers = { bronze = 1, silver = 5, gold = 15, platinum = 30 },
        tier_descriptions = {
            bronze = "Speed read once",
            silver = "Speed read 5 times",
            gold = "Speed read 15 times",
            platinum = "Speed read 30 times",
        },
    },
    
    -- Discovery Badge
    format_explorer = {
        id = "format_explorer",
        name = "Format Explorer",
        description = "Read books in different file formats",
        icon = Icons.ACH_EXPLORER,
        category = "discovery",
        tiers = { bronze = 3, silver = 5, gold = 7, platinum = 10 },
        tier_descriptions = {
            bronze = "Read 3 different formats",
            silver = "Read 5 different formats",
            gold = "Read 7 different formats",
            platinum = "Read 10 different formats",
        },
        count_type = "formats", -- Special: counts formats, not occurrences
    },
    
    -- Milestone Badges
    book_slayer = {
        id = "book_slayer",
        name = "Book Slayer",
        description = "Finish books (reach 95% completion)",
        icon = Icons.ACH_BOOK_SLAYER,
        category = "milestone",
        tiers = { bronze = 1, silver = 5, gold = 15, platinum = 30 },
        tier_descriptions = {
            bronze = "Finish 1 book",
            silver = "Finish 5 books",
            gold = "Finish 15 books",
            platinum = "Finish 30 books",
        },
    },
    paperback_hero = {
        id = "paperback_hero",
        name = "Paperback Hero",
        description = "Read lifetime pages",
        icon = Icons.ACH_PAPERBACK,
        category = "milestone",
        tiers = { bronze = 1000, silver = 2500, gold = 5000, platinum = 10000 },
        tier_descriptions = {
            bronze = "Read 1,000 pages",
            silver = "Read 2,500 pages",
            gold = "Read 5,000 pages",
            platinum = "Read 10,000 pages",
        },
        count_type = "pages", -- Special: uses lifetime pages
    },
    bibliophile = {
        id = "bibliophile",
        name = "Bibliophile",
        description = "Read lifetime pages",
        icon = Icons.ACH_BIBLIOPHILE,
        category = "milestone",
        tiers = { bronze = 5000, silver = 10000, gold = 25000, platinum = 50000 },
        tier_descriptions = {
            bronze = "Read 5,000 pages",
            silver = "Read 10,000 pages",
            gold = "Read 25,000 pages",
            platinum = "Read 50,000 pages",
        },
        count_type = "pages",
    },
    literary_legend = {
        id = "literary_legend",
        name = "Literary Legend",
        description = "Read lifetime pages",
        icon = Icons.ACH_LEGEND,
        category = "milestone",
        tiers = { bronze = 10000, silver = 25000, gold = 50000, platinum = 100000 },
        tier_descriptions = {
            bronze = "Read 10,000 pages",
            silver = "Read 25,000 pages",
            gold = "Read 50,000 pages",
            platinum = "Read 100,000 pages",
        },
        count_type = "pages",
    },
}

function Achievements:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Get tier info by id
function Achievements:getTierInfo(tier_id)
    for _, tier in ipairs(self.TIERS) do
        if tier.id == tier_id then
            return tier
        end
    end
    return self.TIERS[1] -- Default to bronze
end

-- Get next tier after current
function Achievements:getNextTier(current_tier)
    local current_order = 0
    for _, tier in ipairs(self.TIERS) do
        if tier.id == current_tier then
            current_order = tier.order
            break
        end
    end
    
    for _, tier in ipairs(self.TIERS) do
        if tier.order == current_order + 1 then
            return tier
        end
    end
    
    return nil -- Already at max tier
end

-- Calculate tier based on count
function Achievements:calculateTier(achievement_id, count)
    local def = self.DEFINITIONS[achievement_id]
    if not def or not def.tiers then
        return "bronze"
    end
    
    local tier = "bronze"
    if count >= def.tiers.platinum then
        tier = "platinum"
    elseif count >= def.tiers.gold then
        tier = "gold"
    elseif count >= def.tiers.silver then
        tier = "silver"
    elseif count >= def.tiers.bronze then
        tier = "bronze"
    end
    
    return tier
end

-- Get progress to next tier
function Achievements:getTierProgress(achievement_id, count)
    local def = self.DEFINITIONS[achievement_id]
    if not def or not def.tiers then
        return nil
    end
    
    local current_tier = self:calculateTier(achievement_id, count)
    local next_tier = self:getNextTier(current_tier)
    
    if not next_tier then
        -- Max tier reached
        return {
            current_tier = current_tier,
            next_tier = nil,
            current_count = count,
            next_threshold = nil,
            progress_percent = 100,
            is_max = true,
        }
    end
    
    local current_threshold = def.tiers[current_tier]
    local next_threshold = def.tiers[next_tier.id]
    
    local progress = count - current_threshold
    local needed = next_threshold - current_threshold
    local percent = math.floor((progress / needed) * 100)
    
    return {
        current_tier = current_tier,
        next_tier = next_tier.id,
        current_count = count,
        next_threshold = next_threshold,
        progress_percent = math.min(100, math.max(0, percent)),
        is_max = false,
    }
end

function Achievements:checkAllAchievements()
    self:checkTimeBasedAchievements()
    self:checkMilestoneAchievements()
    self:checkDiscoveryAchievements()
end

function Achievements:checkTimeBasedAchievements()
    local hour = tonumber(os.date("%H"))
    local day_of_week = tonumber(os.date("%w"))
    
    -- Early Bird (4 AM - 7 AM)
    if hour >= 4 and hour < 7 then
        self:progressAchievement("early_bird")
    end
    
    -- Night Owl (12 AM - 4 AM)
    if hour >= 0 and hour < 4 then
        self:progressAchievement("night_owl")
    end
    
    -- Weekend Warrior (Saturday or Sunday, 100+ pages)
    if day_of_week == 0 or day_of_week == 6 then
        local today_pages = self.core:getDailyPages()
        if today_pages >= 100 then
            self:progressAchievement("weekend_warrior")
        end
    end
end

function Achievements:checkSessionAchievements(session, active_duration)
    -- Session achievements handled in main.lua
end

function Achievements:checkMilestoneAchievements()
    local lifetime_pages = self.core:getLifetimePages()
    
    -- Page-based achievements - check tier upgrades
    self:checkPageMilestone("paperback_hero", lifetime_pages)
    self:checkPageMilestone("bibliophile", lifetime_pages)
    self:checkPageMilestone("literary_legend", lifetime_pages)
end

function Achievements:checkPageMilestone(achievement_id, pages)
    local def = self.DEFINITIONS[achievement_id]
    if not def then return end
    
    local current_data = self.core:getAchievementData(achievement_id)
    local current_tier = current_data and current_data.tier or nil
    local new_tier = self:calculateTier(achievement_id, pages)
    
    if not current_tier then
        -- First unlock
        if pages >= def.tiers.bronze then
            self:unlock(achievement_id)
            self.core:setAchievementTier(achievement_id, new_tier)
            -- Store pages as count for page-based achievements
            if self.core.data.achievements[achievement_id] then
                self.core.data.achievements[achievement_id].count = pages
            end
        end
    else
        -- Check for tier upgrade
        local current_order = self:getTierInfo(current_tier).order
        local new_order = self:getTierInfo(new_tier).order
        
        if new_order > current_order then
            self.core:setAchievementTier(achievement_id, new_tier)
            if self.core.data.achievements[achievement_id] then
                self.core.data.achievements[achievement_id].count = pages
            end
            self:onTierUp(achievement_id, new_tier)
        end
    end
end

function Achievements:checkDiscoveryAchievements()
    local format_count = self.core:getFormatCount()
    
    local def = self.DEFINITIONS["format_explorer"]
    if not def then return end
    
    local current_data = self.core:getAchievementData("format_explorer")
    local current_tier = current_data and current_data.tier or nil
    local new_tier = self:calculateTier("format_explorer", format_count)
    
    if not current_tier then
        if format_count >= def.tiers.bronze then
            self:unlock("format_explorer")
            self.core:setAchievementTier("format_explorer", new_tier)
            if self.core.data.achievements["format_explorer"] then
                self.core.data.achievements["format_explorer"].count = format_count
            end
        end
    else
        local current_order = self:getTierInfo(current_tier).order
        local new_order = self:getTierInfo(new_tier).order
        
        if new_order > current_order then
            self.core:setAchievementTier("format_explorer", new_tier)
            if self.core.data.achievements["format_explorer"] then
                self.core.data.achievements["format_explorer"].count = format_count
            end
            self:onTierUp("format_explorer", new_tier)
        end
    end
end

-- Progress an achievement (increment count, check tier)
function Achievements:progressAchievement(id)
    local def = self.DEFINITIONS[id]
    if not def then return end
    
    -- Check if already unlocked
    if self.core:isAchievementUnlocked(id) then
        -- Increment count
        local new_count = self.core:incrementAchievementCount(id)
        
        -- Check for tier upgrade
        local current_tier = self.core:getAchievementTier(id)
        local new_tier = self:calculateTier(id, new_count)
        
        local current_order = self:getTierInfo(current_tier).order
        local new_order = self:getTierInfo(new_tier).order
        
        if new_order > current_order then
            self.core:setAchievementTier(id, new_tier)
            self:onTierUp(id, new_tier)
        end
        
        self.core:save()
    else
        -- First time unlock
        self:unlock(id)
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

function Achievements:onTierUp(achievement_id, new_tier)
    local achievement = self.DEFINITIONS[achievement_id]
    if not achievement then return end
    
    local tier_info = self:getTierInfo(new_tier)
    
    -- Award bonus XP for tier upgrade
    local XPEngine = require("xpengine")
    local xp_engine = XPEngine:new{ core = self.core }
    local tier_xp = xp_engine:calculateTierXP(new_tier)
    self.core:addXP(tier_xp, "tier_upgrade")
    
    -- Notify plugin
    if self.plugin and self.plugin.onTierUp then
        self.plugin:onTierUp(achievement_id, achievement, tier_info)
    end
    
    logger.info("ReadMastery: Tier up!", achievement_id, "->", new_tier)
end

function Achievements:getAll()
    local result = {}
    
    local debug_mode = false
    if self.core and self.core.isDebugMode then
        debug_mode = self.core:isDebugMode()
    elseif self.core and self.core.data then
        debug_mode = self.core.data.debug_mode or false
    end
    
    for id, def in pairs(self.DEFINITIONS) do
        local unlocked = false
        local count = 0
        local tier = nil
        local unlocked_at = nil
        
        if self.core and self.core.isAchievementUnlocked then
            unlocked = self.core:isAchievementUnlocked(id) or debug_mode
        end
        
        if unlocked and self.core then
            local data = self.core:getAchievementData(id)
            if data then
                count = data.count or 1
                tier = data.tier or "bronze"
                unlocked_at = data.unlocked_at
            end
        end
        
        -- Get progress info
        local progress = nil
        if unlocked then
            -- For page-based achievements, get current pages
            if def.count_type == "pages" then
                count = self.core:getLifetimePages()
            elseif def.count_type == "formats" then
                count = self.core:getFormatCount()
            end
            progress = self:getTierProgress(id, count)
        end
        
        table.insert(result, {
            id = id,
            name = def.name,
            description = def.description,
            icon = def.icon,
            category = def.category,
            unlocked = unlocked,
            unlocked_at = unlocked_at,
            count = count,
            tier = tier,
            progress = progress,
            tier_descriptions = def.tier_descriptions,
            tiers = def.tiers,
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
        if self.core and self.core.isAchievementUnlocked and self.core:isAchievementUnlocked(id) then
            count = count + 1
        end
    end
    return count, 11
end

-- Count achievements by tier
function Achievements:getTierCounts()
    local counts = { bronze = 0, silver = 0, gold = 0, platinum = 0 }
    
    for id, _ in pairs(self.DEFINITIONS) do
        if self.core and self.core.isAchievementUnlocked and self.core:isAchievementUnlocked(id) then
            local tier = self.core:getAchievementTier(id) or "bronze"
            counts[tier] = counts[tier] + 1
        end
    end
    
    return counts
end

return Achievements