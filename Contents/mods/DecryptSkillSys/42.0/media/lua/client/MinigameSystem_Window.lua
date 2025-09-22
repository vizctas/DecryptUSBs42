-- Minigame Window Base Class
-- Base modal window for all minigame implementations

-- Safe ISPanel inheritance - only derive if ISPanel is available
if ISPanel then
    MinigameWindow = ISPanel:derive("MinigameWindow")
else
    -- Fallback for when ISPanel is not loaded yet
    MinigameWindow = {}
    MinigameWindow.__index = MinigameWindow
    print("[MinigameWindow][WARNING] ISPanel not available - using fallback implementation")
end

-- Constructor
function MinigameWindow:new(x, y, width, height, title)
    -- Verify ISPanel is available before attempting to create window
    if not ISPanel then
        print("[MinigameWindow][ERROR] ISPanel not available - cannot create window")
        return nil
    end

    local o = ISPanel:new(x, y, width, height)
    if not o then
        print("[MinigameWindow][ERROR] ISPanel:new() returned nil")
        return nil
    end

    setmetatable(o, self)
    self.__index = self

    o.title = title or "Decrypt Challenge"
    o.gameType = nil
    o.difficulty = nil
    o.gameState = nil
    o.timerId = nil
    o.autoCloseTimerId = nil

    -- Callbacks
    o.onSuccess = nil
    o.onFailure = nil

    -- UI elements
    o.titleLabel = nil
    o.statusLabel = nil
    o.timerLabel = nil
    o.closeButton = nil

    -- Safe initialization - check if methods exist
    if o.initialise then
        local success, err = pcall(function() o:initialise() end)
        if not success then
            print("[MinigameWindow][ERROR] Failed to initialize window:", err)
            return nil
        end
    end

    if o.instantiate then
        local success, err = pcall(function() o:instantiate() end)
        if not success then
            print("[MinigameWindow][ERROR] Failed to instantiate window:", err)
            return nil
        end
    end

    return o
end

-- Initialize the window
function MinigameWindow:initialise()
    -- Safe call to parent initialise
    if ISPanel and ISPanel.initialise then
        local success, err = pcall(function() ISPanel.initialise(self) end)
        if not success then
            print("[MinigameWindow][ERROR] Failed to call ISPanel.initialise:", err)
            return false
        end
    else
        print("[MinigameWindow][ERROR] ISPanel.initialise not available")
        return false
    end

    -- Safe initialization of window properties
    if self.setAlwaysOnTop then
        pcall(function() self:setAlwaysOnTop(true) end)
    end
    if self.setCapture then
        pcall(function() self:setCapture(true) end)
    end

    -- Create title label safely
    if ISLabel and ISLabel.new then
        local success, err = pcall(function()
            self.titleLabel = ISLabel:new(10, 10, 20, self.title, 1, 1, 1, 1, UIFont.Large, true)
            if self.titleLabel and self.titleLabel.initialise then
                self.titleLabel:initialise()
            end
            if self.addChild then
                self:addChild(self.titleLabel)
            end
        end)
        if not success then
            print("[MinigameWindow][ERROR] Failed to create title label:", err)
        end
    end

    -- Create status label safely
    if ISLabel and ISLabel.new then
        local success, err = pcall(function()
            self.statusLabel = ISLabel:new(10, 40, 20, "Initializing...", 1, 1, 1, 1, UIFont.Medium, true)
            if self.statusLabel and self.statusLabel.initialise then
                self.statusLabel:initialise()
            end
            if self.addChild then
                self:addChild(self.statusLabel)
            end
        end)
        if not success then
            print("[MinigameWindow][ERROR] Failed to create status label:", err)
        end
    end

    -- Create timer label safely
    if ISLabel and ISLabel.new then
        local success, err = pcall(function()
            self.timerLabel = ISLabel:new(self.width - 100, 10, 20, "", 1, 0.8, 0.2, 1, UIFont.Medium, true)
            if self.timerLabel and self.timerLabel.initialise then
                self.timerLabel:initialise()
            end
            if self.addChild then
                self:addChild(self.timerLabel)
            end
        end)
        if not success then
            print("[MinigameWindow][ERROR] Failed to create timer label:", err)
        end
    end

    -- Create close button safely
    if ISButton and ISButton.new then
        local success, err = pcall(function()
            self.closeButton = ISButton:new(self.width - 30, 5, 25, 25, "X", self, self.onCloseButton)
            if self.closeButton and self.closeButton.initialise then
                self.closeButton:initialise()
            end
            if self.closeButton and self.closeButton.setVisible then
                self.closeButton:setVisible(false) -- Hidden during gameplay
            end
            if self.addChild then
                self:addChild(self.closeButton)
            end
        end)
        if not success then
            print("[MinigameWindow][ERROR] Failed to create close button:", err)
        end
    end

    self:debugPrint("MinigameWindow initialized")
    return true
end

-- Set game configuration
function MinigameWindow:setGameConfig(gameType, difficulty, onSuccess, onFailure)
    self.gameType = gameType
    self.difficulty = difficulty
    self.onSuccess = onSuccess
    self.onFailure = onFailure

    -- Update title with difficulty safely
    local displayName = difficulty or "Unknown"
    if DifficultyScaler and DifficultyScaler.getDifficultyDisplayName then
        local success, result = pcall(function() return DifficultyScaler.getDifficultyDisplayName(difficulty) end)
        if success and result then
            displayName = result
        end
    end

    local newTitle = (self.title or "Decrypt Challenge") .. " - " .. displayName

    if self.titleLabel and self.titleLabel.setName then
        pcall(function() self.titleLabel:setName(newTitle) end)
    end

    self:debugPrint("Game config set:", gameType, difficulty)
end

-- Start the minigame
function MinigameWindow:startGame()
    self.gameState = MinigameConfig.STATES.LOADING

    self:updateStatus("Loading challenge...")
    self:setCloseButtonVisible(false)

    -- Start game after a brief delay
    TimerSystem.startTimer(1.0, function()
        self:onGameReady()
    end)

    self:debugPrint("Game started")
end

-- Called when game is ready to begin
function MinigameWindow:onGameReady()
    -- Override in subclasses
    self:debugPrint("Game ready - override in subclass")
end

-- Update status message
function MinigameWindow:updateStatus(message)
    if self.statusLabel then
        self.statusLabel:setName(message)
    end
    self:debugPrint("Status updated:", message)
end

-- Start a timer for this window
function MinigameWindow:startTimer(duration, callback)
    self.timerId = TimerSystem.startTimer(duration, callback, "minigame_window")
    return self.timerId
end

-- Set close button visibility
function MinigameWindow:setCloseButtonVisible(visible)
    if self.closeButton then
        self.closeButton:setVisible(visible)
    end
end

-- Handle close button click
function MinigameWindow:onCloseButton()
    self:abandonGame()
end

-- Abandon the game (player closed window)
function MinigameWindow:abandonGame()
    self.gameState = MinigameConfig.STATES.ABANDONED

    self:debugPrint("Game abandoned by player")

    -- Trigger failure callback with abandon flag
    if self.onFailure then
        local damage = 5 -- Default damage
        if DifficultyScaler and DifficultyScaler.calculateDamage then
            damage = DifficultyScaler.calculateDamage(self.difficulty, false)
        end
        self.onFailure(damage, true) -- true = abandoned
    end

    self:closeWindow()
end

-- Complete game successfully
function MinigameWindow:completeGameSuccess(xpGained)
    self.gameState = MinigameConfig.STATES.SUCCESS

    FeedbackSystem.showSuccess("¡Desafío completado!")

    self:debugPrint("Game completed successfully with", xpGained, "XP")

    -- Trigger success callback
    if self.onSuccess then
        self.onSuccess(xpGained)
    end

    -- Auto-close after delay
    self:startAutoClose(true)
end

-- Complete game with failure
function MinigameWindow:completeGameFailure(damage)
    self.gameState = MinigameConfig.STATES.FAILURE

    FeedbackSystem.showFailure("Desafío fallido")

    self:debugPrint("Game failed with", damage, "damage")

    -- Trigger failure callback
    if self.onFailure then
        self.onFailure(damage, false) -- false = not abandoned
    end

    -- Auto-close after delay
    self:startAutoClose(false)
end

-- Complete game with timeout
function MinigameWindow:completeGameTimeout(damage)
    self.gameState = MinigameConfig.STATES.FAILURE

    FeedbackSystem.showTimeout("¡Tiempo agotado!")

    self:debugPrint("Game timed out with", damage, "damage")

    -- Trigger failure callback
    if self.onFailure then
        self.onFailure(damage, false) -- false = not abandoned
    end

    -- Auto-close after delay
    self:startAutoClose(false)
end

-- Start auto-close timer
function MinigameWindow:startAutoClose(isSuccess)
    local delays = MinigameConfig.getAutoCloseDelays()
    local delay = isSuccess and delays.success or delays.fail

    self.autoCloseTimerId = TimerSystem.startTimer(delay, function()
        self:closeWindow()
    end)

    self:debugPrint("Auto-close scheduled in", delay, "seconds")
end

-- Close the window
function MinigameWindow:closeWindow()
    -- Cancel any active timers
    if self.timerId then
        TimerSystem.cancelTimer(self.timerId)
        self.timerId = nil
    end
    if self.autoCloseTimerId then
        TimerSystem.cancelTimer(self.autoCloseTimerId)
        self.autoCloseTimerId = nil
    end

    -- Remove from UI manager
    if self.parent then
        self.parent:removeChild(self)
    end

    self:debugPrint("Window closed")
end

-- Update method (called every frame)
function MinigameWindow:update()
    ISPanel.update(self)

    -- Update timer display if we have an active timer
    if self.timerId then
        local remaining = TimerSystem.getRemainingTime(self.timerId)
        if remaining > 0 then
            self:updateTimer(remaining)
        end
    end
end

-- Render method
function MinigameWindow:render()
    ISPanel.render(self)

    -- Draw background
    self:drawRect(0, 0, self.width, self.height, 0.8, 0, 0, 0)

    -- Draw border
    self:drawRectBorder(0, 0, self.width, self.height, 1, 0.5, 0.5, 0.5)
end

-- Handle keyboard input
function MinigameWindow:onKeyPress(key)
    -- Allow closing with Escape key
    if key == Keyboard.KEY_ESCAPE then
        self:abandonGame()
        return true
    end
    return false
end

-- Debug print function
function MinigameWindow:debugPrint(...)
    if MinigameConfig and MinigameConfig.DEBUG then
        print("[MinigameWindow]", ...)
    end
end

-- Create window instance
function MinigameWindow.createWindow(gameType, difficulty, onSuccess, onFailure)
    -- Verify MinigameConfig is available
    if not MinigameConfig then
        print("[MinigameWindow][ERROR] MinigameConfig not available - cannot create window")
        return nil
    end

    local windowSettings = MinigameConfig.getWindowSettings()
    if not windowSettings then
        print("[MinigameWindow][ERROR] Failed to get window settings")
        return nil
    end

    -- Center the window safely
    local screenWidth = 1024  -- Default fallback
    local screenHeight = 768  -- Default fallback
    
    -- Try to get actual screen dimensions
    local coreSuccess, core = pcall(function() return getCore() end)
    if coreSuccess and core then
        local widthSuccess, width = pcall(function() return core:getScreenWidth() end)
        if widthSuccess and width then screenWidth = width end
        
        local heightSuccess, height = pcall(function() return core:getScreenHeight() end)
        if heightSuccess and height then screenHeight = height end
    end
    
    local x = (screenWidth - windowSettings.width) / 2
    local y = (screenHeight - windowSettings.height) / 2

    print("[MinigameWindow][DEBUG] Creating window at", x, y, "size", windowSettings.width, windowSettings.height)

    local window = MinigameWindow:new(x, y, windowSettings.width, windowSettings.height, windowSettings.title)
    if not window then
        print("[MinigameWindow][ERROR] MinigameWindow:new() returned nil - cannot create window")
        return nil
    end

    print("[MinigameWindow][DEBUG] Window created successfully, setting game config")

    -- Safe call to setGameConfig
    if window.setGameConfig then
        local success, err = pcall(function() window:setGameConfig(gameType, difficulty, onSuccess, onFailure) end)
        if not success then
            print("[MinigameWindow][ERROR] Failed to set game config:", err)
            return nil
        end
    else
        print("[MinigameWindow][ERROR] setGameConfig method not available")
        return nil
    end

    -- Add to UI manager safely
    if UIManager then
        local success, err = pcall(function()
            local uiManager = UIManager.getInstance()
            if uiManager and uiManager.addWindow then
                uiManager:addWindow(window)
            end
        end)
        if not success then
            print("[MinigameWindow][ERROR] Failed to add window to UI manager:", err)
        end
    else
        print("[MinigameWindow][WARNING] UIManager not available - window created but not added to UI")
    end

    print("[MinigameWindow][DEBUG] Window creation completed successfully")
    return window
end