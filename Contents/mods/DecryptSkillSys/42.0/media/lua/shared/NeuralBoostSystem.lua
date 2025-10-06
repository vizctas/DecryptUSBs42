-- NeuralBoostSystem.lua - Sistema de Buffs Temporales de USBs
-- Algunos USBs otorgan bonos temporales potentes en vez de XP permanente

NeuralBoostSystem = NeuralBoostSystem or {}

--
-- Early helper: warning throttle used by addBoost()
-- Define it BEFORE any call sites to avoid "call nil" during early invokes.
--
local lastWarningTime = 0
local WARNING_COOLDOWN = 300  -- ticks (engine tick, ~5s window)
local function shouldPrintWarning()
    local getTs = _G.getTimestamp
    local now = 0
    if type(getTs) == 'function' then
        local ok, v = pcall(getTs)
        if ok and type(v) == 'number' then now = v end
    end
    if (now - lastWarningTime) > WARNING_COOLDOWN then
        lastWarningTime = now
        return true
    end
    return false
end

local function SafeHaloText(player, text, color)
    if not (player and HaloTextHelper) then return false end

    local col = color
    if not col and HaloTextHelper.getColorGreen then
        local ok, value = pcall(function() return HaloTextHelper.getColorGreen() end)
        if ok then col = value end
    end

    if HaloTextHelper.addText then
        local ok = pcall(HaloTextHelper.addText, player, tostring(text), false, col)
        if ok then return true end
    end

    if HaloTextHelper.AddText then
        local ok = pcall(HaloTextHelper.AddText, HaloTextHelper, player, tostring(text), false, col)
        if ok then return true end
    end

    return false
end

-- ============================================================================
-- CONFIGURACIÓN
-- ============================================================================

-- Probabilidad de que un USB sea de tipo "Neural Boost" (10% por defecto)
NeuralBoostSystem.BOOST_CHANCE = 10

-- Duración de buffs en minutos (tiempo in-game)
NeuralBoostSystem.BUFF_DURATIONS = {
    focus = 60,      -- 60 minutos = 1 hora
    adrenaline = 30, -- 30 minutos
    iron_mind = 60,  -- 60 minutos
    metabolic = 45,  -- 45 minutos
    precision = 30,  -- 30 minutos
    pack_mule = 120  -- 120 minutos = 2 horas
}

-- Tipos de buffs disponibles y sus efectos
NeuralBoostSystem.BOOST_TYPES = {
    focus = {
        name = "Neural Focus",
        description = "+50% XP gain for all skills",
        icon = "⚡",
        color = {r=0.3, g=0.8, b=1, a=1},
        xpMultiplier = 1.5
    },
    adrenaline = {
        name = "Adrenaline Surge",
        description = "+30% attack speed",
        icon = "💪",
        color = {r=1, g=0.3, b=0.3, a=1},
        attackSpeedBonus = 0.3
    },
    iron_mind = {
        name = "Iron Mind",
        description = "Immunity to panic and stress",
        icon = "🧠",
        color = {r=0.8, g=0.8, b=0.2, a=1},
        stressImmunity = true
    },
    metabolic = {
        name = "Metabolic Boost",
        description = "50% slower hunger/thirst",
        icon = "🔋",
        color = {r=0.3, g=1, g=0.3, a=1},
        hungerMultiplier = 0.5
    },
    precision = {
        name = "Enhanced Precision",
        description = "+25% accuracy and crit chance",
        icon = "🎯",
        color = {r=1, g=0.6, b=0.2, a=1},
        accuracyBonus = 0.25,
        critBonus = 0.25
    },
    pack_mule = {
        name = "Pack Mule Enhancement",
        description = "+8kg carry capacity for 2 hours",
        icon = "🎒",
        color = {r=0.6, g=0.4, b=1, a=1},
        carryBonus = 8  -- 8kg adicionales
    }
}

-- ============================================================================
-- GESTIÓN DE BUFFS ACTIVOS
-- ============================================================================

-- Obtener buffs activos del jugador
function NeuralBoostSystem.getActiveBoosts(player)
    if not player then return {} end
    
    local modData = player:getModData()
    if not modData.GVDrive_ActiveBoosts then
        modData.GVDrive_ActiveBoosts = {}
    end
    
    return modData.GVDrive_ActiveBoosts
end

-- Verificar si un boost específico está activo
function NeuralBoostSystem.hasBoost(player, boostType)
    local activeBoosts = NeuralBoostSystem.getActiveBoosts(player)
    return activeBoosts[boostType] ~= nil
end

-- Agregar un boost al jugador
function NeuralBoostSystem.addBoost(player, boostType)
    if not player or not boostType then return false end
    
    local boostData = NeuralBoostSystem.BOOST_TYPES[boostType]
    if not boostData then
        print("[NeuralBoost] Unknown boost type: " .. tostring(boostType))
        return false
    end
    
    local activeBoosts = NeuralBoostSystem.getActiveBoosts(player)
    local duration = NeuralBoostSystem.BUFF_DURATIONS[boostType] or 30
    
    -- Calcular tiempo de expiración con validación robusta
    local gameTime = getGameTime()
    if not gameTime then
        if shouldPrintWarning() then
            print("[NeuralBoost] WARNING: getGameTime() not available, boost activation delayed")
        end
        return
    end
    
    if not gameTime.getTimeInMillis then
        if shouldPrintWarning() then
            print("[NeuralBoost] WARNING: GameTime not fully initialized, boost activation delayed")
        end
        return
    end
    
    -- Usar pcall para proteger contra errores
    local success, currentTime = pcall(function() return gameTime:getTimeInMillis() end)
    if not success then
        if shouldPrintWarning() then
            print("[NeuralBoost] WARNING: Failed to get current time, boost activation delayed")
        end
        return
    end
    
    local expirationMinute = currentTime + (duration * 60 * 1000)  -- Convertir a milisegundos
    
    -- Agregar boost
    activeBoosts[boostType] = {
        expiration = expirationMinute,
        startTime = currentTime,
        duration = duration
    }
    
    player:getModData().GVDrive_ActiveBoosts = activeBoosts
    
    -- Aplicar efecto inmediato si es Pack Mule
    if boostType == "pack_mule" then
        NeuralBoostSystem.applyPackMuleBoost(player, true)
    player:Say(boostData.icon .. " " .. boostData.name .. " ACTIVATED!")
    print("[NeuralBoost] Boost activated: " .. boostType .. " for " .. duration .. " minutes")
    
    -- Notificación visual con HaloText
    SafeHaloText(player, boostData.name .. " (" .. duration .. "min)", HaloTextHelper and HaloTextHelper.getColorGreen and HaloTextHelper.getColorGreen() or nil)
    
    return true
end

-- Remover un boost expirado
{{ ... }}
function NeuralBoostSystem.removeBoost(player, boostType)
    if not player then return end
    
    -- Remover efecto de Pack Mule si es necesario
    if boostType == "pack_mule" then
        NeuralBoostSystem.applyPackMuleBoost(player, false)
    end
    
    local activeBoosts = NeuralBoostSystem.getActiveBoosts(player)
    activeBoosts[boostType] = nil
    player:getModData().GVDrive_ActiveBoosts = activeBoosts
    
    local boostData = NeuralBoostSystem.BOOST_TYPES[boostType]
    if boostData then
        player:Say(boostData.name .. " has expired.")
        print("[NeuralBoost] Boost expired: " .. boostType)
    end
end

-- Actualizar buffs activos (remover expirados)
function NeuralBoostSystem.updateBoosts(player)
    if not player then return end
    
    local activeBoosts = NeuralBoostSystem.getActiveBoosts(player)
    
    -- Validación robusta de gameTime (sin spam de logs)
    local gameTime = getGameTime()
    if not gameTime then
        return  -- Silencioso, no spamear logs
    end
    
    -- Verificar que el método getTimeInMillis existe
    if not gameTime.getTimeInMillis then
        return  -- Silencioso, no spamear logs
    end
    
    -- Usar pcall para proteger contra errores
    local success, currentTime = pcall(function() return gameTime:getTimeInMillis() end)
    if not success then
        return  -- Silencioso, no spamear logs
    end
    
    -- Revisar cada boost activo
    local toRemove = {}
    for boostType, boostInfo in pairs(activeBoosts) do
        if boostInfo and boostInfo.expiration and currentTime >= boostInfo.expiration then
            table.insert(toRemove, boostType)
        end
    end
    
    -- Remover buffs expirados
    for _, boostType in ipairs(toRemove) do
        NeuralBoostSystem.removeBoost(player, boostType)
    end
end

-- ============================================================================
-- APLICACIÓN DE EFECTOS DE BUFFS
-- ============================================================================

-- Aplicar efectos de buff "Focus" (XP multiplier)
function NeuralBoostSystem.applyFocusBoost(player, baseXP)
    if not NeuralBoostSystem.hasBoost(player, "focus") then
        return baseXP
    end
    
    local boost = NeuralBoostSystem.BOOST_TYPES.focus
    local bonusXP = baseXP * (boost.xpMultiplier - 1)
    
    return baseXP + bonusXP
end

-- Aplicar efectos de buff "Iron Mind" (stress immunity)
function NeuralBoostSystem.applyIronMindBoost(player)
    if not NeuralBoostSystem.hasBoost(player, "iron_mind") then
        return
    end
    
    local bodyDamage = player:getBodyDamage()
    if bodyDamage then
        -- Reducir stress y panic a 0
        bodyDamage:setStressLevel(0)
        bodyDamage:setPanic(0)
    end
end

-- Aplicar efectos de buff "Metabolic" (hunger/thirst reduction)
function NeuralBoostSystem.applyMetabolicBoost(player)
    if not NeuralBoostSystem.hasBoost(player, "metabolic") then
        return
    end
    
    -- Reducir hambre y sed más lentamente
    local stats = player:getStats()
    if stats then
        local currentHunger = stats:getHunger()
        local currentThirst = stats:getThirst()
        
        -- Reducir progresión de hambre/sed en 50%
        stats:setHunger(currentHunger * 0.98)  -- Compensar acumulación
        stats:setThirst(currentThirst * 0.98)
    end
end

-- Aplicar efectos de buff "Pack Mule" (carry capacity boost)
function NeuralBoostSystem.applyPackMuleBoost(player, isActivating)
    if not player then return end
    
    local boostData = NeuralBoostSystem.BOOST_TYPES.pack_mule
    if not boostData then return end
    
    local carryBonus = boostData.carryBonus or 8
    
    if isActivating then
        -- ACTIVAR: Aumentar capacidad de carga
        local currentMax = player:getMaxWeight()
        local newMax = currentMax + carryBonus
        player:setMaxWeight(newMax)
        
        print("[NeuralBoost] Pack Mule activated: " .. currentMax .. " -> " .. newMax .. " kg")
        
        -- Guardar capacidad base en ModData para persistencia
        local modData = player:getModData()
        if not modData.GVDrive_BaseMaxWeight then
            modData.GVDrive_BaseMaxWeight = currentMax
        end
    else
        -- DESACTIVAR: Restaurar capacidad original
        local modData = player:getModData()
        local baseWeight = modData.GVDrive_BaseMaxWeight
        
        if baseWeight then
            player:setMaxWeight(baseWeight)
            print("[NeuralBoost] Pack Mule deactivated: restored to " .. baseWeight .. " kg")
        else
            -- Fallback: reducir por el bonus
            local currentMax = player:getMaxWeight()
            local newMax = math.max(8, currentMax - carryBonus)  -- Mínimo 8kg
            player:setMaxWeight(newMax)
            print("[NeuralBoost] Pack Mule deactivated: " .. currentMax .. " -> " .. newMax .. " kg")
        end
    end
end

-- ============================================================================
-- DETECCIÓN Y ACTIVACIÓN DE NEURAL BOOSTS
-- ============================================================================

-- Verificar si un USB debe ser un Neural Boost
function NeuralBoostSystem.shouldBeBoost(difficulty)
    if not difficulty then return false end
    
    -- Probabilidad base
    local chance = NeuralBoostSystem.BOOST_CHANCE
    
    -- Aumentar probabilidad para dificultades más altas
    if difficulty == "Moderate" then
        chance = chance * 1.5  -- 15%
    elseif difficulty == "Expert" then
        chance = chance * 2.0  -- 20%
    end
    
    -- Modificador de sandbox si está disponible
    if SandboxVars and SandboxVars.GVDrive then
        local modifier = tonumber(SandboxVars.GVDrive.NeuralBoost_Chance_Modifier) or 1.0
        chance = chance * modifier
    end
    
    local roll = ZombRand(100)
    print("[NeuralBoost] Boost roll: " .. roll .. " vs " .. chance .. "% (difficulty: " .. difficulty .. ")")
    
    return roll < chance
end

-- Seleccionar tipo de boost aleatorio
function NeuralBoostSystem.selectRandomBoost()
    local boostTypes = {}
    for boostType, _ in pairs(NeuralBoostSystem.BOOST_TYPES) do
        table.insert(boostTypes, boostType)
    end
    
    local index = ZombRand(#boostTypes) + 1
    return boostTypes[index]
end

-- Activar Neural Boost al desencriptar USB
function NeuralBoostSystem.activateBoost(player, difficulty)
    if not player then return false end
    
    -- Verificar si debe ser boost
    if not NeuralBoostSystem.shouldBeBoost(difficulty) then
        print("[NeuralBoost] Not a boost USB this time")
        return false
    end
    
    -- Seleccionar tipo de boost
    local boostType = NeuralBoostSystem.selectRandomBoost()
    
    -- Activar boost
    local success = NeuralBoostSystem.addBoost(player, boostType)
    
    if success then
        -- Efecto visual/sonido
        if getSoundManager() then
            getSoundManager():PlaySound("USBkeyboard", false, 0.7)
        end
        
        print("[NeuralBoost] Neural Boost activated: " .. boostType)
    end
    
    return success
end

-- ============================================================================
-- INTEGRACIÓN CON SISTEMA DE XP
-- ============================================================================

-- Modificar XP otorgada si hay buff activo
function NeuralBoostSystem.modifyXPGain(player, skill, baseXP)
    if not player then return baseXP end
    
    -- Aplicar boost de Focus si está activo
    local modifiedXP = NeuralBoostSystem.applyFocusBoost(player, baseXP)
    
    if modifiedXP > baseXP then
        print("[NeuralBoost] XP boosted: " .. baseXP .. " -> " .. modifiedXP .. " (Focus active)")
        
        -- Notificación visual
        if HaloTextHelper and HaloTextHelper.addText then
            local bonus = modifiedXP - baseXP
            pcall(function()
                HaloTextHelper.addText(player, "Focus Bonus: +" .. math.floor(bonus) .. " XP", false, HaloTextHelper.getColorYellow())
            end)
        end
    end
    
    return modifiedXP
end

-- ============================================================================
-- EVENTOS Y ACTUALIZACIÓN
-- ============================================================================

-- Sistema de throttling para logs (evitar spam)
-- Nota: La implementación se movió al inicio del archivo para evitar
-- llamadas tempranas desde addBoost() cuando aún no estaba definido.

-- Actualizar buffs cada 10 minutos
local function onEveryTenMinutes()
    local players = getOnlinePlayers()
    if not players then return end
    
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            -- Actualizar buffs (remover expirados)
            NeuralBoostSystem.updateBoosts(player)
            
            -- Aplicar efectos pasivos
            NeuralBoostSystem.applyIronMindBoost(player)
            NeuralBoostSystem.applyMetabolicBoost(player)
        end
    end
end

-- Restaurar boosts al cargar jugador (UNA VEZ, no cada tick)
local hasInitialized = false

local function onGameStart()
    if hasInitialized then return end
    hasInitialized = true
    
    local player = getPlayer()
    if not player then return end
    
    print("[NeuralBoost] Initializing Neural Boost System...")
    
    local activeBoosts = NeuralBoostSystem.getActiveBoosts(player)
    
    -- Re-aplicar efectos de Pack Mule si está activo
    if activeBoosts and activeBoosts.pack_mule then
        print("[NeuralBoost] Restoring Pack Mule boost from save")
        NeuralBoostSystem.applyPackMuleBoost(player, true)
    end
    
    -- Limpiar buffs expirados
    NeuralBoostSystem.updateBoosts(player)
    
    print("[NeuralBoost] System initialized successfully")
end

-- Registrar eventos (CORREGIDO: sin OnPlayerUpdate)
Events.EveryTenMinutes.Add(onEveryTenMinutes)
Events.OnGameStart.Add(onGameStart)  -- ✅ Se ejecuta UNA vez al iniciar
Events.OnLoad.Add(function()
    hasInitialized = false  -- Reset flag para permitir reinicialización
end)

-- ============================================================================
-- UI - MOSTRAR BUFFS ACTIVOS
-- ============================================================================

-- Obtener string de buffs activos para mostrar en UI
function NeuralBoostSystem.getActiveBoostsString(player)
    if not player then return "" end
    
    local activeBoosts = NeuralBoostSystem.getActiveBoosts(player)
    local boostStrings = {}
    
    local gameTime = getGameTime()
    if not gameTime then
        return "[Neural Boosts: Loading...]"
    end
    
    if not gameTime.getTimeInMillis then
        return "[Neural Boosts: Initializing...]"
    end
    
    local success, currentTime = pcall(function() return gameTime:getTimeInMillis() end)
    if not success then
        return "[Neural Boosts: Error reading time]"
    end
    
    for boostType, boostInfo in pairs(activeBoosts) do
        local boostData = NeuralBoostSystem.BOOST_TYPES[boostType]
        if boostData then
            -- Calcular tiempo restante
            local timeRemaining = (boostInfo.expiration - currentTime) / (60 * 1000)  -- Convertir a minutos
            timeRemaining = math.max(0, math.floor(timeRemaining))
            
            local boostString = boostData.icon .. " " .. boostData.name .. " (" .. timeRemaining .. "m)"
            table.insert(boostStrings, boostString)
        end
    end
    
    if #boostStrings > 0 then
        return "ACTIVE BOOSTS:\n" .. table.concat(boostStrings, "\n")
    else
        return ""
    end
end

-- ============================================================================
-- FUNCIONES DE DEBUG
-- ============================================================================

function ReloadNeuralBoost()
    print("[DEBUG] Reloading NeuralBoostSystem...")
    package.loaded["shared/NeuralBoostSystem"] = nil
    local success, result = pcall(require, "shared/NeuralBoostSystem")
    if success then
        print("[DEBUG] NeuralBoostSystem reloaded successfully!")
    else
        print("[DEBUG] Failed to reload: " .. tostring(result))
    end
end

function TestNeuralBoost(boostType)
    local player = getPlayer()
    if not player then
        print("❌ No player found")
        return
    end
    
    if boostType then
        print("⚡ Testing neural boost: " .. boostType)
        NeuralBoostSystem.addBoost(player, boostType)
    else
        print("⚡ Testing random neural boost")
        NeuralBoostSystem.activateBoost(player, "Expert")
    end
end

function ListActiveBoosts()
    local player = getPlayer()
    if not player then
        print("❌ No player found")
        return
    end
    
    local boostString = NeuralBoostSystem.getActiveBoostsString(player)
    if boostString ~= "" then
        print(boostString)
    else
        print("No active boosts")
    end
end

function ClearAllBoosts()
    local player = getPlayer()
    if not player then
        print("❌ No player found")
        return
    end
    
    player:getModData().GVDrive_ActiveBoosts = {}
    print("✅ All boosts cleared")
end

print("[NeuralBoostSystem] Module loaded successfully")
