--[[
    ReadMastery integration with Project: Title footer
    
    This user patch adds ReadMastery stats (streak, level, XP, pages)
    to the Project: Title plugin's footer bar in the file browser.
    
    How it works:
    ProjectTitle's CoverMenu:updatePageInfo() calls _Menu_updatePageInfo_orig()
    first, then builds the footer text using a local genItemText table and sets
    it on self.cur_folder_text. This patch wraps Menu.updatePageInfo so that
    when ProjectTitle calls _Menu_updatePageInfo_orig, our wrapper runs.
    We then schedule a very short deferred callback that runs AFTER ProjectTitle's
    updatePageInfo finishes, allowing us to append to cur_folder_text.
    
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

-- We need to hook AFTER ProjectTitle's CoverMenu:updatePageInfo runs.
-- PT's flow: CoverMenu:updatePageInfo -> _Menu_updatePageInfo_orig (our hook) -> PT continues
-- Strategy: In our Menu.updatePageInfo hook, we store a reference to `self`,
-- then schedule a zero-delay callback that appends to cur_folder_text after PT finishes.

local Menu = require("ui/widget/menu")
local updatePageInfo_orig = Menu.updatePageInfo

Menu.updatePageInfo = function(self, select_number)
    -- Call original
    updatePageInfo_orig(self, select_number)
    
    -- Schedule a deferred append to run after the calling function (PT's updatePageInfo) finishes
    -- Use nextTick to ensure it runs after the current call stack completes
    if self.cur_folder_text then
        UIManager:nextTick(function()
            pcall(function()
                local rm_text = getReadMasteryText()
                if rm_text and self.cur_folder_text then
                    local current = self.cur_folder_text.text or ""
                    if current ~= "" then
                        -- Only append if not already present
                        if not current:find(rm_text, 1, true) then
                            self.cur_folder_text:setText(current .. " · " .. rm_text)
                        end
                    else
                        self.cur_folder_text:setText(rm_text)
                    end
                end
            end)
        end)
    end
end

logger.info("ReadMastery: ProjectTitle footer patch loaded")