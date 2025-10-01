
GVDrive_Utils = {}

-- Use Spanish canonical rarity keys: Facil, Moderado, Dificil
local rarityDefaults = {
    Normal = {
        successBonus = 2.0,
        malwareChance = 5.0,
        laptopDamageMin = 3,
        laptopDamageMax = 5,
        xpBonus = 0.0,
        lootChance = 0.1,
    },
    Facil = {
        successBonus = 4.5,
        malwareChance = 7.0,
        laptopDamageMin = 5,
        laptopDamageMax = 10,
        xpBonus = 0.0,
        lootChance = 0.1,
    },
    Dificil = {
        successBonus = 6.5,
        malwareChance = 12.0,
        laptopDamageMin = 15,
        laptopDamageMax = 20,
        xpBonus = 0.0,
        lootChance = 0.3,
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
    -- Canonical Spanish rarity handling: Facil / Moderado / Dificil
    if not info then return "Normal" end
    if info.isSkillSpecific then
        local rarity = tostring(info.rarity or "")
        local r = rarity:lower()

        -- Spanish explicit matches
        if r == "dificil" or r == "difícil" or r:find("dif") then
            return "Dificil"
        end
        if r == "moderado" or r:find("mod") then
            -- We treat Moderado as the middle tier mapping to Facil-like defaults
            return "Facil"
        end
        if r == "facil" or r == "fácil" or r:find("fac") then
            return "Facil"
        end

        return "Normal"
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
    if type(defaults) ~= "table" then
        defaults = rarityDefaults.Normal or {}
    end
    return {
        successBonus = getSandboxRarityValue(key, "_Success_Bonus", defaults.successBonus),
        malwareChance = getSandboxRarityValue(key, "_Malware_Chance", defaults.malwareChance),
        laptopDamageMin = getSandboxRarityValue(key, "_Laptop_Damage_Min", defaults.laptopDamageMin),
        laptopDamageMax = getSandboxRarityValue(key, "_Laptop_Damage_Max", defaults.laptopDamageMax),
        xpBonus = getSandboxRarityValue(key, "_XP_Bonus", defaults.xpBonus),
        lootChance = getSandboxRarityValue(key, "_Loot_Chance", defaults.lootChance),
    }
end

-- Public numeric sandbox reader (safe wrapper)
function GVDrive_Utils.getSandboxNumber(name, default)
    -- Some sandbox numbers will be stored in the new 0.0..5.0 scale
    -- We normalize them back into engine-expected ranges where necessary.
    local v = getSandboxNumber(name, default)
    -- Conversion table: keys that use the 0..5 scale and should be mapped to base percent or numeric
    local scale5_keys = {
        USB_WorldLoot_Chance = true,
        Laptop_WorldLoot_Chance = true,
        EliteDrive_WorldLoot_Chance = true,
        SkillUSB_WorldLoot_Chance = true,
        USB_ZombieDrop_Chance = true,
        Laptop_ZombieDrop_Chance = true,
        EliteDrive_ZombieDrop_Chance = true,
        Antivirus_ZombieDrop_Chance = true,
        Antivirus_Norton_Drop_Rate = true,
        Antivirus_Kaspersky_Drop_Rate = true,
        Antivirus_McAfee_Drop_Rate = true,
        Antivirus_MalwareBytes_Drop_Rate = true,
        Antivirus_Spawn_Rate = true,
    }

    if scale5_keys[name] and type(v) == 'number' then
        -- Map 0..5 range to 0..100 percentage scale for engine logic
        local mapped = (v / 5.0) * 100.0
        if mapped < 0 then mapped = 0 end
        if mapped > 100 then mapped = 100 end
        return mapped
    end
    return v
end

-- Public boolean sandbox reader (safe wrapper)
function GVDrive_Utils.getSandboxBool(name, default)
    local sandbox = getSandbox()
    if not sandbox then return default end
    local v = sandbox[name]
    if v == nil then return default end
    if type(v) == 'boolean' then return v end
    if type(v) == 'number' then return v ~= 0 end
    if type(v) == 'string' then
        local lower = v:lower()
        if lower == 'true' or lower == 'yes' or lower == '1' then return true end
        return false
    end
    return default
end

local function buildDriveInfo(skill, rarity, isUSB)
    local perk = GVDrive_Utils.getSkillPerk(skill)
    local info = {
        skill = perk,
        skillName = skill,
        rarity = rarity,
        isUSB = isUSB,
        isFloppy = false, -- No longer supporting floppies
        isLegacy = false,
        isSkillSpecific = true,
    }

    -- Map incoming rarity strings (from item suffixes) into difficulty
    local lower = tostring(rarity or ""):lower()
    if lower == "dificil" or lower == "difícil" or lower:find("dif") then
        info.difficulty = "Hard"
    elseif lower == "moderado" or lower == "moder" then
        info.difficulty = "Medium"
    elseif lower == "facil" or lower == "fácil" or lower:find("fac") then
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
            local info = buildDriveInfo(skill, rarity, true)
            info.rarityKey = getRarityKeyFromInfo(info)
            return info
        end
    end

    -- Legacy drives fallback (no more floppy support)
    local info = {
        skill = nil,
        difficulty = "Easy",
        isUSB = (itemType == "USB_Closed" or itemType == "USBOpened" or itemType == "USBOpened_Damaged"),
        isFloppy = false, -- No longer supporting floppies
        isLegacy = true,
        isSkillSpecific = false,
        rarity = "Normal",
    }
    info.rarityKey = getRarityKeyFromInfo(info)
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
            local r = tostring(driveInfo.rarity or ""):lower()
            if r == "dificil" or r == "difícil" or r:find("dif") then
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
            -- No more floppy support - default to USB settings
            baseMin = getSandboxNumber("USB_Min_Experience", 35)
            baseMax = getSandboxNumber("USB_Max_Experience", 245)
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
    if not skillName then return nil end

    -- Try engine-provided resolver first if available (safer across versions)
    if Perks and Perks.FromString then
        local ok, perk = pcall(Perks.FromString, skillName)
        if ok and perk then return perk end
        -- Also try with common casing variants
        ok, perk = pcall(Perks.FromString, skillName:lower())
        if ok and perk then return perk end
    end

    -- Explicit mapping for known skill tags used in scripts. If a Perks constant
    -- is unavailable in a particular engine version, the table entry will be
    -- nil and caller should handle it gracefully.
    local skillMap = {
        ["Woodwork"] = Perks and Perks.Woodwork,
        ["Electricity"] = Perks and Perks.Electricity,
        ["Farming"] = Perks and Perks.Farming,
        ["Aiming"] = Perks and Perks.Aiming,
        ["Cooking"] = Perks and Perks.Cooking,
        ["Sneak"] = Perks and Perks.Sneak,
        ["Axe"] = Perks and Perks.Axe,
        ["Fitness"] = Perks and Perks.Fitness,
        ["Doctor"] = Perks and Perks.Doctor,
        ["Survivalist"] = Perks and Perks.Survivalist,
        ["Mechanics"] = Perks and Perks.Mechanics,
        ["Tailoring"] = Perks and Perks.Tailoring,
        ["Maintenance"] = Perks and Perks.Maintenance,
        ["SmallBlade"] = Perks and Perks.SmallBlade,
        ["LongBlade"] = Perks and Perks.LongBlade,
        ["SmallBlunt"] = Perks and Perks.SmallBlunt,
        ["LongBlunt"] = Perks and Perks.LongBlunt,
        ["Spear"] = Perks and Perks.Spear,
        ["Trapping"] = Perks and Perks.Trapping,
        ["Fishing"] = Perks and Perks.Fishing,
        ["Sprinting"] = Perks and Perks.Sprinting,
        ["Strength"] = Perks and Perks.Strength,
        ["Nimble"] = Perks and Perks.Nimble,
        ["Lightfoot"] = Perks and Perks.Lightfoot,
    }

    -- Direct lookup (case-sensitive first, then try capitalized/lower)
    if skillMap[skillName] then return skillMap[skillName] end
    local cap = tostring(skillName):gsub("^%l", string.upper)
    if skillMap[cap] then return skillMap[cap] end

    -- Last resort: if Perks.FromString didn't work earlier, try again with
    -- the capitalized form inside pcall to avoid throwing errors.
    if Perks and Perks.FromString then
        local ok, perk = pcall(Perks.FromString, cap)
        if ok and perk then return perk end
    end

    return nil
end

function GVDrive_Utils.getPerkFromName(skillName)
    return GVDrive_Utils.getSkillPerk(skillName)
end

function GVDrive_Utils.getPerkName(perk)
    if not perk then return "Unknown" end

    -- If a string was passed in, assume it's already the name
    if type(perk) == 'string' then return perk end

    -- Build reverse map with broad coverage; missing Perks constants will
    -- simply be nil and ignored.
    local perkNames = {
        [Perks and Perks.Woodwork] = "Woodwork",
        [Perks and Perks.Electricity] = "Electricity",
        [Perks and Perks.Farming] = "Farming",
        [Perks and Perks.Aiming] = "Aiming",
        [Perks and Perks.Cooking] = "Cooking",
        [Perks and Perks.Sneak] = "Sneak",
        [Perks and Perks.Axe] = "Axe",
        [Perks and Perks.Fitness] = "Fitness",
        [Perks and Perks.Doctor] = "Doctor",
        [Perks and Perks.Survivalist] = "Survivalist",
        [Perks and Perks.Mechanics] = "Mechanics",
        [Perks and Perks.Tailoring] = "Tailoring",
        [Perks and Perks.Maintenance] = "Maintenance",
        [Perks and Perks.SmallBlade] = "SmallBlade",
        [Perks and Perks.LongBlade] = "LongBlade",
        [Perks and Perks.SmallBlunt] = "SmallBlunt",
        [Perks and Perks.LongBlunt] = "LongBlunt",
        [Perks and Perks.Spear] = "Spear",
        [Perks and Perks.Trapping] = "Trapping",
        [Perks and Perks.Fishing] = "Fishing",
        [Perks and Perks.Sprinting] = "Sprinting",
        [Perks and Perks.Strength] = "Strength",
        [Perks and Perks.Nimble] = "Nimble",
        [Perks and Perks.Lightfoot] = "Lightfoot",
    }

    if perkNames[perk] then return perkNames[perk] end

    -- If Perks exposes a debugger-friendly tostring or FromString inversion,
    -- attempt to use it without throwing.
    if Perks and Perks.getPerk then
        local ok, name = pcall(function() return Perks.getPerk(perk) end)
        if ok and name then return tostring(name) end
    end

    return "Unknown"
end

function GVDrive_Utils.getDifficultyForRarity(rarity)
    local value = tostring(rarity or "")
    local lower = value:lower()
    if lower == "dificil" or lower == "difícil" or lower:find("dif") then
        return "Hard"
    elseif lower == "moderado" or lower == "moder" then
        return "Medium"
    elseif lower == "facil" or lower == "fácil" or lower:find("fac") then
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
        local r = tostring(driveInfo.rarity or ""):lower()
        if r == "dificil" or r == "difícil" or r:find("dif") then
            base = 58.5
        else
            base = 50.5
        end
    else
        if driveInfo.isUSB then
            base = getSandboxNumber("USB_Decrypt_Success_Chance", 33)
        else
            -- No more floppy support - default to USB settings
            base = getSandboxNumber("USB_Decrypt_Success_Chance", 33)
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

-- Expose metadata for known sandbox keys to help UI/tooltips show ranges
function GVDrive_Utils.getSandboxKeyMeta(name)
    -- Default unknown meta: full percent range
    local defaultMeta = { min = 0.0, max = 100.0, def = 0.0, scale = "percent" }

    local scale5 = {
        USB_WorldLoot_Chance = { min = 0.0, max = 5.0, def = 1.0, scale = "0-5" },
        Laptop_WorldLoot_Chance = { min = 0.0, max = 5.0, def = 1.0, scale = "0-5" },
        EliteDrive_WorldLoot_Chance = { min = 0.0, max = 5.0, def = 0.1, scale = "0-5" },
        SkillUSB_WorldLoot_Chance = { min = 0.0, max = 5.0, def = 0.2, scale = "0-5" },
        USB_ZombieDrop_Chance = { min = 0.0, max = 5.0, def = 0.4, scale = "0-5" },
        Laptop_ZombieDrop_Chance = { min = 0.0, max = 5.0, def = 0.125, scale = "0-5" },
        EliteDrive_ZombieDrop_Chance = { min = 0.0, max = 5.0, def = 0.05, scale = "0-5" },
        Antivirus_ZombieDrop_Chance = { min = 0.0, max = 5.0, def = 0.167, scale = "0-5" },
        Antivirus_Norton_Drop_Rate = { min = 0.0, max = 5.0, def = 0.4, scale = "0-5" },
        Antivirus_Kaspersky_Drop_Rate = { min = 0.0, max = 5.0, def = 0.3, scale = "0-5" },
        Antivirus_McAfee_Drop_Rate = { min = 0.0, max = 5.0, def = 0.2, scale = "0-5" },
        Antivirus_MalwareBytes_Drop_Rate = { min = 0.0, max = 5.0, def = 0.05, scale = "0-5" },
        Antivirus_Spawn_Rate = { min = 0.0, max = 5.0, def = 2.0, scale = "0-5" },
    }

    if name and scale5[name] then
        return scale5[name]
    end

    -- Numeric keys that are direct percentages or counts
    local percentKeys = {
        USB_Min_Experience = { min = 1, max = 1000, def = 35, scale = "number" },
        USB_Max_Experience = { min = 1, max = 5000, def = 245, scale = "number" },
        USB_Decrypt_Success_Chance = { min = 0, max = 100, def = 33, scale = "percent" },
        Malware_Chance = { min = 0, max = 100, def = 15, scale = "percent" },
    }

    if name and percentKeys[name] then
        return percentKeys[name]
    end

    return defaultMeta
end

function GVDrive_Utils.calculateDamageRisk(driveInfo)
    return GVDrive_Utils.getMalwareChance(driveInfo)
end

-- Gate non-error prints behind a central debug flag
-- Ensure config is loaded, but don't error if it's missing
pcall(require, "shared/GVDrive_Config")
local DEBUG = (GVDrive_Config and GVDrive_Config.getDebug) and GVDrive_Config.getDebug() or false

-- Defensive require for GVDebug: some load orders may not have it available.
-- Use a quiet no-op fallback so calls to GVDebug.debugPrint never cause runtime errors.
local _ok_dbg, _dbg_mod = pcall(require, "shared/GVDebug")
local GVDebug = nil
if _ok_dbg and type(_dbg_mod) == "table" and type(_dbg_mod.debugPrint) == "function" then
    GVDebug = _dbg_mod
else
    GVDebug = { debugPrint = function(...) end, testPrint = function(...) end }
end

GVDebug.debugPrint("GVDrive_Utils.lua loaded with rarity-aware settings")

-- Normalized percent helper
function GVDrive_Utils.getSandboxPercent(name, default)
    default = default or 0
    local sandbox = (SandboxVars and SandboxVars.GVDrive) or nil
    if not sandbox then return default end
    local raw = sandbox[name]
    if raw == nil then return default end
    local n = tonumber(raw)
    if not n then return default end
    -- Accept decimal fractions (0 < n < 1) as fractional percent (e.g. 0.4 -> 0.4)
    -- Accept values 1..100 as direct percent
    if n < 0 then return 0 end
    -- If the key is one that uses the 0..5 normalized scale, convert to percent
    local scale5_keys = {
        USB_WorldLoot_Chance = true,
        Laptop_WorldLoot_Chance = true,
        EliteDrive_WorldLoot_Chance = true,
        SkillUSB_WorldLoot_Chance = true,
        USB_ZombieDrop_Chance = true,
        Laptop_ZombieDrop_Chance = true,
        EliteDrive_ZombieDrop_Chance = true,
        Antivirus_ZombieDrop_Chance = true,
        Antivirus_Spawn_Rate = true,
    }

    if scale5_keys[name] then
        -- raw is expected in 0..5, map to 0..100
        if n > 5 then n = 5 end
        return (n / 5.0) * 100.0
    end
    if n > 100 then return 100 end
    return n
end

function GVDrive_Utils.calculateMinigameXP(skillType, difficulty)
    -- Calcular XP usando configuración sandbox
    local minXP = getSandboxNumber("USB_Min_Experience", 25)
    local maxXP = getSandboxNumber("USB_Max_Experience", 50)

    -- Generar valor aleatorio
    local baseXP = ZombRand(minXP, maxXP + 1)

    -- Aplicar multiplicador por dificultad
    local multiplier = 1.0
    if difficulty == "Easy" then
        multiplier = getSandboxNumber("Facil_Success_Bonus", 0.8)
    elseif difficulty == "Moderate" then
        multiplier = getSandboxNumber("Moderado_Success_Bonus", 1.2)
    elseif difficulty == "Expert" then
        multiplier = getSandboxNumber("Dificil_Success_Bonus", 1.5)
    end

    local finalXP = math.floor(baseXP * multiplier)
    return math.max(1, finalXP)
end

function GVDrive_Utils.calculateMinigameDamage(difficulty)
    -- Calcular daño a laptop según dificultad
    local minDamage = 0
    local maxDamage = 0

    if difficulty == "Easy" then
        minDamage = getSandboxNumber("Facil_Laptop_Damage_Min", 3)
        maxDamage = getSandboxNumber("Facil_Laptop_Damage_Max", 5)
    elseif difficulty == "Moderate" then
        minDamage = getSandboxNumber("Moderado_Laptop_Damage_Min", 8)
        maxDamage = getSandboxNumber("Moderado_Laptop_Damage_Max", 12)
    elseif difficulty == "Expert" then
        minDamage = getSandboxNumber("Dificil_Laptop_Damage_Min", 15)
        maxDamage = getSandboxNumber("Dificil_Laptop_Damage_Max", 20)
    end

    return ZombRand(minDamage, maxDamage + 1)
end

function GVDrive_Utils.applyMinigameResult(player, laptopItem, skillType, difficulty, success)
    if not player or not skillType then
        return false
    end

    -- Obtener perk correspondiente a la habilidad
    local perk = GVDrive_Utils.getSkillPerk(skillType)
    if not perk then
        print("GVDrive_Utils: Could not find perk for skill: " .. tostring(skillType))
        return false
    end

    if success then
        -- ✅ ÉXITO: Otorgar experiencia
        local xp = GVDrive_Utils.calculateMinigameXP(skillType, difficulty)
        
        -- 🎯 NEURAL BOOST: Aplicar multiplicador de XP si está activo
        if NeuralBoostSystem and NeuralBoostSystem.modifyXPGain then
            xp = NeuralBoostSystem.modifyXPGain(player, skillType, xp)
        end
        
        player:getXp():AddXP(perk, xp)
        print("GVDrive_Utils: Awarded " .. xp .. " XP in " .. skillType)
        
        -- 🎁 USB SURPRISE: Verificar si hay sorpresa
        if USBSurpriseSystem and USBSurpriseSystem.triggerSurprise then
            local hasSurprise = USBSurpriseSystem.triggerSurprise(player, difficulty)
            if hasSurprise then
                -- Mensaje contextual de sorpresa
                if ContextualMessages and ContextualMessages.onSpecialEvent then
                    ContextualMessages.onSpecialEvent(player, laptopItem, "surprise_found")
                end
            end
        end
        
        -- ⚡ NEURAL BOOST: Verificar si este USB otorga buff temporal
        if NeuralBoostSystem and NeuralBoostSystem.activateBoost then
            NeuralBoostSystem.activateBoost(player, difficulty)
        end
        
        -- 🔊 SONIDO: Reproducir sonido de éxito
        if DynamicSoundSystem and DynamicSoundSystem.playSuccessSound then
            local isEpic = (difficulty == "Expert" or difficulty == "Elite")
            DynamicSoundSystem.playSuccessSound(player, isEpic)
        end
        
        -- 💬 MENSAJE CONTEXTUAL: Éxito
        if ContextualMessages and ContextualMessages.onMinigameSuccess then
            ContextualMessages.onMinigameSuccess(player, laptopItem)
        end
        
        return true
    else
        -- ❌ FALLO: Aplicar daño a laptop
        if laptopItem then
            local damage = GVDrive_Utils.calculateMinigameDamage(difficulty)
            local currentHealth = 0

            -- Obtener health actual usando LaptopSystem si está disponible
            if LaptopSystem and LaptopSystem.getLaptopHealth then
                currentHealth = LaptopSystem.getLaptopHealth(laptopItem)
                LaptopSystem.damageLaptop(laptopItem, damage)
                print("GVDrive_Utils: Laptop damaged by " .. damage .. "% (" .. currentHealth .. "% -> " .. (currentHealth - damage) .. "%)")
            end
            
            -- 🌡️ THERMAL SYSTEM: Agregar calor por usar el minijuego
            if LaptopThermalSystem and LaptopThermalSystem.addHeat then
                local newTemp = LaptopThermalSystem.addHeat(laptopItem, difficulty)
                
                -- Verificar sobrecalentamiento
                if LaptopThermalSystem.checkOverheat then
                    local isOverheated = LaptopThermalSystem.checkOverheat(player, laptopItem)
                    
                    if isOverheated then
                        -- Mensaje contextual de sobrecalentamiento
                        if ContextualMessages and ContextualMessages.onSpecialEvent then
                            ContextualMessages.onSpecialEvent(player, laptopItem, "overheat_warning")
                        end
                        
                        -- Sonido de alarma
                        if DynamicSoundSystem and DynamicSoundSystem.playOverheatAlarm then
                            DynamicSoundSystem.playOverheatAlarm(player)
                        end
                    end
                end
            end
            
            -- ⚠️ VERIFICAR Y EJECUTAR EVENTOS ALEATORIOS POR FALLOS
            if LaptopEvents and LaptopEvents.checkAndTriggerEvent then
                -- Obtener square de la laptop
                local laptopSquare = nil
                
                -- Intentar obtener square del worldItem
                if laptopItem.getWorldItem and type(laptopItem.getWorldItem) == "function" then
                    local worldItem = laptopItem:getWorldItem()
                    if worldItem and worldItem.getSquare then
                        laptopSquare = worldItem:getSquare()
                    end
                end
                
                -- Fallback: usar square del jugador
                if not laptopSquare and player and player.getCurrentSquare then
                    laptopSquare = player:getCurrentSquare()
                end
                
                -- Ejecutar verificación de eventos
                if laptopSquare then
                    LaptopEvents.checkAndTriggerEvent(player, laptopItem, laptopSquare)
                else
                    print("GVDrive_Utils: Could not determine laptop square for event trigger")
                end
            end
            
            -- 🔊 SONIDO: Reproducir sonido de fallo
            if DynamicSoundSystem and DynamicSoundSystem.playFailureSound then
                DynamicSoundSystem.playFailureSound(player)
            end
            
            -- 💬 MENSAJE CONTEXTUAL: Fallo
            if ContextualMessages and ContextualMessages.onMinigameFailure then
                ContextualMessages.onMinigameFailure(player, laptopItem)
            end
        end
        return false
    end
end

-- ✅ Las funciones ya están expuestas automáticamente como parte del módulo GVDrive_Utils
-- No es necesario reasignarlas explícitamente

-- ========== COLORES POR SKILL PARA MINIJUEGOS ==========
-- Diccionario centralizado de colores temáticos por skill para reutilización en múltiples minijuegos
-- Formato: {border = {r,g,b,a}, title = {r,g,b,a}, accent = {r,g,b,a}}
GVDrive_Utils.skillColors = {
    -- Skills básicas de supervivencia
    ["Farming"] = {
        border = {r=0.2, g=0.8, b=0.2, a=1},    -- Verde agrícola
        title = {r=0.3, g=1, b=0.3, a=1},       -- Verde brillante
        accent = {r=0.4, g=0.9, b=0.4, a=1}     -- Verde claro
    },
    ["Electricity"] = {
        border = {r=1, g=1, b=0.2, a=1},        -- Amarillo eléctrico
        title = {r=1, g=1, b=0.4, a=1},         -- Amarillo brillante
        accent = {r=1, g=1, b=0.6, a=1}         -- Amarillo claro
    },
    ["Woodwork"] = {
        border = {r=0.6, g=0.4, b=0.2, a=1},    -- Marrón madera
        title = {r=0.8, g=0.6, b=0.4, a=1},     -- Marrón claro
        accent = {r=0.7, g=0.5, b=0.3, a=1}     -- Marrón medio
    },
    ["Cooking"] = {
        border = {r=1, g=0.6, b=0.2, a=1},      -- Naranja cocción
        title = {r=1, g=0.8, b=0.4, a=1},       -- Naranja brillante
        accent = {r=1, g=0.7, b=0.3, a=1}       -- Naranja medio
    },
    ["Doctor"] = {
        border = {r=1, g=0.2, b=0.2, a=1},      -- Rojo médico
        title = {r=1, g=0.4, b=0.4, a=1},       -- Rojo claro
        accent = {r=1, g=0.3, b=0.3, a=1}       -- Rojo medio
    },
    ["Fitness"] = {
        border = {r=0.8, g=0.2, b=0.8, a=1},    -- Magenta fitness
        title = {r=1, g=0.4, b=1, a=1},         -- Magenta brillante
        accent = {r=0.9, g=0.3, b=0.9, a=1}     -- Magenta medio
    },
    ["Aiming"] = {
        border = {r=0.2, g=0.2, b=1, a=1},      -- Azul precisión
        title = {r=0.4, g=0.4, b=1, a=1},       -- Azul brillante
        accent = {r=0.3, g=0.3, b=1, a=1}       -- Azul medio
    },
    ["Sneak"] = {
        border = {r=0.5, g=0.5, b=0.5, a=1},    -- Gris sigilo
        title = {r=0.7, g=0.7, b=0.7, a=1},     -- Gris claro
        accent = {r=0.6, g=0.6, b=0.6, a=1}     -- Gris medio
    },
    ["Axe"] = {
        border = {r=0.4, g=0.2, b=0.1, a=1},    -- Marrón oscuro hacha
        title = {r=0.6, g=0.4, b=0.2, a=1},     -- Marrón rojizo
        accent = {r=0.5, g=0.3, b=0.15, a=1}    -- Marrón rojizo oscuro
    },
    ["Survivalist"] = {
        border = {r=0.3, g=0.6, b=0.3, a=1},    -- Verde oliva supervivencia
        title = {r=0.5, g=0.8, b=0.5, a=1},     -- Verde oliva claro
        accent = {r=0.4, g=0.7, b=0.4, a=1}     -- Verde oliva medio
    },
    -- Skills avanzadas
    ["Mechanics"] = {
        border = {r=0.7, g=0.7, b=0.2, a=1},    -- Dorado mecánico
        title = {r=0.9, g=0.9, b=0.4, a=1},     -- Dorado brillante
        accent = {r=0.8, g=0.8, b=0.3, a=1}     -- Dorado medio
    },
    ["Tailoring"] = {
        border = {r=0.8, g=0.4, b=0.8, a=1},    -- Lila costura
        title = {r=1, g=0.6, b=1, a=1},         -- Lila brillante
        accent = {r=0.9, g=0.5, b=0.9, a=1}     -- Lila medio
    },
    ["Maintenance"] = {
        border = {r=0.5, g=0.5, b=0.8, a=1},    -- Azul grisáceo mantenimiento
        title = {r=0.7, g=0.7, b=1, a=1},       -- Azul grisáceo claro
        accent = {r=0.6, g=0.6, b=0.9, a=1}     -- Azul grisáceo medio
    },
    -- Skills de combate cuerpo a cuerpo
    ["SmallBlade"] = {
        border = {r=0.9, g=0.9, b=0.9, a=1},    -- Plata cuchillos
        title = {r=1, g=1, b=1, a=1},           -- Blanco brillante
        accent = {r=0.95, g=0.95, b=0.95, a=1}  -- Plata claro
    },
    ["LongBlade"] = {
        border = {r=0.8, g=0.8, b=0.8, a=1},    -- Plata espadas
        title = {r=0.95, g=0.95, b=0.95, a=1},  -- Plata brillante
        accent = {r=0.85, g=0.85, b=0.85, a=1}  -- Plata medio
    },
    ["SmallBlunt"] = {
        border = {r=0.6, g=0.4, b=0.2, a=1},    -- Marrón oscuro mazas
        title = {r=0.8, g=0.6, b=0.4, a=1},     -- Marrón claro
        accent = {r=0.7, g=0.5, b=0.3, a=1}     -- Marrón medio
    },
    ["LongBlunt"] = {
        border = {r=0.5, g=0.3, b=0.1, a=1},    -- Marrón muy oscuro
        title = {r=0.7, g=0.5, b=0.3, a=1},     -- Marrón rojizo oscuro
        accent = {r=0.6, g=0.4, b=0.2, a=1}     -- Marrón rojizo
    },
    ["Spear"] = {
        border = {r=0.4, g=0.6, b=0.8, a=1},    -- Azul lanza
        title = {r=0.6, g=0.8, b=1, a=1},       -- Azul brillante
        accent = {r=0.5, g=0.7, b=0.9, a=1}     -- Azul medio
    },
    -- Skills de caza/supervivencia avanzada
    ["Trapping"] = {
        border = {r=0.4, g=0.3, b=0.2, a=1},    -- Marrón trampa
        title = {r=0.6, g=0.5, b=0.4, a=1},     -- Marrón claro
        accent = {r=0.5, g=0.4, b=0.3, a=1}     -- Marrón medio
    },
    ["Fishing"] = {
        border = {r=0.2, g=0.5, b=0.8, a=1},    -- Azul agua
        title = {r=0.4, g=0.7, b=1, a=1},       -- Azul brillante
        accent = {r=0.3, g=0.6, b=0.9, a=1}     -- Azul medio
    },
    -- Skills físicas
    ["Sprinting"] = {
        border = {r=1, g=0.8, b=0.2, a=1},      -- Amarillo velocidad
        title = {r=1, g=0.9, b=0.4, a=1},       -- Amarillo brillante
        accent = {r=1, g=0.85, b=0.3, a=1}      -- Amarillo medio
    },
    ["Strength"] = {
        border = {r=0.8, g=0.3, b=0.3, a=1},    -- Rojo fuerza
        title = {r=1, g=0.5, b=0.5, a=1},       -- Rojo brillante
        accent = {r=0.9, g=0.4, b=0.4, a=1}     -- Rojo medio
    },
    ["Nimble"] = {
        border = {r=0.6, g=0.8, b=0.4, a=1},    -- Verde lima agilidad
        title = {r=0.8, g=1, b=0.6, a=1},       -- Verde lima brillante
        accent = {r=0.7, g=0.9, b=0.5, a=1}     -- Verde lima medio
    },
    ["Lightfoot"] = {
        border = {r=0.7, g=0.5, b=0.9, a=1},    -- Púrpura sigilo
        title = {r=0.9, g=0.7, b=1, a=1},       -- Púrpura brillante
        accent = {r=0.8, g=0.6, b=0.95, a=1}    -- Púrpura medio
    }
}

-- Función para obtener colores por skill (con fallback seguro)
function GVDrive_Utils.getSkillColors(skillName)
    if not skillName then
        return GVDrive_Utils.skillColors["Farming"] -- Fallback por defecto
    end

    -- Buscar por nombre exacto
    if GVDrive_Utils.skillColors[skillName] then
        return GVDrive_Utils.skillColors[skillName]
    end

    -- Buscar por nombre capitalizado
    local capName = tostring(skillName):gsub("^%l", string.upper)
    if GVDrive_Utils.skillColors[capName] then
        return GVDrive_Utils.skillColors[capName]
    end

    -- Fallback a Farming si no se encuentra
    return GVDrive_Utils.skillColors["Farming"]
end

-- ✅ EXPONER MÓDULO GLOBALMENTE PARA QUE ESTÉ DISPONIBLE EN TODOS LOS ARCHIVOS
_G.GVDrive_Utils = GVDrive_Utils