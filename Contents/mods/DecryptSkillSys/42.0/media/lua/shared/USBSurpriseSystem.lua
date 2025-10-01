-- USBSurpriseSystem.lua - Sistema de Sorpresas en USBs (Loot Box)
-- Algunos USBs contienen recompensas adicionales ocultas al desencriptarlos

USBSurpriseSystem = USBSurpriseSystem or {}

-- ============================================================================
-- CONFIGURACIÓN
-- ============================================================================

-- Probabilidades base de sorpresas por rareza
USBSurpriseSystem.SURPRISE_CHANCES = {
    Easy = 5,       -- 5% chance
    Moderate = 10,  -- 10% chance
    Expert = 15,    -- 15% chance
    Elite = 100     -- Elite siempre tiene sorpresa
}

-- Tipos de sorpresas y sus pesos (probabilidades relativas)
USBSurpriseSystem.SURPRISE_TYPES = {
    digital_schematic = 25,  -- 25% - Receta única
    survival_tip = 35,       -- 35% - Buff de moodle
    map_fragment = 20,       -- 20% - Fragmento de mapa
    bonus_xp = 15,           -- 15% - XP extra
    rare_item = 5            -- 5% - Item raro (antivirus, etc)
}

-- ============================================================================
-- VERIFICACIÓN Y SELECCIÓN DE SORPRESAS
-- ============================================================================

-- Verificar si un USB debe tener sorpresa
function USBSurpriseSystem.shouldHaveSurprise(difficulty)
    if not difficulty then return false end
    
    -- Obtener probabilidad según dificultad
    local chance = USBSurpriseSystem.SURPRISE_CHANCES[difficulty] or 0
    
    -- Modificar con sandbox si está disponible
    if SandboxVars and SandboxVars.GVDrive then
        local modifier = tonumber(SandboxVars.GVDrive.USB_Surprise_Chance_Modifier) or 1.0
        chance = chance * modifier
    end
    
    local roll = ZombRand(100)
    print("[SurpriseSystem] Surprise roll: " .. roll .. " vs " .. chance .. "% (difficulty: " .. difficulty .. ")")
    
    return roll < chance
end

-- Seleccionar tipo de sorpresa aleatoria
function USBSurpriseSystem.selectSurpriseType()
    local totalWeight = 0
    for _, weight in pairs(USBSurpriseSystem.SURPRISE_TYPES) do
        totalWeight = totalWeight + weight
    end
    
    local roll = ZombRand(totalWeight)
    local currentWeight = 0
    
    for surpriseType, weight in pairs(USBSurpriseSystem.SURPRISE_TYPES) do
        currentWeight = currentWeight + weight
        if roll < currentWeight then
            return surpriseType
        end
    end
    
    return "survival_tip"  -- Fallback
end

-- ============================================================================
-- IMPLEMENTACIÓN DE SORPRESAS
-- ============================================================================

-- 1. DIGITAL SCHEMATIC - Receta única para craftear
function USBSurpriseSystem.giveDigitalSchematic(player)
    if not player then return false end
    
    -- Lista de recetas especiales
    local recipes = {
        "Make_Molotov_Cocktail",
        "Make_Smoke_Bomb",
        "Make_Remote_Controller_V1",
        "Make_Remote_Controller_V2",
        "Make_Remote_Controller_V3",
        "Make_Timer",
        "Craft_Makeshift_Radio"
    }
    
    -- Seleccionar receta aleatoria que el jugador no tenga
    local availableRecipes = {}
    for _, recipe in ipairs(recipes) do
        if player:getKnownRecipes() and not player:getKnownRecipes():contains(recipe) then
            table.insert(availableRecipes, recipe)
        end
    end
    
    if #availableRecipes > 0 then
        local selectedRecipe = availableRecipes[ZombRand(#availableRecipes) + 1]
        player:getKnownRecipes():add(selectedRecipe)
        
        player:Say("USB contains a DIGITAL SCHEMATIC!")
        print("[SurpriseSystem] Granted recipe: " .. selectedRecipe)
        
        -- Notificación visual
        if HaloTextHelper and HaloTextHelper.addText then
            HaloTextHelper.addText(player, "New Recipe Unlocked!", false, 
                HaloTextHelper.getColorGreen())
        end
        
        return true, "recipe"
    else
        -- Fallback si ya tiene todas las recetas: dar XP bonus
        return USBSurpriseSystem.giveBonusXP(player)
    end
end

-- 2. SURVIVAL TIP - Buff temporal de moodle
function USBSurpriseSystem.giveSurvivalTip(player)
    if not player then return false end
    
    local tips = {
        stress = {
            message = "\"Stay calm. Panic kills faster than zombies.\"",
            effect = function(p)
                local bodyDamage = p:getBodyDamage()
                if bodyDamage then
                    bodyDamage:setStressLevel(math.max(0, bodyDamage:getStressLevel() - 30))
                    bodyDamage:setUnhappynessLevel(math.max(0, bodyDamage:getUnhappynessLevel() - 20))
                end
            end
        },
        energy = {
            message = "\"A quick energy boost can save your life.\"",
            effect = function(p)
                local stats = p:getStats()
                if stats then
                    stats:setFatigue(math.max(0, stats:getFatigue() - 0.4))
                    stats:setEndurance(math.min(1, stats:getEndurance() + 0.3))
                end
            end
        },
        health = {
            message = "\"First aid knowledge is power.\"",
            effect = function(p)
                local bodyDamage = p:getBodyDamage()
                if bodyDamage then
                    -- Curar un poco de salud general
                    bodyDamage:RestoreToFullHealth()
                    bodyDamage:setOverallBodyHealth(bodyDamage:getOverallBodyHealth() + 5)
                end
            end
        },
        hunger = {
            message = "\"The body is a machine. Feed it well.\"",
            effect = function(p)
                local stats = p:getStats()
                if stats then
                    stats:setHunger(math.max(0, stats:getHunger() - 0.3))
                    stats:setThirst(math.max(0, stats:getThirst() - 0.3))
                end
            end
        }
    }
    
    -- Seleccionar tip aleatorio
    local tipKeys = {}
    for key, _ in pairs(tips) do
        table.insert(tipKeys, key)
    end
    local selectedKey = tipKeys[ZombRand(#tipKeys) + 1]
    local selectedTip = tips[selectedKey]
    
    -- Aplicar efecto
    selectedTip.effect(player)
    player:Say(selectedTip.message)
    
    print("[SurpriseSystem] Applied survival tip: " .. selectedKey)
    
    -- Notificación visual
    if HaloTextHelper and HaloTextHelper.addText then
        HaloTextHelper.addText(player, "Survival Tip Received!", false, 
            HaloTextHelper.getColorGreen())
    end
    
    return true, "buff"
end

-- 3. MAP FRAGMENT - Fragmento de mapa para tesoro
function USBSurpriseSystem.giveMapFragment(player)
    if not player then return false end
    
    -- Crear o dar fragmento de mapa
    local inventory = player:getInventory()
    if not inventory then return false end
    
    -- Verificar cuántos fragmentos tiene el jugador
    local modData = player:getModData()
    if not modData.GVDrive_MapFragments then
        modData.GVDrive_MapFragments = 0
    end
    
    modData.GVDrive_MapFragments = modData.GVDrive_MapFragments + 1
    local fragmentCount = modData.GVDrive_MapFragments
    
    player:Say("Found encrypted MAP FRAGMENT! (" .. fragmentCount .. "/5)")
    print("[SurpriseSystem] Map fragment received. Total: " .. fragmentCount)
    
    -- Si tiene 5 fragmentos, dar coordenadas de tesoro
    if fragmentCount >= 5 then
        -- Reset fragmentos
        modData.GVDrive_MapFragments = 0
        
        -- Dar mapa completo con coordenadas aleatorias
        player:Say("MAP COMPLETE! Coordinates revealed: Check your journal!")
        
        -- Agregar nota al inventario (si es posible)
        local note = inventory:AddItem("Base.Book")
        if note then
            note:setName("Encrypted Location Data")
            -- En un mod real, aquí spawnearias un stash en el mundo
        end
        
        -- Notificación visual
        if HaloTextHelper and HaloTextHelper.addText then
            HaloTextHelper.addText(player, "TREASURE MAP COMPLETE!", false, 
                HaloTextHelper.getColorOrange())
        end
        
        return true, "map_complete"
    else
        -- Notificación visual
        if HaloTextHelper and HaloTextHelper.addText then
            HaloTextHelper.addText(player, "Map Fragment +" .. fragmentCount .. "/5", false, 
                HaloTextHelper.getColorYellow())
        end
        
        return true, "map_fragment"
    end
end

-- 4. BONUS XP - XP extra en habilidad aleatoria
function USBSurpriseSystem.giveBonusXP(player)
    if not player then return false end
    
    -- Lista de skills para bonus
    local skills = {
        "Woodwork", "Cooking", "Farming", "Doctor", "Electricity",
        "MetalWelding", "Mechanics", "Tailoring", "Fishing"
    }
    
    -- Seleccionar skill aleatoria
    local selectedSkill = skills[ZombRand(#skills) + 1]
    local perk = Perks.FromString(selectedSkill)
    
    if perk then
        local bonusXP = 50 + ZombRand(50)  -- 50-100 XP bonus
        player:getXp():AddXP(perk, bonusXP)
        
        player:Say("BONUS XP UNLOCKED! +" .. bonusXP .. " " .. selectedSkill)
        print("[SurpriseSystem] Bonus XP granted: " .. bonusXP .. " in " .. selectedSkill)
        
        -- Notificación visual
        if HaloTextHelper and HaloTextHelper.addText then
            HaloTextHelper.addText(player, "Bonus XP +" .. bonusXP, false, 
                HaloTextHelper.getColorGreen())
        end
        
        return true, "bonus_xp"
    end
    
    return false
end

-- 5. RARE ITEM - Item raro (antivirus, etc)
function USBSurpriseSystem.giveRareItem(player)
    if not player then return false end
    
    local inventory = player:getInventory()
    if not inventory then return false end
    
    -- Lista de items raros
    local rareItems = {
        {type = "GValley.AntivirusDisk_Norton", name = "Norton Antivirus", weight = 30},
        {type = "GValley.AntivirusDisk_Kaspersky", name = "Kaspersky Antivirus", weight = 25},
        {type = "GValley.AntivirusDisk_McAfee", name = "McAfee Antivirus", weight = 20},
        {type = "GValley.AntivirusDisk_MalwareBytes", name = "MalwareBytes Antivirus", weight = 15},
        {type = "GValley.EliteDrive_Random", name = "Elite Drive", weight = 10}
    }
    
    -- Seleccionar item por peso
    local totalWeight = 0
    for _, item in ipairs(rareItems) do
        totalWeight = totalWeight + item.weight
    end
    
    local roll = ZombRand(totalWeight)
    local currentWeight = 0
    local selectedItem = rareItems[1]
    
    for _, item in ipairs(rareItems) do
        currentWeight = currentWeight + item.weight
        if roll < currentWeight then
            selectedItem = item
            break
        end
    end
    
    -- Agregar item al inventario
    local newItem = inventory:AddItem(selectedItem.type)
    if newItem then
        player:Say("RARE ITEM FOUND: " .. selectedItem.name .. "!")
        print("[SurpriseSystem] Rare item granted: " .. selectedItem.name)
        
        -- Notificación visual
        if HaloTextHelper and HaloTextHelper.addText then
            HaloTextHelper.addText(player, "RARE: " .. selectedItem.name, false, 
                HaloTextHelper.getColorOrange())
        end
        
        return true, "rare_item"
    end
    
    return false
end

-- ============================================================================
-- FUNCIÓN PRINCIPAL: ACTIVAR SORPRESA
-- ============================================================================

function USBSurpriseSystem.triggerSurprise(player, difficulty)
    if not player then return false end
    
    -- Verificar si debe tener sorpresa
    if not USBSurpriseSystem.shouldHaveSurprise(difficulty) then
        print("[SurpriseSystem] No surprise this time")
        return false
    end
    
    -- Seleccionar tipo de sorpresa
    local surpriseType = USBSurpriseSystem.selectSurpriseType()
    print("[SurpriseSystem] Triggering surprise: " .. surpriseType)
    
    -- Activar sorpresa correspondiente
    local success = false
    local resultType = nil
    
    if surpriseType == "digital_schematic" then
        success, resultType = USBSurpriseSystem.giveDigitalSchematic(player)
    elseif surpriseType == "survival_tip" then
        success, resultType = USBSurpriseSystem.giveSurvivalTip(player)
    elseif surpriseType == "map_fragment" then
        success, resultType = USBSurpriseSystem.giveMapFragment(player)
    elseif surpriseType == "bonus_xp" then
        success, resultType = USBSurpriseSystem.giveBonusXP(player)
    elseif surpriseType == "rare_item" then
        success, resultType = USBSurpriseSystem.giveRareItem(player)
    end
    
    if success then
        print("[SurpriseSystem] Surprise activated successfully: " .. tostring(resultType))
        
        -- Sonido de éxito
        if getSoundManager() then
            getSoundManager():PlaySound("USBkeyboard", false, 0.5)
        end
    else
        print("[SurpriseSystem] Surprise activation failed")
    end
    
    return success
end

-- ============================================================================
-- FUNCIONES DE DEBUG
-- ============================================================================

function ReloadSurpriseSystem()
    print("[DEBUG] Reloading USBSurpriseSystem...")
    package.loaded["shared/USBSurpriseSystem"] = nil
    local success, result = pcall(require, "shared/USBSurpriseSystem")
    if success then
        print("[DEBUG] USBSurpriseSystem reloaded successfully!")
    else
        print("[DEBUG] Failed to reload: " .. tostring(result))
    end
end

function TestSurprise(surpriseType)
    local player = getPlayer()
    if not player then
        print("❌ No player found")
        return
    end
    
    print("🎁 Testing surprise: " .. (surpriseType or "random"))
    
    if surpriseType == "recipe" then
        USBSurpriseSystem.giveDigitalSchematic(player)
    elseif surpriseType == "tip" then
        USBSurpriseSystem.giveSurvivalTip(player)
    elseif surpriseType == "map" then
        USBSurpriseSystem.giveMapFragment(player)
    elseif surpriseType == "xp" then
        USBSurpriseSystem.giveBonusXP(player)
    elseif surpriseType == "rare" then
        USBSurpriseSystem.giveRareItem(player)
    else
        -- Test aleatorio
        USBSurpriseSystem.triggerSurprise(player, "Expert")
    end
end

print("[USBSurpriseSystem] Module loaded successfully")
