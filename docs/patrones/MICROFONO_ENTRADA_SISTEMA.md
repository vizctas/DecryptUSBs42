# SISTEMA DE ENTRADA DE MICRÓFONO - PROJECT ZOMBOID

## ANÁLISIS EXHAUSTIVO DE DETECCIÓN DE AUDIO

*Basado en análisis de "Zombies Hear Your Microphone" - Sistema completo de captura y procesamiento de audio*

---

## 1. ARQUITECTURA DEL SISTEMA DE MICRÓFONO

### 1.1 Componentes Principales
```
SISTEMA DE MICRÓFONO:
├── Audio Capture          # Captura de audio del micrófono
├── Volume Processing      # Procesamiento de volumen
├── Sound Generation       # Generación de sonidos en el mundo
├── VOIP Integration      # Integración con sistema VOIP
├── Configuration System   # Sistema de configuración
└── Visual Feedback       # Retroalimentación visual
```

### 1.2 Estructura de Archivos
```
MicrophoneMod/
├── media/lua/client/
│   ├── hotMic.lua                    # Sistema principal
│   ├── hotMic_config.lua             # Configuración
│   └── hotMic_eventAdd.lua           # Registro de eventos
├── media/textures/
│   └── ui/                           # Texturas de UI
└── sandbox-options.txt               # Opciones de configuración
```

---

## 2. SISTEMA PRINCIPAL DE CAPTURA DE AUDIO

### 2.1 Configuración Base del Sistema
```lua
local hotMic = {}

-- Valores de descuento para habilidades (array de multiplicadores)
local DISCOUNT_VALUES = { 1.0, 0.97, 0.94, 0.91, 0.88, 0.85, 0.82, 0.79, 0.76, 0.73, 0.7 }

-- Variable para el círculo visual de radio
---@type GridSquareMarker
local circle

-- Función principal que se ejecuta cada frame del jugador
---@param playerObj IsoMovingObject|IsoGameCharacter|IsoPlayer
function hotMic.onPlayerUpdate(playerObj)
    -- Verificaciones de seguridad básicas
    if playerObj:isDead() or playerObj:isAsleep() then return end
    
    -- Activar testing de micrófono en el core del juego
    getCore():setTestingMicrophone(true)
    
    -- Obtener configuraciones de sandbox
    local traitsInfluence = SandboxVars.ZombiesHearYourMicrophone.traitsInfluence
    local skillsInfluence = SandboxVars.ZombiesHearYourMicrophone.skillsInfluence
    local sneakReduce = SandboxVars.ZombiesHearYourMicrophone.sneakReduce
    
    -- Calcular modificadores
    local factor = calculateAudioFactor(playerObj, traitsInfluence, skillsInfluence, sneakReduce)
    
    -- Procesar audio del micrófono
    local volume = processAudioInput(factor)
    if volume == nil then return end  -- Error en captura de audio
    
    -- Verificar configuraciones VOIP
    if not checkVOIPSettings() then return end
    
    -- Generar sonido en el mundo del juego
    AddWorldSound(playerObj, volume, volume)
    
    -- Mostrar retroalimentación visual si está habilitada
    showVisualFeedback(playerObj, volume)
end
```

### 2.2 Sistema de Cálculo de Factores de Audio
```lua
function calculateAudioFactor(playerObj, traitsInfluence, skillsInfluence, sneakReduce)
    local traitsMultiplier = 0
    
    -- Procesar influencia de traits
    if traitsInfluence and traitsInfluence ~= 1 then
        -- Traits negativos (hacen más ruido)
        if traitsInfluence == 2 or traitsInfluence == 4 then
            traitsMultiplier = traitsMultiplier + (playerObj:HasTrait("Conspicuous") and 1 or 0)
            traitsMultiplier = traitsMultiplier + (playerObj:HasTrait("Clumsy") and 0.2 or 0)
        end
        
        -- Traits positivos (reducen ruido)
        if traitsInfluence == 3 or traitsInfluence == 4 then
            traitsMultiplier = traitsMultiplier - (playerObj:HasTrait("Graceful") and 0.6 or 0)
            traitsMultiplier = traitsMultiplier - (playerObj:HasTrait("Inconspicuous") and 0.5 or 0)
        end
        
        -- Limitar reducción máxima
        if traitsMultiplier < -0.9 then traitsMultiplier = -0.9 end
    end
    
    -- Calcular factor base
    local factor = (1 + traitsMultiplier) * (SandboxVars.ZombiesHearYourMicrophone.multiplier or 1.5)
    
    -- Aplicar influencia de habilidades
    if skillsInfluence and skillsInfluence > 1 then
        if skillsInfluence == 2 or skillsInfluence == 4 then
            -- Habilidad Lightfoot reduce ruido
            factor = factor * DISCOUNT_VALUES[1 + playerObj:getPerkLevel(Perks.Lightfoot)]
        end
        if skillsInfluence == 3 or skillsInfluence == 4 then
            -- Habilidad Sneak reduce ruido
            factor = factor * DISCOUNT_VALUES[1 + playerObj:getPerkLevel(Perks.Sneak)]
        end
    end
    
    -- Reducción adicional si está agachado
    if playerObj:isSneaking() then
        factor = factor * sneakReduce
    end
    
    return factor
end
```

### 2.3 Procesamiento de Entrada de Audio
```lua
function processAudioInput(factor)
    local core = getCore()
    
    -- Obtener volumen del micrófono (0-10)
    local rawVolume = core:getMicVolumeIndicator()
    local volume = math.min(10, math.max(0, rawVolume)) * factor
    
    -- Verificar errores en el micrófono
    local isErr = core:getMicVolumeError()
    if isErr then 
        print("[HotMic] Microphone error detected")
        return nil 
    end
    
    return volume
end
```

### 2.4 Verificación de Configuraciones VOIP
```lua
function checkVOIPSettings()
    local core = getCore()
    
    -- Verificar si se debe respetar la configuración VOIP
    if not SandboxVars.ZombiesHearYourMicrophone.respectEnableVOIP then
        return true  -- Ignorar configuraciones VOIP
    end
    
    -- Verificar Push-to-Talk
    local isPTT = core:getOptionVoiceMode() == 1
    local isPTTKeyDown = GameKeyboard.isKeyDown(core:getKey("Enable voice transmit"))
    if isPTT and not isPTTKeyDown then
        return false  -- PTT activado pero tecla no presionada
    end
    
    -- Verificar VOIP del servidor
    local serverVOIPEnable = core:getServerVOIPEnable()
    if not serverVOIPEnable then
        return false  -- VOIP deshabilitado en servidor
    end
    
    -- Verificar VOIP del cliente
    local voiceEnabled = core:getOptionVoiceEnable()
    if not voiceEnabled then
        return false  -- VOIP deshabilitado en cliente
    end
    
    return true
end
```

---

## 3. SISTEMA DE RETROALIMENTACIÓN VISUAL

### 3.1 Círculo de Radio Visual
```lua
function showVisualFeedback(playerObj, volume)
    -- Verificar si la retroalimentación visual está habilitada
    local options = PZAPI.ModOptions:getOptions("ZombiesHearYourMicrophone")
    local option = options and options:getOption("ZombiesHearYourMicrophone_visualRadius")
    local optionValue = option and option:getValue()
    
    if not optionValue then return end
    
    local worldMarkers = getWorldMarkers()
    
    if circle then
        -- Actualizar círculo existente
        circle:setPosAndSize(
            playerObj:getX(),
            playerObj:getY(), 
            playerObj:getZ(),
            volume * 2  -- Diámetro = volumen * 2
        )
    else
        -- Crear nuevo círculo
        local pSquare = playerObj:getSquare()
        circle = worldMarkers:addGridSquareMarker(
            "circle_center",    # Tipo de marcador
            nil,               # Texto (ninguno)
            pSquare,           # Posición
            1, 1, 1,           # Color RGB (blanco)
            true,              # Visible
            volume * 2         # Tamaño
        )
        circle:setScaleCircleTexture(true)
    end
end
```

### 3.2 Sistema de Colores Dinámicos
```lua
function updateVisualFeedbackColor(volume)
    if not circle then return end
    
    -- Calcular color basado en volumen (verde -> amarillo -> rojo)
    local red, green, blue
    
    if volume < 3 then
        -- Verde (bajo volumen)
        red = 0.0
        green = 1.0
        blue = 0.0
    elseif volume < 6 then
        -- Amarillo (volumen medio)
        local factor = (volume - 3) / 3
        red = factor
        green = 1.0
        blue = 0.0
    else
        -- Rojo (alto volumen)
        local factor = math.min(1.0, (volume - 6) / 4)
        red = 1.0
        green = 1.0 - factor
        blue = 0.0
    end
    
    circle:setColor(red, green, blue)
end
```

---

## 4. SISTEMA DE CONFIGURACIÓN AVANZADO

### 4.1 Opciones de Sandbox Completas
```
option ZombiesHearYourMicrophone.multiplier
{
    type = double,
    min = 0.1,
    max = 5.0,
    default = 1.5,
    page = ZombiesHearYourMicrophone,
    translation = ZombiesHearYourMicrophone_multiplier,
}

option ZombiesHearYourMicrophone.traitsInfluence
{
    type = integer,
    min = 1,
    max = 4,
    default = 4,
    page = ZombiesHearYourMicrophone,
    translation = ZombiesHearYourMicrophone_traitsInfluence,
}

option ZombiesHearYourMicrophone.skillsInfluence
{
    type = integer,
    min = 1,
    max = 4,
    default = 4,
    page = ZombiesHearYourMicrophone,
    translation = ZombiesHearYourMicrophone_skillsInfluence,
}

option ZombiesHearYourMicrophone.sneakReduce
{
    type = double,
    min = 0.1,
    max = 1.0,
    default = 0.5,
    page = ZombiesHearYourMicrophone,
    translation = ZombiesHearYourMicrophone_sneakReduce,
}

option ZombiesHearYourMicrophone.respectEnableVOIP
{
    type = boolean,
    default = true,
    page = ZombiesHearYourMicrophone,
    translation = ZombiesHearYourMicrophone_respectEnableVOIP,
}
```

### 4.2 Sistema de Traducciones
```lua
-- Archivo de traducción EN
ZombiesHearYourMicrophone_EN = {
    ZombiesHearYourMicrophone_multiplier = "Volume Multiplier",
    ZombiesHearYourMicrophone_multiplier_tooltip = "Multiplies the microphone volume",
    
    ZombiesHearYourMicrophone_traitsInfluence = "Traits Influence",
    ZombiesHearYourMicrophone_traitsInfluence_tooltip = "How traits affect microphone detection",
    
    ZombiesHearYourMicrophone_skillsInfluence = "Skills Influence", 
    ZombiesHearYourMicrophone_skillsInfluence_tooltip = "How skills affect microphone detection",
    
    ZombiesHearYourMicrophone_sneakReduce = "Sneak Reduction",
    ZombiesHearYourMicrophone_sneakReduce_tooltip = "Volume reduction when sneaking",
    
    ZombiesHearYourMicrophone_respectEnableVOIP = "Respect VOIP Settings",
    ZombiesHearYourMicrophone_respectEnableVOIP_tooltip = "Only work when VOIP is enabled",
}
```

---

## 5. SISTEMA DE FILTROS DE AUDIO AVANZADO

### 5.1 Procesamiento de Ruido de Fondo
```lua
local AudioFilters = {}

function AudioFilters.initializeFilters()
    AudioFilters.noiseThreshold = SandboxVars.ZombiesHearYourMicrophone.noiseThreshold or 0.1
    AudioFilters.smoothingFactor = 0.3
    AudioFilters.previousVolume = 0
    AudioFilters.volumeHistory = {}
    AudioFilters.maxHistorySize = 10
end

function AudioFilters.processVolume(rawVolume)
    -- Filtro de umbral de ruido
    if rawVolume < AudioFilters.noiseThreshold then
        rawVolume = 0
    end
    
    -- Suavizado temporal
    local smoothedVolume = AudioFilters.previousVolume * AudioFilters.smoothingFactor + 
                          rawVolume * (1 - AudioFilters.smoothingFactor)
    
    -- Actualizar historial
    table.insert(AudioFilters.volumeHistory, smoothedVolume)
    if #AudioFilters.volumeHistory > AudioFilters.maxHistorySize then
        table.remove(AudioFilters.volumeHistory, 1)
    end
    
    AudioFilters.previousVolume = smoothedVolume
    return smoothedVolume
end

function AudioFilters.detectSpeech(volume)
    -- Detectar si es habla vs ruido de fondo
    if #AudioFilters.volumeHistory < 5 then return false end
    
    local variance = 0
    local mean = 0
    
    -- Calcular media
    for _, v in ipairs(AudioFilters.volumeHistory) do
        mean = mean + v
    end
    mean = mean / #AudioFilters.volumeHistory
    
    -- Calcular varianza
    for _, v in ipairs(AudioFilters.volumeHistory) do
        variance = variance + (v - mean) ^ 2
    end
    variance = variance / #AudioFilters.volumeHistory
    
    -- Si hay mucha variación, probablemente es habla
    return variance > 0.05 and mean > 0.2
end
```

### 5.2 Sistema de Calibración Automática
```lua
local AutoCalibration = {}

function AutoCalibration.startCalibration()
    AutoCalibration.calibrationSamples = {}
    AutoCalibration.calibrationTime = 30  -- 30 segundos
    AutoCalibration.startTime = getTimestampMs()
    AutoCalibration.isCalibrating = true
    
    getPlayer():Say("Microphone calibration started. Please remain quiet for 30 seconds.")
end

function AutoCalibration.updateCalibration()
    if not AutoCalibration.isCalibrating then return end
    
    local currentTime = getTimestampMs()
    local elapsed = (currentTime - AutoCalibration.startTime) / 1000
    
    if elapsed >= AutoCalibration.calibrationTime then
        AutoCalibration.finishCalibration()
        return
    end
    
    -- Recopilar muestras de ruido de fondo
    local volume = getCore():getMicVolumeIndicator()
    table.insert(AutoCalibration.calibrationSamples, volume)
end

function AutoCalibration.finishCalibration()
    AutoCalibration.isCalibrating = false
    
    if #AutoCalibration.calibrationSamples == 0 then return end
    
    -- Calcular umbral de ruido basado en muestras
    table.sort(AutoCalibration.calibrationSamples)
    local percentile95 = AutoCalibration.calibrationSamples[math.floor(#AutoCalibration.calibrationSamples * 0.95)]
    
    -- Establecer umbral ligeramente por encima del ruido de fondo
    AudioFilters.noiseThreshold = percentile95 * 1.2
    
    getPlayer():Say("Calibration complete. Noise threshold set to " .. string.format("%.2f", AudioFilters.noiseThreshold))
end
```

---

## 6. INTEGRACIÓN CON SISTEMA DE ZOMBIES

### 6.1 Propagación de Sonido Realista
```lua
local SoundPropagation = {}

function SoundPropagation.calculateSoundRadius(volume, playerObj)
    local baseRadius = volume
    local environment = SoundPropagation.analyzeEnvironment(playerObj)
    
    -- Factores ambientales
    local outdoorMult = environment.isOutdoor and 1.2 or 0.8
    local windMult = environment.windSpeed * 0.1 + 1.0
    local rainMult = environment.isRaining and 0.7 or 1.0
    
    local finalRadius = baseRadius * outdoorMult * windMult * rainMult
    
    return math.max(1, finalRadius)
end

function SoundPropagation.analyzeEnvironment(playerObj)
    local square = playerObj:getSquare()
    local room = square and square:getRoom()
    
    return {
        isOutdoor = room == nil,
        windSpeed = getClimateManager():getWindspeedKph(),
        isRaining = RainManager.isRaining(),
        roomSize = room and (room:getW() * room:getH()) or 0
    }
end

function SoundPropagation.createAdvancedWorldSound(playerObj, volume)
    local radius = SoundPropagation.calculateSoundRadius(volume, playerObj)
    
    -- Crear sonido con propiedades avanzadas
    local worldSound = WorldSoundManager.instance:addSound(
        playerObj,                    # Fuente
        playerObj:getX(),            # X
        playerObj:getY(),            # Y
        playerObj:getZ(),            # Z
        radius,                      # Radio
        volume,                      # Volumen
        false,                       # No es zombie
        false,                       # No es vehículo
        false,                       # No es disparo
        true,                        # Es voz
        30                          # Duración en ticks
    )
    
    return worldSound
end
```

### 6.2 Sistema de Atención de Zombies
```lua
local ZombieAttention = {}

function ZombieAttention.attractZombies(worldSound)
    local soundX = worldSound:getX()
    local soundY = worldSound:getY()
    local soundZ = worldSound:getZ()
    local radius = worldSound:getRadius()
    
    -- Buscar zombies en el área
    local nearbyZombies = getZombiesInRadius(soundX, soundY, soundZ, radius * 1.5)
    
    for _, zombie in ipairs(nearbyZombies) do
        local distance = zombie:DistTo(soundX, soundY)
        local attractionStrength = math.max(0, 1 - (distance / radius))
        
        if attractionStrength > 0.1 then
            ZombieAttention.attractZombie(zombie, soundX, soundY, attractionStrength)
        end
    end
end

function ZombieAttention.attractZombie(zombie, soundX, soundY, strength)
    -- Hacer que el zombie mire hacia el sonido
    zombie:faceLocation(soundX, soundY)
    
    -- Aumentar nivel de alerta
    zombie:setAlerted(true)
    
    -- Si está lo suficientemente cerca, hacer que investigue
    if strength > 0.5 then
        zombie:pathToLocation(soundX, soundY, zombie:getZ())
    end
    
    -- Efecto visual de atención
    if strength > 0.7 then
        zombie:playEmote("exclamation")
    end
end
```

---

## 7. SISTEMA DE DEBUGGING Y MONITOREO

### 7.1 Panel de Debug en Tiempo Real
```lua
local DebugPanel = {}

function DebugPanel.init()
    if not SandboxVars.ZombiesHearYourMicrophone.debugMode then return end
    
    DebugPanel.window = ISPanel:new(10, 10, 300, 200)
    DebugPanel.window:initialise()
    DebugPanel.window:addToUIManager()
    DebugPanel.window.backgroundColor = {r=0, g=0, b=0, a=0.8}
end

function DebugPanel.update()
    if not DebugPanel.window then return end
    
    local core = getCore()
    local player = getPlayer()
    
    DebugPanel.data = {
        rawVolume = core:getMicVolumeIndicator(),
        processedVolume = AudioFilters.previousVolume,
        noiseThreshold = AudioFilters.noiseThreshold,
        isVOIPEnabled = core:getOptionVoiceEnable(),
        isPTTActive = GameKeyboard.isKeyDown(core:getKey("Enable voice transmit")),
        playerSneaking = player:isSneaking(),
        nearbyZombies = #getZombiesInRadius(player:getX(), player:getY(), player:getZ(), 20)
    }
end

function DebugPanel.render()
    if not DebugPanel.window or not DebugPanel.data then return end
    
    local y = 30
    local lineHeight = 15
    
    DebugPanel.window:drawText("=== MICROPHONE DEBUG ===", 10, 10, 1, 1, 1, 1, UIFont.Small)
    
    for key, value in pairs(DebugPanel.data) do
        local text = key .. ": " .. tostring(value)
        DebugPanel.window:drawText(text, 10, y, 1, 1, 1, 1, UIFont.Small)
        y = y + lineHeight
    end
end
```

---

## 8. PATRONES PARA IA - GENERACIÓN AUTOMÁTICA

### 8.1 Template de Sistema de Micrófono
```lua
function generateMicrophoneSystem(modName, features)
    local template = [[
local ]] .. modName .. [[Mic = {}

function ]] .. modName .. [[Mic.onPlayerUpdate(player)
    if player:isDead() or player:isAsleep() then return end
    
    getCore():setTestingMicrophone(true)
    
    local volume = getCore():getMicVolumeIndicator()
    local factor = ]] .. (features.baseFactor or 1.0) .. [[
    
]]

    if features.traitInfluence then
        template = template .. [[
    -- Aplicar influencia de traits
    if player:HasTrait("Conspicuous") then factor = factor * 1.2 end
    if player:HasTrait("Graceful") then factor = factor * 0.8 end
]]
    end

    if features.skillInfluence then
        template = template .. [[
    -- Aplicar influencia de habilidades
    local sneakLevel = player:getPerkLevel(Perks.Sneak)
    factor = factor * (1.0 - sneakLevel * 0.05)
]]
    end

    template = template .. [[
    
    local finalVolume = math.min(10, volume * factor)
    AddWorldSound(player, finalVolume, finalVolume)
end

Events.OnPlayerUpdate.Add(]] .. modName .. [[Mic.onPlayerUpdate)
]]

    return template
end
```

### 8.2 Casos de Uso para IA
```
"Crea sistema de micrófono que detecte susurros"
→ Umbral de ruido muy bajo, amplificación alta

"Genera detección de micrófono solo para gritos"
→ Umbral alto, sin amplificación de susurros

"Diseña sistema que ignore ruido de fondo"
→ Calibración automática, filtros de ruido

"Crea feedback visual con colores de peligro"
→ Sistema de colores dinámicos basado en volumen
```

---

*Esta documentación proporciona un sistema completo para implementar detección de micrófono en Project Zomboid, incluyendo procesamiento de audio, filtros, calibración automática y integración con el sistema de zombies.*
