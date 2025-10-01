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
    
    -- Cargar nuevos sistemas de mejora
    pcall(require, "shared/LaptopThermalSystem")
    if LaptopThermalSystem then
        print("[Server] LaptopThermalSystem loaded successfully")
    end
    
    pcall(require, "shared/USBSurpriseSystem")
    if USBSurpriseSystem then
        print("[Server] USBSurpriseSystem loaded successfully")
    end
    
    pcall(require, "shared/ContextualMessages")
    if ContextualMessages then
        print("[Server] ContextualMessages loaded successfully")
    end
    
    pcall(require, "shared/NeuralBoostSystem")
    if NeuralBoostSystem then
        print("[Server] NeuralBoostSystem loaded successfully")
    end
    
    pcall(require, "shared/DynamicSoundSystem")
    if DynamicSoundSystem then
        print("[Server] DynamicSoundSystem loaded successfully")
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