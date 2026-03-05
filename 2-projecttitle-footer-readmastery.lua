--[[
    ReadMastery - ProjectTitle Footer Integration
    
    NOTE: This patch file is NO LONGER NEEDED as of v1.3.0.
    
    The ProjectTitle footer integration is now built directly into the
    ReadMastery plugin. Simply install ReadMastery and it will automatically
    detect ProjectTitle and add stats to the footer.
    
    You can safely DELETE this file from your patches/ directory.
    If you leave it here, it will do nothing (no-op).
    
    Configure the display format in:
    ReadMastery > Display > ProjectTitle Footer
]]

-- No-op: PT footer integration is now handled by the ReadMastery plugin directly.
-- This file exists only for backwards compatibility.
local logger = require("logger")
logger.info("ReadMastery: PT footer patch is deprecated - integration is now built into the plugin")