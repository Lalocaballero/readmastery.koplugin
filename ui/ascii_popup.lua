local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local InputContainer = require("ui/widget/container/inputcontainer")
local MovableContainer = require("ui/widget/container/movablecontainer")
local OverlapGroup = require("ui/widget/overlapgroup")
local ScrollTextWidget = require("ui/widget/scrolltextwidget")
local Size = require("ui/size")
local TextBoxWidget = require("ui/widget/textboxwidget")
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
    local screen_width = Screen:getWidth()
    local screen_height = Screen:getHeight()
    
    -- Calculate popup size (80% of screen)
    self.width = self.width or math.floor(screen_width * 0.85)
    self.height = self.height or math.floor(screen_height * 0.80)
    
    if Device:isTouchDevice() then
        self.ges_events.TapClose = {
            GestureRange:new{
                ges = "tap",
                range = Geom:new{
                    x = 0, y = 0,
                    w = screen_width,
                    h = screen_height,
                }
            }
        }
    end
    
    if Device:hasKeys() then
        self.key_events.Close = { { "Back" }, doc = "close popup" }
    end
    
    local padding = Size.padding.default or 10
    local frame_padding = Size.padding.large or 15
    local content_width = self.width - (frame_padding * 2) - (padding * 2)
    
    -- Title widget (centered, bold)
    local title_widget = TextWidget:new{
        text = self.title,
        face = Font:getFace("tfont"),
        bold = true,
        max_width = content_width,
    }
    
    local title_container = CenterContainer:new{
        dimen = Geom:new{
            w = content_width,
            h = title_widget:getSize().h,
        },
        title_widget,
    }
    
    -- ASCII Art widget (monospace font, centered)
    local mono_face = Font:getFace("infont", 12)
    
    -- Calculate ASCII art dimensions
    local ascii_lines = {}
    for line in self.ascii_art:gmatch("[^\n]*") do
        table.insert(ascii_lines, line)
    end
    
    local ascii_widget = TextBoxWidget:new{
        text = self.ascii_art,
        face = mono_face,
        width = content_width,
        alignment = "center",
    }
    
    local ascii_container = CenterContainer:new{
        dimen = Geom:new{
            w = content_width,
            h = ascii_widget:getSize().h,
        },
        ascii_widget,
    }
    
    -- Footer widget (centered)
    local footer_widget = TextBoxWidget:new{
        text = self.footer,
        face = Font:getFace("smallinfofont"),
        width = content_width,
        alignment = "center",
        fgcolor = Blitbuffer.COLOR_DARK_GRAY,
    }
    
    local footer_container = CenterContainer:new{
        dimen = Geom:new{
            w = content_width,
            h = footer_widget:getSize().h,
        },
        footer_widget,
    }
    
    -- Vertical spacing
    local span_small = VerticalSpan:new{ width = padding }
    local span_large = VerticalSpan:new{ width = padding * 2 }
    
    -- Combine all elements
    local content = VerticalGroup:new{
        align = "center",
        title_container,
        span_large,
        ascii_container,
        span_large,
        footer_container,
    }
    
    -- Center the content vertically
    local content_height = content:getSize().h
    local available_height = self.height - (frame_padding * 2)
    
    local main_content
    if content_height < available_height then
        -- Center vertically if content fits
        main_content = CenterContainer:new{
            dimen = Geom:new{
                w = content_width,
                h = available_height,
            },
            content,
        }
    else
        -- Use scrollable container if content is too tall
        main_content = ScrollTextWidget:new{
            text = self.title .. "\n\n" .. self.ascii_art .. "\n\n" .. self.footer,
            face = mono_face,
            width = content_width,
            height = available_height,
            dialog = self,
        }
    end
    
    -- Frame
    local frame_radius = Size.radius.window or 8
    local frame_border = Size.border.window or 2
    
    self.frame = FrameContainer:new{
        radius = frame_radius,
        bordersize = frame_border,
        padding = frame_padding,
        background = Blitbuffer.COLOR_WHITE,
        main_content,
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