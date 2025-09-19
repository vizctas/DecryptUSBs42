# SISTEMA DE TRAITS DINÁMICOS - PROJECT ZOMBOID

## GESTIÓN COMPLETA DE TRAITS TEMPORALES Y PERMANENTES

*Basado en análisis exhaustivo del mod N&C's Narcotics y patrones de traits dinámicos*

---

## 1. ARQUITECTURA FUNDAMENTAL DE TRAITS

### 1.1 Estructura Base de un Trait
```
COMPONENTES DE UN TRAIT:
├── TraitName.txt           # Definición del trait
├── UI_trait_TraitName      # Nombre mostrado
├── UI_trait_TraitNamedesc  # Descripción detallada
├── TraitEffects.lua        # Efectos continuos del trait
├── OnEat/OnUse functions   # Funciones que afectan el trait
└── ModData counters        # Contadores para persistencia
```

### 1.2 Tipos de Traits Dinámicos
```
CATEGORÍAS PRINCIPALES:
├── Temporal Removibles     # Se pueden perder con el tiempo
├── Permanentes Irremovibles # Marcados como "CAN'T lose trait"
├── Condicionales          # Aparecen/desaparecen según condiciones
├── Progresivos           # Aumentan/disminuyen en intensidad
└── Dependencias          # Requieren consumo regular para mantener
```

---

## 2. DEFINICIÓN DE TRAITS EN SCRIPTS

### 2.1 Estructura Básica de Trait
```text
trait TraitName
{
    cost = -2,                    # Costo en puntos de trait (negativo = ventaja)
    description = UI_trait_TraitNamedesc,
    displayName = UI_trait_TraitName,
    goodBadTrait = bad,          # good, bad o neutral
    profession = false,          # Si es específico de profesión
    starter = true,              # Si está disponible en creación de personaje
    onlyStartingTrait = true,    # Solo en inicio (no dinámico)
}
```

### 2.2 Traits Dinámicos (Adquiribles)
```text
trait MDMAAddict
{
    cost = -4,
    description = UI_trait_MDMAAddictdesc,
    displayName = UI_trait_MDMAAddict,
    goodBadTrait = bad,
    profession = false,
    starter = false,             # NO disponible en inicio
    onlyStartingTrait = false,   # Puede ser adquirido dinámicamente
}

trait ParanoidUser
{
    cost = -3,
    description = UI_trait_ParanoidUserdesc,
    displayName = UI_trait_ParanoidUser,
    goodBadTrait = bad,
    profession = false,
    starter = true,              # Disponible en inicio
    onlyStartingTrait = false,   # TAMBIÉN dinámico
}
```

### 2.3 Traducciones Críticas
```text
# archivo: EN.txt
UI_trait_MDMAAddict = "MDMA Lover",
UI_trait_MDMAAddictdesc = "In Love with MDMA.<br>Withdrawals at 3 (Medium), 6 (Bad), 10 (Mild) days.<br>If MDMA taken every 5 days, you can lose trait with no tier 2 withdrawals.<br>Will lose trait if no MDMA is done for 18-20 days.<br>-Hunger, +Thirst, +Fatigue, -Endurance, +Stress, +Head Pain.",

UI_trait_ParanoidUser = "Paranoid User",
UI_trait_ParanoidUserdesc = "Drugs give a panic attack for entire duration of effect.<br>CAN'T lose trait.",
```

---

## 3. SISTEMA DE CONTADORES PERSISTENTES

### 3.1 Patrón de ModData para Traits Temporales
```lua
-- PATRÓN CRÍTICO: Usar ModData para persistencia entre sesiones
function initializeTraitCounters(player)
    -- Contadores para dependencias (en intervalos de 10 minutos)
    if player:getModData().NnCTenMinutesMDMAAddict == nil then
        player:getModData().NnCTenMinutesMDMAAddict = 0
    end
    
    if player:getModData().NnCTenMinutesBenzoAddict == nil then
        player:getModData().NnCTenMinutesBenzoAddict = 0
    end
    
    if player:getModData().NnCTenMinutesOpioidAddict == nil then
        player:getModData().NnCTenMinutesOpioidAddict = 0
    end
    
    if player:getModData().NnCTenMinutesPotHead == nil then
        player:getModData().NnCTenMinutesPotHead = 0
    end
    
    -- Contadores para efectos de drogas
    if player:getModData().NnCMDMAEffect == nil then
        player:getModData().NnCMDMAEffect = 0
    end
    
    if player:getModData().NnCBenzoEffect == nil then
        player:getModData().NnCBenzoEffect = 0
    end
end
```

### 3.2 Sistema de Conversión de Tiempo
```lua
-- CONVERSIÓN CRÍTICA: Intervalos de 10 minutos a días
local INTERVALS_PER_HOUR = 6        -- 60 min / 10 min
local INTERVALS_PER_DAY = 144       -- 24 * 6
local INTERVALS_PER_GAME_HOUR = 6   -- En tiempo de juego

-- Función para convertir días reales a intervalos
function daysToIntervals(days)
    return days * INTERVALS_PER_DAY
end

-- Función para verificar si han pasado X días sin consumo
function hasBeenXDaysWithoutConsumption(player, traitCounter, days)
    local currentCounter = player:getModData()[traitCounter] or 0
    local dayThreshold = daysToIntervals(days)
    
    return currentCounter >= dayThreshold
end

-- Verificaciones específicas por trait
local TRAIT_THRESHOLDS = {
    ["MDMAAddict"] = {
        counter = "NnCTenMinutesMDMAAddict",
        lossThreshold = daysToIntervals(18), -- 18-20 días
        withdrawalMild = daysToIntervals(10),
        withdrawalBad = daysToIntervals(6),
        withdrawalMedium = daysToIntervals(3),
    },
    ["BenzoAddict"] = {
        counter = "NnCTenMinutesBenzoAddict",
        lossThreshold = daysToIntervals(18),
        withdrawalMild = daysToIntervals(10),
        withdrawalBad = daysToIntervals(6),
        withdrawalMedium = daysToIntervals(3),
    },
    ["PotHead"] = {
        counter = "NnCTenMinutesPotHead",
        lossThreshold = daysToIntervals(18),
        withdrawalMild = daysToIntervals(15),
        withdrawalBad = daysToIntervals(10),
        withdrawalMedium = daysToIntervals(5),
    },
}
```

---

## 4. AÑADIR TRAITS DINÁMICAMENTE

### 4.1 Función Principal para Añadir Trait
```lua
-- PATRÓN PARA AÑADIR TRAITS DINÁMICAMENTE
function addTraitDynamically(player, traitName, reason)
    -- Verificar que el jugador no tenga ya el trait
    if player:HasTrait(traitName) then
        return false -- Ya lo tiene
    end
    
    -- Verificar que el trait existe
    local trait = TraitFactory.getTrait(traitName)
    if not trait then
        print("ERROR: Trait " .. traitName .. " no existe")
        return false
    end
    
    -- Añadir el trait al jugador
    player:getTraits():add(traitName)
    
    -- Log para debugging
    if SandboxVars.ModName.DebugMode then
        print("[TRAIT] Added trait '" .. traitName .. "' to player. Reason: " .. (reason or "Unknown"))
    end
    
    -- Inicializar contadores específicos del trait
    initializeTraitSpecificData(player, traitName)
    
    -- Trigger eventos personalizados
    triggerTraitAddedEvent(player, traitName)
    
    return true
end

-- Función helper para inicializar data específica
function initializeTraitSpecificData(player, traitName)
    local counters = TRAIT_THRESHOLDS[traitName]
    if counters then
        player:getModData()[counters.counter] = 0
    end
    
    -- Inicializar otros datos específicos según el trait
    if traitName == "MDMAAddict" then
        player:getModData().MDMAAddictionLevel = 1
        player:getModData().MDMALastConsumed = getGameTime():getWorldAgeHours()
    elseif traitName == "ParanoidUser" then
        player:getModData().ParanoidTriggerCount = 0
        -- Este trait es permanente, no se puede perder
    end
end

-- Evento personalizado para traits añadidos
function triggerTraitAddedEvent(player, traitName)
    triggerEvent("OnTraitAdded", player, traitName)
end
```

### 4.2 Sistema de Dependencias Progresivas
```lua
-- Sistema para desarrollar dependencia gradualmente
function updateAddictionProgress(player, substanceName, consumptionAmount)
    local progressKey = "addiction_progress_" .. substanceName
    local currentProgress = player:getModData()[progressKey] or 0
    
    -- Incrementar progreso de adicción
    currentProgress = currentProgress + consumptionAmount
    player:getModData()[progressKey] = currentProgress
    
    -- Thresholds para desarrollar addiction
    local addictionThresholds = {
        ["MDMA"] = { trait = "MDMAAddict", threshold = 10 },
        ["Cocaine"] = { trait = "CokeHead", threshold = 8 },
        ["Meth"] = { trait = "MethHead", threshold = 5 },
        ["Cannabis"] = { trait = "PotHead", threshold = 20 },
        ["Benzodiazepine"] = { trait = "BenzoAddict", threshold = 12 },
        ["Opioids"] = { trait = "OpioidAddict", threshold = 7 },
    }
    
    local config = addictionThresholds[substanceName]
    if config and currentProgress >= config.threshold then
        -- Desarrollar addiction
        if addTraitDynamically(player, config.trait, "Excessive consumption of " .. substanceName) then
            -- Reset progreso, ahora es un adicto
            player:getModData()[progressKey] = 0
            
            -- Notificar al jugador
            if isClient() then
                getPlayer():Say("I think I'm becoming dependent on " .. substanceName .. "...")
            end
        end
    end
end
```

---

## 5. REMOVER TRAITS DINÁMICAMENTE

### 5.1 Función Principal para Remover Trait
```lua
-- PATRÓN PARA REMOVER TRAITS DINÁMICAMENTE
function removeTraitDynamically(player, traitName, reason)
    -- Verificar que el jugador tiene el trait
    if not player:HasTrait(traitName) then
        return false -- No lo tiene
    end
    
    -- Verificar que el trait se puede remover
    if isTraitPermanent(traitName) then
        print("WARNING: Attempted to remove permanent trait: " .. traitName)
        return false
    end
    
    -- Remover el trait del jugador
    player:getTraits():remove(traitName)
    
    -- Log para debugging
    if SandboxVars.ModName.DebugMode then
        print("[TRAIT] Removed trait '" .. traitName .. "' from player. Reason: " .. (reason or "Unknown"))
    end
    
    -- Limpiar datos específicos del trait
    cleanupTraitSpecificData(player, traitName)
    
    -- Trigger eventos personalizados
    triggerTraitRemovedEvent(player, traitName)
    
    return true
end

-- Verificar si un trait es permanente
function isTraitPermanent(traitName)
    local permanentTraits = {
        ["ParanoidUser"] = true,  -- Específicamente marcado como "CAN'T lose trait"
        -- Añadir otros traits permanentes aquí
    }
    
    return permanentTraits[traitName] or false
end

-- Limpiar datos específicos del trait
function cleanupTraitSpecificData(player, traitName)
    local counters = TRAIT_THRESHOLDS[traitName]
    if counters then
        player:getModData()[counters.counter] = nil
    end
    
    -- Limpiar otros datos específicos
    if traitName == "MDMAAddict" then
        player:getModData().MDMAAddictionLevel = nil
        player:getModData().MDMALastConsumed = nil
    elseif traitName == "PotHead" then
        player:getModData().PotHeadLevel = nil
        player:getModData().CannabisTolerance = nil
    end
end
```

### 5.2 Sistema de Pérdida de Traits por Tiempo
```lua
-- Sistema automático de pérdida de traits por abstinencia
function checkTraitLossConditions(player)
    for traitName, config in pairs(TRAIT_THRESHOLDS) do
        if player:HasTrait(traitName) then
            local counter = player:getModData()[config.counter] or 0
            
            -- Verificar si debe perder el trait
            if counter >= config.lossThreshold then
                local success = removeTraitDynamically(player, traitName, "Long-term abstinence")
                
                if success and isClient() then
                    player:Say("I don't feel the craving anymore...")
                    -- Opcional: Moodle positivo por superar la adicción
                    player:getBodyDamage():setUnhappynessLevel(
                        math.max(0, player:getBodyDamage():getUnhappynessLevel() - 10)
                    )
                end
            end
        end
    end
end

-- Ejecutar cada 10 minutos (en tiempo real)
Events.EveryTenMinutes.Add(checkTraitLossConditions)
```

---

## 6. SISTEMA DE EFECTOS DE WITHDRAWAL

### 6.1 Niveles de Withdrawal
```lua
-- Sistema de abstinencia por niveles
function applyWithdrawalEffects(player, traitName)
    local config = TRAIT_THRESHOLDS[traitName]
    if not config or not player:HasTrait(traitName) then return end
    
    local counter = player:getModData()[config.counter] or 0
    local stats = player:getStats()
    local bodyDamage = player:getBodyDamage()
    
    -- Determinar nivel de withdrawal
    local withdrawalLevel = "none"
    if counter >= config.withdrawalMedium then
        withdrawalLevel = "medium"
    end
    if counter >= config.withdrawalBad then
        withdrawalLevel = "bad"
    end
    if counter >= config.withdrawalMild then
        withdrawalLevel = "mild"
    end
    
    -- Aplicar efectos según nivel
    local effects = WITHDRAWAL_EFFECTS[traitName][withdrawalLevel]
    if effects then
        applyWithdrawalEffectsToPlayer(player, effects)
    end
end

-- Configuración de efectos de withdrawal
local WITHDRAWAL_EFFECTS = {
    ["MDMAAddict"] = {
        medium = {
            hunger = -0.01,
            thirst = 0.01,
            fatigue = 0.01,
            endurance = -0.01,
            stress = 0.02,
            headPain = 0.5,
        },
        bad = {
            hunger = -0.02,
            thirst = 0.02,
            fatigue = 0.02,
            endurance = -0.02,
            stress = 0.04,
            headPain = 1.0,
            panic = 5.0,
        },
        mild = {
            hunger = -0.005,
            thirst = 0.005,
            stress = 0.01,
            headPain = 0.2,
        },
    },
    ["BenzoAddict"] = {
        medium = {
            hunger = -0.01,
            thirst = 0.01,
            fatigue = 0.01,
            endurance = -0.01,
            panic = 2.0,
            stress = 0.02,
        },
        bad = {
            hunger = -0.02,
            thirst = 0.02,
            fatigue = 0.02,
            endurance = -0.02,
            panic = 5.0,
            stress = 0.04,
        },
        mild = {
            stress = 0.01,
            panic = 1.0,
        },
    },
}

-- Aplicar efectos al jugador
function applyWithdrawalEffectsToPlayer(player, effects)
    local stats = player:getStats()
    local bodyDamage = player:getBodyDamage()
    
    if effects.hunger then stats:setHunger(stats:getHunger() + effects.hunger) end
    if effects.thirst then stats:setThirst(stats:getThirst() + effects.thirst) end
    if effects.fatigue then stats:setFatigue(stats:getFatigue() + effects.fatigue) end
    if effects.endurance then stats:setEndurance(stats:getEndurance() + effects.endurance) end
    if effects.stress then stats:setStress(stats:getStress() + effects.stress) end
    if effects.panic then stats:setPanic(stats:getPanic() + effects.panic) end
    
    if effects.headPain then
        local bodyPartHead = bodyDamage:getBodyPart(BodyPartType.Head)
        bodyPartHead:setAdditionalPain(bodyPartHead:getAdditionalPain() + effects.headPain)
    end
end
```

---

## 7. SISTEMA DE CONSUMO Y RESETEO

### 7.1 Patrón OnEat para Resetear Contadores
```lua
-- PATRÓN CRÍTICO: Resetear contador al consumir sustancia
function OnEat_MDMA(food, character, player)
    local player = getPlayer()
    
    -- Inicializar contador si no existe
    if player:getModData().NnCTenMinutesMDMAAddict == nil then
        player:getModData().NnCTenMinutesMDMAAddict = 0
    end
    
    -- RESETEAR contador (crítico para evitar pérdida del trait)
    player:getModData().NnCTenMinutesMDMAAddict = 0
    
    -- Aplicar efectos inmediatos de la droga
    player:getModData().NnCMDMAEffect = 18 -- Duración del efecto
    
    -- Si no tiene el trait de adicción, incrementar progreso
    if not player:HasTrait("MDMAAddict") then
        updateAddictionProgress(player, "MDMA", 1)
    end
    
    -- Efectos inmediatos positivos
    local stats = player:getStats()
    stats:setPain(0)
    stats:setStress(0)
    stats:setPanic(0)
    bodyDamage:setBoredomLevel(0)
    
    -- Notificación al jugador
    if isClient() then
        player:Say("I feel amazing...")
    end
end

function OnEat_Cannabis(food, character, player)
    local player = getPlayer()
    
    -- Diferente lógica para PotHead (se puede perder)
    if player:getModData().NnCTenMinutesPotHead == nil then
        player:getModData().NnCTenMinutesPotHead = 0
    end
    
    -- Resetear contador
    player:getModData().NnCTenMinutesPotHead = 0
    
    -- Efectos especiales para PotHead trait
    local PotHeadBonus = player:HasTrait("PotHead") and 216 or 100
    local effectDuration = 18 * (PotHeadBonus / 100) -- Bonus si tiene el trait
    
    player:getModData().NnCWeeeeedEffect = effectDuration
    
    -- Verificar desarrollo de trait
    if not player:HasTrait("PotHead") then
        updateAddictionProgress(player, "Cannabis", 1)
    end
end
```

### 7.2 Sistema de Efectos Temporales con Traits
```lua
-- Efectos que dependen de tener certain traits
function WeeeeedEffect()
    local player = getPlayer()
    local bodyDamage = player:getBodyDamage()
    local stats = player:getStats()
    
    -- Verificar si el efecto está activo
    local WeeeeedEffect = player:getModData().NnCWeeeeedEffect 
    local isEffectActive = WeeeeedEffect and WeeeeedEffect >= 1 and WeeeeedEffect < 19
    
    if not player:isAsleep() and isEffectActive then
        -- Efectos base del cannabis
        stats:setPain(0)
        bodyDamage:setBoredomLevel(0)
        
        -- Efectos específicos para ParanoidUser (trait permanente)
        if player:HasTrait("ParanoidUser") then
            -- Efectos negativos cuando está drogado
            stats:setHunger(stats:getHunger() + 0.001)
            stats:setThirst(stats:getThirst() + 0.001)
            stats:setFatigue(stats:getFatigue() + 0.001)
            stats:setEndurance(stats:getEndurance() - 0.001)
            stats:setPanic(stats:getPanic() + 25)
            stats:setStress(stats:getStress() + 0.25)
            bodyDamage:setUnhappynessLevel(bodyDamage:getUnhappynessLevel() + 5)
            bodyDamage:setDiscomfortLevel(bodyDamage:getDiscomfortLevel() + 5)
            
            -- Remover stiffness de todas las partes del cuerpo
            for i = 1, #AllBodyParts do
                local bodyPart = bodyDamage:getBodyPart(AllBodyParts[i])
                local stiffness = bodyPart:getStiffness()
                if stiffness > 0 then
                    bodyPart:setStiffness(0)
                    bodyPart:setAdditionalPain(0)
                    player:getFitness():removeStiffnessValue(BodyPartType.ToString(AllBodyParts[i]))
                else 
                    bodyPart:setAdditionalPain(0)
                end
            end
        else
            -- Efectos normales sin ParanoidUser
            -- Efectos positivos más pronunciados
            stats:setEndurance(stats:getEndurance() + 0.005)
            bodyDamage:setUnhappynessLevel(math.max(0, bodyDamage:getUnhappynessLevel() - 2))
        end
        
        -- Decrementar efecto
        player:getModData().NnCWeeeeedEffect = WeeeeedEffect - 1
    end
end
```

---

## 8. SISTEMA DE ACTUALIZACIÓN CONTINUA

### 8.1 Sistema Principal de Actualización de Traits
```lua
-- Función principal que maneja todos los traits dinámicos
function updateDynamicTraits(player)
    -- Incrementar contadores cada 10 minutos
    incrementTraitCounters(player)
    
    -- Aplicar efectos de withdrawal
    for traitName, _ in pairs(TRAIT_THRESHOLDS) do
        if player:HasTrait(traitName) then
            applyWithdrawalEffects(player, traitName)
        end
    end
    
    -- Verificar condiciones de pérdida de traits
    checkTraitLossConditions(player)
    
    -- Aplicar efectos activos de drogas
    applyActiveEffects(player)
end

-- Incrementar contadores de abstinencia
function incrementTraitCounters(player)
    for traitName, config in pairs(TRAIT_THRESHOLDS) do
        if player:HasTrait(traitName) then
            local currentCounter = player:getModData()[config.counter] or 0
            player:getModData()[config.counter] = currentCounter + 1
        end
    end
end

-- Aplicar efectos activos de drogas
function applyActiveEffects(player)
    -- Lista de efectos activos
    local activeEffects = {
        "NnCMDMAEffect",
        "NnCBenzoEffect", 
        "NnCWeeeeedEffect",
        "NnCCocaineEffect",
        "NnCMethEffect",
        "NnCOpioidEffect",
    }
    
    for _, effectName in ipairs(activeEffects) do
        local effectLevel = player:getModData()[effectName] or 0
        if effectLevel > 0 then
            -- Llamar función específica del efecto
            local functionName = effectName:gsub("NnC", ""):gsub("Effect", "") .. "Effect"
            if _G[functionName] then
                _G[functionName]() -- Llamar función dinámica
            end
        end
    end
end

-- Registrar la actualización cada 10 minutos
Events.EveryTenMinutes.Add(updateDynamicTraits)
```

---

## 9. TRAITS TEMPORALES BASADOS EN EVENTOS

### 9.1 Sistema de Traits por Eventos Específicos
```lua
-- Traits temporales que se activan por eventos
local EventBasedTraits = {}

-- Añadir trait temporal por evento
function EventBasedTraits.addTemporaryTrait(player, traitName, duration, reason)
    -- Añadir trait
    if addTraitDynamically(player, traitName, reason) then
        -- Programar remoción automática
        local removalData = {
            player = player,
            traitName = traitName,
            removalTime = getGameTime():getWorldAgeHours() + duration,
            reason = "Temporary trait expired"
        }
        
        -- Guardar en lista de traits temporales
        player:getModData().temporaryTraits = player:getModData().temporaryTraits or {}
        table.insert(player:getModData().temporaryTraits, removalData)
        
        return true
    end
    
    return false
end

-- Actualizar traits temporales
function EventBasedTraits.updateTemporaryTraits(player)
    local temporaryTraits = player:getModData().temporaryTraits
    if not temporaryTraits then return end
    
    local currentTime = getGameTime():getWorldAgeHours()
    
    for i = #temporaryTraits, 1, -1 do
        local traitData = temporaryTraits[i]
        
        if currentTime >= traitData.removalTime then
            -- Remover trait temporal
            removeTraitDynamically(player, traitData.traitName, traitData.reason)
            
            -- Remover de la lista
            table.remove(temporaryTraits, i)
        end
    end
end

-- Ejemplos de uso para traits temporales
Events.OnPlayerDamageFromFire.Add(function(player, damage)
    -- Añadir trait temporal de "Burned" por 2 horas
    EventBasedTraits.addTemporaryTrait(player, "Burned", 2, "Fire damage")
end)

Events.OnPlayerUpdate.Add(function(player)
    EventBasedTraits.updateTemporaryTraits(player)
end)
```

---

## 10. SISTEMA DE TRAITS CONDICIONALES

### 10.1 Traits que Aparecen por Condiciones
```lua
-- Sistema de traits condicionales basados en estado del juego
local ConditionalTraits = {}

function ConditionalTraits.checkEnvironmentalTraits(player)
    local square = player:getSquare()
    local room = square and square:getRoom()
    
    -- Trait por estar en área contaminada
    if isInContaminatedArea(player) then
        if not player:HasTrait("Contaminated") then
            addTraitDynamically(player, "Contaminated", "Entered contaminated area")
        end
    else
        if player:HasTrait("Contaminated") then
            removeTraitDynamically(player, "Contaminated", "Left contaminated area")
        end
    end
    
    -- Trait por estar en bunker/refugio
    if room and room:getName() and room:getName():contains("Bunker") then
        if not player:HasTrait("Sheltered") then
            addTraitDynamically(player, "Sheltered", "Found safe shelter")
        end
    end
end

function ConditionalTraits.checkSocialTraits(player)
    -- Traits basados en número de jugadores cerca
    local nearbyPlayers = getNearbyPlayers(player, 10) -- 10 tiles de radio
    
    if #nearbyPlayers >= 3 then
        if not player:HasTrait("Leader") then
            addTraitDynamically(player, "Leader", "Leading a group")
        end
    else
        if player:HasTrait("Leader") then
            removeTraitDynamically(player, "Leader", "No longer leading")
        end
    end
end

-- Función helper para encontrar jugadores cercanos
function getNearbyPlayers(targetPlayer, radius)
    local players = {}
    local allPlayers = getOnlinePlayers()
    
    for i = 0, allPlayers:size() - 1 do
        local otherPlayer = allPlayers:get(i)
        if otherPlayer ~= targetPlayer then
            local distance = IsoUtils.DistanceTo(
                targetPlayer:getX(), targetPlayer:getY(),
                otherPlayer:getX(), otherPlayer:getY()
            )
            
            if distance <= radius then
                table.insert(players, otherPlayer)
            end
        end
    end
    
    return players
end

-- Actualizar cada minuto
Events.EveryOneMinute.Add(function()
    local player = getPlayer()
    ConditionalTraits.checkEnvironmentalTraits(player)
    ConditionalTraits.checkSocialTraits(player)
end)
```

---

## 11. SISTEMA DE TRAITS PROGRESIVOS

### 11.1 Traits con Niveles de Intensidad
```lua
-- Sistema de traits que evolucionan en intensidad
local ProgressiveTraits = {}

function ProgressiveTraits.updateTraitIntensity(player, baseTrait, levels)
    -- levels es una tabla: { {threshold = 100, trait = "LightAddict"}, {threshold = 500, trait = "HeavyAddict"} }
    
    local progressKey = "progress_" .. baseTrait
    local currentProgress = player:getModData()[progressKey] or 0
    
    -- Determinar qué nivel debe tener
    local targetTrait = nil
    for _, level in ipairs(levels) do
        if currentProgress >= level.threshold then
            targetTrait = level.trait
        end
    end
    
    -- Remover traits anteriores del mismo grupo
    for _, level in ipairs(levels) do
        if player:HasTrait(level.trait) and level.trait ~= targetTrait then
            removeTraitDynamically(player, level.trait, "Trait level changed")
        end
    end
    
    -- Añadir nuevo trait si es necesario
    if targetTrait and not player:HasTrait(targetTrait) then
        addTraitDynamically(player, targetTrait, "Reached trait threshold")
    end
end

-- Ejemplo: Sistema de adicción progresiva
function updateAddictionIntensity(player, substanceName, consumptionAmount)
    local progressKey = "total_consumption_" .. substanceName
    local currentConsumption = player:getModData()[progressKey] or 0
    
    -- Incrementar consumo total
    currentConsumption = currentConsumption + consumptionAmount
    player:getModData()[progressKey] = currentConsumption
    
    -- Definir niveles de adicción
    local addictionLevels = {
        { threshold = 10, trait = "LightAddict_" .. substanceName },
        { threshold = 50, trait = "ModerateAddict_" .. substanceName },
        { threshold = 150, trait = "HeavyAddict_" .. substanceName },
        { threshold = 500, trait = "ChronicAddict_" .. substanceName },
    }
    
    ProgressiveTraits.updateTraitIntensity(player, "Addict_" .. substanceName, addictionLevels)
end
```

---

## 12. SISTEMA DE INTERACCIONES ENTRE TRAITS

### 12.1 Traits que se Afectan Mutuamente
```lua
-- Sistema de sinergias y conflictos entre traits
local TraitInteractions = {}

function TraitInteractions.checkTraitConflicts(player)
    -- Conflictos: traits que no pueden coexistir
    local conflicts = {
        { trait1 = "Pacifist", trait2 = "Aggressive" },
        { trait1 = "Vegetarian", trait2 = "Carnivore" },
        { trait1 = "Teetotaler", trait2 = "Alcoholic" },
    }
    
    for _, conflict in ipairs(conflicts) do
        if player:HasTrait(conflict.trait1) and player:HasTrait(conflict.trait2) then
            -- Remover el trait más recientemente adquirido
            -- (requiere tracking de cuándo se añadió cada trait)
            local trait1Time = player:getModData()["trait_acquired_" .. conflict.trait1] or 0
            local trait2Time = player:getModData()["trait_acquired_" .. conflict.trait2] or 0
            
            if trait1Time > trait2Time then
                removeTraitDynamically(player, conflict.trait1, "Conflicts with " .. conflict.trait2)
            else
                removeTraitDynamically(player, conflict.trait2, "Conflicts with " .. conflict.trait1)
            end
        end
    end
end

function TraitInteractions.checkTraitSynergies(player)
    -- Sinergias: traits que potencian efectos
    local synergies = {
        {
            traits = {"ParanoidUser", "MDMAAddict"},
            effect = function(player)
                -- Panic attack más severo
                local stats = player:getStats()
                stats:setPanic(stats:getPanic() + 10) -- Bonus adicional
            end
        },
        {
            traits = {"PotHead", "Pacifist"},
            effect = function(player)
                -- Reducir agresión más efectivamente
                player:getStats():setAnger(0)
            end
        },
    }
    
    for _, synergy in ipairs(synergies) do
        local hasAllTraits = true
        for _, traitName in ipairs(synergy.traits) do
            if not player:HasTrait(traitName) then
                hasAllTraits = false
                break
            end
        end
        
        if hasAllTraits then
            synergy.effect(player)
        end
    end
end

-- Ejecutar verificaciones regularmente
Events.EveryOneMinute.Add(function()
    local player = getPlayer()
    TraitInteractions.checkTraitConflicts(player)
    TraitInteractions.checkTraitSynergies(player)
end)
```

---

## 13. REGISTRO Y EVENTOS CRÍTICOS

### 13.1 Eventos Fundamentales para Traits
```lua
-- CRÍTICO: Registrar todos los eventos necesarios
Events.OnCreatePlayer.Add(function(playerNum, player)
    initializeTraitCounters(player)
end)

Events.OnGameStart.Add(function()
    initializeTraitCounters(getPlayer())
end)

Events.EveryTenMinutes.Add(function()
    local player = getPlayer()
    updateDynamicTraits(player)
end)

Events.OnPlayerUpdate.Add(function(player)
    -- Efectos que necesitan actualización constante
    WeeeeedEffect()
    MDMAEffect()
    BenzoEffect()
    CocaineEffect()
    MethEffect()
    OpioidEffect()
end)

-- Eventos personalizados para traits
LuaEventManager.AddEvent("OnTraitAdded")
LuaEventManager.AddEvent("OnTraitRemoved")
LuaEventManager.AddEvent("OnWithdrawalLevelChanged")

-- Listener para debugging
Events.OnTraitAdded.Add(function(player, traitName)
    print("[TRAIT DEBUG] Trait added: " .. traitName .. " to player " .. player:getUsername())
end)

Events.OnTraitRemoved.Add(function(player, traitName)
    print("[TRAIT DEBUG] Trait removed: " .. traitName .. " from player " .. player:getUsername())
end)
```

---

## 14. PATRONES PARA IA - GENERACIÓN AUTOMÁTICA

### 14.1 Template de Sistema de Traits Dinámicos
```lua
function generateDynamicTraitSystem(modName, traits)
    local template = [[
-- ]] .. modName .. [[ Dynamic Trait System
local ]] .. modName .. [[Traits = {}

-- Trait configurations
local TRAIT_CONFIG = {
]]

    for _, trait in ipairs(traits) do
        template = template .. '    ["' .. trait.name .. '"] = {\n'
        template = template .. '        counter = "' .. modName .. '_counter_' .. trait.name .. '",\n'
        template = template .. '        lossThreshold = ' .. (trait.lossDays * 144) .. ',\n'
        template = template .. '        withdrawalMild = ' .. (trait.withdrawalMild * 144) .. ',\n'
        template = template .. '        withdrawalBad = ' .. (trait.withdrawalBad * 144) .. ',\n'
        template = template .. '        withdrawalMedium = ' .. (trait.withdrawalMedium * 144) .. ',\n'
        template = template .. '        permanent = ' .. tostring(trait.permanent or false) .. ',\n'
        template = template .. '    },\n'
    end
    
    template = template .. [[
}

-- Main update function
function ]] .. modName .. [[Traits.update(player)
    for traitName, config in pairs(TRAIT_CONFIG) do
        if player:HasTrait(traitName) and not config.permanent then
            local counter = player:getModData()[config.counter] or 0
            counter = counter + 1
            player:getModData()[config.counter] = counter
            
            -- Check for trait removal
            if counter >= config.lossThreshold then
                player:getTraits():remove(traitName)
                print("Lost trait: " .. traitName)
            end
        end
    end
end

Events.EveryTenMinutes.Add(]] .. modName .. [[Traits.update)
]]
    
    return template
end
```

### 14.2 Configuración Sandbox para Traits
```
option ModName.EnableDynamicTraits
{
    type = boolean,
    default = true,
    page = ModName,
    translation = ModName_EnableDynamicTraits,
}

option ModName.TraitLossMultiplier
{
    type = double,
    default = 1.0,
    min = 0.1,
    max = 5.0,
    page = ModName,
    translation = ModName_TraitLossMultiplier,
}

option ModName.WithdrawalSeverity
{
    type = integer,
    default = 2,
    min = 1,
    max = 5,
    page = ModName,
    translation = ModName_WithdrawalSeverity,
}
```

---

## 15. CASOS DE USO PARA IA

### 15.1 Prompt para Crear Sistema de Adicción
```
"Crea un trait dinámico de adicción al café que:
- Se adquiere después de tomar 15 cafés en 7 días
- Causa fatiga extra si no se toma café cada 12 horas
- Se puede perder si no se toma café por 10 días
- Los efectos de withdrawal aumentan gradualmente"

PATRÓN IA:
1. Definir trait con starter=false, onlyStartingTrait=false
2. Crear contador de consumo de café
3. Implementar función OnEat_Coffee que incremente progreso
4. Crear sistema de withdrawal con niveles
5. Implementar pérdida automática por tiempo
6. Registrar eventos de actualización
```

### 15.2 Checklist de Validación para IA
```
✅ VALIDACIÓN COMPLETA:
1. Trait definido en scripts con flags correctos
2. Traducciones completas (nombre + descripción)
3. Contador ModData inicializado
4. Función OnEat/OnUse que resetea contador
5. Sistema de withdrawal implementado
6. Condiciones de pérdida definidas
7. Eventos registrados correctamente
8. Sistema de debugging habilitado
9. Configuración sandbox opcional
10. Interacciones con otros traits consideradas
```

---

*Esta documentación proporciona el sistema más completo para la gestión de traits dinámicos en Project Zomboid, diseñado para desarrolladores humanos y sistemas de IA automatizados.*