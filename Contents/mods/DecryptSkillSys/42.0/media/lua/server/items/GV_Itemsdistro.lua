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

    print("[DecryptSkillSys] Enabling world loot for USBs, floppies, and laptops…")

    -- Base weights; procedural values are relative within each list
    -- Apply sandbox multipliers (percentage intensity per item type)
    local usbMul    = ((SandboxVars.GVDrive and SandboxVars.GVDrive.USB_WorldLoot_Chance) or 100) / 100
    local diskMul   = ((SandboxVars.GVDrive and SandboxVars.GVDrive.Floppy_WorldLoot_Chance) or 100) / 100
    local laptopMul = ((SandboxVars.GVDrive and SandboxVars.GVDrive.Laptop_WorldLoot_Chance) or 100) / 100

    local usbWeightProc     = 0.10 * usbMul   -- common-ish small chance in relevant lists
    local floppyWeightProc  = 0.06 * diskMul  -- slightly rarer
    local laptopWeightProc  = 0.01 * laptopMul-- rare in stores/office-related

    local usbWeightVehicle    = 0.5  * usbMul
    local floppyWeightVehicle = 0.25 * diskMul
    local laptopWeightVehicle = 0.05 * laptopMul

    -- Patterns to target relevant procedural lists/containers
    local elecPatterns  = {"electronic", "computer", "tech", "server"}
    local officePatterns= {"office", "desk", "cubicle"}
    local shelfCrate    = {"shelf", "crate", "storage", "warehouse"}
    local schoolLib     = {"school", "library", "class"}
    local homePatterns  = {"bedroom", "sidetable", "living", "garage"}

    -- Items
    local itemUSB       = "GValley.USB_Closed"
    local itemFloppy    = "GValley.FloppyDrive"
    local laptopsClosed = {"GValley.AsusZephLaptopClosed", "GValley.Laptop90sClosed", "GValley.PBIBM_LP90Closed"}

    -- Procedural distributions
    addToProceduralByPattern(elecPatterns,   itemUSB,    usbWeightProc)
    addToProceduralByPattern(officePatterns, itemUSB,    usbWeightProc)
    addToProceduralByPattern(shelfCrate,     itemUSB,    usbWeightProc)
    addToProceduralByPattern(schoolLib,      itemUSB,    usbWeightProc)
    addToProceduralByPattern(homePatterns,   itemUSB,    usbWeightProc)

    addToProceduralByPattern(elecPatterns,   itemFloppy, floppyWeightProc)
    addToProceduralByPattern(officePatterns, itemFloppy, floppyWeightProc)
    addToProceduralByPattern(schoolLib,      itemFloppy, floppyWeightProc)

    for _, lp in ipairs(laptopsClosed) do
        addToProceduralByPattern(elecPatterns,   lp, laptopWeightProc)
        addToProceduralByPattern(officePatterns, lp, laptopWeightProc)
        addToProceduralByPattern(shelfCrate,     lp, laptopWeightProc)
    end

    -- Vehicles (glovebox, seats, trunk)
    addToVehicleCommon(itemUSB,    usbWeightVehicle)
    addToVehicleCommon(itemFloppy, floppyWeightVehicle)
    for _, lp in ipairs(laptopsClosed) do
        addToVehicleCommon(lp, laptopWeightVehicle)
    end

    -- SuburbsDistributions (broad container names across rooms)
    local contPatternsCommon = {"desk", "counter", "shelf", "crate", "locker", "metal", "office"}
    addToSuburbsByContainer(contPatternsCommon, itemUSB,   usbWeightProc)
    addToSuburbsByContainer(contPatternsCommon, itemFloppy,floppyWeightProc)
    for _, lp in ipairs(laptopsClosed) do
        addToSuburbsByContainer({"electronics", "computer", "office", "counter", "shelf"}, lp, laptopWeightProc)
    end

    -- ============ ANTIVIRUS DISTRIBUTIONS (VERY RARE) ============
    local antivirusBasicWeight = 0.001 * ((SandboxVars.GVDrive and SandboxVars.GVDrive.Antivirus_Spawn_Rate) or 100) / 100
    local antivirusAdvancedWeight = 0.0005 * ((SandboxVars.GVDrive and SandboxVars.GVDrive.Antivirus_Spawn_Rate) or 100) / 100
    local antivirusPremiumWeight = 0.0001 * ((SandboxVars.GVDrive and SandboxVars.GVDrive.Antivirus_Spawn_Rate) or 100) / 100

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

    print("[DecryptSkillSys] World loot injected.")
end

-- Attempt to enable world loot on load
Events.OnGameStart.Add(function()
    if isServer() then
        enableWorldLoot()
    end
end)

-- Zombie Drop Function (SIMPLIFIED TO AVOID CRASHES)
function GVDrive_OnZombieDead(zombie)
	if not zombie then return end
	
	-- Get sandbox vars safely
	local sandboxVars = SandboxVars and SandboxVars.GVDrive
	if not sandboxVars then return end
	
	local inventory = zombie:getInventory()
	if not inventory then return end
	
	-- Get drop chances from sandbox variables (convert to 0-100 range)
	local usbDropChance = sandboxVars.USB_ZombieDrop_Chance or 0.8
	local floppyDropChance = sandboxVars.Floppy_ZombieDrop_Chance or 1.0
	local laptopDropChance = sandboxVars.Laptop_ZombieDrop_Chance or 0.5
	
	-- Roll for USB drive drop
	if ZombRand(100) < usbDropChance then
		local usbDrive = getRandomSkillDrive("USB")
		if usbDrive then
			inventory:AddItem(usbDrive)
		end
	end
	
	-- Roll for Floppy drive drop
	if ZombRand(100) < floppyDropChance then
		local floppyDrive = getRandomSkillDrive("Floppy")
		if floppyDrive then
			inventory:AddItem(floppyDrive)
		end
	end
	
	-- Roll for laptop drop (very rare)
	if ZombRand(1000) < laptopDropChance then
		local laptops = {
			"GValley.AsusZephLaptopClosed",
			"GValley.Laptop90sClosed", 
			"GValley.PBIBM_LP90Closed"
		}
		local randomLaptop = laptops[ZombRand(#laptops) + 1]
		inventory:AddItem(randomLaptop)
	end
end

-- Get random skill drive based on rarity distribution (SAFE VERSION)
function getRandomSkillDrive(driveType)
	local rarityRoll = ZombRand(100)
	local skillRoll = ZombRand(100)
	
	if rarityRoll < 1 then
		-- Elite drives (1% chance)
		local eliteTypes = {
			"GValley.EliteDrive_Strength",
			"GValley.EliteDrive_Endurance", 
			"GValley.EliteDrive_Capacity",
			"GValley.EliteDrive_Speed",
			"GValley.EliteDrive_Luck"
		}
		return eliteTypes[ZombRand(#eliteTypes) + 1]
	elseif rarityRoll < 25 then
		-- Skill-specific drives (24% chance)
		local skills = {"Woodwork", "Electricity", "Farming", "Aiming", "Cooking", "Sneak", "Axe", "Fitness", "Doctor", "Survivalist"}
		local selectedSkill = skills[ZombRand(#skills) + 1]
		
		if driveType == "USB" then
			-- 70% common, 30% rare for USB
			if skillRoll < 70 then
				return "GValley.SkillDrive_" .. selectedSkill .. "_Common"
			else
				return "GValley.SkillDrive_" .. selectedSkill .. "_Rare"
			end
		elseif driveType == "Floppy" then
			-- Floppies are always common
			return "GValley.SkillFloppy_" .. selectedSkill .. "_Common"
		else
			return "GValley.SkillDrive_" .. selectedSkill .. "_Common" -- fallback
		end
	else
		-- Legacy drives (75% chance)
		if driveType == "USB" then
			return "GValley.USB_Closed"
		elseif driveType == "Floppy" then
			return "GValley.FloppyDrive"
		else
			return "GValley.USB_Closed" -- fallback
		end
	end
end

-- Register the zombie death event safely
if Events and Events.OnZombieDead and Events.OnZombieDead.Add then
	Events.OnZombieDead.Add(GVDrive_OnZombieDead)
	print("[DecryptSkillSys] Zombie death event registered successfully")
else
	print("[DecryptSkillSys] WARNING: Could not register zombie death event")
end



