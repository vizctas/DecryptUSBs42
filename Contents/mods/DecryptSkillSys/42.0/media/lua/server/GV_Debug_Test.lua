-- Debug test file for DecryptSkillSys
-- This file will help verify that events are working correctly

print("[DecryptSkillSys] Debug test file loaded")

-- Test function to verify zombie death events
local function testZombieDeathEvent()
    print("[DecryptSkillSys] Testing zombie death event registration...")
    
    -- Check if Events system is available
    if not Events then
        print("[DecryptSkillSys] ERROR: Events system not available")
        return false
    end
    
    -- Check if OnZombieDead event exists
    if not Events.OnZombieDead then
        print("[DecryptSkillSys] ERROR: OnZombieDead event not found")
        return false
    end
    
    -- Check if Add method exists
    if not Events.OnZombieDead.Add then
        print("[DecryptSkillSys] ERROR: OnZombieDead.Add method not found")
        return false
    end
    
    print("[DecryptSkillSys] All event systems are available")
    return true
end

-- Test function for sandbox variables
local function testSandboxVars()
    print("[DecryptSkillSys] Testing sandbox variables...")
    
    if not SandboxVars then
        print("[DecryptSkillSys] WARNING: SandboxVars not available")
        return false
    end
    
    if not SandboxVars.GVDrive then
        print("[DecryptSkillSys] WARNING: GVDrive sandbox group not found")
        return false
    end
    
    local gv = SandboxVars.GVDrive
    print(string.format("[DecryptSkillSys] USB Drop Rate: %s", tostring(gv.USB_ZombieDrop_Chance)))
    print(string.format("[DecryptSkillSys] Laptop Drop Rate: %s", tostring(gv.Laptop_ZombieDrop_Chance)))
    print(string.format("[DecryptSkillSys] Elite Drop Rate: %s", tostring(gv.EliteDrive_ZombieDrop_Chance)))
    
    return true
end

-- Simple test zombie death function
local function testZombieDeath(zombie)
    print("[DecryptSkillSys] TEST: Zombie death detected!")
    
    if not zombie then
        print("[DecryptSkillSys] TEST: Zombie is nil")
        return
    end
    
    if not isServer() then
        print("[DecryptSkillSys] TEST: Client side - skipping")
        return
    end
    
    local inventory = zombie:getInventory()
    if not inventory then
        print("[DecryptSkillSys] TEST: No inventory found")
        return
    end
    
    -- Force drop a USB for testing
    inventory:AddItem("GValley.USB_Closed")
    print("[DecryptSkillSys] TEST: Forced USB drop for testing")
end

-- Register test events
Events.OnGameStart.Add(function()
    print("[DecryptSkillSys] Game started - running tests...")
    testZombieDeathEvent()
    testSandboxVars()
end)

-- Register test zombie death event
if Events and Events.OnZombieDead and Events.OnZombieDead.Add then
    Events.OnZombieDead.Add(testZombieDeath)
    print("[DecryptSkillSys] Test zombie death event registered")
else
    print("[DecryptSkillSys] Failed to register test zombie death event")
end

print("[DecryptSkillSys] Debug test file initialization complete")
