-- DynamicSoundSystem.lua - Sistema de Sonidos Dinámicos y Reactivos
-- Reproduce sonidos apropiados según contexto y situación del juego

DynamicSoundSystem = DynamicSoundSystem or {}

-- ============================================================================
-- CONFIGURACIÓN
-- ============================================================================

-- Volúmenes por defecto (0.0 - 1.0)
DynamicSoundSystem.VOLUMES = {
    typing = 0.3,
    success = 0.5,
    failure = 0.4,
    warning = 0.6,
    alarm = 0.7,
    fan = 0.25,
    beep = 0.4
}

-- Control de sonidos repetitivos
DynamicSoundSystem.activeSounds = {}
DynamicSoundSystem.lastSoundTime = {}

-- ============================================================================
-- SONIDOS BÁSICOS DEL SISTEMA
-- ============================================================================

-- Tecleo durante minijuego (loop)
function DynamicSoundSystem.playTypingSound(player, intensity)
    if not player or not getSoundManager() then return end
    
    intensity = intensity or 1.0
    local volume = DynamicSoundSystem.VOLUMES.typing * intensity
    
    -- Usar sonido de teclado USB existente
    local square = player:getCurrentSquare()
    if square then
        local emitter = getSoundManager():PlaySound("USBkeyboard", square, 0, volume)
        
        if emitter then
            print("[DynamicSound] Playing typing sound (volume: " .. volume .. ")")
            return emitter
        end
    end
end

-- Sonido de éxito
function DynamicSoundSystem.playSuccessSound(player, isEpic)
    if not player or not getSoundManager() then return end
    
    local volume = DynamicSoundSystem.VOLUMES.success
    
    -- Si es éxito épico (Elite Drive), volumen mayor
    if isEpic then
        volume = volume * 1.5
    end
    
    local square = player:getCurrentSquare()
    if square then
        -- Usar sonido de teclado como "beep" de éxito
        getSoundManager():PlaySound("USBkeyboard", square, 0, volume)
        
        print("[DynamicSound] Playing success sound " .. (isEpic and "(EPIC)" or ""))
    end
end

-- Sonido de fallo
function DynamicSoundSystem.playFailureSound(player)
    if not player or not getSoundManager() then return end
    
    local volume = DynamicSoundSystem.VOLUMES.failure
    local square = player:getCurrentSquare()
    
    if square then
        -- Usar alarm.ogg existente a bajo volumen como sonido de error
        getSoundManager():PlaySound("alarm", square, 0, volume * 0.3)
        
        print("[DynamicSound] Playing failure sound")
    end
end

-- ============================================================================
-- SONIDOS DE ADVERTENCIA
-- ============================================================================

-- Beep de advertencia (laptop baja salud)
function DynamicSoundSystem.playWarningBeep(player, urgent)
    if not player or not getSoundManager() then return end
    
    -- Evitar spam de beeps
    local currentTime = getTimestamp()
    local lastBeep = DynamicSoundSystem.lastSoundTime["warning_beep"] or 0
    
    if currentTime - lastBeep < 120 then  -- Cooldown de 2 segundos
        return
    end
    
    DynamicSoundSystem.lastSoundTime["warning_beep"] = currentTime
    
    local volume = urgent and DynamicSoundSystem.VOLUMES.warning * 1.5 or DynamicSoundSystem.VOLUMES.warning
    local square = player:getCurrentSquare()
    
    if square then
        -- Beep corto usando alarm
        getSoundManager():PlaySound("alarm", square, 0, volume * 0.2)
        
        print("[DynamicSound] Playing warning beep " .. (urgent and "(URGENT)" or ""))
    end
end

-- Sonido de alarma de sobrecalentamiento
function DynamicSoundSystem.playOverheatAlarm(player)
    if not player or not getSoundManager() then return end
    
    local volume = DynamicSoundSystem.VOLUMES.alarm
    local square = player:getCurrentSquare()
    
    if square then
        getSoundManager():PlaySound("alarm", square, 0, volume * 0.5)
        
        print("[DynamicSound] Playing overheat alarm")
    end
end

-- ============================================================================
-- SONIDOS AMBIENTALES
-- ============================================================================

-- Sonido de ventilador (cuando laptop está caliente)
function DynamicSoundSystem.playFanSound(player, temperature)
    if not player or not getSoundManager() then return end
    
    -- Solo reproducir si temperatura > 60°C
    if temperature < 60 then return end
    
    -- Calcular volumen según temperatura (60-100°C)
    local tempRatio = (temperature - 60) / 40  -- 0.0 a 1.0
    local volume = DynamicSoundSystem.VOLUMES.fan + (tempRatio * 0.3)
    
    local square = player:getCurrentSquare()
    if square then
        -- Usar alarm.ogg muy bajo como "hum" de ventilador
        -- En un mod real, usarías un sonido de ventilador dedicado
        getSoundManager():PlaySound("alarm", square, 0, volume * 0.15)
        
        print("[DynamicSound] Playing fan sound (temp: " .. temperature .. "°C, volume: " .. volume .. ")")
    end
end

-- ============================================================================
-- SECUENCIAS DE SONIDO
-- ============================================================================

-- Secuencia de inicio de minijuego
function DynamicSoundSystem.playMinigameStartSequence(player)
    if not player then return end
    
    -- Sonido inicial de "boot up"
    DynamicSoundSystem.playTypingSound(player, 0.5)
    
    print("[DynamicSound] Minigame start sequence")
end

-- Secuencia de finalización de minijuego
function DynamicSoundSystem.playMinigameEndSequence(player, success, isEpic)
    if not player then return end
    
    if success then
        DynamicSoundSystem.playSuccessSound(player, isEpic)
        
        -- Si es épico, reproducir sonido extra después de un delay
        if isEpic then
            -- En un sistema real, usarías un timer para esto
            print("[DynamicSound] Epic success sequence")
        end
    else
        DynamicSoundSystem.playFailureSound(player)
    end
end

-- ============================================================================
-- GESTIÓN DE SONIDOS EN LOOP
-- ============================================================================

-- Iniciar loop de tecleo durante minijuego
function DynamicSoundSystem.startTypingLoop(player, speed)
    if not player then return end
    
    speed = speed or 1.0
    
    -- Marcar que el loop está activo
    DynamicSoundSystem.activeSounds["typing_loop"] = {
        active = true,
        player = player,
        speed = speed,
        lastTick = getTimestamp()
    }
    
    print("[DynamicSound] Started typing loop (speed: " .. speed .. ")")
end

-- Detener loop de tecleo
function DynamicSoundSystem.stopTypingLoop()
    if DynamicSoundSystem.activeSounds["typing_loop"] then
        DynamicSoundSystem.activeSounds["typing_loop"].active = false
        DynamicSoundSystem.activeSounds["typing_loop"] = nil
        
        print("[DynamicSound] Stopped typing loop")
    end
end

-- Actualizar loops activos (llamar desde evento de tick)
function DynamicSoundSystem.updateSoundLoops()
    -- Actualizar typing loop
    local typingLoop = DynamicSoundSystem.activeSounds["typing_loop"]
    if typingLoop and typingLoop.active then
        local currentTick = getTimestamp()
        local ticksSinceLastSound = currentTick - typingLoop.lastTick
        
        -- Reproducir tecleo cada 20-30 ticks según velocidad
        local interval = math.floor(25 / typingLoop.speed)
        
        if ticksSinceLastSound >= interval then
            DynamicSoundSystem.playTypingSound(typingLoop.player, typingLoop.speed)
            typingLoop.lastTick = currentTick
        end
    end
end

-- ============================================================================
-- INTEGRACIÓN CON SISTEMAS EXISTENTES
-- ============================================================================

-- Sonido reactivo según temperatura de laptop
function DynamicSoundSystem.onTemperatureCheck(player, laptop)
    if not player or not laptop then return end
    
    if LaptopThermalSystem and LaptopThermalSystem.getTemperature then
        local temp = LaptopThermalSystem.getTemperature(laptop)
        
        -- Ventilador si está caliente
        if temp >= 60 and temp < 85 then
            DynamicSoundSystem.playFanSound(player, temp)
        end
        
        -- Alarma si está crítico
        if temp >= 85 then
            DynamicSoundSystem.playOverheatAlarm(player)
        end
    end
end

-- Sonido reactivo según salud de laptop
function DynamicSoundSystem.onLaptopHealthCheck(player, laptop)
    if not player or not laptop then return end
    
    if LaptopSystem and LaptopSystem.getLaptopHealth then
        local health = LaptopSystem.getLaptopHealth(laptop)
        
        -- Beep de advertencia si salud baja
        if health <= 15 and health > 0 then
            DynamicSoundSystem.playWarningBeep(player, health <= 5)
        end
    end
end

-- ============================================================================
-- FUNCIONES DE INTEGRACIÓN CON MINIJUEGOS
-- ============================================================================

-- Llamar cuando minijuego comienza
function DynamicSoundSystem.onMinigameStart(player, difficulty)
    if not player then return end
    
    DynamicSoundSystem.playMinigameStartSequence(player)
    
    -- Iniciar loop de tecleo con velocidad según dificultad
    local speed = 1.0
    if difficulty == "Moderate" then
        speed = 1.3
    elseif difficulty == "Expert" then
        speed = 1.6
    end
    
    DynamicSoundSystem.startTypingLoop(player, speed)
end

-- Llamar cuando minijuego termina
function DynamicSoundSystem.onMinigameEnd(player, success, difficulty)
    if not player then return end
    
    -- Detener loops
    DynamicSoundSystem.stopTypingLoop()
    
    -- Reproducir secuencia de fin
    local isEpic = (difficulty == "Expert" or difficulty == "Elite")
    DynamicSoundSystem.playMinigameEndSequence(player, success, isEpic)
end

-- Llamar durante progreso de minijuego
function DynamicSoundSystem.onMinigameProgress(player, progressPercent)
    if not player then return end
    
    -- Aumentar intensidad de tecleo según progreso
    local typingLoop = DynamicSoundSystem.activeSounds["typing_loop"]
    if typingLoop and typingLoop.active then
        -- Acelerar ligeramente según progreso (100% = +20% velocidad)
        typingLoop.speed = 1.0 + (progressPercent * 0.2)
    end
end

-- ============================================================================
-- CONFIGURACIÓN Y PERSONALIZACIÓN
-- ============================================================================

-- Ajustar volumen global
function DynamicSoundSystem.setGlobalVolume(multiplier)
    multiplier = math.max(0, math.min(2.0, multiplier))
    
    for soundType, volume in pairs(DynamicSoundSystem.VOLUMES) do
        DynamicSoundSystem.VOLUMES[soundType] = volume * multiplier
    end
    
    print("[DynamicSound] Global volume set to " .. (multiplier * 100) .. "%")
end

-- Habilitar/deshabilitar sonidos
DynamicSoundSystem.enabled = true

function DynamicSoundSystem.setEnabled(enabled)
    DynamicSoundSystem.enabled = enabled
    
    if not enabled then
        -- Detener todos los loops activos
        DynamicSoundSystem.stopTypingLoop()
    end
    
    print("[DynamicSound] System " .. (enabled and "enabled" or "disabled"))
end

-- ============================================================================
-- FUNCIONES DE DEBUG
-- ============================================================================

function ReloadDynamicSound()
    print("[DEBUG] Reloading DynamicSoundSystem...")
    package.loaded["shared/DynamicSoundSystem"] = nil
    local success, result = pcall(require, "shared/DynamicSoundSystem")
    if success then
        print("[DEBUG] DynamicSoundSystem reloaded successfully!")
    else
        print("[DEBUG] Failed to reload: " .. tostring(result))
    end
end

function TestSound(soundType)
    local player = getPlayer()
    if not player then
        print("❌ No player found")
        return
    end
    
    print("🔊 Testing sound: " .. (soundType or "typing"))
    
    if soundType == "typing" then
        DynamicSoundSystem.playTypingSound(player, 1.0)
    elseif soundType == "success" then
        DynamicSoundSystem.playSuccessSound(player, false)
    elseif soundType == "epic" then
        DynamicSoundSystem.playSuccessSound(player, true)
    elseif soundType == "failure" then
        DynamicSoundSystem.playFailureSound(player)
    elseif soundType == "warning" then
        DynamicSoundSystem.playWarningBeep(player, false)
    elseif soundType == "urgent" then
        DynamicSoundSystem.playWarningBeep(player, true)
    elseif soundType == "overheat" then
        DynamicSoundSystem.playOverheatAlarm(player)
    elseif soundType == "fan" then
        DynamicSoundSystem.playFanSound(player, 80)
    elseif soundType == "start" then
        DynamicSoundSystem.onMinigameStart(player, "Expert")
    elseif soundType == "end_success" then
        DynamicSoundSystem.onMinigameEnd(player, true, "Expert")
    elseif soundType == "end_failure" then
        DynamicSoundSystem.onMinigameEnd(player, false, "Easy")
    else
        DynamicSoundSystem.playTypingSound(player, 1.0)
    end
end

function StartTypingLoop(speed)
    local player = getPlayer()
    if not player then
        print("❌ No player found")
        return
    end
    
    DynamicSoundSystem.startTypingLoop(player, speed or 1.0)
    print("✅ Typing loop started")
end

function StopTypingLoop()
    DynamicSoundSystem.stopTypingLoop()
    print("✅ Typing loop stopped")
end

print("[DynamicSoundSystem] Module loaded successfully")
