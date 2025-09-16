-- GVDrive Utility Functions (SIMPLIFIED VERSION TO AVOID CRASHES)
-- Shared functions for experience calculation and other utilities

GVDrive_Utils = {}

-- Get drive info - enhanced version for skill drives
function GVDrive_Utils.getDriveInfo(item)
    if not item then return nil end
    
    local itemType = item:getType()
    
    -- Check for skill-specific drives
    if string.find(itemType, "SkillDrive_") then
        local parts = {}
        for part in string.gmatch(itemType, "([^_]+)") do
            table.insert(parts, part)
        end
        
        if #parts >= 3 then
            local skill = parts[2] -- e.g., "Woodwork", "Electricity"
            local rarity = parts[3] -- e.g., "Common", "Rare"
            
            local perk = GVDrive_Utils.getSkillPerk(skill)
            
            return {
                skill = perk,
                skillName = skill,
                rarity = rarity,
                difficulty = (rarity == "Rare") and "Hard" or "Medium",
                isUSB = true,
                isFloppy = false,
                isLegacy = false,
                isSkillSpecific = true
            }
        end
    elseif string.find(itemType, "SkillFloppy_") then
        local parts = {}
        for part in string.gmatch(itemType, "([^_]+)") do
            table.insert(parts, part)
        end
        
        if #parts >= 3 then
            local skill = parts[2] -- e.g., "Woodwork", "Electricity"
            local rarity = parts[3] -- e.g., "Common"
            
            local perk = GVDrive_Utils.getSkillPerk(skill)
            
            return {
                skill = perk,
                skillName = skill,
                rarity = rarity,
                difficulty = "Easy",
                isUSB = false,
                isFloppy = true,
                isLegacy = false,
                isSkillSpecific = true
            }
        end
    end
    
    -- For legacy drives
    local info = {
        skill = nil, -- Will be random
        difficulty = "Easy", -- Safe default
        isUSB = (itemType == "USB_Closed"),
        isFloppy = (itemType == "FloppyDrive"),
        isLegacy = true,
        isSkillSpecific = false
    }
    
    return info
end

-- Enhanced experience calculation for skill drives
function GVDrive_Utils.calculateDriveExperience(character, driveInfo)
    if not character or not driveInfo then return 50 end
    
    local sandboxVars = SandboxVars and SandboxVars.GVDrive
    if not sandboxVars then return 50 end -- fallback
    
    local baseMin, baseMax
    
    if driveInfo.isSkillSpecific then
        -- Skill-specific drives have higher experience rewards
        if driveInfo.isUSB then
            if driveInfo.rarity == "Rare" then
                baseMin = 100
                baseMax = 300
            else -- Common
                baseMin = 50
                baseMax = 200
            end
        else -- Floppy
            baseMin = 35
            baseMax = 150
        end
        
        -- Bonus experience based on current skill level (higher level = less bonus)
        local currentLevel = 0
        if driveInfo.skill and character:getPerkLevel then
            currentLevel = character:getPerkLevel(driveInfo.skill)
        end
        
        -- Reduce experience for higher level characters
        local levelPenalty = math.min(currentLevel * 5, 50) -- Max 50% reduction at level 10
        baseMin = math.max(baseMin - levelPenalty, 10)
        baseMax = math.max(baseMax - levelPenalty, 25)
        
    else
        -- Legacy drives use sandbox settings
        if driveInfo.isUSB then
            baseMin = sandboxVars.USB_Min_Experience or 35
            baseMax = sandboxVars.USB_Max_Experience or 245
        else
            baseMin = sandboxVars.Floppy_Min_Experience or 25
            baseMax = sandboxVars.Floppy_Max_Experience or 195
        end
    end
    
    return ZombRand(baseMin, baseMax)
end

-- Calculate risk of laptop damage
function GVDrive_Utils.calculateDamageRisk(driveInfo)
    if not driveInfo then return 0 end
    
    if driveInfo.isSkillSpecific then
        -- Skill drives have lower malware risk
        if driveInfo.rarity == "Rare" then
            return 5 -- Rare skill drives are safer
        else
            return 8 -- Common skill drives 
        end
    else
        -- Legacy drives have higher risk
        if driveInfo.isUSB then
            return 15 -- USB drives have 15% malware risk
        else
            return 10 -- Floppy drives have 10% malware risk
        end
    end
end

-- Get random skill for legacy drives
-- Get the perk associated with a drive (if provided) or fall back to a legacy/random selection
function GVDrive_Utils.getPerkFromDrive(drive)
    -- If a driveInfo table was passed in (from getDriveInfo), prefer its skill
    if type(drive) == "table" and drive.skill then
        return drive.skill
    end

    -- If an item was passed in, try to parse its drive info
    if type(drive) ~= "nil" and type(drive) ~= "table" then
        -- not a table, assume it's an item and try to get its info
        local ok, info = pcall(function() return GVDrive_Utils.getDriveInfo(drive) end)
        if ok and info and info.skill then
            return info.skill
        end
    end

    -- Legacy / fallback: choose a random perk from the list
    local skills = {Perks.Woodwork, Perks.Electricity, Perks.Farming, Perks.Aiming, Perks.Cooking,
                   Perks.Sneak, Perks.Axe, Perks.Fitness, Perks.Doctor, Perks.Survivalist}
    return skills[ZombRand(#skills) + 1]
end

-- Clearer name for the same behavior
function GVDrive_Utils.getDrivePerk(drive)
    return GVDrive_Utils.getPerkFromDrive(drive)
end

-- NOTE: legacy wrappers removed; use the new APIs:
--   GVDrive_Utils.getDrivePerk(driveOrInfo)
--   GVDrive_Utils.calculateDriveExperience(character, driveInfo)

-- Convert skill name to perk enum
function GVDrive_Utils.getSkillPerk(skillName)
    local skillMap = {
        ["Woodwork"] = Perks.Woodwork,
        ["Electricity"] = Perks.Electricity,
        ["Farming"] = Perks.Farming,
        ["Aiming"] = Perks.Aiming,
        ["Cooking"] = Perks.Cooking,
        ["Sneak"] = Perks.Sneak,
        ["Axe"] = Perks.Axe,
        ["Fitness"] = Perks.Fitness,
        ["Doctor"] = Perks.Doctor,
        ["Survivalist"] = Perks.Survivalist
    }
    return skillMap[skillName]
end

-- Get perk name for display
function GVDrive_Utils.getPerkName(perk)
    local perkNames = {
        [Perks.Woodwork] = "Woodwork",
        [Perks.Electricity] = "Electricity", 
        [Perks.Farming] = "Farming",
        [Perks.Aiming] = "Aiming",
        [Perks.Cooking] = "Cooking",
        [Perks.Sneak] = "Sneak",
        [Perks.Axe] = "Axe",
        [Perks.Fitness] = "Fitness",
        [Perks.Doctor] = "Doctor",
        [Perks.Survivalist] = "Survivalist"
    }
    return perkNames[perk] or "Unknown"
end

-- Get success chance for decryption
function GVDrive_Utils.getSuccessChance(driveInfo)
    local sandboxVars = SandboxVars and SandboxVars.GVDrive
    if not sandboxVars then return 50 end
    
    if driveInfo and driveInfo.isSkillSpecific then
        -- Skill drives have higher success chance
        if driveInfo.rarity == "Rare" then
            return 65 -- Rare skill drives are easier to decrypt
        else
            return 55 -- Common skill drives
        end
    else
        -- Legacy drives use sandbox settings
        if driveInfo and driveInfo.isUSB then
            return sandboxVars.USB_Decrypt_Success_Chance or 33
        else
            return sandboxVars.Floppy_Decrypt_Success_Chance or 30
        end
    end
end

print("[DecryptSkillSys] GVDrive_Utils.lua loaded successfully")

print("[DecryptSkillSys] GVDrive_Utils loaded (simplified version)")