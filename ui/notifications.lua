local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local AsciiArt = require("ascii_art")
local AsciiPopup = require("ui/ascii_popup")

local Notifications = {}

function Notifications:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Notifications:showLevelUp(level, unlocked_feature)
    local ascii = [[

    *    *    *
      \  |  /
       \ | /
    ----   ----
       LEVEL
         ]] .. level .. [[

    ----   ----
       / | \
      /  |  \
    *    *    *

]]
    
    local footer = "Congratulations!"
    if unlocked_feature then
        footer = "NEW UNLOCK: " .. unlocked_feature.name
    end
    footer = footer .. "\n\n(Tap to close)"
    
    local popup = AsciiPopup:new{
        title = "LEVEL UP!",
        ascii_art = ascii,
        footer = footer,
    }
    popup:init()
    UIManager:show(popup)
end

function Notifications:showAchievement(achievement)
    local ascii = AsciiArt.getLarge(achievement.id, true)
    
    local popup = AsciiPopup:new{
        title = "ACHIEVEMENT UNLOCKED!",
        ascii_art = ascii,
        footer = achievement.name .. "\n" .. achievement.description .. "\n\n(Tap to close)",
    }
    popup:init()
    UIManager:show(popup)
end

function Notifications:showStreakMilestone(days)
    local ascii = [[

     ___________
    |           |
    |   ]] .. string.format("%3d", days) .. [[     |
    |   DAYS    |
    |   STREAK  |
    |___________|
       |     |
       |_____|

]]
    
    local milestones = {
        [7] = "One Week Wonder!",
        [14] = "Two Week Triumph!",
        [30] = "Monthly Master!",
        [60] = "Bimonthly Beast!",
        [100] = "Century Streak!",
        [365] = "Year of Reading!",
    }
    
    local milestone_text = milestones[days]
    if milestone_text then
        local popup = AsciiPopup:new{
            title = "STREAK MILESTONE!",
            ascii_art = ascii,
            footer = milestone_text .. "\n\n(Tap to close)",
        }
        popup:init()
        UIManager:show(popup)
    end
end

return Notifications