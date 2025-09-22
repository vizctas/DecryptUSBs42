-- Minigame Controller
-- Main controller for the minigame system

MinigameController = {}

-- Active minigames registry
MinigameController.activeGames = {}

-- Initialize the controller
function MinigameController.initialize()
    MinigameController:debugPrint("MinigameController initialized")
end

-- Start a minigame
function MinigameController.startMinigame(gameType, difficulty, player, usbItem, onSuccess, onFailure)
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    local DifficultyScaler = require "MinigameSystem.Utils.DifficultyScaler"

    -- Validate inputs
    if not MinigameConfig.isValidGameType(gameType) then
        MinigameController:debugPrint("Invalid game type:", gameType)
        return false
    end

    if not DifficultyScaler.isValidDifficulty(difficulty) then
        MinigameController:debugPrint("Invalid difficulty:", difficulty)
        return false
    end

    -- Check if player already has an active game
    if MinigameController.activeGames[player:getUsername()] then
        MinigameController:debugPrint("Player already has active game:", player:getUsername())
        return false
    end

    -- Create game instance
    local gameInstance = MinigameController:createGameInstance(gameType, difficulty, player, usbItem, onSuccess, onFailure)
    if not gameInstance then
        MinigameController:debugPrint("Failed to create game instance")
        return false
    end

    -- Register active game
    MinigameController.activeGames[player:getUsername()] = gameInstance

    -- Start the game
    gameInstance:startGame()

    MinigameController:debugPrint("Minigame started:", gameType, difficulty, player:getUsername())
    return true
end

-- Create game instance based on type
function MinigameController:createGameInstance(gameType, difficulty, player, usbItem, onSuccess, onFailure)
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    local MinigameWindow = require "MinigameSystem.UI.MinigameWindow"

    -- Create base window
    local window = MinigameWindow.createWindow(gameType, difficulty, onSuccess, onFailure)

    -- Create game-specific logic
    local gameLogic = nil
    if gameType == MinigameConfig.GAME_TYPES.SEQUENCE_BREAKER then
        gameLogic = MinigameController:createSequenceBreakerLogic(window, difficulty, player, usbItem)
    elseif gameType == MinigameConfig.GAME_TYPES.PATTERN_MATCH then
        gameLogic = MinigameController:createPatternMatchLogic(window, difficulty, player, usbItem)
    elseif gameType == MinigameConfig.GAME_TYPES.MEMORY_MATRIX then
        gameLogic = MinigameController:createMemoryMatrixLogic(window, difficulty, player, usbItem)
    elseif gameType == MinigameConfig.GAME_TYPES.CODE_CRACKER then
        gameLogic = MinigameController:createCodeCrackerLogic(window, difficulty, player, usbItem)
    elseif gameType == MinigameConfig.GAME_TYPES.DATA_STREAM then
        gameLogic = MinigameController:createDataStreamLogic(window, difficulty, player, usbItem)
    else
        MinigameController:debugPrint("Unknown game type:", gameType)
        return nil
    end

    if not gameLogic then
        MinigameController:debugPrint("Failed to create game logic for:", gameType)
        return nil
    end

    -- Return game instance
    return {
        gameType = gameType,
        difficulty = difficulty,
        player = player,
        usbItem = usbItem,
        window = window,
        logic = gameLogic,
        startGame = function(self)
            self.logic:startGame()
        end,
        endGame = function(self, success, xpGained, damage)
            MinigameController:endMinigame(self.player:getUsername(), success, xpGained, damage)
        end
    }
end

-- Create Sequence Breaker logic
function MinigameController:createSequenceBreakerLogic(window, difficulty, player, usbItem)
    -- Placeholder - will be implemented in ISSUE-006
    MinigameController:debugPrint("Creating Sequence Breaker logic (placeholder)")
    return {
        startGame = function(self)
            window:updateStatus("Sequence Breaker - Coming Soon!")
            -- Placeholder implementation
            local TimerSystem = require "MinigameSystem.Utils.TimerSystem"
            TimerSystem.startTimer(2.0, function()
                window:completeGameSuccess(10)
            end)
        end
    }
end

-- Create Pattern Match logic
function MinigameController:createPatternMatchLogic(window, difficulty, player, usbItem)
    -- Placeholder - will be implemented in ISSUE-007
    MinigameController:debugPrint("Creating Pattern Match logic (placeholder)")
    return {
        startGame = function(self)
            window:updateStatus("Pattern Match - Coming Soon!")
            -- Placeholder implementation
            local TimerSystem = require "MinigameSystem.Utils.TimerSystem"
            TimerSystem.startTimer(2.0, function()
                window:completeGameSuccess(10)
            end)
        end
    }
end

-- Create Memory Matrix logic
function MinigameController:createMemoryMatrixLogic(window, difficulty, player, usbItem)
    -- Placeholder - will be implemented in ISSUE-008
    MinigameController:debugPrint("Creating Memory Matrix logic (placeholder)")
    return {
        startGame = function(self)
            window:updateStatus("Memory Matrix - Coming Soon!")
            -- Placeholder implementation
            local TimerSystem = require "MinigameSystem.Utils.TimerSystem"
            TimerSystem.startTimer(2.0, function()
                window:completeGameSuccess(10)
            end)
        end
    }
end

-- Create Code Cracker logic
function MinigameController:createCodeCrackerLogic(window, difficulty, player, usbItem)
    -- Placeholder - will be implemented in ISSUE-010
    MinigameController:debugPrint("Creating Code Cracker logic (placeholder)")
    return {
        startGame = function(self)
            window:updateStatus("Code Cracker - Coming Soon!")
            -- Placeholder implementation
            local TimerSystem = require "MinigameSystem.Utils.TimerSystem"
            TimerSystem.startTimer(2.0, function()
                window:completeGameSuccess(10)
            end)
        end
    }
end

-- Create Data Stream logic
function MinigameController:createDataStreamLogic(window, difficulty, player, usbItem)
    -- Placeholder - will be implemented in ISSUE-011
    MinigameController:debugPrint("Creating Data Stream logic (placeholder)")
    return {
        startGame = function(self)
            window:updateStatus("Data Stream - Coming Soon!")
            -- Placeholder implementation
            local TimerSystem = require "MinigameSystem.Utils.TimerSystem"
            TimerSystem.startTimer(2.0, function()
                window:completeGameSuccess(10)
            end)
        end
    }
end

-- End a minigame
function MinigameController:endMinigame(playerUsername, success, xpGained, damage)
    local gameInstance = MinigameController.activeGames[playerUsername]
    if not gameInstance then
        MinigameController:debugPrint("No active game found for player:", playerUsername)
        return
    end

    -- Close window
    if gameInstance.window then
        gameInstance.window:closeWindow()
    end

    -- Apply rewards/damage
    if success then
        MinigameController:applySuccessRewards(gameInstance.player, xpGained)
    else
        MinigameController:applyFailureDamage(gameInstance.player, damage)
    end

    -- Clean up
    MinigameController.activeGames[playerUsername] = nil

    MinigameController:debugPrint("Minigame ended for", playerUsername, "- Success:", success, "XP:", xpGained, "Damage:", damage)
end

-- Apply success rewards
function MinigameController:applySuccessRewards(player, xpGained)
    local GVDrive_Utils = require "GVDrive_Utils"

    -- Add XP to Electrical skill
    if player:getPerkLevel(Perks.Electricity) < 10 then
        player:getXp():AddXP(Perks.Electricity, xpGained)
        MinigameController:debugPrint("Added", xpGained, "XP to Electrical skill")
    end

    -- Chance for bonus items
    local bonusChance = GVDrive_Utils.getMinigameBonusItemChance()
    if ZombRandFloat(0, 100) < bonusChance then
        MinigameController:giveBonusItem(player)
    end
end

-- Apply failure damage
function MinigameController:applyFailureDamage(player, damage)
    -- Apply damage to player
    player:getBodyDamage():ReduceGeneralHealth(damage)
    player:getBodyDamage():AddDamage(BodyPartType.Torso, damage * 0.5)

    -- Add stress
    player:getStats():setStress(player:getStats():getStress() + 0.1)

    MinigameController:debugPrint("Applied", damage, "damage to player")
end

-- Give bonus item
function MinigameController:giveBonusItem(player)
    local GVDrive_Utils = require "GVDrive_Utils"
    local bonusItems = GVDrive_Utils.getMinigameBonusItems()
    local itemType = bonusItems[ZombRand(1, #bonusItems + 1)]

    if itemType then
        local item = InventoryItemFactory.CreateItem(itemType)
        if item then
            player:getInventory():AddItem(item)
            MinigameController:debugPrint("Gave bonus item:", itemType)
        end
    end
end

-- Check if player has active game
function MinigameController.hasActiveGame(playerUsername)
    return MinigameController.activeGames[playerUsername] ~= nil
end

-- Get active game for player
function MinigameController.getActiveGame(playerUsername)
    return MinigameController.activeGames[playerUsername]
end

-- Cancel all active games (for cleanup)
function MinigameController.cancelAllGames()
    for username, gameInstance in pairs(MinigameController.activeGames) do
        if gameInstance.window then
            gameInstance.window:abandonGame()
        end
    end
    MinigameController.activeGames = {}
    MinigameController:debugPrint("All games cancelled")
end

-- Debug print function
function MinigameController:debugPrint(...)
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    if MinigameConfig.DEBUG then
        print("[MinigameController]", ...)
    end
end

return MinigameController