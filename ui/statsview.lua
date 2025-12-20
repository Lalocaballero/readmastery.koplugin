local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local _ = require("gettext")
local T = require("ffi/util").template

local Icons = require("icons")

local StatsView = {}

function StatsView:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function StatsView:show()
    local core = self.plugin.core
    local xp_info = core:getXPForNextLevel()
    local streak_info = self.plugin.streak_manager:getStreakInfo()
    local unlocked, total = self.plugin.achievements:getUnlockedCount()
    
    -- Build XP progress bar
    local progress_pct = math.min(100, math.floor((xp_info.current / xp_info.needed) * 100))
    local progress_bar = Icons.progressBar(progress_pct, 20)
    
    local text = [[
====== READMASTERY ======

Level ]] .. core:getLevel() .. [[

]] .. progress_bar .. [[ ]] .. progress_pct .. [[%
XP: ]] .. xp_info.current .. [[ / ]] .. xp_info.needed .. [[


Streak:         ]] .. streak_info.current .. [[ days
Freeze Tokens:  ]] .. streak_info.freeze_tokens .. [[

Lifetime Pages: ]] .. core:getLifetimePages() .. [[

Achievements:   ]] .. unlocked .. [[/]] .. total .. [[

]]
    
    -- Add next unlock info
    local next_unlock = self:getNextUnlock()
    if next_unlock then
        text = text .. "-------------------------\n"
        text = text .. "Next Unlock:\n"
        text = text .. "  " .. next_unlock.name .. " (Level " .. next_unlock.level .. ")\n"
    end
    
    UIManager:show(InfoMessage:new{
        text = text,
        timeout = 10,
    })
end

function StatsView:getNextUnlock()
    local unlocks = self.plugin.feature_unlocks:getAllUnlocks()
    local current_level = self.plugin.core:getLevel()
    
    for _, unlock in ipairs(unlocks) do
        if not unlock.unlocked and unlock.level > current_level then
            return unlock
        end
    end
    
    return nil
end

return StatsView