local DecryptDrivesContextMenu = {}
-- Señalizar que este módulo provee el menú moderno jerárquico
DecryptDrivesContextMenu.MODERN_MENU_ACTIVE = true
pcall(function() _G.DecryptDrivesContextMenu_MODERN = true end)

-- ========== SISTEMA DE DEBUG CONFIGURABLE ==========
-- 🔧 SWITCH MAESTRO DE DEBUG
-- true = Todos los debugs activos | false = Solo errores críticos
local DEBUG_ENABLED = false  -- ⚠️ Cambiar a true para ver debugs

-- Categorías de debug (para control granular cuando DEBUG_ENABLED = true)
local DEBUG_CATEGORIES = {
    MINIGAME_SELECTION = true,   -- Selección aleatoria de minijuegos
    USB_SCANNING = true,         -- Escaneo de USBs en inventario
    LAPTOP_VALIDATION = true,    -- Validación de laptops
    MENU_CREATION = true,        -- Creación de menús contextuales
    USB_SELECTION = true,        -- Selección y uso de USBs
    EVENT_SYSTEM = true,         -- Sistema de eventos
    CRITICAL_ONLY = true         -- Solo errores críticos (siempre activo)
}
-- =====================================================

-- Import centralized config
pcall(require, "shared/GVDrive_Config")

-- Debug print function con categorías
local function debugPrint(category, ...)
    -- Si DEBUG_ENABLED está desactivado, solo mostrar errores críticos
    if not DEBUG_ENABLED and category ~= "CRITICAL" then
        return
    end
    
    -- Verificar si la categoría está habilitada
    if category == "CRITICAL" or (DEBUG_CATEGORIES[category] == true) then
        print("[DecryptSkillSys][" .. category .. "]", ...)
    end
end

-- ========== CONFIGURACIÓN DE MINIJUEGO ==========
-- Sistema de selección aleatoria entre minijuegos disponibles:
-- "sequence" = Minijuego de secuencia (MiniGameUI.lua) - Memoria de secuencia
-- "fallout" = Minijuego de hacking Fallout (MiniGameFallout.lua) - Hacking de contraseñas
-- "circuit" = Minijuego de circuitos (MiniGameCircuit.lua) - Trazar circuitos
-- "packet" = Packet Interceptor (MiniGamePacket.lua) - Ritmo/acción
-- "encryption" = Encryption Cracker (MiniGameEncryption.lua) - Deducción
-- "laser" = Laser Grid Deflector (MiniGameLaser.lua) - Puzzle espacial
-- "hexflood" = Hex Memory Flood (MiniGameHexFlood.lua) - Match-3
-- "bitshift" = Bit Shift Cipher (MiniGameBitShift.lua) - Lógica binaria
-- "buffer" = Buffer Overflow Defender (MiniGameBufferDefense.lua) - Torre defensa
-- -- Testing individual
-- ReloadMiniGamePacket(); TestPacketInterceptor("Expert")
-- ReloadMiniGameEncryption(); TestEncryptionCracker("Moderate")
-- ReloadMiniGameLaser(); TestLaserDeflector("Easy")
-- ReloadMiniGameHexFlood(); TestHexFlood("Expert")
-- ReloadMiniGameBitShift(); TestBitShift("Moderate")
-- ReloadMiniGameBufferDefense(); TestBufferDefense("Easy")

-- -- Testing del sistema de selección aleatoria
-- TestRandomSelection()  -- Muestra distribución en 20 intentos

-- Lista de minijuegos disponibles
local AVAILABLE_MINIGAMES = {"sequence", "fallout", "circuit", "packet", "encryption", "bitshift", "buffer"}

-- Función para seleccionar minijuego aleatorio
local function selectRandomMinigame()
    debugPrint("MINIGAME_SELECTION", "selectRandomMinigame() called")
    debugPrint("MINIGAME_SELECTION", "AVAILABLE_MINIGAMES: " .. tostring(#AVAILABLE_MINIGAMES))

    if #AVAILABLE_MINIGAMES == 0 then
        debugPrint("CRITICAL", "No available minigames, returning fallback: fallout")
        return "fallout" -- Fallback
    end

    -- Usar ZombRand si está disponible
    if ZombRand then
        local randomIndex = ZombRand(1, #AVAILABLE_MINIGAMES + 1)
        local selectedGame = AVAILABLE_MINIGAMES[randomIndex]
        debugPrint("MINIGAME_SELECTION", "Selected game via ZombRand: " .. selectedGame)
        return selectedGame
    end

    -- Fallback: usar timestamp
    local timestamp = os and os.time and os.time() or 1000000
    local simpleRandom = (timestamp % #AVAILABLE_MINIGAMES) + 1
    local selectedGame = AVAILABLE_MINIGAMES[simpleRandom]
    debugPrint("MINIGAME_SELECTION", "Selected game via timestamp: " .. selectedGame)
    return selectedGame
end

-- Seleccionar minijuego aleatorio para esta sesión (ahora se hace por USB, no solo al cargar)
-- local ACTIVE_MINIGAME = selectRandomMinigame()
-- Eliminada la línea de debug que causaba error: print("[DEBUG] ACTIVE_MINIGAME set to: " .. ACTIVE_MINIGAME)

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
            module = "client/MiniGameUI",  -- Path con client/ para PZ
            reloadFunc = "ReloadMiniGame",
            displayName = "sequence"
        }
    elseif currentMinigame == "fallout" then
        return {
            name = "MiniGame_Fallout",  -- Función específica para Fallout (evita conflictos)
            module = "client/MiniGameFallout",  -- Path con client/ para PZ
            reloadFunc = "ReloadMiniGameFallout",
            displayName = "fallout hacking"
        }
    elseif currentMinigame == "circuit" then
        return {
            name = "MiniGame_Circuit",
            module = "client/MiniGameCircuit",
            reloadFunc = "ReloadMiniGameCircuit",
            displayName = "circuit tracer"
        }
    elseif currentMinigame == "packet" then
        return {
            name = "MiniGame_PacketInterceptor",
            module = "client/MiniGamePacket",
            reloadFunc = "ReloadMiniGamePacket",
            displayName = "packet interceptor"
        }
    elseif currentMinigame == "encryption" then
        return {
            name = "MiniGame_EncryptionCracker",
            module = "client/MiniGameEncryption",
            reloadFunc = "ReloadMiniGameEncryption",
            displayName = "encryption cracker"
        }
    elseif currentMinigame == "bitshift" then
        return {
            name = "MiniGame_BitShift",
            module = "client/MiniGameBitShift",
            reloadFunc = "ReloadMiniGameBitShift",
            displayName = "bit shift cipher"
        }
    elseif currentMinigame == "buffer" then
        return {
            name = "MiniGame_BufferDefense",
            module = "client/MiniGameBufferDefense",
            reloadFunc = "ReloadMiniGameBufferDefense",
            displayName = "buffer overflow defender"
        }
    else
        debugPrint("CRITICAL", "Invalid currentMinigame: " .. tostring(currentMinigame) .. ". Using default 'fallout'")
        return {
            name = "MiniGame_Fallout",
            module = "client/MiniGameFallout",
            reloadFunc = "ReloadMiniGameFallout",
            displayName = "fallout hacking"
        }
    end
end


local falloutGameLoaded = false
if _G.MiniGame_Fallout and type(_G.MiniGame_Fallout) == "function" then
    falloutGameLoaded = true
elseif _G.MiniGameFallout and type(_G.MiniGameFallout) == "function" then
    falloutGameLoaded = true
end

-- Verificar que Events esté disponible
if not Events then
    debugPrint("CRITICAL", "Events is nil at module load time - creating fallback")
    Events = { OnFillWorldObjectContextMenu = { Add = function() end } }
end

-- Create hierarchical context menu
function DecryptDrivesContextMenu.createHierarchicalMenu(player, context, laptop, usbList, healthOption)
    debugPrint("MENU_CREATION", "createHierarchicalMenu called")

    -- Try to use modular controller first
    if menuController then
        debugPrint("MENU_CREATION", "Using modular MenuController")
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
                debugPrint("CRITICAL", "MenuController returned without table option; falling back to legacy")
            else
                return option
            end
        else
            debugPrint("CRITICAL", "MenuController:createMenu failed: " .. tostring(result))
        end
    end

    -- Fallback to legacy implementation
    debugPrint("MENU_CREATION", "Using legacy menu implementation - MenuController not available")
    return DecryptDrivesContextMenu.createHierarchicalMenuLegacy(player, context, laptop, usbList, healthOption)
end

-- ============================================================================
-- MODULE INITIALIZATION
-- ============================================================================

debugPrint("EVENT_SYSTEM", "DecryptDrivesContextMenu.lua starting to load...")
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

-- Módulo cargado (mensaje inicial removido para limpieza)

-- =========================================================================
-- UI HELPERS
-- =========================================================================

local USB_ICON_PATH = "media/textures/ui/usb/usb.png"
local usbIconCache = false -- false = not yet attempted, nil = attempted but missing

function DecryptDrivesContextMenu.getUSBIconTexture()
    if usbIconCache == false then
        usbIconCache = getTexture(USB_ICON_PATH)
        if not usbIconCache then
            debugPrint("CRITICAL", "USB icon texture could not be loaded: " .. USB_ICON_PATH)
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
        debugPrint("MENU_CREATION", "applyUSBMenuFormatting: No main option table available; skipping formatting")
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
    debugPrint("LAPTOP_VALIDATION", "isValidLaptop called")
    
    -- Verificación básica del objeto
    if not worldObject then
        debugPrint("LAPTOP_VALIDATION", "worldObject es nil")
        return false, "No se proporcionó ningún objeto"
    end
    
    -- ✅ MULTIPLAYER: Validación mínima de sincronización (MUY PERMISIVO)
    -- NOTA: En multiplayer, los objetos pueden tener delays de sincronización
    -- Solo validamos que el objeto exista, no su estado de sincronización
    if isClient and isClient() then
        debugPrint("LAPTOP_VALIDATION", "Running in multiplayer client mode - using permissive validation")
    end
    
    -- 🔍 DIAGNÓSTICO: Imprimir información detallada del objeto
    local objClassName = "unknown"
    if worldObject.getClass then
        local ok, classObj = pcall(function() return worldObject:getClass() end)
        if ok and classObj then
            -- getClass() devuelve un objeto Java, usar tostring directamente
            objClassName = tostring(classObj)
        end
    end
    debugPrint("LAPTOP_VALIDATION", "🔍 Objeto detectado - Clase: " .. objClassName)
    
    -- Verificar tipos específicos
    local isIsoObject = instanceof(worldObject, "IsoObject")
    local isIsoWorldInventoryObject = instanceof(worldObject, "IsoWorldInventoryObject")
    local isIsoThumpable = instanceof(worldObject, "IsoThumpable")
    
    debugPrint("LAPTOP_VALIDATION", string.format("  - IsoObject: %s", tostring(isIsoObject)))
    debugPrint("LAPTOP_VALIDATION", string.format("  - IsoWorldInventoryObject: %s", tostring(isIsoWorldInventoryObject)))
    debugPrint("LAPTOP_VALIDATION", string.format("  - IsoThumpable: %s", tostring(isIsoThumpable)))
    
    -- Verificar si el objeto es un IsoObject
    if not isIsoObject then
        debugPrint("LAPTOP_VALIDATION", "❌ No es un IsoObject, tipo: " .. objClassName)
        return false, "No es un objeto del mundo válido"
    end
    
    -- ✅ MULTIPLAYER FIX: Intentar obtener el ítem de múltiples formas
    local item = nil
    
    -- Método 1: IsoWorldInventoryObject (objetos en el suelo con inventario)
    if instanceof(worldObject, "IsoWorldInventoryObject") then
        debugPrint("LAPTOP_VALIDATION", "Es un IsoWorldInventoryObject, usando getItem()")
        local success, result = pcall(function() return worldObject:getItem() end)
        if success and result then
            item = result
        end
    end
    
    -- Método 2: IsoThumpable con getItem() (laptops en el suelo)
    if not item and instanceof(worldObject, "IsoThumpable") then
        debugPrint("LAPTOP_VALIDATION", "Es un IsoThumpable, intentando getItem()")
        if worldObject.getItem and type(worldObject.getItem) == "function" then
            local success, result = pcall(function() return worldObject:getItem() end)
            if success and result then
                item = result
                debugPrint("LAPTOP_VALIDATION", "✅ Item obtenido via IsoThumpable:getItem()")
            end
        end
    end
    
    -- Método 3: IsoObject genérico (puede tener getModData con referencia al item)
    if not item and worldObject.getModData then
        debugPrint("LAPTOP_VALIDATION", "Intentando obtener item via getModData()")
        local success, modData = pcall(function() return worldObject:getModData() end)
        if success and modData and modData.item then
            item = modData.item
            debugPrint("LAPTOP_VALIDATION", "✅ Item obtenido via getModData()")
        end
    end
    
    -- Método 4: Verificar sprite del objeto (detección por nombre)
    if not item and worldObject.getSprite then
        debugPrint("LAPTOP_VALIDATION", "Verificando sprite del objeto")
        local success, sprite = pcall(function() return worldObject:getSprite() end)
        if success and sprite then
            local spriteName = ""
            if sprite.getName and type(sprite.getName) == "function" then
                local nameSuccess, name = pcall(function() return sprite:getName() end)
                if nameSuccess and name then
                    spriteName = tostring(name):lower()
                    debugPrint("LAPTOP_VALIDATION", "Sprite detectado: " .. spriteName)
                end
            end
            
            -- Si el sprite contiene "laptop", validar por nombre del objeto
            if spriteName:find("laptop") or spriteName:find("computer") or spriteName:find("asus") or spriteName:find("toshiba") or spriteName:find("ibm") then
                debugPrint("LAPTOP_VALIDATION", "Sprite de laptop detectado: " .. spriteName)
                
                -- Verificar nombre del objeto
                local objName = ""
                if worldObject.getName and type(worldObject.getName) == "function" then
                    local nameOk, name = pcall(function() return worldObject:getName() end)
                    if nameOk and name then
                        objName = tostring(name):lower()
                        debugPrint("LAPTOP_VALIDATION", "Nombre del objeto: " .. objName)
                    end
                end
                
                -- Validar por nombre o sprite
                if objName:find("laptop") or objName:find("asus") or objName:find("toshiba") or objName:find("ibm") or
                   spriteName:find("laptop") or spriteName:find("asus") or spriteName:find("toshiba") or spriteName:find("ibm") then
                    debugPrint("LAPTOP_VALIDATION", "✅ Laptop detectada por sprite/nombre (IsoThumpable sin item)")
                    -- Retornar el worldObject como "laptop válida" para que se maneje en addContextMenuOption
                    return true, "Laptop válida (IsoThumpable)", worldObject
                end
            end
        end
    end
    
    if not item then
        debugPrint("LAPTOP_VALIDATION", "❌ No se pudo obtener el ítem del objeto por ningún método")
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
    
    debugPrint("LAPTOP_VALIDATION", string.format("Analizando objeto: %s (Tipo: %s, FullType: %s)", 
        itemName, itemType, itemFullType))
    
    -- Verificar si es un tipo de laptop válido
    local isLaptop = false
    
    -- Usar pcall para iterar sobre LAPTOP_TYPES de forma segura
    local typeCheckSuccess, typeCheckResult = pcall(function()
        for _, laptopType in ipairs(DECRYPT_CONFIG.LAPTOP_TYPES) do
            if itemFullType:find(laptopType, 1, true) or itemType:find(laptopType, 1, true) then
                debugPrint("LAPTOP_VALIDATION", "Coincidencia de tipo de laptop: " .. laptopType)
                return true
            end
        end
        return false
    end)
    
    if typeCheckSuccess then
        isLaptop = typeCheckResult
    else
        debugPrint("CRITICAL", "Error al verificar tipos de laptop: " .. tostring(typeCheckResult))
    end
    
    -- Para depuración: verificar si contiene "Laptop" en el nombre o tipo
    if not isLaptop then
        local laptopInName = itemName:lower():find("laptop") ~= nil
        local laptopInType = itemType:lower():find("laptop") ~= nil or itemFullType:lower():find("laptop") ~= nil
        
        if laptopInName or laptopInType then
            debugPrint("LAPTOP_VALIDATION", "Se encontró 'Laptop' en el nombre o tipo, pero no en LAPTOP_TYPES")
            debugPrint("LAPTOP_VALIDATION", "Considere agregar este tipo a DECRYPT_CONFIG.LAPTOP_TYPES:")
            debugPrint("LAPTOP_VALIDATION", "Nombre: " .. itemName)
            debugPrint("LAPTOP_VALIDATION", "Tipo: " .. itemType)
            debugPrint("LAPTOP_VALIDATION", "FullType: " .. itemFullType)
            -- Aceptar temporalmente laptops que contengan "laptop" en el nombre/tipo
            isLaptop = true
        end
    end
    
    -- Resultado final
    if isLaptop then
        debugPrint("LAPTOP_VALIDATION", "Laptop válida detectada: " .. itemName)
        return true, "Laptop válida: " .. itemName
    else
        debugPrint("LAPTOP_VALIDATION", "No es una laptop válida: " .. itemName .. " (Tipo: " .. itemType .. ")")
        return false, "No es una laptop compatible"
    end
end

-- ============================================================================
-- USB SCANNING AND GROUPING FUNCTIONS
-- ============================================================================

-- Scan player inventory for USB drives
function DecryptDrivesContextMenu.scanPlayerUSBs(player)
    debugPrint("USB_SCANNING", "scanPlayerUSBs called")

    if not player then
        debugPrint("USB_SCANNING", "Player is nil")
        return {}
    end

    local inventory
    local success, result = pcall(function() return player:getInventory() end)
    if success and result then
        inventory = result
    else
        debugPrint("USB_SCANNING", "Error getting inventory: " .. tostring(result))
        return {}
    end

    if not inventory then
        debugPrint("USB_SCANNING", "No inventory found")
        return {}
    end

    local items
    local itemsSuccess, itemsResult = pcall(function() return inventory:getItems() end)
    if itemsSuccess and itemsResult then
        items = itemsResult
    else
        debugPrint("USB_SCANNING", "Error getting items: " .. tostring(itemsResult))
        return {}
    end

    local itemCount = 0
    local sizeSuccess, sizeResult = pcall(function() return items:size() end)
    if sizeSuccess then
        itemCount = sizeResult or 0
    end
    debugPrint("USB_SCANNING", "Inventory items count: " .. itemCount)

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
                    debugPrint("USB_SCANNING", "USB entry created via GVDrive_Utils: " .. tostring(info.skillName))
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

    debugPrint("USB_SCANNING", "USB scan completed, found " .. tostring(#usbList) .. " USBs")
    return usbList
end

-- Parse USB data from item and fullType
function DecryptDrivesContextMenu.parseUSBData(item, fullType)
    debugPrint("USB_SCANNING", "parseUSBData called with: " .. tostring(fullType))

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
        debugPrint("USB_SCANNING", "USB entry created via parseUSBData: " .. skillName)
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
-- ✅ MULTIPLAYER FIX: Usar firma estándar con playerIndex (número)
function DecryptDrivesContextMenu.addContextMenuOption(playerIndex, context, worldobjects, test)
    debugPrint("MENU_CREATION", "========== addContextMenuOption STARTED ==========")
    debugPrint("MENU_CREATION", "PlayerIndex type: " .. type(playerIndex) .. ", value: " .. tostring(playerIndex))
    debugPrint("MENU_CREATION", "Context: " .. tostring(context))
    debugPrint("MENU_CREATION", "WorldObjects count: " .. (worldobjects and #worldobjects or 0))
    debugPrint("MENU_CREATION", "Test mode: " .. tostring(test))
    
    -- Skip if test mode
    if test then
        debugPrint("MENU_CREATION", "Skipping - test mode active")
        return
    end
    
    -- ✅ MULTIPLAYER: Verificar si estamos en cliente
    if isClient then
        debugPrint("MENU_CREATION", "Running in MULTIPLAYER CLIENT mode")
    else
        debugPrint("MENU_CREATION", "Running in SINGLEPLAYER mode")
    end

    -- ✅ MULTIPLAYER FIX: Convertir playerIndex a IsoPlayer (patrón estándar)
    local playerObj = getSpecificPlayer(playerIndex)
    
    if not playerObj then
        debugPrint("CRITICAL", "Skipping - failed to get player from index: " .. tostring(playerIndex))
        return
    end
    
    if playerObj:isDead() then
        debugPrint("MENU_CREATION", "Skipping - player is dead")
        return
    end
    
    if not context then
        debugPrint("CRITICAL", "Skipping - context is nil")
        return
    end
    
    if not worldobjects then
        debugPrint("CRITICAL", "Skipping - worldobjects is nil")
        return
    end

    -- ✅ PATRÓN DEL JUEGO: Buscar laptops en el square como hace el juego con generadores
    local laptopItem = nil
    local laptopSquare = nil
    
    for _, object in ipairs(worldobjects) do
        local square = object:getSquare()
        if square then
            debugPrint("MENU_CREATION", "Checking square for laptops...")
            -- Buscar en los worldObjects del square (como hace ISBBQMenu)
            local wobs = square:getWorldObjects()
            for i = 0, wobs:size() - 1 do
                local wo = wobs:get(i)
                local item = wo:getItem()
                if item then
                    local itemType = item:getFullType()
                    debugPrint("MENU_CREATION", "Found item in square: " .. tostring(itemType))
                    
                    -- Verificar si es una laptop válida
                    if itemType and (
                        itemType:find("AsusZeph") or 
                        itemType:find("Laptop90s") or 
                        itemType:find("PBIBM_LP90") or
                        itemType:find("LaptopOpened")
                    ) then
                        laptopItem = item
                        laptopSquare = square
                        debugPrint("MENU_CREATION", "✅ Valid laptop found in square: " .. itemType)
                        break
                    end
                end
            end
            if laptopItem then break end
        end
    end

    if laptopItem and laptopSquare then
        debugPrint("MENU_CREATION", "Valid laptop found!")
        
        -- Add laptop health status at the top with battery icon
        local healthOption = DecryptDrivesContextMenu.addLaptopHealthStatus(context, playerObj, laptopItem)
        debugPrint("MENU_CREATION", "Health status added to menu")

        -- Scan for USBs in player inventory
        local usbList = DecryptDrivesContextMenu.scanPlayerUSBs(playerObj)

        if #usbList > 0 then
            debugPrint("MENU_CREATION", "USBs found: " .. #usbList)
            -- Create hierarchical menu (pasar laptopItem en lugar de worldObject)
            local mainOption = DecryptDrivesContextMenu.createHierarchicalMenu(playerObj, context, laptopItem, usbList, healthOption)
            DecryptDrivesContextMenu.applyUSBMenuFormatting(context, mainOption, healthOption)
            debugPrint("MENU_CREATION", "USB menu created")
        else
            debugPrint("MENU_CREATION", "No USBs found in player inventory")
        end

        -- Add antivirus options (pasar laptopItem)
        DecryptDrivesContextMenu.addAntivirusOptions(context, playerObj, laptopItem)

        -- Add elite drive options
        DecryptDrivesContextMenu.addEliteDriveOptions(context, playerObj)

        -- Mark context to indicate modern menu has been attached (defensive against other handlers)
        context._DecryptDrives_ModernMenu = true

        debugPrint("MENU_CREATION", "addContextMenuOption ENDED (complete menu created)")
    else
        debugPrint("MENU_CREATION", "No valid laptop found in worldobjects")
    end
end

-- ============================================================================
-- MODULAR MENU SYSTEM INTEGRATION (Simplified)
-- ============================================================================

-- Simplified approach - just use legacy implementation for reliability

-- Create hierarchical context menu
function DecryptDrivesContextMenu.createHierarchicalMenu(player, context, laptop, usbList)
    debugPrint("MENU_CREATION", "createHierarchicalMenu called")

    -- Use legacy implementation directly (more reliable)
    debugPrint("MENU_CREATION", "Using legacy menu implementation for reliability")
    return DecryptDrivesContextMenu.createHierarchicalMenuLegacy(player, context, laptop, usbList)
end

-- Legacy implementation (kept for compatibility)
function DecryptDrivesContextMenu.createHierarchicalMenuLegacy(player, context, laptop, usbList, healthOption)
    debugPrint("MENU_CREATION", "createHierarchicalMenuLegacy called with " .. #usbList .. " USBs")

    -- Group USBs by skill
    local groupedUSBs = DecryptDrivesContextMenu.groupUSBsBySkill(usbList)

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
            if not difficulties[diff] then
                difficulties[diff] = {}
            end
            table.insert(difficulties[diff], usbData)
        end

        -- Create difficulty submenus with proper order
        local diffOrder = {"Facil", "Moderado", "Dificil"}
        for _, difficultyName in ipairs(diffOrder) do
            if difficulties[difficultyName] and #difficulties[difficultyName] > 0 then
                local count = #difficulties[difficultyName]
                local firstUSB = difficulties[difficultyName][1]
                
                -- Validación crítica: Verificar que el primer USB sea válido
                if firstUSB and firstUSB.displayName then
                    -- Add difficulty option that directly triggers action with the first USB
                    skillSubMenu:addOption(
                        difficultyName .. " x" .. count,
                        player,
                        function(playerObj, laptopObj)
                            -- Llamar onUSBSelected con parámetros garantizados
                            DecryptDrivesContextMenu.onUSBSelected(playerObj, laptop, firstUSB)
                        end
                    )
                else
                    debugPrint("CRITICAL", "Invalid first USB data for difficulty: " .. difficultyName .. " in skill " .. skill)
                end
            end
        end
    end

    debugPrint("MENU_CREATION", "Context menu created with " .. #usbList .. " USB options")
    return mainOption
end

-- ============================================================================
-- USB SELECTION HANDLER
-- ============================================================================

-- Handle USB selection from context menu
function DecryptDrivesContextMenu.onUSBSelected(player, laptop, usbData)
    debugPrint("USB_SELECTION", "onUSBSelected called")
    
    -- Validación mejorada
    if not usbData then
        debugPrint("CRITICAL", "onUSBSelected called with nil usbData")
        return
    end
    
    -- Validación crítica: Verificar que usbData sea una tabla válida
    if type(usbData) ~= "table" then
        debugPrint("CRITICAL", "onUSBSelected called with usbData that is not a table")
        debugPrint("CRITICAL", "usbData type: " .. type(usbData))
        return
    end
    
    if not usbData.displayName then
        debugPrint("CRITICAL", "onUSBSelected called with usbData missing displayName")
        return
    end

    debugPrint("USB_SELECTION", "USB selected: " .. usbData.displayName)

    -- ✅ FIX: laptop ahora es directamente el item, no un worldObject
    local laptopItem = laptop

    -- Verificación crítica: Verificar salud de la laptop antes de iniciar minijuego
    if laptopItem and LaptopSystem then
        local laptopHealth = LaptopSystem.getLaptopHealth(laptopItem)
        if type(laptopHealth) == "number" and laptopHealth <= 0 then
            debugPrint("CRITICAL", "Laptop health is 0% or less, cannot start minigame")
            player:Say("This laptop is completely dead. It cannot run any decryption software.")
            return
        end
    end

    -- Configurar y abrir minijuego con integración USB
    local usbType = usbData.skill
    local difficulty = usbData.difficulty_english

    -- Validación crítica: Verificar que usbType sea válido antes de proceder
    if not usbType or usbType == "" then
        debugPrint("CRITICAL", "usbData.skill is nil or empty")
        player:Say("Invalid USB skill data. Cannot proceed with decryption.")
        return
    end

    if usbType and difficulty then
        -- Obtener configuración fresca cada vez (selección aleatoria por USB)
        local currentConfig = getActiveMinigameConfig()
        debugPrint("USB_SELECTION", "Opening minigame: " .. currentConfig.displayName)

        -- Verificación y recarga del minijuego activo
        if not _G[currentConfig.name] or type(_G[currentConfig.name]) ~= "function" then
            debugPrint("USB_SELECTION", "Reloading " .. currentConfig.module .. " module...")
            if package and package.loaded then
                package.loaded[currentConfig.module] = nil
            end
            local ok, result = pcall(require, currentConfig.module)
            if not ok then
                debugPrint("CRITICAL", "Failed to reload " .. currentConfig.module .. " module: " .. tostring(result))
            end
        end

        if _G[currentConfig.name] and type(_G[currentConfig.name]) == "function" then
            -- ✅ DETENER SONIDO USBSys ANTES DE ABRIR MINIJUEGO
            if player and player.getEmitter and player:getEmitter() then
                local emitter = player:getEmitter()
                if emitter and emitter.stopSoundByName then
                    emitter:stopSoundByName("USBSys")
                    debugPrint("USB_SELECTION", "Stopped USBSys sound before opening minigame")
                end
            end
            
            -- ✅ REPRODUCIR SONIDO LAPTOP STARTUP AL ABRIR MINIJUEGO
            if DynamicSoundSystem and DynamicSoundSystem.playLaptopStartup then
                DynamicSoundSystem.playLaptopStartup(player, 0.4)
                debugPrint("USB_SELECTION", "Playing laptop_startup.ogg")
            end
            
            -- Permitir que el minijuego use la configuración global de ventana
            local success, minigame = pcall(_G[currentConfig.name], nil, nil, usbType, difficulty, laptopItem, usbData)
            if success and minigame then
                debugPrint("USB_SELECTION", currentConfig.displayName .. " minigame opened successfully")
                player:Say("Initializing " .. usbType .. " decryption protocol (" .. difficulty .. " level) - " .. (currentConfig.name == "MiniGame_Fallout" and "Password Hacking..." or "Sequence Memory..."))
            else
                debugPrint("CRITICAL", "Failed to create " .. currentConfig.displayName .. " minigame: " .. tostring(minigame))
                player:Say("Error initializing " .. (currentConfig.name == "MiniGame_Fallout" and "password hacking" or "sequence decryption") .. " system.")
            end
        else
            debugPrint("CRITICAL", currentConfig.name .. " function not available in global scope")
            player:Say("No " .. (currentConfig.name == "MiniGame_Fallout" and "password hacking" or "decryption") .. " protocol available for this drive type.")
        end
    else
        debugPrint("CRITICAL", "Invalid USB data - skill: " .. tostring(usbType) .. ", difficulty: " .. tostring(difficulty))
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
        debugPrint("CRITICAL", "getBatteryTextureForHealth: healthPercent is not a number")
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
    end

    -- Get failure count
    local failureCount = 0
    if LaptopSystem then
        failureCount = LaptopSystem.getFailureCount(laptopItem)
    end
    
    -- 🌡️ Get temperature
    local temperature = 20
    local tempLevel = "Cool"
    local tempColor = {r=0.3, g=0.7, b=1, a=1}
    if LaptopThermalSystem then
        temperature = LaptopThermalSystem.getTemperature(laptopItem)
        tempLevel, tempColor = LaptopThermalSystem.getTemperatureLevel(temperature)
    end

    -- Ensure laptopHealth is valid
    if type(laptopHealth) ~= "number" then
        debugPrint("CRITICAL", "Laptop health is not a number")
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

    -- Display format: Health: percentage (status) - Temp: temp°C (level) - Fails: count
    local healthDisplay = "Health: " .. laptopHealth .. "% (" .. healthStatus .. ") - " .. math.floor(temperature) .. "°C (" .. tempLevel .. ") - " .. failureCount .. " Fails"

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
        
        -- Información de temperatura adicional
        if temperature >= 85 then
            player:Say("Warning: The laptop is critically hot! Let it cool down.")
        elseif temperature >= 70 then
            player:Say("The laptop is running quite warm. Be careful.")
        end
    end)

    -- Assign battery texture as icon to the context menu option
    if batteryTexture then
        healthOption.iconTexture = batteryTexture
    end

    return healthOption
end
-- ============================================================================
-- ANTIVIRUS SYSTEM
-- ============================================================================

-- Add antivirus options to context menu
function DecryptDrivesContextMenu.addAntivirusOptions(context, player, laptopItem)
    if not player or not laptopItem then return end

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
                    DecryptDrivesContextMenu.useAntivirus(player, laptopItem, avType)
                end)
            end
        end
    end
end

-- Use antivirus on laptop
function DecryptDrivesContextMenu.useAntivirus(player, laptopItem, avType)
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
        -- ✅ FIX: laptopItem ya es el item directamente
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
                    if success and item and type(item) == "table" then
                        -- Validar que item tenga los métodos necesarios
                        local itemName = "Sin nombre"
                        local itemType = "Sin tipo"
                        local itemFullType = "Sin tipo completo"
                        
                        if item.getName and type(item.getName) == "function" then
                            local ok, name = pcall(function() return item:getName() end)
                            if ok and name then itemName = name end
                        end
                        
                        if item.getType and type(item.getType) == "function" then
                            local ok, itype = pcall(function() return item:getType() end)
                            if ok and itype then itemType = itype end
                        end
                        
                        if item.getFullType and type(item.getFullType) == "function" then
                            local ok, ftype = pcall(function() return item:getFullType() end)
                            if ok and ftype then itemFullType = ftype end
                        end
                        
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
                    if obj.getSprite and type(obj.getSprite) == "function" then
                        local success, sprite = pcall(function() return obj:getSprite() end)
                        if success and sprite and type(sprite) == "table" then
                            if sprite.getName and type(sprite.getName) == "function" then
                                local ok, spriteName = pcall(function() return sprite:getName() end)
                                if ok and spriteName then
                                    debugPrint(string.format("  - Sprite: %s", tostring(spriteName)))
                                end
                            end
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

-- ============================================================================
-- REGISTRO DE EVENTO - PATRÓN SIMPLE Y CONFIABLE
-- ============================================================================
-- Basado en mods funcionales: MeatCurse y BurnCorpses
-- Ambos usan OnFillWorldObjectContextMenu de forma directa sin complicaciones
-- Referencia: MeatCurseContextMenu.lua línea 122, BurnCorpsePilesContextMenu.lua línea 133

-- ✅ FIX: Wrapper function para evitar "__call metatable not set"
local function onFillWorldObjectContextMenuWrapper(playerIndex, context, worldobjects, test)
    if DecryptDrivesContextMenu and DecryptDrivesContextMenu.addContextMenuOption then
        DecryptDrivesContextMenu.addContextMenuOption(playerIndex, context, worldobjects, test)
    else
        print("[ERROR] DecryptDrivesContextMenu.addContextMenuOption not available")
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenuWrapper)

print("[DecryptSkillSys] ✅ Evento OnFillWorldObjectContextMenu registrado exitosamente")
print("[DecryptSkillSys] Sistema de menú contextual cargado")
print("[DecryptSkillSys] DEBUG_ENABLED: " .. tostring(DEBUG_ENABLED))

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
