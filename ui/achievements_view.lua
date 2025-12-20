local InfoMessage = require("ui/widget/infomessage")
local Menu = require("ui/widget/menu")
local UIManager = require("ui/uimanager")
local Screen = require("device").screen
local _ = require("gettext")

local AsciiArt = require("ascii_art")
local AsciiPopup = require("ui/ascii_popup")

local AchievementsView = {}

function AchievementsView:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function AchievementsView:show()
    local achievements = self.plugin.achievements:getAll()
    local unlocked_count, total = self.plugin.achievements:getUnlockedCount()
    
    -- Build menu items
    local menu_items = {}
    
    -- Category headers
    local categories = {
        { id = "habit", name = "--- TIME & HABIT ---" },
        { id = "session", name = "--- SESSION PERFORMANCE ---" },
        { id = "discovery", name = "--- DISCOVERY ---" },
        { id = "milestone", name = "--- MILESTONES ---" },
    }
    
    local current_category = nil
    local view = self
    
    for _, ach in ipairs(achievements) do
        -- Add category header if new category
        if ach.category ~= current_category then
            current_category = ach.category
            
            local cat_name = current_category
            for _, c in ipairs(categories) do
                if c.id == current_category then
                    cat_name = c.name
                    break
                end
            end
            
            table.insert(menu_items, {
                text = cat_name,
                bold = true,
            })
        end
        
        -- Achievement entry
        local status = ach.unlocked and "[x]" or "[ ]"
        local display_text = status .. " " .. ach.name
        
        if not ach.unlocked then
            display_text = display_text .. " (???)"
        end
        
        local ach_copy = {
            id = ach.id,
            name = ach.name,
            description = ach.description,
            icon = ach.icon,
            category = ach.category,
            unlocked = ach.unlocked,
            unlocked_at = ach.unlocked_at,
        }
        
        table.insert(menu_items, {
            text = display_text,
            callback = function()
                view:showAchievementDetail(ach_copy)
            end,
        })
    end
    
    local menu = Menu:new{
        title = "ACHIEVEMENTS (" .. unlocked_count .. "/" .. total .. ")",
        item_table = menu_items,
        width = Screen:getWidth(),
        height = Screen:getHeight(),
        covers_fullscreen = true,
        is_borderless = true,
        is_popout = false,
    }
    
    menu.close_callback = function()
        UIManager:close(menu)
    end
    
    UIManager:show(menu)
end

function AchievementsView:showAchievementDetail(achievement)
    local ascii = AsciiArt.getLarge(achievement.id, achievement.unlocked)
    
    local status_line = achievement.unlocked and "[UNLOCKED]" or "[LOCKED]"
    
    local footer_text = ""
    if achievement.unlocked then
        footer_text = achievement.description
        if achievement.unlocked_at then
            footer_text = footer_text .. "\nUnlocked: " .. os.date("%B %d, %Y", achievement.unlocked_at)
        end
    else
        footer_text = "Keep reading to unlock!"
    end
    footer_text = footer_text .. "\n\n(Tap to close)"
    
    local popup = AsciiPopup:new{
        title = string.upper(achievement.name) .. " " .. status_line,
        ascii_art = ascii,
        footer = footer_text,
    }
    popup:init()
    UIManager:show(popup)
end

return AchievementsView