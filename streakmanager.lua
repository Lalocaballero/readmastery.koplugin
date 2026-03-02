local logger = require("logger")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local _ = require("gettext")

local StreakManager = {}

function StreakManager:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function StreakManager:checkDailyStreak()
    local today = os.date("%Y-%m-%d")
    local last_active = self.core:getLastActiveDate()
    
    if not last_active then
        -- First time user
        return
    end
    
    if last_active == today then
        -- Already active today, nothing to do
        return
    end
    
    local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
    
    if last_active == yesterday then
        -- Streak continues (will be incremented when they read)
        return
    end
    
    -- Calculate actual days missed (days between last active and today, minus 1)
    -- e.g., if last_active was 2 days ago, days_between = 2, days_missed = 1
    local days_between = self:daysBetween(last_active, today)
    local days_missed = days_between - 1  -- subtract 1 because "yesterday" = 0 missed days
    
    if days_missed <= 0 then
        -- This shouldn't happen given the checks above, but be safe
        return
    end
    
    if days_missed == 1 then
        -- Missed exactly one day, try to use freeze token
        if self.core:useFreezeToken() then
            UIManager:show(InfoMessage:new{
                text = _("🧊 Freeze Token used! Your streak is preserved."),
                timeout = 4,
            })
            logger.info("ReadMastery: Freeze token used to preserve streak")
        else
            -- No freeze token, reset streak
            self:resetStreak()
        end
    else
        -- Missed multiple days, reset streak
        self:resetStreak()
    end
end

function StreakManager:markTodayActive()
    local today = os.date("%Y-%m-%d")
    local last_active = self.core:getLastActiveDate()
    
    if last_active ~= today then
        -- New day of reading
        local current_streak = self.core:getStreak()
        
        if last_active then
            local yesterday = os.date("%Y-%m-%d", os.time() - 86400)
            local days_gap = self:daysBetween(last_active, today)
            
            if last_active == yesterday or days_gap <= 1 then
                -- Continuing streak (yesterday or same day edge case)
                self.core:setStreak(current_streak + 1)
            elseif days_gap == 2 and current_streak > 0 then
                -- Missed exactly one day - streak may have been preserved by freeze token
                -- in checkDailyStreak. If streak is still > 0, it was preserved.
                self.core:setStreak(current_streak + 1)
            else
                -- Gap too large or streak was already reset
                if current_streak > 0 then
                    -- Streak was preserved somehow (freeze token), continue it
                    self.core:setStreak(current_streak + 1)
                else
                    -- Starting fresh
                    self.core:setStreak(1)
                end
            end
        else
            -- First day ever
            self.core:setStreak(1)
        end
        
        self.core:setLastActiveDate(today)
        
        -- Check for freeze token reward (every 7 days)
        local new_streak = self.core:getStreak()
        if new_streak > 0 and new_streak % 7 == 0 then
            self.core:addFreezeToken()
            UIManager:show(InfoMessage:new{
                text = _("🎉 7-day streak! You earned a Freeze Token!"),
                timeout = 3,
            })
        end
        
        self.core:save()
    end
end

function StreakManager:resetStreak()
    local old_streak = self.core:getStreak()
    self.core:setStreak(0)
    
    if old_streak > 0 then
        UIManager:show(InfoMessage:new{
            text = _("💔 Streak lost! Your streak has been reset to 0."),
            timeout = 3,
        })
    end
    
    logger.info("ReadMastery: Streak reset from", old_streak, "to 0")
end

function StreakManager:daysBetween(date1, date2)
    -- Parse dates
    local y1, m1, d1 = date1:match("(%d+)-(%d+)-(%d+)")
    local y2, m2, d2 = date2:match("(%d+)-(%d+)-(%d+)")
    
    local time1 = os.time{year=y1, month=m1, day=d1}
    local time2 = os.time{year=y2, month=m2, day=d2}
    
    return math.floor(math.abs(time2 - time1) / 86400)
end

function StreakManager:getStreakInfo()
    return {
        current = self.core:getStreak(),
        longest = self.core:getLongestStreak(),
        freeze_tokens = self.core:getFreezeTokens(),
        last_active = self.core:getLastActiveDate(),
    }
end

return StreakManager