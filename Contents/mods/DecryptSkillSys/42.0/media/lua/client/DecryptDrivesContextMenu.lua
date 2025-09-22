local DecryptDrivesContextMenu = {}
-- Señalizar que este módulo provee el menú moderno jerárquico
DecryptDrivesContextMenu.MODERN_MENU_ACTIVE = true
pcall(function() _G.DecryptDrivesContextMenu_MODERN = true end)

-- Import centralized config
pcall(require, "shared/GVDrive_Config")

-- Debug print function
local function debugPrint(...)
    if GVDrive_Config and GVDrive_Config.getDebug and GVDrive_Config.getDebug() then
        print("[DecryptSkillSys][DEBUG]", ...)
    end
end

-- Create hierarchical context menu
function DecryptDrivesContextMenu.createHierarchicalMenu(player, context, laptop, usbList)
    debugPrint("DecryptDrivesContextMenu.createHierarchicalMenu called")

    -- Try to use modular controller first
    if menuController then
        debugPrint("DecryptDrivesContextMenu: Using modular MenuController")
        return menuController:createMenu(player, context, laptop, usbList)
    end

    -- Fallback to legacy implementation
    debugPrint("DecryptDrivesContextMenu: Using legacy menu implementation - MenuController not available")
    return DecryptDrivesContextMenu.createHierarchicalMenuLegacy(player, context, laptop, usbList)
end

debugPrint("DecryptDrivesContextMenu.lua starting to load...")

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
        MAIN = "Insert Drive...",
        USB_PREFIX = "USB "
    }
}

print("[DecryptSkillSys] Loading DecryptDrivesContextMenu (DEBUG MODE)...")

-- ============================================================================
-- LAPTOP VALIDATION FUNCTIONS
-- ============================================================================

-- Validate if worldObject is a valid laptop for decryption
function DecryptDrivesContextMenu.isValidLaptop(worldObject)
    debugPrint("=== isValidLaptop called ===")
    
    -- Verificación básica del objeto
    if not worldObject then
        debugPrint("❌ worldObject es nil")
        return false, "No se proporcionó ningún objeto"
    end
    
    -- Verificar si el objeto es un IsoObject
    if not instanceof(worldObject, "IsoObject") then
        local objType = "desconocido"
        if worldObject.getClass and worldObject:getClass() then
            objType = tostring(worldObject:getClass():getName())
        end
        debugPrint("❌ No es un IsoObject, tipo: " .. objType)
        return false, "No es un objeto del mundo válido"
    end
    
    -- Verificar si es un IsoWorldInventoryObject (objetos con inventario como laptops)
    if not instanceof(worldObject, "IsoWorldInventoryObject") then
        debugPrint("❌ No es un IsoWorldInventoryObject (no es un objeto con inventario)")
        return false, "No es un objeto con inventario"
    end
    
    -- Obtener el ítem del objeto del mundo con manejo de errores
    local item, itemErr
    local success, result = pcall(function() return worldObject:getItem() end)
    
    if success then
        item = result
    else
        itemErr = result
        debugPrint("❌ Error al obtener el ítem: " .. tostring(itemErr))
    end
    
    if not item then
        debugPrint("❌ No se pudo obtener el ítem del objeto")
        return false, "No se pudo obtener el ítem del objeto"
    end
    
    -- Obtener información del ítem de forma segura
    local itemName = "[Sin nombre]"
    local itemFullType = "[Sin tipo]"
    local itemType = "[Sin tipo]"
    
    -- Usar pcall para evitar errores en getName(), getFullType(), etc.
    local nameSuccess, nameResult = pcall(function() return item:getName() end)
    if nameSuccess and nameResult then
        itemName = tostring(nameResult)
    end
    
    local fullTypeSuccess, fullTypeResult = pcall(function() return item:getFullType() end)
    if fullTypeSuccess and fullTypeResult then
        itemFullType = tostring(fullTypeResult)
    end
    
    local typeSuccess, typeResult = pcall(function() return item:getType() end)
    if typeSuccess and typeResult then
        itemType = tostring(typeResult)
    end
    
    debugPrint(string.format("🔍 Analizando objeto: %s (Tipo: %s, FullType: %s)", 
        itemName, itemType, itemFullType))
    
    -- Verificar si es un tipo de laptop válido
    local isLaptop = false
    
    -- Usar pcall para iterar sobre LAPTOP_TYPES de forma segura
    local typeCheckSuccess, typeCheckResult = pcall(function()
        for _, laptopType in ipairs(DECRYPT_CONFIG.LAPTOP_TYPES) do
            if itemFullType:find(laptopType, 1, true) or itemType:find(laptopType, 1, true) then
                debugPrint("✅ Coincidencia de tipo de laptop: " .. laptopType)
                return true
            end
        end
        return false
    end)
    
    if typeCheckSuccess then
        isLaptop = typeCheckResult
    else
        debugPrint("⚠️ Error al verificar tipos de laptop: " .. tostring(typeCheckResult))
    end
    
    -- Para depuración: verificar si contiene "Laptop" en el nombre o tipo
    if not isLaptop then
        local laptopInName = itemName:lower():find("laptop") ~= nil
        local laptopInType = itemType:lower():find("laptop") ~= nil or itemFullType:lower():find("laptop") ~= nil
        
        if laptopInName or laptopInType then
            debugPrint("ℹ️  Se encontró 'Laptop' en el nombre o tipo, pero no en LAPTOP_TYPES")
            debugPrint("ℹ️  Considere agregar este tipo a DECRYPT_CONFIG.LAPTOP_TYPES:")
            debugPrint("ℹ️  Nombre: " .. itemName)
            debugPrint("ℹ️  Tipo: " .. itemType)
            debugPrint("ℹ️  FullType: " .. itemFullType)
            -- Aceptar temporalmente laptops que contengan "laptop" en el nombre/tipo
            isLaptop = true
        end
    end
    
    -- Resultado final
    if isLaptop then
        debugPrint("✅ Laptop válida detectada: " .. itemName)
        return true, "Laptop válida: " .. itemName
    else
        debugPrint("❌ No es una laptop válida: " .. itemName .. " (Tipo: " .. itemType .. ")")
        return false, "No es una laptop compatible"
    end
end

-- ============================================================================
-- USB SCANNING AND GROUPING FUNCTIONS
-- ============================================================================

-- Scan player inventory for USB drives
function DecryptDrivesContextMenu.scanPlayerUSBs(player)
    debugPrint("scanPlayerUSBs called")

    if not player then
        debugPrint("Player is nil")
        return {}
    end

    local inventory
    local success, result = pcall(function() return player:getInventory() end)
    if success and result then
        inventory = result
    else
        debugPrint("Error getting inventory: " .. tostring(result))
        return {}
    end

    if not inventory then
        debugPrint("No inventory found")
        return {}
    end

    local items
    local itemsSuccess, itemsResult = pcall(function() return inventory:getItems() end)
    if itemsSuccess and itemsResult then
        items = itemsResult
    else
        debugPrint("Error getting items: " .. tostring(itemsResult))
        return {}
    end

    local itemCount = 0
    local sizeSuccess, sizeResult = pcall(function() return items:size() end)
    if sizeSuccess then
        itemCount = sizeResult or 0
    end
    debugPrint("Inventory items count: " .. itemCount)

    local usbList = {}
    local haveUtils = pcall(require, "shared/GVDrive_Utils") and GVDrive_Utils and GVDrive_Utils.getDriveInfo

    for i = 0, itemCount - 1 do
        local item
        local itemSuccess, itemResult = pcall(function() return items:get(i) end)
        if itemSuccess and itemResult then
            item = itemResult
        end

        if item then
            local handled = false
            if haveUtils then
                local ok, info = pcall(GVDrive_Utils.getDriveInfo, item)
                if ok and info and info.isUSB and info.isSkillSpecific and info.skillName then
                    local rarityEs = tostring(info.rarity or "")
                    local r = rarityEs:lower()
                    if r:find("dif") then rarityEs = "Dificil"
                    elseif r:find("mod") then rarityEs = "Moderado"
                    elseif r:find("fac") then rarityEs = "Facil" else rarityEs = "Facil" end
                    table.insert(usbList, {
                        item = item,
                        fullType = (item.getFullType and item:getFullType()) or (item.getType and item:getType()) or "",
                        skill = tostring(info.skillName),
                        difficulty_spanish = rarityEs,
                        difficulty_english = (DECRYPT_CONFIG.DIFFICULTY_MAP[rarityEs] or "Easy"),
                        displayName = DECRYPT_CONFIG.MENU_TEXT.USB_PREFIX .. tostring(info.skillName) .. " (" .. rarityEs .. ")"
                    })
                    handled = true
                end
            end

            if not handled then
                local ft = (item.getFullType and item:getFullType()) or (item.getType and item:getType()) or ""
                if type(ft) == 'string' and ft:find(DECRYPT_CONFIG.USB_PATTERN, 1, true) then
                    local parsed = DecryptDrivesContextMenu.parseUSBData(item, ft)
                    if parsed then table.insert(usbList, parsed) end
                end
            end
        end
    end

    debugPrint("USB scan completed, found " .. tostring(#usbList) .. " USBs")
    return usbList
end

-- Parse USB data from item and fullType
function DecryptDrivesContextMenu.parseUSBData(item, fullType)
    debugPrint("parseUSBData called with: " .. tostring(fullType))

    local parts = {}
    for part in fullType:gmatch("([^_]+)") do
        table.insert(parts, part)
    end

    -- Expected format: SkillDrive_SkillName_Difficulty
    if #parts >= 3 and parts[1] == "SkillDrive" then
        local skillName = parts[2]
        local difficulty = parts[3]

        -- Normalize difficulty
        local rarityMap = { ["Facil"]=true, ["Moderado"]=true, ["Dificil"]=true }
        local rlower = difficulty:lower()
        if rlower:find("dif") then difficulty = "Dificil"
        elseif rlower:find("mod") then difficulty = "Moderado"
        elseif rlower:find("fac") then difficulty = "Facil"
        else difficulty = "Facil" end

        if not rarityMap[difficulty] then
            difficulty = "Facil"
        end

        return {
            item = item,
            fullType = fullType,
            skill = skillName,
            difficulty_spanish = difficulty,
            difficulty_english = DECRYPT_CONFIG.DIFFICULTY_MAP[difficulty] or "Easy",
            displayName = DECRYPT_CONFIG.MENU_TEXT.USB_PREFIX .. skillName .. " (" .. difficulty .. ")"
        }
    end

    return nil
end

-- Group USBs by skill
function DecryptDrivesContextMenu.groupUSBsBySkill(usbList)
    local grouped = {}
    for _, usb in ipairs(usbList) do
        local skill = usb.skill
        if not grouped[skill] then
            grouped[skill] = {}
        end
        table.insert(grouped[skill], usb)
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
function DecryptDrivesContextMenu.addContextMenuOption(player, context, worldobjects, test)
    debugPrint("=== DecryptDrivesContextMenu.addContextMenuOption STARTED ===")

    -- Normalize player (events may pass player index rather than IsoPlayer)
    local playerObj = player
    if type(player) == "number" then
        local ok, res = pcall(function() return getSpecificPlayer(player) end)
        if ok and res then playerObj = res end
    end

    debugPrint("DecryptDrivesContextMenu: player: " .. tostring(playerObj))
    debugPrint("DecryptDrivesContextMenu: context: " .. tostring(context))
    debugPrint("DecryptDrivesContextMenu: worldobjects count: " .. tostring(worldobjects and #worldobjects or 0))
    debugPrint("DecryptDrivesContextMenu: test mode: " .. tostring(test))

    -- Skip if test mode or missing params
    if test or not playerObj or not context or not worldobjects then
        debugPrint("DecryptDrivesContextMenu: Skipping (test or missing parameters)")
        debugPrint("=== DecryptDrivesContextMenu.addContextMenuOption ENDED (skipped) ===")
        return
    end

    -- Check each world object for valid laptops
    for i, worldObject in ipairs(worldobjects) do
        debugPrint("DecryptDrivesContextMenu: Checking worldObject " .. tostring(i))
        local isValid, reason = DecryptDrivesContextMenu.isValidLaptop(worldObject)

        if isValid then
            debugPrint("DecryptDrivesContextMenu: Valid laptop found!")
            -- Scan for USBs in player inventory
            local usbList = DecryptDrivesContextMenu.scanPlayerUSBs(playerObj)

            if #usbList > 0 then
                debugPrint("DecryptDrivesContextMenu: USBs found: " .. #usbList)
                -- Create hierarchical menu
                DecryptDrivesContextMenu.createHierarchicalMenu(playerObj, context, worldObject, usbList)
                debugPrint("=== DecryptDrivesContextMenu.addContextMenuOption ENDED (menu created) ===")
                break -- Only need one laptop
            else
                debugPrint("DecryptDrivesContextMenu: No USBs found in player inventory")
                debugPrint("=== DecryptDrivesContextMenu.addContextMenuOption ENDED (no USBs) ===")
            end
        else
            debugPrint("DecryptDrivesContextMenu: Invalid laptop: " .. tostring(reason))
        end
    end
    debugPrint("=== DecryptDrivesContextMenu.addContextMenuOption ENDED (no valid laptop found) ===")
end

-- ============================================================================
-- MODULAR MENU SYSTEM INTEGRATION
-- ============================================================================

-- Import modular components
local menuControllerLoaded, menuControllerError = pcall(require, "DecryptDrivesContextMenu.MenuController")
debugPrint("MenuController require result: loaded=" .. tostring(menuControllerLoaded) .. ", error=" .. tostring(menuControllerError))

-- Initialize menu controller
local menuController = nil
if MenuController and menuControllerLoaded then
    menuController = MenuController:new()
    debugPrint("MenuController initialized successfully")
else
    debugPrint("[WARN] MenuController not available or failed to load, falling back to legacy implementation")
end

debugPrint("Final menuController state: " .. tostring(menuController))

-- Create hierarchical context menu
function DecryptDrivesContextMenu.createHierarchicalMenu(player, context, laptop, usbList)
    debugPrint("createHierarchicalMenu called")

    -- Try to use modular controller first
    if menuController then
        debugPrint("Using modular MenuController")
        return menuController:createMenu(player, context, laptop, usbList)
    end

    -- Fallback to legacy implementation
    debugPrint("Using legacy menu implementation - MenuController not available")
    return DecryptDrivesContextMenu.createHierarchicalMenuLegacy(player, context, laptop, usbList)
end

-- Legacy implementation (kept for compatibility)
function DecryptDrivesContextMenu.createHierarchicalMenuLegacy(player, context, laptop, usbList)
    debugPrint("createHierarchicalMenuLegacy called")
    debugPrint("USB count: " .. #usbList)

    -- Group USBs by skill
    local groupedUSBs = DecryptDrivesContextMenu.groupUSBsBySkill(usbList)

    debugPrint("Grouped USBs:")
    for skill, usbs in pairs(groupedUSBs) do
        debugPrint("  Skill: " .. skill .. " - Count: " .. #usbs)
    end

    -- Create main menu option
    local mainOption = context:addOption(DECRYPT_CONFIG.MENU_TEXT.MAIN, nil, nil)
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(mainOption, subMenu)
    -- Mark context to indicate modern menu has been attached (defensive against other handlers)
    context._DecryptDrives_ModernMenu = true

    -- Add skill categories
    for skill, usbs in pairs(groupedUSBs) do
        local skillOption = subMenu:addOption(DECRYPT_CONFIG.MENU_TEXT.USB_PREFIX .. skill, nil, nil)
        local skillSubMenu = ISContextMenu:getNew(subMenu)
        subMenu:addSubMenu(skillOption, skillSubMenu)

        -- Group USBs by difficulty within this skill
        local difficulties = {}
        for _, usbData in ipairs(usbs) do
            local diff = usbData.difficulty_spanish
            debugPrint("LEGACY: Processing USB: skill=" .. skill .. ", difficulty=" .. tostring(diff) .. ", displayName=" .. tostring(usbData.displayName))
            if not difficulties[diff] then
                difficulties[diff] = {}
            end
            table.insert(difficulties[diff], usbData)
        end

        debugPrint("LEGACY: Difficulties for skill " .. skill .. ":")
        for diffName, diffList in pairs(difficulties) do
            debugPrint("LEGACY:   " .. diffName .. ": " .. #diffList .. " USBs")
        end

        -- Create difficulty submenus with proper order
        local diffOrder = {"Facil", "Moderado", "Dificil"}
        for _, difficultyName in ipairs(diffOrder) do
            if difficulties[difficultyName] and #difficulties[difficultyName] > 0 then
                local count = #difficulties[difficultyName]
                debugPrint("LEGACY: Adding difficulty option: " .. difficultyName .. " x" .. count .. " for skill " .. skill)
                
                -- Validate USB data before creating option
                local selectedUSB = difficulties[difficultyName][1]
                if selectedUSB and selectedUSB.displayName then
                    -- Add difficulty option that directly triggers action with the first USB
                    skillSubMenu:addOption(
                        difficultyName .. " x" .. count,
                        DecryptDrivesContextMenu,
                        DecryptDrivesContextMenu.onUSBSelected,
                        player,
                        laptop,
                        selectedUSB  -- Use the validated first USB
                    )
                    debugPrint("LEGACY: Difficulty option added to skill submenu")
                else
                    debugPrint("[ERROR] LEGACY: Invalid USB data for " .. difficultyName .. " - skipping option creation")
                end
            else
                debugPrint("LEGACY: No USBs found for difficulty: " .. difficultyName .. " in skill " .. skill)
            end
        end
    end

    debugPrint("Context menu created with " .. #usbList .. " USB options")
end

-- ============================================================================
-- USB SELECTION HANDLER
-- ============================================================================

-- Handle USB selection from context menu
function DecryptDrivesContextMenu.onUSBSelected(self, player, laptop, usbData)
    debugPrint("onUSBSelected called with parameters:")
    debugPrint("  player: " .. tostring(player))
    debugPrint("  laptop: " .. tostring(laptop))
    debugPrint("  usbData type: " .. type(usbData))
    
    if usbData and type(usbData) == "table" then
        debugPrint("  usbData content:")
        for k, v in pairs(usbData) do
            debugPrint("    " .. k .. ": " .. tostring(v))
        end
    else
        debugPrint("  usbData is nil or not a table")
    end
    
    if not usbData or type(usbData) ~= "table" or not usbData.displayName then
        debugPrint("[ERROR] onUSBSelected called with invalid usbData - missing displayName or not a table")
        return
    end

    debugPrint("USB selected: " .. usbData.displayName)
    debugPrint("Skill: " .. (usbData.skill or "Unknown") .. ", Difficulty: " .. (usbData.difficulty_spanish or "Unknown") .. " -> " .. (usbData.difficulty_english or "Unknown"))

    -- Check if minigame system is available (PZ auto-loads modules)
    if not MinigameController then
        debugPrint("[WARN] Minigame system not available, falling back to legacy behavior")
        player:Say("Initiating decryption of " .. (usbData.skill or "Unknown") .. " drive (" .. (usbData.difficulty_spanish or "Unknown") .. ")...")
        return
    end

    -- Initialize minigame controller if not already done
    if not MinigameController.initialized then
        MinigameController.initialize()
    end

    -- Check if player already has an active minigame
    if MinigameController.hasActiveGame(player:getUsername()) then
        player:Say("Ya tienes un desafío activo. Completa el actual antes de iniciar uno nuevo.")
        return
    end

    -- Determine game type based on USB difficulty (for now, random selection)
    local gameTypes = {MinigameConfig.GAME_TYPES.SEQUENCE_BREAKER}
    local selectedGameType = gameTypes[ZombRand(1, #gameTypes + 1)]

    -- Map difficulty from Spanish to internal format
    local difficultyMap = {
        ["Facil"] = MinigameConfig.DIFFICULTIES.EASY,
        ["Moderado"] = MinigameConfig.DIFFICULTIES.MODERATE,
        ["Dificil"] = MinigameConfig.DIFFICULTIES.EXPERT
    }
    local internalDifficulty = difficultyMap[usbData.difficulty_spanish] or MinigameConfig.DIFFICULTIES.EASY

    -- Success callback
    local onSuccess = function(xpGained)
        debugPrint("Minigame success! XP gained:", xpGained)
        -- Remove USB from inventory after successful decryption
        if usbData.item and player:getInventory() then
            player:getInventory():Remove(usbData.item)
            debugPrint("USB removed from inventory after successful decryption")
        end
        -- Show success message
        player:Say("¡Desafío completado! Ganaste " .. xpGained .. " puntos de experiencia en Electricidad.")
    end

    -- Failure callback
    local onFailure = function(damage, wasAbandoned)
        debugPrint("Minigame failed! Damage:", damage, "Abandoned:", wasAbandoned)
        local message = wasAbandoned and "Desafío abandonado." or ("Desafío fallido. Recibiste " .. damage .. " puntos de daño.")
        player:Say(message)
    end

    -- Start the minigame
    if not usbData.item then
        debugPrint("[ERROR] usbData.item is nil - cannot start minigame")
        player:Say("Error: USB inválido. Inténtalo de nuevo.")
        return
    end

    local success = MinigameController.startMinigame(selectedGameType, internalDifficulty, player, usbData.item, onSuccess, onFailure)

    if success then
        debugPrint("Minigame started successfully for player:", player:getUsername())
    else
        debugPrint("[ERROR] Failed to start minigame")
        player:Say("No se pudo iniciar el desafío. Inténtalo de nuevo.")
    end
end

-- ============================================================================
-- EVENT REGISTRATION
-- ============================================================================

-- Registrar el manejador del menú contextual
-- Según la documentación de ISContextMenu, debemos usar OnFillWorldObjectContextMenu
-- para objetos en el mundo y OnFillInventoryObjectContextMenu para objetos en el inventario

-- Función de depuración mejorada
local function debugContextMenu(player, context, worldobjects, test)
    debugPrint("===== MENU CONTEXTUAL ACTIVADO =====")
    
    -- Información básica
    debugPrint(string.format("Jugador: %s", tostring(player)))
    debugPrint(string.format("Modo test: %s", tostring(test)))
    
    -- Información sobre los objetos del mundo
    if worldobjects and #worldobjects > 0 then
        debugPrint(string.format("Objetos detectados: %d", #worldobjects))
        
        for i, obj in ipairs(worldobjects) do
            debugPrint(string.format("\nObjeto %d:", i))
            
            -- Información del objeto
            if obj then
                -- Obtener información básica del objeto
                local objClass = "Desconocido"
                if obj.getClass then
                    local success, result = pcall(function() return obj:getClass():getName() end)
                    if success and result then
                        objClass = tostring(result)
                    end
                end
                debugPrint(string.format("  - Clase: %s", objClass))
                
                -- Verificar si es un IsoWorldInventoryObject (objeto con inventario)
                if instanceof(obj, "IsoWorldInventoryObject") then
                    debugPrint("  - Tipo: IsoWorldInventoryObject (objeto con inventario)")
                    
                    -- Intentar obtener el ítem del inventario
                    local success, item = pcall(function() return obj:getItem() end)
                    if success and item then
                        local itemName = item:getName() or "Sin nombre"
                        local itemType = item:getType() or "Sin tipo"
                        local itemFullType = item:getFullType() or "Sin tipo completo"
                        
                        debugPrint(string.format("  - Ítem: %s", itemName))
                        debugPrint(string.format("  - Tipo: %s", itemType))
                        debugPrint(string.format("  - Tipo completo: %s", itemFullType))
                        
                        -- Verificar si contiene "laptop" en cualquier parte
                        local hasLaptop = itemName:lower():find("laptop") or 
                                         itemType:lower():find("laptop") or 
                                         itemFullType:lower():find("laptop")
                        
                        if hasLaptop then
                            debugPrint("  - 🎯 CONTIENE 'LAPTOP' - Este podría ser nuestro objetivo!")
                        end
                    else
                        debugPrint("  - ❌ No se pudo obtener el ítem del inventario")
                    end
                elseif instanceof(obj, "IsoObject") then
                    debugPrint("  - Tipo: IsoObject genérico")
                    
                    -- Verificar si tiene propiedades específicas
                    if obj.getSprite then
                        local success, sprite = pcall(function() return obj:getSprite() end)
                        if success and sprite then
                            debugPrint(string.format("  - Sprite: %s", tostring(sprite:getName())))
                        end
                    end
                    
                    -- Verificar si tiene un ítem asociado
                    if obj.getItem then
                        local success, item = pcall(function() return obj:getItem() end)
                        if success and item then
                            debugPrint("  - ✅ Tiene ítem asociado")
                        else
                            debugPrint("  - ❌ No tiene ítem asociado (probablemente decoración/estructura)")
                        end
                    else
                        debugPrint("  - ❌ No tiene método getItem")
                    end
                else
                    debugPrint("  - Tipo: Otro tipo de objeto")
                end
            else
                debugPrint("  - ❌ Objeto nulo")
            end
        end
    else
        debugPrint("No se detectaron objetos en el menú contextual")
    end
    
    debugPrint("===================================")
end

-- Registrar manejadores de eventos
debugPrint("DecryptDrivesContextMenu: Registrando manejadores de menú contextual...")

-- NO registrar para objetos en el mundo - LaptopFill.lua maneja esto para evitar duplicación
-- El menú moderno se llama directamente desde LaptopFill.lua
debugPrint("DecryptDrivesContextMenu: Menú moderno disponible para llamada directa desde LaptopFill.lua")

-- Registrar también el depurador si está en modo DEBUG
if getDebug() then
    if Events.OnFillWorldObjectContextMenu then
        Events.OnFillWorldObjectContextMenu.Add(debugContextMenu)
        debugPrint("DecryptDrivesContextMenu: Depurador de menú contextual habilitado")
    end
else
    debugPrint("[ERROR] DecryptDrivesContextMenu: No se pudo registrar el depurador para OnFillWorldObjectContextMenu")
end

debugPrint("DecryptDrivesContextMenu: Cargado correctamente")

-- Exportar el módulo para pruebas e integración
return DecryptDrivesContextMenu
