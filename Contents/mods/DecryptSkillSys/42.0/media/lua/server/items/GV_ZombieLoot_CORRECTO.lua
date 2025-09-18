-- SOLUCIÓN DEFINITIVA - DISTRIBUCIÓN CORRECTA DE ITEMS EN ZOMBIES
-- Basado en documentación actualizada de patrones PZ B42

print("[DecryptSkillSys] Loading correct zombie loot system...")

-- Defensive requires
local function try_require(path)
    local ok, err = pcall(require, path)
    if not ok then
        print("[DecryptSkillSys] Optional require failed: " .. tostring(path))
    end
    return ok
end

try_require("Items/ProceduralDistributions")

-- FUNCIÓN PRINCIPAL: Se ejecuta cuando se CREA un zombie (no cuando muere)
function GVDrive_OnCreateZombie(zombie)
    -- Verificaciones de seguridad
    if not zombie then 
        print("[DecryptSkillSys] Zombie creation skipped - zombie is nil")
        return 
    end
    
    if not isServer() then 
        print("[DecryptSkillSys] Zombie creation skipped - client side execution")
        return 
    end
    
    -- Debug logging para cada zombie creado
    print("[DecryptSkillSys] Processing zombie creation for loot addition...")
    
    -- Get sandbox vars with fallback defaults
    local sandboxVars = (SandboxVars and SandboxVars.GVDrive) or {
        USB_ZombieDrop_Chance = 5.0,
        Laptop_ZombieDrop_Chance = 1.0,
        EliteDrive_ZombieDrop_Chance = 0.167,
        Antivirus_ZombieDrop_Chance = 0.45
    }
    
    -- Debug sandbox values
    print(string.format("[DecryptSkillSys] Sandbox values - USB: %.2f%%, Laptop: %.2f%%, Elite: %.3f%%, Antivirus: %.2f%%", 
        sandboxVars.USB_ZombieDrop_Chance or 5.0, 
        sandboxVars.Laptop_ZombieDrop_Chance or 1.0,
        sandboxVars.EliteDrive_ZombieDrop_Chance or 0.167,
        sandboxVars.Antivirus_ZombieDrop_Chance or 0.45))
    
    local inventory = zombie and zombie:getInventory()
    if not inventory then 
        print("[DecryptSkillSys] No inventory found on zombie")
        return 
    end
    
    -- Get drop chances with fallbacks
    local usbDropChance = sandboxVars.USB_ZombieDrop_Chance or 5.0
    local laptopDropChance = sandboxVars.Laptop_ZombieDrop_Chance or 1.0
    local eliteDropChance = sandboxVars.EliteDrive_ZombieDrop_Chance or 0.167
    local antivirusDropChance = sandboxVars.Antivirus_ZombieDrop_Chance or 0.45
    
    -- Roll for USB drive drop
    local usbRoll = ZombRand(10000)
    local usbThreshold = usbDropChance * 100
    print(string.format("[DecryptSkillSys] USB roll: %d vs threshold: %.1f", usbRoll, usbThreshold))
    
    if usbRoll < usbThreshold then
        local usbDrive = getRandomSkillDrive("USB")
        if usbDrive then
            inventory:AddItem(usbDrive)
            print(string.format("[DecryptSkillSys] ✅ ADDED USB drive: %s (roll %d < %.1f)", usbDrive, usbRoll, usbThreshold))
        else
            print("[DecryptSkillSys] ❌ Failed to generate USB drive")
        end
    else
        print(string.format("[DecryptSkillSys] No USB drop (roll %d >= %.1f)", usbRoll, usbThreshold))
    end
    
    -- Roll for Laptop drop
    local laptopRoll = ZombRand(10000)
    local laptopThreshold = laptopDropChance * 100
    print(string.format("[DecryptSkillSys] Laptop roll: %d vs threshold: %.1f", laptopRoll, laptopThreshold))
    
    if laptopRoll < laptopThreshold then
        local laptops = {"GValley.AsusZephLaptopClosed", "GValley.Laptop90sClosed", "GValley.PBIBM_LP90Closed"}
        local selectedLaptop = laptops[ZombRand(#laptops) + 1]
        inventory:AddItem(selectedLaptop)
        print(string.format("[DecryptSkillSys] ✅ ADDED laptop: %s (roll %d < %.1f)", selectedLaptop, laptopRoll, laptopThreshold))
    else
        print(string.format("[DecryptSkillSys] No laptop drop (roll %d >= %.1f)", laptopRoll, laptopThreshold))
    end
    
    -- Roll for Elite Drive drop
    local eliteRoll = ZombRand(10000)
    local eliteThreshold = eliteDropChance * 100
    print(string.format("[DecryptSkillSys] Elite roll: %d vs threshold: %.3f", eliteRoll, eliteThreshold))
    
    if eliteRoll < eliteThreshold then
        local eliteTypes = {"Strength", "Endurance", "Capacity", "Speed", "Luck"}
        local selectedType = eliteTypes[ZombRand(#eliteTypes) + 1]
        local eliteItem = "GValley.EliteDrive_" .. selectedType
        inventory:AddItem(eliteItem)
        print(string.format("[DecryptSkillSys] ✅ ADDED ELITE drive: %s (roll %d < %.3f)", eliteItem, eliteRoll, eliteThreshold))
    else
        print(string.format("[DecryptSkillSys] No elite drop (roll %d >= %.3f)", eliteRoll, eliteThreshold))
    end
    
    -- Roll for Antivirus drop
    local avRoll = ZombRand(10000)
    local avThreshold = antivirusDropChance * 100
    print(string.format("[DecryptSkillSys] Antivirus roll: %d vs threshold: %.2f", avRoll, avThreshold))
    
    if avRoll < avThreshold then
        local antivirusTypes = {
            {item = "GValley.Antivirus_Norton", weight = 40},
            {item = "GValley.Antivirus_Kaspersky", weight = 30},
            {item = "GValley.Antivirus_McAfee", weight = 20},
            {item = "GValley.Antivirus_MalwareBytes", weight = 10},
        }
        
        local totalWeight = 100
        local roll = ZombRand(totalWeight)
        local currentWeight = 0
        
        for _, av in ipairs(antivirusTypes) do
            currentWeight = currentWeight + av.weight
            if roll < currentWeight then
                inventory:AddItem(av.item)
                print(string.format("[DecryptSkillSys] ✅ ADDED antivirus: %s (roll %d < %.2f)", av.item, avRoll, avThreshold))
                break
            end
        end
    else
        print(string.format("[DecryptSkillSys] No antivirus drop (roll %d >= %.2f)", avRoll, avThreshold))
    end
    
    print("[DecryptSkillSys] Zombie creation processing completed")
end

-- Get random skill drive function (reutilizada del archivo original)
function getRandomSkillDrive(driveType)
    -- Check for elite drives first (still 1% chance)
    if ZombRand(100) < 1 then
        local eliteTypes = {
            "GValley.EliteDrive_Strength",
            "GValley.EliteDrive_Endurance",
            "GValley.EliteDrive_Capacity",
            "GValley.EliteDrive_Speed",
            "GValley.EliteDrive_Luck",
        }
        return eliteTypes[ZombRand(#eliteTypes) + 1]
    end

    local utils = rawget(_G, "GVDrive_Utils")

    local function getLootWeight(info)
        if utils and utils.getLootChance then
            local ok, value = pcall(utils.getLootChance, info)
            if ok and type(value) == "number" then
                return math.max(0, value)
            end
        end
        return 0
    end

    local isUSB = driveType == "USB"
    local isFloppy = driveType == "Floppy"

    -- NEW RARITY SYSTEM: Fácil/Moderado/Difícil
    local facilInfo = { isSkillSpecific = true, isUSB = isUSB, isFloppy = isFloppy, rarity = "Facil" }
    local moderadoInfo = { isSkillSpecific = true, isUSB = isUSB, isFloppy = isFloppy, rarity = "Moderado" }
    local dificilInfo = { isSkillSpecific = true, isUSB = isUSB, isFloppy = isFloppy, rarity = "Dificil" }

    local facilWeight = getLootWeight(facilInfo)
    local moderadoWeight = getLootWeight(moderadoInfo)
    local dificilWeight = isUSB and getLootWeight(dificilInfo) or 0

    -- Scale weights for better distribution
    local scaledFacil = math.max(0, math.floor(facilWeight * 10 + 0.5))
    local scaledModerado = math.max(0, math.floor(moderadoWeight * 10 + 0.5))
    local scaledDificil = math.max(0, math.floor(dificilWeight * 10 + 0.5))
    local totalScaled = scaledFacil + scaledModerado + scaledDificil

    -- Fallback weights if no sandbox values are available
    if totalScaled <= 0 then
        if driveType == "USB" then
            scaledDificil = 15   -- Difícil: 15% (muy raro)
            scaledModerado = 35  -- Moderado: 35% (común)
            scaledFacil = 50     -- Fácil: 50% (más común)
        elseif driveType == "Floppy" then
            scaledDificil = 10   -- Difícil: 10% (más raro en floppies)
            scaledModerado = 40  -- Moderado: 40%
            scaledFacil = 50     -- Fácil: 50%
        else
            scaledDificil = 0
            scaledModerado = 30
            scaledFacil = 70
        end
        totalScaled = scaledFacil + scaledModerado + scaledDificil
    end

    local roll = ZombRand(totalScaled)
    -- LISTA COMPLETA DE SKILLS DE PROJECT ZOMBOID CON USBS DISPONIBLES
    local skills = {
        -- Combat Skills (con USBs definidas)
        "Axe", "LongBlade", "SmallBlade", "LongBlunt", "SmallBlunt", "Spear", "Maintenance", "Aiming",
        -- Crafting Skills (con USBs definidas)
        "Woodwork", "Cooking", "Farming", "Doctor", "Electricity", "Mechanics", "Tailoring",
        -- Survivalist Skills (con USBs definidas)  
        "Fishing", "Trapping", "Survivalist",
        -- Fitness Skills (con USBs definidas)
        "Fitness", "Strength", "Sprinting", "Lightfoot", "Nimble", "Sneak"
    }
    local function randomSkill()
        return skills[ZombRand(#skills) + 1]
    end

    -- NUEVA DISTRIBUCIÓN (español): Dificil -> Moderado -> Facil
    if roll < scaledDificil and isUSB then
        local selectedSkill = randomSkill()
        return "GValley.SkillDrive_" .. selectedSkill .. "_Dificil"
    elseif roll < (scaledDificil + scaledModerado) and isUSB then
        local selectedSkill = randomSkill()
        return "GValley.SkillDrive_" .. selectedSkill .. "_Moderado"
    else
        local selectedSkill = randomSkill()
        return "GValley.SkillDrive_" .. selectedSkill .. "_Facil"
    end
end

-- REGISTRO CORRECTO DEL EVENTO - ESTE ES EL CAMBIO CRÍTICO
local function registerZombieCreationEvent()
    if not Events then
        print("[DecryptSkillSys] ERROR: Events system not available")
        return false
    end
    
    if not Events.OnCreateLivingCharacter then
        print("[DecryptSkillSys] ERROR: OnCreateLivingCharacter event not available")
        return false
    end
    
    if not Events.OnCreateLivingCharacter.Add then
        print("[DecryptSkillSys] ERROR: OnCreateLivingCharacter.Add method not available")
        return false
    end
    
    -- Remove any existing registration to avoid duplicates
    Events.OnCreateLivingCharacter.Remove(GVDrive_OnCreateZombie)
    
    -- Register the event - ESTE ES EL CAMBIO CRÍTICO
    Events.OnCreateLivingCharacter.Add(GVDrive_OnCreateZombie)
    print("[DecryptSkillSys] Zombie CREATION event registered successfully (OnCreateLivingCharacter)")
    return true
end

-- Register immediately
if not registerZombieCreationEvent() then
    -- Fallback: try to register on server start
    local function delayedRegister()
        print("[DecryptSkillSys] Attempting delayed zombie creation event registration...")
        if registerZombieCreationEvent() then
            print("[DecryptSkillSys] Delayed registration successful")
        else
            print("[DecryptSkillSys] CRITICAL ERROR: Could not register zombie creation event")
        end
    end
    
    if Events and Events.OnServerStarted and Events.OnServerStarted.Add then
        Events.OnServerStarted.Add(delayedRegister)
    end
    
    if Events and Events.OnGameStart and Events.OnGameStart.Add then
        Events.OnGameStart.Add(delayedRegister)
    end
end

print("[DecryptSkillSys] Correct zombie loot system loaded successfully")
