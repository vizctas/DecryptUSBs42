-- Binary logic puzzle inspired by Lights Out where clicks affect neighbors
--
-- v1.5.15 - RESTORED VERSION WITH FIXES:
-- Sistema de timers ultra simple (sin closures problemáticos)
-- Variables locales corregidas (tablas para estado)
-- Estética ALIEN CRT completa con tema verde
-- Manejo de errores robusto con pcall
-- Configuración dinámica completa
-- Layout optimizado con grid centrado
-- Tutorial overlay mejorado con fondo negro alfa 0.45
-- HUD ajustado para evitar overlap
-- Función onCellClick agregada para interacción de cuadros
-- Partículas y efectos visuales mejorados

function ReloadMiniGameBitShift() print("[DEBUG] Reloading BitShift..."); package.loaded["client/MiniGameBitShift"]=nil; pcall(require,"client/MiniGameBitShift") end
function TestBitShift(diff) diff=diff or "Easy"; if _G.MiniGame_BitShift then return _G.MiniGame_BitShift(nil,nil,"TestBit",diff,nil,{skill="TestBit"}) end end

-- CONFIG
local W_PCT, H_PCT = 28, 45
local GRID_SIZES = {Easy=4, Moderate=5, Expert=6}
local MOVE_LIMITS = {Easy=20, Moderate=15, Expert=10}
local TIME_LIMITS = {Easy=90, Moderate=75, Expert=60}
local OPERATIONS = {Easy="XOR", Moderate="XOR", Expert="XOR"}
local AFFECT_PATTERNS = {Easy="cross", Moderate="cross", Expert="cross_center"}

-- ✨ TEMA VERDE CRT (copiado de Fallout/MiniGameUI)
local THEME = {
    bg = {r=0.05, g=0.2, b=0.05, a=0.9},  -- Verde CRT
    border = {r=0.2, g=1, b=0.2, a=1},  -- Verde brillante
    bit_0 = {r=0.08, g=0.15, b=0.08, a=0.95},  -- Verde oscuro
    bit_1 = {r=0.2, g=0.9, b=0.2, a=0.95},  -- Verde brillante
    particle_on = {r=0.3, g=1, b=0.3, a=0.9},  -- Verde partículas
    particle_off = {r=0.15, g=0.3, b=0.15, a=0.7},  -- Verde oscuro partículas
    hover_outline = {r=1, g=1, b=0.2, a=0.8},  -- Amarillo hover
    text = {r=1, g=1, b=1, a=1},  -- Blanco
    grid_line = {r=0.2, g=0.4, b=0.2, a=0.5}  -- Verde grid
}

-- TIMER SYSTEM
local SimpleTimer = {activeTimers={}, nextId=1}
function SimpleTimer:addTimer(dur, cb) 
    local id = self.nextId
    self.nextId = id + 1
    self.activeTimers[id] = {callback=cb, duration=dur, elapsed=0}
    return id
end
function SimpleTimer:removeTimer(id) self.activeTimers[id] = nil end
function SimpleTimer:update() 
    local rm = {}
    for id, t in pairs(self.activeTimers) do 
        t.elapsed = t.elapsed + 1
        if t.elapsed >= t.duration then 
            if t.callback then pcall(t.callback) end
            rm[id] = true
        end
    end
    for id in pairs(rm) do self.activeTimers[id] = nil end
end
if Events and Events.OnTick then Events.OnTick.Add(function() SimpleTimer:update() end) end

-- WINDOW CLASS
local MiniGameBitShiftWindow = ISPanel:derive("MiniGameBitShiftWindow")

function MiniGameBitShiftWindow:new(x, y, w, h, player, usbType, diff, laptop, usbData)
    local o = ISPanel:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    
    o.player = player
    o.usbType = usbType
    o.difficulty = diff
    o.laptopItem = laptop
    o.usbData = usbData
    
    o.backgroundColor = THEME.bg
    o.borderColor = THEME.border
    o.moveWithMouse = true
    
    o.gridSize = GRID_SIZES[diff] or 4
    o.moveLimit = MOVE_LIMITS[diff] or 20
    o.timeLimit = TIME_LIMITS[diff] or 90
    o.operation = OPERATIONS[diff] or "XOR"
    o.pattern = AFFECT_PATTERNS[diff] or "cross"
    
    o.grid = {}
    o.solution = {}
    o.movesLeft = o.moveLimit
    o.timeLeft = o.timeLimit
    o.gameActive = false
    o.resultProcessed = false

    o.flashTicks = 0
    o.flashColor = {r=0.2, g=1, b=0.2}
    o.scanOffset = -20
    o.scanDelay = 4
    o.scanStep = 6
    o.statusMessages = {
        "BITSTREAM STABLE",
        "SHIFT REGISTER ALIGNMENT",
        "ANALYZING TOPOLOGY",
        "MAINTAIN INPUT FOCUS"
    }
    o.statusTextManual = "SYSTEM IDLE"
    o.statusCycleDelay = 180
    o.statusIndex = 1
    o.statusPulseTick = 0

    o.statusTimerId = nil
    o.scanTimerId = nil
    o.closeTimerId = nil
    
    o.titleText = "BIT SHIFTER"
    o.titleShown = 0
    o.titleAcc = 0
    
    o.showTutorial = true
    o.particles = {}
    
    o:generatePuzzle()
    return o
end

function MiniGameBitShiftWindow:generatePuzzle()
    -- Start with all 1s (target state)
    for y = 1, self.gridSize do 
        self.grid[y] = {}
        self.solution[y] = {}
        for x = 1, self.gridSize do 
            self.grid[y][x] = {
                value = 1,
                flipAnim = 0  -- ✨ Animación de flip (5 ticks = más rápido)
            }
            self.solution[y][x] = 1
        end
    end
    
    -- Work backwards: apply random clicks to scramble
    local scrambles = self.moveLimit - 5
    for i = 1, scrambles do
        local x, y = ZombRand(1, self.gridSize + 1), ZombRand(1, self.gridSize + 1)
        self:applyClick(x, y, self.grid, true)  -- true = skip animation during setup
    end
end

function MiniGameBitShiftWindow:applyClick(x, y, grid, skipAnim)
    local dirs = {{0,-1}, {0,1}, {-1,0}, {1,0}}  -- up, down, left, right
    
    -- Toggle self if pattern includes center
    if self.pattern == "cross_center" then
        grid[y][x].value = 1 - grid[y][x].value
        if not skipAnim then
            grid[y][x].flipAnim = 5  -- ✨ 5 ticks = más rápido
            self:createBitParticles(x, y, grid[y][x].value)
        end
    end
    
    -- Toggle neighbors
    for _, d in ipairs(dirs) do
        local nx, ny = x + d[1], y + d[2]
        if nx >= 1 and nx <= self.gridSize and ny >= 1 and ny <= self.gridSize then
            grid[ny][nx].value = 1 - grid[ny][nx].value
            if not skipAnim then
                grid[ny][nx].flipAnim = 5  -- ✨ 5 ticks = más rápido
                self:createBitParticles(nx, ny, grid[ny][nx].value)
            end
        end
    end
end

-- ✨ CREAR PARTÍCULAS (más fluidas)
function MiniGameBitShiftWindow:createBitParticles(gridX, gridY, bitValue)
    if not self.buttons or not self.buttons[gridY] or not self.buttons[gridY][gridX] then return end
    
    local btn = self.buttons[gridY][gridX]
    local centerX = btn:getX() + btn:getWidth() / 2
    local centerY = btn:getY() + btn:getHeight() / 2
    
    -- Crear 2-4 partículas (menos para mejor performance)
    local count = ZombRand(2, 5)
    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local speed = ZombRand(2, 4)
        table.insert(self.particles, {
            x = centerX,
            y = centerY,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - 3,  -- Float up
            life = 20,  -- ✨ 20 ticks = más rápido
            maxLife = 20,
            size = ZombRand(2, 4),
            color = bitValue == 1 and THEME.particle_on or THEME.particle_off
        })
    end
end

function MiniGameBitShiftWindow:updateParticles()
    for i = #self.particles, 1, -1 do
        local p = self.particles[i]
        p.x = p.x + p.vx
        p.y = p.y + p.vy
        p.vy = p.vy + 0.2  -- Gravity
        p.life = p.life - 1
        
        if p.life <= 0 then
            table.remove(self.particles, i)
        end
    end
    
    -- Reducir animaciones de flip
    for y = 1, self.gridSize do
        for x = 1, self.gridSize do
            if self.grid[y][x].flipAnim > 0 then
                self.grid[y][x].flipAnim = self.grid[y][x].flipAnim - 1
            end
        end
    end
end

function MiniGameBitShiftWindow:checkWin()
    for y = 1, self.gridSize do 
        for x = 1, self.gridSize do
            if self.grid[y][x].value ~= self.solution[y][x] then 
                return false
            end
        end
    end
    return true
end

function MiniGameBitShiftWindow:createChildren()
    self.closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)
    
    self.startButton = ISButton:new((self.width - 120) / 2, self.height - 55, 120, 45, "START", self, self.onStart)
    self.startButton.borderColor = THEME.border
    self.startButton.backgroundColor = {r=0.05, g=0.15, b=0.05, a=0.9}
    self.startButton.backgroundColorMouseOver = {r=0.2, g=1, b=0.2, a=0.9}
    self.startButton:initialise()
    self:addChild(self.startButton)
    
    self.buttons = {}
    local cellSize = math.floor(math.min(self.width - 60, self.height - 180) / self.gridSize)
    local gx = (self.width - cellSize * self.gridSize) / 2
    local gy = 90  -- Bajar grid ligeramente para evitar overlap con progress bar
    
    for y = 1, self.gridSize do 
        self.buttons[y] = {}
        for x = 1, self.gridSize do 
            local btn = ISButton:new(
                gx + (x - 1) * cellSize, 
                gy + (y - 1) * cellSize, 
                cellSize, 
                cellSize, 
                "", 
                self, 
                self.onCellClick
            )
            btn.gridX = x
            btn.gridY = y
            btn:initialise()
            self:addChild(btn)
            self.buttons[y][x] = btn
        end
    end

    self:startScanAnimation()
    self:startStatusCycle(true)
end

function MiniGameBitShiftWindow:onStart()
    self.gameActive = true
    self.timeLeft = self.timeLimit
    self.movesLeft = self.moveLimit
    self.showTutorial = false
    self.startButton:setVisible(false)
    
    self:startTimer()
    self:triggerFlash(30, {r=0.2, g=1, b=0.2})
    self.statusTextManual = "LINK ESTABLISHED"
    self.statusIndex = 1
    self.statusPulseTick = 0
    self:startStatusCycle()
    self:playSound("UI_Menu_OS_Start")
end

function MiniGameBitShiftWindow:cancelTimer(field)
    if field and self[field] then 
        SimpleTimer:removeTimer(self[field])
        self[field] = nil
    end
end

function MiniGameBitShiftWindow:startScanAnimation()
    self:cancelTimer("scanTimerId")
    local delay = math.max(1, self.scanDelay or 4)
    self.scanTimerId = SimpleTimer:addTimer(delay, function()
        if not self:getIsVisible() then
            self:cancelTimer("scanTimerId")
            return
        end

        local height = self.height or 0
        self.scanOffset = (self.scanOffset or -20) + (self.scanStep or 6)
        if self.scanOffset > height + 20 then
            self.scanOffset = -20
        end

        self:startScanAnimation()
    end)
end

function MiniGameBitShiftWindow:startStatusCycle(force)
    self:cancelTimer("statusTimerId")
    if not self.gameActive and not force then return end

    local messages = self.statusMessages or {}
    if #messages == 0 then return end

    local delay = math.max(30, self.statusCycleDelay or 180)
    self.statusTimerId = SimpleTimer:addTimer(delay, function()
        if not self.gameActive then
            self.statusTextManual = "SYSTEM IDLE"
            self:cancelTimer("statusTimerId")
            return
        end

        self.statusIndex = (self.statusIndex or 1) + 1
        if self.statusIndex > #messages then
            self.statusIndex = 1
        end
        self.statusTextManual = messages[self.statusIndex]
        self:startStatusCycle()
    end)
end

function MiniGameBitShiftWindow:triggerFlash(ticks, color)
    self.flashTicks = math.max(self.flashTicks or 0, ticks or 20)
    if color then
        self.flashColor = color
    end
end

function MiniGameBitShiftWindow:drawCRTOverlay()
    -- Outer and inner borders
    local border = THEME.border
    self:drawRectBorder(0, 0, self.width, self.height, border.a, border.r, border.g, border.b)
    self:drawRectBorder(2, 2, self.width - 4, self.height - 4, 0.4, border.r, border.g, border.b)

    -- Scan lines
    local offset = self.scanOffset or 0
    for y = -20, self.height + 20, 4 do
        local drawY = y + (offset % 4)
        self:drawRect(0, drawY, self.width, 1, 0.08, 0, 0.4, 0)
    end

    -- Flash overlay
    if self.flashTicks and self.flashTicks > 0 then
        local flashAlpha = math.max(0.05, math.min(0.35, self.flashTicks / 60))
        local fc = self.flashColor or {r=0.2, g=1, b=0.2}
        self:drawRect(0, 0, self.width, self.height, flashAlpha, fc.r, fc.g, fc.b)
    end
end

function MiniGameBitShiftWindow:startTimer()
    self:cancelTimer("timerId")
    self.timerId = SimpleTimer:addTimer(60, function()
        if not self.gameActive then return end
        self.timeLeft = self.timeLeft - 1
        if self.timeLeft <= 0 then 
            self:onTimeUp()
        else 
            self:startTimer()
        end
    end)
end

function MiniGameBitShiftWindow:onTimeUp()
    self.gameActive = false
    self:playSound("UI_Menu_OS_Exit")
    self:processFinalResult(false)
end

function MiniGameBitShiftWindow:onClose()
    if self.gameActive then 
        self:processFinalResult(false)
    end
    self:cancelTimer("timerId")
    self:cancelTimer("statusTimerId")
    self:cancelTimer("scanTimerId")
    self:cancelTimer("closeTimerId")
    self:setVisible(false)
    self:removeFromUIManager()
end

function MiniGameBitShiftWindow:processFinalResult(success)
    if self.resultProcessed then return end
    self.resultProcessed = true
    self.gameActive = false
    
    self:cancelTimer("timerId")
    self:cancelTimer("statusTimerId")
    self:cancelTimer("scanTimerId")
    self:cancelTimer("closeTimerId")
    
    -- Incrementar contador de fallos en laptop
    if not success and self.laptopItem then
        if isClient() then
            sendClientCommand(self.player, "GVDrive", "IncrementFailureCount", {laptop=self.laptopItem})
        elseif LaptopSystem and LaptopSystem.incrementFailureCount then
            LaptopSystem.incrementFailureCount(self.laptopItem)
        end
    end
    
    -- Aplicar resultado del minigame
    if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
        GVDrive_Utils.applyMinigameResult(self.player, self.laptopItem, self.usbType, self.difficulty, success)
    end
    
    -- ✨ SONIDOS SIN ALARMA
    if success then
        self:triggerFlash(45, {r=0.2, g=1, b=0.2})
        self.statusTextManual = "DECRYPT SUCCESS"
    else
        self:triggerFlash(45, {r=1, g=0.3, b=0.3})
        self.statusTextManual = "DECRYPT FAILED"
    end

    self:playSound(success and "UI_Menu_OS_Success" or "UI_Menu_OS_Failure")
    if success and DynamicSoundSystem and DynamicSoundSystem.playSuccessSound then
        DynamicSoundSystem.playSuccessSound(self.player, 1.0)
    end
    -- ⚠️ NO usar playFailureSound - Solo se dispara con evento de alarma por % de fallos
    
    -- Cerrar ventana después de 2 segundos
    self:cancelTimer("closeTimerId")
    self.closeTimerId = SimpleTimer:addTimer(120, function()
        self.closeTimerId = nil
        self:onClose()
    end)
end

function MiniGameBitShiftWindow:playSound(snd)
    if self.player and snd then
        if self.player.playSoundLocal then
            self.player:playSoundLocal(snd)
        elseif getPlayer() then
            getPlayer():playSoundLocal(snd)
        end
    end
end

function MiniGameBitShiftWindow:prerender()
    ISPanel.prerender(self)
    
    if self.flashTicks and self.flashTicks > 0 then
        self.flashTicks = self.flashTicks - 1
    end

    if self.gameActive then
        self:updateParticles()
    end
end

function MiniGameBitShiftWindow:render()
    ISPanel.render(self)
    self:drawCRTOverlay()
    
    -- Tutorial
    if self.showTutorial then
        self:renderTutorial()
        return
    end
    
    -- Título typewriter
    if self.gameActive and self.titleShown < #self.titleText then
        self.titleAcc = self.titleAcc + 1
        if self.titleAcc >= 3 then
            self.titleAcc = 0
            self.titleShown = self.titleShown + 1
        end
    elseif not self.gameActive then
        self.titleShown = #self.titleText
    end
    
    local title = string.sub(self.titleText, 1, self.titleShown)
    self:drawTextCentre(title, self.width / 2, 15, 
        THEME.text.r, THEME.text.g, THEME.text.b, THEME.text.a, UIFont.Large)
    
    if self.gameActive then
        -- HUD (posición ajustada para evitar overlap)
        self:drawText("TIME: " .. math.ceil(self.timeLeft) .. "s", 10, 35,
            THEME.text.r, THEME.text.g, THEME.text.b, 1, UIFont.Small)
        self:drawText("MOVES: " .. self.movesLeft, self.width - 100, 35,
            THEME.text.r, THEME.text.g, THEME.text.b, 1, UIFont.Small)
        
        -- Progress bar
        local correctCount = 0
        local totalBits = self.gridSize * self.gridSize
        for y = 1, self.gridSize do
            for x = 1, self.gridSize do
                if self.grid[y][x].value == self.solution[y][x] then
                    correctCount = correctCount + 1
                end
            end
        end
        
        local progressRatio = correctCount / totalBits
        local barWidth = self.width - 40
        local barHeight = 12
        local barX = 20
        local barY = 70  -- Bajar progress bar para evitar overlap con grid
        
        -- Background
        self:drawRect(barX, barY, barWidth, barHeight, 0.5, 0.1, 0.2, 0.1)
        
        -- Fill (verde)
        local fillColor = progressRatio >= 1 and {r=0.2, g=1, b=0.2} or {r=0.2, g=0.6, b=0.2}
        self:drawRect(barX, barY, barWidth * progressRatio, barHeight, 
            1, fillColor.r, fillColor.g, fillColor.b)
        
        -- Border
        self:drawRectBorder(barX, barY, barWidth, barHeight, 1, 0.3, 0.6, 0.3, 1)
        
        -- Text
        local progressText = correctCount .. " / " .. totalBits .. " bits"
        self:drawTextCentre(progressText, self.width / 2, barY + 1, 
            THEME.text.r, THEME.text.g, THEME.text.b, 1, UIFont.Small)
        
        -- Grid rendering
        for y = 1, self.gridSize do
            for x = 1, self.gridSize do
                local btn = self.buttons[y][x]
                local cell = self.grid[y][x]
                
                local bx = btn:getX()
                local by = btn:getY()
                local bw = btn:getWidth()
                local bh = btn:getHeight()
                
                -- ✨ Flip animation (scale effect más suave: 5 ticks)
                local scale = 1.0
                if cell.flipAnim > 0 then
                    scale = 1.0 + (cell.flipAnim / 5) * 0.2  -- ✨ Menos exagerado
                end
                
                local offsetX = (bw * (1 - scale)) / 2
                local offsetY = (bh * (1 - scale)) / 2
                local scaledX = bx + offsetX
                local scaledY = by + offsetY
                local scaledW = bw * scale
                local scaledH = bh * scale
                
                -- Background color based on bit value
                local bgColor = cell.value == 1 and THEME.bit_1 or THEME.bit_0
                self:drawRect(scaledX, scaledY, scaledW, scaledH, 
                    bgColor.a, bgColor.r, bgColor.g, bgColor.b)
                
                -- Border
                self:drawRectBorder(bx, by, bw, bh, 1, 
                    THEME.grid_line.r, THEME.grid_line.g, THEME.grid_line.b, THEME.grid_line.a)
                
                -- Bit text
                local bitText = tostring(cell.value)
                self:drawTextCentre(bitText, bx + bw / 2, by + bh / 2 - 8, 
                    THEME.text.r, THEME.text.g, THEME.text.b, 1, UIFont.Medium)
                
                -- Hover outline (amarillo)
                if self:getMouseX() >= bx and self:getMouseX() <= bx + bw and
                   self:getMouseY() >= by and self:getMouseY() <= by + bh then
                    self:drawRectBorder(bx, by, bw, bh, 2, 
                        THEME.hover_outline.r, THEME.hover_outline.g, THEME.hover_outline.b, THEME.hover_outline.a)
                end
            end
        end
        
        -- Render particles
        for _, p in ipairs(self.particles) do
            local alpha = p.life / p.maxLife
            self:drawRect(p.x, p.y, p.size, p.size, 
                alpha, p.color.r, p.color.g, p.color.b)
        end
    end
    
    -- Result message
    if self.resultProcessed then
        local msg = self:checkWin() and "SUCCESS!" or "FAILED!"
        local color = self:checkWin() and {r=0.2, g=1, b=0.2} or {r=1, g=0.3, b=0.3}
        self:drawTextCentre(msg, self.width / 2, self.height / 2 - 20, 
            color.r, color.g, color.b, 1, UIFont.Large)
    end

    -- Status text (bottom center)
    local status = self.statusTextManual or "SYSTEM IDLE"
    local pulse = (self.statusPulseTick or 0) / 40
    local alpha = 0.7 + 0.25 * math.sin(pulse)
    self.statusPulseTick = (self.statusPulseTick or 0) + 1
    self:drawTextCentre(status, self.width / 2, self.height - 30, 0.2, 1, 0.2, alpha, UIFont.Small)
end

function MiniGameBitShiftWindow:renderTutorial()
    self.statusTextManual = "AWAITING INPUT"

    -- Fondo negro semitransparente para mejorar legibilidad
    self:drawRect(0, 0, self.width, self.height, 0.45, 0, 0, 0)

    local tutY = 40
    local lineHeight = 24

    self:drawTextCentre("= BIT SHIFTER TUTORIAL =", self.width / 2, tutY,
        THEME.border.r, THEME.border.g, THEME.border.b, 1, UIFont.Large)
    tutY = tutY + lineHeight * 2

    self:drawTextCentre("OBJECTIVE:", self.width / 2, tutY, 1, 1, 1, 1, UIFont.Medium)
    tutY = tutY + lineHeight
    self:drawTextCentre("Turn all bits to 1 (green)", self.width / 2, tutY, 0.8, 0.8, 0.8, 1, UIFont.Small)
    tutY = tutY + lineHeight * 1.5

    self:drawTextCentre("HOW TO PLAY:", self.width / 2, tutY, 1, 1, 1, 1, UIFont.Medium)
    tutY = tutY + lineHeight
    self:drawTextCentre("Click a bit to flip its neighbors", self.width / 2, tutY, 0.8, 0.8, 0.8, 1, UIFont.Small)
    tutY = tutY + lineHeight
    self:drawTextCentre("(↑ ↓ ← →)", self.width / 2, tutY, 0.8, 0.8, 0.8, 1, UIFont.Small)
    tutY = tutY + lineHeight * 1.5

    self:drawTextCentre("LEGEND:", self.width / 2, tutY, 1, 1, 1, 1, UIFont.Medium)
    tutY = tutY + lineHeight
    self:drawTextCentre("0 = OFF (dark) | 1 = ON (green)", self.width / 2, tutY, 0.8, 0.8, 0.8, 1, UIFont.Small)
    tutY = tutY + lineHeight * 2
end

function MiniGameBitShiftWindow:onCellClick(btn)
    if not self.gameActive then return end
    if not btn or not btn.gridX or not btn.gridY then return end
    if self.movesLeft <= 0 then return end

    local x, y = btn.gridX, btn.gridY
    self:applyClick(x, y, self.grid, false)
    self.movesLeft = self.movesLeft - 1

    self:playSound("UI_Menu_OS_Select")

    if self:checkWin() then
        self:processFinalResult(true)
        return
    end

    if self.movesLeft <= 0 then
        self:processFinalResult(false)
    end
end

-- GLOBAL FUNCTION
function MiniGame_BitShift(widthPct, heightPct, usbType, difficulty, laptopItem, usbData)
    local player = getPlayer()
    if not player then 
        print("[BitShift] No player found")
        return 
    end

    widthPct = tonumber(widthPct) or W_PCT
    heightPct = tonumber(heightPct) or H_PCT

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local width = math.max(300, math.floor(screenW * (widthPct / 100)))
    local height = math.max(300, math.floor(screenH * (heightPct / 100)))
    local x = math.floor((screenW - width) / 2)
    local y = math.floor((screenH - height) / 2)

    local window = MiniGameBitShiftWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData)
    window:initialise()
    window:addToUIManager()
    window:bringToTop()
    window:setVisible(true)
    
    print("[BitShift] Window created successfully")
    return window
end

-- Registrar función global
_G.MiniGame_BitShift = MiniGame_BitShift

print("[DecryptSkillSys] MiniGameBitShift.lua loaded successfully - BitShift minigame system ready")