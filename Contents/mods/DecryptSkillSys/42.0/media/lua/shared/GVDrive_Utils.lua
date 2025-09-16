-- GVDrive Utility Functions
-- Shared helpers for drive info, sandbox integration, and balancing

GVDrive_Utils = {}

local rarityDefaults = {
    Normal = {
        successBonus = 2.0,
        malwareChance = 5.0,
        laptopDamageMin = 3,
        laptopDamageMax = 5,
        xpBonus = 0.0,
        lootChance = 5.0,
    },
    Common = {
        successBonus = 4.5,
        malwareChance = 7.0,
        laptopDamageMin = 5,
        laptopDamageMax = 10,
        xpBonus = 0.0,
        lootChance = 2.0,
    },
    Advanced = {
        successBonus = 6.5,
        malwareChance = 12.0,
        laptopDamageMin = 15,
        laptopDamageMax = 20,
        xpBonus = 0.0,
        lootChance = 10.0,
    },
}

local function getSandbox()
    return (SandboxVars and SandboxVars.GVDrive) or nil
end

local function toNumber(value, default)
    if value == nil then return default end
    local num = tonumber(value)
    if num == nil then return default end
    return num
end

local function clamp(value, minVal, maxVal)
    if value == nil then return minVal end
    if value < minVal then return minVal end
    if value > maxVal then return maxVal end
    return value
end

local function getSandboxNumber(name, default)
    local sandbox = getSandbox()
    if not sandbox then return default end
    local value = sandbox[name]
    if value == nil then return default end
    return toNumber(value, default)
end

local function getRarityKeyFromInfo(info)
    if not info then return "Normal" end
    if info.isSkillSpecific then
        local rarity = tostring(info.rarity or "")
        if rarity:lower() == "rare" or rarity:lower() == "advanced" then
            return "Advanced"
        else
            return "Common"
        end
    end
    return "Normal"
end

function GVDrive_Utils.getRarityKey(info)
    return getRarityKeyFromInfo(info)
end

local function getSandboxRarityValue(key, suffix, default)
    local sandbox = getSandbox()
    if sandbox then
        local value = sandbox[key .. suffix]
        if value ~= nil then
            return toNumber(value, default)
        end
    end
    return default
end

function GVDrive_Utils.getRaritySettings(info)
    local key = getRarityKeyFromInfo(info)
    local defaults = rarityDefaults[key] or rarityDefaults.Normal
    return {
        successBonus = getSandboxRarityValue(key, "_Success_Bonus", defaults.successBonus),
        malwareChance = getSandboxRarityValue(key, "_Malware_Chance", defaults.malwareChance),
        laptopDamageMin = getSandboxRarityValue(key, "_Laptop_Damage_Min", defaults.laptopDamageMin),
        laptopDamageMax = getSandboxRarityValue(key, "_Laptop_Damage_Max", defaults.laptopDamageMax),
        xpBonus = getSandboxRarityValue(key, "_XP_Bonus", defaults.xpBonus),
        lootChance = getSandboxRarityValue(key, "_Loot_Chance", defaults.lootChance),
    }
end

local function buildDriveInfo(skill, rarity, isUSB, isFloppy)
    local perk = GVDrive_Utils.getSkillPerk(skill)
    local info = {
        skill = perk,
        skillName = skill,
        rarity = rarity,
        isUSB = isUSB,
        isFloppy = isFloppy,
        isLegacy = false,
        isSkillSpecific = true,
    }

    if rarity == "Rare" or rarity == "Advanced" then
        info.difficulty = "Hard"
    elseif rarity == "Common" then
        info.difficulty = "Medium"
    else
        info.difficulty = "Easy"
    end

    return info
end

-- Get drive info - enhanced version for skill drives
function GVDrive_Utils.getDriveInfo(item)
    if not item then return nil end

    local itemType = item:getType()
    local fullType = item.getFullType and item:getFullType() or itemType

    if string.find(itemType, "SkillDrive_") then
        local parts = {}
        for part in string.gmatch(itemType, "([^_]+)") do
            table.insert(parts, part)
        end
        if #parts >= 3 then
            local skill = parts[2]
            local rarity = parts[3]
            local info = buildDriveInfo(skill, rarity, true, false)
            info.rarityKey = GVDrive_Utils.getRarityKey(info)
            return info
        end
    elseif string.find(itemType, "SkillFloppy_") then
        local parts = {}
        for part in string.gmatch(itemType, "([^_]+)") do
            table.insert(parts, part)
        end
        if #parts >= 3 then
            local skill = parts[2]
            local rarity = parts[3]
            local info = buildDriveInfo(skill, rarity, false, true)
            info.difficulty = "Easy"
            info.rarityKey = GVDrive_Utils.getRarityKey(info)
            return info
        end
    end

    -- Legacy drives fallback
    local info = {
        skill = nil,
        difficulty = "Easy",
        isUSB = (itemType == "USB_Closed" or itemType == "USBOpened" or itemType == "USBOpened_Damaged"),
        isFloppy = (itemType == "FloppyDrive" or itemType == "FloppyDrive_Damaged"),
        isLegacy = true,
        isSkillSpecific = false,
        rarity = "Normal",
    }
    info.rarityKey = GVDrive_Utils.getRarityKey(info)
    return info
end

local function applyXpBonus(baseMin, baseMax, bonusPercent)
    local multiplier = 1 + (bonusPercent or 0) / 100
    local resultMin = math.max(1, math.floor(baseMin * multiplier))
    local resultMax = math.max(resultMin, math.floor(baseMax * multiplier))
    return resultMin, resultMax
end

-- Enhanced experience calculation for skill drives
function GVDrive_Utils.calculateDriveExperience(character, driveInfo)
    if not character or not driveInfo then return 50 end

    local baseMin, baseMax

    if driveInfo.isSkillSpecific then
        if driveInfo.isUSB then
            if (driveInfo.rarity or ""):lower() == "rare" or (driveInfo.rarity or ""):lower() == "advanced" then
                baseMin = 100
                baseMax = 300
            else
                baseMin = 50
                baseMax = 200
            end
        else
            baseMin = 35
            baseMax = 150
        end

        local currentLevel = 0
        if driveInfo.skill and character.getPerkLevel then
            currentLevel = character:getPerkLevel(driveInfo.skill) or 0
        end
        local levelPenalty = math.min(currentLevel * 5, 50)
        baseMin = math.max(baseMin - levelPenalty, 10)
        baseMax = math.max(baseMax - levelPenalty, 25)
    else
        if driveInfo.isUSB then
            baseMin = getSandboxNumber("USB_Min_Experience", 35)
            baseMax = getSandboxNumber("USB_Max_Experience", 245)
        else
            baseMin = getSandboxNumber("Floppy_Min_Experience", 25)
            baseMax = getSandboxNumber("Floppy_Max_Experience", 195)
        end
    end

    local settings = GVDrive_Utils.getRaritySettings(driveInfo)
    baseMin, baseMax = applyXpBonus(baseMin, baseMax, settings.xpBonus)

    if baseMax < baseMin then baseMax = baseMin end
    return ZombRand(math.floor(baseMin), math.floor(baseMax) + 1)
end

function GVDrive_Utils.getPerkFromDrive(drive)
    if type(drive) == "table" and drive.skill then
        return drive.skill
    end

    if type(drive) ~= "nil" and type(drive) ~= "table" then
        local ok, info = pcall(function()
            return GVDrive_Utils.getDriveInfo(drive)
        end)
        if ok and info and info.skill then
            return info.skill
        end
    end

    local skills = {
        Perks.Woodwork, Perks.Electricity, Perks.Farming, Perks.Aiming,
        Perks.Cooking, Perks.Sneak, Perks.Axe, Perks.Fitness,
        Perks.Doctor, Perks.Survivalist
    }
    return skills[ZombRand(#skills) + 1]
end

function GVDrive_Utils.getDrivePerk(drive)
    return GVDrive_Utils.getPerkFromDrive(drive)
end

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
        ["Survivalist"] = Perks.Survivalist,
    }
    return skillMap[skillName]
end

function GVDrive_Utils.getPerkFromName(skillName)
    return GVDrive_Utils.getSkillPerk(skillName)
end

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
        [Perks.Survivalist] = "Survivalist",
    }
    return perkNames[perk] or "Unknown"
end

function GVDrive_Utils.getDifficultyForRarity(rarity)
    local value = tostring(rarity or "")
    local lower = value:lower()
    if lower == "rare" or lower == "advanced" then
        return "Hard"
    elseif lower == "common" then
        return "Medium"
    else
        return "Easy"
    end
end

function GVDrive_Utils.getSuccessChance(driveInfo)
    if not driveInfo then return getSandboxNumber("USB_Decrypt_Success_Chance", 50) end
    local settings = GVDrive_Utils.getRaritySettings(driveInfo)

    local base
    if driveInfo.isSkillSpecific then
        if (driveInfo.rarity or ""):lower() == "rare" or (driveInfo.rarity or ""):lower() == "advanced" then
            base = 58.5
        else
            base = 50.5
        end
    else
        if driveInfo.isUSB then
            base = getSandboxNumber("USB_Decrypt_Success_Chance", 33)
        else
            base = getSandboxNumber("Floppy_Decrypt_Success_Chance", 30)
        end
    end

    local total = clamp(base + settings.successBonus, 0, 100)
    return total
end

function GVDrive_Utils.getMalwareChance(driveInfo)
    if not driveInfo then
        return getSandboxNumber("Malware_Chance", 15)
    end
    local settings = GVDrive_Utils.getRaritySettings(driveInfo)
    return clamp(settings.malwareChance or 0, 0, 100)
end

function GVDrive_Utils.getLaptopDamage(driveInfo, wasSuccess)
    local settings = GVDrive_Utils.getRaritySettings(driveInfo)
    local minVal = clamp(settings.laptopDamageMin or 1, 0, 100)
    local maxVal = clamp(settings.laptopDamageMax or minVal, minVal, 100)

    if wasSuccess then
        minVal = math.max(0, math.floor(minVal / 2))
        maxVal = math.max(minVal, math.floor(maxVal / 2))
    end

    if maxVal <= minVal then
        return minVal
    end
    return ZombRand(minVal, maxVal + 1)
end

function GVDrive_Utils.getLootChance(driveInfo)
    local settings = GVDrive_Utils.getRaritySettings(driveInfo)
    return clamp(settings.lootChance or 0, 0, 100)
end

function GVDrive_Utils.calculateDamageRisk(driveInfo)
    return GVDrive_Utils.getMalwareChance(driveInfo)
end

print("[DecryptSkillSys] GVDrive_Utils.lua loaded with rarity-aware settings")