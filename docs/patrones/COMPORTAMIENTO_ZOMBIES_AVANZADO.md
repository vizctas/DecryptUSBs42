# COMPORTAMIENTO DE ZOMBIES - SISTEMA AVANZADO

## ANÁLISIS EXHAUSTIVO DE MECÁNICAS DE ZOMBIES

*Basado en análisis de Starving Zombies - Sistemas de olfato, detección y comportamiento*

---

## 1. ARQUITECTURA DE COMPORTAMIENTO DE ZOMBIES

### 1.1 Sistemas Principales de Detección
```
SISTEMAS DE DETECCIÓN:
├── Visual Detection        # Sistema de vista (línea de visión)
├── Audio Detection        # Sistema de sonido (pasos, ruidos)
├── Smell Detection        # Sistema de olfato (cuerpos, comida)
├── Movement Patterns      # Patrones de movimiento (wandering, chase)
└── State Management       # Estados (idle, alert, chase, attack)
```

### 1.2 Jerarquía de Archivos de Comportamiento
```
ZombieMod/
├── media/lua/shared/
│   ├── ModName_Bodies.lua              # Detección de cuerpos
│   ├── ModName_SmellFuncs.lua          # Funciones de olfato
│   ├── ModName_Vector.lua              # Matemáticas vectoriales
│   └── ModName_ZombieAI.lua            # IA principal
├── media/lua/client/
│   ├── ModName_ZombieUpdate.lua        # Actualización lado cliente
│   └── ModName_ZombieEffects.lua       # Efectos visuales
└── sandbox-options.txt                  # Configuraciones
```

---

## 2. SISTEMA DE OLFATO AVANZADO

### 2.1 Clase Vector para Cálculos Espaciales
```lua
-- Sistema vectorial para cálculos de distancia y dirección
SZVector = {}
SZVector.__index = SZVector

function SZVector:new(x, y, z)
    local obj = {
        x = x or 0,
        y = y or 0,
        z = z or 0
    }
    setmetatable(obj, SZVector)
    return obj
end

function SZVector:sub(other)
    return SZVector:new(self.x - other.x, self.y - other.y, self.z - other.z)
end

function SZVector:mag()
    return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
end

function SZVector:normalise()
    local magnitude = self:mag()
    if magnitude > 0 then
        self.x = self.x / magnitude
        self.y = self.y / magnitude
        self.z = self.z / magnitude
    end
end

function SZVector:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end
```

### 2.2 Sistema de Detección de Cuerpos Muertos
```lua
-- Acceso a propiedades privadas del engine usando reflection
local deathIdx

---@param isoDeadBody zombie.iso.objects.IsoDeadBody
---@return number
local function getDeathTime(isoDeadBody)
    if deathIdx == nil then
        -- Buscar el índice del campo deathTime usando reflection
        for i = 0, getNumClassFields(isoDeadBody) - 1 do
            local fieldName = tostring(getClassField(isoDeadBody, i))
            if fieldName == "private float zombie.iso.objects.IsoDeadBody.deathTime" then
                deathIdx = i
                break
            end
        end

        if deathIdx == nil then
            getPlayer():addLineChatElement("Starving Zombies: failed to get deathIdx")
            return getGameTime():getWorldAgeHours()
        end
    end

    return getClassFieldVal(isoDeadBody, getClassField(isoDeadBody, deathIdx))
end
```

### 2.3 Función Principal de Detección de Olor
```lua
local szVars
local climateMan
local objVec = SZVector:new()
local charVec = SZVector:new()
local charDir
local charDist
local smellDist

---@param isoZombie zombie.characters.IsoZombie
---@param isoObject zombie.iso.IsoObject
local function initSmellVars(isoZombie, isoObject)
    charVec.x = isoZombie:getX()
    charVec.y = isoZombie:getY()
    charVec.z = isoZombie:getZ()
    objVec.x = isoObject:getX()
    objVec.y = isoObject:getY()
    objVec.z = isoObject:getZ()
    charDir = charVec:sub(objVec)
    charDist = charDir:mag()
    charDir:normalise()
end

---@param maxDistance integer
---@param windSpeedMult number
---@param dispersionAngle integer
---@param bodySizeMult number?
---@return boolean
local function canSmell(maxDistance, windSpeedMult, dispersionAngle, bodySizeMult)
    if not climateMan then climateMan = getClimateManager() end
    if charDist > maxDistance then return false end
    if charDist <= smellDist then return true end

    -- El viento afecta la propagación del olor
    smellDist = smellDist + climateMan:getWindspeedKph() * windSpeedMult
    if bodySizeMult ~= nil then smellDist = smellDist * bodySizeMult end
    if charDist > smellDist then return false end

    -- Verificar dirección del viento
    if dispersionAngle > 0 then
        local windRads = climateMan:getWindAngleRadians()
        local windDir = SZVector:new()
        windDir.x = math.cos(windRads)
        windDir.y = math.sin(windRads)
        if charDir:dot(windDir) >= 1 - dispersionAngle / 90.0 then return true end
        return false
    end

    return true
end
```

### 2.4 Detección Específica de Cuerpos
```lua
---@param isoZombie zombie.characters.IsoZombie
---@param isoDeadBody zombie.iso.objects.IsoDeadBody
---@return boolean
function szCanSmellBody(isoZombie, isoDeadBody)
    if not szVars then szVars = SandboxVars.StarvingZombies end
    if not gameTime then gameTime = getGameTime() end
    if not climateMan then climateMan = getClimateManager() end

    -- Verificación de interiores
    if szVars.BodyIndoorCheck then
        bodySquare = isoDeadBody:getSquare()
        zombieSquare = isoZombie:getSquare()
        
        if bodySquare and zombieSquare then
            local bodyIndoor = bodySquare:getRoom() ~= nil
            local zombieIndoor = zombieSquare:getRoom() ~= nil
            
            -- Si el cuerpo está dentro y el zombie fuera (o viceversa), reducir detección
            if bodyIndoor ~= zombieIndoor then
                return false
            end
        end
    end

    -- Inicializar variables de distancia y dirección
    initSmellVars(isoZombie, isoDeadBody)
    
    -- Calcular tiempo desde la muerte
    local deathTime = getDeathTime(isoDeadBody)
    local currentTime = gameTime:getWorldAgeHours()
    local timeSinceDeath = currentTime - deathTime
    
    -- El olor se intensifica con el tiempo hasta un máximo
    local smellIntensity = math.min(1.0, timeSinceDeath / szVars.BodySmellPeakHours)
    
    -- Verificar si puede oler basado en distancia, viento y tiempo
    local maxDistance = szVars.BodySmellMaxDistance * smellIntensity
    local windMult = szVars.BodyWindMultiplier
    local dispersion = szVars.BodyDispersionAngle
    
    return canSmell(maxDistance, windMult, dispersion, 1.0)
end
```

---

## 3. SISTEMA DE ESTADOS DE ZOMBIE

### 3.1 Enumeración de Estados
```lua
local ZombieState = {
    WANDERING = 1,      # Vagando sin objetivo
    INVESTIGATING = 2,  # Investigando sonido/olor
    CHASING = 3,        # Persiguiendo objetivo
    ATTACKING = 4,      # Atacando
    FEEDING = 5,        # Alimentándose de cuerpo
    STUNNED = 6,        # Aturdido por golpe
    DEAD = 7           # Muerto
}

local ZombieMemory = {}  -- Tabla para almacenar memoria de zombies

function getZombieState(zombie)
    local zombieId = zombie:getOnlineID()
    return ZombieMemory[zombieId] and ZombieMemory[zombieId].state or ZombieState.WANDERING
end

function setZombieState(zombie, newState)
    local zombieId = zombie:getOnlineID()
    if not ZombieMemory[zombieId] then
        ZombieMemory[zombieId] = {}
    end
    ZombieMemory[zombieId].state = newState
    ZombieMemory[zombieId].stateTime = getGameTime():getWorldAgeHours()
end
```

### 3.2 Máquina de Estados Principal
```lua
function updateZombieAI(zombie)
    if zombie:isDead() then return end
    
    local currentState = getZombieState(zombie)
    local newState = currentState
    
    -- Verificar condiciones para cambio de estado
    local player = zombie:getTarget()
    local canSeePlayer = player and zombie:CanSee(player)
    local canHearPlayer = checkAudioDetection(zombie, player)
    local smellsCorpse = checkCorpseSmell(zombie)
    
    -- Lógica de transición de estados
    if currentState == ZombieState.WANDERING then
        if canSeePlayer or canHearPlayer then
            newState = ZombieState.CHASING
            zombie:setTarget(player)
        elseif smellsCorpse then
            newState = ZombieState.INVESTIGATING
            setZombieInvestigationTarget(zombie, smellsCorpse)
        end
        
    elseif currentState == ZombieState.INVESTIGATING then
        if canSeePlayer then
            newState = ZombieState.CHASING
            zombie:setTarget(player)
        elseif hasReachedInvestigationTarget(zombie) then
            local corpse = getZombieInvestigationTarget(zombie)
            if corpse and not corpse:isDestroyed() then
                newState = ZombieState.FEEDING
            else
                newState = ZombieState.WANDERING
            end
        end
        
    elseif currentState == ZombieState.CHASING then
        if not player or zombie:DistTo(player) > 20 then
            newState = ZombieState.WANDERING
        elseif zombie:DistTo(player) < 1.5 then
            newState = ZombieState.ATTACKING
        end
        
    elseif currentState == ZombieState.ATTACKING then
        if not player or zombie:DistTo(player) > 2.0 then
            newState = ZombieState.CHASING
        end
        
    elseif currentState == ZombieState.FEEDING then
        if canSeePlayer then
            newState = ZombieState.CHASING
            zombie:setTarget(player)
        elseif getFeedingTime(zombie) > SandboxVars.StarvingZombies.FeedingDuration then
            newState = ZombieState.WANDERING
        end
    end
    
    -- Aplicar nuevo estado si cambió
    if newState ~= currentState then
        setZombieState(zombie, newState)
        onZombieStateChange(zombie, currentState, newState)
    end
    
    -- Ejecutar comportamiento del estado actual
    executeStateLogic(zombie, newState)
end
```

### 3.3 Comportamientos Específicos por Estado
```lua
function executeStateLogic(zombie, state)
    if state == ZombieState.WANDERING then
        executeWanderingBehavior(zombie)
    elseif state == ZombieState.INVESTIGATING then
        executeInvestigatingBehavior(zombie)
    elseif state == ZombieState.CHASING then
        executeChasingBehavior(zombie)
    elseif state == ZombieState.FEEDING then
        executeFeedingBehavior(zombie)
    end
end

function executeWanderingBehavior(zombie)
    -- Movimiento aleatorio lento
    if ZombRand(100) < 5 then  -- 5% probabilidad cada update
        local angle = ZombRand(360) * math.pi / 180
        local distance = ZombRand(3, 8)
        local targetX = zombie:getX() + math.cos(angle) * distance
        local targetY = zombie:getY() + math.sin(angle) * distance
        
        zombie:pathToLocation(targetX, targetY, zombie:getZ())
    end
end

function executeInvestigatingBehavior(zombie)
    local target = getZombieInvestigationTarget(zombie)
    if target then
        zombie:pathToLocation(target:getX(), target:getY(), target:getZ())
        
        -- Reducir velocidad al investigar
        zombie:setRunning(false)
        zombie:setSneaking(true)
    end
end

function executeFeedingBehavior(zombie)
    local corpse = getZombieInvestigationTarget(zombie)
    if corpse then
        -- Animación de alimentación
        zombie:faceLocation(corpse:getX(), corpse:getY())
        zombie:setVariable("ZombieState", "eating")
        
        -- Efectos de sonido
        if ZombRand(100) < 10 then
            zombie:playSound("ZombieEating")
        end
        
        -- Curar zombie mientras se alimenta
        if SandboxVars.StarvingZombies.FeedingHeals then
            local health = zombie:getHealth()
            zombie:setHealth(math.min(1.0, health + 0.001))
        end
    end
end
```

---

## 4. SISTEMA DE DETECCIÓN DE SONIDO AVANZADO

### 4.1 Análisis de Sonidos del Entorno
```lua
local SoundDetection = {}

function SoundDetection.analyzeSound(zombie, soundSource, volume, distance)
    -- Factores que afectan la detección de sonido
    local hearingMult = SandboxVars.StarvingZombies.HearingMultiplier or 1.0
    local maxHearingDistance = SandboxVars.StarvingZombies.MaxHearingDistance or 20
    
    -- Reducir volumen por distancia
    local effectiveVolume = volume * (1 - (distance / maxHearingDistance))
    effectiveVolume = effectiveVolume * hearingMult
    
    -- Verificar obstáculos (paredes, puertas)
    local obstacleReduction = calculateObstacleReduction(zombie, soundSource)
    effectiveVolume = effectiveVolume * obstacleReduction
    
    -- Diferentes tipos de sonido tienen diferentes prioridades
    local soundType = getSoundType(soundSource)
    local priorityMult = getSoundPriorityMultiplier(soundType)
    effectiveVolume = effectiveVolume * priorityMult
    
    return effectiveVolume > SandboxVars.StarvingZombies.MinSoundThreshold
end

function getSoundType(soundSource)
    local soundTypes = {
        footstep = 1.0,
        gunshot = 3.0,
        explosion = 5.0,
        vehicle = 2.0,
        breaking = 1.5,
        voice = 2.5
    }
    
    -- Determinar tipo basado en el objeto fuente
    if instanceof(soundSource, "IsoPlayer") then
        return "footstep"
    elseif instanceof(soundSource, "BaseVehicle") then
        return "vehicle"
    else
        return "breaking"  -- Sonido genérico
    end
end

function calculateObstacleReduction(zombie, soundSource)
    local zombieSquare = zombie:getSquare()
    local sourceSquare = soundSource:getSquare()
    
    if not zombieSquare or not sourceSquare then return 1.0 end
    
    -- Verificar si están en la misma habitación
    local zombieRoom = zombieSquare:getRoom()
    local sourceRoom = sourceSquare:getRoom()
    
    if zombieRoom and sourceRoom then
        if zombieRoom == sourceRoom then
            return 1.0  -- Misma habitación, sin reducción
        else
            return 0.3  -- Diferentes habitaciones, reducción significativa
        end
    elseif zombieRoom or sourceRoom then
        return 0.6  -- Uno dentro, otro fuera
    else
        return 1.0  -- Ambos fuera, sin reducción
    end
end
```

### 4.2 Sistema de Memoria Auditiva
```lua
local AudioMemory = {}

function AudioMemory.addSoundMemory(zombie, soundLocation, volume, timestamp)
    local zombieId = zombie:getOnlineID()
    if not AudioMemory[zombieId] then
        AudioMemory[zombieId] = {}
    end
    
    table.insert(AudioMemory[zombieId], {
        x = soundLocation.x,
        y = soundLocation.y,
        z = soundLocation.z,
        volume = volume,
        timestamp = timestamp,
        investigated = false
    })
    
    -- Mantener solo los últimos 5 sonidos
    if #AudioMemory[zombieId] > 5 then
        table.remove(AudioMemory[zombieId], 1)
    end
end

function AudioMemory.getNextSoundToInvestigate(zombie)
    local zombieId = zombie:getOnlineID()
    local memories = AudioMemory[zombieId]
    
    if not memories then return nil end
    
    -- Buscar el sonido más fuerte no investigado
    local bestSound = nil
    local bestVolume = 0
    
    for _, memory in ipairs(memories) do
        if not memory.investigated and memory.volume > bestVolume then
            bestSound = memory
            bestVolume = memory.volume
        end
    end
    
    if bestSound then
        bestSound.investigated = true
        return {x = bestSound.x, y = bestSound.y, z = bestSound.z}
    end
    
    return nil
end
```

---

## 5. SISTEMA DE HAMBRE Y NECESIDADES

### 5.1 Estado de Hambre del Zombie
```lua
local ZombieHunger = {}

function ZombieHunger.initializeHunger(zombie)
    local zombieId = zombie:getOnlineID()
    if not ZombieMemory[zombieId] then
        ZombieMemory[zombieId] = {}
    end
    
    ZombieMemory[zombieId].hunger = ZombRand(20, 80)  -- Hambre inicial aleatoria
    ZombieMemory[zombieId].lastFed = getGameTime():getWorldAgeHours()
end

function ZombieHunger.updateHunger(zombie)
    local zombieId = zombie:getOnlineID()
    local memory = ZombieMemory[zombieId]
    
    if not memory then
        ZombieHunger.initializeHunger(zombie)
        memory = ZombieMemory[zombieId]
    end
    
    local currentTime = getGameTime():getWorldAgeHours()
    local timeSinceLastFed = currentTime - memory.lastFed
    
    -- Aumentar hambre con el tiempo
    local hungerRate = SandboxVars.StarvingZombies.HungerRate or 1.0
    memory.hunger = memory.hunger + (timeSinceLastFed * hungerRate)
    memory.hunger = math.min(100, memory.hunger)
    
    -- Efectos del hambre en el comportamiento
    if memory.hunger > 80 then
        -- Zombie muy hambriento: más agresivo, mejor detección de olor
        zombie:setAggressive(true)
        return 1.5  -- Multiplicador de detección de olor
    elseif memory.hunger > 50 then
        return 1.2
    else
        return 1.0
    end
end

function ZombieHunger.feedZombie(zombie, corpse)
    local zombieId = zombie:getOnlineID()
    local memory = ZombieMemory[zombieId]
    
    if memory then
        memory.hunger = math.max(0, memory.hunger - 30)
        memory.lastFed = getGameTime():getWorldAgeHours()
        
        -- Efectos de alimentación
        if SandboxVars.StarvingZombies.FeedingHeals then
            zombie:setHealth(math.min(1.0, zombie:getHealth() + 0.1))
        end
        
        -- Sonido de alimentación
        zombie:playSound("ZombieEating" .. ZombRand(1, 4))
    end
end
```

---

## 6. INTEGRACIÓN CON EVENTOS DEL JUEGO

### 6.1 Registro de Eventos Principales
```lua
-- Actualización principal de zombies
Events.OnZombieUpdate.Add(function(zombie)
    if not zombie or zombie:isDead() then return end
    
    -- Actualizar hambre
    local hungerMult = ZombieHunger.updateHunger(zombie)
    
    -- Actualizar IA
    updateZombieAI(zombie)
    
    -- Verificar detección de olores con multiplicador de hambre
    checkSmellDetection(zombie, hungerMult)
end)

-- Cuando un zombie muere
Events.OnZombieDead.Add(function(zombie)
    local zombieId = zombie:getOnlineID()
    if ZombieMemory[zombieId] then
        ZombieMemory[zombieId] = nil  -- Limpiar memoria
    end
end)

-- Cuando se crea un zombie
Events.OnCreateLivingCharacter.Add(function(character)
    if instanceof(character, "IsoZombie") then
        ZombieHunger.initializeHunger(character)
        setZombieState(character, ZombieState.WANDERING)
    end
end)

-- Detección de sonidos del mundo
Events.OnWorldSound.Add(function(worldSound)
    local soundX = worldSound:getX()
    local soundY = worldSound:getY()
    local soundZ = worldSound:getZ()
    local volume = worldSound:getVolume()
    
    -- Notificar a zombies cercanos
    local nearbyZombies = getZombiesInRadius(soundX, soundY, soundZ, 30)
    for _, zombie in ipairs(nearbyZombies) do
        if SoundDetection.analyzeSound(zombie, worldSound, volume, zombie:DistTo(soundX, soundY)) then
            AudioMemory.addSoundMemory(zombie, {x=soundX, y=soundY, z=soundZ}, volume, getGameTime():getWorldAgeHours())
        end
    end
end)
```

---

## 7. CONFIGURACIÓN AVANZADA SANDBOX

### 7.1 Opciones de Configuración Completas
```
option StarvingZombies.HungerRate
{
    type = double,
    min = 0.1,
    max = 5.0,
    default = 1.0,
    page = StarvingZombies,
    translation = StarvingZombies_HungerRate,
}

option StarvingZombies.BodySmellMaxDistance
{
    type = integer,
    min = 5,
    max = 50,
    default = 15,
    page = StarvingZombies,
    translation = StarvingZombies_BodySmellMaxDistance,
}

option StarvingZombies.FeedingHeals
{
    type = boolean,
    default = true,
    page = StarvingZombies,
    translation = StarvingZombies_FeedingHeals,
}

option StarvingZombies.HearingMultiplier
{
    type = double,
    min = 0.1,
    max = 3.0,
    default = 1.0,
    page = StarvingZombies,
    translation = StarvingZombies_HearingMultiplier,
}
```

---

## 8. PATRONES PARA IA - COMPORTAMIENTO AUTOMÁTICO

### 8.1 Generación de Comportamiento Personalizado
```lua
-- Template para IA generar comportamiento de zombie
function generateZombieBehavior(behaviorName, triggers, actions, conditions)
    local template = [[
local ]] .. behaviorName .. [[Behavior = {}

function ]] .. behaviorName .. [[Behavior.shouldActivate(zombie)
]]
    
    for _, condition in ipairs(conditions) do
        template = template .. '    if not (' .. condition .. ') then return false end\n'
    end
    
    template = template .. [[
    return true
end

function ]] .. behaviorName .. [[Behavior.execute(zombie)
]]
    
    for _, action in ipairs(actions) do
        template = template .. '    ' .. action .. '\n'
    end
    
    template = template .. [[
end

-- Registrar comportamiento
Events.OnZombieUpdate.Add(function(zombie)
    if ]] .. behaviorName .. [[Behavior.shouldActivate(zombie) then
        ]] .. behaviorName .. [[Behavior.execute(zombie)
    end
end)
]]
    
    return template
end
```

### 8.2 Casos de Uso para IA
```
"Crea zombies que se vuelvan más rápidos cuando huelen sangre"
→ Detectar sangre en área, aumentar velocidad temporalmente

"Genera zombies que trabajen en grupo para romper puertas"
→ Detectar zombies cercanos, coordinar ataques a estructuras

"Diseña zombies que eviten el fuego pero persigan más agresivamente"
→ Lógica de evasión de fuego + aumento de agresividad

"Crea zombies nocturnos con mejor visión en la oscuridad"
→ Modificar detección visual basada en hora del día
```

---

*Esta documentación proporciona un sistema completo para crear comportamientos avanzados de zombies, incluyendo detección de olores, estados de IA, memoria auditiva y sistemas de hambre.*
