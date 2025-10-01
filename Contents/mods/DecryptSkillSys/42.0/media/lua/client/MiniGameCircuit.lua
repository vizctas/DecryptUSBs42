-- MiniGameCircuit.lua - Trazador de Circuitos
-- Inspirado en BioShock y otros juegos de puzzles de tuberías.
-- Estética Cyberpunk.

-- ============================================================================
-- DEBUG & RELOAD FUNCTIONS
-- ============================================================================
function ReloadMiniGameCircuit()
    print("[DEBUG] Reloading MiniGameCircuit system...")
    package.loaded["client/MiniGameCircuit"] = nil
    local success, result = pcall(require, "client/MiniGameCircuit")
    if success then
        print("[DEBUG] MiniGameCircuit reloaded successfully!")
    else
        print("[DEBUG] Failed to reload MiniGameCircuit: " .. tostring(result))
    end
end

function TestCircuitTracer(difficulty)
    difficulty = difficulty or "Easy"
    print("[DEBUG] Testing MiniGameCircuit with difficulty: " .. difficulty)
    if _G.MiniGame_Circuit then
        return _G.MiniGame_Circuit(nil, nil, "TestCircuit", difficulty, nil, {skill="TestCircuit", difficulty_english=difficulty, displayName="Test USB"})
    else
        print("[DEBUG] MiniGame_Circuit function not available. Try ReloadMiniGameCircuit() first.")
    end
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

-- ========== CONFIGURACIÓN DE VENTANA Y GRID ==========
-- Ajusta estos valores para cambiar el tamaño de la ventana y el grid
local WINDOW_WIDTH_PERCENT = 20      -- % del ancho de pantalla (20-60 recomendado)
local WINDOW_HEIGHT_PERCENT = 45     -- % del alto de pantalla (30-70 recomendado)
local GRID_FILL_PERCENT = 100         -- % de la ventana que ocupa el grid (50-85 recomendado)
-- ======================================================

-- Game Settings
local GRID_SIZES = { Easy = 5, Moderate = 6, Expert = 7 }
local TIME_LIMITS = { Easy = 45, Moderate = 40, Expert = 35 }

-- Cyberpunk Theme Colors
local THEME = {
    background = {r=0.05, g=0.05, b=0.15, a=0.5}, -- Azul oscuro/púrpura
    border = {r=0.8, g=0.1, b=0.8, a=1}, -- Magenta/neón
    grid_background = {r=0.1, g=0.1, b=0.25, a=0.5},
    pipe_idle = {r=0.3, g=0.3, b=0.5, a=0.8},
    pipe_powered = {r=0.2, g=0.8, b=1.0, a=1}, -- Cyan brillante
    start_node = {r=0.1, g=1.0, b=0.1, a=1}, -- Verde
    end_node = {r=1.0, g=0.2, b=0.2, a=1}, -- Rojo
    text_title = {r=1, g=1, b=1, a=1},
    text_info = {r=0.8, g=0.8, b=1.0, a=0.9},
}

-- Tile Types: 1=line, 2=corner
local TILE_TYPES = { LINE = 1, CORNER = 2 }

-- ============================================================================
-- TIMER SYSTEM (reused from other minigames)
-- ============================================================================
local SimpleTimer = {}
SimpleTimer.activeTimers = {}
SimpleTimer.nextId = 1
function SimpleTimer:addTimer(duration, callback)
    local id = self.nextId; self.nextId = self.nextId + 1
    self.activeTimers[id] = { callback = callback, duration = duration, elapsed = 0 }
    return id
end
function SimpleTimer:removeTimer(id) self.activeTimers[id] = nil end
function SimpleTimer:update()
    local toRemove = {}
    for id, timer in pairs(self.activeTimers) do
        timer.elapsed = timer.elapsed + 1
        if timer.elapsed >= timer.duration then
            if timer.callback then pcall(timer.callback) end
            toRemove[id] = true
        end
    end
    for id in pairs(toRemove) do self.activeTimers[id] = nil end
end
if Events and Events.OnTick and Events.OnTick.Add then
    Events.OnTick.Add(function() SimpleTimer:update() end)
end

-- ============================================================================
-- MAIN MINIGAME WINDOW
-- ============================================================================
local MiniGameCircuitWindow = ISPanel:derive("MiniGameCircuitWindow")

function MiniGameCircuitWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.player = player
    o.backgroundColor = THEME.background
    o.borderColor = THEME.border
    o.moveWithMouse = true
    
    o.usbType = usbType
    o.difficulty = difficulty
    o.laptopItem = laptopItem
    o.usbData = usbData
    
    o.gridSize = GRID_SIZES[difficulty] or 5
    o.timeLimit = TIME_LIMITS[difficulty] or 45
    o.timeLeft = o.timeLimit
    o.gameActive = false
    o.grid = {}
    o.buttons = {}
    o.startNode = {x=1, y=1}
    o.endNode = {x=1, y=1}
    o.resultProcessed = false
    o.flashTick = 0
    o.scanLineY = 0
    o.pulsePhase = 0
    o.victoryFlash = 0
    
    o:generateGrid()
    return o
end

function MiniGameCircuitWindow:createChildren()
    self.closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    self.startButton = ISButton:new((self.width - 120) / 2, self.height - 55, 120, 45, "START", self, self.onStart)
    self.startButton.borderColor = {r=0.8, g=0.1, b=0.8, a=1}
    self.startButton.backgroundColor = {r=0.2, g=0.05, b=0.2, a=0.9}
    self.startButton.backgroundColorMouseOver = {r=0.8, g=0.1, b=0.8, a=0.9}
    self.startButton:initialise()
    self:addChild(self.startButton)

    -- Calcular espacio disponible para el grid usando GRID_FILL_PERCENT
    local titleSpace = 50       -- Espacio reservado para el título
    local startButtonSpace = 60 -- Espacio reservado para el botón START
    local availableHeight = self.height - titleSpace - startButtonSpace
    local availableWidth = self.width - 40
    
    -- Aplicar el porcentaje de llenado del grid
    local gridFillPercent = tonumber(GRID_FILL_PERCENT) or 70
    gridFillPercent = math.max(50, math.min(90, gridFillPercent))  -- Límites: 50-90%
    
    local targetGridSize = math.min(availableWidth, availableHeight) * (gridFillPercent / 100)
    local buttonSize = math.floor(targetGridSize / self.gridSize)
    
    local gridWidth = self.gridSize * buttonSize
    local gridHeight = self.gridSize * buttonSize
    local gridStartX = (self.width - gridWidth) / 2
    
    -- Centrar verticalmente el grid en el espacio disponible
    local gridStartY = titleSpace + ((availableHeight - gridHeight) / 2)

    for y = 1, self.gridSize do
        self.buttons[y] = {}
        for x = 1, self.gridSize do
            local btn = ISButton:new(gridStartX + (x-1)*buttonSize, gridStartY + (y-1)*buttonSize, buttonSize, buttonSize, "", self, self.onTileClick)
            btn.gridX = x
            btn.gridY = y
            btn:initialise()
            self:addChild(btn)
            self.buttons[y][x] = btn
        end
    end
end

function MiniGameCircuitWindow:onStart()
    self.gameActive = true
    self.timeLeft = self.timeLimit
    self.startButton:setVisible(false)
    self:startTimer()
    self:playSound("UI_Menu_OS_Start")
end

function MiniGameCircuitWindow:cancelTimer(fieldName)
    if not fieldName then return end
    local timerId = self[fieldName]
    if timerId then
        SimpleTimer:removeTimer(timerId)
        self[fieldName] = nil
    end
end

function MiniGameCircuitWindow:startTimer()
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

function MiniGameCircuitWindow:onTimeUp()
    self.gameActive = false
    self:playSound("UI_Menu_OS_Exit")
    self:processFinalResult(false)
end

function MiniGameCircuitWindow:onTileClick(button)
    if not self.gameActive then return end
    local x, y = button.gridX, button.gridY
    local tile = self.grid[y][x]
    
    if tile.type == TILE_TYPES.LINE then
        tile.rotation = (tile.rotation + 1) % 2
    elseif tile.type == TILE_TYPES.CORNER then
        tile.rotation = (tile.rotation + 1) % 4
    end
    
    self:playSound("UI_Menu_OS_Select")
    self:checkWinCondition()
end

function MiniGameCircuitWindow:onClose()
    if self.gameActive then
        self:processFinalResult(false)
    end
    self:clearAllTimers()
    self:setVisible(false)
    self:removeFromUIManager()
end

function MiniGameCircuitWindow:clearAllTimers()
    if self.timerId then SimpleTimer:removeTimer(self.timerId); self.timerId = nil end
end

function MiniGameCircuitWindow:processFinalResult(success)
    if self.resultProcessed then return end
    self.resultProcessed = true
    self.gameActive = false
    self:clearAllTimers()

    if isClient() and self.laptopItem and not success then
        sendClientCommand(self.player, "GVDrive", "IncrementFailureCount", { laptop = self.laptopItem })
    end

    if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
        GVDrive_Utils.applyMinigameResult(self.player, self.laptopItem, self.usbType, self.difficulty, success)
    end

    if success then
        self:playSound("UI_Menu_OS_Success")
    else
        self:playSound("UI_Menu_OS_Failure")
    end

    SimpleTimer:addTimer(120, function() self:onClose() end)
end

function MiniGameCircuitWindow:playSound(soundName)
    if self.player and soundName then
        if self.player.playSoundLocal then
            self.player:playSoundLocal(soundName)
        elseif getPlayer() and getPlayer().playSoundLocal then
            getPlayer():playSoundLocal(soundName)
        else
            local sm = getSoundManager()
            if sm and sm.playUISound then pcall(function() sm:playUISound(soundName) end) end
        end
    end
end

-- ============================================================================
-- GAME LOGIC
-- ============================================================================

function MiniGameCircuitWindow:generateGrid()
    -- 1. Initialize grid with empty data
    for y = 1, self.gridSize do
        self.grid[y] = {}
        for x = 1, self.gridSize do
            self.grid[y][x] = { type = 0, rotation = 0, powered = false }
        end
    end

    -- 2. Define start and end points
    self.startNode = {x = 1, y = ZombRand(1, self.gridSize + 1)}
    self.endNode = {x = self.gridSize, y = ZombRand(1, self.gridSize + 1)}

    -- 3. Carve a guaranteed solvable path using randomized DFS
    local path = {}
    local visited = {}
    local function carvePath(x, y)
        visited[y .. "," .. x] = true
        table.insert(path, {x=x, y=y})

        if x == self.endNode.x and y == self.endNode.y then
            return true
        end

        local directions = {{0, -1}, {0, 1}, {-1, 0}, {1, 0}} -- Up, Down, Left, Right
        for i = #directions, 2, -1 do
            local j = ZombRand(i + 1)
            directions[i], directions[j] = directions[j], directions[i]
        end

        for _, dir in ipairs(directions) do
            local nx, ny = x + dir[1], y + dir[2]
            if nx >= 1 and nx <= self.gridSize and ny >= 1 and ny <= self.gridSize and not visited[ny .. "," .. nx] then
                if carvePath(nx, ny) then
                    return true
                end
            end
        end

        table.remove(path)
        return false
    end

    carvePath(self.startNode.x, self.startNode.y)

    -- 4. Convert the path into tiles and rotations
    for i = 1, #path do
        local p = path[i]
        local prev = path[i-1]
        local next = path[i+1]
        local tile = self.grid[p.y][p.x]

        if not prev or not next then -- Start or End node
            tile.type = TILE_TYPES.LINE
            if p.x == 1 or p.x == self.gridSize then tile.rotation = 1 else tile.rotation = 0 end
        else
            local dx1, dy1 = p.x - prev.x, p.y - prev.y
            local dx2, dy2 = next.x - p.x, next.y - p.y

            if dx1 == dx2 and dy1 == dy2 then -- Straight line
                tile.type = TILE_TYPES.LINE
                tile.rotation = (dy1 ~= 0) and 0 or 1
            else -- Corner
                tile.type = TILE_TYPES.CORNER
                if (dx1 == 0 and dy1 == -1 and dx2 == 1 and dy2 == 0) or (dx1 == -1 and dy1 == 0 and dx2 == 0 and dy2 == 1) then tile.rotation = 1
                elseif (dx1 == 1 and dy1 == 0 and dx2 == 0 and dy2 == 1) or (dx1 == 0 and dy1 == -1 and dx2 == -1 and dy2 == 0) then tile.rotation = 2
                elseif (dx1 == 0 and dy1 == 1 and dx2 == -1 and dy2 == 0) or (dx1 == 1 and dy1 == 0 and dx2 == 0 and dy2 == -1) then tile.rotation = 3
                else tile.rotation = 0
                end
            end
        end
    end

    -- 5. Fill remaining empty cells and randomize all rotations
    for y = 1, self.gridSize do
        for x = 1, self.gridSize do
            local tile = self.grid[y][x]
            if tile.type == 0 then
                tile.type = ZombRand(2) == 1 and TILE_TYPES.LINE or TILE_TYPES.CORNER
            end
            tile.rotation = ZombRand(4)
        end
    end
end

function MiniGameCircuitWindow:checkWinCondition()
    -- Pathfinding (BFS) to check for a complete circuit
    for y = 1, self.gridSize do
        for x = 1, self.gridSize do
            self.grid[y][x].powered = false
        end
    end

    local q = {self.startNode}
    self.grid[self.startNode.y][self.startNode.x].powered = true
    local head = 1

    while head <= #q do
        local curr = q[head]
        head = head + 1

        local connections = self:getConnections(curr.x, curr.y)
        for _, conn in ipairs(connections) do
            local nx, ny = conn.x, conn.y
            if nx >= 1 and nx <= self.gridSize and ny >= 1 and ny <= self.gridSize and not self.grid[ny][nx].powered then
                local neighborConnections = self:getConnections(nx, ny)
                for _, nc in ipairs(neighborConnections) do
                    if nc.x == curr.x and nc.y == curr.y then
                        self.grid[ny][nx].powered = true
                        table.insert(q, {x = nx, y = ny})
                        break
                    end
                end
            end
        end
    end

    if self.grid[self.endNode.y][self.endNode.x].powered then
        self.victoryFlash = 60  -- Start victory animation
        self:processFinalResult(true)
    end
end

function MiniGameCircuitWindow:getConnections(x, y)
    local tile = self.grid[y][x]
    local connections = {}
    if tile.type == TILE_TYPES.LINE then
        if tile.rotation == 0 then -- Vertical
            table.insert(connections, {x=x, y=y-1}); table.insert(connections, {x=x, y=y+1})
        else -- Horizontal
            table.insert(connections, {x=x-1, y=y}); table.insert(connections, {x=x+1, y=y})
        end
    elseif tile.type == TILE_TYPES.CORNER then
        if tile.rotation == 0 then -- Up-Right
            table.insert(connections, {x=x, y=y-1}); table.insert(connections, {x=x+1, y=y})
        elseif tile.rotation == 1 then -- Right-Down
            table.insert(connections, {x=x+1, y=y}); table.insert(connections, {x=x, y=y+1})
        elseif tile.rotation == 2 then -- Down-Left
            table.insert(connections, {x=x, y=y+1}); table.insert(connections, {x=x-1, y=y})
        else -- Left-Up
            table.insert(connections, {x=x-1, y=y}); table.insert(connections, {x=x, y=y-1})
        end
    end
    return connections
end

-- ============================================================================
-- RENDER FUNCTION
-- ============================================================================

function MiniGameCircuitWindow:render()
    ISPanel.render(self)
    
    -- Update animation counters
    self.pulsePhase = (self.pulsePhase + 0.05) % (2 * math.pi)
    self.scanLineY = (self.scanLineY + 2) % (self.height + 40)
    if self.victoryFlash > 0 then self.victoryFlash = self.victoryFlash - 1 end
    
    -- Draw background and border
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    
    -- Cyberpunk scan line effect
    local scanY = self.scanLineY - 20
    if scanY >= 0 and scanY < self.height then
        self:drawRect(0, scanY, self.width, 3, 0.15, 0.8, 0.1, 0.8)
    end
    
    -- Victory flash overlay
    if self.victoryFlash > 0 then
        local flashAlpha = (self.victoryFlash / 60) * 0.3
        self:drawRect(0, 0, self.width, self.height, flashAlpha, 0.2, 1, 0.2)
    end
    
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
    self:drawRectBorder(2, 2, self.width-4, self.height-4, self.borderColor.a * 0.5, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    -- Title
    local title = "CIRCUIT TRACER"
    self:drawTextCentre(title, self.width / 2, 10, THEME.text_title.r, THEME.text_title.g, THEME.text_title.b, THEME.text_title.a, UIFont.Large)

    -- Timer
    if self.gameActive then
        local timeText = string.format("TIME: %ds", math.ceil(self.timeLeft))
        self:drawTextRight(timeText, self.width - 10, 35, THEME.text_info.r, THEME.text_info.g, THEME.text_info.b, THEME.text_info.a, UIFont.Small)
    end

    -- Draw Grid
    for y = 1, self.gridSize do
        for x = 1, self.gridSize do
            local btn = self.buttons[y][x]
            local tile = self.grid[y][x]
            self:drawRect(btn:getX(), btn:getY(), btn:getWidth(), btn:getHeight(), THEME.grid_background.a, THEME.grid_background.r, THEME.grid_background.g, THEME.grid_background.b)
            self:drawTile(btn, tile)
        end
    end
end

function MiniGameCircuitWindow:drawTile(button, tile)
    local x, y, w, h = button:getX(), button:getY(), button:getWidth(), button:getHeight()
    local cx, cy = x + w / 2, y + h / 2
    
    -- Animated pulse effect for powered pipes
    local pipeColor = THEME.pipe_idle
    if tile.powered then
        local pulse = 0.7 + 0.3 * math.sin(self.pulsePhase)
        pipeColor = {
            r = THEME.pipe_powered.r * pulse,
            g = THEME.pipe_powered.g * pulse,
            b = THEME.pipe_powered.b,
            a = THEME.pipe_powered.a
        }
    end
    
    local thickness = math.max(2, w / 8)

    if tile.type == TILE_TYPES.LINE then
        if tile.rotation == 0 then -- Vertical
            self:drawRect(cx - thickness / 2, y, thickness, h, pipeColor.a, pipeColor.r, pipeColor.g, pipeColor.b)
        else -- Horizontal
            self:drawRect(x, cy - thickness / 2, w, thickness, pipeColor.a, pipeColor.r, pipeColor.g, pipeColor.b)
        end
    elseif tile.type == TILE_TYPES.CORNER then
        local halfW, halfH = w / 2, h / 2
        if tile.rotation == 0 then -- Up-Right
            self:drawRect(cx - thickness / 2, y, thickness, halfH + thickness/2, pipeColor.a, pipeColor.r, pipeColor.g, pipeColor.b)
            self:drawRect(cx - thickness/2, cy - thickness / 2, halfW + thickness/2, thickness, pipeColor.a, pipeColor.r, pipeColor.g, pipeColor.b)
        elseif tile.rotation == 1 then -- Right-Down
            self:drawRect(cx - thickness / 2, cy - thickness/2, halfW + thickness/2, thickness, pipeColor.a, pipeColor.r, pipeColor.g, pipeColor.b)
            self:drawRect(cx - thickness / 2, cy - thickness/2, thickness, halfH + thickness/2, pipeColor.a, pipeColor.r, pipeColor.g, pipeColor.b)
        elseif tile.rotation == 2 then -- Down-Left
            self:drawRect(x, cy - thickness / 2, halfW + thickness/2, thickness, pipeColor.a, pipeColor.r, pipeColor.g, pipeColor.b)
            self:drawRect(cx - thickness / 2, cy - thickness/2, thickness, halfH + thickness/2, pipeColor.a, pipeColor.r, pipeColor.g, pipeColor.b)
        else -- Left-Up
            self:drawRect(x, cy - thickness / 2, halfW + thickness/2, thickness, pipeColor.a, pipeColor.r, pipeColor.g, pipeColor.b)
            self:drawRect(cx - thickness / 2, y, thickness, halfH + thickness/2, pipeColor.a, pipeColor.r, pipeColor.g, pipeColor.b)
        end
    end
    
    -- Draw start/end nodes with glow effect
    if self.startNode.x == button.gridX and self.startNode.y == button.gridY then
        local glow = 0.3 + 0.2 * math.sin(self.pulsePhase * 2)
        self:drawRect(x, y, w, h, glow, THEME.start_node.r, THEME.start_node.g, THEME.start_node.b)
        self:drawRectBorder(x, y, w, h, 0.8, THEME.start_node.r, THEME.start_node.g, THEME.start_node.b)
    elseif self.endNode.x == button.gridX and self.endNode.y == button.gridY then
        local glow = 0.3 + 0.2 * math.sin(self.pulsePhase * 2)
        self:drawRect(x, y, w, h, glow, THEME.end_node.r, THEME.end_node.g, THEME.end_node.b)
        self:drawRectBorder(x, y, w, h, 0.8, THEME.end_node.r, THEME.end_node.g, THEME.end_node.b)
    end
end

-- ============================================================================
-- GLOBAL FUNCTION
-- ============================================================================
function MiniGame_Circuit(widthPct, heightPct, usbType, difficulty, laptopItem, usbData)
    local player = getPlayer()
    if not player then return end

    -- Usar configuración de porcentajes
    local windowWidthPct = tonumber(WINDOW_WIDTH_PERCENT) or 35
    local windowHeightPct = tonumber(WINDOW_HEIGHT_PERCENT) or 55
    
    -- Validar rangos
    windowWidthPct = math.max(20, math.min(80, windowWidthPct))
    windowHeightPct = math.max(30, math.min(90, windowHeightPct))
    
    local screenW, screenH = getCore():getScreenWidth(), getCore():getScreenHeight()
    local width = math.floor(screenW * (windowWidthPct / 100))
    local height = math.floor(screenH * (windowHeightPct / 100))
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2

    local window = MiniGameCircuitWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData)
    window:initialise()
    window:addToUIManager()
    window:bringToTop()
    return window
end
