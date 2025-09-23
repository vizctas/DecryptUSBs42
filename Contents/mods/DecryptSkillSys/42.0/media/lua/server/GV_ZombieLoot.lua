-- Minimal server-side zombie loot for USBs and skill drives
-- Adds a simple, sandbox-aware drop on zombie death for testing/production

-- Use central config for DEBUG
pcall(require, "shared/GVDrive_Utils")
pcall(require, "shared/GVDrive_Config")

local ok_debug, GVDebug = pcall(require, "shared/GVDebug")
if not ok_debug or not GVDebug then
    GVDebug = { debugPrint = function(...) end, testPrint = function(...) end }
end

-- Local wrappers so existing unqualified `testPrint(...)` and `debugPrint(...)` calls
-- resolve to the centralized `GVDebug` implementation (no-op if missing).
local function debugPrint(...)
    if GVDebug and GVDebug.debugPrint then
        GVDebug.debugPrint(...)
    end
end
local function testPrint(...)
    if GVDebug and GVDebug.testPrint then
        GVDebug.testPrint(...)
    end
end

local DEBUG = false
if GVDrive_Config and GVDrive_Config.getDebug then
    DEBUG = GVDrive_Config.getDebug()
end

local function safeNum(v, def)
    if v == nil then return def end
    local n = tonumber(v)
    return n or def
end

-- COMPREHENSIVE ITEM CONFIGURATION - Auto-updatable
-- Add new items here and they will automatically be included in drops
local AVAILABLE_ITEMS = {
    skills = {
        "Woodwork", "Electricity", "Farming", "Aiming", "Cooking", "Sneak",
        "Axe", "Fitness", "Doctor", "Survivalist", "Mechanics", "Tailoring",
        "Maintenance", "SmallBlade", "LongBlade", "SmallBlunt", "LongBlunt",
        "Spear", "Trapping", "Fishing", "Sprinting", "Strength", "Nimble", "Lightfoot"
    },
    rarities = {"Facil", "Moderado", "Dificil"},
    laptops = {
        "GValley.AsusZephLaptopClosed",
        "GValley.Laptop90sClosed", 
        "GValley.PBIBM_LP90Closed"
    },
    eliteTypes = {"Strength", "Endurance", "Capacity", "Speed", "Luck"},
    antivirusTypes = {
        "GValley.Antivirus_Norton",
        "GValley.Antivirus_Kaspersky", 
        "GValley.Antivirus_McAfee",
        "GValley.Antivirus_MalwareBytes"
    }
}
-- Modern item spawning function with comprehensive item support
local function spawnCorrectItem(zombie, itemType)
    GVDebug.testPrint("Attempting to spawn", itemType, "...")
    local itemToSpawn = nil
    
    if itemType == "USB" then
        -- Spawn skill-specific USB drives from ALL available skills
        local skill = AVAILABLE_ITEMS.skills[ZombRand(#AVAILABLE_ITEMS.skills) + 1]
        local rarity = AVAILABLE_ITEMS.rarities[ZombRand(#AVAILABLE_ITEMS.rarities) + 1]
        itemToSpawn = string.format("GValley.SkillDrive_%s_%s", skill, rarity)
        GVDebug.testPrint("Selected skill:", skill, "rarity:", rarity, "full item:", itemToSpawn)
        GVDebug.testPrint("Available rarities:", table.concat(AVAILABLE_ITEMS.rarities, ", "))
        
    elseif itemType == "Laptop" then
        -- Spawn laptops from available laptop types
        itemToSpawn = AVAILABLE_ITEMS.laptops[ZombRand(#AVAILABLE_ITEMS.laptops) + 1]
        
    elseif itemType == "Elite" then
        -- Spawn elite drives from available elite types
        local eliteType = AVAILABLE_ITEMS.eliteTypes[ZombRand(#AVAILABLE_ITEMS.eliteTypes) + 1]
        itemToSpawn = string.format("GValley.EliteDrive_%s", eliteType)
        
    elseif itemType == "Antivirus" then
        -- Spawn antivirus items from available antivirus types
        itemToSpawn = AVAILABLE_ITEMS.antivirusTypes[ZombRand(#AVAILABLE_ITEMS.antivirusTypes) + 1]
    end
    
    if not itemToSpawn then
        GVDebug.testPrint("No item determined for type:", itemType)
        return
    end
    
    GVDebug.testPrint("Selected item:", itemToSpawn)
    
    -- Try corpse inventory first, then ground
    local spawned = false
    local ok, err = pcall(function()
        if zombie and zombie.getInventory then
            local inv = zombie:getInventory()
            if inv and inv.AddItem then
                inv:AddItem(itemToSpawn)
                spawned = true
                testPrint("✅ Successfully placed", itemToSpawn, "into zombie inventory")
                GVDebug.testPrint("✅ Successfully placed", itemToSpawn, "into zombie inventory")
            end
        end
    end)
    
    if not ok then
                GVDebug.testPrint("Error in inventory placement:", tostring(err))
    end
    
    -- Fallback to ground
    if not spawned then
        local sq = zombie and zombie:getCurrentSquare()
        if sq then
            local ok2, err2 = pcall(function()
                sq:AddWorldInventoryItem(itemToSpawn, 0, 0, 0)
            end)
            if ok2 then
                GVDebug.testPrint("Successfully spawned", itemToSpawn, "on ground (fallback)")
            else
                GVDebug.testPrint("Error spawning on ground:", tostring(err2))
            end
        else
            testPrint("❌ Cannot spawn item: no square and inventory placement failed")
            GVDebug.testPrint("❌ Cannot spawn item: no square and inventory placement failed")
        end
    end
end

-- Main zombie death handler with comprehensive drop system
local function onZombieDeadModern(zombie)
    GVDebug.testPrint("ZOMBIE KILLED! Handler executing...")
    if not zombie then 
        testPrint("❌ zombie is nil, returning")
    GVDebug.testPrint("❌ zombie is nil, returning")
        return 
    end
    if instanceof(zombie, "IsoPlayer") then 
        testPrint("❌ zombie is IsoPlayer, returning")
    GVDebug.testPrint("❌ zombie is IsoPlayer, returning")
        return 
    end
    
    GVDebug.testPrint("Valid zombie killed, checking drops...")

    -- Multiple drop attempts: USB/Laptop/Elite/Antivirus
    local dropAttempts = {
        {type = "USB", chance_key = "USB_ZombieDrop_Chance", default = 10.0},
        {type = "Laptop", chance_key = "Laptop_ZombieDrop_Chance", default = 5.0},
        {type = "Elite", chance_key = "EliteDrive_ZombieDrop_Chance", default = 2.0},
        {type = "Antivirus", chance_key = "Antivirus_ZombieDrop_Chance", default = 8.0}
    }

    for _, attempt in ipairs(dropAttempts) do
        local chancePercent = attempt.default
        GVDebug.testPrint("Getting sandbox value for", attempt.chance_key)
        if GVDrive_Utils and GVDrive_Utils.getSandboxPercent then
            local raw = GVDrive_Utils.getSandboxPercent(attempt.chance_key, attempt.default)
            chancePercent = raw / 100.0
            testPrint("getSandboxPercent returned:", raw, "converted to:", chancePercent)
            GVDebug.testPrint("getSandboxPercent returned:", raw, "converted to:", chancePercent)
        end

        local roll = ZombRand(0, 10000) / 100.0
        local threshold = chancePercent * 100.0
        GVDebug.testPrint(string.format("%s drop roll: %.2f vs threshold: %.2f - %s", attempt.type, roll, threshold, roll < threshold and "SUCCESS" or "FAILED"))
        
        if roll < threshold then
            spawnCorrectItem(zombie, attempt.type)
        end
    end
end

GVDebug.debugPrint("GV_ZombieLoot.lua modern handler defined")

-- EXPANSION HELPER: Add new items here and they'll automatically be included in drops
-- TO ADD A NEW SKILL: Add to AVAILABLE_ITEMS.skills array
-- TO ADD A NEW LAPTOP: Add to AVAILABLE_ITEMS.laptops array  
-- TO ADD A NEW ELITE TYPE: Add to AVAILABLE_ITEMS.eliteTypes array
-- TO ADD A NEW ANTIVIRUS: Add to AVAILABLE_ITEMS.antivirusTypes array
-- The system will automatically pick from all available options

local function getItemStats()
    local stats = {
        totalSkillDrives = #AVAILABLE_ITEMS.skills * #AVAILABLE_ITEMS.rarities,
        totalLaptops = #AVAILABLE_ITEMS.laptops,
        totalEliteTypes = #AVAILABLE_ITEMS.eliteTypes, 
        totalAntivirusTypes = #AVAILABLE_ITEMS.antivirusTypes
    }
    stats.totalItems = stats.totalSkillDrives + stats.totalLaptops + stats.totalEliteTypes + stats.totalAntivirusTypes
    return stats
end

GVDebug.testPrint("ITEM CONFIGURATION LOADED:")
local stats = getItemStats()
GVDebug.testPrint(string.format("   • %d Skills × %d Rarities = %d Skill Drives", #AVAILABLE_ITEMS.skills, #AVAILABLE_ITEMS.rarities, stats.totalSkillDrives))
GVDebug.testPrint(string.format("   • %d Laptop Types", stats.totalLaptops))
GVDebug.testPrint(string.format("   • %d Elite Drive Types", stats.totalEliteTypes))
GVDebug.testPrint(string.format("   • %d Antivirus Types", stats.totalAntivirusTypes))
GVDebug.testPrint(string.format("   TOTAL AVAILABLE ITEMS: %d", stats.totalItems))

-- Hook combined attempt: all modern items in one streamlined function
local function onZombieDeadCombined(zombie)
    GVDebug.testPrint("Combined zombie death handler called")
    pcall(onZombieDeadModern, zombie)
    GVDebug.testPrint("Combined handler complete")
end

-- FINAL VERIFICATION: Register on server or single-player with comprehensive logging
local function registerZombieHandler()
    local registered = false
    testPrint("=== REGISTERING ZOMBIE HANDLER - FINAL VERIFICATION ===")
    GVDebug.testPrint("=== REGISTERING ZOMBIE HANDLER - FINAL VERIFICATION ===")
    
    local canRegister = false
    local contextInfo = ""
    pcall(function()
        canRegister = isServer() or not isClient()
        if isServer and isServer() then
            contextInfo = "SERVER"
        elseif isClient and not isClient() then
            contextInfo = "SINGLE_PLAYER"
        else
            contextInfo = "CLIENT_ONLY"
        end
    end)
    GVDebug.testPrint("Context check - canRegister:", canRegister, "contextInfo:", contextInfo)

    if canRegister then
        if Events and Events.OnZombieDead and Events.OnZombieDead.Add then
            Events.OnZombieDead.Add(onZombieDeadCombined)
            registered = true
            GVDebug.testPrint("SUCCESS: GV_ZombieLoot.lua registered combined OnZombieDead handler (" .. contextInfo .. ")")
            GVDebug.testPrint("VERIFICATION: Handler function exists:", type(onZombieDeadCombined))
            
            -- Test sandbox access immediately
            local testSandbox = (SandboxVars and SandboxVars.GVDrive) or {}
            GVDebug.testPrint("VERIFICATION: SandboxVars.GVDrive exists:", testSandbox ~= nil)
            GVDebug.testPrint("VERIFICATION: USB_ZombieDrop_Chance value:", testSandbox.USB_ZombieDrop_Chance or "NOT_SET")
        else
            GVDebug.debugPrint("FAILED: Events.OnZombieDead.Add not available")
        end
    else
        GVDebug.debugPrint("SKIPPED: OnZombieDead registration - context:", contextInfo)
    end
    GVDebug.debugPrint("=== REGISTRATION COMPLETE - registered:", registered, "===")
    return registered
end

registerZombieHandler()

-- FINAL VERIFICATION: Test sandbox access and log all relevant values
local function verifyConfiguration()
    GVDebug.debugPrint("=== FINAL CONFIGURATION VERIFICATION ===")
    local gv = (SandboxVars and SandboxVars.GVDrive) or {}
    
    -- Test all drop-related sandbox keys
    local keys = {
        "USB_ZombieDrop_Chance",
        "Laptop_ZombieDrop_Chance", 
        "EliteDrive_ZombieDrop_Chance",
        "Antivirus_ZombieDrop_Chance"
    }
    
    for _, key in ipairs(keys) do
        local rawValue = gv[key]
        local processedValue = "N/A"
        if GVDrive_Utils and GVDrive_Utils.getSandboxPercent then
            local ok, result = pcall(GVDrive_Utils.getSandboxPercent, key, 0.0)
            if ok then
                processedValue = string.format("%.2f%%", result)
            end
        end
    GVDebug.debugPrint(string.format("%-25s Raw: %-8s Processed: %s", key, tostring(rawValue), processedValue))
    end
    
    -- Test comprehensive item availability
    GVDebug.debugPrint("=== TESTING COMPREHENSIVE ITEM AVAILABILITY ===")
    
    -- Test sample from each category
    local testItems = {
        -- Sample skill drives from different skills
        "GValley.SkillDrive_Woodwork_Facil",
        "GValley.SkillDrive_Mechanics_Moderado",
        "GValley.SkillDrive_Lightfoot_Dificil",
        -- All laptops
        "GValley.AsusZephLaptopClosed", 
        "GValley.Laptop90sClosed",
        "GValley.PBIBM_LP90Closed",
        -- All elite drives
        "GValley.EliteDrive_Strength",
        "GValley.EliteDrive_Endurance",
        "GValley.EliteDrive_Capacity",
        "GValley.EliteDrive_Speed",
        "GValley.EliteDrive_Luck",
        -- All antivirus types
        "GValley.Antivirus_Norton",
        "GValley.Antivirus_Kaspersky",
        "GValley.Antivirus_McAfee",
        "GValley.Antivirus_MalwareBytes"
    }
    
    local totalItems = #testItems
    local existingItems = 0
    
    for _, item in ipairs(testItems) do
        local exists = getScriptManager():getItem(item) ~= nil
        if exists then existingItems = existingItems + 1 end
        GVDebug.debugPrint(string.format("%-35s %s", item, exists and "EXISTS" or "MISSING"))
    end
    
    GVDebug.debugPrint(string.format("=== ITEM AVAILABILITY: %d/%d (%.1f%%) ===", existingItems, totalItems, (existingItems/totalItems)*100))
    GVDebug.debugPrint(string.format("=== TOTAL SKILL DRIVES AVAILABLE: %d skills × 3 rarities = %d items ===", #AVAILABLE_ITEMS.skills, #AVAILABLE_ITEMS.skills * 3))
    GVDebug.debugPrint("=== VERIFICATION COMPLETE - MOD READY FOR TESTING ===")
end

-- Run verification after a short delay to ensure everything is loaded
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(verifyConfiguration)
else
    verifyConfiguration()  -- Run immediately if event not available
end
testPrint(string.format("   • %d Elite Drive Types", stats.totalEliteTypes))
testPrint(string.format("   • %d Antivirus Types", stats.totalAntivirusTypes))
testPrint(string.format("   💎 TOTAL AVAILABLE ITEMS: %d", stats.totalItems))

-- EXPANSION HELPER: Add new items here and they'll automatically be included in drops
-- TO ADD A NEW SKILL: Add to AVAILABLE_ITEMS.skills array
-- TO ADD A NEW LAPTOP: Add to AVAILABLE_ITEMS.laptops array  
-- TO ADD A NEW ELITE TYPE: Add to AVAILABLE_ITEMS.eliteTypes array
-- TO ADD A NEW ANTIVIRUS: Add to AVAILABLE_ITEMS.antivirusTypes array
-- The system will automatically pick from all available options

local function getItemStats()
    local stats = {
        totalSkillDrives = #AVAILABLE_ITEMS.skills * #AVAILABLE_ITEMS.rarities,
        totalLaptops = #AVAILABLE_ITEMS.laptops,
        totalEliteTypes = #AVAILABLE_ITEMS.eliteTypes, 
        totalAntivirusTypes = #AVAILABLE_ITEMS.antivirusTypes
    }
    stats.totalItems = stats.totalSkillDrives + stats.totalLaptops + stats.totalEliteTypes + stats.totalAntivirusTypes
    return stats
end

testPrint("📊 ITEM CONFIGURATION LOADED:")
local stats = getItemStats()
testPrint(string.format("   • %d Skills × %d Rarities = %d Skill Drives", #AVAILABLE_ITEMS.skills, #AVAILABLE_ITEMS.rarities, stats.totalSkillDrives))
testPrint(string.format("   • %d Laptop Types", stats.totalLaptops))
testPrint(string.format("   • %d Elite Drive Types", stats.totalEliteTypes))
testPrint(string.format("   • %d Antivirus Types", stats.totalAntivirusTypes))
testPrint(string.format("   💎 TOTAL AVAILABLE ITEMS: %d", stats.totalItems))

-- Hook combined attempt: all modern items in one streamlined function
local function onZombieDeadCombined(zombie)
    testPrint("=== Combined zombie death handler called ===")
    pcall(onZombieDeadModern, zombie)
    testPrint("=== Combined handler complete ===")
end

-- Replace registration to combined handler (remove original and add combined)
-- Remove previous registration and register the combined one
-- Defensive: if Events has no Remove or we can't remove, just add combined handler as well
local function registerZombieHandler()
    -- FINAL VERIFICATION: Register on server or single-player with comprehensive logging
    local registered = false
    testPrint("=== REGISTERING ZOMBIE HANDLER - FINAL VERIFICATION ===")
    pcall(function()
        if Events and Events.OnZombieDead and Events.OnZombieDead.Remove then
            Events.OnZombieDead:Remove(onZombieDead)
            testPrint("Removed old onZombieDead handler")
        end
    end)

    local canRegister = false
    local contextInfo = ""
    pcall(function()
        canRegister = isServer() or not isClient()
        if isServer and isServer() then
            contextInfo = "SERVER"
        elseif isClient and not isClient() then
            contextInfo = "SINGLE_PLAYER"
        else
            contextInfo = "CLIENT_ONLY"
        end
    end)
    testPrint("Context check - canRegister:", canRegister, "contextInfo:", contextInfo)

    if canRegister then
        if Events and Events.OnZombieDead and Events.OnZombieDead.Add then
            Events.OnZombieDead.Add(onZombieDeadCombined)
            registered = true
            testPrint("✅ SUCCESS: GV_ZombieLoot.lua registered combined OnZombieDead handler (" .. contextInfo .. ")")
            testPrint("✅ VERIFICATION: Handler function exists:", type(onZombieDeadCombined))
            
            -- Test sandbox access immediately
            local testSandbox = (SandboxVars and SandboxVars.GVDrive) or {}
            testPrint("✅ VERIFICATION: SandboxVars.GVDrive exists:", testSandbox ~= nil)
            testPrint("✅ VERIFICATION: USB_ZombieDrop_Chance value:", testSandbox.USB_ZombieDrop_Chance or "NOT_SET")
        else
            testPrint("❌ FAILED: Events.OnZombieDead.Add not available")
        end
    else
        testPrint("❌ SKIPPED: OnZombieDead registration - context:", contextInfo)
    end
    testPrint("=== REGISTRATION COMPLETE - registered:", registered, "===")
    return registered
end

registerZombieHandler()

-- FINAL VERIFICATION: Test sandbox access and log all relevant values
local function verifyConfiguration()
    testPrint("=== FINAL CONFIGURATION VERIFICATION ===")
    local gv = (SandboxVars and SandboxVars.GVDrive) or {}
    
    -- Test all drop-related sandbox keys
    local keys = {
        "USB_ZombieDrop_Chance",
        "Laptop_ZombieDrop_Chance", 
        "EliteDrive_ZombieDrop_Chance",
        "Antivirus_ZombieDrop_Chance"
    }
    
    for _, key in ipairs(keys) do
        local rawValue = gv[key]
        local processedValue = "N/A"
        if GVDrive_Utils and GVDrive_Utils.getSandboxPercent then
            local ok, result = pcall(GVDrive_Utils.getSandboxPercent, key, 0.0)
            if ok then
                processedValue = string.format("%.2f%%", result)
            end
        end
        testPrint(string.format("%-25s Raw: %-8s Processed: %s", key, tostring(rawValue), processedValue))
    end
    
    -- Test comprehensive item availability
    testPrint("=== TESTING COMPREHENSIVE ITEM AVAILABILITY ===")
    
    -- Test sample from each category
    local testItems = {
        -- Sample skill drives from different skills
        "GValley.SkillDrive_Woodwork_Facil",
        "GValley.SkillDrive_Mechanics_Moderado",
        "GValley.SkillDrive_Lightfoot_Dificil",
        -- All laptops
        "GValley.AsusZephLaptopClosed", 
        "GValley.Laptop90sClosed",
        "GValley.PBIBM_LP90Closed",
        -- All elite drives
        "GValley.EliteDrive_Strength",
        "GValley.EliteDrive_Endurance",
        "GValley.EliteDrive_Capacity",
        "GValley.EliteDrive_Speed",
        "GValley.EliteDrive_Luck",
        -- All antivirus types
        "GValley.Antivirus_Norton",
        "GValley.Antivirus_Kaspersky",
        "GValley.Antivirus_McAfee",
        "GValley.Antivirus_MalwareBytes"
    }
    
    local totalItems = #testItems
    local existingItems = 0
    
    for _, item in ipairs(testItems) do
        local exists = getScriptManager():getItem(item) ~= nil
        if exists then existingItems = existingItems + 1 end
        testPrint(string.format("%-35s %s", item, exists and "✅ EXISTS" or "❌ MISSING"))
    end
    
    testPrint(string.format("=== ITEM AVAILABILITY: %d/%d (%.1f%%) ===", existingItems, totalItems, (existingItems/totalItems)*100))
    testPrint(string.format("=== TOTAL SKILL DRIVES AVAILABLE: %d skills × 3 rarities = %d items ===", #AVAILABLE_ITEMS.skills, #AVAILABLE_ITEMS.skills * 3))
    testPrint("=== VERIFICATION COMPLETE - MOD READY FOR TESTING ===")
end

-- Run verification after a short delay to ensure everything is loaded
if Events and Events.OnGameStart then
    Events.OnGameStart.Add(verifyConfiguration)
else
    verifyConfiguration()  -- Run immediately if event not available
end
