--[[
    ReadMastery integration with Project: Title footer
    
    This user patch adds ReadMastery stats (streak, level, XP, pages)
    to the Project: Title plugin's footer bar in the file browser.
    
    How it works:
    We hook Menu.updatePageInfo. On the first call where we detect that
    CoverMenu has overridden updatePageInfo (meaning ProjectTitle is active),
    we wrap CoverMenu's version so our code runs AFTER PT finishes setting
    cur_folder_text. This ensures ReadMastery text persists across pagination.
    
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
local function appendToFooter(self)
    pcall(function()
        if self.cur_folder_text then
            local rm_text = getReadMasteryText()
            if rm_text then
                local current = self.cur_folder_text.text or ""
                if current ~= "" then
                    if not current:find(rm_text, 1, true) then
                        self.cur_folder_text:setText(current .. " · " .. rm_text)
                    end
                else
                    self.cur_folder_text:setText(rm_text)
                end
            end
        end
    end)
end

-- Strategy: Hook Menu.updatePageInfo. When PT's CoverMenu overrides updatePageInfo,
-- it stores the original as _Menu_updatePageInfo_orig and calls it inside its own
-- CoverMenu:updatePageInfo. We can't hook CoverMenu directly at patch load time
-- (it doesn't exist yet). Instead, we use a lazy approach:
--
-- On each call to our hooked Menu.updatePageInfo, we check if the calling object's
-- class has its own updatePageInfo (i.e., CoverMenu). If so, we wrap THAT method
-- once, so our append code runs AFTER CoverMenu:updatePageInfo completes.

local Menu = require("ui/widget/menu")
local updatePageInfo_orig = Menu.updatePageInfo
local _covermenu_hooked = false

Menu.updatePageInfo = function(self, select_number)
    -- Call the real original Menu.updatePageInfo
    updatePageInfo_orig(self, select_number)
    
    -- Lazy-hook CoverMenu's updatePageInfo if not already done
    -- We detect CoverMenu by checking if the object's metatable has its own
    -- updatePageInfo that differs from Menu.updatePageInfo
    if not _covermenu_hooked then
        local mt = getmetatable(self)
        if mt and mt.__index then
            local class = mt.__index
            -- Check if this class has its own updatePageInfo (CoverMenu does)
            if rawget(class, "updatePageInfo") and rawget(class, "updatePageInfo") ~= Menu.updatePageInfo then
                local covermenu_updatePageInfo_orig = rawget(class, "updatePageInfo")
                -- Wrap CoverMenu's updatePageInfo
                class.updatePageInfo = function(cm_self, cm_select_number)
                    -- Call CoverMenu's original updatePageInfo (which calls _Menu_updatePageInfo_orig internally)
                    covermenu_updatePageInfo_orig(cm_self, cm_select_number)
                    -- NOW we run AFTER PT has finished setting cur_folder_text
                    appendToFooter(cm_self)
                end
                _covermenu_hooked = true
                -- Also append for this first call since we just hooked
                appendToFooter(self)
                logger.info("ReadMastery: Hooked CoverMenu.updatePageInfo for footer integration")
            end
        end
    end
end

logger.info("ReadMastery: ProjectTitle footer patch loaded")