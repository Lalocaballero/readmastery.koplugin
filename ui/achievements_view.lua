local InfoMessage = require("ui/widget/infomessage")
local Menu = require("ui/widget/menu")
local UIManager = require("ui/uimanager")
local Screen = require("device").screen
local _ = require("gettext")

local AsciiArt = require("ascii_art")
local AsciiPopup = require("ui/ascii_popup")
local Icons = require("icons")

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
    local tier_counts = self.plugin.achievements:getTierCounts()
    
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
        
        -- Achievement entry with tier
        local status = ach.unlocked and "[x]" or "[ ]"
        local tier_icon = ""
        if ach.unlocked and ach.tier then
            tier_icon = " " .. Icons.getTierIcon(ach.tier)
        end
        
        local display_text = status .. " " .. ach.name .. tier_icon
        
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
            count = ach.count,
            tier = ach.tier,
            progress = ach.progress,
            tier_descriptions = ach.tier_descriptions,
            tiers = ach.tiers,
        }
        
        table.insert(menu_items, {
            text = display_text,
            callback = function()
                view:showAchievementDetail(ach_copy)
            end,
        })
    end
    
    -- Build title with tier summary
    local title = "ACHIEVEMENTS (" .. unlocked_count .. "/" .. total .. ")"
    
    local menu = Menu:new{
        title = title,
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
    
    local status_text = "[LOCKED]"
    if achievement.unlocked then
        local tier_name = Icons.getTierName(achievement.tier or "bronze")
        status_text = "[" .. string.upper(tier_name) .. "]"
    end
    
    local title = string.upper(achievement.name) .. " " .. status_text
    
    local footer = ""
    if achievement.unlocked then
        footer = achievement.description .. "\n"
        
        -- Show tier progress
        if achievement.progress then
            footer = footer .. "\n"
            
            if achievement.progress.is_max then
                footer = footer .. "MAX TIER REACHED!\n"
            else
                local current_tier = Icons.getTierName(achievement.progress.current_tier)
                local next_tier = Icons.getTierName(achievement.progress.next_tier)
                
                footer = footer .. "Current: " .. current_tier .. "\n"
                footer = footer .. "Next: " .. next_tier .. " (" .. achievement.progress.current_count .. "/" .. achievement.progress.next_threshold .. ")\n"
                footer = footer .. Icons.progressBar(achievement.progress.progress_percent, 15) .. " " .. achievement.progress.progress_percent .. "%\n"
            end
        end
        
        -- Show tier requirements
        if achievement.tier_descriptions then
            footer = footer .. "\n--- TIERS ---\n"
            footer = footer .. "(B) " .. achievement.tier_descriptions.bronze .. "\n"
            footer = footer .. "(S) " .. achievement.tier_descriptions.silver .. "\n"
            footer = footer .. "(G) " .. achievement.tier_descriptions.gold .. "\n"
            footer = footer .. "(P) " .. achievement.tier_descriptions.platinum .. "\n"
        end
        
        if achievement.unlocked_at then
            local unlock_date = os.date("%b %d, %Y", achievement.unlocked_at)
            footer = footer .. "\nFirst unlocked: " .. unlock_date .. "\n"
        end
    else
        footer = "Keep reading to unlock!\n"
        
        -- Show what's needed for bronze
        if achievement.tier_descriptions then
            footer = footer .. "\nRequirement:\n"
            footer = footer .. achievement.tier_descriptions.bronze .. "\n"
        end
    end
    
    footer = footer .. "\n(Tap to close)"
    
    local popup = AsciiPopup:new{
        title = title,
        ascii_art = ascii,
        footer = footer,
    }
    popup:init()
    UIManager:show(popup)
end

return AchievementsView