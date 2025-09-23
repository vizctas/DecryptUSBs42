-- DecryptDrivesContextMenu.lua
-- Context menu system for Decrypt USBs mod
-- Based on CODEBASE patterns from PATRONES_UI_Y_MINIJUEGOS.md

print("[DecryptSkillSys] Loading DecryptDrivesContextMenu (DEBUG MODE)...")

-- ============================================================================
-- CONFIGURATION CONSTANTS
-- ============================================================================

local DECRYPT_CONFIG = {
    LAPTOP_TYPES = {
        "AsusZephLaptopOpened",    -- ASUS Zephyrus M (Opened)
        "Laptop90sOpened",         -- Toshiba Satellite Pro (Opened)
        "IBM_LP90Opened"           -- IBM Palm Top PC 110 (Opened)
    },
    USB_PATTERN = "SkillDrive_",
    DIFFICULTIES = {"Facil", "Moderado", "Dificil"},  -- Nombres en español según scripts
    DIFFICULTY_MAP = {                              -- Mapeo a nombres en inglés
        ["Facil"] = "Easy",
        ["Moderado"] = "Moderate",
        ["Dificil"] = "Expert"
    },
    MENU_TEXT = {
        MAIN = "Decrypt Drives",
        USB_PREFIX = "USB "
    }
}

-- ============================================================================
-- MAIN MODULE
-- ============================================================================

local DecryptDrivesContextMenu = {}
-- Indicate that this module provides a modern hierarchical context menu.
-- Other legacy code (e.g., LaptopFill.lua) can check this flag to avoid adding duplicate menus.
DecryptDrivesContextMenu.MODERN_MENU_ACTIVE = true
-- Also set a global flag so legacy modules can detect this module regardless of require/load order
pcall(function()
    _G.DecryptDrivesContextMenu_MODERN = true
end)

-- ============================================================================
-- LAPTOP VALIDATION FUNCTIONS
-- ============================================================================

-- Validate if worldObject is a valid laptop for decryption
-- Enhanced debugging version
function DecryptDrivesContextMenu.isValidLaptop(worldObject)
    print("[DecryptSkillSys][DEBUG] isValidLaptop called")

    if not worldObject then
        print("[DecryptSkillSys][DEBUG] worldObject is nil")
        return false, "No object provided"
    end

    print("[DecryptSkillSys][DEBUG] worldObject type: " .. tostring(worldObject:getClass():getName()))

    -- Must be a world object (not inventory item)
    if not instanceof(worldObject, "IsoObject") then
        print("[DecryptSkillSys][DEBUG] Not an IsoObject: " .. tostring(worldObject:getClass():getName()))
        return false, "Not a world object"
    end

    -- Robustly attempt to get the underlying item for this world object
    local function tryGetItem(obj)
        if not obj then return nil end
        -- First try direct getItem if present (safe pcall)
    if not item then
        print("[DecryptSkillSys][DEBUG] No item in world object")
        return false, "No item in world object"
    end

    -- Check if it's a laptop type
    local itemType = item:getFullType() or item:getType() or ""
    local isLaptop = false

    for _, laptopType in ipairs(DECRYPT_CONFIG.LAPTOP_TYPES) do
        if itemType:find(laptopType) then
            isLaptop = true
            print("[DecryptSkillSys][DEBUG] Laptop type match: " .. laptopType)
            break
        end
    end

    if not isLaptop then
        print("[DecryptSkillSys][DEBUG] Not a valid laptop type: " .. itemType)
        return false, "Not a valid laptop type: " .. itemType
    end

    print("[DecryptSkillSys][DEBUG] Valid laptop detected!")
    return true, "Valid laptop"
end

-- ============================================================================
-- USB SCANNING AND GROUPING FUNCTIONS
-- ============================================================================

-- Scan player inventory for USB drives
function DecryptDrivesContextMenu.scanPlayerUSBs(player)
    print("[DecryptSkillSys][DEBUG] scanPlayerUSBs called")

    if not player then
        print("[DecryptSkillSys][DEBUG] Player is nil")
        return {}
    end

    local inventory = player:getInventory()
    if not inventory then
        print("[DecryptSkillSys][DEBUG] No inventory found")
        return {}
    end

    local items = inventory:getItems()
    print("[DecryptSkillSys][DEBUG] Inventory items count: " .. items:size())

    local usbList = {}

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item then
            local fullType = item:getFullType() or item:getType() or ""
            print("[DecryptSkillSys][DEBUG] Item " .. i .. ": " .. fullType)

            -- Check if it's a USB drive
            if fullType:find(DECRYPT_CONFIG.USB_PATTERN) then
                print("[DecryptSkillSys][DEBUG] USB drive found: " .. fullType)
                local usbData = DecryptDrivesContextMenu.parseUSBData(item, fullType)
                if usbData then
                    table.insert(usbList, usbData)
                    print("[DecryptSkillSys][DEBUG] USB added to list")
                else
                    print("[DecryptSkillSys][DEBUG] Failed to parse USB data")
                end
            end
        end
    end

    print("[DecryptSkillSys][DEBUG] USB scan completed, found " .. #usbList .. " USBs")
    return usbList
end

-- Parse USB data from item and fullType
function DecryptDrivesContextMenu.parseUSBData(item, fullType)
    print("[DecryptSkillSys][DEBUG] parseUSBData called with: " .. tostring(fullType))

    local parts = {}
    for part in fullType:gmatch("([^_]+)") do
        table.insert(parts, part)
    end

    print("[DecryptSkillSys][DEBUG] Parts found: " .. #parts)
    for i, part in ipairs(parts) do
        print("[DecryptSkillSys][DEBUG] Part " .. i .. ": " .. part)
    end

    if #parts < 3 then
        print("[DecryptSkillSys][DEBUG] Invalid USB format: " .. fullType)
        return nil
    end

    local skill = parts[2]
    local difficulty_spanish = parts[3]
    local difficulty_english = DECRYPT_CONFIG.DIFFICULTY_MAP[difficulty_spanish]

    if not difficulty_english then
        print("[DecryptSkillSys][DEBUG] Unknown difficulty: " .. difficulty_spanish)
        return nil
    end

    local usbData = {
        item = item,
        skill = skill,
        difficulty_spanish = difficulty_spanish,
        difficulty_english = difficulty_english,
        displayName = DECRYPT_CONFIG.MENU_TEXT.USB_PREFIX .. skill .. " (" .. difficulty_spanish .. ")",
        fullType = fullType
    }

    print("[DecryptSkillSys][DEBUG] USB parsed successfully: " .. usbData.displayName)
    return usbData
end

-- Group USBs by skill for hierarchical menu
function DecryptDrivesContextMenu.groupUSBsBySkill(usbList)
    print("[DecryptSkillSys][DEBUG] groupUSBsBySkill called with " .. #usbList .. " USBs")

    local grouped = {}

    for _, usbData in ipairs(usbList) do
        local skill = usbData.skill
        if not grouped[skill] then
            grouped[skill] = {}
        end

        table.insert(grouped[skill], usbData)
    end

    -- Sort difficulties within each skill (using English mapping)
    for skill, usbs in pairs(grouped) do
        table.sort(usbs, function(a, b)
            local diffOrder = {["Easy"] = 1, ["Moderate"] = 2, ["Expert"] = 3}
            local aOrder = diffOrder[a.difficulty_english] or 999
            local bOrder = diffOrder[b.difficulty_english] or 999
            return aOrder < bOrder
        end)
    end

    return grouped
end

-- ============================================================================
-- CONTEXT MENU CREATION
-- ============================================================================

-- Main context menu handler
-- Main context menu handler (restore)
function DecryptDrivesContextMenu.addContextMenuOption(player, context, worldobjects, test)
    print("[DecryptSkillSys][DEBUG] addContextMenuOption called")

    -- Skip if test mode
    if test then
        print("[DecryptSkillSys][DEBUG] Test mode, skipping")
        return
    end

    -- Validate parameters
    -- Normalize player: events may pass player index or player object
    local playerObj = nil
    if player then
        -- If caller passed index (number), convert to player object
        if type(player) == "number" then
            playerObj = getSpecificPlayer(player)
        else
            playerObj = player
        end
    end

    if not playerObj or not context or not worldobjects then
        print("[DecryptSkillSys][DEBUG] Missing parameters in addContextMenuOption")
        return
    end

    -- Helper: try to find a laptop from worldobjects, square contents, or player inventory
    local function findLaptopForContext(player, worldobjects)
        -- 1) Check worldobjects directly using isValidLaptop
        for i, worldObject in ipairs(worldobjects) do
            print("[DecryptSkillSys][DEBUG] Checking worldObject " .. i)
            local ok, reason = pcall(function() return DecryptDrivesContextMenu.isValidLaptop(worldObject) end)
            if ok then
                local isValid, msg = DecryptDrivesContextMenu.isValidLaptop(worldObject)
                if isValid then
                    print("[DecryptSkillSys][DEBUG] Valid laptop found in worldobjects")
                    return worldObject
                else
                    print("[DecryptSkillSys][DEBUG] Not valid laptop in worldobject: " .. tostring(msg))
                end
            end
        end

        -- 2) Scan squares of worldobjects for an item whose fullType matches laptop types
        for i, worldObject in ipairs(worldobjects) do
            if worldObject and worldObject.getSquare then
                local ok, sq = pcall(function() return worldObject:getSquare() end)
                if ok and sq and sq.getObjects then
                    local objs = sq:getObjects()
                    for j = 0, objs:size() - 1 do
                        local o = objs:get(j)
                        if o then
                                -- Some world objects are IsoWorldInventoryObject and still have getItem
                                local itemCandidate = nil
                                if o.getItem then
                                    local ok2, it = pcall(function() return o:getItem() end)
                                    if ok2 and it then
                                        itemCandidate = it
                                    end
                                end

                                if itemCandidate then
                                    local ft = (itemCandidate.getFullType and itemCandidate:getFullType()) or (itemCandidate.getType and itemCandidate:getType()) or ""
                                    local ftLower = tostring(ft):lower()
                                    for _, laptopType in ipairs(DECRYPT_CONFIG.LAPTOP_TYPES) do
                                        local ltLower = tostring(laptopType):lower()
                                        if ftLower:find(ltLower) or ftLower:find("laptop") then
                                            print("[DecryptSkillSys][DEBUG] Found laptop item in square: " .. tostring(ft))
                                            return o
                                        end
                                    end
                                end
                            end
                    end
                end
            end
        end

        -- 3) Fallback: check player's inventory for a laptop item
        if player and player.getInventory then
            local inv = player:getInventory()
            if inv and inv.getItems then
                local items = inv:getItems()
                        for k = 0, items:size() - 1 do
                    local it = items:get(k)
                    if it and it.getFullType then
                        local ft = it:getFullType() or it:getType() or ""
                        local ftLower = tostring(ft):lower()
                        for _, laptopType in ipairs(DECRYPT_CONFIG.LAPTOP_TYPES) do
                            local ltLower = tostring(laptopType):lower()
                            if ftLower:find(ltLower) or ftLower:find("laptop") then
                                print("[DecryptSkillSys][DEBUG] Found laptop in player inventory: " .. tostring(ft))
                                local pseudo = { getItem = function() return it end }
                                return pseudo
                            end
                        end
                    end
                end
            end
        end

        return nil
    end

    local laptopCandidate = findLaptopForContext(playerObj, worldobjects)
    if laptopCandidate then
        -- Scan for USBs in player inventory
        local usbList = DecryptDrivesContextMenu.scanPlayerUSBs(playerObj)
        if #usbList > 0 then
            print("[DecryptSkillSys][DEBUG] USBs found: " .. #usbList)
            DecryptDrivesContextMenu.createHierarchicalMenu(playerObj, context, laptopCandidate, usbList)
            return
        else
            print("[DecryptSkillSys][DEBUG] No USBs found in player inventory - falling back to legacy options if available")
            -- Legacy fallback: if the player has the old items (USBOpened / FloppyDrive) add top-level options
            local inv = nil
            if playerObj and playerObj.getInventory then
                inv = playerObj:getInventory()
            end
            if inv then
                -- attempt to determine a laptop model string for legacy handlers
                local laptopModel = nil
                if laptopCandidate and laptopCandidate.getItem then
                    local ok, it = pcall(function() return laptopCandidate:getItem() end)
                    if ok and it and it.getFullType then
                        laptopModel = it:getFullType()
                    end
                end

                if inv:getItemCount("USBOpened") > 0 then
                    print("[DecryptSkillSys][DEBUG] Adding legacy Decrypt drive option (USBOpened present)")
                    context:addOptionOnTop("Decrypt drive", playerObj, DecryptDrivesContextMenu.LegacyDecryptUSB, laptopCandidate, laptopModel)
                end
                if inv:getItemCount("FloppyDrive") > 0 then
                    print("[DecryptSkillSys][DEBUG] Adding legacy Check Floppy Disk option (FloppyDrive present)")
                    context:addOptionOnTop("Check Floppy Disk", playerObj, DecryptDrivesContextMenu.LegacyDecryptFloppy, laptopCandidate, laptopModel)
                end
                return
            end
            return
        end
    else
        print("[DecryptSkillSys][DEBUG] No laptop candidate found in worldobjects, square or inventory")
        -- FALLBACK: try legacy behaviour similar to LaptopFill.lua
        -- Gather worldObjects' first item's fullType for legacy handlers
        for i, worldObject in ipairs(worldobjects) do
            local ok, item = pcall(function() if worldObject and worldObject.getItem then return worldObject:getItem() end end)
            if ok and item and item.getFullType then
                local ft = item:getFullType()
                -- Add legacy options on top for visual parity with original mod
                if ft and tostring(ft) ~= "" then
                    if playerObj and playerObj.getInventory and playerObj:getInventory():getItemCount("USBOpened") > 0 then
                        context:addOptionOnTop("Decrypt drive", playerObj, DecryptDrivesContextMenu.LegacyDecryptUSB, worldObject, ft)
                    end
                    if playerObj and playerObj.getInventory and playerObj:getInventory():getItemCount("FloppyDrive") > 0 then
                        context:addOptionOnTop("Check Floppy Disk", playerObj, DecryptDrivesContextMenu.LegacyDecryptFloppy, worldObject, ft)
                    end
                    -- If we've added at least one option, stop
                    return
                end
            end
        end
    end
end


-- Create hierarchical context menu
function DecryptDrivesContextMenu.createHierarchicalMenu(player, context, laptop, usbList)
    print("[DecryptSkillSys][DEBUG] createHierarchicalMenu called")
    print("[DecryptSkillSys][DEBUG] USB count: " .. #usbList)

    -- Group USBs by skill
    local groupedUSBs = DecryptDrivesContextMenu.groupUSBsBySkill(usbList)

    print("[DecryptSkillSys][DEBUG] Grouped USBs:")
    for skill, usbs in pairs(groupedUSBs) do
        print("[DecryptSkillSys][DEBUG]  Skill: " .. skill .. " - Count: " .. #usbs)
    end

    -- Create main menu option
    local mainOption = context:addOption(DECRYPT_CONFIG.MENU_TEXT.MAIN, nil, nil)
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(mainOption, subMenu)

    -- Add skill categories
    for skill, usbs in pairs(groupedUSBs) do
        local skillOption = subMenu:addOption(DECRYPT_CONFIG.MENU_TEXT.USB_PREFIX .. skill, nil, nil)
        local skillSubMenu = ISContextMenu:getNew(subMenu)
        subMenu:addSubMenu(skillOption, skillSubMenu)

        -- Group USBs by difficulty within this skill
        local difficulties = {}
        for _, usbData in ipairs(usbs) do
            local diff = usbData.difficulty_spanish
            if not difficulties[diff] then
                difficulties[diff] = {}
            end
            table.insert(difficulties[diff], usbData)
        end

        -- Create difficulty submenus with proper order
        local diffOrder = {"Facil", "Moderado", "Dificil"}
        for _, difficultyName in ipairs(diffOrder) do
            if difficulties[difficultyName] then
                local difficultyOption = skillSubMenu:addOption(difficultyName, nil, nil)
                local difficultySubMenu = ISContextMenu:getNew(skillSubMenu)
                skillSubMenu:addSubMenu(difficultyOption, difficultySubMenu)

                -- Add individual USB options under this difficulty
                for _, usbData in ipairs(difficulties[difficultyName]) do
                    print("[DecryptSkillSys][DEBUG] Adding USB option: " .. usbData.displayName .. " under " .. skill .. " > " .. difficultyName)
                    if usbData.legacy then
                        difficultySubMenu:addOption(
                            usbData.displayName,
                            DecryptDrivesContextMenu,
                            DecryptDrivesContextMenu.onUSBSelectedLegacy,
                            player,
                            laptop,
                            usbData
                        )
                    else
                        difficultySubMenu:addOption(
                            usbData.displayName,
                            DecryptDrivesContextMenu,
                            DecryptDrivesContextMenu.onUSBSelected,
                            player,
                            laptop,
                            usbData
                        )
                    end
                end
            end
        end
    end

    print("[DecryptSkillSys][DEBUG] Context menu created with " .. #usbList .. " USB options")
end

-- ============================================================================
-- USB SELECTION HANDLER
-- ============================================================================

-- Handle USB selection from context menu
-- This will be connected to ISSUE-003 (MinigameController) later
function DecryptDrivesContextMenu.onUSBSelected(player, laptop, usbData)
    print("[DecryptSkillSys][DEBUG] USB selected: " .. usbData.displayName)
    print("[DecryptSkillSys][DEBUG] Skill: " .. usbData.skill .. ", Difficulty: " .. usbData.difficulty_spanish .. " -> " .. usbData.difficulty_english)

    -- TODO: Connect to MinigameController when ISSUE-003 is implemented
    -- For now, just show a message to the player
    player:Say("Initiating decryption of " .. usbData.skill .. " drive (" .. usbData.difficulty_spanish .. ")...")

    -- Prepare data structure for future minigame integration
    local minigameData = {
        player = player,
        laptop = laptop,
        usb = usbData,
        skill = usbData.skill,
        difficulty_spanish = usbData.difficulty_spanish,
        difficulty_english = usbData.difficulty_english  -- Use English for internal logic
    }

    -- TODO: Launch minigame
    -- MinigameController.launchMinigame(minigameData)
end

    print("[DecryptSkillSys] DecryptDrivesContextMenu loaded successfully (DEBUG MODE)")

    -- Export module for testing and integration
    return DecryptDrivesContextMenu
