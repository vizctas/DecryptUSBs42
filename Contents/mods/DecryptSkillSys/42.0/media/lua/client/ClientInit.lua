-- Client side initialization for DecryptSkillSys (debug prints gated)
pcall(require, "shared/GVDrive_Config")
local DEBUG = (GVDrive_Config and GVDrive_Config.getDebug) and GVDrive_Config.getDebug() or false
local function debugPrint(...)
    if not DEBUG then return end
    print("[DecryptSkillSys][DEBUG]", ...)
end

debugPrint("ClientInit.lua loading...")

-- Force-load critical shared modules to avoid load-order issues
pcall(require, "shared/GVDrive_Utils")
pcall(require, "shared/LaptopSystem")

-- Load client modules
require("client/TimedActions/LaptopFill")

debugPrint("ClientInit.lua loaded - all client modules should be active")
