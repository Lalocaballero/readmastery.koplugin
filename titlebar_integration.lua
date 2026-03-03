--[[
    ReadMastery integration with Title Bar Patch
    Adds streak/level display to the file manager title bar
    
    Requires: Title Bar Patch (2-filemanager-titlebar.lua or similar)
]]

local logger = require("logger")

local TitleBarIntegration = {}

-- Store reference to core
TitleBarIntegration.core = nil
TitleBarIntegration.initialized = false

-- Check if title bar patch is installed
function TitleBarIntegration:isAvailable()
    local lfs = require("libs/libkoreader-lfs")
    local patch_paths = {
        "patches/2-filemanager-titlebar.lua",
        "patches/2-filemanager-title-bar.lua",
        "patches/2-pt-titlebar.lua",
    }
    
    for _, path in ipairs(patch_paths) do
        if lfs.attributes(path, "mode") == "file" then
            return true
        end
    end
    
    return false
end

-- Initialize integration
function TitleBarIntegration:init(core)
    self.core = core
    
    if not self:isAvailable() then
        logger.dbg("ReadMastery: Title Bar Patch not found, skipping integration")
        return false
    end
    
    -- Don't hook anything - just make data available
    -- The title bar patch can call TitleBarIntegration:getDisplayText() if needed
    self.initialized = true
    
    logger.info("ReadMastery: Title Bar integration successful")
    return true
end

-- Format text based on format string
function TitleBarIntegration:formatText(format)
    if not self.core then return "" end
    
    local streak = self.core:getStreak() or 0
    local level = self.core:getLevel() or 1
    
    if format == "streak_only" then
        return "~" .. streak
    elseif format == "level_only" then
        return "Lv" .. level
    elseif format == "streak_level" then
        return "~" .. streak .. " Lv" .. level
    elseif format == "level_xp" then
        local xp_info = self.core:getXPForNextLevel()
        return "Lv" .. level .. " XP " .. xp_info.current .. "/" .. xp_info.needed
    elseif format == "full" then
        local pages = self.core:getDailyPages() or 0
        return "~" .. streak .. " Lv" .. level .. " " .. pages .. "pg"
    else
        return "~" .. streak .. " Lv" .. level
    end
end

-- Get formatted display text for title bar (can be called by other patches)
function TitleBarIntegration:getDisplayText()
    local format = self.core and self.core.data.tb_display_format or "streak_level"
    return self:formatText(format)
end

-- Get formatted display text for ProjectTitle footer
function TitleBarIntegration:getFooterDisplayText()
    local format = self.core and self.core.data.pt_display_format or self.core.data.tb_display_format or "streak_level"
    return self:formatText(format)
end

-- Get individual stats (for patches that want specific data)
function TitleBarIntegration:getStreak()
    if not self.core then return 0 end
    return self.core:getStreak() or 0
end

function TitleBarIntegration:getLevel()
    if not self.core then return 1 end
    return self.core:getLevel() or 1
end

function TitleBarIntegration:getPagesToday()
    if not self.core then return 0 end
    return self.core:getDailyPages() or 0
end

function TitleBarIntegration:getFreezeTokens()
    if not self.core then return 0 end
    return self.core:getFreezeTokens() or 0
end

-- Cleanup
function TitleBarIntegration:cleanup()
    self.initialized = false
    logger.dbg("ReadMastery: Title Bar cleanup called")
end

return TitleBarIntegration