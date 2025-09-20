-- Defensive requires to avoid hard crashes on servers where
-- some vanilla files are renamed/missing (B42 changes, etc.)
local DEBUG = false
pcall(require, "shared/GVDrive_Config")
if GVDrive_Config and GVDrive_Config.getDebug then
    DEBUG = GVDrive_Config.getDebug()
end

-- Defensive GVDebug require: some loader orders may not have it yet
local ok_dbg, GVDebug = pcall(require, "shared/GVDebug")
if not ok_dbg or not GVDebug then
    GVDebug = { debugPrint = function(...) end }
end

local function try_require(path)
    local ok, err = pcall(require, path)
    if not ok and GVDebug and GVDebug.debugPrint then
        GVDebug.debugPrint("Optional require failed:", tostring(path))
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

    GVDebug.debugPrint("GV_Itemsdistro.lua loaded")

function safeInsertItems(distriName, item, weight)
	if not distriName or not item or not weight then return end

	local multiplier = 1.0  -- Default multiplier
	local proceduralDistrib = (ProceduralDistributions and ProceduralDistributions.list) and ProceduralDistributions.list[distriName] or nil
	local vehicleDistrib = (type(VehicleDistributions_List) == "table") and VehicleDistributions_List[distriName] or nil

    if not proceduralDistrib and not vehicleDistrib then
        -- Avoid spamming, but give one hint of what's happening
        if GVDebug and GVDebug.debugPrint then
            GVDebug.debugPrint("Distribution '" .. tostring(distriName) .. "' not found in Procedural or Vehicle tables")
        end
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
            if GVDebug and GVDebug.debugPrint then
                GVDebug.debugPrint("Injected into Procedural list:", name, "item=", item, "weight=", weight)
            end
        end
    end
end

local function addToVehicleCommon(item, weight)
    if type(VehicleDistributions_List) ~= "table" then return end
    for name, list in pairs(VehicleDistributions_List) do
        if list and list.items and stringContainsAny(name, {"glove", "glovebox", "trunk", "seat"}) then
            table.insert(list.items, item)
            table.insert(list.items, weight)
            if GVDebug and GVDebug.debugPrint then
                GVDebug.debugPrint("Injected into Vehicle list:", name, "item=", item, "weight=", weight)
            end
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
                    if GVDebug and GVDebug.debugPrint then
                        GVDebug.debugPrint("Injected into Suburbs container:", roomName, containerName, "item=", item, "weight=", weight)
                    end
                end
            end
        end
    end
end

local function enableWorldLoot()
    -- Guard on sandbox toggle (fallback ON if option missing in old saves)
    local gv = (SandboxVars and SandboxVars.GVDrive) or {}
    local getNum = GVDrive_Utils and GVDrive_Utils.getSandboxNumber
    local getPct = GVDrive_Utils and GVDrive_Utils.getSandboxPercent
    local enable = gv.EnableWorldLoot
    local enableFallback = false
    if enable == nil then
        enable = true
        enableFallback = true
    end
    if GVDebug and GVDebug.debugPrint then GVDebug.debugPrint("enableWorldLoot running; EnableWorldLoot=", tostring(enable)) end
    if not enable then
    GVDebug.debugPrint("World loot disabled by sandbox option")
        return
    end
    if enableFallback and GVDebug and GVDebug.debugPrint then
        GVDebug.debugPrint("World loot enabled (fallback: option missing in save)")
    end

    if GVDebug and GVDebug.debugPrint then GVDebug.debugPrint("Enabling world loot for USBs and laptops (no more floppies)…") end

    -- Base weights; procedural values are relative within each list
    -- Apply sandbox multipliers (percentage intensity per item type)
    -- Normalize sandbox multipliers: accept decimals or 1..100 values
    local usbMul = 1.0
    local laptopMul = 1.0
    if getPct then
        usbMul = (getPct("USB_WorldLoot_Chance", 100)) / 100.0
        laptopMul = (getPct("Laptop_WorldLoot_Chance", 100)) / 100.0
    else
        usbMul = ((gv.USB_WorldLoot_Chance or 100)) / 100
        laptopMul = ((gv.Laptop_WorldLoot_Chance or 100)) / 100
    end

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
        {item = "GValley.Antivirus_Norton", rate = (getNum and getNum('Antivirus_Norton_Drop_Rate', 0.4) or (gv.Antivirus_Norton_Drop_Rate or 0.4)) / 10},
        {item = "GValley.Antivirus_Kaspersky", rate = (getNum and getNum('Antivirus_Kaspersky_Drop_Rate', 0.3) or (gv.Antivirus_Kaspersky_Drop_Rate or 0.3)) / 10},
        {item = "GValley.Antivirus_McAfee", rate = (getNum and getNum('Antivirus_McAfee_Drop_Rate', 0.2) or (gv.Antivirus_McAfee_Drop_Rate or 0.2)) / 10},
        {item = "GValley.Antivirus_MalwareBytes", rate = (getNum and getNum('Antivirus_MalwareBytes_Drop_Rate', 0.05) or (gv.Antivirus_MalwareBytes_Drop_Rate or 0.05)) / 10},
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

    -- Elite Drives World Loot (Ultra Rare)
    local eliteRate = 0.02
    if getPct then
        eliteRate = (getPct("EliteDrive_WorldLoot_Chance", 2)) / 100.0
    else
        eliteRate = (gv.EliteDrive_WorldLoot_Chance or 2) / 100
    end
    local eliteWeight = 0.000001 * eliteRate  -- Ultra rare: 0.0001%
    
    local eliteItems = {
        "GValley.EliteDrive_Strength",
        "GValley.EliteDrive_Endurance",
        "GValley.EliteDrive_Capacity",
        "GValley.EliteDrive_Speed",
        "GValley.EliteDrive_Luck"
    }
    
    -- Only in ultra-secure military/special locations
    local militaryPatterns = {"military", "army", "bunker", "vault", "classified"}
    local securePatterns = {"safe", "security", "police", "military"}
    for _, elite in ipairs(eliteItems) do
        addToProceduralByPattern(militaryPatterns, elite, eliteWeight)
        addToProceduralByPattern(securePatterns, elite, eliteWeight * 0.5)
    end

    -- Skill USB World Loot
    local skillUSBRate = 0.08
    if getPct then
        skillUSBRate = (getPct("SkillUSB_WorldLoot_Chance", 8)) / 100.0
    else
        skillUSBRate = (gv.SkillUSB_WorldLoot_Chance or 8) / 100
    end
    local skillUSBWeight = 0.0001 * skillUSBRate  -- Ultra rare: 0.01%
    
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
    GVDebug.debugPrint("Skill USB (Facil) planned injections for skill:", skill, facilItem)
        
        -- Moderado: Less common  
        addToProceduralByPattern(elecPatterns, moderadoItem, skillUSBWeight * 2)
        addToProceduralByPattern(officePatterns, moderadoItem, skillUSBWeight)
    GVDebug.debugPrint("Skill USB (Moderado) planned injections for skill:", skill, moderadoItem)
        
        -- Dificil: Very rare, only in high-tech locations
        local techPatterns = {"server", "electronics", "computer", "tech", "radio"}
        addToProceduralByPattern(techPatterns, dificilItem, skillUSBWeight * 0.5)
        addToProceduralByPattern(securePatterns, dificilItem, skillUSBWeight * 0.3)
    GVDebug.debugPrint("Skill USB (Dificil) planned injections for skill:", skill, dificilItem)
    end

    GVDebug.debugPrint("World loot injected: USBs, Laptops, Elite Drives, Skill USBs.")
end

-- Attempt to enable world loot on load
Events.OnGameStart.Add(function()
    if isServer() then
        enableWorldLoot()
    end
end)