-- DecryptSkillSys New Rarity System Test Script
-- This script tests if all new items can be spawned correctly

local function testNewRaritySystem()
    print("[DecryptSkillSys] === TESTING NEW RARITY SYSTEM ===")
    
    local player = getPlayer()
    if not player then
        print("[DecryptSkillSys] ERROR: No player found for testing")
        return
    end
    
    local inv = player:getInventory()
    if not inv then
        print("[DecryptSkillSys] ERROR: No inventory found for testing")
        return
    end
    
    print("[DecryptSkillSys] Starting new rarity system test...")
    
    -- Test all USB drives with new rarity system
    local skills = {"Woodwork", "Electricity", "Farming", "Aiming", "Cooking", "Sneak", "Axe", "Fitness", "Doctor", "Survivalist"}
    local rarities = {"Facil", "Moderado", "Dificil"}
    
    local testResults = {
        usbSuccess = 0,
        usbFailed = 0,
        floppySuccess = 0,
        floppyFailed = 0,
        failedItems = {}
    }
    
    -- Test USB drives
    for _, skill in ipairs(skills) do
        for _, rarity in ipairs(rarities) do
            local itemType = "GValley.SkillDrive_" .. skill .. "_" .. rarity
            local item = inv:AddItem(itemType)
            if item then
                testResults.usbSuccess = testResults.usbSuccess + 1
                print("[DecryptSkillSys] ✓ USB " .. skill .. " " .. rarity .. " - SUCCESS")
            else
                testResults.usbFailed = testResults.usbFailed + 1
                table.insert(testResults.failedItems, itemType)
                print("[DecryptSkillSys] ✗ USB " .. skill .. " " .. rarity .. " - FAILED")
            end
        end
    end
    
    -- Test Floppy drives
    for _, skill in ipairs(skills) do
        for _, rarity in ipairs(rarities) do
            local itemType = "GValley.SkillFloppy_" .. skill .. "_" .. rarity
            local item = inv:AddItem(itemType)
            if item then
                testResults.floppySuccess = testResults.floppySuccess + 1
                print("[DecryptSkillSys] ✓ Floppy " .. skill .. " " .. rarity .. " - SUCCESS")
            else
                testResults.floppyFailed = testResults.floppyFailed + 1
                table.insert(testResults.failedItems, itemType)
                print("[DecryptSkillSys] ✗ Floppy " .. skill .. " " .. rarity .. " - FAILED")
            end
        end
    end
    
    -- Test distribution system
    print("[DecryptSkillSys] Testing distribution system...")
    for i = 1, 10 do
        local usbDrive = getRandomSkillDrive("USB")
        local floppyDrive = getRandomSkillDrive("Floppy")
        
        if usbDrive then
            print("[DecryptSkillSys] ✓ Random USB: " .. usbDrive)
        else
            print("[DecryptSkillSys] ✗ Random USB failed")
        end
        
        if floppyDrive then
            print("[DecryptSkillSys] ✓ Random Floppy: " .. floppyDrive)
        else
            print("[DecryptSkillSys] ✗ Random Floppy failed")
        end
    end
    
    -- Print test results
    print("[DecryptSkillSys] === TEST RESULTS ===")
    print("[DecryptSkillSys] USB Drives - Success: " .. testResults.usbSuccess .. ", Failed: " .. testResults.usbFailed)
    print("[DecryptSkillSys] Floppy Drives - Success: " .. testResults.floppySuccess .. ", Failed: " .. testResults.floppyFailed)
    print("[DecryptSkillSys] Total Expected: 60 items (30 USB + 30 Floppy)")
    print("[DecryptSkillSys] Total Success: " .. (testResults.usbSuccess + testResults.floppySuccess))
    print("[DecryptSkillSys] Total Failed: " .. (testResults.usbFailed + testResults.floppyFailed))
    
    if #testResults.failedItems > 0 then
        print("[DecryptSkillSys] FAILED ITEMS:")
        for _, item in ipairs(testResults.failedItems) do
            print("[DecryptSkillSys] - " .. item)
        end
    else
        print("[DecryptSkillSys] ✓ ALL ITEMS CREATED SUCCESSFULLY!")
    end
    
    print("[DecryptSkillSys] === END TEST ===")
end

-- Register command for testing (only for testing purposes)
if getDebug and getDebug() then
    Events.OnKeyPressed.Add(function(key)
        -- Press F9 to run test
        if key == Keyboard.KEY_F9 then
            testNewRaritySystem()
        end
    end)
end

-- Also test on game start in debug mode
Events.OnGameStart.Add(function()
    if getDebug and getDebug() then
        print("[DecryptSkillSys] Debug mode detected. Press F9 to test new rarity system.")
    end
end)