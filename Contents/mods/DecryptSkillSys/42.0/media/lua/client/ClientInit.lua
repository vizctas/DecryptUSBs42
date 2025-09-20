-- Client side initialization for DecryptSkillSys (debug prints gated)
-- Use centralized debug utility
pcall(require, "shared/GVDrive_Config")
local GVDebug = pcall(require, "shared/GVDebug") and require("shared/GVDebug") or nil
if GVDebug then GVDebug.debugPrint("ClientInit.lua loading...") end

-- Force-load critical shared modules to avoid load-order issues
pcall(require, "shared/GVDrive_Utils")
pcall(require, "shared/LaptopSystem")

-- Load client modules
require("client/TimedActions/LaptopFill")

if GVDebug then GVDebug.debugPrint("ClientInit.lua loaded - all client modules should be active") end
