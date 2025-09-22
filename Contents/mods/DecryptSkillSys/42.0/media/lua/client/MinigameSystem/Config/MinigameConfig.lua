-- Minigame System Configuration
-- Central configuration for all minigame components

MinigameConfig = {}

-- Debug settings
MinigameConfig.DEBUG = false

-- Game states
MinigameConfig.STATES = {
    LOADING = "loading",
    SHOWING_PATTERN = "showing_pattern",
    PLAYER_INPUT = "player_input",
    VALIDATING = "validating",
    SUCCESS = "success",
    FAILURE = "failure",
    ABANDONED = "abandoned"
}

-- Difficulty levels
MinigameConfig.DIFFICULTIES = {
    EASY = "Easy",
    MODERATE = "Moderate",
    EXPERT = "Expert"
}

-- Minigame types
MinigameConfig.GAME_TYPES = {
    SEQUENCE_BREAKER = "sequence_breaker",
    CODE_MATRIX = "code_matrix",
    MEMORY_DECRYPT = "memory_decrypt"
}

-- Default game settings
MinigameConfig.DEFAULTS = {
    WINDOW_TITLE = "Decrypt Challenge",
    WINDOW_WIDTH = 400,
    WINDOW_HEIGHT = 300,
    AUTO_CLOSE_SUCCESS = 3,
    AUTO_CLOSE_FAIL = 2,
    ENABLE_SOUND = true,
    ENABLE_VISUAL_EFFECTS = true
}

-- Sequence Breaker specific config
MinigameConfig.SEQUENCE_BREAKER = {
    BUTTONS = {"🔴", "🔵", "🟢", "🟡"},
    DIFFICULTY_SETTINGS = {
        [MinigameConfig.DIFFICULTIES.EASY] = {
            sequenceLength = 4,
            showTime = 6,
            timeLimit = 0, -- unlimited
            hints = true
        },
        [MinigameConfig.DIFFICULTIES.MODERATE] = {
            sequenceLength = 5,
            showTime = 4,
            timeLimit = 12,
            hints = false
        },
        [MinigameConfig.DIFFICULTIES.EXPERT] = {
            sequenceLength = 6,
            showTime = 3,
            timeLimit = 8,
            hints = false,
            distractions = true
        }
    }
}

-- Code Matrix specific config
MinigameConfig.CODE_MATRIX = {
    SYMBOLS = {"🔷", "🔶", "🔴", "🔵", "🟢", "🟡", "🟠", "🟣"},
    DIFFICULTY_SETTINGS = {
        [MinigameConfig.DIFFICULTIES.EASY] = {
            matrixSize = 3,
            correctSymbols = 2,
            timeLimit = 15,
            showHints = true
        },
        [MinigameConfig.DIFFICULTIES.MODERATE] = {
            matrixSize = 4,
            correctSymbols = 3,
            timeLimit = 20,
            showHints = false
        },
        [MinigameConfig.DIFFICULTIES.EXPERT] = {
            matrixSize = 5,
            correctSymbols = 4,
            timeLimit = 25,
            showHints = false
        }
    }
}

-- Memory Decrypt specific config
MinigameConfig.MEMORY_DECRYPT = {
    SYMBOLS = {"💿", "💾", "🖥️", "🖱️", "⌨️", "🔌", "🔋", "🔷", "🔶", "🔴"},
    DIFFICULTY_SETTINGS = {
        [MinigameConfig.DIFFICULTIES.EASY] = {
            totalCards = 6, -- 3 pairs
            showTime = 15,
            timeLimit = 30,
            showColors = true
        },
        [MinigameConfig.DIFFICULTIES.MODERATE] = {
            totalCards = 8, -- 4 pairs
            showTime = 10,
            timeLimit = 25,
            showColors = false
        },
        [MinigameConfig.DIFFICULTIES.EXPERT] = {
            totalCards = 10, -- 5 pairs
            showTime = 8,
            timeLimit = 20,
            showColors = false,
            hasFakeCards = true
        }
    }
}

-- Sound effects mapping
MinigameConfig.SOUNDS = {
    BUTTON_RED = "ButtonRed",
    BUTTON_BLUE = "ButtonBlue",
    BUTTON_GREEN = "ButtonGreen",
    BUTTON_YELLOW = "ButtonYellow",
    SUCCESS = "Success",
    FAILURE = "Failure",
    TIMEOUT = "Timeout",
    CARD_FLIP = "CardFlip",
    MATCH_FOUND = "MatchFound",
    MATCH_WRONG = "MatchWrong"
}

-- Visual effects settings
MinigameConfig.VISUAL_EFFECTS = {
    GLOW_DURATION = 0.5,
    SHAKE_DURATION = 0.3,
    SHAKE_INTENSITY = 5,
    SUCCESS_PARTICLES = true,
    FAILURE_SHAKE = true
}

-- Timer system settings
MinigameConfig.TIMERS = {
    UPDATE_INTERVAL = 0.1, -- 100ms updates
    WARNING_THRESHOLD = 3  -- seconds for warning
}

-- Get configuration for specific game type and difficulty
function MinigameConfig.getGameConfig(gameType, difficulty)
    if not gameType or not difficulty then return nil end

    local gameConfig = MinigameConfig[string.upper(gameType)]
    if not gameConfig then return nil end

    return gameConfig.DIFFICULTY_SETTINGS[difficulty]
end

-- Get default window settings from SANDBOXVARS
function MinigameConfig.getWindowSettings()
    local GVDrive_Utils = require "shared/GVDrive_Utils"
    local size = GVDrive_Utils.getMinigameWindowSize()

    return {
        width = size.width,
        height = size.height,
        title = MinigameConfig.DEFAULTS.WINDOW_TITLE
    }
end

-- Get auto-close delays from SANDBOXVARS
function MinigameConfig.getAutoCloseDelays()
    local GVDrive_Utils = require "shared/GVDrive_Utils"
    return GVDrive_Utils.getMinigameAutoCloseDelays()
end

-- Check if sound is enabled
function MinigameConfig.isSoundEnabled()
    local GVDrive_Utils = require "shared/GVDrive_Utils"
    return GVDrive_Utils.isMinigameSoundEnabled()
end

-- Check if visual effects are enabled
function MinigameConfig.isVisualEffectsEnabled()
    local GVDrive_Utils = require "shared/GVDrive_Utils"
    return GVDrive_Utils.isMinigameVisualEffectsEnabled()
end

-- Debug print function
function MinigameConfig.debugPrint(...)
    if MinigameConfig.DEBUG then
        print("[MinigameConfig]", ...)
    end
end

MinigameConfig.debugPrint("MinigameConfig.lua loaded successfully")

return MinigameConfig