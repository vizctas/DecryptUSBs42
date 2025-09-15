-- Import required modules
require "TimedActions/ISBaseTimedAction"
require "client/TimedActions/ISUsbSys"
require "client/TimedActions/ISFloppySys"

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

function LaptopOnFillWorldObjectContextMenu(player, context, worldobjects, test)
	local playerObj = getSpecificPlayer(player)
	if not playerObj then return end
	
	local inv = playerObj:getInventory()
	if not inv then return end
	
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
					-- Simplified line of sight check for PZ42 compatibility
					local hasLineOfSight = true
					if LosUtil and LosUtil.lineClear then
						local lineOfSightTestResults = LosUtil.lineClear(playerObj:getCell(), objX, objY, objZ, pX, pY, pZ, false)
						hasLineOfSight = tostring(lineOfSightTestResults) ~= "Blocked"
					end
					
					if hasLineOfSight then
						if inv:getItemCount("GValley.USBOpened") > 0 then
							context:addOptionOnTop(getText("GVDrive_Ctx_Decrypt_Drive") or "Decrypt drive", playerObj, DecryptMyUSBPlease, worldObject, LaptopName)
						end
						if inv:getItemCount("GValley.FloppyDrive") > 0 then
							context:addOptionOnTop(getText("GVDrive_Ctx_Check_Floppy") or "Check Floppy Disk", playerObj, DecryptMyFloppyPlease, worldObject, LaptopName)
						end
					end
				end
			end
		end
	end
end

Events.OnFillWorldObjectContextMenu.Add(LaptopOnFillWorldObjectContextMenu)
