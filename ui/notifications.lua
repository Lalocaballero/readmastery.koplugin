local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local AsciiArt = require("ascii_art")
local AsciiPopup = require("ui/ascii_popup")
local Icons = require("icons")

local Notifications = {}

function Notifications:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Notifications:showLevelUp(level, unlocked_feature)
    local text = [[
=============================
        LEVEL UP!
=============================

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

=============================
]]
    
    if unlocked_feature then
        text = text .. "\n  NEW UNLOCK: " .. unlocked_feature.name .. "\n"
    end
    
    text = text .. "\n     Congratulations!\n"
    
    UIManager:show(InfoMessage:new{
        text = text,
        timeout = 5,
    })
end

function Notifications:showAchievement(achievement)
    local ascii = AsciiArt.getLarge(achievement.id, true)
    
    local text = [[
=============================
   ACHIEVEMENT UNLOCKED!
=============================

]] .. ascii .. [[

]] .. achievement.name .. " " .. Icons.TIER_BRONZE .. [[

]] .. achievement.description .. [[

=============================
]]
    
    UIManager:show(InfoMessage:new{
        text = text,
        timeout = 6,
    })
end

function Notifications:showTierUp(achievement_id, achievement, tier_info)
    local ascii = AsciiArt.getLarge(achievement_id, true)
    local tier_icon = Icons.getTierIcon(tier_info.id)
    local tier_name = Icons.getTierName(tier_info.id)
    
    local text = [[
=============================
       TIER UPGRADE!
=============================

]] .. ascii .. [[

]] .. achievement.name .. [[

       ]] .. tier_icon .. " " .. string.upper(tier_name) .. [[ ]] .. tier_icon .. [[

=============================
]]
    
    UIManager:show(InfoMessage:new{
        text = text,
        timeout = 6,
    })
end

function Notifications:showStreakMilestone(days)
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
        local text = [[
=============================
     STREAK MILESTONE!
=============================

       ___________
      |           |
      |    ]] .. string.format("%3d", days) .. [[    |
      |   DAYS    |
      |  STREAK   |
      |___________|
         |     |
         |_____|

]] .. milestone_text .. [[

=============================
]]
        UIManager:show(InfoMessage:new{
            text = text,
            timeout = 5,
        })
    end
end

return Notifications