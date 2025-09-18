-- Defensive requires to avoid hard crashes on servers where
-- some vanilla files are renamed/missing (B42 changes, etc.)
local function try_require(path)
    local ok, err = pcall(require, path)
    if not ok then
        print("[DecryptSkillSys] Optional require failed: " .. tostring(path))
    end
    return ok
end

-- World loot distribution (re-enabled)
-- Load vanilla distribution tables if available
try_require("Items/ProceduralDistributions")
try_require("Vehicles/VehicleDistributions_List")
try_require("Vehicles/VehicleDistribution_GloveBoxJunk")
try_require("Vehicles/VehicleDistribution_TrunkJunk")
try_require("Vehicles/VehicleDistribution_SeatJunk")
try_require("Vehicles/VehicleDistributions")

-- Older B41/B42 helper lists (optional)
try_require("Items/Distribution_BinJunk")
try_require("Items/Distribution_ClosetJunk")
try_require("Items/Distribution_CounterJunk")
try_require("Items/Distribution_DeskJunk")
try_require("Items/Distribution_ShelfJunk")
try_require("Items/Distribution_SideTableJunk")

-- Loads SuburbsDistributions via ItemPicker
try_require("Items/Distribution_BagsAndContainers")
try_require("Items/ItemPicker")

print("[DecryptSkillSys] GV_Itemsdistro.lua loaded")

function safeInsertItems(distriName, item, weight)
	if not distriName or not item or not weight then return end

	local multiplier = 1.0  -- Default multiplier
	local proceduralDistrib = (ProceduralDistributions and ProceduralDistributions.list) and ProceduralDistributions.list[distriName] or nil
	local vehicleDistrib = (type(VehicleDistributions_List) == "table") and VehicleDistributions_List[distriName] or nil

	if not proceduralDistrib and not vehicleDistrib then
		-- Avoid spamming, but give one hint of what's happening
		print("[DecryptSkillSys] Distribution '" .. tostring(distriName) .. "' not found in Procedural or Vehicle tables")
	end

	if proceduralDistrib and proceduralDistrib.items then
		table.insert(proceduralDistrib.items, item)
		table.insert(proceduralDistrib.items, weight * multiplier)
	end

	if vehicleDistrib and vehicleDistrib.items then
		table.insert(vehicleDistrib.items, item)
		table.insert(vehicleDistrib.items, weight * multiplier)
	end
end

-- Utilities to inject items into distributions by name/patterns
local function stringContainsAny(hay, needles)
    if type(hay) ~= "string" then return false end
    local lhay = string.lower(hay)
    for _, n in ipairs(needles or {}) do
        if lhay:find(string.lower(n), 1, true) then
            return true
        end
    end
    return false
end

local function addToProceduralByPattern(patterns, item, weight)
    if not (ProceduralDistributions and ProceduralDistributions.list) then return end
    for name, list in pairs(ProceduralDistributions.list) do
        local t = list and list.items
        if t and stringContainsAny(name, patterns) then
            table.insert(t, item)
            table.insert(t, weight)
        end
    end
end

local function addToVehicleCommon(item, weight)
    if type(VehicleDistributions_List) ~= "table" then return end
    for name, list in pairs(VehicleDistributions_List) do
        if list and list.items and stringContainsAny(name, {"glove", "glovebox", "trunk", "seat"}) then
            table.insert(list.items, item)
            table.insert(list.items, weight)
        end
    end
end

local function addToSuburbsByContainer(patterns, item, weight)
    if type(SuburbsDistributions) ~= "table" then return end
    for roomName, containers in pairs(SuburbsDistributions) do
        if type(containers) == "table" then
            for containerName, dist in pairs(containers) do
                local t = dist and dist.items
                if t and stringContainsAny(containerName, patterns) then
                    table.insert(t, item)
                    table.insert(t, weight)
                end
            end
        end
    end
end

local function enableWorldLoot()
    -- Guard on sandbox toggle (fallback ON if option missing in old saves)
    local gv = (SandboxVars and SandboxVars.GVDrive) or {}
    local enable = gv.EnableWorldLoot
    local enableFallback = false
    if enable == nil then
        enable = true
        enableFallback = true
    end
    if not enable then
        print("[DecryptSkillSys] World loot disabled by sandbox option")
        return
    end
    if enableFallback then
        print("[DecryptSkillSys] World loot enabled (fallback: option missing in save)")
    end

    print("[DecryptSkillSys] Enabling world loot for USBs and laptops (no more floppies)…")

    -- Base weights; procedural values are relative within each list
    -- Apply sandbox multipliers (percentage intensity per item type)
    local usbMul    = ((gv.USB_WorldLoot_Chance or 100)) / 100
    local laptopMul = ((gv.Laptop_WorldLoot_Chance or 100)) / 100

	local usbWeightProc     = 0.01 * usbMul   -- muy raro en world loot
	local laptopWeightProc  = 0.001 * laptopMul-- ultra raro en stores/office

	local usbWeightVehicle    = 0.05  * usbMul  -- reducido de 0.5
	local laptopWeightVehicle = 0.005 * laptopMul-- reducido de 0.05

    -- Patterns to target relevant procedural lists/containers
    local elecPatterns  = {"electronic", "computer", "tech", "server"}
    local officePatterns= {"office", "desk", "cubicle"}
    local shelfCrate    = {"shelf", "crate", "storage", "warehouse"}
    local schoolLib     = {"school", "library", "class"}
    local homePatterns  = {"bedroom", "sidetable", "living", "garage"}

    -- Items (no more floppy support)
	local itemUSB       = "GValley.USB_Closed"
	local laptopsClosed = {"GValley.AsusZephLaptopClosed", "GValley.Laptop90sClosed", "GValley.PBIBM_LP90Closed"}
    
    -- Antivirus items with their drop rates
    local antiviruses = {
        {item = "GValley.Antivirus_Norton", rate = (gv.Antivirus_Norton_Drop_Rate or 0.8) / 10},
        {item = "GValley.Antivirus_Kaspersky", rate = (gv.Antivirus_Kaspersky_Drop_Rate or 0.71) / 10},
        {item = "GValley.Antivirus_McAfee", rate = (gv.Antivirus_McAfee_Drop_Rate or 0.5) / 10},
        {item = "GValley.Antivirus_MalwareBytes", rate = (gv.Antivirus_MalwareBytes_Drop_Rate or 0.09) / 10},
    }

    -- Procedural distributions (USBs only)
    addToProceduralByPattern(elecPatterns,   itemUSB,    usbWeightProc)
    addToProceduralByPattern(officePatterns, itemUSB,    usbWeightProc)
    addToProceduralByPattern(shelfCrate,     itemUSB,    usbWeightProc)
    addToProceduralByPattern(schoolLib,      itemUSB,    usbWeightProc)
    addToProceduralByPattern(homePatterns,   itemUSB,    usbWeightProc)
    
    -- Add antivirus items
    for _, av in ipairs(antiviruses) do
        addToProceduralByPattern(elecPatterns,   av.item, av.rate)
        addToProceduralByPattern(officePatterns, av.item, av.rate)
    end

    for _, lp in ipairs(laptopsClosed) do
        addToProceduralByPattern(elecPatterns,   lp, laptopWeightProc)
        addToProceduralByPattern(officePatterns, lp, laptopWeightProc)
        addToProceduralByPattern(shelfCrate,     lp, laptopWeightProc)
    end

    -- Vehicles (glovebox, seats, trunk)
	addToVehicleCommon(itemUSB,    usbWeightVehicle)
    for _, lp in ipairs(laptopsClosed) do
        addToVehicleCommon(lp, laptopWeightVehicle)
    end

    -- SuburbsDistributions (broad container names across rooms)
    local contPatternsCommon = {"desk", "counter", "shelf", "crate", "locker", "metal", "office"}
	addToSuburbsByContainer(contPatternsCommon, itemUSB,   usbWeightProc)
    for _, lp in ipairs(laptopsClosed) do
        addToSuburbsByContainer({"electronics", "computer", "office", "counter", "shelf"}, lp, laptopWeightProc)
    end

    -- ============ ANTIVIRUS DISTRIBUTIONS (VERY RARE) ============
    local antivirusRate = (gv.Antivirus_Spawn_Rate or 100) / 100
    local antivirusBasicWeight = 0.0001 * antivirusRate     -- reducido 10x
    local antivirusAdvancedWeight = 0.00005 * antivirusRate -- reducido 10x
    local antivirusPremiumWeight = 0.00001 * antivirusRate  -- reducido 10x

    -- Antivirus items
    local itemAntivirusBasic = "GValley.AntivirusDisk_Basic"
    local itemAntivirusAdvanced = "GValley.AntivirusDisk_Advanced"
    local itemAntivirusPremium = "GValley.AntivirusDisk_Premium"

    -- Only in specific high-tech locations (servers, computer stores, electronics shops)
    local techPatterns = {"server", "electronics", "computer", "tech", "radio"}
    addToProceduralByPattern(techPatterns, itemAntivirusBasic, antivirusBasicWeight)
    addToProceduralByPattern(techPatterns, itemAntivirusAdvanced, antivirusAdvancedWeight)
    addToProceduralByPattern(techPatterns, itemAntivirusPremium, antivirusPremiumWeight)

    -- Very rarely in office safes or high-security locations
    local securePatterns = {"safe", "security", "police", "military"}
    addToProceduralByPattern(securePatterns, itemAntivirusAdvanced, antivirusAdvancedWeight * 2)
    addToProceduralByPattern(securePatterns, itemAntivirusPremium, antivirusPremiumWeight * 3)

    -- ============ ELITE DRIVES WORLD LOOT (ULTRA RARE) ============
    local eliteRate = (gv.EliteDrive_WorldLoot_Chance or 100) / 100
    local eliteWeight = 0.000001 * eliteRate  -- Ultra rare: 0.0001% (reducido 10x)
    
    local eliteItems = {
        "GValley.EliteDrive_Strength",
        "GValley.EliteDrive_Endurance",
        "GValley.EliteDrive_Capacity",
        "GValley.EliteDrive_Speed",
        "GValley.EliteDrive_Luck"
    }
    
    -- Only in ultra-secure military/special locations
    local militaryPatterns = {"military", "army", "bunker", "vault", "classified"}
    for _, elite in ipairs(eliteItems) do
        addToProceduralByPattern(militaryPatterns, elite, eliteWeight)
        addToProceduralByPattern(securePatterns, elite, eliteWeight * 0.5)
    end

    -- ============ SKILL USB WORLD LOOT ============
    -- Add random skill USBs to world (much rarer than generic USB_Closed)
    local skillUSBRate = (gv.SkillUSB_WorldLoot_Chance or 100) / 100
    local skillUSBWeight = 0.0001 * skillUSBRate  -- Ultra rare: 0.01% (reducido 10x)
    
    -- Skills available for world spawn
    local worldSkills = {
        "Woodwork", "Electricity", "Farming", "Aiming", "Cooking", "Sneak",
        "Axe", "Fitness", "Doctor", "Survivalist", "Mechanics", "Tailoring",
        "Maintenance", "SmallBlade", "LongBlade", "SmallBlunt", "LongBlunt",
        "Spear", "Trapping", "Fishing", "Sprinting", "Strength", "Nimble", "Lightfoot"
    }
    
    -- Add skill USBs to specific relevant locations
    for _, skill in ipairs(worldSkills) do
        local facilItem = "GValley.SkillDrive_" .. skill .. "_Facil"
        local moderadoItem = "GValley.SkillDrive_" .. skill .. "_Moderado"
        local dificilItem = "GValley.SkillDrive_" .. skill .. "_Dificil"
        
        -- Facil: Common in relevant locations
        addToProceduralByPattern(elecPatterns, facilItem, skillUSBWeight * 3)
        addToProceduralByPattern(officePatterns, facilItem, skillUSBWeight * 2)
        addToProceduralByPattern(schoolLib, facilItem, skillUSBWeight * 2)
        
        -- Moderado: Less common  
        addToProceduralByPattern(elecPatterns, moderadoItem, skillUSBWeight * 2)
        addToProceduralByPattern(officePatterns, moderadoItem, skillUSBWeight)
        
        -- Dificil: Very rare, only in high-tech locations
        addToProceduralByPattern(techPatterns, dificilItem, skillUSBWeight * 0.5)
        addToProceduralByPattern(securePatterns, dificilItem, skillUSBWeight * 0.3)
    end

    print("[DecryptSkillSys] World loot injected: USBs, Laptops, Antivirus, Elite Drives, Skill USBs.")
end

-- Attempt to enable world loot on load
Events.OnGameStart.Add(function()
    if isServer() then
        enableWorldLoot()
    end
end)

-- Zombie Drop Function - Ajustado para vision balanceada del mod
function GVDrive_OnZombieDead(zombie)
	-- Improved initialization with better error checking
	if not zombie then 
		print("[DecryptSkillSys] Zombie drop skipped - zombie is nil")
		return 
	end
	
	if not isServer() then 
		print("[DecryptSkillSys] Zombie drop skipped - client side execution")
		return 
	end
	
	-- Debug logging for every zombie death
	print("[DecryptSkillSys] Processing zombie death for drops...")
	
	-- Get sandbox vars with fallback defaults (increased for testing)
	local sandboxVars = (SandboxVars and SandboxVars.GVDrive) or {
		USB_ZombieDrop_Chance = 5.0,
		Laptop_ZombieDrop_Chance = 1.0,
		EliteDrive_ZombieDrop_Chance = 0.167,
		Antivirus_ZombieDrop_Chance = 0.45
	}
	
	-- Debug sandbox values
	print(string.format("[DecryptSkillSys] Sandbox values - USB: %.2f%%, Laptop: %.2f%%, Elite: %.3f%%, Antivirus: %.2f%%", 
		sandboxVars.USB_ZombieDrop_Chance or 5.0, 
		sandboxVars.Laptop_ZombieDrop_Chance or 1.0,
		sandboxVars.EliteDrive_ZombieDrop_Chance or 0.167,
		sandboxVars.Antivirus_ZombieDrop_Chance or 0.45))
	
	local inventory = zombie and zombie:getInventory()
	if not inventory then return end
	
	-- Get drop chances with fallbacks
	local usbDropChance = sandboxVars.USB_ZombieDrop_Chance or 1.5
	local laptopDropChance = sandboxVars.Laptop_ZombieDrop_Chance or 0.3
	local eliteDropChance = sandboxVars.EliteDrive_ZombieDrop_Chance or 0.08
	local antivirusDropChance = sandboxVars.Antivirus_ZombieDrop_Chance or 0.3
	
	-- Roll for USB drive drop (now with debug logging)
	local usbRoll = ZombRand(10000)
	local usbThreshold = usbDropChance * 100
	print(string.format("[DecryptSkillSys] USB roll: %d vs threshold: %.1f", usbRoll, usbThreshold))
	
	if usbRoll < usbThreshold then
		local usbDrive = getRandomSkillDrive("USB")
		if usbDrive then
			inventory:AddItem(usbDrive)
			print(string.format("[DecryptSkillSys] ✅ DROPPED USB drive: %s (roll %d < %.1f)", usbDrive, usbRoll, usbThreshold))
		else
			print("[DecryptSkillSys] ❌ Failed to generate USB drive")
		end
	else
		print(string.format("[DecryptSkillSys] No USB drop (roll %d >= %.1f)", usbRoll, usbThreshold))
	end
	
	-- Roll for Laptop drop
	local laptopRoll = ZombRand(10000)
	local laptopThreshold = laptopDropChance * 100
	print(string.format("[DecryptSkillSys] Laptop roll: %d vs threshold: %.1f", laptopRoll, laptopThreshold))
	
	if laptopRoll < laptopThreshold then
		local laptops = {"GValley.AsusZephLaptopClosed", "GValley.Laptop90sClosed", "GValley.PBIBM_LP90Closed"}
		local selectedLaptop = laptops[ZombRand(#laptops) + 1]
		inventory:AddItem(selectedLaptop)
		print(string.format("[DecryptSkillSys] ✅ DROPPED laptop: %s (roll %d < %.1f)", selectedLaptop, laptopRoll, laptopThreshold))
	else
		print(string.format("[DecryptSkillSys] No laptop drop (roll %d >= %.1f)", laptopRoll, laptopThreshold))
	end
	
	-- Roll for Elite Drive drop
	local eliteRoll = ZombRand(10000)
	local eliteThreshold = eliteDropChance * 100
	print(string.format("[DecryptSkillSys] Elite roll: %d vs threshold: %.3f", eliteRoll, eliteThreshold))
	
	if eliteRoll < eliteThreshold then
		local eliteTypes = {"Strength", "Endurance", "Capacity", "Speed", "Luck"}
		local selectedType = eliteTypes[ZombRand(#eliteTypes) + 1]
		local eliteItem = "GValley.EliteDrive_" .. selectedType
		inventory:AddItem(eliteItem)
		print(string.format("[DecryptSkillSys] ✅ DROPPED ELITE drive: %s (roll %d < %.3f)", eliteItem, eliteRoll, eliteThreshold))
	else
		print(string.format("[DecryptSkillSys] No elite drop (roll %d >= %.3f)", eliteRoll, eliteThreshold))
	end
	
	-- Roll for Antivirus drop
	local avRoll = ZombRand(10000)
	local avThreshold = antivirusDropChance * 100
	print(string.format("[DecryptSkillSys] Antivirus roll: %d vs threshold: %.2f", avRoll, avThreshold))
	
	if avRoll < avThreshold then
		local antivirusTypes = {
			{item = "GValley.Antivirus_Norton", weight = 40},
			{item = "GValley.Antivirus_Kaspersky", weight = 30},
			{item = "GValley.Antivirus_McAfee", weight = 20},
			{item = "GValley.Antivirus_MalwareBytes", weight = 10},
		}
		
		local totalWeight = 100
		local roll = ZombRand(totalWeight)
		local currentWeight = 0
		
		for _, av in ipairs(antivirusTypes) do
			currentWeight = currentWeight + av.weight
			if roll < currentWeight then
				inventory:AddItem(av.item)
				print(string.format("[DecryptSkillSys] ✅ DROPPED antivirus: %s (roll %d < %.2f)", av.item, avRoll, avThreshold))
				break
			end
		end
	else
		print(string.format("[DecryptSkillSys] No antivirus drop (roll %d >= %.2f)", avRoll, avThreshold))
	end
	
	print("[DecryptSkillSys] Zombie death processing completed")
end

-- Get random skill drive based on NEW rarity distribution (Fácil/Moderado/Difícil)
function getRandomSkillDrive(driveType)
	-- Check for elite drives first (still 1% chance)
	if ZombRand(100) < 1 then
		local eliteTypes = {
			"GValley.EliteDrive_Strength",
			"GValley.EliteDrive_Endurance",
			"GValley.EliteDrive_Capacity",
			"GValley.EliteDrive_Speed",
			"GValley.EliteDrive_Luck",
		}
		return eliteTypes[ZombRand(#eliteTypes) + 1]
	end

	local utils = rawget(_G, "GVDrive_Utils")

	local function getLootWeight(info)
		if utils and utils.getLootChance then
			local ok, value = pcall(utils.getLootChance, info)
			if ok and type(value) == "number" then
				return math.max(0, value)
			end
		end
		return 0
	end

	local isUSB = driveType == "USB"
	local isFloppy = driveType == "Floppy"

	-- NEW RARITY SYSTEM: Fácil/Moderado/Difícil
	local facilInfo = { isSkillSpecific = true, isUSB = isUSB, isFloppy = isFloppy, rarity = "Facil" }
	local moderadoInfo = { isSkillSpecific = true, isUSB = isUSB, isFloppy = isFloppy, rarity = "Moderado" }
	local dificilInfo = { isSkillSpecific = true, isUSB = isUSB, isFloppy = isFloppy, rarity = "Dificil" }

	local facilWeight = getLootWeight(facilInfo)
	local moderadoWeight = getLootWeight(moderadoInfo)
	local dificilWeight = isUSB and getLootWeight(dificilInfo) or 0

	-- Scale weights for better distribution
	local scaledFacil = math.max(0, math.floor(facilWeight * 10 + 0.5))
	local scaledModerado = math.max(0, math.floor(moderadoWeight * 10 + 0.5))
	local scaledDificil = math.max(0, math.floor(dificilWeight * 10 + 0.5))
	local totalScaled = scaledFacil + scaledModerado + scaledDificil

	-- Fallback weights if no sandbox values are available
	if totalScaled <= 0 then
		if driveType == "USB" then
			scaledDificil = 15   -- Difícil: 15% (muy raro)
			scaledModerado = 35  -- Moderado: 35% (común)
			scaledFacil = 50     -- Fácil: 50% (más común)
		elseif driveType == "Floppy" then
			scaledDificil = 10   -- Difícil: 10% (más raro en floppies)
			scaledModerado = 40  -- Moderado: 40%
			scaledFacil = 50     -- Fácil: 50%
		else
			scaledDificil = 0
			scaledModerado = 30
			scaledFacil = 70
		end
		totalScaled = scaledFacil + scaledModerado + scaledDificil
	end

	local roll = ZombRand(totalScaled)
	-- LISTA COMPLETA DE SKILLS DE PROJECT ZOMBOID CON USBS DISPONIBLES
	local skills = {
		-- Combat Skills (con USBs definidas)
		"Axe", "LongBlade", "SmallBlade", "LongBlunt", "SmallBlunt", "Spear", "Maintenance", "Aiming",
		-- Crafting Skills (con USBs definidas)
		"Woodwork", "Cooking", "Farming", "Doctor", "Electricity", "Mechanics", "Tailoring",
		-- Survivalist Skills (con USBs definidas)  
		"Fishing", "Trapping", "Survivalist",
		-- Fitness Skills (con USBs definidas)
		"Fitness", "Strength", "Sprinting", "Lightfoot", "Nimble", "Sneak"
	}
	local function randomSkill()
		return skills[ZombRand(#skills) + 1]
	end

	-- NUEVA DISTRIBUCIÓN (español): Dificil -> Moderado -> Facil
	if roll < scaledDificil and isUSB then
		local selectedSkill = randomSkill()
		return "GValley.SkillDrive_" .. selectedSkill .. "_Dificil"
	elseif roll < (scaledDificil + scaledModerado) and isUSB then
		local selectedSkill = randomSkill()
		return "GValley.SkillDrive_" .. selectedSkill .. "_Moderado"
	else
		local selectedSkill = randomSkill()
		return "GValley.SkillDrive_" .. selectedSkill .. "_Facil"
	end
end

-- ARCHIVO DESHABILITADO - USAR GV_ZombieLoot_CORRECTO.lua EN SU LUGAR
-- El problema era que usábamos OnZombieDead en lugar de OnCreateLivingCharacter

--[[ CÓDIGO DESHABILITADO
-- Register the zombie death event safely with proper error handling
local function registerZombieDeathEvent()
    if not Events then
        print("[DecryptSkillSys] ERROR: Events system not available")
        return false
    end
    
    if not Events.OnZombieDead then
        print("[DecryptSkillSys] ERROR: OnZombieDead event not available")
        return false
    end
    
    if not Events.OnZombieDead.Add then
        print("[DecryptSkillSys] ERROR: OnZombieDead.Add method not available")
        return false
    end
    
    -- Remove any existing registration to avoid duplicates
    Events.OnZombieDead.Remove(GVDrive_OnZombieDead)
    
    -- Register the event
    Events.OnZombieDead.Add(GVDrive_OnZombieDead)
    print("[DecryptSkillSys] Zombie death event registered successfully")
    return true
end

-- Register immediately
if not registerZombieDeathEvent() then
    -- Fallback: try to register on server start
    local function delayedRegister()
        print("[DecryptSkillSys] Attempting delayed zombie death event registration...")
        if registerZombieDeathEvent() then
            print("[DecryptSkillSys] Delayed registration successful")
        else
            print("[DecryptSkillSys] CRITICAL ERROR: Could not register zombie death event")
        end
    end
    
    if Events and Events.OnServerStarted and Events.OnServerStarted.Add then
        Events.OnServerStarted.Add(delayedRegister)
    end
    
    if Events and Events.OnGameStart and Events.OnGameStart.Add then
        Events.OnGameStart.Add(delayedRegister)
    end
end
--]] -- FIN CÓDIGO DESHABILITADO
