local DecryptDrivesContextMenu = {}
-- Señalizar que este módulo provee el menú moderno jerárquico
DecryptDrivesContextMenu.MODERN_MENU_ACTIVE = true
pcall(function() _G.DecryptDrivesContextMenu_MODERN = true end)

-- ========== CONFIGURACIÓN DE MINIJUEGO ==========
-- Sistema de selección aleatoria entre minijuegos disponibles:
-- "sequence" = Minijuego de secuencia (MiniGameUI.lua) - Memoria de secuencia
-- "fallout" = Minijuego de hacking Fallout (MiniGameFallout.lua) - Hacking de contraseñas

-- Lista de minijuegos disponibles
local AVAILABLE_MINIGAMES = {"sequence", "fallout"}

-- Función para seleccionar minijuego aleatorio (SIMPLIFICADA PARA DEBUG)
local function selectRandomMinigame()
    print("[DEBUG] selectRandomMinigame() called")
    print("[DEBUG] AVAILABLE_MINIGAMES: " .. tostring(#AVAILABLE_MINIGAMES))
    for i, game in ipairs(AVAILABLE_MINIGAMES) do
        print("[DEBUG]   [" .. i .. "] " .. game)
    end

    if #AVAILABLE_MINIGAMES == 0 then
        print("[DEBUG] No available minigames, returning fallback: fallout")
        return "fallout" -- Fallback
    end

    -- ✅ MÉTODO ULTRA SIMPLE: Usar solo ZombRand si está disponible
    if ZombRand then
        print("[DEBUG] Using ZombRand() for true randomness...")
        local randomIndex = ZombRand(1, #AVAILABLE_MINIGAMES + 1) -- ZombRand is 1-based
        print("[DEBUG] ZombRand generated index: " .. randomIndex)
        local selectedGame = AVAILABLE_MINIGAMES[randomIndex]
        print("[DEBUG] Selected game via ZombRand: " .. selectedGame)
        return selectedGame
    end

    -- Fallback ultra simple: usar timestamp si ZombRand no está disponible
    print("[DEBUG] ZombRand not available, using timestamp fallback...")
    local timestamp = os and os.time and os.time() or 1000000
    local simpleRandom = (timestamp % #AVAILABLE_MINIGAMES) + 1
    print("[DEBUG] Timestamp-based random index: " .. simpleRandom .. " (timestamp: " .. timestamp .. ")")
    local selectedGame = AVAILABLE_MINIGAMES[simpleRandom]
    print("[DEBUG] Selected game via timestamp: " .. selectedGame)
    return selectedGame
end

-- Seleccionar minijuego aleatorio para esta sesión (ahora se hace por USB, no solo al cargar)
-- local ACTIVE_MINIGAME = selectRandomMinigame()
-- Eliminada la línea de debug que causaba error: print("[DEBUG] ACTIVE_MINIGAME set to: " .. ACTIVE_MINIGAME)

-- Import centralized config
pcall(require, "shared/GVDrive_Config")

-- Debug print function - DEFINIR PRIMERO
local function debugPrint(...)
    if GVDrive_Config and GVDrive_Config.getDebug and GVDrive_Config.getDebug() then
        print("[DecryptSkillSys][DEBUG]", ...)
    end
end

-- ✅ CARGAR MINIJUEGO SELECCIONADO - PATRÓN MODULAR DEL CODEBASE
local miniGameLoaded = false

-- Función helper para obtener configuración del minijuego activo (SELECCIÓN POR USB)
local function getActiveMinigameConfig()
    -- ✅ NUEVO: Seleccionar minijuego aleatorio CADA VEZ que se usa un USB
    local currentMinigame = selectRandomMinigame()
    print("[DEBUG] Selected minigame for this USB: " .. currentMinigame)

    if currentMinigame == "sequence" then
        return {
            name = "MiniGame",  -- Función global para secuencia
            module = "client.MiniGameUI",  -- Path con client/ para PZ
            reloadFunc = "ReloadMiniGame",
            displayName = "sequence"
        }
    elseif currentMinigame == "fallout" then
        return {
            name = "MiniGame_Fallout",  -- Función específica para Fallout (evita conflictos)
            module = "client.MiniGameFallout",  -- Path con client/ para PZ
            reloadFunc = "ReloadMiniGameFallout",
            displayName = "fallout hacking"
        }
    else
        debugPrint("[ERROR] Invalid currentMinigame: " .. tostring(currentMinigame) .. ". Using default 'fallout'")
        return {
            name = "MiniGame_Fallout",
            module = "client.MiniGameFallout",
            reloadFunc = "ReloadMiniGameFallout",
            displayName = "fallout hacking"
        }
    end
end

local activeConfig = getActiveMinigameConfig()
debugPrint("[INFO] Active minigame: " .. activeConfig.displayName .. " (" .. activeConfig.name .. ")")

-- ✅ CARGAR MINIJUEGOS ADICIONALES
local morseGameLoaded = false
if _G.MiniGameMorse and type(_G.MiniGameMorse) == "function" then
    morseGameLoaded = true
    debugPrint("[SUCCESS] MiniGameMorse already available")
else
    debugPrint("[INFO] Loading MiniGameMorse.lua")
    local success, result = pcall(require, "client/MiniGameMorse")
    if success then
        debugPrint("[SUCCESS] MiniGameMorse.lua loaded successfully")
        morseGameLoaded = true
        if _G.MiniGameMorse and type(_G.MiniGameMorse) == "function" then
            debugPrint("[SUCCESS] MiniGameMorse function available")
        else
            debugPrint("[WARNING] MiniGameMorse function not available after loading")
        end
    else
        debugPrint("[WARNING] Failed to load MiniGameMorse.lua: " .. tostring(result))
    end
end

local falloutGameLoaded = false
if _G.MiniGame_Fallout and type(_G.MiniGame_Fallout) == "function" then
    falloutGameLoaded = true
    debugPrint("[SUCCESS] MiniGame_Fallout already available")
elseif _G.MiniGameFallout and type(_G.MiniGameFallout) == "function" then
    falloutGameLoaded = true
    debugPrint("[SUCCESS] MiniGameFallout (legacy) already available")
else
    debugPrint("[INFO] MiniGame_Fallout not available, will load when needed")
end

-- Verificar que Events esté disponible inmediatamente
if not Events then
    debugPrint("[ERROR] DecryptDrivesContextMenu: Events is nil at module load time")
    debugPrint("[ERROR] DecryptDrivesContextMenu: This indicates Events is not available in this game version")
    -- Crear un Events falso para evitar errores
    Events = { OnFillWorldObjectContextMenu = { Add = function() end } }
else
    debugPrint("DecryptDrivesContextMenu: Events is available at load time")
end

-- Create hierarchical context menu
function DecryptDrivesContextMenu.createHierarchicalMenu(player, context, laptop, usbList, healthOption)
    debugPrint("DecryptDrivesContextMenu.createHierarchicalMenu called")

    -- Try to use modular controller first
    if menuController then
        debugPrint("DecryptDrivesContextMenu: Using modular MenuController")
        local ok, result = pcall(function()
            return menuController:createMenu(player, context, laptop, usbList, healthOption)
        end)
        if ok then
            local option = nil
            if type(result) == "table" then
                option = result
            elseif result == true then
                option = context and context._DecryptDrives_MainOption
            end

            if type(option) ~= "table" then
                option = context and context._DecryptDrives_MainOption
            end

            if type(option) ~= "table" then
                debugPrint("[WARN] MenuController returned without table option; falling back to legacy")
            else
                return option
            end
        else
            debugPrint("[ERROR] MenuController:createMenu failed: " .. tostring(result))
        end
    end

    -- Fallback to legacy implementation
    debugPrint("DecryptDrivesContextMenu: Using legacy menu implementation - MenuController not available")
    return DecryptDrivesContextMenu.createHierarchicalMenuLegacy(player, context, laptop, usbList, healthOption)
end

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

debugPrint("DecryptDrivesContextMenu.lua starting to load...")
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
        MAIN = "Insert Drive",
        USB_PREFIX = "USB "
    }
}

print("[DecryptSkillSys] Loading DecryptDrivesContextMenu (DEBUG MODE)...")

-- =========================================================================
-- UI HELPERS
-- =========================================================================

local USB_ICON_PATH = "media/textures/ui/usb/usb.png"
local usbIconCache = false -- false = not yet attempted, nil = attempted but missing

function DecryptDrivesContextMenu.getUSBIconTexture()
    if usbIconCache == false then
        usbIconCache = getTexture(USB_ICON_PATH)
        if usbIconCache then
            debugPrint("USB icon texture loaded successfully: " .. USB_ICON_PATH)
        else
            debugPrint("[WARN] USB icon texture could not be loaded: " .. USB_ICON_PATH)
        end
    end
    return usbIconCache or nil
end

function DecryptDrivesContextMenu.moveOptionBelow(context, option, anchorOption)
    if not context or not option or not anchorOption then return end
    local options = context.options
    if not options then return end

    local optionIndex, anchorIndex
    for index, opt in ipairs(options) do
        if opt == option then optionIndex = index end
        if opt == anchorOption then anchorIndex = index end
    end

    if not optionIndex or not anchorIndex then return end
    if optionIndex == anchorIndex + 1 then return end -- already in correct position

    table.remove(options, optionIndex)
    local insertIndex = math.min(anchorIndex + 1, #options + 1)
    table.insert(options, insertIndex, option)

    if context.calculateHeight then
        context:calculateHeight()
    elseif context.derivePosition then
        context:derivePosition()
    end
end

function DecryptDrivesContextMenu.applyUSBMenuFormatting(context, mainOption, healthOption)
    if not context then return end

    if mainOption and type(mainOption) ~= "table" then
        mainOption = nil
    end

    if not mainOption then
        if context and context._DecryptDrives_MainOption and type(context._DecryptDrives_MainOption) == "table" then
            mainOption = context._DecryptDrives_MainOption
        end
    end

    if not mainOption then
        local options = context.options
        if options and type(options) == "table" then
            for _, opt in ipairs(options) do
                if opt and type(opt) == "table" and (opt.name == DECRYPT_CONFIG.MENU_TEXT.MAIN or opt.name == "Decrypt USB Drives") then
                    mainOption = opt
                    break
                end
            end
        end
    end

    if not mainOption or type(mainOption) ~= "table" then
        debugPrint("[WARN] applyUSBMenuFormatting: No main option table available; skipping formatting")
        return
    end

    if mainOption then
        local desiredLabel = (DECRYPT_CONFIG and DECRYPT_CONFIG.MENU_TEXT and DECRYPT_CONFIG.MENU_TEXT.MAIN) or "Insert Drive"
        if desiredLabel and mainOption.name ~= desiredLabel then
            mainOption.name = desiredLabel
            mainOption.text = desiredLabel
        end

        local iconTexture = DecryptDrivesContextMenu.getUSBIconTexture()
        if iconTexture then
            mainOption.iconTexture = iconTexture
        end
        if healthOption then
            DecryptDrivesContextMenu.moveOptionBelow(context, mainOption, healthOption)
        end

        if context.calculateHeight then
            context:calculateHeight()
        elseif context.derivePosition then
            context:derivePosition()
        end
    end
end

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
                    local usbEntry = {
                        item = item,
                        fullType = (item.getFullType and item:getFullType()) or (item.getType and item:getType()) or "",
                        skill = tostring(info.skillName),
                        difficulty_spanish = rarityEs,
                        difficulty_english = (DECRYPT_CONFIG.DIFFICULTY_MAP[rarityEs] or "Easy"),
                        displayName = DECRYPT_CONFIG.MENU_TEXT.USB_PREFIX .. tostring(info.skillName) .. " (" .. rarityEs .. ")"
                    }
                    debugPrint("✅ USB entry created via GVDrive_Utils:")
                    -- Usar pcall para evitar errores si pairs falla
                    local success, err = pcall(function()
                        for k, v in pairs(usbEntry) do
                            debugPrint("✅   " .. tostring(k) .. ": " .. tostring(v))
                        end
                    end)
                    if not success then
                        debugPrint("[ERROR] Could not iterate usbEntry: " .. tostring(err))
                    end
                    table.insert(usbList, usbEntry)
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

        local usbEntry = {
            item = item,
            fullType = fullType,
            skill = skillName,
            difficulty_spanish = difficulty,
            difficulty_english = DECRYPT_CONFIG.DIFFICULTY_MAP[difficulty] or "Easy",
            displayName = DECRYPT_CONFIG.MENU_TEXT.USB_PREFIX .. skillName .. " (" .. difficulty .. ")"
        }
        debugPrint("✅ USB entry created via parseUSBData:")
        -- Usar pcall para evitar errores si pairs falla
        local success, err = pcall(function()
            for k, v in pairs(usbEntry) do
                debugPrint("✅   " .. tostring(k) .. ": " .. tostring(v))
            end
        end)
        if not success then
            debugPrint("[ERROR] Could not iterate parseUSBData usbEntry: " .. tostring(err))
        end
        return usbEntry
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

            -- Get laptop item for health and other operations
            local laptopItem = worldObject:getItem()
            local healthOption = nil
            if laptopItem then
                -- Add laptop health status at the top with battery icon
                healthOption = DecryptDrivesContextMenu.addLaptopHealthStatus(context, playerObj, laptopItem)
                debugPrint("DecryptDrivesContextMenu: Health status added to menu")
            end

            -- Scan for USBs in player inventory
            local usbList = DecryptDrivesContextMenu.scanPlayerUSBs(playerObj)

            if #usbList > 0 then
                debugPrint("DecryptDrivesContextMenu: USBs found: " .. #usbList)
                -- Create hierarchical menu
                local mainOption = DecryptDrivesContextMenu.createHierarchicalMenu(playerObj, context, worldObject, usbList, healthOption)
                DecryptDrivesContextMenu.applyUSBMenuFormatting(context, mainOption, healthOption)
                debugPrint("DecryptDrivesContextMenu: USB menu created")
            else
                debugPrint("DecryptDrivesContextMenu: No USBs found in player inventory")
            end

            -- Add antivirus options
            DecryptDrivesContextMenu.addAntivirusOptions(context, playerObj, worldObject)
            debugPrint("DecryptDrivesContextMenu: Antivirus options added")

            -- Add elite drive options
            DecryptDrivesContextMenu.addEliteDriveOptions(context, playerObj)
            debugPrint("DecryptDrivesContextMenu: Elite drive options added")

            -- Mark context to indicate modern menu has been attached (defensive against other handlers)
            context._DecryptDrives_ModernMenu = true
            debugPrint("DecryptDrivesContextMenu: Context marked as modern menu active")

            debugPrint("=== DecryptDrivesContextMenu.addContextMenuOption ENDED (complete menu created) ===")
            break -- Only need one laptop
        else
            debugPrint("DecryptDrivesContextMenu: Invalid laptop: " .. tostring(reason))
        end
    end
    debugPrint("=== DecryptDrivesContextMenu.addContextMenuOption ENDED (no valid laptop found) ===")
end

-- ============================================================================
-- MODULAR MENU SYSTEM INTEGRATION (Simplified)
-- ============================================================================

-- Simplified approach - just use legacy implementation for reliability
debugPrint("DecryptDrivesContextMenu: Using simplified legacy implementation for maximum compatibility")

-- Create hierarchical context menu
function DecryptDrivesContextMenu.createHierarchicalMenu(player, context, laptop, usbList)
    debugPrint("createHierarchicalMenu called")

    -- Use legacy implementation directly (more reliable)
    debugPrint("Using legacy menu implementation for reliability")
    return DecryptDrivesContextMenu.createHierarchicalMenuLegacy(player, context, laptop, usbList)
end

-- Legacy implementation (kept for compatibility)
function DecryptDrivesContextMenu.createHierarchicalMenuLegacy(player, context, laptop, usbList, healthOption)
    debugPrint("createHierarchicalMenuLegacy called")
    debugPrint("USB count: " .. #usbList)

    -- Group USBs by skill
    local groupedUSBs = DecryptDrivesContextMenu.groupUSBsBySkill(usbList)

    debugPrint("Grouped USBs:")
    -- Usar pcall para evitar errores si pairs falla
    local success, err = pcall(function()
        for skill, usbs in pairs(groupedUSBs) do
            debugPrint("  Skill: " .. skill .. " - Count: " .. #usbs)
        end
    end)
    if not success then
        debugPrint("[ERROR] Could not iterate groupedUSBs: " .. tostring(err))
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
            debugPrint("LEGACY: Processing USB: skill=" .. skill .. ", difficulty=" .. tostring(diff))
            if not difficulties[diff] then
                difficulties[diff] = {}
            end
            table.insert(difficulties[diff], usbData)
        end

        debugPrint("LEGACY: Difficulties for skill " .. skill .. ":")
        -- Usar pcall para evitar errores si pairs falla
        local success, err = pcall(function()
            for diffName, diffList in pairs(difficulties) do
                debugPrint("LEGACY:   " .. diffName .. ": " .. #diffList .. " USBs")
            end
        end)
        if not success then
            debugPrint("[ERROR] Could not iterate difficulties: " .. tostring(err))
        end

        -- Create difficulty submenus with proper order
        local diffOrder = {"Facil", "Moderado", "Dificil"}
        for _, difficultyName in ipairs(diffOrder) do
            if difficulties[difficultyName] and #difficulties[difficultyName] > 0 then
                local count = #difficulties[difficultyName]
                local firstUSB = difficulties[difficultyName][1]
                
                -- ✅ VALIDACIÓN CRÍTICA: Verificar que el primer USB sea válido
                if firstUSB and firstUSB.displayName then
                    debugPrint("LEGACY: Adding difficulty option: " .. difficultyName .. " x" .. count .. " for skill " .. skill)
                    debugPrint("LEGACY: First USB data: " .. tostring(firstUSB.displayName))
                    
                    -- Add difficulty option that directly triggers action with the first USB
                    -- ✅ CORRECCIÓN CRÍTICA: Usar wrapper function para garantizar parámetros correctos
                    skillSubMenu:addOption(
                        difficultyName .. " x" .. count,
                        player,
                        function(playerObj, laptopObj)
                            -- Llamar onUSBSelected con parámetros garantizados
                            DecryptDrivesContextMenu.onUSBSelected(playerObj, laptop, firstUSB)
                        end
                    )
                    debugPrint("LEGACY: Difficulty option added to skill submenu")
                else
                    debugPrint("[ERROR] LEGACY: Invalid first USB data for difficulty: " .. difficultyName .. " in skill " .. skill)
                    debugPrint("[ERROR] LEGACY: firstUSB: " .. tostring(firstUSB))
                    if firstUSB then
                        debugPrint("[ERROR] LEGACY: firstUSB.displayName: " .. tostring(firstUSB.displayName))
                    end
                end
            else
                debugPrint("LEGACY: No USBs found for difficulty: " .. difficultyName .. " in skill " .. skill)
            end
        end
    end

    debugPrint("Context menu created with " .. #usbList .. " USB options")
    return mainOption
end

-- ============================================================================
-- USB SELECTION HANDLER
-- ============================================================================

-- Handle USB selection from context menu
function DecryptDrivesContextMenu.onUSBSelected(player, laptop, usbData)
    debugPrint("✅ onUSBSelected called with parameters:")
    debugPrint("✅   player: " .. tostring(player) .. " (type: " .. type(player) .. ")")
    debugPrint("✅   laptop: " .. tostring(laptop) .. " (type: " .. type(laptop) .. ")")
    debugPrint("✅   usbData: " .. tostring(usbData) .. " (type: " .. type(usbData) .. ")")
    
    -- ✅ VALIDACIÓN MEJORADA: Información detallada de debugging
    if not usbData then
        debugPrint("[ERROR] onUSBSelected called with nil usbData")
        debugPrint("[ERROR] Parameters received:")
        debugPrint("[ERROR]   player: " .. tostring(player))
        debugPrint("[ERROR]   laptop: " .. tostring(laptop))
        debugPrint("[ERROR]   usbData: nil")
        return
    end
    
    -- ✅ VALIDACIÓN CRÍTICA: Verificar que usbData sea una tabla válida
    if type(usbData) ~= "table" then
        debugPrint("[ERROR] onUSBSelected called with usbData that is not a table")
        debugPrint("[ERROR] usbData type: " .. type(usbData))
        debugPrint("[ERROR] usbData value: " .. tostring(usbData))
        debugPrint("[ERROR] This suggests parameter order is incorrect in addOption call")
        return
    end
    
    if not usbData.displayName then
        debugPrint("[ERROR] onUSBSelected called with usbData missing displayName")
        debugPrint("[ERROR] usbData contents:")
        -- Usar pcall para evitar errores si pairs falla
        local success, err = pcall(function()
            for key, value in pairs(usbData) do
                debugPrint("[ERROR]   " .. tostring(key) .. ": " .. tostring(value))
            end
        end)
        if not success then
            debugPrint("[ERROR] Could not iterate usbData: " .. tostring(err))
        end
        return
    end

    debugPrint("✅ USB selected successfully: " .. usbData.displayName)
    debugPrint("✅ Skill: " .. (usbData.skill or "Unknown") .. ", Difficulty: " .. (usbData.difficulty_spanish or "Unknown") .. " -> " .. (usbData.difficulty_english or "Unknown"))
    debugPrint("✅ Full usbData:")
    -- Usar pcall para evitar errores si pairs falla
    local success, err = pcall(function()
        for key, value in pairs(usbData) do
            debugPrint("✅   " .. tostring(key) .. ": " .. tostring(value))
        end
    end)
    if not success then
        debugPrint("[ERROR] Could not iterate successful usbData: " .. tostring(err))
    end

    -- Obtener laptop item para integración
    local laptopItem = nil
    if laptop then
        laptopItem = laptop:getItem()
    end

    -- ✅ VERIFICACIÓN CRÍTICA: Verificar salud de la laptop antes de iniciar minijuego
    if laptopItem and LaptopSystem then
        local laptopHealth = LaptopSystem.getLaptopHealth(laptopItem)
        if type(laptopHealth) == "number" and laptopHealth <= 0 then
            debugPrint("[ERROR] Laptop health is 0% or less, cannot start minigame")
            player:Say("This laptop is completely dead. It cannot run any decryption software.")
            return
        end
    end

    -- Configurar y abrir minijuego con integración USB
    local usbType = usbData.skill
    local difficulty = usbData.difficulty_english

    -- ✅ VALIDACIÓN CRÍTICA: Verificar que usbType sea válido antes de proceder
    if not usbType or usbType == "" then
        debugPrint("[ERROR] usbData.skill is nil or empty. usbData contents:")
        if usbData then
            for key, value in pairs(usbData) do
                debugPrint("[ERROR]   " .. tostring(key) .. ": " .. tostring(value))
            end
        end
        player:Say("Invalid USB skill data. Cannot proceed with decryption.")
        return
    end

    if usbType and difficulty then
        -- ✅ OBTENER CONFIGURACIÓN FRESCA CADA VEZ (selección aleatoria por USB)
        local currentConfig = getActiveMinigameConfig()
        debugPrint("Opening random minigame for USB: " .. usbType .. " (" .. difficulty .. ") using " .. currentConfig.displayName .. " minigame")

        -- ✅ VERIFICACIÓN Y RECARGA DEL MINIJUEGO ACTIVO
        if not _G[currentConfig.name] or type(_G[currentConfig.name]) ~= "function" then
            debugPrint("[WARN] _G." .. currentConfig.name .. " missing or not a function. Attempting to reload " .. currentConfig.module .. " module...")
            if package and package.loaded then
                package.loaded[currentConfig.module] = nil
            else
                debugPrint("[WARN] Lua 'package.loaded' not available in this context; skipping cache clear")
            end
            local ok, result = pcall(require, currentConfig.module)
            if ok then
                debugPrint("[INFO] " .. currentConfig.module .. " module reloaded. _G." .. currentConfig.name .. " type after reload: " .. type(_G[currentConfig.name]))
            else
                debugPrint("[ERROR] Failed to reload " .. currentConfig.module .. " module: " .. tostring(result))
                debugPrint("[WARN] Trying " .. currentConfig.reloadFunc .. "() as secondary fallback...")
                local reloadOk, reloadResult = pcall(function()
                    if _G[currentConfig.reloadFunc] then
                        _G[currentConfig.reloadFunc]()
                    else
                        debugPrint("[ERROR] " .. currentConfig.reloadFunc .. " not available")
                    end
                end)
                if not reloadOk then
                    debugPrint("[ERROR] " .. currentConfig.reloadFunc .. "() threw an error: " .. tostring(reloadResult))
                else
                    debugPrint("[INFO] " .. currentConfig.reloadFunc .. "() executed. _G." .. currentConfig.name .. " type now: " .. type(_G[currentConfig.name]))
                end
            end
        end

        debugPrint("[DEBUG] About to call _G." .. currentConfig.name)
        debugPrint("[DEBUG] _G." .. currentConfig.name .. " type: " .. type(_G[currentConfig.name]))
        if _G[currentConfig.name] and type(_G[currentConfig.name]) == "function" then
            -- ✅ Permitir que el minijuego use la configuración global de ventana (widthPct/heightPct nil)
            debugPrint("[DEBUG] Calling " .. currentConfig.name .. " with default window sizing, usbType=" .. usbType .. ", difficulty=" .. difficulty)
            local success, minigame = pcall(_G[currentConfig.name], nil, nil, usbType, difficulty, laptopItem, usbData)
            if success and minigame then
                debugPrint(currentConfig.displayName .. " minigame opened successfully with USB integration")
                player:Say("Initializing " .. usbType .. " decryption protocol (" .. difficulty .. " level) - " .. (currentConfig.name == "MiniGame_Fallout" and "Password Hacking..." or "Sequence Memory..."))
            else
                debugPrint("[ERROR] Failed to create " .. currentConfig.displayName .. " minigame: " .. tostring(minigame))
                player:Say("Error initializing " .. (currentConfig.name == "MiniGame_Fallout" and "password hacking" or "sequence decryption") .. " system.")
            end
        else
            debugPrint("[ERROR] " .. currentConfig.name .. " function not available in global scope")
            debugPrint("[ERROR] _G." .. currentConfig.name .. ": " .. tostring(_G[currentConfig.name]))
            player:Say("No " .. (currentConfig.name == "MiniGame_Fallout" and "password hacking" or "decryption") .. " protocol available for this drive type.")
        end
    else
        debugPrint("[ERROR] Invalid USB data - skill: " .. tostring(usbType) .. ", difficulty: " .. tostring(difficulty))
        player:Say("Invalid drive data. Cannot proceed with decryption.")
    end
end

-- ============================================================================
-- LAPTOP HEALTH SYSTEM
-- ============================================================================

-- Get battery texture based on health percentage
function DecryptDrivesContextMenu.getBatteryTextureForHealth(healthPercent)
    -- Ensure healthPercent is a valid number
    if type(healthPercent) ~= "number" then
        debugPrint("getBatteryTextureForHealth: healthPercent is not a number, type=" .. type(healthPercent) .. ", value=" .. tostring(healthPercent))
        healthPercent = 0 -- Default to 0 if invalid
    end

    -- Clamp to valid range
    if healthPercent < 0 then healthPercent = 0 end
    if healthPercent > 100 then healthPercent = 100 end

    -- Return texture object for context menu icon
    if healthPercent <= 12 then
        return getTexture("media/textures/ui/health/batt0.png")
    elseif healthPercent <= 37 then
        return getTexture("media/textures/ui/health/batt25.png")
    elseif healthPercent <= 62 then
        return getTexture("media/textures/ui/health/batt50.png")
    elseif healthPercent <= 87 then
        return getTexture("media/textures/ui/health/batt75.png")
    else
        return getTexture("media/textures/ui/health/batt100.png")
    end
end

-- Add laptop health status to context menu
function DecryptDrivesContextMenu.addLaptopHealthStatus(context, player, laptopItem)
    if not laptopItem then return end

    -- Get laptop health
    local laptopHealth = 0
    if LaptopSystem then
        laptopHealth = LaptopSystem.getLaptopHealth(laptopItem)
        debugPrint("Laptop health retrieved: " .. tostring(laptopHealth))
    else
        debugPrint("LaptopSystem not available for health check")
    end

    -- Ensure laptopHealth is valid
    if type(laptopHealth) ~= "number" then
        debugPrint("Laptop health is not a number, type=" .. type(laptopHealth) .. ", value=" .. tostring(laptopHealth))
        laptopHealth = 0 -- Default to 0 if invalid
    end

    -- Get battery texture for menu icon
    local batteryTexture = DecryptDrivesContextMenu.getBatteryTextureForHealth(laptopHealth)

    -- Determine health status based on percentage
    local healthStatus = ""
    if laptopHealth >= 80 then
        healthStatus = "Excellent"
    elseif laptopHealth >= 60 then
        healthStatus = "Good"
    elseif laptopHealth >= 40 then
        healthStatus = "Fair"
    elseif laptopHealth >= 20 then
        healthStatus = "Poor"
    else
        healthStatus = "Critical"
    end

    -- Display format: Health: percentage (status)
    local healthDisplay = "Health: " .. laptopHealth .. "% (" .. healthStatus .. ")"

    -- Create a custom option with texture icon
    local healthOption = context:addOptionOnTop(healthDisplay, player, function()
        local messages = {
            "The laptop hums softly, displaying its current condition.",
            "You examine the laptop's status indicators carefully.",
            "The screen flickers slightly as you check the system diagnostics.",
            "You run a quick hardware diagnostic on the laptop.",
            "The laptop responds to your touch, showing its current state."
        }

        if laptopHealth <= 0 then
            player:Say("This laptop is completely dead. It's nothing more than expensive paperweight now.")
        elseif laptopHealth < 20 then
            player:Say("This laptop is barely hanging on. One wrong move and it'll be toast.")
        elseif laptopHealth < 40 then
            player:Say("This laptop has seen better days. Some TLC with antivirus might help.")
        elseif laptopHealth < 60 then
            player:Say("This laptop is holding up okay, but could use some maintenance.")
        elseif laptopHealth < 80 then
            player:Say("This laptop is in good shape and should serve you well.")
        else
            local randomMsg = messages[ZombRand(#messages) + 1]
            player:Say(randomMsg)
        end
    end)

    -- Assign battery texture as icon to the context menu option
    if batteryTexture then
        healthOption.iconTexture = batteryTexture
        debugPrint("Battery texture assigned to menu option iconTexture successfully")
    else
        debugPrint("Failed to load battery texture - no icon will be displayed")
    end

    return healthOption
end

-- ============================================================================
-- ANTIVIRUS SYSTEM
-- ============================================================================

-- Add antivirus options to context menu
function DecryptDrivesContextMenu.addAntivirusOptions(context, player, worldObject)
    if not player or not worldObject then return end

    local inv = player:getInventory()
    if not inv then return end

    -- Check for antivirus (both old and new item names)
    local antivirusCount = inv:getItemCount("GValley.Antivirus_Norton") +
                           inv:getItemCount("GValley.Antivirus_Kaspersky") +
                           inv:getItemCount("GValley.Antivirus_McAfee") +
                           inv:getItemCount("GValley.Antivirus_MalwareBytes")

    if antivirusCount > 0 then
        -- Create antivirus submenu
        local antivirusOption = context:addOption("Use Antivirus (" .. antivirusCount .. ")", player, function() end)
        local antivirusSubMenu = ISContextMenu:getNew(context)
        context:addSubMenu(antivirusOption, antivirusSubMenu)

        -- Check each antivirus type and add to submenu
        local antivirusTypes = {
            {id = "GValley.Antivirus_MalwareBytes", name = "MalwareBytes", heal = 12},
            {id = "GValley.Antivirus_McAfee", name = "McAfee", heal = 10},
            {id = "GValley.Antivirus_Kaspersky", name = "Kaspersky", heal = 8},
            {id = "GValley.Antivirus_Norton", name = "Norton", heal = 5}
        }

        for _, avType in ipairs(antivirusTypes) do
            local count = inv:getItemCount(avType.id)
            if count > 0 then
                antivirusSubMenu:addOption(avType.name .. " (" .. count .. ") - Heal +" .. avType.heal .. "%", player, function()
                    DecryptDrivesContextMenu.useAntivirus(player, worldObject, avType)
                end)
            end
        end
    end
end

-- Use antivirus on laptop
function DecryptDrivesContextMenu.useAntivirus(player, worldObject, avType)
    local inv = player:getInventory()
    if not inv then
        player:Say("Cannot access inventory.")
        return
    end

    -- Find and use this specific antivirus type
    local antivirusItem = nil

    -- Try multiple methods to find the item
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local checkItem = items:get(i)
        if checkItem and checkItem:getFullType() == avType.id then
            antivirusItem = checkItem
            break
        end
    end

    -- Fallback: try getItemsFromType
    if not antivirusItem then
        local itemList = inv:getItemsFromType(avType.id)
        if itemList and itemList:size() > 0 then
            antivirusItem = itemList:get(0)
        end
    end

    if antivirusItem then
        -- Use the antivirus on the world object laptop
        local laptopItem = worldObject:getItem()
        if laptopItem and LaptopSystem then
            -- Get current health before treatment
            local beforeHealth = LaptopSystem.getLaptopHealth(laptopItem)

            -- Remove the antivirus item
            inv:DoRemoveItem(antivirusItem)

            -- Apply antivirus cleaning directly to world object
            local cleaned = false
            if LaptopSystem.cleanMalware then
                cleaned = LaptopSystem.cleanMalware(laptopItem, avType.heal)
            end
            local afterHealth = LaptopSystem.getLaptopHealth(laptopItem)
            local healthGain = afterHealth - beforeHealth

            if cleaned then
                player:Say("Antivirus " .. avType.name .. " successfully cleaned malware! Health: " .. beforeHealth .. "% -> " .. afterHealth .. "% (+" .. healthGain .. "%)")
            else
                player:Say("No malware detected. " .. avType.name .. " improved laptop condition: " .. beforeHealth .. "% -> " .. afterHealth .. "% (+" .. healthGain .. "%)")
                if LaptopSystem.damageLaptop then
                    LaptopSystem.damageLaptop(laptopItem, -math.floor(avType.heal / 2))
                end
                -- Update after the additional healing
                local finalHealth = LaptopSystem.getLaptopHealth(laptopItem)
                if finalHealth ~= afterHealth then
                    player:Say("Additional maintenance applied. Final health: " .. finalHealth .. "%")
                end
            end
        else
            player:Say("Cannot access laptop for cleaning.")
        end
    else
        player:Say("No " .. avType.name .. " antivirus found in inventory.")
    end
end

-- ============================================================================
-- ELITE DRIVES SYSTEM
-- ============================================================================

-- Add elite drives options to context menu
function DecryptDrivesContextMenu.addEliteDriveOptions(context, player)
    if not player then return end

    local inv = player:getInventory()
    if not inv then return end

    local eliteCount = 0
    local eliteTypes = {{"Strength", "Force"}, {"Endurance", "Resistance"}, {"Capacity", "Weight"}, {"Speed", "Movement"}, {"Luck", "Fortune"}}
    local availableElites = {}

    for _, eData in ipairs(eliteTypes) do
        local eType = eData[1]
        local displayName = eData[2]
        local fullTypeName = "GValley.EliteDrive_" .. eType

        -- Use multiple methods to count elite drives
        local count = 0

        -- Method 1: getItemCount
        count = inv:getItemCount(fullTypeName)

        -- Method 2: Manual count if getItemCount fails
        if count == 0 then
            local items = inv:getItems()
            for i = 0, items:size() - 1 do
                local checkItem = items:get(i)
                if checkItem and checkItem:getFullType() == fullTypeName then
                    count = count + 1
                end
            end
        end

        if count >= 2 then
            eliteCount = eliteCount + 1
            table.insert(availableElites, {type = eType, name = displayName, count = count, fullType = fullTypeName})
        end
    end

    if eliteCount > 0 then
        -- Create elite drives submenu
        local eliteOption = context:addOption("Use Elite Enhancement (" .. eliteCount .. " types)", player, function() end)
        local eliteSubMenu = ISContextMenu:getNew(context)
        context:addSubMenu(eliteOption, eliteSubMenu)

        -- Add info header
        local infoOpt = eliteSubMenu:addOption("Elite Enhancements Available:", player, function() end)
        infoOpt.notAvailable = true
        eliteSubMenu:addOption("---------", player, function() end).notAvailable = true

        -- Add each available elite type
        for _, elite in ipairs(availableElites) do
            eliteSubMenu:addOption("Elite " .. elite.name .. " (" .. elite.count .. "/2)", player, function()
                DecryptDrivesContextMenu.useEliteDrive(player, elite)
            end)
        end

        eliteSubMenu:addOption("---------", player, function() end).notAvailable = true
        eliteSubMenu:addOption("Note: Elite drives work independently", player, function()
            player:Say("Elite drives can be used directly from inventory without requiring a laptop.")
        end).notAvailable = true
    end
end

-- Use elite drive enhancement
function DecryptDrivesContextMenu.useEliteDrive(player, elite)
    local inv = player:getInventory()
    if not inv then
        player:Say("Cannot access inventory.")
        return
    end

    -- Find elite drives in inventory
    local eliteItems = {}
    local items = inv:getItems()
    for i = 0, items:size() - 1 do
        local checkItem = items:get(i)
        if checkItem and checkItem:getFullType() == elite.fullType then
            table.insert(eliteItems, checkItem)
            if #eliteItems >= 2 then break end -- Only need 2
        end
    end

    if #eliteItems >= 2 then
        -- Remove 2 elite drives from inventory
        inv:DoRemoveItem(eliteItems[1])
        inv:DoRemoveItem(eliteItems[2])

        -- Apply elite enhancement
        if EliteDriveSystem and EliteDriveSystem.useEliteDrive then
            local success = EliteDriveSystem.useEliteDrive(player, elite.type)
            if success then
                player:Say("Elite " .. elite.name .. " enhancement successfully applied! You feel more powerful...")
            else
                player:Say("Elite " .. elite.name .. " enhancement failed. You may have already used this enhancement.")
                -- Return items if failed
                inv:AddItem(elite.fullType)
                inv:AddItem(elite.fullType)
            end
        else
            player:Say("Elite enhancement system not available.")
            -- Return items if system not available
            inv:AddItem(elite.fullType)
            inv:AddItem(elite.fullType)
        end
    else
        player:Say("Not enough Elite " .. elite.name .. " drives found. Need 2, have " .. #eliteItems)
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

-- INTENTAR múltiples eventos posibles para el menú contextual
local eventRegistered = false

-- Evento principal para objetos del mundo
if Events and Events.OnFillWorldObjectContextMenu and Events.OnFillWorldObjectContextMenu.Add then
    Events.OnFillWorldObjectContextMenu.Add(DecryptDrivesContextMenu.addContextMenuOption)
    debugPrint("DecryptDrivesContextMenu: Manejador principal registrado exitosamente")
    eventRegistered = true
end

-- Evento alternativo 1
if not eventRegistered and Events and Events.OnObjectRightClicked and Events.OnObjectRightClicked.Add then
    Events.OnObjectRightClicked.Add(DecryptDrivesContextMenu.addContextMenuOption)
    debugPrint("DecryptDrivesContextMenu: Manejador alternativo 1 registrado")
    eventRegistered = true
end

-- Evento alternativo 2
if not eventRegistered and Events and Events.OnRightMouseUp and Events.OnRightMouseUp.Add then
    Events.OnRightMouseUp.Add(DecryptDrivesContextMenu.addContextMenuOption)
    debugPrint("DecryptDrivesContextMenu: Manejador alternativo 2 registrado")
    eventRegistered = true
end

-- Verificar si Events existe
if not Events then
    debugPrint("[ERROR] DecryptDrivesContextMenu: Events es nil - no se pueden registrar eventos")
    debugPrint("[ERROR] DecryptDrivesContextMenu: Esto indica que el sistema de eventos no está disponible")
else
    debugPrint("DecryptDrivesContextMenu: Events está disponible")

    -- Listar eventos disponibles para debugging
    local availableEvents = {}
    for key, value in pairs(Events) do
        if type(value) == "table" and value.Add then
            table.insert(availableEvents, key)
        end
    end

    debugPrint("DecryptDrivesContextMenu: Eventos disponibles con Add(): " .. table.concat(availableEvents, ", "))
end

if not eventRegistered then
    debugPrint("[ERROR] DecryptDrivesContextMenu: No se pudo registrar ningún manejador de eventos")
    debugPrint("[ERROR] DecryptDrivesContextMenu: El menú contextual no funcionará")
else
    debugPrint("DecryptDrivesContextMenu: Al menos un manejador de eventos registrado exitosamente")
end

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

-- ✅ FUNCIÓN DE DEBUG PARA PROBAR AMBOS MINIJUEGOS
function TestBothMinigames()
    local player = getPlayer()
    if not player then
        print("[ERROR] No player found for testing")
        return
    end

    print("[DEBUG] Testing both minigames...")

    -- Test Sequence minigame
    print("[DEBUG] Testing Sequence minigame...")
    local success1, result1 = pcall(function()
        return MiniGame(nil, nil, "TestSkill", "Easy", nil, {skill="TestSkill", difficulty_english="Easy", displayName="Test USB"})
    end)
    if success1 and result1 then
        print("[SUCCESS] Sequence minigame created successfully")
        result1:setVisible(false)
        result1:removeFromUIManager()
    else
        print("[ERROR] Failed to create Sequence minigame: " .. tostring(result1))
    end

    -- Test Fallout minigame
    print("[DEBUG] Testing Fallout minigame...")
    local success2, result2 = pcall(function()
        return MiniGame_Fallout(nil, nil, "TestSkill", "Easy", nil, {skill="TestSkill", difficulty_english="Easy", displayName="Test USB"})
    end)
    if success2 and result2 then
        print("[SUCCESS] Fallout minigame created successfully")
        result2:setVisible(false)
        result2:removeFromUIManager()
    else
        print("[ERROR] Failed to create Fallout minigame: " .. tostring(result2))
    end

    print("[DEBUG] Both minigames tested. Check console for results.")
end

-- ✅ FUNCIÓN DE DEBUG PARA PROBAR SELECCIÓN ALEATORIA
function TestRandomSelection()
    print("[DEBUG] Testing random selection system...")
    local results = {sequence = 0, fallout = 0}

    for i = 1, 20 do
        local selected = selectRandomMinigame()
        results[selected] = results[selected] + 1
        print("[DEBUG] Test " .. i .. ": Selected " .. selected)
    end

    print("[DEBUG] Results after 20 tests:")
    print("[DEBUG]   Sequence: " .. results.sequence .. " times (" .. math.floor((results.sequence / 20) * 100) .. "%)")
    print("[DEBUG]   Fallout: " .. results.fallout .. " times (" .. math.floor((results.fallout / 20) * 100) .. "%)")

    if results.fallout > 0 then
        print("[SUCCESS] Random selection is working correctly!")
    else
        print("[WARNING] Random selection may not be working - no Fallout selections in 20 tests")
        print("[WARNING] Try running TestMathRandom() to debug the random generation")
    end
end

-- ✅ FUNCIÓN DE DEBUG PARA PROBAR MATH.RANDOM() DIRECTAMENTE
function TestMathRandom()
    print("[DEBUG] Testing math.random() directly...")

    -- Test 1: Check if math exists
    print("[DEBUG] math type: " .. type(math))
    print("[DEBUG] math: " .. tostring(math))

    -- Test 2: Check if math.random exists
    if math and math.random then
        print("[DEBUG] math.random type: " .. type(math.random))
        print("[DEBUG] math.random function exists!")

        -- Test 3: Try to call math.random
        print("[DEBUG] Calling math.random(1, 10)...")
        local success, result = pcall(function()
            return math.random(1, 10)
        end)

        if success then
            print("[DEBUG] math.random(1, 10) = " .. result)
            print("[DEBUG] math.random() is working correctly!")
        else
            print("[DEBUG] math.random() failed: " .. tostring(result))
        end
    else
        print("[DEBUG] math.random is not available!")
    end

    -- Test 4: Try alternative random generation
    print("[DEBUG] Testing alternative random generation...")
    local timestamp = os and os.time and os.time() or 0
    print("[DEBUG] os.time() = " .. timestamp)

    if timestamp > 0 then
        local pseudoRandom = timestamp % 2
        print("[DEBUG] Pseudo-random result: " .. pseudoRandom)
        print("[DEBUG] Alternative random generation working!")

        -- Test 5: Test the actual selection function
        print("[DEBUG] Testing selectRandomMinigame() function...")
        local selected = selectRandomMinigame()
        print("[DEBUG] selectRandomMinigame() returned: " .. selected)
    else
        print("[DEBUG] os.time() not available")
    end

    -- Test 6: Check ZombRand availability
    print("[DEBUG] Checking ZombRand...")
    print("[DEBUG] ZombRand type: " .. type(ZombRand))
    if ZombRand then
        print("[DEBUG] ZombRand function exists!")
        local success, result = pcall(function()
            return ZombRand(1, 10)
        end)
        if success then
            print("[DEBUG] ZombRand(1, 10) = " .. result)
        else
            print("[DEBUG] ZombRand() failed: " .. tostring(result))
        end
    else
        print("[DEBUG] ZombRand is not available")
    end
end

-- ✅ FUNCIÓN DE DEBUG PARA REINICIAR Y PROBAR EL SISTEMA
function ResetAndTestSystem()
    print("[DEBUG] Resetting and testing the complete system...")

    -- Test 1: Test math functions
    print("[DEBUG] === TESTING MATH FUNCTIONS ===")
    TestMathRandom()

    print("[DEBUG] === TESTING RANDOM SELECTION ===")
    -- Test 2: Test random selection
    TestRandomSelection()

    print("[DEBUG] === SYSTEM TEST COMPLETE ===")
    print("[DEBUG] If you see both 'sequence' and 'fallout' in the results, the system is working!")
    print("[DEBUG] If you only see 'sequence', there might be an issue with random generation.")
end

-- ✅ FUNCIÓN DE DEBUG SIMPLIFICADA PARA PROBAR SELECCIÓN ALEATORIA
function TestSimpleRandomSelection()
    print("[DEBUG] === TESTING SIMPLIFIED RANDOM SELECTION ===")
    local results = {sequence = 0, fallout = 0}

    for i = 1, 10 do
        local selected = selectRandomMinigame()
        results[selected] = results[selected] + 1
        print("[DEBUG] Test " .. i .. ": " .. selected)
    end

    print("[DEBUG] Final Results:")
    print("[DEBUG]   Sequence: " .. results.sequence .. " times (" .. math.floor((results.sequence / 10) * 100) .. "%)")
    print("[DEBUG]   Fallout: " .. results.fallout .. " times (" .. math.floor((results.fallout / 10) * 100) .. "%)")

    if results.sequence > 0 and results.fallout > 0 then
        print("[SUCCESS] ✅ Random selection is working! Both minigames are being selected.")
    elseif results.fallout == 0 then
        print("[ERROR] ❌ Only Sequence is being selected. Check random generation.")
    elseif results.sequence == 0 then
        print("[ERROR] ❌ Only Fallout is being selected. Check random generation.")
    end
end
