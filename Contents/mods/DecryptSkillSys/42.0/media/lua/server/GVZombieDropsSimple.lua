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
    Facil = 0.05,
    Moderado = 0.15,
    Dificil = 0.30,
}

-- Function to get drop chance for a category from sandbox
local function getDropChance(category, specificItem)
    local sandboxKey = category .. "_ZombieDrop_Chance"
    local gv = SandboxVars and SandboxVars.GVDrive
    local baseChance = 0
    
    if gv and gv[sandboxKey] then
        baseChance = gv[sandboxKey]
    else
        -- Defaults if not found (matching sandbox-options.txt)
        -- USB: ~1 every 20 zombies, Laptop: ~1 every 100 zombies, EliteDrive: ~1 every 120 zombies, Antivirus: ~1 every 60 zombies
        local defaults = {USB = 5.0, Laptop = 1.0, EliteDrive = 0.83, Antivirus = 1.67}
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
            -- Kaspersky reduce 0.05%
            return math.max(0, baseChance - 0.05)
        elseif specificItem == "GValley.Antivirus_McAfee" then
            -- McAfee reduce 0.1%
            return math.max(0, baseChance - 0.1)
        elseif specificItem == "GValley.Antivirus_MalwareBytes" then
            -- MalwareBytes reduce 0.2% (más difícil de conseguir)
            return math.max(0, baseChance - 0.2)
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
    elseif itemType == "EliteDrive" then
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
        -- Use ZombRand(10000) for precise percentage checks (0.08% = 8 out of 10000)
        local roll = ZombRand(10000) / 100.0  -- Convert to 0-100 range with decimals
        if roll < chance then
            spawnItem(zombie, "USB", rarity)
            usbDropped = true
            break
        end
    end

    -- Check drops for other categories independently
    local categories = {"Laptop", "EliteDrive"}
    for _, category in ipairs(categories) do
        local chance = getDropChance(category)
        -- Use ZombRand(10000) for precise percentage checks
        local roll = ZombRand(10000) / 100.0  -- Convert to 0-100 range with decimals
        if roll < chance then
            spawnItem(zombie, category)
        end
    end
    
    -- Special handling for antivirus - each type has its own chance
    for _, antivirusItem in ipairs(DROP_DISTRIBUTIONS.antivirusTypes) do
        local chance = getDropChance("Antivirus", antivirusItem)
        -- Use ZombRand(10000) for precise percentage checks
        local roll = ZombRand(10000) / 100.0  -- Convert to 0-100 range with decimals
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
