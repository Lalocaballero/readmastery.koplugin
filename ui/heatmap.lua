local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local Heatmap = {}

function Heatmap:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Heatmap:show()
    local analytics = self.plugin.analytics
    local text = analytics:renderHeatmapText()
    
    UIManager:show(InfoMessage:new{
        text = text,
        timeout = 15,
    })
end

return Heatmap