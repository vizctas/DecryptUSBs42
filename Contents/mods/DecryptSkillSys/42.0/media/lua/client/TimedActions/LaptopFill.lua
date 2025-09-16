-- Import required modules
require "TimedActions/ISBaseTimedAction"
require "client/TimedActions/ISUsbSys"
require "client/TimedActions/ISFloppySys" 
require "client/TimedActions/DecryptSkillDrive"
require "shared/LaptopSystem"
require "shared/GVDrive_Utils"

LaptopList = {
    "GValley.AsusZephLaptopOpened",
	"GValley.Laptop90sOpened",
	"GValley.IBM_LP90Opened",
}

LaptopUSBAllowed = {
    "GValley.AsusZephLaptopOpened",
}

LaptopFloppyAllowed = {
	"GValley.Laptop90sOpened",
	"GValley.IBM_LP90Opened",
}

-- Fallback safe_getDriveInfo: try GVDrive_Utils.getDriveInfo, otherwise parse fullType
local function safe_getDriveInfo(item)
    if not item then return nil end
    -- Prefer official util if available
    if GVDrive_Utils and GVDrive_Utils.getDriveInfo then
        local ok, res = pcall(GVDrive_Utils.getDriveInfo, item)
        if ok then return res end
    end

    -- Basic fallback parsing from full type (e.g., GValley.SkillDrive_Electricity_Facil)
    local fullType = tostring(item:getFullType() or "")
    local name = fullType:match("([^%.]+)%.(.+)") or fullType
    -- Normalize to last component
    local short = fullType:match("([^%.]+)$") or fullType
    if string.find(short, "SkillDrive_") or string.find(short, "SkillFloppy_") then
        local parts = {}
        for part in string.gmatch(short, "([^_]+)") do table.insert(parts, part) end
        if #parts >= 3 then
            return {
                skillName = parts[2],
                rarity = parts[3], -- Now supports Facil/Moderado/Dificil
                isUSB = string.find(short, "SkillDrive_") ~= nil,
            }
        end
    end
    -- Legacy types
    if short == "USB_Closed" or short == "USBOpened" or short == "USBOpened_Damaged" then
        return { skillName = "LegacyUSB", rarity = "Normal", isUSB = true }
    end
    if short == "FloppyDrive" then
        return { skillName = "LegacyFloppy", rarity = "Normal", isUSB = false }
    end
    return nil
end

-- Get all skill drives in inventory (FIXED TO DETECT SPECIALIZED DRIVES)
local function getSkillDrives(inventory, driveType)
    local drives = {}
    
    if not inventory then return drives end
    
    print("[DecryptSkillSys] getSkillDrives: Looking for " .. driveType .. " drives")
    
    -- Get all items in inventory using getItems() instead of getAllType()
    local items = inventory:getItems()
    print("[DecryptSkillSys] Checking " .. items:size() .. " items in inventory")
    
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local fullType = item:getFullType()
            print("[DecryptSkillSys] Checking item: " .. fullType)
            
            -- Check for skill-specific drives
            if driveType == "USB" then
                -- Look for SkillDrive_ pattern (USBs)
                if string.find(fullType, "SkillDrive_") then
                    print("[DecryptSkillSys] Found skill USB: " .. fullType)
                    table.insert(drives, item)
                end
            elseif driveType == "Floppy" then
                -- Look for SkillFloppy_ pattern (Floppies)  
                if string.find(fullType, "SkillFloppy_") then
                    print("[DecryptSkillSys] Found skill Floppy: " .. fullType)
                    table.insert(drives, item)
                end
            end
        end
    end
    
    -- Also include legacy drives for backward compatibility
    if driveType == "USB" then
        local count = inventory:getItemCount("GValley.USB_Closed")
        if count > 0 then
            local item = inventory:getFirstTypeEvalRecurse("GValley.USB_Closed", function(item) return true end)
            if item then
                table.insert(drives, item)
            end
        end
    elseif driveType == "Floppy" then
        local count = inventory:getItemCount("GValley.FloppyDrive")
        if count > 0 then
            local item = inventory:getFirstTypeEvalRecurse("GValley.FloppyDrive", function(item) return true end)
            if item then
                table.insert(drives, item)
            end
        end
    end
    
    return drives
end

local decryptSkillDriveModuleNames = {
    "client/TimedActions/DecryptSkillDrive",
    "TimedActions/DecryptSkillDrive",
}

local cachedDecryptSkillDriveClass = nil

local function getDecryptSkillDriveClass()
    print("[DecryptSkillSys] getDecryptSkillDriveClass called")
    if cachedDecryptSkillDriveClass and type(cachedDecryptSkillDriveClass.new) == "function" then
        print("[DecryptSkillSys] Using cached DecryptSkillDrive class")
        return cachedDecryptSkillDriveClass
    end

    if DecryptSkillDrive and type(DecryptSkillDrive.new) == "function" then
        print("[DecryptSkillSys] Using global DecryptSkillDrive class")
        cachedDecryptSkillDriveClass = DecryptSkillDrive
        return cachedDecryptSkillDriveClass
    end

    print("[DecryptSkillSys] DecryptSkillDrive not found globally, checking package.loaded")
    if package and package.loaded then
        for _, moduleName in ipairs(decryptSkillDriveModuleNames) do
            local loaded = package.loaded[moduleName]
            if type(loaded) == "table" and type(loaded.new) == "function" then
                cachedDecryptSkillDriveClass = loaded
                if not DecryptSkillDrive or type(DecryptSkillDrive.new) ~= "function" then
                    DecryptSkillDrive = loaded
                end
                return cachedDecryptSkillDriveClass
            end
        end
    end

    for _, moduleName in ipairs(decryptSkillDriveModuleNames) do
        local ok, module = pcall(require, moduleName)
        if ok then
            if type(module) == "table" and type(module.new) == "function" then
                cachedDecryptSkillDriveClass = module
                if not DecryptSkillDrive or type(DecryptSkillDrive.new) ~= "function" then
                    DecryptSkillDrive = module
                end
                return cachedDecryptSkillDriveClass
            end

            if DecryptSkillDrive and type(DecryptSkillDrive.new) == "function" then
                cachedDecryptSkillDriveClass = DecryptSkillDrive
                return cachedDecryptSkillDriveClass
            end
        else
            print("[DecryptSkillSys] ERROR: require(" .. moduleName .. ") failed: " .. tostring(module))
        end
    end

    print("[DecryptSkillSys] ERROR: DecryptSkillDrive class not available even after require attempts")
    return nil
end

local function DecryptMySkillDrivesPlease(playerObj, Item, LaptopModel, driveType)
    local time = 500
    local player = playerObj
    if not player then return end

    -- Check if laptop can be used (power and health)
    local canUse, errorMsg = LaptopSystem.canUseLaptop(player, Item)
    if not canUse then
        player:Say(getText(errorMsg))
        return
    end

    local isCompatible = false
    local allowedList = driveType == "USB" and LaptopUSBAllowed or LaptopFloppyAllowed
    
    for _, allowed in ipairs(allowedList) do
        if LaptopModel == allowed then
            isCompatible = true
            break
        end
    end
    
    if isCompatible then
        local drives = getSkillDrives(playerObj:getInventory(), driveType)
        local actionClass = getDecryptSkillDriveClass()
        if not actionClass then
            player:Say(getText("GVDrive_Msg_Decrypt_Action_Failed") or "Cannot start decrypt action right now.")
            return
        end

        for _, drive in ipairs(drives) do
            ISTimedActionQueue.add(actionClass:new(playerObj, Item, drive, time))
        end

        if #drives == 0 then
            player:Say(getText("GVDrive_Msg_No_Drives") or "No drives found!")
        end
    else
        if driveType == "USB" then
            player:Say(getText("GVDrive_Msg_UsbTooOldLaptop"))
        else
            player:Say(getText("GVDrive_Msg_NeedsFloppyLaptop"))
        end
        print(LaptopModel)
    end
end

local function DecryptMyUSBPlease(playerObj, Item, LaptopModel)
    local time = 500
    local player = playerObj
    if not player then return end

    -- Check if laptop can be used (power and health)
    local canUse, errorMsg = LaptopSystem.canUseLaptop(player, Item)
    if not canUse then
        player:Say(getText(errorMsg))
        return
    end

	local isUSBCompatible = false
	for _, allowed in ipairs(LaptopUSBAllowed) do
		if LaptopModel == allowed then
			isUSBCompatible = true
			break
		end
	end
	
	if isUSBCompatible then
		local cnt = playerObj:getInventory():getItemCount("GValley.USBOpened")
		for i = 1, cnt do
			ISTimedActionQueue.add(DecryptDrive:new(playerObj, Item, time))
		end
    else
        player:Say(getText("GVDrive_Msg_UsbTooOldLaptop"))
        print(LaptopModel)
    end
end

local function DecryptMyFloppyPlease(playerObj, Item, LaptopModel)
    local time = 500
    local player = playerObj
    if not player then return end

    -- Check if laptop can be used (power and health)
    local canUse, errorMsg = LaptopSystem.canUseLaptop(player, Item)
    if not canUse then
        player:Say(getText(errorMsg))
        return
    end
	
	local isFloppyCompatible = false
	for _, allowed in ipairs(LaptopFloppyAllowed) do
		if LaptopModel == allowed then
			isFloppyCompatible = true
			break
		end
	end
	
	if isFloppyCompatible then
		local cnt = playerObj:getInventory():getItemCount("GValley.FloppyDrive")
		for i = 1, cnt do
			ISTimedActionQueue.add(DecryptFloppyDisk:new(playerObj, Item, time))
		end
    else
        player:Say(getText("GVDrive_Msg_NeedsFloppyLaptop"))
        print(LaptopModel)
    end
end

-- Local helper to avoid overriding base functions
local function GVDrive_getWorldObjectsOnSquares(squares, worldObjects)
    for _, square in ipairs(squares) do
        local squareObjects = square:getWorldObjects()
        for i = 1, squareObjects:size() do
            local worldObject = squareObjects:get(i-1)
            table.insert(worldObjects, worldObject)
        end
    end
end

-- B42 compatibility: fallback for getSquaresInRadius if missing
local function GVDrive_getSquaresInRadius(cx, cy, cz, radius, doneSquare, outSquares)
    local cell = getCell and getCell() or nil
    if not cell then return end
    for dx = -radius, radius do
        for dy = -radius, radius do
            local sq = cell:getGridSquare(cx + dx, cy + dy, cz)
            if sq and not doneSquare[sq] then
                doneSquare[sq] = true
                table.insert(outSquares, sq)
            end
        end
    end
end

-- NEW FUNCTION: Decrypt specific skill drive type (moved here to be defined before use)
local function DecryptSpecificSkillDrive(playerObj, worldObject, LaptopModel, driveType, skillName, rarity)
    print("[DecryptSkillSys] DecryptSpecificSkillDrive called with:", driveType, skillName, rarity)
    local time = 500
    local player = playerObj
    if not player then 
        print("[DecryptSkillSys] ERROR: No player object")
        return 
    end

    -- Get the laptop item from the world object
    local Item = worldObject:getItem()
    if not Item then
        print("[DecryptSkillSys] ERROR: Could not get item from world object")
        return
    end

    -- Check if laptop can be used (power and health)
    local canUse, errorMsg = LaptopSystem.canUseLaptop(player, Item)
    if not canUse then
        print("[DecryptSkillSys] Laptop cannot be used:", errorMsg)
        player:Say(getText(errorMsg))
        return
    end

    local isCompatible = false
    local allowedList = driveType == "USB" and LaptopUSBAllowed or LaptopFloppyAllowed
    
    for _, allowed in ipairs(allowedList) do
        if LaptopModel == allowed then
            isCompatible = true
            break
        end
    end
    
    print("[DecryptSkillSys] Laptop compatibility check:", isCompatible, "Model:", LaptopModel)
    
    if isCompatible then
        -- Find drives of the specific type (skill + rarity)
        local inv = playerObj:getInventory()
        local targetDrives = {}
        
        local items = inv:getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item then
                local driveInfo = safe_getDriveInfo(item)
                if driveInfo and driveInfo.skillName == skillName and driveInfo.rarity == rarity then
                    if (driveType == "USB" and driveInfo.isUSB) or (driveType == "Floppy" and not driveInfo.isUSB) then
                        table.insert(targetDrives, item)
                        print("[DecryptSkillSys] Found target drive:", item:getType())
                    end
                end
            end
        end
        
        print("[DecryptSkillSys] Found", #targetDrives, "target drives")
        
        -- Queue decrypt actions for all matching drives
        local actionClass = getDecryptSkillDriveClass()
        if not actionClass then
            print("[DecryptSkillSys] ERROR: Could not get DecryptSkillDrive class!")
            player:Say(getText("GVDrive_Msg_Decrypt_Action_Failed") or "Cannot start decrypt action right now.")
            return
        end

        print("[DecryptSkillSys] actionClass found:", tostring(actionClass))
        for _, drive in ipairs(targetDrives) do
            print("[DecryptSkillSys] Adding DecryptSkillDrive action for:", drive:getType())
            print("[DecryptSkillSys] Calling actionClass:new with params - player:", tostring(playerObj), "worldObject:", tostring(worldObject), "drive:", tostring(drive), "time:", tostring(time))
            ISTimedActionQueue.add(actionClass:new(playerObj, worldObject, drive, time))
        end
        
        if #targetDrives == 0 then
            player:Say(getText("GVDrive_Msg_No_Drives") or "No matching drives found!")
        end
    else
        if driveType == "USB" then
            player:Say(getText("GVDrive_Msg_UsbTooOldLaptop"))
        else
            player:Say(getText("GVDrive_Msg_NeedsFloppyLaptop"))
        end
        print(LaptopModel)
    end
end

function LaptopOnFillWorldObjectContextMenu(player, context, worldobjects, test)
	print("[DecryptSkillSys] Context menu function called for player " .. tostring(player))
	local playerObj = getSpecificPlayer(player)
	if not playerObj then 
		print("[DecryptSkillSys] WARNING: playerObj is nil")
		return 
	end
	
	local inv = playerObj:getInventory()
	if not inv then 
		print("[DecryptSkillSys] WARNING: inventory is nil")
		return 
	end
	
	local squares = {}
	local doneSquare = {}
	
	for i, v in ipairs(worldobjects) do
		if v and v:getSquare() and not doneSquare[v:getSquare()] then
			doneSquare[v:getSquare()] = true
			table.insert(squares, v:getSquare())
		end
	end
	
	if #squares == 0 then return end
	
	local worldObjects = {}
	if JoypadState.players[player+1] then
		for _, square in ipairs(squares) do
			for i = 1, square:getWorldObjects():size() do
				local worldObject = square:getWorldObjects():get(i-1)
				table.insert(worldObjects, worldObject)
			end
		end
	else
		local squares2 = {}
		for k, v in pairs(squares) do
			squares2[k] = v
		end
        local radius = 1
        for _, square in ipairs(squares2) do
            if ISWorldObjectContextMenu and ISWorldObjectContextMenu.getSquaresInRadius then
                ISWorldObjectContextMenu.getSquaresInRadius(square:getX(), square:getY(), square:getZ(), radius, doneSquare, squares)
            else
                GVDrive_getSquaresInRadius(square:getX(), square:getY(), square:getZ(), radius, doneSquare, squares)
            end
        end
        GVDrive_getWorldObjectsOnSquares(squares, worldObjects)
    end
	
	if #worldObjects == 0 then return false end
	
	for _, worldObject in ipairs(worldObjects) do
		local item = worldObject:getItem()
		if item then
			local LaptopName = item:getFullType()
			local isValidLaptop = false
			
			for _, laptop in ipairs(LaptopList) do
				if LaptopName == laptop then
					isValidLaptop = true
					break
				end
			end
			
			if isValidLaptop then
				local maxDistance = 1.4
				local objX = worldObject:getX() + 0.5
				local objY = worldObject:getY() + 0.5
				local objZ = worldObject:getZ()
				local pX = playerObj:getX()
				local pY = playerObj:getY()
				local pZ = playerObj:getZ()
				
				local dX = objX - pX
				local dY = objY - pY
				local dZ = objZ - pZ
				local distance = math.sqrt(dX*dX + dY*dY + dZ*dZ)
				
				if distance <= maxDistance then
					-- Get laptop health and create a modern health display
					local laptopHealthValue = LaptopSystem.getLaptopHealth(item) or 0
					local healthLabel = getText("GVDrive_Laptop_Health_Label") or "Laptop Health"
					
					-- Create a modern health display with color coding
					local healthPercent = math.floor(laptopHealthValue)
					local healthIcon = ""
					local healthColor = ""
					
					if healthPercent >= 80 then
						healthIcon = "💚"
						healthColor = "<RGB:0.4,1.0,0.4>"
					elseif healthPercent >= 60 then
						healthIcon = "💛"
						healthColor = "<RGB:1.0,1.0,0.4>"
					elseif healthPercent >= 40 then
						healthIcon = "🧡"
						healthColor = "<RGB:1.0,0.8,0.4>"
					elseif healthPercent >= 20 then
						healthIcon = "❤️"
						healthColor = "<RGB:1.0,0.6,0.4>"
					else
						healthIcon = "💀"
						healthColor = "<RGB:1.0,0.4,0.4>"
					end
					
					local healthOption = context:addOptionOnTop(string.format("%s %s %s: %d%%", healthIcon, healthLabel, healthColor, healthPercent))
					healthOption.notAvailable = true
					
					-- Simplified line of sight check for PZ42 compatibility  
					local hasLineOfSight = true
					if LosUtil and LosUtil.lineClear then
						local lineOfSightTestResults = LosUtil.lineClear(playerObj:getCell(), objX, objY, objZ, pX, pY, pZ, false)
						hasLineOfSight = tostring(lineOfSightTestResults) ~= "Blocked"
					end
					
					if hasLineOfSight then
						-- Get skill drives for menu
						local skillUSBs = getSkillDrives(inv, "USB")
						local skillFloppies = getSkillDrives(inv, "Floppy")
						
						-- Add individual menu items for each skill USB type
						if #skillUSBs > 0 then
							local usbsByType = {}
							for _, usb in ipairs(skillUSBs) do
								print("[DecryptSkillSys] Processing USB: " .. tostring(usb:getType()) .. " (Full: " .. tostring(usb:getFullType()) .. ")")
								
                                local driveInfo = safe_getDriveInfo(usb)
								if driveInfo then
									print("[DecryptSkillSys] Drive info: " .. driveInfo.skillName .. " " .. driveInfo.rarity)
									local menuKey = driveInfo.skillName .. "_" .. driveInfo.rarity
									if not usbsByType[menuKey] then
										usbsByType[menuKey] = {
											count = 0,
											skill = driveInfo.skillName,
											rarity = driveInfo.rarity,
											item = usb
										}
									end
									usbsByType[menuKey].count = usbsByType[menuKey].count + 1
								else
									print("[DecryptSkillSys] WARNING: Could not get drive info for " .. tostring(usb:getType()))
								end
							end
							
							-- Add menu options for each USB type
							for menuKey, usbData in pairs(usbsByType) do
								local skillName = usbData.skill
								local rarity = usbData.rarity
								local count = usbData.count
								local menuText = string.format("Decrypt %s USB (%s) x%d", skillName, rarity, count)
								print("[DecryptSkillSys] Adding menu option: " .. menuText)
								print("[DecryptSkillSys] Menu parameters: playerObj=" .. tostring(playerObj) .. ", worldObject=" .. tostring(worldObject) .. ", LaptopName=" .. tostring(LaptopName))
								context:addOptionOnTop(menuText, playerObj, DecryptSpecificSkillDrive, worldObject, LaptopName, "USB", skillName, rarity)
							end
						end
						
						-- Add individual menu items for each skill Floppy type
						if #skillFloppies > 0 then
							local floppiesByType = {}
							for _, floppy in ipairs(skillFloppies) do
                                local driveInfo = safe_getDriveInfo(floppy)
								if driveInfo then
									local menuKey = driveInfo.skillName .. "_" .. driveInfo.rarity
									if not floppiesByType[menuKey] then
										floppiesByType[menuKey] = {
											count = 0,
											skill = driveInfo.skillName,
											rarity = driveInfo.rarity,
											item = floppy
										}
									end
									floppiesByType[menuKey].count = floppiesByType[menuKey].count + 1
								end
							end
							
							-- Add menu options for each Floppy type
							for menuKey, floppyData in pairs(floppiesByType) do
								local skillName = floppyData.skill
								local rarity = floppyData.rarity
								local count = floppyData.count
								local menuText = string.format("Decrypt %s Floppy (%s) x%d", skillName, rarity, count)
								print("[DecryptSkillSys] Adding floppy menu option: " .. menuText)
								context:addOptionOnTop(menuText, playerObj, DecryptSpecificSkillDrive, worldObject, LaptopName, "Floppy", skillName, rarity)
							end
						end
						
						-- Legacy options removed - only use new skill-specific decrypt options
					end
				end
			end
		end
	end
end

Events.OnFillWorldObjectContextMenu.Add(LaptopOnFillWorldObjectContextMenu)
print("[DecryptSkillSys] Context menu event handler registered successfully")
print("[DecryptSkillSys] LaptopFill.lua v42 compatibility FIXED - getAllType() replaced with getItems()")

-- Verify that GVDrive_Utils is loaded
if GVDrive_Utils then
    print("[DecryptSkillSys] GVDrive_Utils loaded successfully")
else
    print("[DecryptSkillSys] WARNING: GVDrive_Utils not loaded - attempting manual require")
    local success = pcall(require, "shared/GVDrive_Utils")
    if success and GVDrive_Utils then
        print("[DecryptSkillSys] GVDrive_Utils loaded after manual require")
    else
        print("[DecryptSkillSys] CRITICAL: Failed to load GVDrive_Utils")
    end
end
