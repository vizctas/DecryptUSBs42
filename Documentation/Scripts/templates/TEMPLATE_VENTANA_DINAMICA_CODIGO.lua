-- ============================================================================
-- TEMPLATE DE VENTANA DINÁMICA - BASE PARA NUEVAS VENTANAS
-- Versión: 2.0 - Ultra Fiable y Modular
-- Fecha: 2025-09-24
-- Basado en: MiniGameUI.lua
-- ============================================================================

print("[Template] Loading DynamicWindowTemplate.lua")

-- ========== [PASO 1] CONFIGURACIÓN GLOBAL ==========
-- Copiar y modificar estas variables según las necesidades de tu ventana

local GRID_ROWS = 4           -- Número de filas del grid
local GRID_COLS = 4           -- Número de columnas del grid
local SEQUENCE_LENGTH = 5     -- Longitud de secuencias/interacciones
local BUTTON_SIZE = 30        -- Tamaño base de botones
local BUTTON_SPACING = 10     -- Espaciado entre botones

-- Configuración de escalado adaptativo
local PADDING_HORIZONTAL = 40   -- Espacio horizontal alrededor
local PADDING_VERTICAL = 90     -- Espacio vertical para título y controles
local MIN_BUTTON_SIZE = 20      -- Tamaño mínimo de botones
local MAX_BUTTON_SIZE = 40      -- Tamaño máximo de botones

-- Configuración de ventana
local WINDOW_WIDTH_PCT = 25     -- Porcentaje del ancho de pantalla
local WINDOW_HEIGHT_PCT = 35    -- Porcentaje del alto de pantalla
local WINDOW_WIDTH = 400        -- Ancho fallback en píxeles
local WINDOW_HEIGHT = 500       -- Alto fallback en píxeles

-- ========== [PASO 2] SISTEMA DE TIMERS ULTRA SIMPLE ==========
-- NO MODIFICAR - Copiar tal cual para todas las ventanas

local SimpleTimer = {}
SimpleTimer.activeTimers = {}
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
            if timer.callback and type(timer.callback) == 'function' then
                local success, err = pcall(timer.callback)
                if not success then
                    print("[SimpleTimer] Callback error:", err)
                end
            end
            toRemove[id] = true
        end
    end

    for id in pairs(toRemove) do
        self.activeTimers[id] = nil
    end
end

-- Registrar el sistema de timers
if Events and Events.OnTick and Events.OnTick.Add then
    Events.OnTick.Add(function() SimpleTimer:update() end)
else
    print("[Template] Events not available - timers disabled")
end

-- ========== [PASO 3] CLASE PRINCIPAL DE VENTANA ==========
-- MODIFICAR: Cambiar "TemplateWindow" por el nombre de tu ventana

local TemplateWindow = ISPanel:derive("TemplateWindow")

-- ========== [PASO 4] CONSTRUCTOR ==========
-- MODIFICAR: Parámetros según las necesidades de tu ventana

function TemplateWindow:new(x, y, width, height, player, customParam1, customParam2)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    -- ✅ PROPIEDADES ESTÉTICAS - MODIFICAR colores según tema
    o.backgroundColor = {r=0.05, g=0.2, b=0.05, a=0.9}  -- Verde CRT
    o.borderColor = {r=0.2, g=1, b=0.2, a=1}            -- Borde verde brillante
    o.moveWithMouse = true

    -- ✅ PARÁMETROS DE INTEGRACIÓN - MODIFICAR según necesidades
    o.player = player
    o.customParam1 = customParam1
    o.customParam2 = customParam2

    -- ✅ ESTADO DEL JUEGO - MODIFICAR variables de estado
    o.gameState = "idle"      -- Estados: "idle", "playing", "success", "failure"
    o.currentStep = 0
    o.maxSteps = SEQUENCE_LENGTH
    o.userSequence = {}
    o.targetSequence = {}

    -- ✅ ELEMENTOS UI - MODIFICAR según componentes necesarios
    o.buttons = {}           -- Grid de botones
    o.closeButton = nil      -- Botón de cierre
    o.startButton = nil      -- Botón principal

    -- ✅ ANIMACIÓN DE REVELACIÓN - NO MODIFICAR
    o.gridRevealed = false   -- Si el grid ya se reveló
    o.revealIndex = 0        -- Índice actual de revelación
    o.totalButtons = GRID_ROWS * GRID_COLS  -- Total de botones a revelar

    return o
end

-- ========== [PASO 5] CREACIÓN DE ELEMENTOS UI ==========
-- MODIFICAR: Adaptar según el tipo de interfaz que necesites

function TemplateWindow:createChildren()
    -- ✅ ESCALADO ADAPTATIVO - NO MODIFICAR
    local paddingH = PADDING_HORIZONTAL
    local availableWidth = self.width - paddingH * 2
    local availableHeight = self.height - PADDING_VERTICAL

    -- ✅ BOTÓN DE CIERRE - NO MODIFICAR
    self.closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    -- ✅ BOTÓN PRINCIPAL - MODIFICAR texto y posición según necesidades
    local startY = gridStartY + gridHeight + 20
    self.startButton = ISButton:new((self.width - 100) / 2, startY, 100, 30, "START", self, self.onStart)
    self.startButton:initialise()
    self:addChild(self.startButton)
end

-- ========== [PASO 6] SISTEMA DE LAYOUT ADAPTATIVO ==========
-- MODIFICAR: Solo si necesitas layout personalizado

function TemplateWindow:updateLayout()
    -- VALIDACIÓN ROBUSTA
    local gridRows = math.max(1, GRID_ROWS)
    local gridCols = math.max(1, GRID_COLS)

    -- Recalcular tamaños
    local availableWidth = self.width - PADDING_HORIZONTAL * 2
    local availableHeight = self.height - PADDING_VERTICAL

    local btnW = math.max(MIN_BUTTON_SIZE, availableWidth / gridCols - BUTTON_SPACING)
    local btnH = math.max(MIN_BUTTON_SIZE, availableHeight / gridRows - BUTTON_SPACING)

    btnW = math.min(btnW, MAX_BUTTON_SIZE)
    btnH = math.min(btnH, MAX_BUTTON_SIZE)

    -- Centrar grid
    local gridWidth = btnW * gridCols + (gridCols - 1) * BUTTON_SPACING
    local gridStartX = (self.width - gridWidth) / 2

    -- Actualizar posiciones de botones
    for row = 1, gridRows do
        for col = 1, gridCols do
            local btn = self.buttons[row] and self.buttons[row][col]
            if btn then
                local x = gridStartX + (col - 1) * (btnW + BUTTON_SPACING)
                local y = 80 + (row - 1) * (btnH + BUTTON_SPACING)
                btn:setX(x)
                btn:setY(y)
                btn:setWidth(btnW)
                btn:setHeight(btnH)
            end
        end
    end

    -- Actualizar botón de cierre
    if self.closeButton then
        self.closeButton:setX(self.width - 25)
    end

    -- Actualizar botón start - MODIFICAR según necesidades
    if self.startButton then
        self.startButton:setX((self.width - 100) / 2)
    end
end

function TemplateWindow:onResize(newW, newH)
    self:updateLayout()
end

-- ========== [PASO 7] MANEJO DE EVENTOS ==========
-- MODIFICAR: Implementar la lógica específica de tu ventana

function TemplateWindow:onClose()
    -- ✅ LIMPIEZA OBLIGATORIA
    self:clearAllTimers()

    -- ✅ LÓGICA ESPECÍFICA - MODIFICAR según necesidades
    if self.gameState == "playing" then
        print("[Template] Window closed during gameplay")
        -- Aplicar penalización si es necesario
    end

    -- ✅ CERRAR VENTANA - NO MODIFICAR
    self:setVisible(false)
    self:removeFromUIManager()
end

function TemplateWindow:onButtonPress(button)
    -- ✅ VALIDACIÓN BÁSICA - NO MODIFICAR
    if self.gameState ~= "playing" then return end

    -- ✅ LÓGICA ESPECÍFICA - MODIFICAR según necesidades
    local row, col = button.row, button.col
    print(string.format("[Template] Button pressed: row=%d, col=%d", row, col))

    -- Feedback visual
    self:flashButton(button, {r=1, g=1, b=0, a=1})

    -- Procesar input del usuario
    self:processUserInput(row, col)
end

function TemplateWindow:onStart()
    print("[Template] Game starting...")

    -- ✅ RESETEO OBLIGATORIO
    self:resetGame()

    -- ✅ INICIALIZACIÓN - MODIFICAR según necesidades
    self.gameState = "playing"
    self:startGameSequence()
end

-- ========== [PASO 8] FUNCIONES DE JUEGO ==========
-- MODIFICAR: Implementar toda la lógica específica de tu minijuego/ventana

function TemplateWindow:resetGame()
    print("[Template] Resetting game...")

    -- Limpiar estado
    self.gameState = "idle"
    self.currentStep = 0
    self.userSequence = {}
    self.targetSequence = {}

    -- Limpiar UI
    self:clearAllButtonColors()

    -- Limpiar timers
    self:clearAllTimers()
end

function TemplateWindow:startGameSequence()
    print("[Template] Starting game sequence...")

    -- Generar secuencia objetivo
    self.targetSequence = self:generateTargetSequence()

    -- Mostrar secuencia al usuario
    self:showSequenceToUser(1)
end

function TemplateWindow:generateTargetSequence()
    -- MODIFICAR: Lógica para generar la secuencia objetivo
    local sequence = {}
    local totalButtons = GRID_ROWS * GRID_COLS

    for i = 1, SEQUENCE_LENGTH do
        local randomIndex = ZombRand(1, totalButtons + 1)
        table.insert(sequence, randomIndex)
    end

    print("[Template] Generated sequence:", table.concat(sequence, ", "))
    return sequence
end

function TemplateWindow:showSequenceToUser(step)
    -- MODIFICAR: Lógica para mostrar secuencia al usuario
    if step > #self.targetSequence then
        print("[Template] Sequence display complete, waiting for user input")
        self.gameState = "waiting_input"
        return
    end

    local btnIndex = self.targetSequence[step]
    self:flashButtonByIndex(btnIndex, {r=0, g=1, b=0, a=1})  -- Verde para mostrar

    -- Programar siguiente paso
    SimpleTimer:addTimer(30, function()  -- 1.5 segundos
        self:showSequenceToUser(step + 1)
    end)
end

function TemplateWindow:processUserInput(row, col)
    -- MODIFICAR: Lógica para procesar input del usuario
    local btnIndex = (row - 1) * GRID_COLS + col
    table.insert(self.userSequence, btnIndex)

    print(string.format("[Template] User input %d: button %d", #self.userSequence, btnIndex))

    -- Verificar si es correcto
    local expectedIndex = self.userSequence[#self.userSequence]
    local actualIndex = self.targetSequence[#self.userSequence]

    if expectedIndex == actualIndex then
        print("[Template] Correct input!")
        self:setButtonColorByIndex(btnIndex, {r=0, g=1, b=0, a=1})  -- Verde para correcto

        -- Verificar si completó la secuencia
        if #self.userSequence >= #self.targetSequence then
            self:gameSuccess()
        end
    else
        print("[Template] Wrong input!")
        self:setButtonColorByIndex(btnIndex, {r=1, g=0, b=0, a=1})  -- Rojo para error
        self:gameFailure()
    end
end

function TemplateWindow:gameSuccess()
    print("[Template] GAME SUCCESS!")

    self.gameState = "success"

    -- MODIFICAR: Lógica de éxito
    if self.player then
        self.player:Say("Success! Well done!")
    end

    -- Cerrar automáticamente después de 3 segundos
    SimpleTimer:addTimer(60, function()
        self:onClose()
    end)
end

function TemplateWindow:gameFailure()
    print("[Template] GAME FAILURE!")

    self.gameState = "failure"

    -- MODIFICAR: Lógica de fracaso
    if self.player then
        self.player:Say("Failed! Try again!")
    end

    -- Reset después de 2 segundos
    SimpleTimer:addTimer(40, function()
        self:resetGame()
    end)
end

-- ========== FUNCIONES DE UTILIDAD ==========
-- MODIFICAR: Solo si necesitas funciones adicionales

function TemplateWindow:flashButton(button, color)
    -- VALIDACIÓN ULTRA SEGURA
    if not button then return end

    local origColor = button.backgroundColor

    -- Flash con color especificado
    self:setSafeButtonColor(button, color)

    -- Restaurar después de delay
    SimpleTimer:addTimer(15, function()  -- 0.75 segundos
        if button then
            self:setSafeButtonColor(button, origColor)
        end
    end)
end

function TemplateWindow:flashButtonByIndex(btnIndex, color)
    local row = math.ceil(btnIndex / GRID_COLS)
    local col = ((btnIndex - 1) % GRID_COLS) + 1

    local button = self.buttons[row] and self.buttons[row][col]
    if button then
        self:flashButton(button, color)
    end
end

function TemplateWindow:setButtonColorByIndex(btnIndex, color)
    local row = math.ceil(btnIndex / GRID_COLS)
    local col = ((btnIndex - 1) % GRID_COLS) + 1

    local button = self.buttons[row] and self.buttons[row][col]
    if button then
        self:setSafeButtonColor(button, color)
    end
end

function TemplateWindow:setSafeButtonColor(button, color)
    -- NUNCA usar nil en colores
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

function TemplateWindow:clearAllButtonColors()
    for row = 1, GRID_ROWS do
        for col = 1, GRID_COLS do
            local button = self.buttons[row] and self.buttons[row][col]
            if button then
                self:setSafeButtonColor(button, nil)
                button:setTitle("")
            end
        end
    end
end

function TemplateWindow:clearAllTimers()
    -- SimpleTimer se auto-limpia, pero podemos forzar limpieza si es necesario
end

-- ========== ANIMACIÓN DE REVELACIÓN DEL GRID ==========
-- NO MODIFICAR - Sistema ultra fiable de revelación secuencial

function TemplateWindow:startGridRevealAnimation()
    print("[Template] Starting grid reveal animation...")

    -- Reset estado de animación
    self.gridRevealed = false
    self.revealIndex = 0

    -- Iniciar revelación del primer botón
    self:revealNextButton()
end

function TemplateWindow:revealNextButton()
    self.revealIndex = self.revealIndex + 1

    if self.revealIndex > self.totalButtons then
        -- Animación completa
        self.gridRevealed = true
        print("[Template] Grid reveal animation complete!")
        return
    end

    -- Calcular fila y columna del botón actual
    local row = math.ceil(self.revealIndex / GRID_COLS)
    local col = ((self.revealIndex - 1) % GRID_COLS) + 1

    -- Revelar botón con efecto
    local button = self.buttons[row] and self.buttons[row][col]
    if button then
        self:revealButton(button)
    end

    -- Programar siguiente revelación (muy rápido pero smooth: 3-5 frames)
    SimpleTimer:addTimer(3 + ZombRand(0, 3), function()  -- 0.15-0.3 segundos
        self:revealNextButton()
    end)
end

function TemplateWindow:revealButton(button)
    if not button then return end

    -- Hacer visible
    button:setVisible(true)

    -- Efecto de "aparición" con flash rápido
    local revealColor = {r=1, g=1, b=1, a=1}  -- Blanco brillante
    self:setSafeButtonColor(button, revealColor)

    -- Restaurar a color normal después de flash
    SimpleTimer:addTimer(8, function()  -- 0.4 segundos
        if button then
            self:setSafeButtonColor(button, nil)  -- Color por defecto
        end
    end)

    -- Efecto de sonido opcional (si tienes sistema de audio)
    -- self:playRevealSound()
end

-- ========== [PASO 9] RENDERIZADO Y EFECTOS VISUALES ==========
-- MODIFICAR: Personalizar efectos visuales según tema

function TemplateWindow:render()
    ISPanel.render(self)

    -- ✅ EFECTO CRT VERDE - MODIFICAR colores según tema
    local crtColor = {r=0, g=0, b=0, a=0.3}
    self:drawRect(0, 0, self.width, self.height, crtColor.a, crtColor.r, crtColor.g, crtColor.b)

    -- ✅ LÍNEAS DE ESCANEO
    for y = 0, self.height, 4 do
        self:drawRect(0, y, self.width, 1, 0.1, 0, 0.3, 0)
    end

    -- ✅ BORDE
    local borderColor = {r=0.2, g=1, b=0.2, a=1}
    self:drawRectBorder(0, 0, self.width, self.height, borderColor.a, borderColor.r, borderColor.g, borderColor.b)

    -- ✅ TÍTULO - MODIFICAR texto
    local titleText = "TEMPLATE WINDOW"
    self:drawTextCentered(titleText, 10, UIFont.Large, {r=0.2, g=1, b=0.2, a=1})

    -- ✅ ESTADO DINÁMICO - MODIFICAR según estado del juego
    local statusText = self:getStatusText()
    self:drawTextCentered(statusText, self.height - 35, UIFont.Small, {r=0.2, g=0.8, b=0.2, a=0.9})
end

function TemplateWindow:drawTextCentered(text, y, font, color)
    local textManager = getTextManager()
    if not textManager or not textManager.MeasureStringX then return end

    local success, width = pcall(function()
        return textManager:MeasureStringX(font, text)
    end)

    if success and width then
        local x = (self.width - width) / 2
        self:drawText(text, x, y, color.r, color.g, color.b, color.a, font)
    end
end

function TemplateWindow:getStatusText()
    -- MODIFICAR: Texto de estado según lógica del juego
    if self.gameState == "idle" then
        return "SYSTEM READY"
    elseif self.gameState == "playing" then
        return string.format("STEP: %d/%d", self.currentStep, self.maxSteps)
    elseif self.gameState == "success" then
        return "SUCCESS!"
    elseif self.gameState == "failure" then
        return "FAILED - RETRYING..."
    else
        return "UNKNOWN STATE"
    end
end

-- ========== [PASO 10] FUNCIÓN GLOBAL DE APERTURA ==========
-- MODIFICAR: Cambiar nombre de función y parámetros

function OpenTemplateWindow(widthPct, heightPct, customParam1, customParam2)
    local player = getPlayer()
    if not player then
        print("[Template] No player found")
        return
    end

    -- Validación de parámetros
    widthPct = widthPct or WINDOW_WIDTH_PCT
    heightPct = heightPct or WINDOW_HEIGHT_PCT
    widthPct = math.max(10, math.min(100, widthPct))
    heightPct = math.max(10, math.min(100, heightPct))

    -- Calcular dimensiones
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local width = math.max(350, math.floor(screenW * (widthPct / 100)))
    local height = math.max(300, math.floor(screenH * (heightPct / 100)))
    local x = math.floor((screenW - width) / 2)
    local y = math.floor((screenH - height) / 2)

    -- Crear y mostrar ventana
    local window = TemplateWindow:new(x, y, width, height, player, customParam1, customParam2)
    window:initialise()
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()

    -- ✅ INICIAR ANIMACIÓN DE REVELACIÓN DEL GRID
    window:startGridRevealAnimation()

    print(string.format("[Template] Window opened: %dx%d at (%d,%d)", width, height, x, y))
    return window
end

-- ✅ EXPONER GLOBALMENTE - MODIFICAR nombre
_G.OpenTemplateWindow = OpenTemplateWindow

-- ========== FUNCIONES DE DEBUG ==========
-- MODIFICAR: Para testing durante desarrollo

function ReloadTemplate()
    print("[Template] Reloading...")
    package.loaded["client/TemplateWindow"] = nil

    local success, result = pcall(require, "client/TemplateWindow")
    if success then
        print("[Template] Reloaded successfully!")
    else
        print("[Template] Reload failed:", result)
    end
end

function TestTemplate()
    print("[Template] Testing...")
    if OpenTemplateWindow then
        return OpenTemplateWindow(30, 40, "testParam1", "testParam2")
    else
        print("[Template] Function not available")
    end
end

print("[Template] TemplateWindow loaded successfully!")
print("[Template] Use OpenTemplateWindow(width%, height%) to test")
print("[Template] Use ReloadTemplate() to reload during development")</content>
<parameter name="filePath">c:\Users\joshg\Zomboid42\Workshop\DecryptUSBs42\Documentation\Scripts\templates\TEMPLATE_VENTANA_DINAMICA_CODIGO.lua