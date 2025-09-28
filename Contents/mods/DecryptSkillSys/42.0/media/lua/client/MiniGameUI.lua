-- ✅ MINIJUEGO SEPARADO CON FORMATO COMPLETO RESTAURADO
-- MiniGameUI.lua - Sistema de minijuego independiente para DecryptSkillSys
-- Basado en patrones del CODEBASE y memorias de formato perfecto

-- ✅ FUNCIÓN DE DEBUG PARA PROBAR CONSUMO DE USB
function TestUSBConsumption()
    print("[DEBUG] Testing USB consumption logic...")
    local player = getPlayer()
    if not player then
        print("[ERROR] No player found for testing")
        return
    end

    local inventory = player:getInventory()
    if not inventory then
        print("[ERROR] No inventory found")
        return
    end

    -- Buscar un USB en el inventario
    local usbItem = nil
    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getFullType() and string.find(item:getFullType(), "SkillDrive_") then
            usbItem = item
            break
        end
    end

    if not usbItem then
        print("[ERROR] No USB found in inventory for testing")
        return
    end

    print("[DEBUG] Found USB: " .. tostring(usbItem:getName()) .. " (" .. tostring(usbItem:getFullType()) .. ")")

    -- Simular la lógica de consumo de USB
    if inventory:contains(usbItem) then
        inventory:Remove(usbItem)
        print("[SUCCESS] USB consumed from inventory: " .. tostring(usbItem:getName()))
    else
        print("[WARNING] USB not found in inventory for consumption")
    end
end

-- ✅ FUNCIÓN DE RECARGA PARA DEBUG - Permite recargar sin reiniciar el juego
function ReloadMiniGame()
    print("[DEBUG] Reloading MiniGame system...")
    
    -- Limpiar función global anterior
    if MiniGame then
        MiniGame = nil
        print("[DEBUG] Previous MiniGame function cleared")
    end
    
    -- Forzar recarga del módulo
    package.loaded["client/MiniGameUI"] = nil
    
    -- Recargar
    local success, result = pcall(require, "client/MiniGameUI")
    if success then
        print("[DEBUG] MiniGame system reloaded successfully!")
        print("[DEBUG] You can now test different configurations by calling MiniGame(width%, height%)")
        print("[DEBUG] Example: MiniGame(30, 40) for 30% width, 40% height")
    else
        print("[DEBUG] Failed to reload MiniGame: " .. tostring(result))
    end
end

-- ✅ FUNCIÓN DE PRUEBA RÁPIDA PARA DEBUG
function TestMiniGame(widthPct, heightPct)
    widthPct = widthPct or WINDOW_WIDTH_PCT
    heightPct = heightPct or WINDOW_HEIGHT_PCT
    print("[DEBUG] Testing MiniGame with size: " .. widthPct .. "% x " .. heightPct .. "%")
    
    if MiniGame then
        return MiniGame(widthPct, heightPct, "TestSkill", "Easy", nil, {skill="TestSkill", difficulty_english="Easy", displayName="Test USB"})
    else
        print("[DEBUG] MiniGame function not available. Try ReloadMiniGame() first.")
    end
end

-- ========== CONFIGURACIÓN DEL GRID ==========
local GRID_ROWS = 4           -- Número de filas (ej: 2 para 2x2, 4 para 4x4)
local GRID_COLS = 4           -- Número de columnas (ej: 2 para 2x2, 4 para 4x4)  
local SEQUENCE_LENGTH = 5     -- Longitud de la secuencia a recordar
local BUTTON_SIZE = 10        -- Tamaño de los botones en píxeles
local BUTTON_SPACING = 8      -- Espaciado entre botones en píxeles
local SEQUENCE_DELAY = 30     -- Ticks entre cada paso de secuencia (20 = 1 segundo)
local RESULT_DISPLAY_TIME = 180 -- Ticks para mostrar resultado antes de cerrar (180 = 9 segundos)
local AUTO_CLOSE_DELAY = 60     -- Ticks para cierre automático después de llenar grid (60 = 3 segundos)
local DIFFICULTY_PATTERNS = 2 -- Número de patrones simultáneos (1-3): 1=Solo verde, 2=Verde+Rojo, 3=Verde+Rojo+Azul
local DIFFICULTY_TEXT = "DIFFICULTY: ADVANCED [GREEN PATTERN ONLY]" -- Texto configurable de dificultad
-- =============================================

-- ========== CONFIGURACIÓN DE ESCALADO ADAPTATIVO (de MiniGameFallout.lua) ==========
local PADDING_HORIZONTAL = 40   -- Espacio horizontal alrededor de elementos
local PADDING_VERTICAL = 90     -- Espacio vertical para título y controles
local MIN_BUTTON_SIZE = 20      -- Tamaño mínimo de botones
local MAX_BUTTON_SIZE = 40      -- Tamaño máximo de botones
local BUTTON_SIZE_FALLBACK = 30 -- Tamaño preferido de botones
local BUTTON_SPACING_FALLBACK = 10 -- Espaciado entre botones
-- ========== CONFIGURACIÓN DE VENTANA ==========
local WINDOW_WIDTH_PCT = 15     -- Porcentaje del ancho de pantalla
local WINDOW_HEIGHT_PCT = 35    -- Porcentaje del alto de pantalla
local WINDOW_WIDTH = 400        -- Ancho fallback en píxeles
local WINDOW_HEIGHT = 500       -- Alto fallback en píxeles
-- ============== DIFFICULTY SETTINGS (de MiniGameFallout.lua) ===============
local EASY_DELAY = 38
local MODERATE_DELAY = 35
local EXPERT_DELAY = 31
local EASY_LENGTH = 4
local MODERATE_LENGTH = 5
local EXPERT_LENGTH = 6
local EASY_PATTERNS = 1
local MODERATE_PATTERNS = 2
local EXPERT_PATTERNS = 3
-- ============== XP AND DAMAGE SETTINGS (ahora desde SandboxVars) ===============
-- Los valores se obtienen dinámicamente de GVDrive_Utils usando SandboxVars
-- XP: USB_Min_Experience, USB_Max_Experience + bonuses por dificultad
-- Daño: Laptop_Damage_Min/Max por dificultad
-- =============================================

-- SISTEMA DE TIMERS ULTRA SIMPLE - Sin closures complejos
local SimpleTimer = {}
SimpleTimer.activeTimers = {}

-- Estructura: {callback = function, duration = ticks, elapsed = 0, id = uniqueId}
SimpleTimer.nextId = 1

function SimpleTimer:addTimer(duration, callback)
    local id = self.nextId
    self.nextId = self.nextId + 1
    
    self.activeTimers[id] = {
        callback = callback,
        duration = duration,
        elapsed = 0
    }
    
    return id
end

function SimpleTimer:removeTimer(id)
    self.activeTimers[id] = nil
end

function SimpleTimer:update()
    local toRemove = {}
    
    for id, timer in pairs(self.activeTimers) do
        timer.elapsed = timer.elapsed + 1
        if timer.elapsed >= timer.duration then
            -- Ejecutar callback de forma segura
            if timer.callback and type(timer.callback) == 'function' then
                local success, err = pcall(timer.callback)
                if not success then
                    print("SimpleTimer: Callback error:", err)
                end
            end
            toRemove[id] = true
        end
    end
    
    -- Remover timers completados
    for id in pairs(toRemove) do
        self.activeTimers[id] = nil
    end
end

-- Registrar el sistema de timers ultra simple (solo si Events existe)
if Events and Events.OnTick and Events.OnTick.Add then
    Events.OnTick.Add(function() SimpleTimer:update() end)
else
    print("[MiniGameUI] Events not available - timers will not be registered (expected in test environment)")
end

local MiniGameWindow = ISPanel:derive("MiniGameWindow")

function MiniGameWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    -- ✅ PROPIEDADES ESTÉTICA ALIEN CRT RESTAURADA
    o.player = player
    o.backgroundColor = {r=0.05, g=0.2, b=0.05, a=0.9}  -- Fondo verde CRT
    o.borderColor = {r=0.2, g=1, b=0.2, a=1}            -- Borde verde brillante
    o.moveWithMouse = true
    
    -- ✅ INTEGRACIÓN USB MANTENIDA (pipeline intacto)
    o.usbType = usbType
    o.difficulty = difficulty  
    o.laptopItem = laptopItem
    o.usbData = usbData
    
    -- ✅ ESTADO DEL JUEGO COMPLETO
    o.sequence = {}
    o.currentIndex = 1
    o.playing = false
    o.userInput = {}
    o.sequenceLength = SEQUENCE_LENGTH
    o.sequenceButtons = {}
    o.typingIndex = 0  -- ✅ PARA ANIMACIÓN DE TIPEO
    o.resultProcessed = false  -- ✅ FLAG PARA EVITAR DOBLE PROCESAMIENTO

    -- ✅ ANIMACIÓN DE REVELACIÓN DEL GRID
    o.gridRevealed = false   -- Si el grid ya se reveló
    o.revealIndex = 0        -- Índice actual de revelación
    o.totalButtons = GRID_ROWS * GRID_COLS  -- Total de botones a revelar

    -- ✅ CONFIGURACIÓN AUTOMÁTICA SEGÚN USB
    o:configureFromUSB()
    return o
end

function MiniGameWindow:configureFromUSB()
    -- Configurar automáticamente el minijuego según la dificultad del USB
    if not self.usbType or not self.difficulty then
        print("MiniGame: No USB parameters provided, using default configuration")
        return
    end

    -- Configuración equilibrada por dificultad
    local config = self:getDifficultyConfig(self.difficulty)

    -- Aplicar configuración global
    SEQUENCE_LENGTH = config.sequenceLength
    SEQUENCE_DELAY = config.delay
    DIFFICULTY_PATTERNS = config.patterns
    DIFFICULTY_TEXT = config.displayText

    print(string.format("MiniGame: Configured for USB %s - Difficulty: %s - Patterns: %d, Length: %d, Delay: %d",
        tostring(self.usbType), tostring(self.difficulty), config.patterns or 0, config.sequenceLength or 0, config.delay or 0))
end

-- Configuración equilibrada por dificultad
function MiniGameWindow:getDifficultyConfig(difficulty)
    local configs = {
        ["Easy"] = {
            patterns = EASY_PATTERNS,           -- Solo verde
            sequenceLength = EASY_LENGTH,       -- 4 pasos
            delay = EASY_DELAY,                         -- 2 segundos entre pasos
            displayText = ""
        },
        ["Moderate"] = {
            patterns = MODERATE_PATTERNS,       -- Verde + Rojo
            sequenceLength = MODERATE_LENGTH,   -- 5 pasos
            delay = MODERATE_DELAY,                         -- 1.5 segundos entre pasos
            displayText = ""
        },
        ["Expert"] = {
            patterns = EXPERT_PATTERNS,         -- Verde + Rojo + Azul
            sequenceLength = EXPERT_LENGTH,     -- 6 pasos
            delay = EXPERT_DELAY,                         -- 1.25 segundos entre pasos
            displayText = ""
        }
    }
    
    -- Retornar configuración específica o fallback a Easy
    return configs[difficulty] or configs["Easy"]
end

-- ✅ FUNCIÓN PARA APLICAR XP EN ÉXITO
function MiniGameWindow:applySuccessXP()
    if not self.usbType or not self.difficulty or not self.player then
        print("[MiniGame] Missing parameters for XP calculation")
        return false
    end
    
    -- Usar GVDrive_Utils.applyMinigameResult para XP (ya incluye cálculo de XP)
    if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
        local success = GVDrive_Utils.applyMinigameResult(self.player, self.laptopItem, self.usbType, self.difficulty, true)
        if success then
            print("[SUCCESS] XP granted via GVDrive_Utils.applyMinigameResult")
            return true
        else
            print("[ERROR] GVDrive_Utils.applyMinigameResult returned false")
            return false
        end
    else
        print("[ERROR] GVDrive_Utils.applyMinigameResult not available")
        return false
    end
end

-- ✅ FUNCIÓN PARA APLICAR DAÑO EN FRACASO
function MiniGameWindow:applyFailureDamage()
    if not self.difficulty then
        print("[MiniGame] No difficulty for damage calculation")
        return false
    end
    
    -- Usar GVDrive_Utils.applyMinigameResult para daño (ya incluye cálculo de daño)
    if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
        local success = GVDrive_Utils.applyMinigameResult(self.player, self.laptopItem, self.usbType, self.difficulty, false)
        if success then
            print("[FAILURE] Damage applied via GVDrive_Utils.applyMinigameResult")
            return true
        else
            print("[ERROR] GVDrive_Utils.applyMinigameResult returned false for damage")
            return false
        end
    else
        print("[ERROR] GVDrive_Utils.applyMinigameResult not available for damage")
        return false
    end
end

-- ✅ FUNCIÓN PARA LLENAR GRID PROGRESIVAMENTE CON RESULTADO
function MiniGameWindow:fillGridWithResult(resultText, onComplete)
    local gridRows = tonumber(GRID_ROWS) or 4
    local gridCols = tonumber(GRID_COLS) or 4
    local totalButtons = gridRows * gridCols
    local fillIndex = 0
    
    -- Función recursiva para llenar un botón a la vez
    local function fillNextButton()
        fillIndex = fillIndex + 1
        
        if fillIndex <= totalButtons then
            -- Calcular fila y columna (top-left to bottom-right)
            local row = math.ceil(fillIndex / gridCols)
            local col = ((fillIndex - 1) % gridCols) + 1
            
            if self.sequenceButtons and self.sequenceButtons[row] and self.sequenceButtons[row][col] then
                local btn = self.sequenceButtons[row][col]
                if btn then
                    -- Establecer color y texto según resultado
                    if resultText == "OK" then
                        btn.backgroundColor = {r=0, g=1, b=0, a=1} -- Verde para éxito
                    else
                        btn.backgroundColor = {r=1, g=0, b=0, a=1} -- Rojo para error
                    end
                    btn:setTitle(resultText)
                    
                    -- Programar siguiente botón en 0.1 segundos (2 ticks)
                    SimpleTimer:addTimer(2, fillNextButton)
                else
                    -- Botón no existe, continuar
                    fillNextButton()
                end
            else
                -- Botón no existe, continuar
                fillNextButton()
            end
        else
            -- Grid completado, ejecutar callback si existe
            if onComplete and type(onComplete) == 'function' then
                onComplete()
            end
        end
    end
    
    -- Iniciar el llenado
    fillNextButton()
end

-- ✅ FUNCIÓN PARA PROCESAR RESULTADO FINAL (PIPELINE)
function MiniGameWindow:processFinalResult(success)
    -- ✅ GUARD: Evitar doble procesamiento
    if self.resultProcessed then
        print("[MiniGame] Result already processed, skipping")
        return
    end
    self.resultProcessed = true
    
    print(string.format("[MiniGame] Processing final result: %s", success and "SUCCESS" or "FAILURE"))
    
    -- 1. ADD XP or DMG LAPTOP
    if success then
        self:applySuccessXP()
        if self.player then
            self.player:Say("Experience gained from " .. self.usbType .. " decryption!")
        end
    else
        self:applyFailureDamage()
        if self.player then
            self.player:Say("Laptop damaged from failed " .. self.usbType .. " decryption!")
        end
    end
    
    -- 2. EMPTY PIPE (reservado para futuras actualizaciones)
    -- Aquí se pueden agregar efectos adicionales en el futuro
    
    -- 3. RESET BUG PREVENTION
    self:resetForNextGame()
    
    -- 4. FILL GRID con resultado
    local resultText = success and "OK" or "ERR"
    self:fillGridWithResult(resultText, function()
    -- 5. WAIT 3 seconds and CLOSE
    SimpleTimer:addTimer(AUTO_CLOSE_DELAY, function() -- 60 ticks = 3 segundos
        self:onClose()
    end)
    end)
end

-- ✅ FUNCIÓN PARA RESET PARA EVITAR BUGS EN SIGUIENTE USB
function MiniGameWindow:resetForNextGame()
    -- Limpiar todas las secuencias
    self.greenSequence = nil
    self.redSequence = nil
    self.blueSequence = nil
    self.sequence = {}
    self.userInput = {}
    self.currentIndex = 1
    self.playing = false
    self.typingIndex = 0
    
    -- Limpiar timers activos
    self:clearAllTimers()
    
    -- ✅ RESET FLAG PARA PERMITIR NUEVO PROCESAMIENTO
    self.resultProcessed = false
    
    print("[MiniGame] Reset completed for next game prevention")
end

-- No override de onMouseUp: dejar comportamiento por defecto para que el dragging se libere correctamente

function MiniGameWindow:createChildren()
    -- ✅ ESCALADO ADAPTATIVO PARA BOTONES (de MiniGameFallout.lua)
    local paddingHorizontal = tonumber(PADDING_HORIZONTAL) or 40
    local paddingVertical = tonumber(PADDING_VERTICAL) or 60
    local availableWidth = math.max(100, self.width - paddingHorizontal * 2)
    local availableHeight = math.max(100, self.height - paddingVertical)
    
    local buttonSpacing = tonumber(BUTTON_SPACING_FALLBACK) or 10
    local gridRows = tonumber(GRID_ROWS) or 4
    local gridCols = tonumber(GRID_COLS) or 4
    local maxButtonSizeByWidth = math.floor((availableWidth - (gridCols - 1) * buttonSpacing) / gridCols)
    local maxButtonSizeByHeight = math.floor(availableHeight / gridRows)
    
    local minButtonSize = tonumber(MIN_BUTTON_SIZE) or 20
    local maxButtonSize = tonumber(MAX_BUTTON_SIZE) or 40
    local buttonSize = math.max(minButtonSize, math.min(maxButtonSize, math.min(maxButtonSizeByWidth, maxButtonSizeByHeight)))
    local configuredMinSize = tonumber(BUTTON_SIZE_FALLBACK) or 30
    buttonSize = math.max(buttonSize, math.min(configuredMinSize, maxButtonSize))

    -- ✅ BOTÓN DE CIERRE
    self.closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    -- ✅ CREAR GRID DE BOTONES CENTRADO
    self.sequenceButtons = {}
    local gridWidth = gridCols * buttonSize + (gridCols - 1) * buttonSpacing
    local gridHeight = gridRows * buttonSize + (gridRows - 1) * buttonSpacing
    local gridStartX = (self.width - gridWidth) / 2
    local gridStartY = 80  -- Espacio para título
    
    for row = 1, gridRows do
        self.sequenceButtons[row] = {}
        for col = 1, gridCols do
            local btnIndex = (row - 1) * gridCols + col
            local x = gridStartX + (col - 1) * (buttonSize + buttonSpacing)
            local y = gridStartY + (row - 1) * (buttonSize + buttonSpacing)
            local btn = ISButton:new(x, y, buttonSize, buttonSize, "", self, self.onSequencePress)
            btn.sequenceIndex = btnIndex
            btn.gridRow = row
            btn.gridCol = col
            btn:initialise()
            btn:setVisible(false)  -- ✅ INICIALMENTE INVISIBLE PARA ANIMACIÓN
            self:addChild(btn)
            self.sequenceButtons[row][col] = btn
        end
    end

    -- ✅ BOTÓN START ABAJO DEL GRID, CENTRADO (formato restaurado)
    local startButtonY = gridStartY + gridHeight + 20  -- 20px padding después del grid
    local startButtonX = (self.width - 100) / 2        -- Centrado horizontalmente
    self.startButton = ISButton:new(startButtonX, startButtonY, 100, 30, "START", self, self.onStart)
    self.startButton:initialise()
    self:addChild(self.startButton)

    -- ✅ BOTÓN RESET REMOVIDO - Ya no se necesita según requerimientos del usuario
end

function MiniGameWindow:updateLayout()
    -- VALIDACIÓN ROBUSTA: asegurarse de que todas las variables sean números válidos
    local gridRows = tonumber(GRID_ROWS) or 4
    local gridCols = tonumber(GRID_COLS) or 4
    local buttonSpacing = tonumber(BUTTON_SPACING) or 10
    local buttonSize = tonumber(BUTTON_SIZE) or 15

    -- Asegurar valores mínimos y máximos seguros
    gridRows = math.max(1, math.min(10, gridRows))
    gridCols = math.max(1, math.min(10, gridCols))
    buttonSpacing = math.max(0, math.min(50, buttonSpacing))
    buttonSize = math.max(10, math.min(100, buttonSize))

    -- Layout for GRID_ROWS x GRID_COLS grid - ESPACIADO CONFIGURABLE
    local gridStartX = 20
    local gridStartY = 100  -- ← Aumentado para dar espacio al título
    local availableWidth = math.max(100, self.width - 40)
    local availableHeight = math.max(100, self.height - 140)

    local btnW = math.max(buttonSize, math.floor(availableWidth / gridCols) - buttonSpacing)
    local btnH = math.max(buttonSize, math.floor(availableHeight / gridRows) - buttonSpacing)

    local gridWidth = btnW * gridCols + (gridCols - 1) * buttonSpacing
    local gridHeight = btnH * gridRows + (gridRows - 1) * buttonSpacing

    -- Check if grid fits; if not, reduce button size
    if gridWidth > availableWidth then
        btnW = math.max(buttonSize, math.floor((availableWidth - (gridCols - 1) * buttonSpacing) / gridCols))
        gridWidth = btnW * gridCols + (gridCols - 1) * buttonSpacing
    end
    if gridHeight > availableHeight then
        btnH = math.max(buttonSize, math.floor((availableHeight - (gridRows - 1) * buttonSpacing) / gridRows))
        gridHeight = btnH * gridRows + (gridRows - 1) * buttonSpacing
    end

    -- Center the grid
    gridStartX = math.max(10, (self.width - gridWidth) / 2)

    -- Update sequence button positions and sizes
    for row = 1, gridRows do
        for col = 1, gridCols do
            local btn = self.sequenceButtons[row][col]
            if btn then
                local x = gridStartX + (col - 1) * (btnW + buttonSpacing)
                local y = gridStartY + (row - 1) * (btnH + buttonSpacing)
                btn:setX(x)
                btn:setY(y)
                btn:setWidth(btnW)
                btn:setHeight(btnH)
            end
        end
    end

    -- Update control buttons - POSICIONAMIENTO MEJORADO
    if self.closeButton then
        self.closeButton:setX(math.max(10, self.width - 25))
    end

    local btnWidth = math.max(80, math.floor((self.width - 40) / 2) - 10)
    if self.startButton then
        self.startButton:setWidth(btnWidth)
        -- ✅ MANTENER BOTÓN START CENTRADO ABAJO DEL GRID
        local startButtonX = (self.width - btnWidth) / 2
        self.startButton:setX(startButtonX)
        self.startButton:setY(65)
    end
    -- Reset button removed - no longer needed
end

function MiniGameWindow:onResize(newW, newH)
    self:updateLayout()
end

function MiniGameWindow:processFinalResult(success)
    -- ✅ INTEGRACIÓN USB SEGURA
    if self.usbType and self.difficulty and self.laptopItem then
        if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
            local result = GVDrive_Utils.applyMinigameResult(self.player, self.laptopItem, self.usbType, self.difficulty, success)
            if success then
                if self.player then self.player:Say("Perfect! Sequence completed! Experience gained!") end
            else
                if self.player then self.player:Say("Wrong sequence! Laptop damaged!") end
            end
        else
            print("[ERROR] GVDrive_Utils not available for result application")
            if self.player then
                self.player:Say(success and "Sequence completed!" or "Wrong sequence!")
            end
        end
    else
        print("[WARNING] Missing USB parameters for result application")
        if self.player then
            self.player:Say(success and "Sequence completed!" or "Wrong sequence!")
        end
    end
end

function MiniGameWindow:onClose()
    -- ✅ VERIFICACIÓN CRÍTICA: Si el minijuego está en progreso al cerrar, contar como FAILURE
    if self.playing or (self.sequence and #self.sequence > 0) then
        print("[CLOSE FAILURE] Sequence minigame closed while in progress - treating as failure")

        -- ✅ CONSUMIR USB DEL INVENTARIO (cierre = fracaso)
        if self.usbData and self.usbData.item then
            local inventory = self.player and self.player:getInventory()
            if inventory and inventory:contains(self.usbData.item) then
                inventory:Remove(self.usbData.item)
                print("[CLOSE FAILURE] USB consumed from inventory due to early closure: " .. tostring(self.usbData.displayName))
            else
                print("[WARNING] USB not found in inventory for consumption on close")
            end
        end

        -- ✅ INTEGRACIÓN USB: Aplicar resultado del minijuego (FRACASO por cierre)
        if self.usbType and self.difficulty and self.laptopItem then
            -- Verificar que GVDrive_Utils esté disponible
            if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
                local success = GVDrive_Utils.applyMinigameResult(self.player, self.laptopItem, self.usbType, self.difficulty, false)
                if not success then
                    self.player:Say("Laptop damaged from interrupted " .. self.usbType .. " decryption!")
                end
            else
                print("[ERROR] GVDrive_Utils not available for damage calculation on close")
                self.player:Say("Decryption interrupted, but damage system unavailable.")
            end
        end

        -- Mensaje al jugador sobre el cierre prematuro
        if self.player then
            self.player:Say("Decryption sequence interrupted! You gave up too early.")
        end
    else
        print("[DEBUG] Minigame closed without consuming USB - not in progress")
    end

    -- Cerrar la ventana normalmente
    self:setVisible(false)
    self:removeFromUIManager()
end

-- ========== ANIMACIÓN DE REVELACIÓN DEL GRID ==========
-- Sistema ultra fiable de revelación secuencial 1:1

function MiniGameWindow:startGridRevealAnimation()
    print("[MiniGame] Starting grid reveal animation...")

    -- Reset estado de animación
    self.gridRevealed = false
    self.revealIndex = 0

    -- Iniciar revelación del primer botón
    self:revealNextButton()
end

function MiniGameWindow:revealNextButton()
    self.revealIndex = self.revealIndex + 1

    if self.revealIndex > self.totalButtons then
        -- Animación completa
        self.gridRevealed = true
        print("[MiniGame] Grid reveal animation complete!")
        return
    end

    -- Calcular fila y columna del botón actual (izquierda a derecha, arriba a abajo)
    local row = math.ceil(self.revealIndex / GRID_COLS)
    local col = ((self.revealIndex - 1) % GRID_COLS) + 1

    -- Revelar botón con efecto
    local button = self.sequenceButtons[row] and self.sequenceButtons[row][col]
    if button then
        self:revealButton(button)
    end

    -- Programar siguiente revelación (muy rápido pero smooth: 3-5 frames)
    SimpleTimer:addTimer(3 + ZombRand(0, 3), function()  -- 0.15-0.3 segundos
        self:revealNextButton()
    end)
end

function MiniGameWindow:revealButton(button)
    if not button then return end

    -- Hacer visible
    button:setVisible(true)

    -- Efecto de "aparición" con flash rápido estilo CRT
    local revealColor = {r=1, g=1, b=1, a=1}  -- Blanco brillante
    self:setSafeButtonColor(button, revealColor)

    -- Restaurar a color normal después de flash
    SimpleTimer:addTimer(8, function()  -- 0.4 segundos
        if button then
            self:setSafeButtonColor(button, nil)  -- Color por defecto
        end
    end)
end

-- ========== FUNCIONES DE UTILIDAD PARA COLORES ==========
-- Función segura para establecer colores de botones

function MiniGameWindow:setSafeButtonColor(button, color)
    -- VALIDACIÓN ULTRA SEGURA: nunca usar nil en colores
    if button and color and type(color) == 'table' then
        button.backgroundColor = {
            r = tonumber(color.r) or 0.5,
            g = tonumber(color.g) or 0.5,
            b = tonumber(color.b) or 0.5,
            a = tonumber(color.a) or 1
        }
    elseif button then
        button.backgroundColor = {r=0.5, g=0.5, b=0.5, a=0}
    end
end

function MiniGameWindow:onStart()
    -- Limpiar timers anteriores
    self:clearAllTimers()
    
    -- ✅ RESET ANIMACIÓN DE TIPEO
    self.typingIndex = 0
    
    -- VALIDACIÓN ROBUSTA: usar valores seguros
    local gridRows = tonumber(GRID_ROWS) or 4
    local gridCols = tonumber(GRID_COLS) or 4
    local seqLength = tonumber(SEQUENCE_LENGTH) or 5
    local difficultyPatterns = tonumber(DIFFICULTY_PATTERNS) or 1
    
    -- Asegurar valores mínimos
    gridRows = math.max(1, gridRows)
    gridCols = math.max(1, gridCols)
    seqLength = math.max(1, seqLength)
    difficultyPatterns = math.max(1, math.min(3, difficultyPatterns))
    
    -- Generate random sequences - MÚLTIPLES PATRONES SEGÚN DIFICULTAD
    local totalButtons = gridRows * gridCols
    
    -- Generar secuencia VERDE (correcta)
    self.greenSequence = {}
    for i = 1, seqLength do
        local randomBtn = ZombRand(1, totalButtons + 1)
        table.insert(self.greenSequence, randomBtn)
    end
    
    -- Generar secuencias adicionales según dificultad
    self.redSequence = {}
    self.blueSequence = {}
    
    if difficultyPatterns >= 2 then
        -- Generar secuencia ROJA (distractor)
        for i = 1, seqLength do
            local randomBtn = ZombRand(1, totalButtons + 1)
            table.insert(self.redSequence, randomBtn)
        end
    end
    
    if difficultyPatterns >= 3 then
        -- Generar secuencia AZUL (distractor)
        for i = 1, seqLength do
            local randomBtn = ZombRand(1, totalButtons + 1)
            table.insert(self.blueSequence, randomBtn)
        end
    end
    
    -- La secuencia correcta es siempre la VERDE
    self.sequence = self.greenSequence
    self.currentIndex = 1
    self.playing = true
    self.userInput = {}
    
    if self.player then
        if difficultyPatterns == 1 then
            self.player:Say("Sequence started - watch carefully!")
        else
            self.player:Say("Multiple patterns! Follow the GREEN one only!")
        end
    end
    
    -- Start showing sequences
    self:showMultipleSequences()
end

function MiniGameWindow:showMultipleSequences()
    -- VALIDACIÓN ROBUSTA: verificar estado
    if not self.greenSequence or #self.greenSequence == 0 then
        print("MiniGame: No green sequence to show")
        return
    end
    
    if not self.currentIndex or self.currentIndex < 1 then
        self.currentIndex = 1
    end
    
    if self.currentIndex <= #self.greenSequence then
        local difficultyPatterns = tonumber(DIFFICULTY_PATTERNS) or 1
        
        -- Mostrar patrón VERDE (correcto)
        local greenBtnIndex = self.greenSequence[self.currentIndex]
        self:flashButtonWithColor(greenBtnIndex, {r=0.2, g=1, b=0.2, a=1}) -- Verde brillante
        
        -- Mostrar patrones distractores según dificultad
        if difficultyPatterns >= 2 and self.redSequence and #self.redSequence >= self.currentIndex then
            local redBtnIndex = self.redSequence[self.currentIndex]
            -- Delay ligeramente el patrón rojo para no confundir
            SimpleTimer:addTimer(5, function()
                self:flashButtonWithColor(redBtnIndex, {r=1, g=0.2, b=0.2, a=1}) -- Rojo brillante
            end)
        end
        
        if difficultyPatterns >= 3 and self.blueSequence and #self.blueSequence >= self.currentIndex then
            local blueBtnIndex = self.blueSequence[self.currentIndex]
            -- Delay aún más el patrón azul
            SimpleTimer:addTimer(10, function()
                self:flashButtonWithColor(blueBtnIndex, {r=0.2, g=0.2, b=1, a=1}) -- Azul brillante
            end)
        end
        
        -- Schedule next step
        local nextIndex = self.currentIndex + 1
        SimpleTimer:addTimer(SEQUENCE_DELAY, function()
            self.currentIndex = nextIndex
            self:showMultipleSequences()
        end)
    else
        -- Sequences shown, now wait for user input
        self.currentIndex = 1
        if self.player then
            self.player:Say("Now repeat the GREEN sequence only!")
        end
    end
end

function MiniGameWindow:flashButtonWithColor(btnIndex, color)
    -- VALIDACIÓN ROBUSTA: verificar parámetros
    if not btnIndex or type(btnIndex) ~= 'number' or btnIndex < 1 then
        print("MiniGame: Invalid btnIndex:", btnIndex)
        return
    end
    
    if not color or type(color) ~= 'table' then
        print("MiniGame: Invalid color")
        return
    end
    
    -- Usar valores seguros para grid
    local gridRows = tonumber(GRID_ROWS) or 4
    local gridCols = tonumber(GRID_COLS) or 4
    gridRows = math.max(1, gridRows)
    gridCols = math.max(1, gridCols)
    
    -- Convertir índice lineal a coordenadas de grid
    local row = math.ceil(btnIndex / gridCols)
    local col = ((btnIndex - 1) % gridCols) + 1
    
    -- Verificar que el botón existe
    if row > gridRows or col > gridCols or not self.sequenceButtons or 
       not self.sequenceButtons[row] or not self.sequenceButtons[row][col] then
        print("MiniGame: Button not found at row:", row, "col:", col)
        return
    end
    
    local btn = self.sequenceButtons[row][col]
    if not btn then
        print("MiniGame: Button is nil")
        return
    end
    
    -- Guardar color original de forma segura
    local origBg = btn.backgroundColor
    
    -- Flash con el color especificado
    btn.backgroundColor = {r=color.r, g=color.g, b=color.b, a=color.a}
    
    -- Restaurar color usando sistema de timers ultra simple
    SimpleTimer:addTimer(15, function()  -- 0.75 seconds
        if btn then  -- Verificar que el botón aún existe
            if origBg and type(origBg) == 'table' then
                -- Restaurar color original con validación
                local r = tonumber(origBg.r) or 0.5
                local g = tonumber(origBg.g) or 0.5
                local b = tonumber(origBg.b) or 0.5
                local a = tonumber(origBg.a) or 1
                btn.backgroundColor = {r=r, g=g, b=b, a=a}
            else
                -- Color transparente en lugar de nil
                btn.backgroundColor = {r=0.5, g=0.5, b=0.5, a=0}
            end
        end
    end)
    
    -- Play sound de forma ULTRA SEGURA
    local success = false
    if self.player and type(self.player) == 'table' then
        if self.player.getCurrentSquare and type(self.player.getCurrentSquare) == 'function' then
            local square = self.player:getCurrentSquare()
            if square then
                local soundManager = getSoundManager()
                if soundManager and type(soundManager) == 'table' then
                    if soundManager.playWorldSound and type(soundManager.playWorldSound) == 'function' then
                        local status, err = pcall(function()
                            soundManager:playWorldSound("ButtonClick", square, 0, 10, 1, false)
                        end)
                        if status then
                            success = true
                        else
                            print("MiniGame: Sound error:", err)
                        end
                    end
                end
            end
        end
    end
    
    -- Si no funcionó el sonido normal, intentar alternativa
    if not success then
        local soundManager = getSoundManager()
        if soundManager and soundManager.playUISound then
            pcall(function()
                soundManager:playUISound("ButtonClick")
            end)
        end
    end
end

function MiniGameWindow:flashButton(btnIndex)
    -- VALIDACIÓN ROBUSTA: verificar parámetros
    if not btnIndex or type(btnIndex) ~= 'number' or btnIndex < 1 then
        print("MiniGame: Invalid btnIndex:", btnIndex)
        return
    end
    
    -- Usar valores seguros para grid
    local gridRows = tonumber(GRID_ROWS) or 4
    local gridCols = tonumber(GRID_COLS) or 4
    gridRows = math.max(1, gridRows)
    gridCols = math.max(1, gridCols)
    
    -- Convertir índice lineal a coordenadas de grid
    local row = math.ceil(btnIndex / gridCols)
    local col = ((btnIndex - 1) % gridCols) + 1
    
    -- Verificar que el botón existe
    if row > gridRows or col > gridCols or not self.sequenceButtons or 
       not self.sequenceButtons[row] or not self.sequenceButtons[row][col] then
        print("MiniGame: Button not found at row:", row, "col:", col)
        return
    end
    
    local btn = self.sequenceButtons[row][col]
    if not btn then
        print("MiniGame: Button is nil")
        return
    end
    
    -- Guardar color original de forma segura
    local origBg = btn.backgroundColor
    
    -- Flash yellow
    btn.backgroundColor = {r=1, g=1, b=0.3, a=1}
    
    -- Restaurar color usando sistema de timers ultra simple
    SimpleTimer:addTimer(10, function()  -- 0.5 seconds
        if btn then  -- Verificar que el botón aún existe
            if origBg and type(origBg) == 'table' then
                -- Restaurar color original con validación
                local r = tonumber(origBg.r) or 0.5
                local g = tonumber(origBg.g) or 0.5
                local b = tonumber(origBg.b) or 0.5
                local a = tonumber(origBg.a) or 1
                btn.backgroundColor = {r=r, g=g, b=b, a=a}
            else
                -- Color transparente en lugar de nil
                btn.backgroundColor = {r=0.5, g=0.5, b=0.5, a=0}
            end
        end
    end)
    
    -- Play sound de forma ULTRA SEGURA - Múltiples verificaciones
    local success = false
    if self.player and type(self.player) == 'table' then
        if self.player.getCurrentSquare and type(self.player.getCurrentSquare) == 'function' then
            local square = self.player:getCurrentSquare()
            if square then
                local soundManager = getSoundManager()
                if soundManager and type(soundManager) == 'table' then
                    if soundManager.playWorldSound and type(soundManager.playWorldSound) == 'function' then
                        -- Usar pcall para máxima seguridad
                        local status, err = pcall(function()
                            soundManager:playWorldSound("ButtonClick", square, 0, 10, 1, false)
                        end)
                        if status then
                            success = true
                        else
                            print("MiniGame: Sound error:", err)
                        end
                    end
                end
            end
        end
    end
    
    -- Si no funcionó el sonido normal, intentar alternativa
    if not success then
        local soundManager = getSoundManager()
        if soundManager and soundManager.playUISound then
            pcall(function()
                soundManager:playUISound("ButtonClick")
            end)
        end
    end
end

function MiniGameWindow:onSequencePress(button)
    if not self.playing then return end
    
    local btnIndex = button.sequenceIndex
    table.insert(self.userInput, btnIndex)
    
    -- Flash button briefly
    self:flashButton(btnIndex)
    
    -- Check if correct
    if btnIndex == self.sequence[self.currentIndex] then
        -- Correct! Mark this button as completed (stay green)
        self:setButtonColor(btnIndex, {r=0.3, g=1, b=0.3, a=1}) -- Verde claro para progreso
        
        self.currentIndex = self.currentIndex + 1
        
        if self.currentIndex > #self.sequence then
            -- Success! Process final result with new pipeline
            self.playing = false
            
            -- ✅ CONSUMIR USB DEL INVENTARIO
            if self.usbData and self.usbData.item then
                local inventory = self.player:getInventory()
                if inventory:contains(self.usbData.item) then
                    inventory:Remove(self.usbData.item)
                    print("[SUCCESS] USB consumed from inventory: " .. tostring(self.usbData.displayName))
                else
                    print("[WARNING] USB not found in inventory for consumption")
                end
            end
            
            -- ✅ PROCESAR RESULTADO FINAL CON NUEVO PIPELINE
            self:processFinalResult(true)
            
            if self.player then
                self.player:Say("Perfect! Sequence completed!")
            end
        end
    else
        -- Failure: Process final result with new pipeline
        self.playing = false
        
        -- ✅ CONSUMIR USB DEL INVENTARIO
        if self.usbData and self.usbData.item then
            local inventory = self.player:getInventory()
            if inventory:contains(self.usbData.item) then
                inventory:Remove(self.usbData.item)
                print("[FAILURE] USB consumed from inventory after failure: " .. tostring(self.usbData.displayName))
            else
                print("[WARNING] USB not found in inventory for consumption after failure")
            end
        end
        
        -- ✅ PROCESAR RESULTADO FINAL CON NUEVO PIPELINE
        self:processFinalResult(false)
        
        if self.player then
            self.player:Say("Wrong! You lost. Resetting for retry.")
        end
    end
end

function MiniGameWindow:onReset()
    -- Limpiar todos los timers activos
    self:clearAllTimers()
    
    -- ✅ RESET ANIMACIÓN DE TIPEO
    self.typingIndex = 0
    
    self.sequence = {}
    self.userInput = {}
    self.currentIndex = 1
    self.playing = false
    
    -- Reset button colors and clear text SAFELY
    self:clearAllButtonColors()
    
    if self.player then
        self.player:Say("Game reset")
    end
end

-- FUNCIÓN SEGURA PARA ESTABLECER COLORES - NUNCA USA nil
function MiniGameWindow:setAllButtonsColorSafe(color, text)
    local gridRows = tonumber(GRID_ROWS) or 4
    local gridCols = tonumber(GRID_COLS) or 4
    gridRows = math.max(1, gridRows)
    gridCols = math.max(1, gridCols)
    
    for row = 1, gridRows do
        for col = 1, gridCols do
            if self.sequenceButtons and self.sequenceButtons[row] and self.sequenceButtons[row][col] then
                local btn = self.sequenceButtons[row][col]
                if btn then
                    -- SIEMPRE establecer un color válido, NUNCA nil
                    if color and type(color) == 'table' then
                        local r = tonumber(color.r) or 0.5
                        local g = tonumber(color.g) or 0.5
                        local b = tonumber(color.b) or 0.5
                        local a = tonumber(color.a) or 1
                        btn.backgroundColor = {r=r, g=g, b=b, a=a}
                    else
                        -- Color por defecto transparente en lugar de nil
                        btn.backgroundColor = {r=0.5, g=0.5, b=0.5, a=0}
                    end
                    
                    -- Establecer texto
                    if text and type(text) == 'string' then
                        btn:setTitle(text)
                    else
                        btn:setTitle("")
                    end
                end
            end
        end
    end
end

-- FUNCIÓN PARA LIMPIAR COLORES DE FORMA SEGURA
function MiniGameWindow:clearAllButtonColors()
    local gridRows = tonumber(GRID_ROWS) or 4
    local gridCols = tonumber(GRID_COLS) or 4
    gridRows = math.max(1, gridRows)
    gridCols = math.max(1, gridCols)
    
    for row = 1, gridRows do
        for col = 1, gridCols do
            if self.sequenceButtons and self.sequenceButtons[row] and self.sequenceButtons[row][col] then
                local btn = self.sequenceButtons[row][col]
                if btn then
                    -- Color transparente en lugar de nil
                    btn.backgroundColor = {r=0.5, g=0.5, b=0.5, a=0}
                    btn:setTitle("")
                end
            end
        end
    end
end

-- FUNCIÓN PARA ESTABLECER COLOR DE UN BOTÓN ESPECÍFICO
function MiniGameWindow:setButtonColor(btnIndex, color)
    local gridRows = tonumber(GRID_ROWS) or 4
    local gridCols = tonumber(GRID_COLS) or 4
    local row = math.ceil(btnIndex / gridCols)
    local col = ((btnIndex - 1) % gridCols) + 1
    
    if self.sequenceButtons and self.sequenceButtons[row] and self.sequenceButtons[row][col] then
        local btn = self.sequenceButtons[row][col]
        if btn and color and type(color) == 'table' then
            local r = tonumber(color.r) or 0.5
            local g = tonumber(color.g) or 0.5
            local b = tonumber(color.b) or 0.5
            local a = tonumber(color.a) or 1
            btn.backgroundColor = {r=r, g=g, b=b, a=a}
        end
    end
end

function MiniGameWindow:setButtonColor(btnIndex, color)
    if type(btnIndex) ~= "number" or btnIndex < 1 then
        return
    end

    local gridRows = tonumber(GRID_ROWS) or 4
    local gridCols = tonumber(GRID_COLS) or 4
    gridRows = math.max(1, gridRows)
    gridCols = math.max(1, gridCols)

    local row = math.ceil(btnIndex / gridCols)
    local col = ((btnIndex - 1) % gridCols) + 1

    if not self.sequenceButtons or not self.sequenceButtons[row] then
        return
    end

    local btn = self.sequenceButtons[row][col]
    if not btn or type(color) ~= "table" then
        return
    end

    local r = tonumber(color.r) or 0.5
    local g = tonumber(color.g) or 0.5
    local b = tonumber(color.b) or 0.5
    local a = tonumber(color.a) or 1
    btn.backgroundColor = {r=r, g=g, b=b, a=a}
end

-- MANTENER LA FUNCIÓN ORIGINAL PARA COMPATIBILIDAD
function MiniGameWindow:setAllButtonsColor(color, text)
    self:setAllButtonsColorSafe(color, text)
end

-- Función global para abrir la ventana (versión integrada con USBs)
function MiniGame(widthPct, heightPct, usbType, difficulty, laptopItem, usbData)
    local player = getPlayer()
    if not player then 
        print("MiniGame: No player found")
        return 
    end

    widthPct = tonumber(widthPct) or WINDOW_WIDTH_PCT
    heightPct = tonumber(heightPct) or WINDOW_HEIGHT_PCT

    if type(widthPct) ~= 'number' or widthPct < 10 or widthPct > 100 then
        widthPct = WINDOW_WIDTH_PCT
    end
    if type(heightPct) ~= 'number' or heightPct < 10 or heightPct > 100 then
        heightPct = WINDOW_HEIGHT_PCT
    end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local width = math.max(350, math.floor(screenW * (widthPct / 100)))
    local height = math.max(300, math.floor(screenH * (heightPct / 100)))
    local x = math.floor((screenW - width) / 2)
    local y = math.floor((screenH - height) / 2)

    -- Crear ventana con integración USB
    local window = MiniGameWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData)
    window:initialise()
    window:addToUIManager()
    window:bringToTop()
    window:setVisible(true)

    -- ✅ INICIAR ANIMACIÓN DE REVELACIÓN DEL GRID
    window:startGridRevealAnimation()

    print(string.format("[MiniGame] Window opened: %dx%d at (%d,%d)", width, height, x, y))
    return window
end

-- ✅ FUNCIÓN DUPLICADA ELIMINADA: Solo mantener la versión integrada con USB
-- La función MiniGame ahora maneja tanto llamadas con USB como sin USB automáticamente

-- Mejorar renderizado: EFECTO CRT VERDE ESTILO ALIEN (de MiniGameFallout.lua)
function MiniGameWindow:render()
    ISPanel.render(self)

    -- EFECTO CRT
    local crtGreen = {r=0, g=0, b=0, a=0.3}
    self:drawRect(0, 0, self.width, self.height, crtGreen.a, crtGreen.r, crtGreen.g, crtGreen.b)
    
    for y = 0, self.height, 4 do
        self:drawRect(0, y, self.width, 1, 0.1, 0, 0.3, 0)
    end
    
    local borderGreen = {r=0.2, g=1, b=0.2, a=1}
    self:drawRectBorder(0, 0, self.width, self.height, borderGreen.a, borderGreen.r, borderGreen.g, borderGreen.b)
    self:drawRectBorder(1, 1, self.width-2, self.height-2, borderGreen.a * 0.5, borderGreen.r, borderGreen.g, borderGreen.b)

    -- TÍTULO
    local titleText = "SEQUENCE TERMINAL"
    local titleWidth = 190
    local textManager = getTextManager()
    if textManager and textManager.MeasureStringX then
        local success, width = pcall(function()
            return textManager:MeasureStringX(UIFont.Large, titleText)
        end)
        if success and width then titleWidth = width end
    end
    local titleX = (self.width - titleWidth) / 2
    self:drawText(titleText, titleX + 1, 11, 0.1, 0.5, 0.1, 0.8, UIFont.Large)
    self:drawText(titleText, titleX, 10, 0.2, 1, 0.2, 1, UIFont.Large)

    -- Dificultad
    local diffText = DIFFICULTY_TEXT or "DIFFICULTY: BASIC"
    local diffWidth = 180
    if textManager and textManager.MeasureStringX then
        local success, width = pcall(function()
            return textManager:MeasureStringX(UIFont.Small, diffText)
        end)
        if success and width then diffWidth = width end
    end
    local diffX = (self.width - diffWidth) / 2
    self:drawText(diffText, diffX, 35, 0.2, 0.8, 0.2, 0.9, UIFont.Small)

    -- Línea de estado en la parte inferior
    local statusText
    if self.playing then
        -- ✅ MOSTRAR PROGRESO INMEDIATAMENTE AL PRESIONAR START
        statusText = "PROGRESS: " .. (self.currentIndex - 1) .. "/" .. #self.sequence
    elseif not self.playing and self.sequence and #self.sequence > 0 then
        statusText = "SEQUENCE ANALYSIS COMPLETE"
    else
        -- ✅ ANIMACIÓN DE TIPEO PARA "SYSTEM READY"
        local fullText = "SYSTEM READY"
        self.typingIndex = (self.typingIndex or 0) + 1
        local charsToShow = math.floor(self.typingIndex / 3)  -- Velocidad de tipeo
        statusText = string.sub(fullText, 1, charsToShow)
        if charsToShow < #fullText then
            statusText = statusText .. "_"  -- Cursor parpadeante
        end
        if charsToShow >= #fullText then
            self.typingIndex = #fullText * 3  -- Detener animación
        end
    end
    
    -- VALIDACIÓN ULTRA SEGURA para getTextManager en estado - CORREGIDA
    local statusWidth = 140 -- Valor por defecto más realista
    local textManager = getTextManager()
    if textManager and textManager.MeasureStringX then
        local success, width = pcall(function()
            return textManager:MeasureStringX(UIFont.Small, statusText)
        end)
        if success and width and type(width) == "number" then
            statusWidth = width
        end
    end
    local statusX = (self.width - statusWidth) / 2
    
    -- Efecto de parpadeo en el estado - VALIDACIÓN ULTRA SEGURA
    local blinkAlpha = 0.8 -- Valor por defecto
    if os and os.clock then
        local success, time = pcall(os.clock)
        if success and time and type(time) == 'number' and time > 0 then
            blinkAlpha = 0.5 + 0.5 * math.sin(time * 4)
        end
    end
    self:drawText(statusText, statusX, self.height - 35, 0.2, 1, 0.2, blinkAlpha, UIFont.Small)
end