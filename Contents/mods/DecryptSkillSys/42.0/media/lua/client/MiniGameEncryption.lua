-- MiniGameEncryption.lua - Encryption Cracker Minigame v1.5.14
-- Mastermind-style deduction game where players crack hex codes
-- MEJORAS v1.5.14:
-- ✅ Interlineado 24px (2.0x) para mejor legibilidad
-- ✅ +3 intentos en Easy/Moderate para mejor progresión
-- ✅ Color gradient por cercanía (verde→amarillo→naranja→rojo)
-- ✅ Animaciones de submit (shake + flash)
-- ✅ Sound feedback con pitch variable

print("[DecryptSkillSys] Loading MiniGameEncryption.lua v1.5.15 - FUN & BALANCED Encryption Cracker")

-- ============================================================================
-- DEBUG & RELOAD FUNCTIONS
-- ============================================================================
function ReloadMiniGameEncryption()
    print("[DEBUG] Reloading MiniGameEncryption system...")
    package.loaded["client/MiniGameEncryption"] = nil
    local success, result = pcall(require, "client/MiniGameEncryption")
    if success then
        print("[DEBUG] MiniGameEncryption reloaded successfully!")
    else
        print("[DEBUG] Failed to reload MiniGameEncryption: " .. tostring(result))
    end
end

function TestEncryptionCracker(difficulty)
    difficulty = difficulty or "Easy"
    print("[DEBUG] Testing MiniGameEncryption with difficulty: " .. difficulty)
    if _G.MiniGame_Encryption then
        return _G.MiniGame_Encryption(nil, nil, "TestEncryption", difficulty, nil, {skill="TestEncryption", difficulty_english=difficulty, displayName="Test USB"})
    else
        print("[DEBUG] MiniGame_EncryptionCracker function not available. Try ReloadMiniGameEncryption() first.")
    end
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

-- ========== WINDOW CONFIGURATION ==========
local WINDOW_WIDTH_PERCENT = 22
local WINDOW_HEIGHT_PERCENT = 40
local TITLE_TYPEWRITER_DELAY = 3

-- ========== SPACING CONSTANTS (v1.5.14 - INTERLINEADO 2.0x) ==========
local LINE_HEIGHT = 24        -- Interlineado principal (antes: 18px)
local TITLE_SPACING = 30      -- Después de títulos principales
local SECTION_SPACING = 36    -- Entre secciones completas
local SYMBOL_SPACING = 20     -- Entre símbolos de feedback

-- ========== GAME SETTINGS (v1.5.15 - BALANCED FOR FUN) ==========
local KEY_LENGTHS = { Easy = 4, Moderate = 5, Expert = 6 }  -- +1 dígito en todas
local MAX_ATTEMPTS = { Easy = 18, Moderate = 15, Expert = 12 }  -- +3 intentos para balance
local TIME_LIMITS = { Easy = 150, Moderate = 120, Expert = 90 }  -- +30s más tiempo
local ALLOW_DUPLICATES = { Easy = false, Moderate = false, Expert = true }
local FEEDBACK_DETAIL = { Easy = "full", Moderate = "partial", Expert = "minimal" }
local HINT_THRESHOLDS = { Easy = {5, 10}, Moderate = {8, 13}, Expert = {} }  -- Intentos para hints

-- ========== THEME COLORS (Tema CRT Verde Consistente con Fallout/UI) ==========
local THEME = {
    -- Colores principales (CRT Verde)
    background = {r=0.05, g=0.2, b=0.05, a=0.9}, -- Verde oscuro como Fallout
    border = {r=0.2, g=1, b=0.2, a=1}, -- Verde brillante como Fallout
    flash = {r=0.2, g=1, b=0.2}, -- Verde para flash effects
    
    -- UI Components
    input_bg = {r=0.1, g=0.3, b=0.1, a=0.8}, -- Verde más claro para inputs
    input_border = {r=0.2, g=0.6, b=0.2, a=1},
    button_hex = {r=0.05, g=0.25, b=0.05, a=0.9}, -- Botones hex verde oscuro
    button_hex_hover = {r=0.1, g=0.5, b=0.1, a=1}, -- Hover verde más brillante
    
    -- Feedback colors (manteniendo la lógica existente pero ajustando tonos)
    correct_pos = {r=0.2, g=1.0, b=0.2, a=1}, -- ✓ Verde brillante
    correct_char = {r=0.2, g=0.8, b=1.0, a=1}, -- ○ Cian para contraste
    incorrect = {r=0.6, g=0.3, b=0.3, a=1}, -- ✗ Rojo tenue
    
    -- Text colors (verde compatible)
    text_title = {r=0.2, g=1, b=0.2, a=1}, -- Verde brillante para títulos
    text_info = {r=0.7, g=0.9, b=0.7, a=0.9}, -- Verde claro para info
    text_highlight = {r=0.8, g=1, b=0.8, a=1}, -- Verde muy claro para highlights
    
    -- Color gradients por cercanía (verdes)
    gradient_excellent = {r=0.2, g=1, b=0.2, a=1},   -- 75%+ Verde brillante
    gradient_good = {r=0.5, g=1, b=0.2, a=1},        -- 50-75% Verde-amarillo
    gradient_fair = {r=0.8, g=0.8, b=0.2, a=1},      -- 25-50% Amarillo tenue
    gradient_poor = {r=0.8, g=0.4, b=0.2, a=1},      -- 0-25% Naranja tenue
}

-- ========== HEX CHARACTERS ==========
local HEX_CHARS = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}

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
local MiniGameEncryptionWindow = ISPanel:derive("MiniGameEncryptionWindow")

function MiniGameEncryptionWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData)
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
    o.keyLength = KEY_LENGTHS[difficulty] or 3
    o.maxAttempts = MAX_ATTEMPTS[difficulty] or 15
    o.timeLimit = TIME_LIMITS[difficulty] or 120
    o.allowDuplicates = ALLOW_DUPLICATES[difficulty] or false
    o.feedbackDetail = FEEDBACK_DETAIL[difficulty] or "full"
    
    o.secretKey = {}
    o.currentInput = {}
    o.attempts = {}
    o.attemptsRemaining = o.maxAttempts
    o.timeLeft = o.timeLimit
    o.gameActive = false
    o.resultProcessed = false
    
    -- v1.5.15: Hint system y tracking
    o.hintsRevealed = {}  -- Posiciones reveladas como hint
    o.bestAttempt = nil   -- Mejor intento hasta ahora
    o.bestScore = 0       -- Score del mejor intento (chars correctos)
    
    -- UI state
    o.hexButtons = {}
    o.inputDisplay = {}
    o.titleText = "ENCRYPTION CRACKER"
    o.titleCharsShown = 0
    o.titleAccumulator = 0
    o.titleTypewriterDelay = TITLE_TYPEWRITER_DELAY
    
    -- ✨ CRT Effects (optimizados para rendimiento)
    o.scanLineY = 0
    o.scanLineSpeed = 1.5 -- Velocidad optimizada
    o.flashTicks = 0
    o.flashColor = THEME.flash
    o.shakeTicks = 0
    o.baseX = x
    o.baseY = y
    
    -- v1.5.14: Animaciones de submit (optimizadas)
    o.submitShake = 0
    o.submitFlash = 0
    o.submitSuccess = false
    
    return o
end

function MiniGameEncryptionWindow:generateSecretKey()
    self.secretKey = {}
    self.hintsRevealed = {}  -- Reset hints
    local used = {}
    
    for i = 1, self.keyLength do
        local char
        repeat
            char = HEX_CHARS[ZombRand(1, #HEX_CHARS + 1)]
        until self.allowDuplicates or not used[char]
        
        used[char] = true
        table.insert(self.secretKey, char)
    end
end

function MiniGameEncryptionWindow:calculateFeedback(guess)
    local feedback = {}
    local secretUsed = {}
    local guessUsed = {}
    
    -- First pass: mark correct positions
    for i = 1, #guess do
        if guess[i] == self.secretKey[i] then
            feedback[i] = "correct_pos" -- ✓
            secretUsed[i] = true
            guessUsed[i] = true
        end
    end
    
    -- Second pass: mark correct characters in wrong positions
    for i = 1, #guess do
        if not guessUsed[i] then
            local found = false
            for j = 1, #self.secretKey do
                if not secretUsed[j] and guess[i] == self.secretKey[j] then
                    feedback[i] = "correct_char" -- ○
                    secretUsed[j] = true
                    found = true
                    break
                end
            end
            if not found then
                feedback[i] = "incorrect" -- ✗
            end
        end
    end
    
    return feedback
end

-- v1.5.15: Sistema de hints progresivos
function MiniGameEncryptionWindow:checkAndRevealHint()
    local thresholds = HINT_THRESHOLDS[self.difficulty] or {}
    local attemptsUsed = self.maxAttempts - self.attemptsRemaining
    
    for _, threshold in ipairs(thresholds) do
        if attemptsUsed == threshold and #self.hintsRevealed < math.floor(self.keyLength / 2) then
            -- Revelar una posición que no haya sido revelada
            local availablePositions = {}
            for i = 1, self.keyLength do
                local alreadyRevealed = false
                for _, revealed in ipairs(self.hintsRevealed) do
                    if revealed == i then
                        alreadyRevealed = true
                        break
                    end
                end
                if not alreadyRevealed then
                    table.insert(availablePositions, i)
                end
            end
            
            if #availablePositions > 0 then
                local randomIndex = ZombRand(1, #availablePositions + 1)
                local posToReveal = availablePositions[randomIndex]
                table.insert(self.hintsRevealed, posToReveal)
                
                -- Notificación visual
                if self.player and self.player.Say then
                    self.player:Say("💡 HINT: Position " .. posToReveal .. " = " .. self.secretKey[posToReveal])
                end
                
                self:triggerFlash(25, {r=1, g=0.8, b=0.2})
                self:playSound("UI_Menu_OS_Success", 1.2)
                
                print("[Encryption] Hint revealed: Position " .. posToReveal .. " = " .. self.secretKey[posToReveal])
                break
            end
        end
    end
end

-- v1.5.15: Trackear mejor intento
function MiniGameEncryptionWindow:updateBestAttempt(attempt, score)
    if score > self.bestScore then
        self.bestScore = score
        self.bestAttempt = attempt
    end
end

-- v1.5.14: Color gradient basado en cercanía
function MiniGameEncryptionWindow:getColorByCorrectness(correctCount, totalLength)
    local ratio = correctCount / totalLength
    if ratio >= 0.75 then return THEME.gradient_excellent      -- 75%+ Verde
    elseif ratio >= 0.50 then return THEME.gradient_good       -- 50-75% Amarillo
    elseif ratio >= 0.25 then return THEME.gradient_fair       -- 25-50% Naranja
    else return THEME.gradient_poor end                        -- 0-25% Rojo
end

function MiniGameEncryptionWindow:createChildren()
    -- Close button
    self.closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)
    
    -- Start button (tema CRT verde)
    self.startButton = ISButton:new((self.width - 120) / 2, self.height - 55, 120, 45, "START", self, self.onStart)
    self.startButton.borderColor = THEME.border
    self.startButton.backgroundColor = {r=0.05, g=0.15, b=0.05, a=0.9}
    self.startButton.backgroundColorMouseOver = {r=0.1, g=0.5, b=0.1, a=0.9}
    self.startButton:initialise()
    self:addChild(self.startButton)
    
    -- Submit button (verde brillante)
    self.submitButton = ISButton:new((self.width - 120) / 2, self.height - 110, 120, 35, "SUBMIT", self, self.onSubmit)
    self.submitButton.borderColor = THEME.correct_pos
    self.submitButton.backgroundColor = {r=0.05, g=0.2, b=0.05, a=0.9}
    self.submitButton.backgroundColorMouseOver = {r=0.2, g=1.0, b=0.2, a=0.9}
    self.submitButton:initialise()
    self.submitButton:setVisible(false)
    self:addChild(self.submitButton)
    
    -- Clear button (rojo tenue para contraste)
    self.clearButton = ISButton:new((self.width - 120) / 2 - 70, self.height - 110, 60, 35, "CLEAR", self, self.onClear)
    self.clearButton.borderColor = {r=0.8, g=0.3, b=0.3, a=1}
    self.clearButton.backgroundColor = {r=0.2, g=0.05, b=0.05, a=0.9}
    self.clearButton.backgroundColorMouseOver = {r=0.6, g=0.2, b=0.2, a=0.9}
    self.clearButton:initialise()
    self.clearButton:setVisible(false)
    self:addChild(self.clearButton)
    
    -- Hex buttons (0-F)
    local hexButtonsPerRow = 8
    local buttonW = 30
    local buttonH = 30
    local spacing = 5
    local startX = (self.width - (hexButtonsPerRow * (buttonW + spacing))) / 2
    local startY = self.height - 200
    
    for i, char in ipairs(HEX_CHARS) do
        local row = math.floor((i - 1) / hexButtonsPerRow)
        local col = (i - 1) % hexButtonsPerRow
        local x = startX + col * (buttonW + spacing)
        local y = startY + row * (buttonH + spacing)
        
        local btn = ISButton:new(x, y, buttonW, buttonH, char, self, self.onHexButton)
        btn.hexChar = char
        btn.borderColor = THEME.input_border
        btn.backgroundColor = THEME.button_hex
        btn.backgroundColorMouseOver = THEME.button_hex_hover
        btn:initialise()
        btn:setVisible(false)
        self:addChild(btn)
        table.insert(self.hexButtons, btn)
    end
end

function MiniGameEncryptionWindow:onStart()
    self.gameActive = true
    self.timeLeft = self.timeLimit
    self.currentInput = {}
    self.attempts = {}
    self.attemptsRemaining = self.maxAttempts
    self:generateSecretKey()
    
    self.startButton:setVisible(false)
    self.submitButton:setVisible(true)
    self.clearButton:setVisible(true)
    
    for _, btn in ipairs(self.hexButtons) do
        btn:setVisible(true)
    end
    
    self:startTimer()
    
    -- ✨ FLASH Y SONIDO INICIAL (como en Fallout)
    self:triggerFlash(30, THEME.correct_pos)
    self:playSound("UI_Menu_OS_Start", 1.0)
end

function MiniGameEncryptionWindow:onHexButton(button)
    if not self.gameActive or #self.currentInput >= self.keyLength then return end
    table.insert(self.currentInput, button.hexChar)
    
    -- ✨ EFECTO VISUAL EN BOTÓN (como en Fallout)
    self:triggerFlash(5, THEME.button_hex_hover)
    self:playSound("UI_Menu_OS_Select", 1.0)
end

function MiniGameEncryptionWindow:onClear()
    self.currentInput = {}
    self:playSound("UI_Menu_OS_Select", 0.8)
end

function MiniGameEncryptionWindow:onSubmit()
    if not self.gameActive or #self.currentInput ~= self.keyLength then return end
    
    local feedback = self:calculateFeedback(self.currentInput)
    table.insert(self.attempts, {guess = table_copy(self.currentInput), feedback = feedback})
    
    -- Check win condition
    local allCorrect = true
    for _, fb in ipairs(feedback) do
        if fb ~= "correct_pos" then
            allCorrect = false
            break
        end
    end
    
    -- v1.5.14: Animaciones de submit
    self.submitShake = 15  -- Ticks de shake
    self.submitFlash = 20  -- Ticks de flash
    self.submitSuccess = allCorrect
    
    -- ✨ TRIGGER FLASH EFFECT (como en Fallout)
    if allCorrect then
        self:triggerFlash(30, THEME.correct_pos)
    else
        self:triggerFlash(20, THEME.gradient_poor)
    end
    
    -- v1.5.14: Sound feedback con pitch variable
    local correctCount = 0
    for _, fb in ipairs(feedback) do
        if fb == "correct_pos" then correctCount = correctCount + 1 end
    end
    local pitch = 0.6 + (correctCount / self.keyLength) * 0.4  -- 0.6 a 1.0
    
    if allCorrect then
        self:playSound("UI_Menu_OS_Success", 1.2)
        SimpleTimer:addTimer(30, function() self:processFinalResult(true) end)
        return
    else
        self:playSound("UI_Menu_OS_Select", pitch)
    end
    
    self.attemptsRemaining = self.attemptsRemaining - 1
    self.currentInput = {}
    
    -- v1.5.15: Trackear mejor intento
    self:updateBestAttempt(#self.attempts, correctCount)
    
    -- v1.5.15: Verificar si debe revelar hint
    self:checkAndRevealHint()
    
    if self.attemptsRemaining <= 0 then
        SimpleTimer:addTimer(30, function() self:processFinalResult(false) end)
    end
end

-- ✨ TRIGGER FLASH EFFECT (como en Fallout)
function MiniGameEncryptionWindow:triggerFlash(ticks, color)
    self.flashTicks = math.max(self.flashTicks or 0, ticks or 20)
    if color then
        self.flashColor = color
    end
end

function table_copy(t)
    local copy = {}
    for k, v in pairs(t) do copy[k] = v end
    return copy
end

function MiniGameEncryptionWindow:cancelTimer(fieldName)
    if not fieldName then return end
    local timerId = self[fieldName]
    if timerId then
        SimpleTimer:removeTimer(timerId)
        self[fieldName] = nil
    end
end

function MiniGameEncryptionWindow:startTimer()
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

function MiniGameEncryptionWindow:onTimeUp()
    self.gameActive = false
    self:playSound("UI_Menu_OS_Exit", 0.8)
    self:processFinalResult(false)
end

function MiniGameEncryptionWindow:onClose()
    if self.gameActive then
        self:processFinalResult(false)
    end
    self:clearAllTimers()
    self:setVisible(false)
    self:removeFromUIManager()
end

function MiniGameEncryptionWindow:clearAllTimers()
    self:cancelTimer("timerId")
    -- Reset effects
    self.flashTicks = 0
    self.submitShake = 0
    self.submitFlash = 0
end

function MiniGameEncryptionWindow:processFinalResult(success)
    if self.resultProcessed then return end
    self.resultProcessed = true
    self.gameActive = false
    self:clearAllTimers()
    
    -- Increment failure count if failed
    if not success and self.laptopItem then
        if isClient() then
            sendClientCommand(self.player, "GVDrive", "IncrementFailureCount", { laptop = self.laptopItem })
        else
            if LaptopSystem and LaptopSystem.incrementFailureCount then
                local newCount = LaptopSystem.incrementFailureCount(self.laptopItem)
                print("[MiniGameEncryption] Failure count incremented to: " .. tostring(newCount))
            end
        end
    end
    
    -- Apply minigame result
    if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
        GVDrive_Utils.applyMinigameResult(self.player, self.laptopItem, self.usbType, self.difficulty, success)
    end
    
    if success then
        self:playSound("UI_Menu_OS_Success", 1.0)
    else
        self:playSound("UI_Menu_OS_Failure", 0.8)
    end
    
    SimpleTimer:addTimer(120, function() self:onClose() end)
end

function MiniGameEncryptionWindow:playSound(soundName, pitch)
    if not self.player or not soundName then return end
    pitch = pitch or 1.0
    
    -- Usar DynamicSoundSystem si está disponible
    if DynamicSoundSystem and DynamicSoundSystem.playUISound then
        pcall(function() DynamicSoundSystem.playUISound(self.player, soundName, pitch) end)
        return
    end
    
    -- Fallback a método estándar
    if self.player.playSoundLocal then
        self.player:playSoundLocal(soundName)
    elseif getPlayer() and getPlayer().playSoundLocal then
        getPlayer():playSoundLocal(soundName)
    else
        local sm = getSoundManager()
        if sm and sm.playUISound then pcall(function() sm:playUISound(soundName) end) end
    end
end

function MiniGameEncryptionWindow:update()
    ISPanel.update(self)
    
    -- ✨ CRT Effects optimization
    self.scanLineY = (self.scanLineY + self.scanLineSpeed) % (self.height + 20)
    
    -- v1.5.14: Update shake animation
    if self.submitShake and self.submitShake > 0 then
        self.submitShake = self.submitShake - 1
    end
    
    -- v1.5.14: Update flash animation
    if self.submitFlash and self.submitFlash > 0 then
        self.submitFlash = self.submitFlash - 1
    end
    
    -- Flash effects decay
    if self.flashTicks and self.flashTicks > 0 then
        self.flashTicks = self.flashTicks - 1
    end
end

function MiniGameEncryptionWindow:render()
    -- ✨ SHAKE EFFECT (optimizado como en Fallout)
    local shaking = self.submitShake and self.submitShake > 0
    local originalX, originalY
    
    if shaking then
        originalX = self:getX()
        originalY = self:getY()
        self.baseX = self.baseX or originalX
        self.baseY = self.baseY or originalY
        local strength = math.max(1, math.floor(self.submitShake / 6) + 1)
        local offsetX = math.floor(((ZombRand(0, 3) - 1)) * strength)
        local offsetY = math.floor(((ZombRand(0, 3) - 1)) * strength)
        self:setX(self.baseX + offsetX)
        self:setY(self.baseY + offsetY)
    end
    
    ISPanel.render(self)
    
    -- Restaurar posición después del shake
    if shaking then
        self:setX(originalX)
        self:setY(originalY)
        if self.submitShake == 0 then
            self.baseX = originalX
            self.baseY = originalY
        end
    end
    
    -- ✨ EFECTO CRT VERDE (como en Fallout)
    -- Overlay verde translúcido
    local crtGreen = {r=0, g=0.2, b=0, a=0.1}
    self:drawRect(0, 0, self.width, self.height, crtGreen.a, crtGreen.r, crtGreen.g, crtGreen.b)
    
    -- Líneas de escaneo horizontales (optimizadas)
    for y = 0, self.height, 4 do
        self:drawRect(0, y, self.width, 1, 0.08, 0, 0.3, 0)
    end
    
    -- Scan line animado (como en Fallout)
    if self.scanLineY then
        local scanY = math.floor(self.scanLineY)
        if scanY >= 0 and scanY < self.height then
            self:drawRect(0, scanY, self.width, 8, 0.15, 0.1, 0.8, 0.1)
        end
    end
    
    -- ✨ BORDES CRT VERDES (doble borde como Fallout)
    local borderGreen = THEME.border
    self:drawRectBorder(0, 0, self.width, self.height, borderGreen.a, borderGreen.r, borderGreen.g, borderGreen.b)
    self:drawRectBorder(1, 1, self.width-2, self.height-2, borderGreen.a * 0.5, borderGreen.r, borderGreen.g, borderGreen.b)
    
    -- ✨ FLASH EFFECTS (optimizados)
    if self.flashTicks and self.flashTicks > 0 then
        local fc = self.flashColor or THEME.flash
        local flashAlpha = math.min(0.3, 0.1 + (self.flashTicks / 40))
        self:drawRect(0, 0, self.width, self.height, flashAlpha, fc.r, fc.g, fc.b)
        self:drawRectBorder(0, 0, self.width, self.height, flashAlpha + 0.1, fc.r, fc.g, fc.b)
    end
    
    -- v1.5.14: Aplicar shake effect al offset de renderizado
    local shakeOffsetX = 0
    local shakeOffsetY = 0
    if self.submitShake and self.submitShake > 0 then
        shakeOffsetX = (ZombRand(0, 3) - 1) * 2
        shakeOffsetY = (ZombRand(0, 3) - 1) * 2
    end
    
    -- v1.5.14: Flash overlay (submit feedback)
    if self.submitFlash and self.submitFlash > 0 then
        local alpha = self.submitFlash / 20 * 0.2
        if self.submitSuccess then
            self:drawRect(0, 0, self.width, self.height, alpha, THEME.correct_pos.r, THEME.correct_pos.g, THEME.correct_pos.b)
        else
            self:drawRect(0, 0, self.width, self.height, alpha, THEME.gradient_poor.r, THEME.gradient_poor.g, THEME.gradient_poor.b)
        end
    end
    
    -- ⚡ TUTORIAL: Mostrar explicación MEJORADA con interlineado 2.0
    if not self.gameActive then
        local tutY = 50
        self:drawTextCentre("= HOW TO PLAY =", self.width / 2, tutY, THEME.text_highlight.r, THEME.text_highlight.g, THEME.text_highlight.b, 1, UIFont.Medium)
        tutY = tutY + TITLE_SPACING
        
        self:drawText("Crack the " .. self.keyLength .. "-digit hex code!", 15, tutY, 0.9, 0.9, 0.9, 1, UIFont.Small)
        tutY = tutY + LINE_HEIGHT
        self:drawText("• Select hex digits to build code", 15, tutY, 0.8, 0.8, 0.8, 1, UIFont.Small)
        tutY = tutY + LINE_HEIGHT
        self:drawText("• Submit when complete", 15, tutY, 0.8, 0.8, 0.8, 1, UIFont.Small)
        tutY = tutY + SECTION_SPACING
        
        self:drawText("FEEDBACK SYMBOLS:", 15, tutY, THEME.text_highlight.r, THEME.text_highlight.g, THEME.text_highlight.b, 1, UIFont.Small)
        tutY = tutY + LINE_HEIGHT
        self:drawText("  ✓ = Correct digit, correct position", 20, tutY, THEME.correct_pos.r, THEME.correct_pos.g, THEME.correct_pos.b, 1, UIFont.Small)
        tutY = tutY + SYMBOL_SPACING
        self:drawText("  ○ = Correct digit, wrong position", 20, tutY, THEME.correct_char.r, THEME.correct_char.g, THEME.correct_char.b, 1, UIFont.Small)
        tutY = tutY + SYMBOL_SPACING
        self:drawText("  ✗ = Incorrect digit", 20, tutY, THEME.incorrect.r, THEME.incorrect.g, THEME.incorrect.b, 1, UIFont.Small)
        tutY = tutY + SECTION_SPACING
        
        self:drawTextCentre("Strategy: Use feedback to eliminate", self.width / 2, tutY, 0.7, 0.7, 1, 1, UIFont.Small)
        tutY = tutY + LINE_HEIGHT
        self:drawTextCentre("possibilities like Mastermind!", self.width / 2, tutY, 0.7, 0.7, 1, 1, UIFont.Small)
    end
    
    -- Draw stats
    if self.gameActive then
        self:drawText("TIME: " .. math.ceil(self.timeLeft) .. "s", 10, 35, THEME.text_info.r, THEME.text_info.g, THEME.text_info.b, THEME.text_info.a, UIFont.Small)
        self:drawText("ATTEMPTS: " .. self.attemptsRemaining, self.width - 140, 35, THEME.text_info.r, THEME.text_info.g, THEME.text_info.b, THEME.text_info.a, UIFont.Small)
        
        -- Draw current input
        self:drawTextCentre("CURRENT:", self.width / 2, 55, THEME.text_info.r, THEME.text_info.g, THEME.text_info.b, THEME.text_info.a, UIFont.Small)
        local inputStr = table.concat(self.currentInput, " ")
        for i = #self.currentInput + 1, self.keyLength do
            inputStr = inputStr .. " _"
        end
        self:drawTextCentre(inputStr, self.width / 2 + shakeOffsetX, 70 + shakeOffsetY, 1, 1, 1, 1, UIFont.Large)
        
        -- Draw attempts history (v1.5.15: MEJORADO con feedback individual)
        local historyY = 100
        local headerText = "HISTORY (click to copy):"
        if self.bestAttempt then
            headerText = "HISTORY - Best: " .. self.bestScore .. "/" .. self.keyLength .. " correct"
        end
        self:drawText(headerText, 20, historyY, THEME.text_info.r, THEME.text_info.g, THEME.text_info.b, THEME.text_info.a, UIFont.Small)
        historyY = historyY + 20
        
        -- Limitar a últimos 8 intentos para no llenar pantalla
        local startIdx = math.max(1, #self.attempts - 7)
        
        for i = startIdx, #self.attempts do
            local attempt = self.attempts[i]
            local correctCount = 0
            for _, fb in ipairs(attempt.feedback) do
                if fb == "correct_pos" then correctCount = correctCount + 1 end
            end
            
            -- v1.5.15: Indicador de "best attempt"
            local isBest = (i == self.bestAttempt)
            local prefix = isBest and "★ " or "  "
            self:drawText(prefix .. "#" .. i, 10, historyY, 0.7, 0.7, 0.7, 1, UIFont.Small)
            
            -- v1.5.15: DIBUJAR CADA CARÁCTER CON SU COLOR INDIVIDUAL
            local charX = 45
            for j, char in ipairs(attempt.guess) do
                local fb = attempt.feedback[j]
                local color = THEME.incorrect
                local bgAlpha = 0
                
                if fb == "correct_pos" then
                    color = THEME.correct_pos
                    bgAlpha = 0.3  -- Fondo verde para correctos
                elseif fb == "correct_char" then
                    color = THEME.correct_char
                    bgAlpha = 0.2  -- Fondo cian para "casi"
                else
                    color = THEME.incorrect
                end
                
                -- Dibujar fondo detrás del carácter
                if bgAlpha > 0 then
                    self:drawRect(charX - 2, historyY - 2, 18, 18, bgAlpha, color.r, color.g, color.b)
                end
                
                -- Dibujar carácter con su color
                self:drawText(char, charX, historyY, color.r, color.g, color.b, color.a, UIFont.Medium)
                
                charX = charX + 20
            end
            
            -- Dibujar símbolos de feedback ENCIMA (más pequeños)
            local symbolX = 45
            local symbolY = historyY - 10
            for j, fb in ipairs(attempt.feedback) do
                local symbol = ""
                if fb == "correct_pos" then
                    symbol = "✓"
                elseif fb == "correct_char" then
                    symbol = "○"
                else
                    symbol = "·"  -- Punto pequeño en vez de X
                end
                
                self:drawText(symbol, symbolX + 3, symbolY, 0.9, 0.9, 0.9, 0.7, UIFont.Small)
                symbolX = symbolX + 20
            end
            
            -- Score del intento
            local scoreText = correctCount .. "/" .. self.keyLength
            self:drawText(scoreText, charX + 10, historyY, 0.6, 0.6, 0.6, 1, UIFont.Small)
            
            historyY = historyY + 25  -- Más espacio entre líneas
        end
        
        -- v1.5.15: Mostrar hints revelados
        if #self.hintsRevealed > 0 then
            historyY = historyY + 10
            self:drawText("💡 HINTS:", 20, historyY, 1, 0.8, 0.2, 1, UIFont.Small)
            historyY = historyY + 18
            
            for _, pos in ipairs(self.hintsRevealed) do
                local hintText = "Position " .. pos .. " = " .. self.secretKey[pos]
                self:drawText(hintText, 30, historyY, 0.2, 1, 0.2, 1, UIFont.Small)
                historyY = historyY + 16
            end
        end
        
        -- Draw scan line
        if self.scanLineY >= 60 and self.scanLineY < self.height - 60 then
            self:drawRect(0, self.scanLineY, self.width, 1, 0.1, THEME.border.r, THEME.border.g, THEME.border.b)
        end
    else
        -- Game over
        if self.resultProcessed then
            local centerY = self.height / 2 - 20
            if #self.attempts > 0 then
                local won = false
                for _, fb in ipairs(self.attempts[#self.attempts].feedback) do
                    if fb ~= "correct_pos" then won = false; break end
                    won = true
                end
                
                if won then
                    self:drawTextCentre("ACCESS GRANTED", self.width / 2, centerY, THEME.correct_pos.r, THEME.correct_pos.g, THEME.correct_pos.b, THEME.correct_pos.a, UIFont.Large)
                else
                    self:drawTextCentre("ACCESS DENIED", self.width / 2, centerY, THEME.gradient_poor.r, THEME.gradient_poor.g, THEME.gradient_poor.b, THEME.gradient_poor.a, UIFont.Large)
                    local keyStr = "KEY: " .. table.concat(self.secretKey, " ")
                    self:drawTextCentre(keyStr, self.width / 2, centerY + 30, 1, 1, 1, 1, UIFont.Medium)
                end
            end
        end
    end
end

-- ============================================================================
-- GLOBAL FUNCTION
-- ============================================================================
function MiniGame_Encryption(widthPct, heightPct, usbType, difficulty, laptopItem, usbData)
    local player = getPlayer()
    if not player then return end
    
    local windowWidthPct = math.max(20, math.min(60, tonumber(WINDOW_WIDTH_PERCENT) or 25))
    local windowHeightPct = math.max(30, math.min(80, tonumber(WINDOW_HEIGHT_PERCENT) or 50))
    
    local screenW, screenH = getCore():getScreenWidth(), getCore():getScreenHeight()
    local width = math.floor(screenW * (windowWidthPct / 100))
    local height = math.floor(screenH * (windowHeightPct / 100))
    local x = (screenW - width) / 2
    local y = (screenH - height) / 2
    
    local window = MiniGameEncryptionWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData)
    window:initialise()
    window:addToUIManager()
    window:bringToTop()
    return window
end

-- ✅ ALIAS DE COMPATIBILIDAD para DecryptDrivesContextMenu
MiniGame_EncryptionCracker = MiniGame_Encryption
_G.MiniGame_EncryptionCracker = MiniGame_Encryption
print("[DecryptSkillSys] MiniGame_EncryptionCracker v1.5.15 alias registered")
print("[DecryptSkillSys] v1.5.15 FUN UPDATE: Individual char feedback, hint system, better balance, best attempt tracker!")
