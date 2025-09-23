-- MiniGameUI.lua - Ventana configurable UI para DecryptSkillSys
-- Basado en patrones del CODEBASE (PATRONES_UI_Y_MINIJUEGOS.md)

-- ========== CONFIGURACIÓN DEL GRID ==========
-- Modifica estas variables para cambiar el tamaño del grid del minijuego
local GRID_ROWS = 4           -- Número de filas (ej: 2 para 2x2, 4 para 4x4)
local GRID_COLS = 4           -- Número de columnas (ej: 2 para 2x2, 4 para 4x4)
local SEQUENCE_LENGTH = 5     -- Longitud de la secuencia a recordar
local BUTTON_SIZE = 12        -- Tamaño de los botones en píxeles
local SEQUENCE_DELAY = 35     -- Ticks entre cada paso de secuencia (20 = 1 segundo)
local RESULT_DISPLAY_TIME = 60 -- Ticks para mostrar resultado (ERROR/DECRYPT) antes de cerrar
local DIFFICULTY_PATTERNS = 1 -- Número de patrones simultáneos (1-3): 1=Solo verde, 2=Verde+Rojo, 3=Verde+Rojo+Azul
local DIFFICULTY_TEXT = "DIFFICULTY: BASIC" -- Texto configurable de dificultad
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

-- Registrar el sistema de timers ultra simple
Events.OnTick.Add(function() SimpleTimer:update() end)

local MiniGameWindow = ISPanel:derive("MiniGameWindow")

function MiniGameWindow:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.player = player
    -- Fondo ligeramente translúcido; disminuir para que el texto no quede tan apagado
    o.backgroundColor = {r=0, g=0, b=0, a=0.6}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.moveWithMouse = true

    -- Game state for sequence minigame - CONFIGURABLE
    o.sequence = {}
    o.currentIndex = 1
    o.playing = false
    o.userInput = {}
    o.sequenceLength = SEQUENCE_LENGTH  -- ← Usa configuración global
    
    -- Sistema de timers para esta instancia
    o.activeTimers = {}

    return o
end

function MiniGameWindow:initialise()
    ISPanel.initialise(self)
    self:createChildren()
end

-- SISTEMA DE TIMERS PARA LA INSTANCIA - Más seguro que closures
function MiniGameWindow:addTimer(duration, callback)
    return SimpleTimer:addTimer(duration, callback)
end

function MiniGameWindow:clearAllTimers()
    -- Limpiar todos los timers activos
    for id, timer in pairs(SimpleTimer.activeTimers) do
        SimpleTimer.activeTimers[id] = nil
    end
end

function MiniGameWindow:onClose()
    self:clearAllTimers()
    self:setVisible(false)
    self:removeFromUIManager()
end

-- No override de onMouseUp: dejar comportamiento por defecto para que el dragging se libere correctamente

function MiniGameWindow:createChildren()
    -- VALIDACIÓN ROBUSTA: usar valores seguros para configuración
    local gridRows = tonumber(GRID_ROWS) or 4
    local gridCols = tonumber(GRID_COLS) or 4
    local buttonSize = tonumber(BUTTON_SIZE) or 15

    -- Asegurar valores mínimos y máximos seguros
    gridRows = math.max(1, math.min(10, gridRows))
    gridCols = math.max(1, math.min(10, gridCols))
    buttonSize = math.max(10, math.min(100, buttonSize))

    -- Botón de cierre
    self.closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    -- Start button
    self.startButton = ISButton:new(10, 45, 100, 30, "Start", self, self.onStart)
    self.startButton:initialise()
    self:addChild(self.startButton)

    -- Reset button
    self.resetButton = ISButton:new(120, 45, 100, 30, "Reset", self, self.onReset)
    self.resetButton:initialise()
    self:addChild(self.resetButton)

    -- Create GRID_ROWS x GRID_COLS grid of sequence buttons - CONFIGURABLE
    self.sequenceButtons = {}
    for row = 1, gridRows do
        self.sequenceButtons[row] = {}
        for col = 1, gridCols do
            local btnIndex = (row - 1) * gridCols + col
            local btn = ISButton:new(0, 0, buttonSize, buttonSize, "", self, self.onSequencePress)
            btn.sequenceIndex = btnIndex
            btn.gridRow = row
            btn.gridCol = col
            btn:initialise()
            self:addChild(btn)
            self.sequenceButtons[row][col] = btn
        end
    end

    self:updateLayout()
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
        self.startButton:setX(10)
        self.startButton:setY(65)
    end
    if self.resetButton then
        self.resetButton:setWidth(btnWidth)
        self.resetButton:setX(20 + btnWidth)
        self.resetButton:setY(65)
    end
end

function MiniGameWindow:onResize(newW, newH)
    self:updateLayout()
end

function MiniGameWindow:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
end

function MiniGameWindow:onStart()
    -- Limpiar timers anteriores
    self:clearAllTimers()
    
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
            -- Success! All buttons green with DECRYPT
            self.playing = false
            self:setAllButtonsColorSafe({r=0, g=1, b=0, a=1}, "DECRYPT")
            
            -- Close minigame after configured time
            SimpleTimer:addTimer(RESULT_DISPLAY_TIME, function()
                self:onClose() -- Cerrar minijuego después de mostrar éxito
            end)
            
            if self.player then
                self.player:Say("Perfect! Sequence completed!")
            end
        end
    else
        -- Failure: Show error on all buttons
        self.playing = false
        
        -- Show error on ALL buttons immediately
        self:setAllButtonsColorSafe({r=1, g=0, b=0, a=1}, "ERROR")
        
        -- Clear error after configured time and CLOSE minigame
        SimpleTimer:addTimer(RESULT_DISPLAY_TIME, function()
            self:clearAllButtonColors()
            self:onClose() -- Cerrar minijuego después de mostrar error
        end)
        
        if self.player then
            self.player:Say("Wrong! You lost. Resetting for retry.")
        end
    end
end

function MiniGameWindow:onReset()
    -- Limpiar todos los timers activos
    self:clearAllTimers()
    
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

-- MANTENER LA FUNCIÓN ORIGINAL PARA COMPATIBILIDAD
function MiniGameWindow:setAllButtonsColor(color, text)
    self:setAllButtonsColorSafe(color, text)
end

-- Función global para abrir la ventana
function MiniGame(widthPct, heightPct)
    local player = getPlayer()
    if not player then 
        print("MiniGame: No player found")
        return 
    end

    -- Soporta tamaños dinámicos en %: MiniGame(widthPct, heightPct)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()

    widthPct = tonumber(widthPct) or 20
    heightPct = tonumber(heightPct) or 40

    -- Validar rangos
    if type(widthPct) ~= 'number' or widthPct < 10 or widthPct > 100 then widthPct = 20 end
    if type(heightPct) ~= 'number' or heightPct < 10 or heightPct > 100 then heightPct = 40 end

    local width = math.max(200, math.floor(screenW * (widthPct / 100)))
    local height = math.max(80, math.floor(screenH * (heightPct / 100)))
    local x = math.floor((screenW - width) / 2)
    local y = math.floor((screenH - height) / 2)

    local window = MiniGameWindow:new(x, y, width, height, player)
    window:initialise()
    window:addToUIManager()
    window:bringToTop()
    window:setVisible(true)
    return window
end

-- Mejorar renderizado: EFECTO CRT VERDE ESTILO ALIEN
function MiniGameWindow:render()
    -- Llamar render base primero para dibujar hijos
    ISPanel.render(self)

    -- EFECTO CRT: Fondo verde oscuro con líneas de escaneo
    local crtGreen = {r=0, g=0, b=0, a=0.3}
    self:drawRect(0, 0, self.width, self.height, crtGreen.a, crtGreen.r, crtGreen.g, crtGreen.b)
    
    -- Líneas de escaneo horizontales para efecto CRT
    for y = 0, self.height, 4 do
        self:drawRect(0, y, self.width, 1, 0.1, 0, 0.3, 0)
    end
    
    -- Borde verde brillante estilo terminal
    local borderGreen = {r=0.2, g=1, b=0.2, a=1}
    self:drawRectBorder(0, 0, self.width, self.height, borderGreen.a, borderGreen.r, borderGreen.g, borderGreen.b)
    self:drawRectBorder(1, 1, self.width-2, self.height-2, borderGreen.a * 0.5, borderGreen.r, borderGreen.g, borderGreen.b)

    -- TÍTULO CENTRADO con efecto de terminal
    local titleText = "DECRYPT SEQUENCE TERMINAL"
    local titleWidth = getTextManager():MeasureStringX(UIFont.Large, titleText)
    local titleX = (self.width - titleWidth) / 2
    
    -- Efecto de resplandor en el título
    self:drawText(titleText, titleX + 1, 11, 0.1, 0.5, 0.1, 0.8, UIFont.Large) -- Sombra
    self:drawText(titleText, titleX, 10, 0.2, 1, 0.2, 1, UIFont.Large) -- Texto principal
    
    -- Información de dificultad
    local diffText = DIFFICULTY_TEXT or "DIFFICULTY: BASIC"
    
    local diffWidth = getTextManager():MeasureStringX(UIFont.Small, diffText)
    local diffX = (self.width - diffWidth) / 2
    self:drawText(diffText, diffX, 35, 0.2, 0.8, 0.2, 0.9, UIFont.Small)
    
    -- Draw sequence info con estilo terminal
    if self.sequence and #self.sequence > 0 then
        local seqInfo = "PROGRESS: " .. (self.currentIndex - 1) .. "/" .. #self.sequence
        local seqWidth = getTextManager():MeasureStringX(UIFont.Small, seqInfo)
        local seqX = self.width - seqWidth - 10
        
        -- Efecto de parpadeo en el progreso - VALIDACIÓN SEGURA
        local time = os.clock()
        if time and type(time) == 'number' then
            local alpha = 0.7 + 0.3 * math.sin(time * 3)
            self:drawText(seqInfo, seqX, self.height - 20, 0.2, 1, 0.2, alpha, UIFont.Small)
        else
            -- Fallback sin animación si os.clock() falla
            self:drawText(seqInfo, seqX, self.height - 20, 0.2, 1, 0.2, 0.9, UIFont.Small)
        end
    end
    
    -- Línea de estado en la parte inferior
    local statusText = self.playing and "AWAITING INPUT..." or "SYSTEM READY"
    if not self.playing and self.sequence and #self.sequence > 0 then
        statusText = "SEQUENCE ANALYSIS COMPLETE"
    end
    
    local statusWidth = getTextManager():MeasureStringX(UIFont.Small, statusText)
    local statusX = (self.width - statusWidth) / 2
    
    -- Efecto de parpadeo en el estado - VALIDACIÓN SEGURA
    local time = os.clock()
    if time and type(time) == 'number' then
        local blinkAlpha = 0.5 + 0.5 * math.sin(time * 4)
        self:drawText(statusText, statusX, self.height - 35, 0.2, 1, 0.2, blinkAlpha, UIFont.Small)
    else
        -- Fallback sin animación si os.clock() falla
        self:drawText(statusText, statusX, self.height - 35, 0.2, 1, 0.2, 0.8, UIFont.Small)
    end
end