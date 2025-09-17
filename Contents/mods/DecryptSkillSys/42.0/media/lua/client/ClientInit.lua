-- Client side initialization for DecryptSkillSys
print("[DecryptSkillSys] ClientInit.lua loading...")

-- Force-load critical shared modules to avoid load-order issues
pcall(require, "shared/GVDrive_Utils")
pcall(require, "shared/LaptopSystem")

-- Load client modules
require("client/TimedActions/LaptopFill")

print("[DecryptSkillSys] ClientInit.lua loaded - all client modules should be active")
