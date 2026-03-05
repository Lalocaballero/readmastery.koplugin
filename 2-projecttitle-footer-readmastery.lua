--[[
    ReadMastery integration with Project: Title footer
    
    This user patch adds ReadMastery stats (streak, level, XP, pages)
    to the Project: Title plugin's footer bar in the file browser.
    
    Installation:
    1. Copy this file to your KOReader patches/ directory
    2. Restart KOReader
    3. Configure display format in ReadMastery > Display > ProjectTitle Footer
    
    Requires: Project: Title plugin
    Requires: ReadMastery plugin
]]

local DataStorage = require("datastorage")
local json = require("json")
local logger = require("logger")
local UIManager = require("ui/uimanager")

-- Cache for ReadMastery data (refreshed on each call)
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

local Menu = require("ui/widget/menu")
local updatePageInfo_orig = Menu.updatePageInfo

Menu.updatePageInfo = function(self, select_number)
    -- Call original (PT stores this as _Menu_updatePageInfo_orig)
    updatePageInfo_orig(self, select_number)
    
    -- If this menu has cur_folder_text, it's ProjectTitle's CoverMenu
    -- Schedule append on next tick AND tick after next to cover both
    -- initial render and pagination scenarios
    if self.cur_folder_text then
        local menu_ref = self
        
        -- First attempt: nextTick (works for initial load, folder navigation)
        UIManager:nextTick(function()
            pcall(function()
                local rm_text = getReadMasteryText()
                if rm_text and menu_ref.cur_folder_text then
                    local current = menu_ref.cur_folder_text.text or ""
                    if current ~= "" then
                        if not current:find(rm_text, 1, true) then
                            menu_ref.cur_folder_text:setText(current .. " · " .. rm_text)
                            -- Force screen refresh so the change is visible
                            UIManager:setDirty(menu_ref, "ui")
                        end
                    else
                        menu_ref.cur_folder_text:setText(rm_text)
                        UIManager:setDirty(menu_ref, "ui")
                    end
                end
            end)
        end)
        
        -- Second attempt: tickAfterNext (backup for pagination where nextTick is too early)
        UIManager:tickAfterNext(function()
            pcall(function()
                local rm_text = getReadMasteryText()
                if rm_text and menu_ref.cur_folder_text then
                    local current = menu_ref.cur_folder_text.text or ""
                    if current ~= "" then
                        if not current:find(rm_text, 1, true) then
                            menu_ref.cur_folder_text:setText(current .. " · " .. rm_text)
                            UIManager:setDirty(menu_ref, "ui")
                        end
                    else
                        menu_ref.cur_folder_text:setText(rm_text)
                        UIManager:setDirty(menu_ref, "ui")
                    end
                end
            end)
        end)
        
        -- Third attempt: short scheduled delay as final fallback
        UIManager:scheduleIn(0.1, function()
            pcall(function()
                local rm_text = getReadMasteryText()
                if rm_text and menu_ref.cur_folder_text then
                    local current = menu_ref.cur_folder_text.text or ""
                    if current ~= "" then
                        if not current:find(rm_text, 1, true) then
                            menu_ref.cur_folder_text:setText(current .. " · " .. rm_text)
                            UIManager:setDirty(menu_ref, "ui")
                        end
                    else
                        menu_ref.cur_folder_text:setText(rm_text)
                        UIManager:setDirty(menu_ref, "ui")
                    end
                end
            end)
        end)
    end
end

logger.info("ReadMastery: ProjectTitle footer patch loaded")