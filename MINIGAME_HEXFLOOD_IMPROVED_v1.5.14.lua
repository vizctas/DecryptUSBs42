-- MiniGameHexFlood.lua - Hexadecimal Flood Minigame v1.5.14
-- Match-3 puzzle with rising hex symbols, inspired by Tetris Attack and Panel de Pon
--
-- 🆕 v1.5.14 IMPROVEMENTS:
-- ✅ Render directo del grid (sin botones ISButton invisibles)
-- ✅ Mouse events personalizados para interacción
-- ✅ Contraste mejorado (texto blanco con sombra)
-- ✅ Paleta de colores más vibrante y visible
-- ✅ Animaciones de match con partículas
-- ✅ Pulse effect en celda seleccionada
-- ✅ Shake effect al perder por overflow
-- ✅ Tutorial integrado antes de START
-- ✅ Progress bar mostrando altura del grid

print("[DecryptSkillSys] Loading MiniGameHexFlood.lua v1.5.14 - Hexadecimal Flood system")

function ReloadMiniGameHexFlood() print("[DEBUG] Reloading HexFlood..."); package.loaded["client/MiniGameHexFlood"]=nil; pcall(require,"client/MiniGameHexFlood") end
function TestHexFlood(diff) diff=diff or "Easy"; if _G.MiniGame_HexFlood then return _G.MiniGame_HexFlood(nil,nil,"TestHex",diff,nil,{skill="TestHex"}) end end

-- CONFIG
local W_PCT, H_PCT = 38, 55  -- ⚡ Aumentado para mejor visibilidad
local GRID_W, GRID_H = 6, {Easy=8, Moderate=10, Expert=12}
local RISE_SPEEDS = {Easy=180, Moderate=120, Expert=80} -- ticks
local TIME_LIMITS = {Easy=90, Moderate=75, Expert=60}
local MATCH_SIZES = {Easy=3, Moderate=4, Expert=5}
local HEX_SYMBOLS = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}

-- ✨ TEMA MEJORADO: Colores más vibrantes y contrastantes
local THEME = {
    bg = {r=0.03, g=0.06, b=0.10, a=0.95},  -- Azul oscuro profundo
    border = {r=0.2, g=0.9, b=0.3, a=1},  -- Verde brillante
    cell_bg = {r=0.08, g=0.12, b=0.18, a=0.95},  -- Azul oscuro para celdas
    cell_border = {r=0.15, g=0.25, b=0.35, a=1},  -- Borde sutil
    selected = {r=1, g=1, b=0.2, a=0.8},  -- Amarillo brillante
    matched = {r=1, g=0.3, b=0.3, a=0.9},  -- Rojo brillante para matches
    
    -- Paleta hex más vibrante (16 colores distintos)
    hex_0 = {r=0.9, g=0.2, b=0.2, a=1},   -- Rojo
    hex_1 = {r=0.2, g=0.9, b=0.2, a=1},   -- Verde
    hex_2 = {r=0.2, g=0.4, b=0.9, a=1},   -- Azul
    hex_3 = {r=0.9, g=0.9, b=0.2, a=1},   -- Amarillo
    hex_4 = {r=0.9, g=0.2, b=0.9, a=1},   -- Magenta
    hex_5 = {r=0.2, g=0.9, b=0.9, a=1},   -- Cian
    hex_6 = {r=0.9, g=0.5, b=0.2, a=1},   -- Naranja
    hex_7 = {r=0.5, g=0.2, b=0.9, a=1},   -- Púrpura
    hex_8 = {r=0.9, g=0.7, b=0.3, a=1},   -- Oro
    hex_9 = {r=0.3, g=0.9, b=0.5, a=1},   -- Verde menta
    hex_A = {r=0.9, g=0.3, b=0.5, a=1},   -- Rosa
    hex_B = {r=0.5, g=0.9, b=0.3, a=1},   -- Lima
    hex_C = {r=0.3, g=0.5, b=0.9, a=1},   -- Azul cielo
    hex_D = {r=0.9, g=0.3, b=0.7, a=1},   -- Rosa fuerte
    hex_E = {r=0.7, g=0.9, b=0.3, a=1},   -- Amarillo verdoso
    hex_F = {r=0.5, g=0.3, b=0.9, a=1},   -- Violeta
    
    text = {r=1, g=1, b=1, a=1},  -- Blanco para texto
    text_shadow = {r=0, g=0, b=0, a=0.8}  -- Sombra negra
}

-- ⏱️ SIMPLE TIMER SYSTEM
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

-- 🎮 MAIN WINDOW CLASS
local MiniGameHexFloodWindow = ISPanel:derive("MiniGameHexFloodWindow")

function MiniGameHexFloodWindow:new(x, y, w, h, player, usbType, diff, laptop, usbData)
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
    
    o.gridH = GRID_H[diff] or 8
    o.riseSpeed = RISE_SPEEDS[diff] or 180
    o.timeLimit = TIME_LIMITS[diff] or 90
    o.matchSize = MATCH_SIZES[diff] or 3
    
    o.grid = {}
    o.selected = nil
    o.timeLeft = o.timeLimit
    o.gameActive = false
    o.resultProcessed = false
    o.score = 0
    o.combo = 0
    o.riseCounter = 0
    
    o.titleText = "HEXADECIMAL FLOOD"
    o.titleShown = 0
    o.titleAcc = 0
    
    o.showTutorial = true  -- ✨ Tutorial antes de empezar
    o.particles = {}  -- ✨ Sistema de partículas
    o.shakeOffset = {x=0, y=0}  -- ✨ Shake effect
    o.pulseAnim = 0  -- ✨ Pulse en celda seleccionada
    
    -- Grid layout
    o.cellSize = math.floor((w - 60) / GRID_W)
    o.gridX = 30
    o.gridY = 120
    
    o:initGrid()
    return o
end

function MiniGameHexFloodWindow:initGrid()
    for y = 1, self.gridH do 
        self.grid[y] = {}
        for x = 1, GRID_W do 
            self.grid[y][x] = {
                symbol = HEX_SYMBOLS[ZombRand(1, 9)],  -- Empezar con símbolos básicos (0-8)
                marked = false,
                fallAnim = 0  -- ✨ Animación de caída
            }
        end
    end
end

function MiniGameHexFloodWindow:addRow()
    -- Remover fila superior y agregar nueva abajo
    table.remove(self.grid, 1)
    local newRow = {}
    for x = 1, GRID_W do 
        newRow[x] = {
            symbol = HEX_SYMBOLS[ZombRand(1, #HEX_SYMBOLS + 1)],
            marked = false,
            fallAnim = 10  -- ✨ Animación al aparecer
        }
    end
    table.insert(self.grid, newRow)
end

function MiniGameHexFloodWindow:findMatches()
    -- Resetear marcas
    for y = 1, self.gridH do 
        for x = 1, GRID_W do 
            self.grid[y][x].marked = false
        end
    end
    
    local found = false
    
    -- Buscar matches horizontales
    for y = 1, self.gridH do 
        for x = 1, GRID_W - self.matchSize + 1 do
            local sym = self.grid[y][x].symbol
            if sym ~= "" then
                local match = true
                for dx = 1, self.matchSize - 1 do 
                    if self.grid[y][x + dx].symbol ~= sym then 
                        match = false
                        break
                    end
                end
                if match then 
                    for dx = 0, self.matchSize - 1 do 
                        self.grid[y][x + dx].marked = true
                    end
                    found = true
                end
            end
        end
    end
    
    -- Buscar matches verticales
    for x = 1, GRID_W do 
        for y = 1, self.gridH - self.matchSize + 1 do
            local sym = self.grid[y][x].symbol
            if sym ~= "" then
                local match = true
                for dy = 1, self.matchSize - 1 do 
                    if self.grid[y + dy][x].symbol ~= sym then 
                        match = false
                        break
                    end
                end
                if match then 
                    for dy = 0, self.matchSize - 1 do 
                        self.grid[y + dy][x].marked = true
                    end
                    found = true
                end
            end
        end
    end
    
    return found
end

function MiniGameHexFloodWindow:removeMarked()
    local removed = 0
    local markedCells = {}
    
    -- Contar y guardar posiciones marcadas
    for y = 1, self.gridH do 
        for x = 1, GRID_W do 
            if self.grid[y][x].marked then 
                self.grid[y][x].symbol = ""
                removed = removed + 1
                table.insert(markedCells, {x=x, y=y})
            end
        end
    end
    
    if removed > 0 then 
        self.score = self.score + (removed * 10 * (self.combo + 1))
        self.combo = self.combo + 1
        
        -- ✨ Crear partículas en celdas marcadas
        for _, cell in ipairs(markedCells) do
            self:createMatchParticles(cell.x, cell.y)
        end
        
        -- ✨ Efectos de sonido y visuales
        self:playSound("UI_Menu_OS_Select")
        if DynamicSoundSystem and DynamicSoundSystem.playSuccessSound then
            DynamicSoundSystem.playSuccessSound(self.player, 0.3 + (self.combo * 0.1))
        end
        if self.player and self.combo > 3 then
            self.player:Say("Combo x" .. self.combo .. "!")
        end
    else 
        self.combo = 0
    end
    
    -- ✨ Compactar grid con animación de caída
    for x = 1, GRID_W do 
        local col = {}
        for y = self.gridH, 1, -1 do 
            if self.grid[y][x].symbol ~= "" then 
                table.insert(col, self.grid[y][x])
            end
        end
        for y = self.gridH, 1, -1 do 
            if col[self.gridH - y + 1] then
                self.grid[y][x] = col[self.gridH - y + 1]
                self.grid[y][x].fallAnim = 5  -- Animación de caída
            else
                self.grid[y][x] = {symbol="", marked=false, fallAnim=0}
            end
        end
    end
end

-- ✨ SISTEMA DE PARTÍCULAS
function MiniGameHexFloodWindow:createMatchParticles(gridX, gridY)
    local cellX = self.gridX + (gridX - 1) * self.cellSize + self.cellSize / 2
    local cellY = self.gridY + (gridY - 1) * self.cellSize + self.cellSize / 2
    
    -- Crear 4-8 partículas por match
    local count = ZombRand(4, 9)
    for i = 1, count do
        local angle = (i / count) * math.pi * 2
        local speed = ZombRand(2, 5)
        table.insert(self.particles, {
            x = cellX,
            y = cellY,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed - 2,  -- Bias upward
            life = 30,
            maxLife = 30,
            size = ZombRand(3, 6),
            color = THEME["hex_" .. HEX_SYMBOLS[ZombRand(1, #HEX_SYMBOLS + 1)]] or THEME.text
        })
    end
end

function MiniGameHexFloodWindow:updateParticles()
    local alive = {}
    for _, p in ipairs(self.particles) do
        p.x = p.x + p.vx
        p.y = p.y + p.vy
        p.vy = p.vy + 0.3  -- Gravedad
        p.life = p.life - 1
        if p.life > 0 then
            table.insert(alive, p)
        end
    end
    self.particles = alive
end

function MiniGameHexFloodWindow:createChildren()
    -- Botón de cerrar
    self.closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)
    
    -- Botón START
    self.startButton = ISButton:new((self.width - 120) / 2, self.height - 60, 120, 50, "START", self, self.onStart)
    self.startButton.borderColor = THEME.border
    self.startButton.backgroundColor = {r=0.05, g=0.15, b=0.05, a=0.9}
    self.startButton.backgroundColorMouseOver = {r=0.2, g=1, b=0.2, a=0.9}
    self.startButton:initialise()
    self:addChild(self.startButton)
end

function MiniGameHexFloodWindow:onStart()
    self.gameActive = true
    self.timeLeft = self.timeLimit
    self.score = 0
    self.combo = 0
    self.riseCounter = 0
    self.showTutorial = false
    self.startButton:setVisible(false)
    
    self:startTimer()
    self:startRiser()
    self:playSound("UI_Menu_OS_Start")
end

function MiniGameHexFloodWindow:onMouseDown(x, y)
    if not self.gameActive then return end
    
    -- Convertir coordenadas a grid
    local gx = math.floor((x - self.gridX) / self.cellSize) + 1
    local gy = math.floor((y - self.gridY) / self.cellSize) + 1
    
    if gx < 1 or gx > GRID_W or gy < 1 or gy > self.gridH then return end
    if self.grid[gy][gx].symbol == "" then return end
    
    if not self.selected then
        -- Primera selección
        self.selected = {x=gx, y=gy}
        self.pulseAnim = 10
        self:playSound("UI_Menu_OS_Select")
    else
        -- Segunda selección: verificar adyacencia
        local dx = math.abs(gx - self.selected.x)
        local dy = math.abs(gy - self.selected.y)
        
        if dx + dy == 1 then
            -- Swap adyacente
            local c1 = self.grid[self.selected.y][self.selected.x]
            local c2 = self.grid[gy][gx]
            c1.symbol, c2.symbol = c2.symbol, c1.symbol
            
            if self:findMatches() then
                self:removeMarked()
            else
                -- No hay match, revertir swap
                c1.symbol, c2.symbol = c2.symbol, c1.symbol
            end
            
            self.selected = nil
            self:playSound("UI_Menu_OS_Select")
        else
            -- Selección no adyacente, cambiar selección
            self.selected = {x=gx, y=gy}
            self.pulseAnim = 10
        end
    end
end

function MiniGameHexFloodWindow:cancelTimer(f) 
    if f and self[f] then 
        SimpleTimer:removeTimer(self[f])
        self[f] = nil
    end
end

function MiniGameHexFloodWindow:startTimer() 
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

function MiniGameHexFloodWindow:startRiser() 
    self:cancelTimer("riserId")
    self.riserId = SimpleTimer:addTimer(1, function() 
        if not self.gameActive then return end
        self.riseCounter = self.riseCounter + 1
        if self.riseCounter >= self.riseSpeed then 
            self:addRow()
            self.riseCounter = 0
            -- Verificar game over por overflow
            if self.grid[1][1].symbol ~= "" then 
                self:processFinalResult(false)
            end
        end
        self:startRiser()
    end)
end

function MiniGameHexFloodWindow:onTimeUp() 
    self.gameActive = false
    self:playSound("UI_Menu_OS_Exit")
    self:processFinalResult(true)
end

function MiniGameHexFloodWindow:onClose() 
    if self.gameActive then 
        self:processFinalResult(false)
    end
    self:cancelTimer("timerId")
    self:cancelTimer("riserId")
    self:setVisible(false)
    self:removeFromUIManager()
end

function MiniGameHexFloodWindow:processFinalResult(success)
    if self.resultProcessed then return end
    self.resultProcessed = true
    self.gameActive = false
    
    self:cancelTimer("timerId")
    self:cancelTimer("riserId")
    
    -- ✨ Shake effect al perder
    if not success then
        for i = 1, 10 do
            SimpleTimer:addTimer(i * 2, function()
                self.shakeOffset.x = ZombRand(-5, 6)
                self.shakeOffset.y = ZombRand(-5, 6)
            end)
        end
        SimpleTimer:addTimer(20, function()
            self.shakeOffset = {x=0, y=0}
        end)
    end
    
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
    
    -- ✨ Efectos finales
    self:playSound(success and "UI_Menu_OS_Success" or "UI_Menu_OS_Failure")
    if success and DynamicSoundSystem and DynamicSoundSystem.playSuccessSound then
        DynamicSoundSystem.playSuccessSound(self.player, 1.0)
    elseif not success and DynamicSoundSystem and DynamicSoundSystem.playFailureSound then
        DynamicSoundSystem.playFailureSound(self.player, 0.7)
    end
    
    if self.player then
        if success then
            self.player:Say("Hex flood cleared! Score: " .. self.score)
        else
            self.player:Say("Flooded! Game over.")
        end
    end
    
    -- Cerrar ventana después de 2 segundos
    SimpleTimer:addTimer(120, function() self:onClose() end)
end

function MiniGameHexFloodWindow:playSound(snd) 
    if self.player and snd then 
        if self.player.playSoundLocal then 
            self.player:playSoundLocal(snd)
        elseif getPlayer() then 
            getPlayer():playSoundLocal(snd)
        end
    end
end

function MiniGameHexFloodWindow:prerender()
    ISPanel.prerender(self)
    
    -- Actualizar animaciones
    if self.pulseAnim > 0 then
        self.pulseAnim = self.pulseAnim - 1
    end
    
    -- Actualizar animaciones de caída
    for y = 1, self.gridH do
        for x = 1, GRID_W do
            if self.grid[y][x].fallAnim > 0 then
                self.grid[y][x].fallAnim = self.grid[y][x].fallAnim - 1
            end
        end
    end
    
    -- Actualizar partículas
    self:updateParticles()
end

function MiniGameHexFloodWindow:render()
    ISPanel.render(self)
    
    -- ✨ Aplicar shake offset
    local shakeX = self.shakeOffset.x or 0
    local shakeY = self.shakeOffset.y or 0
    
    -- Título con animación typewriter
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
    self:drawTextCentre(title, self.width / 2 + shakeX, 10 + shakeY, 
        THEME.text.r, THEME.text.g, THEME.text.b, THEME.text.a, UIFont.Large)
    
    -- ✨ TUTORIAL antes de empezar
    if self.showTutorial then
        local tutY = 50
        local lineHeight = 18
        
        self:drawTextCentre("= HOW TO PLAY =", self.width / 2, tutY, 
            THEME.border.r, THEME.border.g, THEME.border.b, 1, UIFont.Medium)
        tutY = tutY + 25
        
        local instructions = {
            "• Match " .. self.matchSize .. " or more identical hex symbols",
            "• Click two adjacent cells to swap them",
            "• Grid rises over time - prevent overflow!",
            "• Make combos for bonus points",
            "• Clear rows before reaching the top"
        }
        
        for _, line in ipairs(instructions) do
            self:drawText(line, 20, tutY, 
                THEME.text.r, THEME.text.g, THEME.text.b, 0.9, UIFont.Small)
            tutY = tutY + lineHeight
        end
        
        return
    end
    
    -- HUD de juego activo
    if self.gameActive then
        -- Timer
        local timeColor = self.timeLeft < 20 and {r=1, g=0.3, b=0.3} or THEME.text
        self:drawText("TIME: " .. math.ceil(self.timeLeft) .. "s", 10, 40, 
            timeColor.r, timeColor.g, timeColor.b, 1, UIFont.Small)
        
        -- Score
        self:drawText("SCORE: " .. self.score, self.width - 120, 40, 
            THEME.text.r, THEME.text.g, THEME.text.b, 1, UIFont.Small)
        
        -- Combo indicator
        if self.combo > 1 then
            self:drawTextCentre("COMBO x" .. self.combo, self.width / 2, 60, 
                1, 0.8, 0.2, 1, UIFont.Medium)
        end
        
        -- ✨ Progress bar de altura del grid
        local dangerHeight = 3  -- Primeras 3 filas son peligrosas
        local filledRows = 0
        for y = 1, dangerHeight do
            for x = 1, GRID_W do
                if self.grid[y][x].symbol ~= "" then
                    filledRows = filledRows + 1
                    break
                end
            end
        end
        local dangerRatio = filledRows / dangerHeight
        local barWidth = self.width - 40
        local barHeight = 10
        local barX = 20
        local barY = 80
        
        -- Fondo de la barra
        self:drawRect(barX, barY, barWidth, barHeight, 0.5, 0.2, 0.2, 0.2)
        
        -- Relleno (rojo si peligroso, verde si seguro)
        local barColor = dangerRatio > 0.6 and {r=0.9, g=0.2, b=0.2} or {r=0.2, g=0.9, b=0.2}
        self:drawRect(barX, barY, barWidth * dangerRatio, barHeight, 
            barColor.a or 1, barColor.r, barColor.g, barColor.b)
        
        -- Borde
        self:drawRectBorder(barX, barY, barWidth, barHeight, 1, 0.5, 0.5, 0.5, 1)
        
        -- ✨ RENDERIZAR GRID
        for y = 1, self.gridH do
            for x = 1, GRID_W do
                local cell = self.grid[y][x]
                local cellX = self.gridX + (x - 1) * self.cellSize + shakeX
                local cellY = self.gridY + (y - 1) * self.cellSize + shakeY
                
                -- ✨ Offset de animación de caída
                local fallOffset = cell.fallAnim > 0 and (cell.fallAnim * 2) or 0
                cellY = cellY - fallOffset
                
                -- Fondo de celda
                self:drawRect(cellX, cellY, self.cellSize, self.cellSize, 
                    THEME.cell_bg.a, THEME.cell_bg.r, THEME.cell_bg.g, THEME.cell_bg.b)
                
                -- Borde de celda
                self:drawRectBorder(cellX, cellY, self.cellSize, self.cellSize, 
                    1, THEME.cell_border.r, THEME.cell_border.g, THEME.cell_border.b, THEME.cell_border.a)
                
                -- Símbolo hex con color
                if cell.symbol ~= "" then
                    local hexColor = THEME["hex_" .. cell.symbol] or THEME.text
                    
                    -- Fondo coloreado del símbolo
                    local padding = 3
                    self:drawRect(cellX + padding, cellY + padding, 
                        self.cellSize - padding * 2, self.cellSize - padding * 2,
                        hexColor.a, hexColor.r, hexColor.g, hexColor.b)
                    
                    -- ✨ Texto del símbolo con sombra para contraste
                    local textX = cellX + self.cellSize / 2 - 4
                    local textY = cellY + self.cellSize / 2 - 8
                    
                    -- Sombra negra
                    self:drawText(cell.symbol, textX + 1, textY + 1, 
                        THEME.text_shadow.r, THEME.text_shadow.g, THEME.text_shadow.b, THEME.text_shadow.a, 
                        UIFont.Medium)
                    
                    -- Texto blanco
                    self:drawText(cell.symbol, textX, textY, 
                        THEME.text.r, THEME.text.g, THEME.text.b, THEME.text.a, 
                        UIFont.Medium)
                end
                
                -- ✨ Highlight de celda seleccionada con pulse
                if self.selected and self.selected.x == x and self.selected.y == y then
                    local pulseAlpha = 0.6 + (self.pulseAnim / 10) * 0.4
                    self:drawRectBorder(cellX, cellY, self.cellSize, self.cellSize, 
                        3, THEME.selected.r, THEME.selected.g, THEME.selected.b, pulseAlpha)
                end
            end
        end
        
        -- ✨ Renderizar partículas
        for _, p in ipairs(self.particles) do
            local alpha = p.life / p.maxLife
            self:drawRect(p.x + shakeX, p.y + shakeY, p.size, p.size, 
                alpha, p.color.r, p.color.g, p.color.b)
        end
        
    else
        -- Pantalla de resultado final
        if self.resultProcessed then
            self:drawTextCentre("FINAL SCORE: " .. self.score, self.width / 2, self.height / 2 - 20, 
                THEME.text.r, THEME.text.g, THEME.text.b, 1, UIFont.Large)
            
            local resultText = self.score > 500 and "EXCELLENT!" or 
                               self.score > 300 and "GOOD JOB!" or 
                               self.score > 100 and "NOT BAD!" or "TRY AGAIN!"
            self:drawTextCentre(resultText, self.width / 2, self.height / 2 + 10, 
                0.9, 0.9, 0.2, 1, UIFont.Medium)
        end
    end
end

-- 🎮 PUBLIC API
function MiniGame_HexFlood(widthPct, heightPct, usbType, difficulty, laptopItem, usbData)
    local player = getPlayer()
    if not player then return end
    
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local width = math.floor(screenW * (W_PCT / 100))
    local height = math.floor(screenH * (H_PCT / 100))
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2
    
    local win = MiniGameHexFloodWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData)
    win:initialise()
    win:addToUIManager()
    win:bringToTop()
    return win
end
