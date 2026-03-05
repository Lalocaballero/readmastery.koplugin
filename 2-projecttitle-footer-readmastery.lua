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

-- Helper to append ReadMastery text to cur_folder_text
local function appendToFooter(menu_instance)
    pcall(function()
        if menu_instance and menu_instance.cur_folder_text then
            local rm_text = getReadMasteryText()
            if rm_text then
                local current = menu_instance.cur_folder_text.text or ""
                if current ~= "" then
                    if not current:find(rm_text, 1, true) then
                        menu_instance.cur_folder_text:setText(current .. " · " .. rm_text)
                    end
                else
                    menu_instance.cur_folder_text:setText(rm_text)
                end
            end
        end
    end)
end

-- Hook strategy:
-- We wrap Menu.updatePageInfo. PT stores this as _Menu_updatePageInfo_orig.
-- When PT's CoverMenu:updatePageInfo calls _Menu_updatePageInfo_orig, our code runs.
-- We save a reference to the menu instance.
-- Then we ALSO hook FileManager events that trigger after updatePageInfo completes.

local Menu = require("ui/widget/menu")
local updatePageInfo_orig = Menu.updatePageInfo

-- Keep track of the last CoverMenu instance we saw
local _last_menu_instance = nil

Menu.updatePageInfo = function(self, select_number)
    -- Call the real original
    updatePageInfo_orig(self, select_number)
    
    -- Remember this instance if it has cur_folder_text (meaning it's PT's CoverMenu)
    if self.cur_folder_text then
        _last_menu_instance = self
    end
end

-- Hook FileManager events that fire after the menu is fully rendered.
-- FileManager:onPathChanged fires on folder navigation.
-- We also hook FileManager:onResume and the initial onPathChanged.
local FileManager = require("apps/filemanager/filemanager")

local orig_onPathChanged = FileManager.onPathChanged
if orig_onPathChanged then
    FileManager.onPathChanged = function(self, path)
        local result = orig_onPathChanged(self, path)
        -- After path change, append to footer
        if _last_menu_instance then
            appendToFooter(_last_menu_instance)
        end
        return result
    end
end

-- Also hook the file_chooser's onFileSelect and page navigation
-- by wrapping FileChooser:refreshPath which is called on every pagination
local FileChooser = require("ui/widget/filechooser")
local orig_refreshPath = FileChooser.refreshPath

if orig_refreshPath then
    FileChooser.refreshPath = function(self, ...)
        local result = orig_refreshPath(self, ...)
        -- After refresh (pagination, folder change), append to footer
        if _last_menu_instance then
            appendToFooter(_last_menu_instance)
        end
        return result
    end
end

logger.info("ReadMastery: ProjectTitle footer patch loaded")