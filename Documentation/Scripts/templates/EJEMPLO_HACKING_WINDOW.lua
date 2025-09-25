-- ============================================================================
-- EJEMPLO PRÁCTICO: VENTANA DE HACKING EN 2 MINUTOS
-- Versión: 1.0 - Implementación ultra rápida
-- Fecha: 2025-09-24
-- Basado en: TEMPLATE_VENTANA_DINAMICA_CODIGO.lua
-- ============================================================================

print("[HackingWindow] Loading HackingWindow.lua")

-- ========== CONFIGURACIÓN ULTRA RÁPIDA ==========
local GRID_ROWS = 3           -- 3x3 grid para hacking
local GRID_COLS = 3
local SEQUENCE_LENGTH = 4     -- Secuencia de 4 pasos
local WINDOW_WIDTH_PCT = 30   -- Más grande para mejor UX
local WINDOW_HEIGHT_PCT = 40

-- ========== CLASE PRINCIPAL ==========
local HackingWindow = ISPanel:derive("HackingWindow")

-- ========== CONSTRUCTOR ==========
function HackingWindow:new(x, y, width, height, player, targetDevice, difficulty)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    -- PROPIEDADES ESTÉTICAS
    o.backgroundColor = {r=0.05, g=0.05, b=0.2, a=0.9}  -- Azul oscuro
    o.borderColor = {r=0.2, g=0.5, b=1, a=1}            -- Azul brillante
    o.moveWithMouse = true

    -- PARÁMETROS DE INTEGRACIÓN
    o.player = player
    o.targetDevice = targetDevice or "Unknown Device"
    o.difficulty = difficulty or 1

    -- ESTADO DEL JUEGO
    o.gameState = "idle"
    o.currentStep = 0
    o.maxSteps = SEQUENCE_LENGTH
    o.userSequence = {}
    o.targetSequence = {}
    o.hackProgress = 0

    -- ELEMENTOS UI
    o.buttons = {}
    o.closeButton = nil
    o.hackButton = nil

    return o
end

-- ========== CREACIÓN DE ELEMENTOS UI ==========
function HackingWindow:createChildren()
    -- ESCALADO ADAPTATIVO
    local paddingH = 40
    local availableWidth = self.width - paddingH * 2
    local availableHeight = self.height - 90

    -- BOTÓN DE CIERRE
    self.closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    -- CREAR GRID DE BOTONES
    self.buttons = {}
    local gridRows = GRID_ROWS
    local gridCols = GRID_COLS

    local btnSize = math.max(20, math.min(40,
        math.min(availableWidth / gridCols, availableHeight / gridRows) - 10))

    local gridWidth = gridCols * btnSize + (gridCols - 1) * 10
    local gridStartX = (self.width - gridWidth) / 2
    local gridStartY = 80

    for row = 1, gridRows do
        self.buttons[row] = {}
        for col = 1, gridCols do
            local x = gridStartX + (col - 1) * (btnSize + 10)
            local y = gridStartY + (row - 1) * (btnSize + 10)

            local btn = ISButton:new(x, y, btnSize, btnSize, "", self, self.onButtonPress)
            btn.row = row
            btn.col = col
            btn.gridIndex = (row - 1) * gridCols + col
            btn:initialise()
            btn:setVisible(false)  -- ✅ INICIALMENTE INVISIBLE PARA ANIMACIÓN
            self:addChild(btn)
            self.buttons[row][col] = btn
        end
    end

    -- BOTÓN DE HACKING
    local startY = gridStartY + gridRows * (btnSize + 10) + 20
    self.hackButton = ISButton:new((self.width - 120) / 2, startY, 120, 30, "START HACK", self, self.onStartHack)
    self.hackButton:initialise()
    self:addChild(self.hackButton)
end

-- ========== MANEJO DE EVENTOS ==========
function HackingWindow:onClose()
    self:clearAllTimers()
    if self.gameState == "playing" then
        print("[Hacking] Hack interrupted!")
        if self.player then
            self.player:Say("Hack interrupted!")
        end
    end
    self:setVisible(false)
    self:removeFromUIManager()
end

function HackingWindow:onButtonPress(button)
    if self.gameState ~= "playing" then return end

    local row, col = button.row, button.col
    print(string.format("[Hacking] Node accessed: %d,%d", row, col))

    -- Feedback visual azul
    self:flashButton(button, {r=0.2, g=0.5, b=1, a=1})

    self:processHackInput(row, col)
end

function HackingWindow:onStartHack()
    print("[Hacking] Initiating hack sequence...")
    self:resetHack()
    self.gameState = "playing"
    self:startHackSequence()
end

-- ========== LÓGICA DE HACKING ==========
function HackingWindow:resetHack()
    self.gameState = "idle"
    self.currentStep = 0
    self.userSequence = {}
    self.targetSequence = {}
    self.hackProgress = 0
    self:clearAllButtonColors()
    self:clearAllTimers()
end

function HackingWindow:startHackSequence()
    -- Generar secuencia de nodos vulnerables
    self.targetSequence = {}
    for i = 1, SEQUENCE_LENGTH do
        local nodeIndex = ZombRand(1, 10)  -- 3x3 = 9 nodos
        table.insert(self.targetSequence, nodeIndex)
    end

    print("[Hacking] Target nodes:", table.concat(self.targetSequence, " → "))

    -- Mostrar secuencia de vulnerabilidades
    self:showVulnerableNodes(1)
end

function HackingWindow:showVulnerableNodes(step)
    if step > #self.targetSequence then
        print("[Hacking] Vulnerability scan complete")
        self.gameState = "waiting_input"
        return
    end

    local nodeIndex = self.targetSequence[step]
    self:flashButtonByIndex(nodeIndex, {r=1, g=0.5, b=0, a=1})  -- Amarillo para vulnerable

    -- Siguiente vulnerabilidad
    SimpleTimer:addTimer(45, function()  -- 2.25 segundos
        self:showVulnerableNodes(step + 1)
    end)
end

function HackingWindow:processHackInput(row, col)
    local nodeIndex = (row - 1) * GRID_COLS + col
    table.insert(self.userSequence, nodeIndex)

    print(string.format("[Hacking] Accessing node %d (step %d/%d)",
        nodeIndex, #self.userSequence, #self.targetSequence))

    local expectedNode = self.targetSequence[#self.userSequence]

    if nodeIndex == expectedNode then
        print("[Hacking] Node exploited successfully!")
        self:setButtonColorByIndex(nodeIndex, {r=0, g=1, b=0, a=1})  -- Verde éxito
        self.hackProgress = self.hackProgress + (100 / SEQUENCE_LENGTH)

        if #self.userSequence >= #self.targetSequence then
            self:hackSuccess()
        end
    else
        print("[Hacking] Security alert triggered!")
        self:setButtonColorByIndex(nodeIndex, {r=1, g=0, b=0, a=1})  -- Rojo error
        self:hackFailure()
    end
end

function HackingWindow:hackSuccess()
    print("[Hacking] HACK SUCCESSFUL!")

    self.gameState = "success"

    if self.player then
        self.player:Say("Access granted! " .. self.targetDevice .. " compromised!")

        -- Otorgar XP por hacking exitoso
        if _G.GVDrive_Utils and _G.GVDrive_Utils.applyMinigameResult then
            _G.GVDrive_Utils.applyMinigameResult(self.player, true, "hacking", self.difficulty)
        end
    end

    -- Cerrar después de 3 segundos
    SimpleTimer:addTimer(60, function()
        self:onClose()
    end)
end

function HackingWindow:hackFailure()
    print("[Hacking] HACK FAILED!")

    self.gameState = "failure"

    if self.player then
        self.player:Say("Hack failed! Security systems alerted!")

        -- Aplicar daño por fallo
        if _G.GVDrive_Utils and _G.GVDrive_Utils.applyMinigameResult then
            _G.GVDrive_Utils.applyMinigameResult(self.player, false, "hacking", self.difficulty)
        end
    end

    -- Reset después de 3 segundos
    SimpleTimer:addTimer(60, function()
        self:resetHack()
    end)
end

-- ========== FUNCIONES DE UTILIDAD ==========
function HackingWindow:flashButton(button, color)
    if not button then return end

    local origColor = button.backgroundColor
    self:setSafeButtonColor(button, color)

    SimpleTimer:addTimer(15, function()
        if button then
            self:setSafeButtonColor(button, origColor)
        end
    end)
end

function HackingWindow:flashButtonByIndex(btnIndex, color)
    local row = math.ceil(btnIndex / GRID_COLS)
    local col = ((btnIndex - 1) % GRID_COLS) + 1

    local button = self.buttons[row] and self.buttons[row][col]
    if button then
        self:flashButton(button, color)
    end
end

function HackingWindow:setButtonColorByIndex(btnIndex, color)
    local row = math.ceil(btnIndex / GRID_COLS)
    local col = ((btnIndex - 1) % GRID_COLS) + 1

    local button = self.buttons[row] and self.buttons[row][col]
    if button then
        self:setSafeButtonColor(button, color)
    end
end

function HackingWindow:setSafeButtonColor(button, color)
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

function HackingWindow:clearAllButtonColors()
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

function HackingWindow:clearAllTimers()
    -- SimpleTimer se auto-limpia
end

-- ========== ANIMACIÓN DE REVELACIÓN DEL GRID ==========
function HackingWindow:startGridRevealAnimation()
    print("[Hacking] Starting grid reveal animation...")

    self.gridRevealed = false
    self.revealIndex = 0

    self:revealNextButton()
end

function HackingWindow:revealNextButton()
    self.revealIndex = self.revealIndex + 1

    if self.revealIndex > self.totalButtons then
        self.gridRevealed = true
        print("[Hacking] Grid reveal animation complete!")
        return
    end

    local row = math.ceil(self.revealIndex / GRID_COLS)
    local col = ((self.revealIndex - 1) % GRID_COLS) + 1

    local button = self.buttons[row] and self.buttons[row][col]
    if button then
        self:revealButton(button)
    end

    SimpleTimer:addTimer(3 + ZombRand(0, 3), function()
        self:revealNextButton()
    end)
end

function HackingWindow:revealButton(button)
    if not button then return end

    button:setVisible(true)

    -- Efecto de revelación azul (tema hacking)
    local revealColor = {r=0.2, g=0.5, b=1, a=1}  -- Azul brillante
    self:setSafeButtonColor(button, revealColor)

    SimpleTimer:addTimer(8, function()
        if button then
            self:setSafeButtonColor(button, nil)
        end
    end)
end

-- ========== RENDERIZADO ==========
function HackingWindow:render()
    ISPanel.render(self)

    -- Efecto azul técnico
    local techColor = {r=0, g=0, b=0, a=0.3}
    self:drawRect(0, 0, self.width, self.height, techColor.a, techColor.r, techColor.g, techColor.b)

    -- Líneas de escaneo
    for y = 0, self.height, 6 do
        self:drawRect(0, y, self.width, 1, 0.1, 0, 0, 0.3)
    end

    -- Borde azul
    local borderColor = {r=0.2, g=0.5, b=1, a=1}
    self:drawRectBorder(0, 0, self.width, self.height, borderColor.a, borderColor.r, borderColor.g, borderColor.b)

    -- Título
    local titleText = "HACKING TERMINAL"
    self:drawTextCentered(titleText, 10, UIFont.Large, {r=0.2, g=0.5, b=1, a=1})

    -- Información del dispositivo
    local deviceText = "Target: " .. (self.targetDevice or "Unknown")
    self:drawTextCentered(deviceText, 35, UIFont.Small, {r=0.5, g=0.8, b=1, a=0.9})

    -- Estado dinámico
    local statusText = self:getStatusText()
    self:drawTextCentered(statusText, self.height - 35, UIFont.Small, {r=0.2, g=0.8, b=1, a=0.9})

    -- Barra de progreso
    if self.gameState == "playing" then
        local progressY = self.height - 20
        local progressWidth = self.width - 40
        local progressHeight = 8

        -- Fondo de barra
        self:drawRect(20, progressY, progressWidth, progressHeight, 0.5, 0.1, 0.1, 0.1)

        -- Progreso
        local progressFill = (self.hackProgress / 100) * progressWidth
        self:drawRect(20, progressY, progressFill, progressHeight, 0.8, 0, 0.5, 1)
    end
end

function HackingWindow:drawTextCentered(text, y, font, color)
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

function HackingWindow:getStatusText()
    if self.gameState == "idle" then
        return "SYSTEM READY - PRESS START HACK"
    elseif self.gameState == "playing" then
        return string.format("ACCESSING NODES: %d/%d", #self.userSequence, self.maxSteps)
    elseif self.gameState == "success" then
        return "ACCESS GRANTED!"
    elseif self.gameState == "failure" then
        return "SECURITY ALERT - RETRYING..."
    else
        return "UNKNOWN STATE"
    end
end

-- ========== FUNCIÓN GLOBAL ==========
function OpenHackingWindow(widthPct, heightPct, targetDevice, difficulty)
    local player = getPlayer()
    if not player then
        print("[Hacking] No player found")
        return
    end

    widthPct = widthPct or WINDOW_WIDTH_PCT
    heightPct = heightPct or WINDOW_HEIGHT_PCT
    widthPct = math.max(10, math.min(100, widthPct))
    heightPct = math.max(10, math.min(100, heightPct))

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local width = math.max(350, math.floor(screenW * (widthPct / 100)))
    local height = math.max(300, math.floor(screenH * (heightPct / 100)))
    local x = math.floor((screenW - width) / 2)
    local y = math.floor((screenH - height) / 2)

    local window = HackingWindow:new(x, y, width, height, player, targetDevice, difficulty)
    window:initialise()
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()

    -- ✅ INICIAR ANIMACIÓN DE REVELACIÓN DEL GRID
    window:startGridRevealAnimation()

    print(string.format("[Hacking] Terminal opened: %dx%d at (%d,%d)", width, height, x, y))
    return window
end

_G.OpenHackingWindow = OpenHackingWindow

-- ========== FUNCIONES DE DEBUG ==========
function ReloadHacking()
    print("[Hacking] Reloading...")
    package.loaded["client/HackingWindow"] = nil

    local success, result = pcall(require, "client/HackingWindow")
    if success then
        print("[Hacking] Reloaded successfully!")
    else
        print("[Hacking] Reload failed:", result)
    end
end

function TestHacking()
    print("[Hacking] Testing...")
    if OpenHackingWindow then
        return OpenHackingWindow(35, 45, "Test Server", 2)
    else
        print("[Hacking] Function not available")
    end
end

print("[Hacking] HackingWindow loaded successfully!")
print("[Hacking] Use OpenHackingWindow(width%, height%, device, difficulty) to test")
print("[Hacking] Use ReloadHacking() to reload during development")