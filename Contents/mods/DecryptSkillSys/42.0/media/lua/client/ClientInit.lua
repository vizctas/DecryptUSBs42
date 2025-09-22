-- Client side initialization for DecryptSkillSys (debug prints gated)
-- Use centralized debug utility
pcall(require, "shared/GVDrive_Config")
local GVDebug = pcall(require, "shared/GVDebug") and require("shared/GVDebug") or nil
if GVDebug then GVDebug.debugPrint("ClientInit.lua loading...") end

-- Force-load critical shared modules to avoid load-order issues
pcall(require, "shared/GVDrive_Utils")
pcall(require, "shared/LaptopSystem")

-- PZ auto-loads client modules, verify MinigameSystem availability
print("[DecryptSkillSys][DEBUG] ClientInit: Checking MinigameSystem availability...")
if MinigameConfig then
    print("[DecryptSkillSys][DEBUG] ClientInit: MinigameConfig is available")
else
    print("[DecryptSkillSys][ERROR] ClientInit: MinigameConfig is NOT available - loading manually")
    local success, err = pcall(dofile, "MinigameSystem_Config.lua")
    if success then
        print("[DecryptSkillSys][DEBUG] ClientInit: MinigameConfig loaded manually")
    else
        print("[DecryptSkillSys][ERROR] ClientInit: Failed to load MinigameConfig: " .. tostring(err))
    end
end

if MinigameController then
    print("[DecryptSkillSys][DEBUG] ClientInit: MinigameController is available")
    -- Initialize the controller
    MinigameController.initialize()
else
    print("[DecryptSkillSys][ERROR] ClientInit: MinigameController is NOT available - loading manually")
    local success, err = pcall(dofile, "MinigameSystem_Controller.lua")
    if success then
        print("[DecryptSkillSys][DEBUG] ClientInit: MinigameController loaded manually")
        if MinigameController and MinigameController.initialize then
            MinigameController.initialize()
        end
    else
        print("[DecryptSkillSys][ERROR] ClientInit: Failed to load MinigameController: " .. tostring(err))
    end
end

-- Load MinigameWindow and related modules manually if not auto-loaded
local minigameModules = {
    "MinigameSystem_Window.lua",
    "MinigameSystem_SequenceBreaker.lua", 
    "MinigameSystem_DifficultyScaler.lua",
    "MinigameSystem_TimerSystem.lua",
    "MinigameSystem_FeedbackSystem.lua"
}

for _, moduleFile in ipairs(minigameModules) do
    local moduleName = moduleFile:gsub("%.lua$", ""):gsub("MinigameSystem_", "")
    if _G[moduleName] then
        print("[DecryptSkillSys][DEBUG] ClientInit: " .. moduleName .. " is available")
    else
        print("[DecryptSkillSys][ERROR] ClientInit: " .. moduleName .. " is NOT available - loading manually")
        local success, err = pcall(dofile, moduleFile)
        if success then
            print("[DecryptSkillSys][DEBUG] ClientInit: " .. moduleName .. " loaded manually")
        else
            print("[DecryptSkillSys][ERROR] ClientInit: Failed to load " .. moduleName .. ": " .. tostring(err))
        end
    end
end

-- Final verification
print("[DecryptSkillSys][DEBUG] ClientInit: Final module verification...")
if MinigameWindow then
    print("[DecryptSkillSys][DEBUG] ClientInit: MinigameWindow is available")
else
    print("[DecryptSkillSys][ERROR] ClientInit: MinigameWindow is NOT available")
end

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

-- Load TimedActions with error handling
print("[DecryptSkillSys][DEBUG] ClientInit: Loading TimedActions...")
local laptopSuccess, laptopError = pcall(require, "client/TimedActions/LaptopFill")
if laptopSuccess then
    print("[DecryptSkillSys][DEBUG] ClientInit: LaptopFill loaded successfully")
else
    print("[DecryptSkillSys][ERROR] ClientInit: Failed to load LaptopFill: " .. tostring(laptopError))
end

if GVDebug then GVDebug.debugPrint("ClientInit.lua loaded - all client modules should be active") end
