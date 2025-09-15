-- GVDrive Utility Functions
-- Shared functions for experience calculation and other utilities

GVDrive_Utils = {}

-- Calculate scalable experience based on current skill level
function GVDrive_Utils.calculateScalableExperience(character, perk, isUSB)
    if not SandboxVars.GVDrive.Use_Scalable_Experience then
        -- Use old system
        if isUSB then
            local maxExpGain = SandboxVars.GVDrive.USB_Max_Experience
            local minExpGain = SandboxVars.GVDrive.USB_Min_Experience
            return ZombRand(minExpGain, maxExpGain) + 1
        else
            local maxExpGain = SandboxVars.GVDrive.Floppy_Max_Experience
            local minExpGain = SandboxVars.GVDrive.Floppy_Min_Experience
            return ZombRand(minExpGain, maxExpGain) + 1
        end
    end

    -- New scalable system
    local currentLevel = character:getPerkLevel(perk)
    local baseMultiplier = SandboxVars.GVDrive.Scalable_Base_Experience or 50
    local levelFactor = SandboxVars.GVDrive.Scalable_Level_Multiplier or 1.2
    
    -- Calculate base experience (higher for USB, lower for diskette)
    local baseExp = isUSB and 50 or 35
    
    -- Calculate level-appropriate experience
    -- Formula: baseExp * baseMultiplier * (levelFactor ^ currentLevel)
    local scaledExp = baseExp * baseMultiplier * (levelFactor ^ currentLevel)
    
    -- Add some randomness (±20%)
    local variance = scaledExp * 0.2
    local minExp = scaledExp - variance
    local maxExp = scaledExp + variance
    
    return math.max(1, math.floor(ZombRand(minExp, maxExp)))
end

-- Get random perk from available list
function GVDrive_Utils.getRandomPerk()
    local perkTable = {
        Perks.Woodwork,
        Perks.Electricity,
        Perks.Farming,
        Perks.Aiming,
        Perks.Cooking,
        Perks.Sneak,
        Perks.Axe,
        Perks.Fitness,
        Perks.Doctor,
        Perks.Survivalist,
    }
    local randomPerkIndex = ZombRand(1, #perkTable + 1)
    return perkTable[randomPerkIndex]
end

-- Get perk name for message display
function GVDrive_Utils.getPerkName(perk)
    local perkNameMap = {
        [Perks.Woodwork] = "Woodwork",
        [Perks.Electricity] = "Electricity",
        [Perks.Farming] = "Farming",
        [Perks.Aiming] = "Aiming",
        [Perks.Cooking] = "Cooking",
        [Perks.Sneak] = "Sneak",
        [Perks.Axe] = "Axe",
        [Perks.Fitness] = "Fitness",
        [Perks.Doctor] = "Doctor",
        [Perks.Survivalist] = "Survivalist",
    }
    return perkNameMap[perk] or "Woodwork"
end