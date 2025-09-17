-- DecryptSkillSys New Rarity System Test Script
-- Debug-only helper for validating item registrations

local skills = {"Woodwork", "Electricity", "Farming", "Aiming", "Cooking", "Sneak", "Axe", "Fitness", "Doctor", "Survivalist"}
local rarities = {"Facil", "Moderado", "Dificil"}

local function getRandomSkillDrive(kind)
    local skill = skills[ZombRand(#skills) + 1]
    local rarity = rarities[ZombRand(#rarities) + 1]
    if kind == "Floppy" then
        return "GValley.SkillFloppy_" .. skill .. "_" .. rarity
    end
    return "GValley.SkillDrive_" .. skill .. "_" .. rarity
end

local function addItem(inv, typeName)
    local ok, result = pcall(inv.AddItem, inv, typeName)
    if ok then
        return result
    end
    return nil
end

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

    local results = {
        usbSuccess = 0,
        usbFailed = 0,
        floppySuccess = 0,
        floppyFailed = 0,
        failedItems = {}
    }

    -- USB drives
    for _, skill in ipairs(skills) do
        for _, rarity in ipairs(rarities) do
            local typeName = "GValley.SkillDrive_" .. skill .. "_" .. rarity
            if addItem(inv, typeName) then
                results.usbSuccess = results.usbSuccess + 1
                print(string.format("[DecryptSkillSys] USB %s %s - SUCCESS", skill, rarity))
            else
                results.usbFailed = results.usbFailed + 1
                table.insert(results.failedItems, typeName)
                print(string.format("[DecryptSkillSys] USB %s %s - FAILED", skill, rarity))
            end
        end
    end

    -- Floppy drives
    for _, skill in ipairs(skills) do
        for _, rarity in ipairs(rarities) do
            local typeName = "GValley.SkillFloppy_" .. skill .. "_" .. rarity
            if addItem(inv, typeName) then
                results.floppySuccess = results.floppySuccess + 1
                print(string.format("[DecryptSkillSys] Floppy %s %s - SUCCESS", skill, rarity))
            else
                results.floppyFailed = results.floppyFailed + 1
                table.insert(results.failedItems, typeName)
                print(string.format("[DecryptSkillSys] Floppy %s %s - FAILED", skill, rarity))
            end
        end
    end

    print("[DecryptSkillSys] Testing distribution helpers...")
    for _ = 1, 10 do
        local usbDrive = getRandomSkillDrive("USB")
        local floppyDrive = getRandomSkillDrive("Floppy")
        print("[DecryptSkillSys] Random USB: " .. tostring(usbDrive))
        print("[DecryptSkillSys] Random Floppy: " .. tostring(floppyDrive))
    end

    print("[DecryptSkillSys] === TEST RESULTS ===")
    print(string.format("[DecryptSkillSys] USB Drives - Success: %d, Failed: %d", results.usbSuccess, results.usbFailed))
    print(string.format("[DecryptSkillSys] Floppy Drives - Success: %d, Failed: %d", results.floppySuccess, results.floppyFailed))
    print("[DecryptSkillSys] Total Expected: 60 items (30 USB + 30 Floppy)")
    print(string.format("[DecryptSkillSys] Total Success: %d", results.usbSuccess + results.floppySuccess))
    print(string.format("[DecryptSkillSys] Total Failed: %d", results.usbFailed + results.floppyFailed))

    if #results.failedItems > 0 then
        print("[DecryptSkillSys] FAILED ITEMS:")
        for _, typeName in ipairs(results.failedItems) do
            print("[DecryptSkillSys] - " .. typeName)
        end
    else
        print("[DecryptSkillSys] ALL ITEMS CREATED SUCCESSFULLY!")
    end

    print("[DecryptSkillSys] === END TEST ===")
end

if getDebug and getDebug() then
    Events.OnKeyPressed.Add(function(key)
        if key == Keyboard.KEY_F9 then
            testNewRaritySystem()
        end
    end)

    Events.OnGameStart.Add(function()
        print("[DecryptSkillSys] Debug mode detected. Press F9 to test the rarity system.")
    end)
end
