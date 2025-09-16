-- ClientInit: ensure critical shared modules are loaded early on client startup
print("[DecryptSkillSys] ClientInit.lua loading shared modules...")

-- Force-load critical shared utilities to avoid load-order issues
local ok, mod = pcall(require, "shared/GVDrive_Utils")
if ok then
    print("[DecryptSkillSys] GVDrive_Utils required successfully in ClientInit")
else
    print("[DecryptSkillSys] WARNING: failed to require GVDrive_Utils in ClientInit: " .. tostring(mod))
end

-- Also ensure LaptopSystem is available
pcall(require, "shared/LaptopSystem")

print("[DecryptSkillSys] ClientInit.lua finished")
-- Client side initialization for DecryptSkillSys

print("[DecryptSkillSys] ClientInit.lua loading...")

-- Ensure core modules are loaded
require("client/TimedActions/LaptopFill")

print("[DecryptSkillSys] ClientInit.lua loaded - all client modules should be active")