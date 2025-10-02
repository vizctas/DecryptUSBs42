-- LaptopEvents.lua - Sistema de Eventos Aleatorios por Fallos Acumulados
-- Eventos que ocurren cuando una laptop tiene 3+ fallos acumulados

LaptopEvents = LaptopEvents or {}

-- ============================================================================
-- CONFIGURACIÓN DE EVENTOS
-- ============================================================================

-- Umbrales de fallos para activar eventos
LaptopEvents.FAILURE_THRESHOLD_LOW = 3   -- Eventos leves
LaptopEvents.FAILURE_THRESHOLD_HIGH = 7  -- Eventos severos

-- Probabilidad base de que ocurra un evento (cuando fallos >= threshold)
LaptopEvents.EVENT_TRIGGER_CHANCE = 25  -- 25% por defecto

-- Probabilidades individuales de cada evento (deben sumar ~100%)
LaptopEvents.EVENT_WEIGHTS = {
    distress_signal = 40,  -- Señal de Socorro Falsa (40%)
    accelerated_damage = 35, -- Daño Acelerado (35%)
    security_alarm = 25     -- Alarma de Seguridad (25%)
}

-- ============================================================================
-- EVENTO 1: SEÑAL DE SOCORRO FALSA
-- ============================================================================

-- Spawn zombies en perímetro exterior del safehouse
function LaptopEvents.triggerDistressSignal(player, laptop, laptopSquare)
    if not player or not laptopSquare then return false end
    
    print("[LaptopEvents] Triggering Distress Signal event...")
    
    -- Obtener configuración de sandbox
    local zombieCount = 5  -- Por defecto 5 zombies
    local spawnRadius = 20 -- 20 tiles de distancia
    
    if SandboxVars and SandboxVars.GVDrive then
        zombieCount = tonumber(SandboxVars.GVDrive.Event_DistressSignal_ZombieCount) or 5
        spawnRadius = tonumber(SandboxVars.GVDrive.Event_DistressSignal_SpawnRadius) or 20
    end
    
    -- Validar rango
    zombieCount = math.max(3, math.min(10, zombieCount))
    spawnRadius = math.max(15, math.min(30, spawnRadius))
    
    local x = laptopSquare:getX()
    local y = laptopSquare:getY()
    local z = laptopSquare:getZ()
    
    -- ✅ VERIFICAR SI ESTÁ EN SAFEHOUSE
    local isInSafehouse = false
    if SafeHouse and SafeHouse.isSafeHouse then
        isInSafehouse = SafeHouse.isSafeHouse(laptopSquare, player:getUsername(), false)
    end
    
    if isInSafehouse then
        print("[LaptopEvents] Player is in safehouse - spawning zombies OUTSIDE safehouse")
        -- Aumentar radio de spawn para estar fuera del safehouse
        spawnRadius = spawnRadius + 15
    end
    
    -- Generar puntos de spawn en círculo alrededor de la laptop
    local spawnedCount = 0
    for i = 1, zombieCount do
        -- Ángulo aleatorio
        local angle = (i / zombieCount) * 2 * math.pi + (ZombRand(100) / 100) * 0.5
        
        -- Calcular posición en el perímetro
        local spawnX = x + math.floor(math.cos(angle) * spawnRadius)
        local spawnY = y + math.floor(math.sin(angle) * spawnRadius)
        
        -- Obtener square de spawn
        local spawnSquare = getCell():getGridSquare(spawnX, spawnY, z)
        
        if spawnSquare then
            -- ✅ VERIFICAR QUE NO SEA SAFEHOUSE
            local spawnInSafehouse = false
            if SafeHouse and SafeHouse.isSafeHouse then
                spawnInSafehouse = SafeHouse.isSafeHouse(spawnSquare, player:getUsername(), false)
            end
            
            -- Verificar que el square sea válido para spawn Y no esté en safehouse
            if not spawnInSafehouse and not spawnSquare:isVehicleIntersecting() and spawnSquare:isFree(false) then
                -- ✅ SPAWN ZOMBIE CORRECTAMENTE usando createZombieInOutfit
                if createZombieInOutfit then
                    local zombie = createZombieInOutfit("Crawler", 0, spawnX, spawnY, z)
                    if zombie then
                        spawnedCount = spawnedCount + 1
                        print("[LaptopEvents] Spawned zombie " .. i .. " at (" .. spawnX .. ", " .. spawnY .. ")")
                        
                        -- Hacer que el zombie sea atraído hacia la laptop
                        if zombie.setX and zombie.setY then
                            zombie:setX(spawnX)
                            zombie:setY(spawnY)
                        end
                    end
                end
            else
                print("[LaptopEvents] Invalid spawn square at (" .. spawnX .. ", " .. spawnY .. ") - safehouse or blocked")
            end
        end
    end
    
    -- Mensaje al jugador
    if player then
        player:Say("The laptop is emitting a strange signal...")
        
        -- Agregar moodle temporal (si está disponible)
        if player.getBodyDamage then
            local bodyDamage = player:getBodyDamage()
            if bodyDamage and bodyDamage.setUnhappynessLevel then
                -- Aumentar estrés temporalmente
                bodyDamage:setStressLevel(bodyDamage:getStressLevel() + 10)
            end
        end
    end
    
    print("[LaptopEvents] Distress Signal complete. Spawned " .. spawnedCount .. " zombies")
    return true
end

-- ============================================================================
-- EVENTO 2: DAÑO ACELERADO
-- ============================================================================

-- Daña la laptop significativamente
function LaptopEvents.triggerAcceleratedDamage(player, laptop, laptopSquare)
    if not laptop then return false end
    
    print("[LaptopEvents] Triggering Accelerated Damage event...")
    
    -- Obtener configuración de sandbox
    local damageAmount = 20  -- Por defecto 20%
    
    if SandboxVars and SandboxVars.GVDrive then
        damageAmount = tonumber(SandboxVars.GVDrive.Event_AcceleratedDamage_Amount) or 20
    end
    
    -- Validar rango (10-40%)
    damageAmount = math.max(10, math.min(40, damageAmount))
    
    -- Aplicar daño usando LaptopSystem
    if LaptopSystem and LaptopSystem.damageLaptop then
        local currentHealth = LaptopSystem.getLaptopHealth(laptop)
        local newHealth = LaptopSystem.damageLaptop(laptop, damageAmount)
        
        print("[LaptopEvents] Laptop damaged: " .. currentHealth .. "% -> " .. newHealth .. "%")
        
        -- Mensaje al jugador
        if player then
            if newHealth <= 0 then
                player:Say("The laptop has completely failed!")
            elseif newHealth <= 25 then
                player:Say("The laptop is critically damaged!")
            else
                player:Say("The laptop's systems are degrading rapidly!")
            end
        end
        
        return true
    end
    
    return false
end

-- ============================================================================
-- EVENTO 3: ALARMA DE SEGURIDAD
-- ============================================================================

-- Emite ruido fuerte que atrae zombies
function LaptopEvents.triggerSecurityAlarm(player, laptop, laptopSquare)
    if not laptopSquare then return false end
    
    print("[LaptopEvents] Triggering Security Alarm event...")
    
    -- Obtener configuración de sandbox
    local alarmDuration = 45  -- Por defecto 45 segundos
    local soundRadius = 50    -- Radio de atracción
    local soundVolume = 100   -- Volumen del sonido
    
    if SandboxVars and SandboxVars.GVDrive then
        alarmDuration = tonumber(SandboxVars.GVDrive.Event_SecurityAlarm_Duration) or 45
        soundRadius = tonumber(SandboxVars.GVDrive.Event_SecurityAlarm_Radius) or 50
        soundVolume = tonumber(SandboxVars.GVDrive.Event_SecurityAlarm_Volume) or 100
    end
    
    -- Validar rangos
    alarmDuration = math.max(30, math.min(90, alarmDuration))
    soundRadius = math.max(30, math.min(100, soundRadius))
    soundVolume = math.max(50, math.min(150, soundVolume))
    
    -- Mensaje al jugador
    if player then
        player:Say("The laptop's security alarm is blaring!")
    end
    
    -- Emitir sonido inicial que ATRAE ZOMBIES
    if getSoundManager() then
        -- PlayWorldSound con parámetros correctos para atraer zombies
        getSoundManager():PlayWorldSound("alarm", laptopSquare, 0, soundVolume / 100, soundRadius, true)
        print("[LaptopEvents] Security alarm started - volume: " .. soundVolume .. ", radius: " .. soundRadius)
    end
    
    -- Crear sonidos repetidos durante la duración
    local ticksPerSecond = 60  -- Project Zomboid usa ~60 ticks por segundo
    local totalTicks = alarmDuration * ticksPerSecond
    local soundInterval = 3 * ticksPerSecond  -- Sonido cada 3 segundos
    
    -- Función recursiva para emitir sonidos
    local function emitAlarmSound(ticksRemaining)
        if ticksRemaining <= 0 then
            print("[LaptopEvents] Security Alarm ended")
            if player then
                player:Say("The alarm has finally stopped...")
            end
            return
        end
        
        -- Emitir sonido que ATRAE ZOMBIES
        if getSoundManager() and laptopSquare then
            getSoundManager():PlayWorldSound("alarm", laptopSquare, 0, soundVolume / 100, soundRadius, true)
            print("[LaptopEvents] Alarm sound emitted, " .. math.floor(ticksRemaining / ticksPerSecond) .. " seconds remaining")
        end
        
        -- Programar siguiente sonido
        if Events and Events.OnTick then
            local ticksElapsed = 0
            local tickHandler
            tickHandler = function()
                ticksElapsed = ticksElapsed + 1
                if ticksElapsed >= soundInterval then
                    Events.OnTick.Remove(tickHandler)
                    emitAlarmSound(ticksRemaining - soundInterval)
                end
            end
            Events.OnTick.Add(tickHandler)
        end
    end
    
    -- Iniciar alarma
    emitAlarmSound(totalTicks)
    
    return true
end

-- ============================================================================
-- SISTEMA DE SELECCIÓN DE EVENTOS
-- ============================================================================

-- Selecciona un evento aleatorio basado en pesos
function LaptopEvents.selectRandomEvent()
    local totalWeight = 0
    for _, weight in pairs(LaptopEvents.EVENT_WEIGHTS) do
        totalWeight = totalWeight + weight
    end
    
    local random = ZombRand(totalWeight)
    local currentWeight = 0
    
    for eventName, weight in pairs(LaptopEvents.EVENT_WEIGHTS) do
        currentWeight = currentWeight + weight
        if random < currentWeight then
            return eventName
        end
    end
    
    return "distress_signal"  -- Fallback
end

-- ============================================================================
-- FUNCIÓN PRINCIPAL: VERIFICAR Y EJECUTAR EVENTOS
-- ============================================================================

-- Verifica si debe ocurrir un evento y lo ejecuta
function LaptopEvents.checkAndTriggerEvent(player, laptop, laptopSquare)
    if not laptop or not player then
        print("[LaptopEvents] Invalid parameters, skipping event check")
        return false
    end
    
    -- Obtener contador de fallos
    local failureCount = 0
    if LaptopSystem and LaptopSystem.getFailureCount then
        failureCount = LaptopSystem.getFailureCount(laptop)
    end
    
    print("[LaptopEvents] Checking events for laptop with " .. failureCount .. " failures")
    
    -- Verificar si alcanza el umbral
    if failureCount < LaptopEvents.FAILURE_THRESHOLD_LOW then
        print("[LaptopEvents] Failure count below threshold (" .. LaptopEvents.FAILURE_THRESHOLD_LOW .. "), no event")
        return false
    end
    
    -- Calcular probabilidad de evento
    local triggerChance = LaptopEvents.EVENT_TRIGGER_CHANCE
    
    -- Aumentar probabilidad si hay muchos fallos
    if failureCount >= LaptopEvents.FAILURE_THRESHOLD_HIGH then
        triggerChance = triggerChance + 15  -- +15% si fallos >= 7
        print("[LaptopEvents] High failure count, increased chance to " .. triggerChance .. "%")
    end
    
    -- Tirar dado
    local roll = ZombRand(100)
    print("[LaptopEvents] Event roll: " .. roll .. " vs " .. triggerChance .. "%")
    
    if roll >= triggerChance then
        print("[LaptopEvents] No event triggered this time")
        return false
    end
    
    -- Seleccionar evento aleatorio
    local eventName = LaptopEvents.selectRandomEvent()
    print("[LaptopEvents] Selected event: " .. eventName)
    
    -- Ejecutar evento
    local success = false
    if eventName == "distress_signal" then
        success = LaptopEvents.triggerDistressSignal(player, laptop, laptopSquare)
    elseif eventName == "accelerated_damage" then
        success = LaptopEvents.triggerAcceleratedDamage(player, laptop, laptopSquare)
    elseif eventName == "security_alarm" then
        success = LaptopEvents.triggerSecurityAlarm(player, laptop, laptopSquare)
    end
    
    if success then
        print("[LaptopEvents] Event '" .. eventName .. "' executed successfully")
        
        -- ⚠️ RESET CONTADOR DE FALLOS DESPUÉS DE EVENTO EXITOSO
        if LaptopSystem and LaptopSystem.setFailureCount then
            LaptopSystem.setFailureCount(laptop, 0)
            print("[LaptopEvents] Failure count reset to 0 after successful event")
        end
    else
        print("[LaptopEvents] Event '" .. eventName .. "' failed to execute")
    end
    
    return success
end

-- ============================================================================
-- FUNCIÓN DE RECARGA PARA DEBUG
-- ============================================================================

function ReloadLaptopEvents()
    print("[DEBUG] Reloading LaptopEvents system...")
    package.loaded["shared/LaptopEvents"] = nil
    local success, result = pcall(require, "shared/LaptopEvents")
    if success then
        print("[DEBUG] LaptopEvents reloaded successfully!")
    else
        print("[DEBUG] Failed to reload LaptopEvents: " .. tostring(result))
    end
end

-- ============================================================================
-- FUNCIÓN DE DIAGNÓSTICO PARA DEBUG
-- ============================================================================

-- Función de diagnóstico para eventos de laptop
function DiagnoseLaptopEvents()
    print("=== LAPTOP EVENTS DIAGNOSTIC ===")

    -- Verificar que el módulo esté cargado
    if not LaptopEvents then
        print("❌ ERROR: LaptopEvents module not loaded!")
        return false
    end
    print("✅ LaptopEvents module is loaded")

    -- Verificar configuración
    print("📊 Configuration:")
    print("   - FAILURE_THRESHOLD_LOW: " .. tostring(LaptopEvents.FAILURE_THRESHOLD_LOW))
    print("   - FAILURE_THRESHOLD_HIGH: " .. tostring(LaptopEvents.FAILURE_THRESHOLD_HIGH))
    print("   - EVENT_TRIGGER_CHANCE: " .. tostring(LaptopEvents.EVENT_TRIGGER_CHANCE) .. "%")

    -- Verificar pesos de eventos
    print("🎯 Event Weights:")
    for eventName, weight in pairs(LaptopEvents.EVENT_WEIGHTS) do
        print("   - " .. eventName .. ": " .. weight .. "%")
    end

    -- Verificar funciones principales
    print("🔧 Functions Check:")
    if LaptopEvents.checkAndTriggerEvent and type(LaptopEvents.checkAndTriggerEvent) == "function" then
        print("   ✅ checkAndTriggerEvent: Available")
    else
        print("   ❌ checkAndTriggerEvent: Missing!")
    end

    if LaptopEvents.triggerDistressSignal and type(LaptopEvents.triggerDistressSignal) == "function" then
        print("   ✅ triggerDistressSignal: Available")
    else
        print("   ❌ triggerDistressSignal: Missing!")
    end

    if LaptopEvents.triggerAcceleratedDamage and type(LaptopEvents.triggerAcceleratedDamage) == "function" then
        print("   ✅ triggerAcceleratedDamage: Available")
    else
        print("   ❌ triggerAcceleratedDamage: Missing!")
    end

    if LaptopEvents.triggerSecurityAlarm and type(LaptopEvents.triggerSecurityAlarm) == "function" then
        print("   ✅ triggerSecurityAlarm: Available")
    else
        print("   ❌ triggerSecurityAlarm: Missing!")
    end

    -- Verificar integración con GVDrive_Utils
    if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
        print("✅ GVDrive_Utils.applyMinigameResult: Available")
    else
        print("❌ GVDrive_Utils.applyMinigameResult: Missing!")
    end

    -- Verificar LaptopSystem
    if LaptopSystem and LaptopSystem.getFailureCount then
        print("✅ LaptopSystem.getFailureCount: Available")
    else
        print("❌ LaptopSystem.getFailureCount: Missing!")
    end

    -- Test del sistema con datos simulados
    print("🧪 Testing Event System:")

    -- Simular un jugador y laptop
    local player = getPlayer()
    if not player then
        print("   ⚠️  No player found for testing")
        return false
    end

    -- Buscar una laptop en el inventario
    local laptop = nil
    local inventory = player:getInventory()
    if inventory then
        local items = inventory:getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and item:getType() then
                local typeName = item:getType()
                if typeName:find("Laptop") or typeName:find("USB") then
                    laptop = item
                    break
                end
            end
        end
    end

    if laptop then
        print("   📱 Found laptop: " .. laptop:getType())

        -- Obtener contador de fallos
        local failureCount = 0
        if LaptopSystem and LaptopSystem.getFailureCount then
            failureCount = LaptopSystem.getFailureCount(laptop)
            print("   📊 Failure count: " .. failureCount)
        end

        -- Obtener square del jugador
        local square = player:getCurrentSquare()
        if square then
            print("   📍 Player square: (" .. square:getX() .. ", " .. square:getY() .. ")")

            -- Probar el sistema de eventos
            print("   🎲 Testing event trigger...")
            local result = LaptopEvents.checkAndTriggerEvent(player, laptop, square)
            if result then
                print("   ✅ Event triggered successfully!")
            else
                print("   ❌ Event not triggered (this is normal due to probability)")
            end
        else
            print("   ❌ No player square found")
        end
    else
        print("   ❌ No laptop found in inventory")
    end

    print("=== DIAGNOSTIC COMPLETE ===")
    return true
end

-- ============================================================================
-- FUNCIONES DE PRUEBA FORZADA
-- ============================================================================

-- Forzar un evento específico para pruebas
function ForceLaptopEvent(eventName)
    print("=== FORCING LAPTOP EVENT: " .. eventName .. " ===")

    local player = getPlayer()
    if not player then
        print("❌ No player found!")
        return false
    end

    -- Buscar una laptop en el inventario
    local laptop = nil
    local inventory = player:getInventory()
    if inventory then
        local items = inventory:getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and item:getType() then
                local typeName = item:getType()
                if typeName:find("Laptop") then
                    laptop = item
                    break
                end
            end
        end
    end

    if not laptop then
        print("❌ No laptop found in inventory!")
        return false
    end

    local square = player:getCurrentSquare()
    if not square then
        print("❌ No player square found!")
        return false
    end

    print("🎯 Forcing event: " .. eventName)
    local success = false

    if eventName == "distress_signal" then
        success = LaptopEvents.triggerDistressSignal(player, laptop, square)
    elseif eventName == "accelerated_damage" then
        success = LaptopEvents.triggerAcceleratedDamage(player, laptop, square)
    elseif eventName == "security_alarm" then
        success = LaptopEvents.triggerSecurityAlarm(player, laptop, square)
    elseif eventName == "random" then
        success = LaptopEvents.checkAndTriggerEvent(player, laptop, square)
    else
        print("❌ Unknown event name. Use: distress_signal, accelerated_damage, security_alarm, or random")
        return false
    end

    if success then
        print("✅ Event '" .. eventName .. "' executed successfully!")
    else
        print("❌ Event '" .. eventName .. "' failed to execute!")
    end

    return success
end

print("[LaptopEvents] Module loaded successfully")
