local _ = require("gettext")

local FeatureUnlocks = {}

FeatureUnlocks.UNLOCKS = {
    { level = 3, feature = "session_stats", name = _("Session Stats") },
    { level = 5, feature = "heatmap", name = _("Reading Heatmap") },
    { level = 7, feature = "weekly_digest", name = _("Weekly Digest") },
    { level = 10, feature = "speed_analytics", name = _("Speed Analytics") },
    { level = 15, feature = "completion_rate", name = _("Book Completion Rate") },
    { level = 20, feature = "hall_of_fame", name = _("Hall of Fame") },
}

function FeatureUnlocks:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function FeatureUnlocks:checkUnlock(level)
    for _, unlock in ipairs(self.UNLOCKS) do
        if unlock.level == level then
            return unlock
        end
    end
    return nil
end

function FeatureUnlocks:isFeatureUnlocked(feature_id)
    if self.core:isSandboxMode() then
        return true
    end
    
    local current_level = self.core:getLevel()
    
    for _, unlock in ipairs(self.UNLOCKS) do
        if unlock.feature == feature_id then
            return current_level >= unlock.level
        end
    end
    
    return true -- Unknown features are unlocked by default
end

function FeatureUnlocks:getRequiredLevel(feature_id)
    for _, unlock in ipairs(self.UNLOCKS) do
        if unlock.feature == feature_id then
            return unlock.level
        end
    end
    return 1
end

function FeatureUnlocks:getAllUnlocks()
    local result = {}
    local current_level = self.core:getLevel()
    
    for _, unlock in ipairs(self.UNLOCKS) do
        table.insert(result, {
            level = unlock.level,
            feature = unlock.feature,
            name = unlock.name,
            unlocked = self.core:isSandboxMode() or current_level >= unlock.level,
        })
    end
    
    return result
end

return FeatureUnlocks