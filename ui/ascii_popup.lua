local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local MovableContainer = require("ui/widget/container/movablecontainer")
local ScrollTextWidget = require("ui/widget/scrolltextwidget")
local Size = require("ui/size")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local Screen = Device.screen

local AsciiPopup = InputContainer:extend{
    title = "",
    ascii_art = "",
    footer = "",
    width = nil,
    height = nil,
}

function AsciiPopup:init()
    -- Use hardcoded margins since Size.margin.large may not exist
    local margin = 20
    self.width = self.width or Screen:getWidth() - margin * 2
    self.height = self.height or Screen:getHeight() - margin * 2
    
    if Device:isTouchDevice() then
        self.ges_events.TapClose = {
            GestureRange:new{
                ges = "tap",
                range = Geom:new{
                    x = 0, y = 0,
                    w = Screen:getWidth(),
                    h = Screen:getHeight(),
                }
            }
        }
    end
    
    if Device:hasKeys() then
        self.key_events.Close = { { "Back" }, doc = "close popup" }
    end
    
    local padding = Size.padding.default or 10
    local content_width = self.width - padding * 4
    
    -- Title (regular font)
    local title_widget = TextWidget:new{
        text = self.title,
        face = Font:getFace("tfont"),
        bold = true,
    }
    
    -- ASCII Art (MONOSPACE font)
    local mono_font = Font:getFace("infont", 12)
    
    local ascii_widget = ScrollTextWidget:new{
        text = self.ascii_art,
        face = mono_font,
        width = content_width,
        height = self.height - 200,
        dialog = self,
    }
    
    -- Footer (regular font)
    local footer_widget = TextWidget:new{
        text = self.footer or "(Tap to close)",
        face = Font:getFace("smallinfofont"),
        fgcolor = Blitbuffer.COLOR_DARK_GRAY,
    }
    
    local span_width = Size.padding.default or 10
    
    local content = VerticalGroup:new{
        align = "center",
        title_widget,
        VerticalSpan:new{ width = span_width },
        ascii_widget,
        VerticalSpan:new{ width = span_width },
        footer_widget,
    }
    
    local frame_padding = Size.padding.large or 15
    local frame_radius = Size.radius.window or 8
    local frame_border = Size.border.window or 2
    
    self.frame = FrameContainer:new{
        radius = frame_radius,
        bordersize = frame_border,
        padding = frame_padding,
        background = Blitbuffer.COLOR_WHITE,
        content,
    }
    
    self.movable = MovableContainer:new{
        self.frame,
    }
    
    self[1] = CenterContainer:new{
        dimen = Screen:getSize(),
        self.movable,
    }
end

function AsciiPopup:onTapClose()
    self:onClose()
    return true
end

function AsciiPopup:onClose()
    UIManager:close(self)
    return true
end

function AsciiPopup:onCloseWidget()
    UIManager:setDirty(nil, "ui")
end

return AsciiPopup