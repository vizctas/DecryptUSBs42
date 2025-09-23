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

if GVDebug then GVDebug.debugPrint("ClientInit.lua loaded - all client modules should be active") end
