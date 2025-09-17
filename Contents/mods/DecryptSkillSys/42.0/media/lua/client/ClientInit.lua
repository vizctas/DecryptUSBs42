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

-- Load and initialize the new Laptop Battery Widget (replacing old UI)
require("client/UI/LaptopBatteryWidget")

-- Test function for the widget
local function testLaptopWidget()
    print("[DecryptSkillSys] Testing laptop widget...")
    
    local player = getPlayer()
    if not player then
        print("[DecryptSkillSys] No player found for test")
        return
    end
    
    -- Test the widget with a mock laptop
    if showLaptopBatteryWidget then
        print("[DecryptSkillSys] showLaptopBatteryWidget function is available!")
        -- Create a quick test
        showLaptopBatteryWidget(nil) -- Test with no laptop (should handle gracefully)
    else
        print("[DecryptSkillSys] ERROR: showLaptopBatteryWidget function not found!")
    end
end

-- Add keybind for testing (F10)
Events.OnKeyPressed.Add(function(key)
    if key == Keyboard.KEY_F10 then
        testLaptopWidget()
    end
end)

print("[DecryptSkillSys] ClientInit.lua loaded - all client modules should be active")
print("[DecryptSkillSys] Press F10 to test the laptop widget!")
