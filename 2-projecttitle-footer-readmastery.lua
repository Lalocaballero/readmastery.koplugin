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

-- Hook into Menu.updatePageInfo to append ReadMastery text AFTER footer renders
Menu.updatePageInfo = function(self, select_number)
    -- Call original function first (let ProjectTitle render its footer)
    updatePageInfo_orig(self, select_number)
    
    -- Now try to append ReadMastery text to the rendered footer
    local rm_text = getReadMasteryText()
    if rm_text then
        pcall(function()
            -- Try to find and modify the page info text widget
            -- KOReader's Menu uses page_info_text (TextWidget with .text property)
            if self.page_info_text and self.page_info_text.text then
                local current = self.page_info_text.text
                -- Only append if not already present
                if not current:find(rm_text, 1, true) then
                    self.page_info_text:setText(current .. " · " .. rm_text)
                end
            -- ProjectTitle may use a different structure - try page_info
            elseif self.page_info and self.page_info_text then
                local current = self.page_info_text.text or ""
                if current ~= "" and not current:find(rm_text, 1, true) then
                    self.page_info_text:setText(current .. " · " .. rm_text)
                end
            end
        end)
    end
end

logger.info("ReadMastery: ProjectTitle footer patch loaded")