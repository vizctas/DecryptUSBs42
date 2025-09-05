-- Defensive requires to avoid hard crashes on servers where
-- some vanilla files are renamed/missing (B42 changes, etc.)
local function try_require(path)
    local ok, err = pcall(require, path)
    if not ok then
        print("[DecryptSkillSys] Optional require failed: " .. tostring(path))
    end
    return ok
end

try_require("Items/ProceduralDistributions")
try_require("Vehicles/VehicleDistributions_List")
try_require("Vehicles/VehicleDistribution_GloveBoxJunk")
try_require("Vehicles/VehicleDistribution_TrunkJunk")
try_require("Vehicles/VehicleDistribution_SeatJunk")
try_require("Vehicles/VehicleDistributions")

try_require("Items/Distribution_BinJunk")
try_require("Items/Distribution_ClosetJunk")
try_require("Items/Distribution_CounterJunk")
try_require("Items/Distribution_DeskJunk")
try_require("Items/Distribution_ShelfJunk")
try_require("Items/Distribution_SideTableJunk")

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

function GVDrive_ProceduralDistributions()
	-- USB Drives
	safeInsertItems("SecurityLockers", "GValley.USB_Closed", 4.2)
	safeInsertItems("SchoolLockers", "GValley.USB_Closed", 4.1)
	safeInsertItems("GigamartHouseElectronics", "GValley.USB_Closed", 6.3)
	safeInsertItems("OfficeDesk", "GValley.USB_Closed", 3.5)
	safeInsertItems("ComputerStoreElectronics", "GValley.USB_Closed", 8.0)
	
	-- Floppy Drives
	safeInsertItems("SecurityLockers", "GValley.FloppyDrive", SandboxVars.GVDrive.DriveDropChance_Diskette or 1.0)
	safeInsertItems("SchoolLockers", "GValley.FloppyDrive", 2.5)
	safeInsertItems("GigamartHouseElectronics", "GValley.FloppyDrive", 4.0)
	safeInsertItems("OfficeDesk", "GValley.FloppyDrive", 2.8)
	safeInsertItems("ComputerStoreElectronics", "GValley.FloppyDrive", 6.0)
	
	-- Laptops
	safeInsertItems("Bag_SurvivorBag", "GValley.AsusZephLaptopClosed", 4.4)
	safeInsertItems("Bag_DuffelBagTINT", "GValley.AsusZephLaptopClosed", 4.1)
	safeInsertItems("SchoolLockers", "GValley.AsusZephLaptopClosed", 3.5)
	safeInsertItems("LivingRoomShelf", "GValley.AsusZephLaptopClosed", 2.2)
	safeInsertItems("GigamartHouseElectronics", "GValley.AsusZephLaptopClosed", 12.4)
	safeInsertItems("SecurityLockers", "GValley.AsusZephLaptopClosed", 1.5)
	safeInsertItems("ComputerStoreElectronics", "GValley.AsusZephLaptopClosed", 15.0)
	
	safeInsertItems("Bag_SurvivorBag", "GValley.Laptop90sClosed", 4.5)
	safeInsertItems("Bag_DuffelBag", "GValley.Laptop90sClosed", 5.3)
	safeInsertItems("SchoolLockers", "GValley.Laptop90sClosed", 7.2)
	safeInsertItems("GigamartHouseElectronics", "GValley.Laptop90sClosed", 8.3)
	safeInsertItems("SecurityLockers", "GValley.Laptop90sClosed", 5.4)
	safeInsertItems("ComputerStoreElectronics", "GValley.Laptop90sClosed", 10.0)
	
	safeInsertItems("Bag_SurvivorBag", "GValley.PBIBM_LP90Closed", 5.5)
	safeInsertItems("Bag_DuffelBag", "GValley.PBIBM_LP90Closed", 5.5)
	safeInsertItems("SchoolLockers", "GValley.PBIBM_LP90Closed", 7.2)
	safeInsertItems("GigamartHouseElectronics", "GValley.PBIBM_LP90Closed", 8.1)
	safeInsertItems("SecurityLockers", "GValley.PBIBM_LP90Closed", 7.4)
	safeInsertItems("ComputerStoreElectronics", "GValley.PBIBM_LP90Closed", 12.0)
	
	-- Do NOT call ItemPickerJava.Parse() here.
	-- In Build 42 the engine parses/initializes the WorldDictionary after
	-- OnPreDistributionMerge. Calling Parse() here can trigger recursive
	-- initialization and crash clients/servers while joining a game.
	-- The engine will pick up the injected items without a manual parse.
end

Events.OnPreDistributionMerge.Add(GVDrive_ProceduralDistributions)

-- Zombie Drop Function
function GVDrive_OnZombieDead(zombie)
	if not zombie or not SandboxVars.GVDrive then return end
	
	local inventory = zombie:getInventory()
	if not inventory then return end
	
	-- Get drop chances from sandbox variables (convert to 0-1 range)
	local usbDropChance = (SandboxVars.GVDrive.DriveDropChance_USB or 0.8) / 100
	local floppyDropChance = (SandboxVars.GVDrive.DriveDropChance_Diskette or 1.0) / 100
	
	-- Very low chance for laptops (not configurable, fixed low rate)
	local laptopDropChance = 0.005  -- 0.5% chance
	
	-- Roll for USB drive drop
	if ZombRand(100) / 100 < usbDropChance then
		inventory:AddItem("GValley.USB_Closed")
	end
	
	-- Roll for Floppy drive drop
	if ZombRand(100) / 100 < floppyDropChance then
		inventory:AddItem("GValley.FloppyDrive")
	end
	
	-- Roll for laptop drop (very rare)
	if ZombRand(10000) / 10000 < laptopDropChance then
		local laptops = {
			"GValley.AsusZephLaptopClosed",
			"GValley.Laptop90sClosed", 
			"GValley.PBIBM_LP90Closed"
		}
		local randomLaptop = laptops[ZombRand(#laptops) + 1]
		inventory:AddItem(randomLaptop)
	end
end

-- Register the zombie death event
Events.OnZombieDead.Add(GVDrive_OnZombieDead)



