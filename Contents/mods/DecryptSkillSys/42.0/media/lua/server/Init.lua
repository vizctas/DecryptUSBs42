-- Basic server init logging for DecryptSkillSys
-- SIMPLIFIED VERSION - uses new native PZ approach

local DEBUG = false
pcall(require, "shared/GVDrive_Config")
if GVDrive_Config and GVDrive_Config.getDebug then
    DEBUG = GVDrive_Config.getDebug()
end

local ok_debug, GVDebug = pcall(require, "shared/GVDebug")
if not ok_debug or not GVDebug then
    GVDebug = { debugPrint = function(...) end, testPrint = function(...) end }
end

local function initMod()
    GVDebug.debugPrint("Starting simplified mod initialization...")

    -- Cargar sistema de eventos de laptop
    pcall(require, "shared/LaptopEvents")
    if LaptopEvents then
        print("[Server] LaptopEvents system loaded successfully")
    end
end

-- Register simplified init
if Events and Events.OnServerStarted then
    Events.OnServerStarted.Add(initMod)
elseif Events and Events.OnGameBoot then  
    Events.OnGameBoot.Add(initMod)
else
    initMod()
end