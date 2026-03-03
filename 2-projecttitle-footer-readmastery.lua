--[[
    ReadMastery integration with Project: Title footer
    
    This user patch adds ReadMastery stats (streak, level, XP, pages)
    to the Project: Title plugin's footer bar in the file browser.
    
    Installation:
    1. Copy this file to your KOReader patches/ directory
    2. Restart KOReader
    3. Configure display format in ReadMastery > Display > ProjectTitle Footer
    
    Requires: Project: Title plugin (https://github.com/joshuacant/ProjectTitle.koplugin)
    Requires: ReadMastery plugin
]]

local DataStorage = require("datastorage")
local json = require("json")
local logger = require("logger")

local Menu = require("ui/widget/menu")

-- Store original function
local updatePageInfo_orig = Menu.updatePageInfo

-- ReadMastery data reader for footer
local function getReadMasteryText()
    local ok, result = pcall(function()
        local data_file = DataStorage:getDataDir() .. "/readmastery/readmastery_data.json"
        local file = io.open(data_file, "r")
        if file then
            local content = file:read("*all")
            file:close()
            local data = json.decode(content)
            if data then
                local streak = data.current_streak or 0
                local level = data.level or 1
                local format = data.pt_display_format or data.tb_display_format or "streak_level"
                
                if format == "streak_only" then
                    return "~" .. streak
                elseif format == "level_only" then
                    return "Lv" .. level
                elseif format == "streak_level" then
                    return "~" .. streak .. " Lv" .. level
                elseif format == "level_xp" then
                    -- Calculate XP for current level
                    local xp = data.xp or 0
                    local function getXPRequiredForLevel(lvl)
                        local total = 0
                        for l = 2, lvl do
                            total = total + (l * 50) + ((l - 1) * 25)
                        end
                        return total
                    end
                    local xp_for_current = getXPRequiredForLevel(level)
                    local xp_for_next = getXPRequiredForLevel(level + 1)
                    local current_xp = xp - xp_for_current
                    local needed_xp = xp_for_next - xp_for_current
                    return "Lv" .. level .. " XP " .. current_xp .. "/" .. needed_xp
                elseif format == "full" then
                    local today = os.date("%Y-%m-%d")
                    local pages = data.daily_pages and data.daily_pages[today] or 0
                    return "~" .. streak .. " Lv" .. level .. " " .. pages .. "pg"
                else
                    return "~" .. streak .. " Lv" .. level
                end
            end
        end
        return nil
    end)
    if ok and result then
        return result
    end
    return nil
end

-- Hook into Menu.updatePageInfo to add ReadMastery to footer
Menu.updatePageInfo = function(self, select_number)
    -- Build footer config with ReadMastery included
    -- Check if footer_config already exists (from another patch)
    if not self.footer_config then
        self.footer_config = {
            order = {
                "clock",
                "wifi",
                "battery",
                "frontlight",
                "frontlight_warmth",
            },
            wifi_show_disabled = true,
            frontlight_show_off = true,
        }
    end
    
    -- Add readmastery to the order if not already present
    local has_readmastery = false
    if self.footer_config.order then
        for _, item in ipairs(self.footer_config.order) do
            if item == "readmastery" then
                has_readmastery = true
                break
            end
        end
    end
    
    if not has_readmastery then
        table.insert(self.footer_config.order, "readmastery")
    end
    
    -- Register the readmastery text generator if the footer supports custom items
    -- This works with ProjectTitle's genItemText pattern
    if self.genItemText then
        self.genItemText.readmastery = getReadMasteryText
    end
    
    -- Call original function
    updatePageInfo_orig(self, select_number)
end

logger.info("ReadMastery: ProjectTitle footer patch loaded")