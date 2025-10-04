-- MiniGameEncryption.lua - Encryption Cracker Minigame v1.5.14
-- Mastermind-style deduction game where players crack hex codes
-- MEJORAS v1.5.14:
-- ✅ Interlineado 24px (2.0x) para mejor legibilidad
-- ✅ +3 intentos en Easy/Moderate para mejor progresión
-- ✅ Color gradient por cercanía (verde→amarillo→naranja→rojo)
-- ✅ Animaciones de submit (shake + flash)
-- ✅ Sound feedback con pitch variable

print("[DecryptSkillSys] Loading MiniGameEncryption.lua v1.5.14 - Enhanced Encryption Cracker")

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

-- ========== GAME SETTINGS (v1.5.14 - +3 INTENTOS) ==========
local KEY_LENGTHS = { Easy = 3, Moderate = 4, Expert = 5 }
local MAX_ATTEMPTS = { Easy = 15, Moderate = 12, Expert = 9 }  -- +3 en Easy/Moderate
local TIME_LIMITS = { Easy = 120, Moderate = 90, Expert = 60 }
local ALLOW_DUPLICATES = { Easy = false, Moderate = false, Expert = true }
local FEEDBACK_DETAIL = { Easy = "full", Moderate = "partial", Expert = "minimal" }

-- ========== THEME COLORS ==========
local THEME = {
    background = {r=0.08, g=0.08, b=0.08, a=0.92},
    border = {r=0.9, g=0.7, b=0.1, a=1}, -- Gold
    input_bg = {r=0.15, g=0.15, b=0.15, a=0.9},
    input_border = {r=0.5, g=0.5, b=0.5, a=1},
    button_hex = {r=0.2, g=0.2, b=0.25, a=0.9},
    button_hex_hover = {r=0.3, g=0.3, b=0.4, a=1},
    correct_pos = {r=0.2, g=1.0, b=0.2, a=1}, -- ✓ Green
    correct_char = {r=1.0, g=0.8, b=0.2, a=1}, -- ○ Gold
    incorrect = {r=0.5, g=0.5, b=0.5, a=1}, -- ✗ Gray
    text_title = {r=1, g=1, b=1, a=1},
    text_info = {r=0.9, g=0.9, b=0.9, a=0.9},
    text_highlight = {r=1, g=1, b=0.2, a=1}, -- Yellow for highlights
    -- v1.5.14: Color gradients por cercanía
    gradient_excellent = {r=0.2, g=1, b=0.2, a=1},   -- 75%+ Verde
    gradient_good = {r=1, g=1, b=0.2, a=1},          -- 50-75% Amarillo
    gradient_fair = {r=1, g=0.6, b=0.2, a=1},        -- 25-50% Naranja
    gradient_poor = {r=1, g=0.2, b=0.2, a=1},        -- 0-25% Rojo
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
    
    -- UI state
    o.hexButtons = {}
    o.inputDisplay = {}
    o.titleText = "ENCRYPTION CRACKER"
    o.titleCharsShown = 0
    o.titleAccumulator = 0
    o.titleTypewriterDelay = TITLE_TYPEWRITER_DELAY
    o.scanLineY = 0
    
    -- v1.5.14: Animaciones de submit
    o.submitShake = 0
    o.submitFlash = 0
    o.submitSuccess = false
    
    return o
end

function MiniGameEncryptionWindow:generateSecretKey()
    self.secretKey = {}
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
    
    -- Start button
    self.startButton = ISButton:new((self.width - 120) / 2, self.height - 55, 120, 45, "START", self, self.onStart)
    self.startButton.borderColor = {r=0.9, g=0.7, b=0.1, a=1}
    self.startButton.backgroundColor = {r=0.15, g=0.12, b=0.05, a=0.9}
    self.startButton.backgroundColorMouseOver = {r=0.9, g=0.7, b=0.1, a=0.9}
    self.startButton:initialise()
    self:addChild(self.startButton)
    
    -- Submit button
    self.submitButton = ISButton:new((self.width - 120) / 2, self.height - 110, 120, 35, "SUBMIT", self, self.onSubmit)
    self.submitButton.borderColor = {r=0.2, g=1.0, b=0.2, a=1}
    self.submitButton.backgroundColor = {r=0.05, g=0.15, b=0.05, a=0.9}
    self.submitButton.backgroundColorMouseOver = {r=0.2, g=1.0, b=0.2, a=0.9}
    self.submitButton:initialise()
    self.submitButton:setVisible(false)
    self:addChild(self.submitButton)
    
    -- Clear button
    self.clearButton = ISButton:new((self.width - 120) / 2 - 70, self.height - 110, 60, 35, "CLEAR", self, self.onClear)
    self.clearButton.borderColor = {r=1.0, g=0.2, b=0.2, a=1}
    self.clearButton.backgroundColor = {r=0.15, g=0.05, b=0.05, a=0.9}
    self.clearButton.backgroundColorMouseOver = {r=1.0, g=0.2, b=0.2, a=0.9}
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
        btn.borderColor = {r=0.5, g=0.5, b=0.5, a=1}
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
    self:playSound("UI_Menu_OS_Start", 1.0)
end

function MiniGameEncryptionWindow:onHexButton(button)
    if not self.gameActive or #self.currentInput >= self.keyLength then return end
    table.insert(self.currentInput, button.hexChar)
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
    
    if self.attemptsRemaining <= 0 then
        SimpleTimer:addTimer(30, function() self:processFinalResult(false) end)
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
    
    -- v1.5.14: Update shake animation
    if self.submitShake and self.submitShake > 0 then
        self.submitShake = self.submitShake - 1
    end
    
    -- v1.5.14: Update flash animation
    if self.submitFlash and self.submitFlash > 0 then
        self.submitFlash = self.submitFlash - 1
    end
end

function MiniGameEncryptionWindow:render()
    ISPanel.render(self)
    
    -- v1.5.14: Aplicar shake effect al offset de renderizado
    local shakeOffsetX = 0
    local shakeOffsetY = 0
    if self.submitShake and self.submitShake > 0 then
        shakeOffsetX = (ZombRand(0, 3) - 1) * 2
        shakeOffsetY = (ZombRand(0, 3) - 1) * 2
    end
    
    -- Update animations
    self.scanLineY = (self.scanLineY + 1.5) % (self.height + 20)
    
    -- Typewriter effect
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
    self:drawTextCentre(titleToRender, self.width / 2 + shakeOffsetX, 10 + shakeOffsetY, THEME.text_title.r, THEME.text_title.g, THEME.text_title.b, THEME.text_title.a, UIFont.Large)
    
    -- v1.5.14: Flash overlay
    if self.submitFlash and self.submitFlash > 0 then
        local alpha = self.submitFlash / 20 * 0.3
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
        self:drawText("  'O' below a digit means:", 20, tutY, THEME.correct_pos.r, THEME.correct_pos.g, THEME.correct_pos.b, 1, UIFont.Small)
        tutY = tutY + SYMBOL_SPACING
        self:drawText("      Correct digit, correct position.", 25, tutY, 0.8, 0.8, 0.8, 1, UIFont.Small)
        tutY = tutY + LINE_HEIGHT
        self:drawText("  'X' below a digit means:", 20, tutY, THEME.correct_char.r, THEME.correct_char.g, THEME.correct_char.b, 1, UIFont.Small)
        tutY = tutY + SYMBOL_SPACING
        self:drawText("      Correct digit, wrong position.", 25, tutY, 0.8, 0.8, 0.8, 1, UIFont.Small)
        tutY = tutY + LINE_HEIGHT
        self:drawText("  '-' below a digit means:", 20, tutY, THEME.incorrect.r, THEME.incorrect.g, THEME.incorrect.b, 1, UIFont.Small)
        tutY = tutY + SYMBOL_SPACING
        self:drawText("      Incorrect digit.", 25, tutY, 0.8, 0.8, 0.8, 1, UIFont.Small)
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
        
        -- Draw attempts history
        local historyY = 100
        self:drawText("HISTORY:", 20, historyY, THEME.text_info.r, THEME.text_info.g, THEME.text_info.b, THEME.text_info.a, UIFont.Small)
        historyY = historyY + 25

        local attemptSpacing = 35 -- Vertical space between attempts
        local charSpacing = 25 -- Horizontal space between characters

        for i, attempt in ipairs(self.attempts) do
            -- v1.5.14: Calcular cercanía para color gradient
            local correctCount = 0
            for _, fb in ipairs(attempt.feedback) do
                if fb == "correct_pos" then correctCount = correctCount + 1 end
            end
            local attemptColor = self:getColorByCorrectness(correctCount, self.keyLength)

            local startX = 30
            for j, char in ipairs(attempt.guess) do
                local charX = startX + (j - 1) * charSpacing
                self:drawText(char, charX, historyY, attemptColor.r, attemptColor.g, attemptColor.b, attemptColor.a, UIFont.Medium)

                -- Draw feedback symbol below
                local symbol = ""
                local color = THEME.incorrect
                local fb = attempt.feedback[j]

                if fb == "correct_pos" then
                    symbol = "O"
                    color = THEME.correct_pos
                elseif fb == "correct_char" then
                    symbol = "X"
                    color = THEME.correct_char
                else
                    symbol = "-"
                    color = THEME.incorrect
                end
                
                self:drawText(symbol, charX, historyY + 15, color.r, color.g, color.b, color.a, UIFont.Small)
            end
            
            historyY = historyY + attemptSpacing
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
print("[DecryptSkillSys] MiniGame_EncryptionCracker v1.5.14 alias registered")
print("[DecryptSkillSys] v1.5.14 Improvements: Interlineado 2.0x, +3 attempts, color gradients, animations")
