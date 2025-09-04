require "Items/ProceduralDistributions"

require "Vehicles/VehicleDistributions_List"

require "Vehicles/VehicleDistribution_GloveBoxJunk"
require "Vehicles/VehicleDistribution_TrunkJunk"
require "Vehicles/VehicleDistribution_SeatJunk"
require "Vehicles/VehicleDistributions"

require "Items/Distribution_BinJunk"
require "Items/Distribution_ClosetJunk"
require "Items/Distribution_CounterJunk"
require "Items/Distribution_DeskJunk"
require "Items/Distribution_ShelfJunk"
require "Items/Distribution_SideTableJunk"

require "Items/Distribution_BagsAndContainers"

require "Items/ItemPicker"

function safeInsertItems(distriName, item, weight)
	if not distriName or not item or not weight then return end
	
	local multiplier = 1.0  -- Default multiplier
	local proceduralDistrib = ProceduralDistributions.list[distriName]
	local vehicleDistrib = VehicleDistributions_List[distriName]
	
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
	
	ItemPickerJava.Parse()
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




