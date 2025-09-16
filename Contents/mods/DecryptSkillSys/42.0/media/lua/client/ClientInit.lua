-- ClientInit: ensure critical shared modules are loaded early on client startup
print("[DecryptSkillSys] ClientInit.lua loading shared modules...")

-- Force-load critical shared utilities to avoid load-order issues
pcall(require, "shared/GVDrive_Utils")
pcall(require, "shared/LaptopSystem")

print("[DecryptSkillSys] ClientInit.lua finished")
-- Client side initialization for DecryptSkillSys

print("[DecryptSkillSys] ClientInit.lua loading...")

-- Ensure core modules are loaded
require("client/TimedActions/LaptopFill")

-- Load and initialize the new Laptop Battery UI
require("client/UI/LaptopBatteryUI")

print("[DecryptSkillSys] ClientInit.lua loaded - all client modules should be active")
