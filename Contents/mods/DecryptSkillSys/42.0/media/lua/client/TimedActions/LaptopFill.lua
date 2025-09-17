-- Import required modules
require "TimedActions/ISBaseTimedAction"
require "client/TimedActions/ISUsbSys"
require "client/TimedActions/ISFloppySys"

local DecryptSkillDrive = require "client/TimedActions/DecryptSkillDrive"
require "shared/LaptopSystem"
require "shared/GVDrive_Utils"

print("[DecryptSkillSys] LaptopFill.lua starting to load...")

-- Function to get translated message with fallback
local function getTranslatedMessage(key, fallback)
    if not key then return fallback or "Unknown message" end
    
    local translated = getText(key)
    if translated and translated ~= key then
        return translated
    end
    
    return fallback or "Unknown message"
end

local function ensureDecryptSkillDrive()
    if DecryptSkillDrive and type(DecryptSkillDrive.new) == "function" then
        return DecryptSkillDrive
    end

    local moduleNames = {
        "client/TimedActions/DecryptSkillDrive",
        "TimedActions/DecryptSkillDrive"
    }

    for _, name in ipairs(moduleNames) do
        local ok, module = pcall(require, name)
        if ok and module and type(module.new) == "function" then
            DecryptSkillDrive = module
            return DecryptSkillDrive
        end
    end

    if _G.DecryptSkillDrive and type(_G.DecryptSkillDrive.new) == "function" then
        DecryptSkillDrive = _G.DecryptSkillDrive
        return DecryptSkillDrive
    end

    return nil
end

local function getDriveInfoSafe(item)
    if not item then return nil end
    if GVDrive_Utils and GVDrive_Utils.getDriveInfo then
        local ok, info = pcall(GVDrive_Utils.getDriveInfo, item)
        if ok and info then return info end
    end
    return nil
end

local rarityFallback = {
    Facil = { en = "Easy", es = "Facil" },
    Moderado = { en = "Moderate", es = "Moderado" },
    Dificil = { en = "Hard", es = "Dificil" }
}

local function buildDriveDisplayName(isUSB, skillName, rarity)
    if not skillName then skillName = "Unknown" end
    if not rarity then rarity = "Unknown" end

    local baseKey = isUSB and "DisplayName_SkillDrive_" or "DisplayName_SkillFloppy_"
    local translationKey = baseKey .. skillName .. "_" .. rarity
    local label = getText and getText(translationKey) or translationKey
    if label == translationKey then
        local rarityLabel = rarityFallback[rarity]
        if rarityLabel then
            local language = "EN"
            if getCore and getCore() and getCore().getOptionLanguage then
                local ok, lang = pcall(function() return getCore():getOptionLanguage() end)
                if ok and lang then language = lang end
            end
            if language == "ES" then
                rarity = rarityLabel.es
            else
                rarity = rarityLabel.en
            end
        end
        label = string.format("%s (%s)", skillName, rarity)
    end
    return label
end

local function queueDecryptActions(player, worldObj, drives)
    if not drives or #drives == 0 then return end

    -- Validate laptop health before queuing actions
    local laptopItem = worldObj
    if laptopItem and laptopItem.getItem then
        local ok, inner = pcall(function() return laptopItem:getItem() end)
        if ok and inner then laptopItem = inner end
    end

    if LaptopSystem and laptopItem then
        local health = LaptopSystem.getLaptopHealth(laptopItem)
        if health <= 0 then
            player:Say(getTranslatedMessage("GVDrive_Msg_Laptop_Broken", "This laptop doesn't work... I should find a way to repair it."))
            return
        end
    end

    local class = ensureDecryptSkillDrive()
    if not class then
        player:Say(getTranslatedMessage("GVDrive_Msg_Decrypt_Action_Failed", "Cannot start decrypt action right now."))
        return
    end

    for _, drive in ipairs(drives) do
        ISTimedActionQueue.add(class:new(player, worldObj, drive, 500))
    end
end

local function groupDrivesByInfo(driveList, isUSB)
    local groups = {}

    for _, drive in ipairs(driveList) do
        local info = getDriveInfoSafe(drive)
        local skill = (info and info.skillName) or "Unknown"
        local rarity = (info and info.rarity) or "Unknown"
        local key = skill .. "|" .. rarity

        if not groups[key] then
            groups[key] = {
                drives = {},
                skill = skill,
                rarity = rarity,
                isUSB = isUSB
            }
        end

        table.insert(groups[key].drives, drive)
    end

    local ordered = {}
    for key, data in pairs(groups) do
        data.sortKey = key
        table.insert(ordered, data)
    end
    table.sort(ordered, function(a, b) return a.sortKey < b.sortKey end)

    return ordered
end

-- Lists of allowed laptops
LaptopList = {
    "GValley.AsusZephLaptopOpened",
    "GValley.AsusZephLaptopClosed",
	"GValley.Laptop90sOpened",
	"GValley.Laptop90sClosed",
	"GValley.IBM_LP90Opened",
	"GValley.PBIBM_LP90Closed",
}

LaptopUSBAllowed = {
    "GValley.AsusZephLaptopOpened",
    "GValley.AsusZephLaptopClosed",
}

LaptopFloppyAllowed = {
	"GValley.Laptop90sOpened",
	"GValley.Laptop90sClosed",
	"GValley.IBM_LP90Opened",
	"GValley.PBIBM_LP90Closed",
}

-- Main context menu function
function LaptopOnFillWorldObjectContextMenu(player, context, worldobjects, test)
	print("[DecryptSkillSys] ==> Context menu function called for player " .. tostring(player))
	
	local playerObj = getSpecificPlayer(player)
	if not playerObj then 
		print("[DecryptSkillSys] ERROR: playerObj is nil")
		return 
	end
	
	-- Variable to prevent duplicate menu entries
	local menuAdded = false
	
	print("[DecryptSkillSys] ==> playerObj found: " .. tostring(playerObj))
	
	-- Check each world object for laptops
	for _, worldObject in ipairs(worldobjects) do
		if worldObject and worldObject.getItem then
			local item = worldObject:getItem()
			if item and item.getFullType then
				local LaptopName = item:getFullType()
				local isValidLaptop = false
				
				-- Check if this is a valid laptop
				for _, laptop in ipairs(LaptopList) do
					if LaptopName == laptop then
						isValidLaptop = true
						break
					end
				end
				
				if isValidLaptop then
					print("[DecryptSkillSys] ==> Found valid laptop: " .. LaptopName)
					
					-- Check distance
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
					
				if distance <= maxDistance and not menuAdded then
					print("[DecryptSkillSys] ==> Player is close enough to laptop")
					menuAdded = true						-- Add laptop health info
						local healthValue = 50 -- Default value
						if LaptopSystem and LaptopSystem.getLaptopHealth then
							local ok, res = pcall(LaptopSystem.getLaptopHealth, item)
							if ok and res then 
								healthValue = math.floor(res)
							end
						end
						
						-- Build long life label with state and add with icon
						local statusKey = "GVDrive_Laptop_Status_Good"
						if healthValue > 75 then
							statusKey = "GVDrive_Laptop_Status_Excellent"
						elseif healthValue > 50 then
							statusKey = "GVDrive_Laptop_Status_Good"
						elseif healthValue > 25 then
							statusKey = "GVDrive_Laptop_Status_Warning"
						elseif healthValue > 10 then
							statusKey = "GVDrive_Laptop_Status_Critical"
						else
							statusKey = "GVDrive_Laptop_Status_Failing"
						end
						local statusText = getTranslatedMessage(statusKey, "Good")
						local lifeFmt = getTranslatedMessage("GVDrive_Ctx_LaptopLife", "Laptop Condition: %d%% (%s)")
						local healthLabel = string.format(lifeFmt, healthValue, statusText)
						print("[DecryptSkillSys] ==> Adding health label: " .. healthLabel)
						local healthOption = context:addOptionOnTop(healthLabel, playerObj, function() end)
						-- Add phase icon
						local phase = 4
						if healthValue >= 80 then
							phase = 0
						elseif healthValue >= 60 then
							phase = 1
						elseif healthValue >= 40 then
							phase = 2
						elseif healthValue >= 20 then
							phase = 3
						end
						local icon = getTexture and (getTexture("media/textures/ui/needs/fatigue/background-" .. phase .. ".png") or getTexture("media/textures/ui/battery/background-" .. phase .. ".png")) or nil
						if icon then healthOption.iconTexture = icon end
						
					-- Check for skill drives in inventory and add decrypt options
					local inv = playerObj:getInventory()
					if inv then
						local items = inv:getItems()
						local skillUSBs = {}
						local skillFloppies = {}
						
						print("[DecryptSkillSys] ==> Checking " .. items:size() .. " items in inventory")
						
						-- Separate USBs and Floppies
						for i = 0, items:size() - 1 do
							local invItem = items:get(i)
							if invItem then
								local fullType = invItem:getFullType()
								if string.find(fullType, "SkillDrive_") then
									table.insert(skillUSBs, invItem)
									print("[DecryptSkillSys] ==> Found skill USB: " .. fullType)
								elseif string.find(fullType, "SkillFloppy_") then
									table.insert(skillFloppies, invItem)
									print("[DecryptSkillSys] ==> Found skill Floppy: " .. fullType)
								end
							end
						end
						
						-- Add USB decrypt option if compatible laptop and USBs available
						local isUSBCompatible = false
						for _, allowed in ipairs(LaptopUSBAllowed) do
							if LaptopName == allowed then
								isUSBCompatible = true
								break
							end
						end
						
						if isUSBCompatible and #skillUSBs > 0 then
							print("[DecryptSkillSys] ==> Adding USB decrypt options for " .. #skillUSBs .. " drives")
							for _, data in ipairs(groupDrivesByInfo(skillUSBs, true)) do
								local displayName = buildDriveDisplayName(true, data.skill, data.rarity)
								local labelFmt = getTranslatedMessage("GVDrive_Ctx_Decrypt_USB", "Decrypt %s (x%d)")
								local optionLabel = string.format(labelFmt, displayName, #data.drives)
								context:addOption(optionLabel, playerObj, queueDecryptActions, worldObject, data.drives)
							end
						end
						
						-- Add Floppy decrypt option if compatible laptop and Floppies available
						local isFloppyCompatible = false
						for _, allowed in ipairs(LaptopFloppyAllowed) do
							if LaptopName == allowed then
								isFloppyCompatible = true
								break
							end
						end
						
						
						-- Show compatibility messages if no drives or incompatible laptop
						if #skillUSBs == 0 then
							local noDrivesText = getTranslatedMessage("GVDrive_Ctx_NoSkillDrives", "No skill drives found")
							context:addOption(noDrivesText, playerObj, function() end).notAvailable = true
						elseif not isUSBCompatible then
							local tooOldText = getTranslatedMessage("GVDrive_Ctx_LaptopTooOldUSB", "Laptop too old for USB drives")
							context:addOption(tooOldText, playerObj, function() end).notAvailable = true
						end
					end
					
					print("[DecryptSkillSys] ==> Context menu options added successfully")
					break -- Exit loop after adding menu for first valid laptop
				else
					print("[DecryptSkillSys] ==> Player too far from laptop (distance: " .. distance .. ")")
				end
				end
			end
		end
	end
end

-- Register the context menu event
print("[DecryptSkillSys] ==> Registering context menu event...")
Events.OnFillWorldObjectContextMenu.Add(LaptopOnFillWorldObjectContextMenu)
print("[DecryptSkillSys] ==> Context menu event registered successfully")

print("[DecryptSkillSys] LaptopFill.lua loaded successfully")
