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

local function DecryptMyUSBPlease(playerObj, Item, LaptopModel)
    local time = 500
    local player = playerObj
    if not player then return end

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

function LaptopOnFillWorldObjectContextMenu(player, context, worldobjects, test)
	local playerObj = getSpecificPlayer(player)
	if not playerObj then return end
	
	local inv = playerObj:getInventory()
	local squares = {}
	local doneSquare = {}
	
	for i, v in ipairs(worldobjects) do
		if v:getSquare() and not doneSquare[v:getSquare()] then
			doneSquare[v:getSquare()] = true
			table.insert(squares, v:getSquare())
		end
	end
	
	if #squares == 0 then return false end
	
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
			ISWorldObjectContextMenu.getSquaresInRadius(square:getX(), square:getY(), square:getZ(), radius, doneSquare, squares)
		end
        GVDrive_getWorldObjectsOnSquares(squares, worldObjects)
	end
	
	if #worldObjects == 0 then return false end
	
	for _, worldObject in ipairs(worldObjects) do
		local item = worldObject:getItem()
		if not item then goto continue end
		
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
				local lineOfSightTestResults = LosUtil.lineClear(playerObj:getCell(), objX, objY, objZ, pX, pY, pZ, false)
				
				if tostring(lineOfSightTestResults) ~= "Blocked" then
					if inv:getItemCount("GValley.USBOpened") > 0 then
						context:addOptionOnTop("Decrypt drive", playerObj, DecryptMyUSBPlease, worldObject, LaptopName)
					end
					if inv:getItemCount("GValley.FloppyDrive") > 0 then
						context:addOptionOnTop("Check Floppy Disk", playerObj, DecryptMyFloppyPlease, worldObject, LaptopName)
					end
				end
			end
		end
		
		::continue::
	end
end

Events.OnFillWorldObjectContextMenu.Add(LaptopOnFillWorldObjectContextMenu)
