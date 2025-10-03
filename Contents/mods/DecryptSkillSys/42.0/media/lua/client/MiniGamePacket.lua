-- MiniGamePacket.lua - Packet Interceptor Minigame
-- Rhythm/action game inspired by Guitar Hero and network packet inspection
-- Players must press the correct key when packets reach the interception zone

print("[DecryptSkillSys] Loading MiniGamePacket.lua - Packet Interceptor system")

-- ============================================================================
-- DEBUG & RELOAD FUNCTIONS
-- ============================================================================
function ReloadMiniGamePacket()
    print("[DEBUG] Reloading MiniGamePacket system...")
    package.loaded["client/MiniGamePacket"] = nil
    local success, result = pcall(require, "client/MiniGamePacket")
    if success then
        print("[DEBUG] MiniGamePacket reloaded successfully!")
    else
        print("[DEBUG] Failed to reload MiniGamePacket: " .. tostring(result))
    end
end

function TestPacketInterceptor(difficulty)
    difficulty = difficulty or "Easy"
    print("[DEBUG] Testing MiniGamePacket with difficulty: " .. difficulty)
    if _G.MiniGame_Packet then
        return _G.MiniGame_Packet(nil, nil, "TestPacket", difficulty, nil, {skill="TestPacket", difficulty_english=difficulty, displayName="Test USB"})
    else
        print("[DEBUG] MiniGame_Packet function not available. Try ReloadMiniGamePacket() first.")
    end
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

-- ========== WINDOW CONFIGURATION ==========
local WINDOW_WIDTH_PERCENT = 25      -- % of screen width (20-60 recommended)
local WINDOW_HEIGHT_PERCENT = 40     -- % of screen height (40-80 recommended)
local TITLE_TYPEWRITER_DELAY = 3     -- Ticks between title letters

-- ========== GAME SETTINGS ==========
local LANE_COUNTS = { Easy = 3, Moderate = 4, Expert = 5 }
local TIME_LIMITS = { Easy = 15, Moderate = 18, Expert = 20 } -- ⚡ Reducido significativamente
local PACKET_SPEEDS = { Easy = 7, Moderate = 9, Expert = 11 } -- pixels/tick (6-8x más rápido)
local SPAWN_RATES = { Easy = 50, Moderate = 45, Expert = 40 } -- ⚡ Ligeramente más espaciado
local HIT_WINDOWS = { Easy = 25, Moderate = 18, Expert = 15 } -- pixels tolerance (más generoso)
local MISS_PENALTIES = { Easy = 0, Moderate = -1, Expert = -1 } -- seconds
local PERFECT_BONUSES = { Easy = 0, Moderate = 2, Expert = 3 } -- seconds
local COMBO_MULTIPLIERS = { Easy = false, Moderate = true, Expert = true }
local SHOW_TIMING = { Easy = true, Moderate = true, Expert = false }

-- ========== THEME COLORS ==========
local THEME = {
    background = {r=0.03, g=0.03, b=0.12, a=0.9}, -- Dark blue
    border = {r=0.2, g=0.8, b=1.0, a=1}, -- Cyan
    lane_line = {r=0.1, g=0.3, b=0.5, a=0.7},
    hit_zone = {r=0.2, g=1.0, b=0.2, a=0.6}, -- Green
    packet = {r=0.8, g=0.2, b=1.0, a=0.9}, -- Magenta
    packet_text = {r=1, g=1, b=1, a=1},
    hit_perfect = {r=0.2, g=1.0, b=0.2, a=1},
    hit_good = {r=1.0, g=1.0, b=0.2, a=1},
    miss = {r=1.0, g=0.2, b=0.2, a=1},
    text_title = {r=1, g=1, b=1, a=1},
    text_info = {r=0.8, g=0.8, b=1.0, a=0.9},
}

-- ========== PACKET TYPES ==========
local PACKET_TYPES = {
    {symbol = "0x", color = {r=0.8, g=0.2, b=1.0, a=0.9}}, -- Magenta
    {symbol = ">>", color = {r=0.2, g=0.8, b=1.0, a=0.9}}, -- Cyan
    {symbol = "##", color = {r=1.0, g=0.8, b=0.2, a=0.9}}, -- Gold
    {symbol = "<<", color = {r=1.0, g=0.2, b=0.6, a=0.9}}, -- Pink
    {symbol = "**", color = {r=0.2, g=1.0, b=0.4, a=0.9}}, -- Green
}

-- ============================================================================
-- TIMER SYSTEM
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
        if timer and timer.elapsed then  -- ✅ Validación nil-safe
            timer.elapsed = timer.elapsed + 1
            if timer.elapsed >= timer.duration then
                if timer.callback then pcall(timer.callback) end
                toRemove[id] = true
            end
        else
            toRemove[id] = true  -- Remover timers corruptos
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
local MiniGamePacketWindow = ISPanel:derive("MiniGamePacketWindow")

function MiniGamePacketWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData)
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
    
    -- Game state
    o.laneCount = LANE_COUNTS[difficulty] or 3
    o.laneWidth = (width - 40) / o.laneCount  -- ✅ Calcular ancho de lane
    o.timeLimit = TIME_LIMITS[difficulty] or 60
    o.packetSpeed = PACKET_SPEEDS[difficulty] or 1.5
    o.spawnRate = SPAWN_RATES[difficulty] or 90
    o.hitWindow = HIT_WINDOWS[difficulty] or 20
    o.missPenalty = MISS_PENALTIES[difficulty] or 0
    o.perfectBonus = PERFECT_BONUSES[difficulty] or 0
    o.comboEnabled = COMBO_MULTIPLIERS[difficulty] or false
    o.showTiming = SHOW_TIMING[difficulty] or true
    
    o.timeLeft = o.timeLimit
    o.gameActive = false
    o.packets = {} -- {lane, y, typeIndex, missed}
    o.spawnCounter = 0
    o.hitZoneY = height - 150 -- Position of hit zone
    o.score = 0
    o.combo = 0
    o.maxCombo = 0
    o.hits = 0
    o.misses = 0
    o.resultProcessed = false
    
    -- ✅ PROPIEDADES PARA FEEDBACK DE RESULTADO
    o.showResult = false
    o.resultSuccess = false
    o.resultMessage = ""
    o.resultColor = THEME.hit_perfect
    
    -- Animation state
    o.scanLineY = 0
    o.flashFeedback = {} -- {lane, color, duration}
    o.hitParticles = {} -- ✨ {x, y, alpha, scale, isPerfect, lifetime}
    o.titleText = "PACKET INTERCEPTOR"
    o.titleCharsShown = 0
    o.titleAccumulator = 0
    o.titleTypewriterDelay = TITLE_TYPEWRITER_DELAY
    
    -- Input keys (1,2,3,4,5)
    o.keyBinds = {Keyboard.KEY_1, Keyboard.KEY_2, Keyboard.KEY_3, Keyboard.KEY_4, Keyboard.KEY_5}
    
    return o
end

function MiniGamePacketWindow:createChildren()
    -- Close button
    self.closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)
    
    -- Start button
    self.startButton = ISButton:new((self.width - 120) / 2, self.height - 55, 120, 45, "START", self, self.onStart)
    self.startButton.borderColor = {r=0.2, g=0.8, b=1.0, a=1}
    self.startButton.backgroundColor = {r=0.05, g=0.1, b=0.2, a=0.9}
    self.startButton.backgroundColorMouseOver = {r=0.2, g=0.8, b=1.0, a=0.9}
    self.startButton:initialise()
    self:addChild(self.startButton)
end

function MiniGamePacketWindow:onStart()
    self.gameActive = true
    self.timeLeft = self.timeLimit
    self.packets = {}
    self.score = 0
    self.combo = 0
    self.maxCombo = 0
    self.hits = 0
    self.misses = 0
    self.spawnCounter = 0
    self.flashFeedback = {}
    self.startButton:setVisible(false)
    self:startTimer()
    self:startSpawner()
    self:playSound("UI_Menu_OS_Start")
end

function MiniGamePacketWindow:cancelTimer(fieldName)
    if not fieldName then return end
    local timerId = self[fieldName]
    if timerId then
        SimpleTimer:removeTimer(timerId)
        self[fieldName] = nil
    end
end

function MiniGamePacketWindow:startTimer()
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

function MiniGamePacketWindow:startSpawner()
    self:cancelTimer("spawnerId")
    self.spawnerId = SimpleTimer:addTimer(1, function()
        if not self.gameActive then return end
        self.spawnCounter = self.spawnCounter + 1
        if self.spawnCounter >= self.spawnRate then
            self:spawnPacket()
            self.spawnCounter = 0
        end
        self:startSpawner()
    end)
end

function MiniGamePacketWindow:spawnPacket()
    local lane = ZombRand(1, self.laneCount + 1)
    local typeIndex = ZombRand(1, #PACKET_TYPES + 1)
    table.insert(self.packets, {
        lane = lane,
        y = 60, -- Start from top
        typeIndex = typeIndex,
        missed = false
    })
end

function MiniGamePacketWindow:onTimeUp()
    self.gameActive = false
    self:playSound("UI_Menu_OS_Exit")
    
    -- Calculate success based on accuracy
    local totalAttempts = self.hits + self.misses
    local accuracy = totalAttempts > 0 and (self.hits / totalAttempts) or 0
    local success = accuracy >= 0.7 -- 70% accuracy required
    
    self:processFinalResult(success)
end

function MiniGamePacketWindow:onKeyPress(key)
    if not self.gameActive then return end
    
    -- Find which lane was pressed
    local pressedLane = nil
    for i, keyCode in ipairs(self.keyBinds) do
        if key == keyCode and i <= self.laneCount then
            pressedLane = i
            break
        end
    end
    
    if not pressedLane then return end
    
    -- Check if there's a packet in the hit zone for this lane
    local hitPacket = nil
    local bestDistance = self.hitWindow + 1
    
    for i, packet in ipairs(self.packets) do
        if packet.lane == pressedLane and not packet.missed then
            local distance = math.abs(packet.y - self.hitZoneY)
            if distance < bestDistance and distance <= self.hitWindow then
                bestDistance = distance
                hitPacket = {index = i, distance = distance}
            end
        end
    end
    
    if hitPacket then
        -- HIT!
        table.remove(self.packets, hitPacket.index)
        self.hits = self.hits + 1
        
        -- Determine hit quality
        local isPerfect = hitPacket.distance <= (self.hitWindow / 3)
        local points = isPerfect and 100 or 50
        
        if self.comboEnabled then
            self.combo = self.combo + 1
            self.maxCombo = math.max(self.maxCombo, self.combo)
            points = points + (self.combo * 10)
        end
        
        self.score = self.score + points
        
        -- Add time bonus for perfect hits
        if isPerfect and self.perfectBonus > 0 then
            self.timeLeft = self.timeLeft + self.perfectBonus
        end
        
        -- ✨ ANIMACIÓN: Crear partícula visual al interceptar
        table.insert(self.hitParticles, {
            x = 100 + (pressedLane - 1) * self.laneWidth,
            y = self.hitZoneY,
            alpha = 1.0,
            scale = 1.0,
            isPerfect = isPerfect,
            lifetime = 0
        })
        
        -- Visual feedback
        local feedbackColor = isPerfect and THEME.hit_perfect or THEME.hit_good
        table.insert(self.flashFeedback, {lane = pressedLane, color = feedbackColor, duration = 15})
        
        -- 🔊 SONIDO: Reproducir sonido de intercepción
        if DynamicSoundSystem then
            if isPerfect then
                -- Sonido especial para perfect hit
                if DynamicSoundSystem.playButtonClick then
                    DynamicSoundSystem.playButtonClick(self.player, 0.8)
                end
            else
                -- Sonido normal para hit
                if DynamicSoundSystem.playButtonClick then
                    DynamicSoundSystem.playButtonClick(self.player, 0.5)
                end
            end
        else
            self:playSound("UI_Menu_OS_Select")
        end
    else
        -- MISS!
        if self.comboEnabled then
            self.combo = 0
        end
        
        -- Time penalty
        if self.missPenalty < 0 then
            self.timeLeft = self.timeLeft + self.missPenalty
        end
        
        -- Visual feedback
        table.insert(self.flashFeedback, {lane = pressedLane, color = THEME.miss, duration = 15})
        
        self:playSound("UI_Menu_OS_Failure")
    end
end

function MiniGamePacketWindow:onClose()
    -- ✅ REPRODUCIR SONIDO LAPTOP SHUTDOWN AL CERRAR
    if self.player and DynamicSoundSystem and DynamicSoundSystem.playLaptopShutdown then
        DynamicSoundSystem.playLaptopShutdown(self.player, 0.4)
        print("[MiniGamePacket] Playing laptop_shutdown.ogg")
    end
    
    if self.gameActive then
        self:processFinalResult(false)
    end
    self:clearAllTimers()
    self:setVisible(false)
    self:removeFromUIManager()
end

function MiniGamePacketWindow:clearAllTimers()
    self:cancelTimer("timerId")
    self:cancelTimer("spawnerId")
end

function MiniGamePacketWindow:processFinalResult(success)
    if self.resultProcessed then return end
    self.resultProcessed = true
    self.gameActive = false
    self:clearAllTimers()
    
    -- ✅ FEEDBACK VISUAL CLARO: Mostrar resultado grande
    self.showResult = true
    self.resultSuccess = success
    self.resultMessage = success and "DECRYPTION SUCCESS!" or "DECRYPTION FAILED!"
    self.resultColor = success and THEME.hit_perfect or THEME.miss
    
    -- ✅ MENSAJE AL JUGADOR
    if self.player then
        if success then
            self.player:Say("Packet interception successful! Score: " .. self.score)
        else
            self.player:Say("Failed to intercept packets in time.")
        end
    end
    
    -- Increment failure count if failed
    if not success and self.laptopItem then
        if isClient() then
            sendClientCommand(self.player, "GVDrive", "IncrementFailureCount", { laptop = self.laptopItem })
        else
            if LaptopSystem and LaptopSystem.incrementFailureCount then
                local newCount = LaptopSystem.incrementFailureCount(self.laptopItem)
                print("[MiniGamePacket] Failure count incremented to: " .. tostring(newCount))
            end
        end
    end
    
    -- Apply minigame result (XP, damage, etc.)
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

function MiniGamePacketWindow:playSound(soundName)
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

function MiniGamePacketWindow:prerender()
    ISPanel.prerender(self)
    
    -- Register keyboard handler
    if self.gameActive and not self.keyHandlerRegistered then
        Events.OnKeyPressed.Add(function(key) self:onKeyPress(key) end)
        self.keyHandlerRegistered = true
    end
end

function MiniGamePacketWindow:update()
    ISPanel.update(self)
    
    if not self.gameActive then return end
    
    -- Update packets
    for i = #self.packets, 1, -1 do
        local packet = self.packets[i]
        packet.y = packet.y + self.packetSpeed
        
        -- Check if packet passed hit zone (missed)
        if packet.y > self.hitZoneY + self.hitWindow and not packet.missed then
            packet.missed = true
            self.misses = self.misses + 1
            if self.comboEnabled then
                self.combo = 0
            end
        end
        
        -- Remove packets that went off screen
        if packet.y > self.height then
            table.remove(self.packets, i)
        end
    end
    
    -- Update flash feedback
    for i = #self.flashFeedback, 1, -1 do
        local flash = self.flashFeedback[i]
        flash.duration = flash.duration - 1
        if flash.duration <= 0 then
            table.remove(self.flashFeedback, i)
        end
    end
    
    -- ✨ UPDATE HIT PARTICLES
    for i = #self.hitParticles, 1, -1 do
        local p = self.hitParticles[i]
        p.lifetime = p.lifetime + 1
        p.alpha = 1.0 - (p.lifetime / 30)  -- Fade out over 30 ticks
        p.scale = 1.0 + (p.lifetime / 15)  -- Grow slightly
        p.y = p.y - 2  -- Float upward
        
        if p.lifetime > 30 then
            table.remove(self.hitParticles, i)
        end
    end
end

function MiniGamePacketWindow:render()
    ISPanel.render(self)
    
    -- Update animations
    self.scanLineY = (self.scanLineY + 2) % (self.height + 20)
    
    -- Typewriter effect for title
    if self.gameActive and self.titleCharsShown < #self.titleText then
        self.titleAccumulator = self.titleAccumulator + 1
        if self.titleAccumulator >= self.titleTypewriterDelay then
            self.titleAccumulator = 0
            self.titleCharsShown = self.titleCharsShown + 1
        end
    elseif not self.gameActive then
        self.titleCharsShown = #self.titleText
    end
    
    -- Draw title
    local titleToRender = string.sub(self.titleText, 1, self.titleCharsShown)
    self:drawTextCentre(titleToRender, self.width / 2, 10, THEME.text_title.r, THEME.text_title.g, THEME.text_title.b, THEME.text_title.a, UIFont.Large)
    
    -- Draw stats
    if self.gameActive then
        local statsY = 35
        self:drawText("TIME: " .. math.ceil(self.timeLeft) .. "s", 10, statsY, THEME.text_info.r, THEME.text_info.g, THEME.text_info.b, THEME.text_info.a, UIFont.Small)
        self:drawText("SCORE: " .. self.score, self.width - 120, statsY, THEME.text_info.r, THEME.text_info.g, THEME.text_info.b, THEME.text_info.a, UIFont.Small)
        
        if self.comboEnabled and self.combo > 1 then
            self:drawText("COMBO: x" .. self.combo, self.width / 2 - 40, statsY, 1, 1, 0.2, 1, UIFont.Medium)
        end
        
        -- Draw lanes
        local laneWidth = (self.width - 40) / self.laneCount
        for i = 1, self.laneCount do
            local laneX = 20 + (i - 1) * laneWidth
            
            -- Lane line
            self:drawRect(laneX, 60, 2, self.height - 120, THEME.lane_line.a, THEME.lane_line.r, THEME.lane_line.g, THEME.lane_line.b)
            
            -- Lane number at bottom
            self:drawTextCentre(tostring(i), laneX + laneWidth / 2, self.height - 35, THEME.text_info.r, THEME.text_info.g, THEME.text_info.b, THEME.text_info.a, UIFont.Medium)
            
            -- Flash feedback
            for _, flash in ipairs(self.flashFeedback) do
                if flash.lane == i then
                    local alpha = flash.duration / 15
                    self:drawRect(laneX, self.hitZoneY - 10, laneWidth, 60, alpha * 0.5, flash.color.r, flash.color.g, flash.color.b)
                end
            end
        end
        
        -- Draw hit zone
        self:drawRect(20, self.hitZoneY - 2, self.width - 40, 4, THEME.hit_zone.a, THEME.hit_zone.r, THEME.hit_zone.g, THEME.hit_zone.b)
        if self.showTiming then
            self:drawRect(20, self.hitZoneY - self.hitWindow, self.width - 40, 1, 0.3, 1, 1, 1)
            self:drawRect(20, self.hitZoneY + self.hitWindow, self.width - 40, 1, 0.3, 1, 1, 1)
        end
        
        -- Draw packets
        for _, packet in ipairs(self.packets) do
            local laneX = 20 + (packet.lane - 1) * laneWidth
            local packetType = PACKET_TYPES[packet.typeIndex]
            local color = packetType.color
            
            -- Packet box
            local packetW = laneWidth - 10
            local packetH = 30
            self:drawRect(laneX + 5, packet.y - packetH/2, packetW, packetH, color.a, color.r, color.g, color.b)
            self:drawRectBorder(laneX + 5, packet.y - packetH/2, packetW, packetH, 1, 1, 1, 1, 1)
            
            -- Packet symbol
            self:drawTextCentre(packetType.symbol, laneX + laneWidth / 2, packet.y - 10, THEME.packet_text.r, THEME.packet_text.g, THEME.packet_text.b, THEME.packet_text.a, UIFont.Small)
        end
        
        -- ✨ DRAW HIT PARTICLES (animación al interceptar)
        for _, p in ipairs(self.hitParticles) do
            local color = p.isPerfect and THEME.hit_perfect or THEME.hit_good
            local size = 20 * p.scale
            local halfSize = size / 2
            
            -- Círculo brillante que crece y se desvanece
            self:drawRect(p.x - halfSize, p.y - halfSize, size, size, 
                p.alpha * 0.7, color.r, color.g, color.b)
            
            -- Borde del círculo
            self:drawRectBorder(p.x - halfSize, p.y - halfSize, size, size, 
                p.alpha, color.r * 1.5, color.g * 1.5, color.b * 1.5)
            
            -- Texto flotante
            if p.isPerfect then
                self:drawTextCentre("PERFECT!", p.x, p.y - halfSize - 10, 
                    color.r, color.g, color.b, p.alpha, UIFont.Small)
            end
        end
        
        -- Draw scan line effect
        if self.scanLineY >= 60 and self.scanLineY < self.height - 60 then
            self:drawRect(20, self.scanLineY, self.width - 40, 2, 0.2, THEME.border.r, THEME.border.g, THEME.border.b)
        end
    else
        -- ✅ MENSAJE GRANDE DE VICTORIA/DERROTA
        if self.showResult and self.resultMessage then
            local centerY = self.height / 2 - 80
            
            -- Background semitransparente para el mensaje
            self:drawRect(10, centerY - 10, self.width - 20, 100, 0.8, 0.05, 0.05, 0.15)
            
            -- Mensaje grande de resultado
            self:drawTextCentre(self.resultMessage, self.width / 2, centerY + 5, 
                self.resultColor.r, self.resultColor.g, self.resultColor.b, 1, UIFont.Large)
            
            -- Línea de separación
            self:drawRect(30, centerY + 35, self.width - 60, 2, 0.5, 
                self.resultColor.r, self.resultColor.g, self.resultColor.b)
        end
        
        -- Game over stats
        if self.hits > 0 or self.misses > 0 then
            local totalAttempts = self.hits + self.misses
            local accuracy = (self.hits / totalAttempts) * 100
            local centerY = self.height / 2
            
            self:drawTextCentre("FINAL STATS", self.width / 2, centerY, THEME.text_title.r, THEME.text_title.g, THEME.text_title.b, THEME.text_title.a, UIFont.Large)
            self:drawTextCentre("Score: " .. self.score, self.width / 2, centerY + 30, THEME.text_info.r, THEME.text_info.g, THEME.text_info.b, THEME.text_info.a, UIFont.Medium)
            self:drawTextCentre("Accuracy: " .. string.format("%.1f%%", accuracy), self.width / 2, centerY + 50, THEME.text_info.r, THEME.text_info.g, THEME.text_info.b, THEME.text_info.a, UIFont.Medium)
            self:drawTextCentre("Max Combo: x" .. self.maxCombo, self.width / 2, centerY + 70, THEME.text_info.r, THEME.text_info.g, THEME.text_info.b, THEME.text_info.a, UIFont.Medium)
        end
    end
end

-- ============================================================================
-- GLOBAL FUNCTION
-- ============================================================================
function MiniGame_Packet(widthPct, heightPct, usbType, difficulty, laptopItem, usbData)
    local player = getPlayer()
    if not player then return end
    
    local windowWidthPct = math.max(20, math.min(60, tonumber(WINDOW_WIDTH_PERCENT) or 30))
    local windowHeightPct = math.max(40, math.min(80, tonumber(WINDOW_HEIGHT_PERCENT) or 60))
    
    local screenW, screenH = getCore():getScreenWidth(), getCore():getScreenHeight()
    local width = math.floor(screenW * (windowWidthPct / 100))
    local height = math.floor(screenH * (windowHeightPct / 100))
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2
    
    local window = MiniGamePacketWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData)
    window:initialise()
    window:addToUIManager()
    window:bringToTop()
    return window
end

-- ✅ ALIAS para compatibilidad con DecryptDrivesContextMenu
MiniGame_PacketInterceptor = MiniGame_Packet
_G.MiniGame_PacketInterceptor = MiniGame_Packet
