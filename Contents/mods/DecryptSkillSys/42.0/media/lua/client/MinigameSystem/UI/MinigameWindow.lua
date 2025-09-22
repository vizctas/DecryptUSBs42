-- Minigame Window Base Class
-- Base modal window for all minigame implementations

MinigameWindow = ISPanel:derive("MinigameWindow")

-- Constructor
function MinigameWindow:new(x, y, width, height, title)
    local o = ISPanel:new(x, y, width, height)
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

    o:initialise()
    o:instantiate()

    return o
end

-- Initialize the window
function MinigameWindow:initialise()
    ISPanel.initialise(self)

    self:setAlwaysOnTop(true)
    self:setCapture(true)

    -- Create title label
    self.titleLabel = ISLabel:new(10, 10, 20, self.title, 1, 1, 1, 1, UIFont.Large, true)
    self.titleLabel:initialise()
    self:addChild(self.titleLabel)

    -- Create status label
    self.statusLabel = ISLabel:new(10, 40, 20, "Initializing...", 1, 1, 1, 1, UIFont.Medium, true)
    self.statusLabel:initialise()
    self:addChild(self.statusLabel)

    -- Create timer label
    self.timerLabel = ISLabel:new(self.width - 100, 10, 20, "", 1, 0.8, 0.2, 1, UIFont.Medium, true)
    self.timerLabel:initialise()
    self:addChild(self.timerLabel)

    -- Create close button
    self.closeButton = ISButton:new(self.width - 30, 5, 25, 25, "X", self, self.onCloseButton)
    self.closeButton:initialise()
    self.closeButton:setVisible(false) -- Hidden during gameplay
    self:addChild(self.closeButton)

    self:debugPrint("MinigameWindow initialized")
end

-- Set game configuration
function MinigameWindow:setGameConfig(gameType, difficulty, onSuccess, onFailure)
    self.gameType = gameType
    self.difficulty = difficulty
    self.onSuccess = onSuccess
    self.onFailure = onFailure

    -- Update title with difficulty
    local DifficultyScaler = require "MinigameSystem.Utils.DifficultyScaler"
    local displayName = DifficultyScaler.getDifficultyDisplayName(difficulty)
    self.titleLabel:setName(self.title .. " - " .. displayName)

    self:debugPrint("Game config set:", gameType, difficulty)
end

-- Start the minigame
function MinigameWindow:startGame()
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    self.gameState = MinigameConfig.STATES.LOADING

    self:updateStatus("Loading challenge...")
    self:setCloseButtonVisible(false)

    -- Start game after a brief delay
    local TimerSystem = require "MinigameSystem.Utils.TimerSystem"
    TimerSystem.startTimer(1.0, function()
        self:onGameReady()
    end, "game_start")

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

-- Update timer display
function MinigameWindow:updateTimer(remainingTime, totalTime)
    if self.timerLabel then
        if remainingTime and remainingTime > 0 then
            local timeStr = string.format("%.1f", remainingTime)
            if remainingTime <= 3 then
                self.timerLabel:setColor(1, 0.2, 0.2, 1) -- Red for warning
            else
                self.timerLabel:setColor(1, 1, 1, 1) -- White normal
            end
            self.timerLabel:setName("Time: " .. timeStr .. "s")
        else
            self.timerLabel:setName("")
        end
    end
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
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    self.gameState = MinigameConfig.STATES.ABANDONED

    self:debugPrint("Game abandoned by player")

    -- Trigger failure callback with abandon flag
    if self.onFailure then
        local DifficultyScaler = require "MinigameSystem.Utils.DifficultyScaler"
        local damage = DifficultyScaler.calculateDamage(self.difficulty, false)
        self.onFailure(damage, true) -- true = abandoned
    end

    self:closeWindow()
end

-- Complete game successfully
function MinigameWindow:completeGameSuccess(xpGained)
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    self.gameState = MinigameConfig.STATES.SUCCESS

    local FeedbackSystem = require "MinigameSystem.Utils.FeedbackSystem"
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
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    self.gameState = MinigameConfig.STATES.FAILURE

    local FeedbackSystem = require "MinigameSystem.Utils.FeedbackSystem"
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
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    self.gameState = MinigameConfig.STATES.FAILURE

    local FeedbackSystem = require "MinigameSystem.Utils.FeedbackSystem"
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
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    local delays = MinigameConfig.getAutoCloseDelays()
    local delay = isSuccess and delays.success or delays.fail

    local TimerSystem = require "MinigameSystem.Utils.TimerSystem"
    self.autoCloseTimerId = TimerSystem.startTimer(delay, function()
        self:closeWindow()
    end, "auto_close")

    self:debugPrint("Auto-close scheduled in", delay, "seconds")
end

-- Close the window
function MinigameWindow:closeWindow()
    -- Cancel any active timers
    local TimerSystem = require "MinigameSystem.Utils.TimerSystem"
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
        local TimerSystem = require "MinigameSystem.Utils.TimerSystem"
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
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    if MinigameConfig.DEBUG then
        print("[MinigameWindow]", ...)
    end
end

-- Create window instance
function MinigameWindow.createWindow(gameType, difficulty, onSuccess, onFailure)
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    local windowSettings = MinigameConfig.getWindowSettings()

    -- Center the window
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local x = (screenWidth - windowSettings.width) / 2
    local y = (screenHeight - windowSettings.height) / 2

    local window = MinigameWindow:new(x, y, windowSettings.width, windowSettings.height, windowSettings.title)
    window:setGameConfig(gameType, difficulty, onSuccess, onFailure)

    -- Add to UI manager
    local uiManager = UIManager.getInstance()
    uiManager:addWindow(window)

    return window
end

return MinigameWindow