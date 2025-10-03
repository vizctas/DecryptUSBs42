-- Simplified Zombie Drops for Decrypt Skill Sys
-- This file contains simplified distribution tables for all USB types, laptops, elite drives, and antivirus

local ok_debug, GVDebug = pcall(require, "shared/GVDebug")
if not ok_debug or not GVDebug then
    GVDebug = { debugPrint = function(...) end, testPrint = function(...) end }
end

-- Simplified distribution tables
local DROP_DISTRIBUTIONS = {
    -- Skill drives: uniform distribution across all skills and rarities
    skills = {
        "Woodwork", "Electricity", "Farming", "Aiming", "Cooking", "Sneak",
        "Axe", "Fitness", "Doctor", "Survivalist", "Mechanics", "Tailoring",
        "Maintenance", "SmallBlade", "LongBlade", "SmallBlunt", "LongBlunt",
        "Spear", "Trapping", "Fishing", "Sprinting", "Strength", "Nimble", "Lightfoot"
    },

    -- All rarities have equal chance
    rarities = {"Facil", "Moderado", "Dificil"},

    -- Laptops: uniform distribution
    laptops = {
        "GValley.AsusZephLaptopOpened",
        "GValley.Laptop90sOpened",
        "GValley.PBIBM_LP90Opened"
    },

    -- Elite drives: uniform distribution
    eliteTypes = {"Strength", "Endurance", "Capacity", "Speed", "Luck"},

    -- Antivirus: uniform distribution
    antivirusTypes = {
        "GValley.Antivirus_Norton",
        "GValley.Antivirus_Kaspersky",
        "GValley.Antivirus_McAfee",
        "GValley.Antivirus_MalwareBytes"
    }
}

local RARITY_CHANCE_OFFSETS = {
    Facil = 0.3,
    Moderado = 0.6,
    Dificil = 0.9,
}

-- Function to get drop chance for a category from sandbox
local function getDropChance(category, specificItem)
    local sandboxKey = category .. "_ZombieDrop_Chance"
    local gv = SandboxVars and SandboxVars.GVDrive
    local baseChance = 0
    
    if gv and gv[sandboxKey] then
        baseChance = gv[sandboxKey]
    else
        -- Defaults if not found
        local defaults = {USB = 2.86, Laptop = 1.0, Elite = 0.25, Antivirus = 2.2}
        baseChance = defaults[category] or 0
    end
    
    -- Apply hardcoded modifiers for USB rarities
    if category == "USB" and specificItem then
        local offset = RARITY_CHANCE_OFFSETS[specificItem]
        if offset then
            return math.max(0, baseChance - offset)
        end
    end

    -- Apply hardcoded modifiers for specific antivirus types
    if category == "Antivirus" and specificItem then
        if specificItem == "GValley.Antivirus_Norton" then
            -- Norton mantiene el porcentaje del sandbox (0% reducción)
            return baseChance
        elseif specificItem == "GValley.Antivirus_Kaspersky" then
            -- Kaspersky reduce 0.3%
            return math.max(0, baseChance - 0.3)
        elseif specificItem == "GValley.Antivirus_McAfee" then
            -- McAfee reduce 0.5%
            return math.max(0, baseChance - 0.5)
        elseif specificItem == "GValley.Antivirus_MalwareBytes" then
            -- MalwareBytes reduce 0.8% (más difícil de conseguir)
            return math.max(0, baseChance - 0.8)
        end
    end
    
    return baseChance
end

-- Function to spawn an item of the given type
local function spawnItem(zombie, itemType, rarityOverride)
    local itemToSpawn = nil

    if itemType == "USB" then
        local skill = DROP_DISTRIBUTIONS.skills[ZombRand(#DROP_DISTRIBUTIONS.skills) + 1]
        local rarity = rarityOverride or DROP_DISTRIBUTIONS.rarities[ZombRand(#DROP_DISTRIBUTIONS.rarities) + 1]
        itemToSpawn = string.format("GValley.SkillDrive_%s_%s", skill, rarity)
    elseif itemType == "Laptop" then
        itemToSpawn = DROP_DISTRIBUTIONS.laptops[ZombRand(#DROP_DISTRIBUTIONS.laptops) + 1]
    elseif itemType == "Elite" then
        local eliteType = DROP_DISTRIBUTIONS.eliteTypes[ZombRand(#DROP_DISTRIBUTIONS.eliteTypes) + 1]
        itemToSpawn = string.format("GValley.EliteDrive_%s", eliteType)
    elseif itemType == "Antivirus" then
        itemToSpawn = DROP_DISTRIBUTIONS.antivirusTypes[ZombRand(#DROP_DISTRIBUTIONS.antivirusTypes) + 1]
    end

    if not itemToSpawn then return end

    -- Try to spawn in zombie inventory first, then on ground
    local spawned = false
    if zombie and zombie.getInventory then
        local inv = zombie:getInventory()
        if inv and inv.AddItem then
            inv:AddItem(itemToSpawn)
            spawned = true
        end
    end

    if not spawned then
        local sq = zombie and zombie:getCurrentSquare()
        if sq then
            sq:AddWorldInventoryItem(itemToSpawn, 0, 0, 0)
        end
    end
end

-- Main zombie death handler
local function onZombieDead(zombie)
    if not zombie or instanceof(zombie, "IsoPlayer") then return end

    -- Handle USB drops with rarity-specific offsets
    local usbDropped = false
    for _, rarity in ipairs(DROP_DISTRIBUTIONS.rarities) do
        local chance = getDropChance("USB", rarity)
        local roll = ZombRand(0, 100)
        if roll < chance then
            spawnItem(zombie, "USB", rarity)
            usbDropped = true
            break
        end
    end

    -- Check drops for other categories independently
    local categories = {"Laptop", "Elite"}
    for _, category in ipairs(categories) do
        local chance = getDropChance(category)
        local roll = ZombRand(0, 100)
        if roll < chance then
            spawnItem(zombie, category)
        end
    end
    
    -- Special handling for antivirus - each type has its own chance
    for _, antivirusItem in ipairs(DROP_DISTRIBUTIONS.antivirusTypes) do
        local chance = getDropChance("Antivirus", antivirusItem)
        local roll = ZombRand(0, 100)
        if roll < chance then
            -- Spawn the specific antivirus item
            local spawned = false
            if zombie and zombie.getInventory then
                local inv = zombie:getInventory()
                if inv and inv.AddItem then
                    inv:AddItem(antivirusItem)
                    spawned = true
                end
            end
            
            if not spawned then
                local sq = zombie and zombie:getCurrentSquare()
                if sq then
                    sq:AddWorldInventoryItem(antivirusItem, 0, 0, 0)
                end
            end
            break -- Only drop one antivirus per zombie
        end
    end
end

-- Register the handler
if Events and Events.OnZombieDead then
    Events.OnZombieDead.Add(onZombieDead)
end

-- Export for debugging
GVZombieDrops = {
    distributions = DROP_DISTRIBUTIONS,
    getDropChance = getDropChance,
    spawnItem = spawnItem
}
