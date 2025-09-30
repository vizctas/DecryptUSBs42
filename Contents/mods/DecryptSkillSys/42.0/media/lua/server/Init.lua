-- Basic server init logging for DecryptSkillSys
-- SIMPLIFIED VERSION - uses new native PZ approach

local DEBUG = true
pcall(require, "shared/GVDrive_Config")
if GVDrive_Config and GVDrive_Config.getDebug then
    DEBUG = GVDrive_Config.getDebug()
end

local ok_debug, GVDebug = pcall(require, "shared/GVDebug")
if not ok_debug or not GVDebug then
    GVDebug = { debugPrint = function(...) end, testPrint = function(...) end }
end

-- SIMPLIFIED INIT: Just load the simplified loader
local function initMod()
    GVDebug.debugPrint("🚀 Starting simplified mod initialization...")
    -- The simplified loader (GVLoaderSimple) was removed to avoid recursive/erroneous requires.
    -- Core systems will be loaded via explicit requires further down; this avoids noisy pcall failures.
    GVDebug.debugPrint("ℹ️ GVLoaderSimple not present; using direct loading of core systems")
    
    GVDebug.debugPrint("🎯 Initialization complete - using native PZ systems")
end

-- Register simplified init
if Events and Events.OnServerStarted then
    Events.OnServerStarted.Add(initMod)
elseif Events and Events.OnGameBoot then  
    Events.OnGameBoot.Add(initMod)
else
    -- Fallback: run immediately
    initMod()
end

do
GVDebug.debugPrint("Simplified Init.lua loaded")


