-- Difficulty Scaler for Minigame Framework
-- Handles difficulty scaling and configuration for all minigames

DifficultyScaler = {}

-- Initialize the difficulty scaler
function DifficultyScaler.init()
    DifficultyScaler.debugPrint("DifficultyScaler initialized")
end

-- Get scaled configuration for a specific game type and difficulty
function DifficultyScaler.getScaledConfig(gameType, difficulty)
    if not gameType or not difficulty then
        DifficultyScaler.debugPrint("Invalid parameters for getScaledConfig:", gameType, difficulty)
        return nil
    end

    local baseConfig = MinigameConfig.getGameConfig(gameType, difficulty)

    if not baseConfig then
        DifficultyScaler.debugPrint("No base config found for", gameType, difficulty)
        return nil
    end

    -- Apply SANDBOXVARS scaling
    local scaledConfig = DifficultyScaler.applySandboxScaling(baseConfig, difficulty)

    DifficultyScaler.debugPrint("Scaled config for", gameType, difficulty, ":", scaledConfig)
    return scaledConfig
end

-- Apply SANDBOXVARS scaling to base configuration
function DifficultyScaler.applySandboxScaling(baseConfig, difficulty)

    local scaled = {}
    for key, value in pairs(baseConfig) do
        scaled[key] = value
    end

    -- Apply time limit scaling from SANDBOXVARS
    if scaled.timeLimit and scaled.timeLimit > 0 then
        local sandboxTimeLimit = GVDrive_Utils.getMinigameTimeLimit(difficulty)
        if sandboxTimeLimit > 0 then
            scaled.timeLimit = sandboxTimeLimit
        end
    end

    -- Apply XP multiplier (this affects the final XP calculation, not stored in config)
    scaled.xpMultiplier = GVDrive_Utils.getMinigameXPMultiplier(difficulty)

    return scaled
end

-- Calculate XP reward for a minigame based on difficulty and base XP
function DifficultyScaler.calculateXP(baseXP, difficulty, gameType)
    if not baseXP or not difficulty then return baseXP end

    local multiplier = GVDrive_Utils.getMinigameXPMultiplier(difficulty)

    local finalXP = math.floor(baseXP * multiplier)

    DifficultyScaler.debugPrint("Calculated XP:", baseXP, "*", multiplier, "=", finalXP, "for", gameType, difficulty)
    return finalXP
end

-- Calculate damage for laptop failure based on difficulty
function DifficultyScaler.calculateDamage(difficulty, wasSuccess)
    if not difficulty then return 5 end -- Default damage

    -- Get damage range from existing SANDBOXVARS
    local settings = GVDrive_Utils.getRaritySettings({rarity = DifficultyScaler.difficultyToRarity(difficulty)})
    local minDamage = settings.laptopDamageMin or 3
    local maxDamage = settings.laptopDamageMax or 5

    if wasSuccess then
        minDamage = math.max(0, math.floor(minDamage / 2))
        maxDamage = math.max(minDamage, math.floor(maxDamage / 2))
    end

    if maxDamage <= minDamage then
        return minDamage
    end

    local damage = ZombRand(minDamage, maxDamage + 1)
    DifficultyScaler.debugPrint("Calculated damage:", damage, "for", difficulty, "(success:", wasSuccess, ")")
    return damage
end

-- Convert minigame difficulty to drive rarity
function DifficultyScaler.difficultyToRarity(difficulty)
    local difficultyMap = {
        [1] = "Facil",
        [2] = "Moderado",
        [3] = "Dificil"
    }

    return difficultyMap[difficulty] or "Facil"
end

-- Get difficulty from drive info
function DifficultyScaler.getDifficultyFromDrive(driveInfo)
    return GVDrive_Utils.getMinigameDifficulty(driveInfo)
end

-- Validate difficulty level
function DifficultyScaler.isValidDifficulty(difficulty)
    return difficulty == MinigameConfig.DIFFICULTIES.EASY or
           difficulty == MinigameConfig.DIFFICULTIES.MODERATE or
           difficulty == MinigameConfig.DIFFICULTIES.EXPERT
end

-- Get all available difficulties
function DifficultyScaler.getAvailableDifficulties()
    return {
        MinigameConfig.DIFFICULTIES.EASY,
        MinigameConfig.DIFFICULTIES.MODERATE,
        MinigameConfig.DIFFICULTIES.EXPERT
    }
end

-- Get difficulty display name
function DifficultyScaler.getDifficultyDisplayName(difficulty)
    local displayNames = {
        [1] = "Fácil",
        [2] = "Moderado",
        [3] = "Experto"
    }

    return displayNames[difficulty] or tostring(difficulty)
end

-- Get difficulty color (for UI)
function DifficultyScaler.getDifficultyColor(difficulty)
    local colors = {
        [1] = {0.2, 0.8, 0.2, 1},     -- Green
        [2] = {0.8, 0.8, 0.2, 1}, -- Yellow
        [3] = {0.8, 0.2, 0.2, 1}    -- Red
    }

    return colors[difficulty] or {0.5, 0.5, 0.5, 1} -- Gray fallback
end

-- Get difficulty description
function DifficultyScaler.getDifficultyDescription(difficulty)
    local descriptions = {
        [1] = "Desafío sencillo con pistas y tiempo generoso",
        [2] = "Desafío moderado con tiempo limitado",
        [3] = "Desafío extremo con tiempo muy limitado y distracciones"
    }

    return descriptions[difficulty] or "Dificultad desconocida"
end

-- Scale value based on difficulty (generic scaling function)
function DifficultyScaler.scaleValue(baseValue, difficulty, scaleType)
    if not baseValue or not difficulty then return baseValue end

    local scaleFactors = {
        time_limit = {
            [1] = 1.5,    -- 50% more time
            [2] = 1.0, -- Normal time
            [3] = 0.7    -- 30% less time
        },
        complexity = {
            [1] = 0.7,    -- 30% less complex
            [2] = 1.0, -- Normal complexity
            [3] = 1.4    -- 40% more complex
        },
        hints = {
            [1] = 1.0,    -- Full hints
            [2] = 0.5, -- Partial hints
            [3] = 0.0    -- No hints
        }
    }

    local factors = scaleFactors[scaleType]
    if not factors then return baseValue end

    local factor = factors[difficulty] or 1.0

    if scaleType == "hints" then
        return factor -- Return as multiplier for boolean-like scaling
    else
        return math.floor(baseValue * factor)
    end
end

-- Debug print function
function DifficultyScaler.debugPrint(...)
    if MinigameConfig and MinigameConfig.DEBUG then
        print("[DifficultyScaler]", ...)
    end
end

-- Initialize on load
DifficultyScaler.init()

DifficultyScaler.debugPrint("DifficultyScaler.lua loaded successfully")