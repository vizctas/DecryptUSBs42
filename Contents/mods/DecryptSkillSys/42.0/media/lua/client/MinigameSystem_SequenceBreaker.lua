-- Sequence Breaker Minigame
-- A retro CRT-style terminal minigame where players must break through security sequences

-- Safe inheritance - only derive if MinigameWindow has derive method
if MinigameWindow and MinigameWindow.derive then
    SequenceBreaker = MinigameWindow:derive("SequenceBreaker")
else
    -- Fallback for when MinigameWindow is not fully available
    SequenceBreaker = {}
    SequenceBreaker.__index = SequenceBreaker
    print("[SequenceBreaker][WARNING] MinigameWindow.derive not available - using fallback implementation")
end

-- Game configuration
SequenceBreaker.SEQUENCE_LENGTHS = {4, 6, 8, 10, 12} -- By difficulty
SequenceBreaker.SYMBOLS = {"A", "B", "C", "D", "E", "F", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}
SequenceBreaker.INPUT_DELAY = 0.5 -- Seconds between inputs
SequenceBreaker.SEQUENCE_DISPLAY_TIME = 2.0 -- How long to show the sequence

-- CRT-style colors (Alien green with Fallout influences)
SequenceBreaker.COLORS = {
    BACKGROUND = {r = 0.0, g = 0.0, b = 0.0, a = 1.0}, -- Pure black
    TEXT_PRIMARY = {r = 0.0, g = 1.0, b = 0.0, a = 1.0}, -- Bright green
    TEXT_SECONDARY = {r = 0.2, g = 0.8, b = 0.2, a = 0.8}, -- Dim green
    TEXT_ERROR = {r = 1.0, g = 0.2, b = 0.2, a = 1.0}, -- Red for errors
    BORDER = {r = 0.0, g = 0.6, b = 0.0, a = 0.8}, -- Dark green border
    SCANLINE = {r = 0.0, g = 0.3, b = 0.0, a = 0.1}, -- Subtle scanlines
    GLITCH = {r = 0.8, g = 0.8, b = 1.0, a = 0.3} -- Blue glitch effect
}

-- Constructor
function SequenceBreaker:new()
    -- Don't call MinigameWindow:new() here - the window is created separately
    -- and passed to us. We just set up our game-specific properties.
    local o = {}
    setmetatable(o, self)
    self.__index = self

    -- Game state
    o.sequence = {}
    o.playerInput = {}
    o.currentSequenceIndex = 1
    o.gamePhase = "showing" -- "showing", "input", "complete"
    o.lastInputTime = 0
    o.displaySequenceIndex = 1
    o.sequenceDisplayTimer = 0
    o.gameStartTime = 0

    -- UI elements will be created in initialise()
    o.titleLabel = nil
    o.statusLabel = nil
    o.sequenceDisplay = nil
    o.inputDisplay = nil
    o.instructionLabel = nil
    o.progressBar = nil

    -- CRT effects
    o.scanlineOffset = 0
    o.glitchTimer = 0
    o.glitchActive = false

    -- These will be set by the controller
    o.window = nil
    o.difficulty = nil
    o.player = nil
    o.usbItem = nil

    o:initialise()
    o:instantiate()

    return o
end

-- Instantiate method (for compatibility)
function SequenceBreaker:instantiate()
    -- Nothing special needed for SequenceBreaker
end

-- Initialize the game
function SequenceBreaker:initialise()
    -- Use the existing window instead of creating new UI elements
    if not self.window then
        self:debugPrint("No window assigned to SequenceBreaker")
        return
    end

    -- Set up CRT-style appearance on the existing window
    if self.window.setAlwaysOnTop then
        pcall(function() self.window:setAlwaysOnTop(true) end)
    end
    if self.window.setCapture then
        pcall(function() self.window:setCapture(true) end)
    end

    -- Create title with CRT effect
    if ISLabel and ISLabel.new then
        local success, err = pcall(function()
            self.titleLabel = ISLabel:new(20, 15, 24, "SECURITY BREACH TERMINAL v2.1.47", 1, 1, 1, 1, UIFont.Large, true)
            if self.titleLabel and self.titleLabel.initialise then
                self.titleLabel:initialise()
            end
            if self.titleLabel and self.titleLabel.setColor then
                self.titleLabel:setColor(SequenceBreaker.COLORS.TEXT_PRIMARY.r, SequenceBreaker.COLORS.TEXT_PRIMARY.g, SequenceBreaker.COLORS.TEXT_PRIMARY.b, SequenceBreaker.COLORS.TEXT_PRIMARY.a)
            end
            if self.window.addChild then
                self.window:addChild(self.titleLabel)
            end
        end)
        if not success then
            self:debugPrint("Failed to create title label:", err)
        end
    end

    -- Status display
    if ISLabel and ISLabel.new then
        local success, err = pcall(function()
            self.statusLabel = ISLabel:new(20, 50, 18, "INITIALIZING BREACH PROTOCOL...", 1, 1, 1, 1, UIFont.Medium, true)
            if self.statusLabel and self.statusLabel.initialise then
                self.statusLabel:initialise()
            end
            if self.statusLabel and self.statusLabel.setColor then
                self.statusLabel:setColor(SequenceBreaker.COLORS.TEXT_SECONDARY.r, SequenceBreaker.COLORS.TEXT_SECONDARY.g, SequenceBreaker.COLORS.TEXT_SECONDARY.b, SequenceBreaker.COLORS.TEXT_SECONDARY.a)
            end
            if self.window.addChild then
                self.window:addChild(self.statusLabel)
            end
        end)
        if not success then
            self:debugPrint("Failed to create status label:", err)
        end
    end

    -- Sequence display area (large central area)
    local seqX = 50
    local seqY = 100
    local seqWidth = self.window.width and (self.window.width - 100) or 300
    local seqHeight = 120

    if ISLabel and ISLabel.new then
        local success, err = pcall(function()
            self.sequenceDisplay = ISLabel:new(seqX, seqY, 48, "", 1, 1, 1, 1, UIFont.Title, true)
            if self.sequenceDisplay and self.sequenceDisplay.initialise then
                self.sequenceDisplay:initialise()
            end
            if self.sequenceDisplay and self.sequenceDisplay.setColor then
                self.sequenceDisplay:setColor(SequenceBreaker.COLORS.TEXT_PRIMARY.r, SequenceBreaker.COLORS.TEXT_PRIMARY.g, SequenceBreaker.COLORS.TEXT_PRIMARY.b, SequenceBreaker.COLORS.TEXT_PRIMARY.a)
            end
            if self.window.addChild then
                self.window:addChild(self.sequenceDisplay)
            end
        end)
        if not success then
            self:debugPrint("Failed to create sequence display:", err)
        end
    end

    -- Input display
    if ISLabel and ISLabel.new then
        local success, err = pcall(function()
            self.inputDisplay = ISLabel:new(seqX, seqY + 80, 32, "", 1, 1, 1, 1, UIFont.Large, true)
            if self.inputDisplay and self.inputDisplay.initialise then
                self.inputDisplay:initialise()
            end
            if self.inputDisplay and self.inputDisplay.setColor then
                self.inputDisplay:setColor(SequenceBreaker.COLORS.TEXT_SECONDARY.r, SequenceBreaker.COLORS.TEXT_SECONDARY.g, SequenceBreaker.COLORS.TEXT_SECONDARY.b, SequenceBreaker.COLORS.TEXT_SECONDARY.a)
            end
            if self.window.addChild then
                self.window:addChild(self.inputDisplay)
            end
        end)
        if not success then
            self:debugPrint("Failed to create input display:", err)
        end
    end

    -- Instructions
    if ISLabel and ISLabel.new then
        local success, err = pcall(function()
            self.instructionLabel = ISLabel:new(20, (self.window.height and self.window.height - 80) or 220, 16, "MEMORIZE SEQUENCE - REPEAT EXACTLY", 1, 1, 1, 1, UIFont.Small, true)
            if self.instructionLabel and self.instructionLabel.initialise then
                self.instructionLabel:initialise()
            end
            if self.instructionLabel and self.instructionLabel.setColor then
                self.instructionLabel:setColor(SequenceBreaker.COLORS.TEXT_SECONDARY.r, SequenceBreaker.COLORS.TEXT_SECONDARY.g, SequenceBreaker.COLORS.TEXT_SECONDARY.b, SequenceBreaker.COLORS.TEXT_SECONDARY.a)
            end
            if self.window.addChild then
                self.window:addChild(self.instructionLabel)
            end
        end)
        if not success then
            self:debugPrint("Failed to create instruction label:", err)
        end
    end

    -- Progress indicator
    if ISLabel and ISLabel.new then
        local success, err = pcall(function()
            self.progressLabel = ISLabel:new(20, (self.window.height and self.window.height - 50) or 250, 14, "PROGRESS: [░░░░░░░░░░] 0%", 1, 1, 1, 1, UIFont.Small, true)
            if self.progressLabel and self.progressLabel.initialise then
                self.progressLabel:initialise()
            end
            if self.progressLabel and self.progressLabel.setColor then
                self.progressLabel:setColor(SequenceBreaker.COLORS.TEXT_SECONDARY.r, SequenceBreaker.COLORS.TEXT_SECONDARY.g, SequenceBreaker.COLORS.TEXT_SECONDARY.b, SequenceBreaker.COLORS.TEXT_SECONDARY.a)
            end
            if self.window.addChild then
                self.window:addChild(self.progressLabel)
            end
        end)
        if not success then
            self:debugPrint("Failed to create progress label:", err)
        end
    end

    self:debugPrint("SequenceBreaker initialized")
end

-- Start the game
function SequenceBreaker:startGame()
    -- Generate sequence based on difficulty
    self:generateSequence()

    -- Start showing sequence
    self.gamePhase = "showing"
    self.displaySequenceIndex = 1
    self.sequenceDisplayTimer = SequenceBreaker.SEQUENCE_DISPLAY_TIME
    -- Use PZ's getGameTime() if available, fallback to os.time()
    local success, gameTime = pcall(function() return getGameTime() end)
    if success and gameTime and gameTime.getWorldAgeHours then
        self.gameStartTime = gameTime:getWorldAgeHours() * 3600 -- Convert to seconds
    else
        self.gameStartTime = os.time()
    end
    self.lastInputTime = self.gameStartTime
    self:updateStatus("ANALYZING SECURITY SEQUENCE...")
    self:updateSequenceDisplay()
    self:updateProgress()

    -- Set timer for the entire game using the window's timer system
    local gameTime = self:getGameTimeLimit()
    if self.window and self.window.startTimer then
        self.timerId = self.window:startTimer(gameTime, function()
            self:completeGameTimeout(self:getTimeoutDamage())
        end)
    end

    self:debugPrint("Sequence Breaker game started with difficulty", self.difficulty)
end

-- Generate random sequence based on difficulty
function SequenceBreaker:generateSequence()
    local length = SequenceBreaker.SEQUENCE_LENGTHS[self.difficulty] or 6
    self.sequence = {}

    for i = 1, length do
        local symbolIndex = ZombRand(1, #SequenceBreaker.SYMBOLS + 1)
        table.insert(self.sequence, SequenceBreaker.SYMBOLS[symbolIndex])
    end

    self:debugPrint("Generated sequence of length", length, ":", table.concat(self.sequence, ""))
end

-- Update sequence display (shows one symbol at a time)
function SequenceBreaker:updateSequenceDisplay()
    if self.gamePhase ~= "showing" then return end

    if self.displaySequenceIndex <= #self.sequence then
        local symbol = self.sequence[self.displaySequenceIndex]
        self.sequenceDisplay:setName(symbol)
        self.displaySequenceIndex = self.displaySequenceIndex + 1
        self.sequenceDisplayTimer = SequenceBreaker.SEQUENCE_DISPLAY_TIME
    else
        -- Sequence display complete, switch to input phase
        self.gamePhase = "input"
        self.sequenceDisplay:setName("")
        self.inputDisplay:setName("")
        self.playerInput = {}
        self.currentSequenceIndex = 1
        self:updateStatus("ENTER SEQUENCE:")
        self.instructionLabel:setName("PRESS KEYS TO INPUT SEQUENCE")
    end
end

-- Update progress bar
function SequenceBreaker:updateProgress()
    local progress = 0
    if self.gamePhase == "input" then
        progress = (#self.playerInput / #self.sequence) * 100
    end

    local progressBars = math.floor(progress / 10)
    local progressStr = string.rep("█", progressBars) .. string.rep("░", 10 - progressBars)
    local progressText = string.format("PROGRESS: [%s] %d%%", progressStr, progress)

    self.progressLabel:setName(progressText)
end

-- Handle key input
function SequenceBreaker:onKeyPress(key)
    -- Let parent window handle escape key
    if self.window and self.window.onKeyPress then
        local handled = self.window:onKeyPress(key)
        if handled then return true end
    end

    if self.gamePhase ~= "input" then
        return false
    end

    -- Check input delay
    local currentTime
    local success, gameTime = pcall(function() return getGameTime() end)
    if success and gameTime and gameTime.getWorldAgeHours then
        currentTime = gameTime:getWorldAgeHours() * 3600 -- Convert to seconds
    else
        currentTime = os.time()
    end
    
    if currentTime - self.lastInputTime < SequenceBreaker.INPUT_DELAY then
        return false
    end

    -- Get key name
    local keyName = self:getKeyName(key)
    if not keyName then
        return false
    end

    -- Add to player input
    table.insert(self.playerInput, keyName)
    self.lastInputTime = currentTime

    -- Update display
    self.inputDisplay:setName(table.concat(self.playerInput, " "))
    self:updateProgress()

    -- Check if input matches sequence
    local expectedSymbol = self.sequence[#self.playerInput]
    if keyName ~= expectedSymbol then
        -- Wrong input - fail
        self:triggerGlitch()
        if self.statusLabel then
            self.statusLabel:setColor(SequenceBreaker.COLORS.TEXT_ERROR.r, SequenceBreaker.COLORS.TEXT_ERROR.g, SequenceBreaker.COLORS.TEXT_ERROR.b, SequenceBreaker.COLORS.TEXT_ERROR.a)
        end
        self:updateStatus("SEQUENCE CORRUPTED - BREACH FAILED")
        if self.instructionLabel then
            self.instructionLabel:setName("SECURITY ALERT TRIGGERED")
        end

        local damage = self:getFailureDamage()
        self:completeGameFailure(damage)
        return true
    end

    -- Check if sequence is complete
    if #self.playerInput >= #self.sequence then
        -- Success!
        self:updateStatus("BREACH SUCCESSFUL - ACCESS GRANTED")
        if self.instructionLabel then
            self.instructionLabel:setName("DECRYPTION COMPLETE")
        end

        local xpGained = self:getSuccessXP()
        self:completeGameSuccess(xpGained)
        return true
    end

    return true
end

-- Get key name from key code
function SequenceBreaker:getKeyName(key)
    local keyMap = {
        [Keyboard.KEY_A] = "A",
        [Keyboard.KEY_B] = "B",
        [Keyboard.KEY_C] = "C",
        [Keyboard.KEY_D] = "D",
        [Keyboard.KEY_E] = "E",
        [Keyboard.KEY_F] = "F",
        [Keyboard.KEY_0] = "0",
        [Keyboard.KEY_1] = "1",
        [Keyboard.KEY_2] = "2",
        [Keyboard.KEY_3] = "3",
        [Keyboard.KEY_4] = "4",
        [Keyboard.KEY_5] = "5",
        [Keyboard.KEY_6] = "6",
        [Keyboard.KEY_7] = "7",
        [Keyboard.KEY_8] = "8",
        [Keyboard.KEY_9] = "9"
    }

    return keyMap[key]
end

-- Trigger glitch effect
function SequenceBreaker:triggerGlitch()
    self.glitchActive = true
    self.glitchTimer = 0.5 -- Glitch for half second
end

-- Update method (called every frame)
function SequenceBreaker:update()
    -- Update CRT scanlines
    self.scanlineOffset = self.scanlineOffset + 0.05
    if self.scanlineOffset > 1 then
        self.scanlineOffset = 0
    end

    -- Update glitch effect
    if self.glitchActive then
        self.glitchTimer = self.glitchTimer - (1/30) -- Assuming 30 FPS
        if self.glitchTimer <= 0 then
            self.glitchActive = false
        end
    end

    -- Update sequence display timing
    if self.gamePhase == "showing" and self.sequenceDisplayTimer > 0 then
        self.sequenceDisplayTimer = self.sequenceDisplayTimer - (1/30)
        if self.sequenceDisplayTimer <= 0 then
            self:updateSequenceDisplay()
        end
    end
end

-- Render CRT-style effects
function SequenceBreaker:render()
    -- Let the window render first
    if self.window and self.window.render then
        self.window:render()
    end

    -- Draw CRT background safely
    if self.window and self.window.drawRect then
        pcall(function()
            self.window:drawRect(0, 0, self.window.width or 400, self.window.height or 300, 
                SequenceBreaker.COLORS.BACKGROUND.a,
                SequenceBreaker.COLORS.BACKGROUND.r, SequenceBreaker.COLORS.BACKGROUND.g, SequenceBreaker.COLORS.BACKGROUND.b)
        end)
    end

    -- Draw scanlines safely
    if self.window and self.window.drawRect then
        local windowHeight = self.window.height or 300
        for y = 0, windowHeight, 4 do
            local alpha = SequenceBreaker.COLORS.SCANLINE.a * (0.5 + 0.5 * math.sin(self.scanlineOffset + y * 0.1))
            pcall(function()
                self.window:drawRect(0, y, self.window.width or 400, 2, alpha,
                    SequenceBreaker.COLORS.SCANLINE.r, SequenceBreaker.COLORS.SCANLINE.g, SequenceBreaker.COLORS.SCANLINE.b)
            end)
        end
    end

    -- Draw border with CRT effect safely
    if self.window and self.window.drawRectBorder then
        pcall(function()
            self.window:drawRectBorder(0, 0, self.window.width or 400, self.window.height or 300, 3,
                SequenceBreaker.COLORS.BORDER.r, SequenceBreaker.COLORS.BORDER.g, SequenceBreaker.COLORS.BORDER.b, SequenceBreaker.COLORS.BORDER.a)
        end)
    end

    -- Draw glitch effect if active
    if self.glitchActive and self.window and self.window.drawRect then
        for i = 1, 5 do
            local y = ZombRand(0, self.window.height or 300)
            local height = ZombRand(2, 10)
            pcall(function()
                self.window:drawRect(0, y, self.window.width or 400, height, SequenceBreaker.COLORS.GLITCH.a,
                    SequenceBreaker.COLORS.GLITCH.r, SequenceBreaker.COLORS.GLITCH.g, SequenceBreaker.COLORS.GLITCH.b)
            end)
        end
    end

    -- Draw corner decorations (retro terminal style) safely
    if self.window and self.window.drawTextCentre then
        pcall(function()
            self.window:drawTextCentre(">", 20, (self.window.height or 300) - 25, 
                SequenceBreaker.COLORS.TEXT_PRIMARY.r, SequenceBreaker.COLORS.TEXT_PRIMARY.g, 
                SequenceBreaker.COLORS.TEXT_PRIMARY.b, SequenceBreaker.COLORS.TEXT_PRIMARY.a, UIFont.Small)
            self.window:drawTextCentre("READY", 45, (self.window.height or 300) - 25, 
                SequenceBreaker.COLORS.TEXT_SECONDARY.r, SequenceBreaker.COLORS.TEXT_SECONDARY.g, 
                SequenceBreaker.COLORS.TEXT_SECONDARY.b, SequenceBreaker.COLORS.TEXT_SECONDARY.a, UIFont.Small)
        end)
    end
end

-- Get game time limit based on difficulty
function SequenceBreaker:getGameTimeLimit()
    if DifficultyScaler and DifficultyScaler.scaleValue then
        return DifficultyScaler.scaleValue(30, self.difficulty, "time_limit")
    else
        return 30 -- Default time
    end
end

-- Get success XP based on difficulty
function SequenceBreaker:getSuccessXP()
    if DifficultyScaler and DifficultyScaler.calculateXP then
        return DifficultyScaler.calculateXP(25, self.difficulty, "sequence_breaker")
    else
        return 25 -- Default XP
    end
end

-- Get failure damage based on difficulty
function SequenceBreaker:getFailureDamage()
    if DifficultyScaler and DifficultyScaler.calculateDamage then
        return DifficultyScaler.calculateDamage(self.difficulty, false)
    else
        return 5 -- Default damage
    end
end

-- Get timeout damage
function SequenceBreaker:getTimeoutDamage()
    return self:getFailureDamage() * 0.8 -- Slightly less damage for timeout
end

-- Complete game successfully
function SequenceBreaker:completeGameSuccess(xpGained)
    if self.window and self.window.completeGameSuccess then
        self.window:completeGameSuccess(xpGained)
    end
end

-- Complete game with failure
function SequenceBreaker:completeGameFailure(damage)
    if self.window and self.window.completeGameFailure then
        self.window:completeGameFailure(damage)
    end
end

-- Complete game with timeout
function SequenceBreaker:completeGameTimeout(damage)
    if self.window and self.window.completeGameTimeout then
        self.window:completeGameTimeout(damage)
    end
end

-- Debug print
function SequenceBreaker:debugPrint(...)
    if MinigameConfig and MinigameConfig.DEBUG then
        print("[SequenceBreaker]", ...)
    end
end