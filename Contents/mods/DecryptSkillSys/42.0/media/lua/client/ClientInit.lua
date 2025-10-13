-- Client side initialization for DecryptSkillSys (debug prints gated)
-- Use centralized debug utility
pcall(require, "shared/GVDrive_Config")
local GVDebug = pcall(require, "shared/GVDebug") and require("shared/GVDebug") or nil
if GVDebug then GVDebug.debugPrint("ClientInit.lua loading...") end

-- Force-load critical shared modules to avoid load-order issues
pcall(require, "shared/GVDrive_Utils")
pcall(require, "shared/LaptopSystem")

-- Load client modules
-- Ensure modern hierarchical context menu loads first to set global flags and register its handler
print("[DecryptSkillSys][DEBUG] ClientInit: Attempting to load DecryptDrivesContextMenu...")
local success, modernMenu = pcall(require, "client/DecryptDrivesContextMenu")
if success and modernMenu then
    print("[DecryptSkillSys][DEBUG] ClientInit: DecryptDrivesContextMenu loaded successfully")
    _G.DecryptDrivesContextMenu_MODERN = true  -- Ensure global flag is set
else
    print("[DecryptSkillSys][ERROR] ClientInit: Failed to load DecryptDrivesContextMenu: " .. tostring(modernMenu))
end

require("client/TimedActions/LaptopFill")

-- Load all MiniGames
print("[DecryptSkillSys][DEBUG] ClientInit: Loading minigames...")
pcall(require, "client/MiniGameUI")
pcall(require, "client/MiniGameFallout")
pcall(require, "client/MiniGameCircuit")
pcall(require, "client/MiniGamePacket")
pcall(require, "client/MiniGameEncryption")
pcall(require, "client/MiniGameLaser")
pcall(require, "client/MiniGameHexFlood")
pcall(require, "client/MiniGameBitShift")
pcall(require, "client/MiniGameBufferDefense")
pcall(require, "client/MiniGameRewardHelper")
print("[DecryptSkillSys][DEBUG] ClientInit: Minigames loaded")

-- Load Laptop Events System
pcall(require, "shared/LaptopEvents")
if LaptopEvents then
    print("[Client] LaptopEvents system loaded successfully")
end

-- Load new enhancement systems
pcall(require, "shared/LaptopThermalSystem")
if LaptopThermalSystem then
    print("[Client] LaptopThermalSystem loaded successfully")
end

pcall(require, "shared/USBSurpriseSystem")
if USBSurpriseSystem then
    print("[Client] USBSurpriseSystem loaded successfully")
end

pcall(require, "shared/ContextualMessages")
if ContextualMessages then
    print("[Client] ContextualMessages system loaded successfully")
end

pcall(require, "shared/NeuralBoostSystem")
if NeuralBoostSystem then
    print("[Client] NeuralBoostSystem loaded successfully")
end

pcall(require, "shared/DynamicSoundSystem")
if DynamicSoundSystem then
    print("[Client] DynamicSoundSystem loaded successfully")
end

if GVDebug then GVDebug.debugPrint("ClientInit.lua loaded - all client modules should be active") end
