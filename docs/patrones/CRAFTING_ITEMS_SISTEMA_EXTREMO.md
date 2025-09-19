# SISTEMA DE CRAFTING AVANZADO - PROJECT ZOMBOID

> **DOCUMENTACIÓN TÉCNICA PARA MODDING AVANZADO**  
> Referencia completa para crear items con propiedades especiales, sonidos personalizados y efectos únicos

---

## ÍNDICE
1. [Estructura Base de Items](#1-estructura-base-de-items)
2. [Sistema de Sonidos Personalizados](#2-sistema-de-sonidos-personalizados)
3. [Propiedades Especiales de Armas](#3-propiedades-especiales-de-armas)
4. [Efectos Eléctricos y Especiales](#4-efectos-eléctricos-y-especiales)
5. [Sistema de Context Menus](#5-sistema-de-context-menus)
6. [Recipes OnCreate Avanzados](#6-recipes-oncreate-avanzados)
7. [Armas con Efectos Únicos](#7-armas-con-efectos-únicos)
8. [Ejemplos Prácticos](#8-ejemplos-prácticos)

---

## 1. ESTRUCTURA BASE DE ITEMS

### 1.1 Template Base para Item con Propiedades Especiales
```text
module ModuleName
{
    item ItemName
    {
        # Propiedades básicas
        Type = Weapon,                      # Weapon/Food/Normal/Drainable
        DisplayName = Item Display Name,
        DisplayCategory = Category,
        Icon = ModName_ItemIcon,
        Weight = 1.5,
        
        # Modelo 3D y visuales
        WorldStaticModel = ModName_ItemModel,
        StaticModel = ModName_ItemBackpackModel,
        WeaponSprite = ModName_ItemSprite,
        
        # Propiedades de contexto
        CustomContextMenu = SpecialAction,
        CustomEatSound = SpecialSound,
        OnEat = OnEat_SpecialFunction,
        OnCreate = OnCreate_SpecialFunction,
        
        # Tags de comportamiento
        Tags = Special;Electric;Custom,
        
        # Tooltips y ayuda
        Tooltip = Tooltip_SpecialItem,
    }
}
```

### 1.2 Sistema de Propiedades Dinámicas
```lua
-- Script: ModName_ItemProperties.lua
local ItemProperties = {}

-- Configurar propiedades especiales para un item
function ItemProperties.setSpecialProperties(item, properties)
    if not item or not properties then return end
    
    local modData = item:getModData()
    
    -- Propiedades eléctricas
    if properties.electric then
        modData.ElectricDamage = properties.electric.damage or 1.5
        modData.ElectricChance = properties.electric.chance or 0.3
        modData.ElectricSound = properties.electric.sound or "Thunder"
        modData.ElectricEffect = properties.electric.effect or "lightning"
    end
    
    -- Propiedades de sonido
    if properties.sound then
        modData.HitSound = properties.sound.hit
        modData.SwingSound = properties.sound.swing
        modData.SpecialSound = properties.sound.special
    end
    
    -- Efectos visuales
    if properties.visual then
        modData.HitEffect = properties.visual.hit
        modData.SwingEffect = properties.visual.swing
        modData.SpecialEffect = properties.visual.special
    end
end

-- Aplicar efectos especiales al golpear
function ItemProperties.onSpecialHit(attacker, victim, weapon, damage)
    local modData = weapon:getModData()
    
    -- Efecto eléctrico
    if modData.ElectricDamage and ZombRand(100) < (modData.ElectricChance * 100) then
        -- Daño eléctrico adicional
        victim:getBodyDamage():AddDamage(BodyPartType.Torso, modData.ElectricDamage)
        
        -- Sonido de rayo
        if modData.ElectricSound then
            getSoundManager():PlaySound(modData.ElectricSound, false, 2.0)
            addSound(victim, victim:getX(), victim:getY(), victim:getZ(), 20, 15)
        end
        
        -- Efecto visual de electricidad
        if modData.ElectricEffect then
            getCell():addEffect(victim:getX(), victim:getY(), victim:getZ(), modData.ElectricEffect)
        end
        
        -- Stun temporal
        if victim:isZombie() then
            victim:setStun(true, ZombRand(30, 60))
        end
    end
end

-- Registrar eventos
Events.OnWeaponHitCharacter.Add(ItemProperties.onSpecialHit)
```

---

## 2. SISTEMA DE SONIDOS PERSONALIZADOS

### 2.1 Configuración de Audio para Items
```lua
-- Script: ModName_SoundSystem.lua
local SoundSystem = {}

-- Configuración de sonidos por tipo de item
local soundConfig = {
    ["ModName.ElectricBat"] = {
        hitSound = "Thunder",
        swingSound = "ElectricHum", 
        specialSound = "Lightning",
        volume = 2.0,
        range = 25,
        is3D = true,
    },
    ["ModName.FireSword"] = {
        hitSound = "FireBurst",
        swingSound = "FlameWoosh",
        specialSound = "Inferno",
        volume = 1.8,
        range = 20,
        is3D = true,
    },
}

-- Reproducir sonido personalizado
function SoundSystem.playCustomSound(item, soundType, player)
    local itemType = item:getFullType()
    local config = soundConfig[itemType]
    
    if config and config[soundType] then
        local sound = config[soundType]
        
        -- Reproducir sonido principal
        getSoundManager():PlaySound(sound, false, config.volume)
        
        -- Agregar sonido para IA de zombies
        if player then
            addSound(player, player:getX(), player:getY(), player:getZ(), 
                    config.range, config.volume * 10)
        end
    end
end

-- Hook para sonidos de swing
Events.OnWeaponSwing.Add(function(player, weapon)
    SoundSystem.playCustomSound(weapon, "swingSound", player)
end)

-- Hook para sonidos de hit
Events.OnWeaponHitCharacter.Add(function(attacker, victim, weapon, damage)
    SoundSystem.playCustomSound(weapon, "hitSound", attacker)
end)
```

### 2.2 Sistema CustomEatSound (para items consumibles)
```text
# En definición de item
item CustomSoundItem
{
    Type = Food,
    CustomEatSound = CustomSound,       # Sonido personalizado al usar
    OnEat = OnEat_CustomFunction,       # Función al consumir
    EatType = special,                  # Tipo de consumo especial
    
    # Configuración de sonido
    SoundVolume = 1.5,                  # Volumen del sonido
    SoundRange = 15,                    # Rango del sonido para zombies
}
```

---

## 3. PROPIEDADES ESPECIALES DE ARMAS

### 3.1 Arma Eléctrica Base
```text
item ModName_ElectricBat
{
    # Propiedades básicas de arma
    Type = Weapon,
    DisplayName = Electric Bat,
    DisplayCategory = Weapon,
    Icon = ModName_ElectricBat,
    Weight = 3.0,
    
    # Propiedades de combate
    MinDamage = 1.8,
    MaxDamage = 3.2,
    MinRange = 0.61,
    MaxRange = 1.5,
    WeaponSprite = ModName_ElectricBatSprite,
    
    # Efectos especiales
    SpecialEffect = lightning,          # Efecto eléctrico
    ElectricDamage = 2.0,              # Daño eléctrico adicional
    ElectricChance = 30,               # 30% probabilidad de efecto
    
    # Sonidos personalizados
    SwingSound = ElectricHum,          # Sonido al swing
    HitSound = Thunder,                # Sonido al golpear
    SpecialHitSound = Lightning,       # Sonido del efecto eléctrico
    
    # Propiedades físicas
    ConditionMax = 20,
    ConditionLowerChanceOneIn = 15,
    WeaponWeight = 3.0,
    
    # Animación y timing
    SwingAnim = Bat,
    SwingAmountBeforeImpact = 0.02,
    MinimumSwingTime = 4,
    
    # Efectos de combate
    CriticalChance = 20,
    CritDmgMultiplier = 2.5,
    KnockdownMod = 1.5,
    PushBackMod = 0.8,
    
    # Categorización
    Categories = Weapon;Blunt;Electric,
    SubCategory = Bat,
    
    # Modelos y sprites
    WorldStaticModel = ModName_ElectricBat,
    StaticModel = ModName_ElectricBatBackpack,
    
    # Tags especiales
    Tags = Electric;Special;Lightning;Weapon,
    
    # Tooltip explicativo
    Tooltip = Tooltip_ElectricBat,
}
```

### 3.2 Script de Efectos Eléctricos
```lua
-- Script: ModName_ElectricWeapons.lua
local ElectricWeapons = {}

-- Configuración de efectos eléctricos
local electricConfig = {
    ["ModName.ElectricBat"] = {
        damage = 2.0,
        chance = 0.3,
        stunDuration = {30, 60},
        sound = "Thunder",
        effect = "Lightning",
        range = 3,              -- Radio de efecto de área
        chainLightning = true,  -- Puede saltar a otros zombies
    },
}

-- Aplicar efecto eléctrico
function ElectricWeapons.applyElectricEffect(attacker, victim, weapon)
    local weaponType = weapon:getFullType()
    local config = electricConfig[weaponType]
    
    if not config then return end
    
    -- Verificar probabilidad
    if ZombRand(100) >= (config.chance * 100) then return end
    
    -- Aplicar daño eléctrico
    victim:getBodyDamage():AddDamage(BodyPartType.Torso, config.damage)
    
    -- Reproducir sonido de rayo
    getSoundManager():PlaySound(config.sound, false, 2.0)
    addSound(victim, victim:getX(), victim:getY(), victim:getZ(), 25, 20)
    
    -- Efecto de stun
    if victim:isZombie() then
        local stunTime = ZombRand(config.stunDuration[1], config.stunDuration[2])
        victim:setStun(true, stunTime)
    end
    
    -- Chain lightning (opcional)
    if config.chainLightning then
        ElectricWeapons.chainLightningEffect(victim, config)
    end
    
    -- Efecto visual
    if config.effect then
        getCell():addLightSource(victim:getX(), victim:getY(), victim:getZ(), 
                               5, 0.8, 0.8, 1.0, 10) -- Luz azul temporal
    end
end

-- Efecto de rayo en cadena
function ElectricWeapons.chainLightningEffect(source, config)
    local x, y, z = source:getX(), source:getY(), source:getZ()
    local cell = getCell()
    
    -- Buscar zombies cercanos
    local nearbyZombies = {}
    for dx = -config.range, config.range do
        for dy = -config.range, config.range do
            local square = cell:getGridSquare(x + dx, y + dy, z)
            if square then
                for i = 0, square:getMovingObjects():size() - 1 do
                    local obj = square:getMovingObjects():get(i)
                    if obj:isZombie() and obj ~= source then
                        table.insert(nearbyZombies, obj)
                    end
                end
            end
        end
    end
    
    -- Aplicar chain lightning a 1-2 zombies adicionales
    local chainTargets = math.min(2, #nearbyZombies)
    for i = 1, chainTargets do
        local target = nearbyZombies[ZombRand(1, #nearbyZombies)]
        
        -- Efecto reducido
        target:getBodyDamage():AddDamage(BodyPartType.Torso, config.damage * 0.5)
        getSoundManager():PlaySound("ElectricZap", false, 1.0)
        
        if target:isZombie() then
            target:setStun(true, ZombRand(15, 30))
        end
    end
end

-- Registrar eventos
Events.OnWeaponHitCharacter.Add(ElectricWeapons.applyElectricEffect)
```

---

## 4. EFECTOS ELÉCTRICOS Y ESPECIALES

### 4.1 Sistema de Efectos Visuales
```lua
-- Script: ModName_VisualEffects.lua
local VisualEffects = {}

-- Configuración de efectos visuales
local visualConfig = {
    lightning = {
        duration = 10,
        color = {r = 0.8, g = 0.8, b = 1.0, a = 1.0},
        radius = 5,
        intensity = 0.9,
    },
    fire = {
        duration = 30,
        color = {r = 1.0, g = 0.5, b = 0.0, a = 0.8},
        radius = 3,
        intensity = 1.2,
    },
    ice = {
        duration = 20,
        color = {r = 0.5, g = 0.8, b = 1.0, a = 0.7},
        radius = 4,
        intensity = 0.6,
    },
}

-- Crear efecto visual
function VisualEffects.createEffect(x, y, z, effectType)
    local config = visualConfig[effectType]
    if not config then return end
    
    local cell = getCell()
    
    -- Crear luz temporal
    cell:addLightSource(x, y, z, 
                       config.radius,
                       config.color.r, config.color.g, config.color.b,
                       config.duration)
    
    -- Crear partículas (si disponible)
    if effectType == "lightning" then
        -- Simular efecto de rayos con luces intermitentes
        for i = 1, 3 do
            getGameTime():addEvent(function()
                cell:addLightSource(x + ZombRandFloat(-1, 1), 
                                  y + ZombRandFloat(-1, 1), z,
                                  2, 0.9, 0.9, 1.0, 5)
            end, i * 3)
        end
    end
end

-- Aplicar efecto de área
function VisualEffects.areaEffect(centerX, centerY, centerZ, radius, effectType)
    for dx = -radius, radius do
        for dy = -radius, radius do
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance <= radius then
                local x, y = centerX + dx, centerY + dy
                
                -- Efecto decreciente con la distancia
                local intensity = 1 - (distance / radius)
                
                getGameTime():addEvent(function()
                    VisualEffects.createEffect(x, y, centerZ, effectType)
                end, ZombRand(0, 10))
            end
        end
    end
end
```

### 4.2 Sistema de Propiedades Mágicas/Especiales
```lua
-- Script: ModName_MagicProperties.lua
local MagicProperties = {}

-- Efectos especiales por tipo
local specialEffects = {
    lightning = {
        name = "Lightning Strike",
        damage = 2.5,
        chance = 0.25,
        stunDuration = 45,
        sound = "Thunder",
        areaEffect = true,
        areaRadius = 2,
    },
    fire = {
        name = "Fire Burst",
        damage = 1.5,
        chance = 0.4,
        burnDuration = 30,
        sound = "FireBurst",
        igniteChance = 0.6,
    },
    ice = {
        name = "Frost Touch",
        damage = 1.0,
        chance = 0.3,
        slowDuration = 60,
        sound = "IceShatter",
        freezeChance = 0.2,
    },
}

-- Aplicar propiedades mágicas
function MagicProperties.applyMagicEffect(attacker, victim, weapon, effectType)
    local effect = specialEffects[effectType]
    if not effect then return end
    
    -- Verificar probabilidad
    if ZombRand(100) >= (effect.chance * 100) then return end
    
    -- Aplicar efecto base
    victim:getBodyDamage():AddDamage(BodyPartType.Torso, effect.damage)
    
    -- Sonido específico
    getSoundManager():PlaySound(effect.sound, false, 2.0)
    addSound(victim, victim:getX(), victim:getY(), victim:getZ(), 20, 15)
    
    -- Efectos específicos por tipo
    if effectType == "lightning" then
        -- Stun eléctrico
        if victim:isZombie() then
            victim:setStun(true, effect.stunDuration)
        end
        
        -- Efecto de área
        if effect.areaEffect then
            MagicProperties.lightningAreaEffect(victim, effect.areaRadius)
        end
        
    elseif effectType == "fire" then
        -- Quemar al enemigo
        if ZombRand(100) < (effect.igniteChance * 100) then
            victim:setOnFire(true)
        end
        
    elseif effectType == "ice" then
        -- Efecto de ralentización
        if victim:isZombie() then
            local zombie = victim
            zombie:setSlowTimer(effect.slowDuration)
        end
    end
    
    -- Crear efecto visual
    VisualEffects.createEffect(victim:getX(), victim:getY(), victim:getZ(), effectType)
end

-- Efecto de rayo en área
function MagicProperties.lightningAreaEffect(centerVictim, radius)
    local x, y, z = centerVictim:getX(), centerVictim:getY(), centerVictim:getZ()
    local cell = getCell()
    
    for dx = -radius, radius do
        for dy = -radius, radius do
            local square = cell:getGridSquare(x + dx, y + dy, z)
            if square then
                for i = 0, square:getMovingObjects():size() - 1 do
                    local obj = square:getMovingObjects():get(i)
                    if obj:isZombie() and obj ~= centerVictim then
                        -- Chain lightning reducido
                        obj:getBodyDamage():AddDamage(BodyPartType.Torso, 1.0)
                        getSoundManager():PlaySound("ElectricZap", false, 1.0)
                        obj:setStun(true, 20)
                    end
                end
            end
        end
    end
end
```

---

## 5. SISTEMA DE CONTEXT MENUS

### 5.1 Context Menus Personalizados
```lua
-- Script: ModName_ContextMenus.lua
local ContextMenus = {}

-- Registrar context menu personalizado
function ContextMenus.registerSpecialAction()
    -- Menu para activar efectos especiales
    Events.OnFillInventoryObjectContextMenu.Add(function(player, context, items)
        for i = 1, #items do
            local item = items[i]
            if not instanceof(item, "InventoryItem") then
                item = item.items[1]
            end
            
            if item:getFullType() == "ModName.ElectricBat" then
                -- Opción de activar modo eléctrico
                local option = context:addOption("Activate Electric Mode", item, 
                                                ContextMenus.activateElectricMode, player)
                option.toolTip = ISInventoryTooltip:new("Charges the bat with electricity")
                
                -- Opción de descargar electricidad
                if item:getModData().ElectricCharge and item:getModData().ElectricCharge > 0 then
                    local dischargeOption = context:addOption("Discharge Lightning", item,
                                                            ContextMenus.dischargeLightning, player)
                    dischargeOption.toolTip = ISInventoryTooltip:new("Release stored electrical energy")
                end
            end
        end
    end)
end

-- Activar modo eléctrico
function ContextMenus.activateElectricMode(item, player)
    local modData = item:getModData()
    
    -- Verificar si tiene batería o fuente de energía
    local battery = player:getInventory():getItemFromType("Battery")
    if not battery or battery:getUsedDelta() < 0.2 then
        player:Say("Need a battery with at least 20% charge.")
        return
    end
    
    -- Consumir batería
    battery:setUsedDelta(battery:getUsedDelta() - 0.2)
    
    -- Activar modo eléctrico por 5 minutos
    modData.ElectricCharge = 300  -- 5 minutos
    modData.ElectricActive = true
    
    -- Efectos visuales y sonoros
    getSoundManager():PlaySound("ElectricCharge", false, 1.5)
    player:Say("Electric bat charged!")
    
    -- Timer para desactivar
    getGameTime():addEvent(function()
        modData.ElectricCharge = 0
        modData.ElectricActive = false
        player:Say("Electric charge depleted.")
    end, 300)
end

-- Descargar rayo
function ContextMenus.dischargeLightning(item, player)
    local modData = item:getModData()
    
    if not modData.ElectricCharge or modData.ElectricCharge <= 0 then
        player:Say("No electric charge remaining.")
        return
    end
    
    -- Crear efecto de rayo masivo
    local x, y, z = player:getX(), player:getY(), player:getZ()
    
    -- Sonido de trueno potente
    getSoundManager():PlaySound("Thunder", false, 3.0)
    addSound(player, x, y, z, 50, 30)  -- Muy ruidoso
    
    -- Efecto visual
    VisualEffects.areaEffect(x, y, z, 5, "lightning")
    
    -- Daño en área
    MagicProperties.lightningAreaEffect(player, 5)
    
    -- Consumir toda la carga
    modData.ElectricCharge = 0
    modData.ElectricActive = false
    
    player:Say("Lightning discharged!")
end

-- Inicializar context menus
ContextMenus.registerSpecialAction()
```

---

## 6. RECIPES ONCREATE AVANZADOS

### 6.1 Recipe para Crear Arma Eléctrica
```text
recipe Craft Electric Bat
{
    keep Battery,
    destroy Baseball Bat,
    destroy Wire,
    destroy Amplifier,
    destroy Electronics Scrap,
    
    Result:ModName.ElectricBat,
    
    Time:300.0,
    Category:Weapon,
    OriginalRecipe:true,
    
    OnCreate:Recipe.OnCreate.CraftElectricBat,
    
    Tooltip:Tooltip_CraftElectricBat,
    
    AnimNode:Craft,
    SoundCategory:craftingElectronics,
    
    RequiredSkills:Electrical:4;Metalwork:3,
}
```

### 6.2 OnCreate Script para Arma Eléctrica
```lua
-- Script: Recipe_OnCreate_ElectricWeapons.lua
Recipe = Recipe or {}
Recipe.OnCreate = Recipe.OnCreate or {}

-- Crear bate eléctrico
function Recipe.OnCreate.CraftElectricBat(items, result, player)
    -- Obtener items utilizados
    local battery = nil
    local bat = nil
    
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:getType() == "Battery" then
            battery = item
        elseif item:getType() == "BaseballBat" then
            bat = item
        end
    end
    
    -- Configurar propiedades del resultado
    if result and battery and bat then
        local modData = result:getModData()
        
        -- Transferir condición del bate original
        local condition = bat:getCondition() / bat:getConditionMax()
        result:setCondition(result:getConditionMax() * condition)
        
        -- Configurar carga eléctrica inicial
        local batteryCharge = battery:getUsedDelta()
        modData.ElectricCharge = batteryCharge * 600  -- Hasta 10 minutos
        modData.ElectricActive = batteryCharge > 0.1
        
        -- Propiedades especiales basadas en calidad de componentes
        if batteryCharge > 0.8 then
            modData.ElectricDamage = 2.5      -- Daño mejorado
            modData.ElectricChance = 0.4      -- Mayor probabilidad
        else
            modData.ElectricDamage = 1.5
            modData.ElectricChance = 0.2
        end
        
        -- Configurar sonidos especiales
        modData.HitSound = "Thunder"
        modData.SwingSound = "ElectricHum"
        modData.SpecialSound = "Lightning"
        
        -- Experiencia al crear
        player:getXp():AddXP(Perks.Electrical, 100)
        player:getXp():AddXP(Perks.Metalwork, 50)
        
        -- Mensaje de éxito
        player:Say("Electric bat crafted successfully!")
        getSoundManager():PlaySound("ElectricCharge", false, 1.0)
    end
end

-- Función para mantener carga eléctrica
function Recipe.OnCreate.RechargeElectricWeapon(items, result, player)
    local battery = nil
    local weapon = nil
    
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item:getType() == "Battery" then
            battery = item
        elseif item:getModData().ElectricActive ~= nil then
            weapon = item
        end
    end
    
    if weapon and battery then
        local modData = weapon:getModData()
        local batteryCharge = battery:getUsedDelta()
        
        -- Recargar arma eléctrica
        modData.ElectricCharge = (modData.ElectricCharge or 0) + (batteryCharge * 300)
        modData.ElectricActive = modData.ElectricCharge > 0
        
        -- Límite máximo de carga
        if modData.ElectricCharge > 600 then
            modData.ElectricCharge = 600
        end
        
        player:Say("Weapon recharged. Charge: " .. math.floor(modData.ElectricCharge / 6) .. "%")
        getSoundManager():PlaySound("ElectricRecharge", false, 1.0)
    end
end
```

---

## 7. ARMAS CON EFECTOS ÚNICOS

### 7.1 Ejemplo Completo: Bate de Rayo
```text
item ModName_ThunderBat
{
    # Propiedades básicas
    Type = Weapon,
    DisplayName = Thunder Bat,
    DisplayCategory = Weapon,
    Icon = ModName_ThunderBat,
    Weight = 3.5,
    
    # Propiedades de combate mejoradas
    MinDamage = 2.2,
    MaxDamage = 4.0,
    MinRange = 0.61,
    MaxRange = 1.8,                    # Mayor alcance
    WeaponSprite = ModName_ThunderBatSprite,
    
    # Efectos de rayo únicos
    LightningDamage = 3.0,             # Daño de rayo muy alto
    LightningChance = 50,              # 50% probabilidad
    ChainLightning = 3,                # Puede saltar a 3 enemigos
    ElectricStun = 90,                 # Stun de 90 segundos
    
    # Sonidos épicos
    SwingSound = ThunderRumble,        # Sonido de trueno al swing
    HitSound = LightningStrike,        # Sonido de rayo al hit
    ChargeSound = ElectricBuildup,     # Sonido de carga eléctrica
    
    # Propiedades físicas especiales
    ConditionMax = 35,                 # Muy duradero
    ConditionLowerChanceOneIn = 25,    # Baja probabilidad de degradación
    WeaponWeight = 3.5,
    
    # Críticos aumentados
    CriticalChance = 30,               # Alta probabilidad de crítico
    CritDmgMultiplier = 3.0,           # Triple daño crítico
    
    # Efectos de combate únicos
    KnockdownMod = 2.0,                # Mayor knockdown
    PushBackMod = 1.2,                 # Mayor pushback
    MaxHitCount = 3,                   # Puede golpear 3 enemigos
    
    # Animación especial
    SwingAnim = Bat,
    SwingAmountBeforeImpact = 0.01,    # Swing más rápido
    MinimumSwingTime = 3,              # Tiempo mínimo reducido
    
    # Efectos visuales
    WeaponGlow = electric_blue,        # Brillar eléctrico
    HitEffect = lightning_burst,       # Efecto al golpear
    
    # Categorización especial
    Categories = Weapon;Blunt;Electric;Legendary,
    SubCategory = Bat,
    
    # Modelos únicos
    WorldStaticModel = ModName_ThunderBat,
    StaticModel = ModName_ThunderBatBackpack,
    
    # Requisitos especiales
    RequiredSkill = Electrical:5,      # Requiere skill eléctrico
    
    # Tags especiales
    Tags = Electric;Lightning;Legendary;Weapon;Thunder,
    
    # Tooltip detallado
    Tooltip = Tooltip_ThunderBat,
}
```

### 7.2 Script de Control del Thunder Bat
```lua
-- Script: ModName_ThunderBat.lua
local ThunderBat = {}

-- Verificar si el arma es Thunder Bat
function ThunderBat.isThunderBat(weapon)
    return weapon and weapon:getFullType() == "ModName.ThunderBat"
end

-- Efecto especial del Thunder Bat
function ThunderBat.onThunderHit(attacker, victim, weapon, damage)
    if not ThunderBat.isThunderBat(weapon) then return end
    
    local modData = weapon:getModData()
    
    -- Verificar carga eléctrica (se degrada con uso)
    local charge = modData.ElectricCharge or 100
    if charge <= 0 then return end
    
    -- Probabilidad basada en carga
    local chance = (charge / 100) * 0.5  -- Hasta 50% con carga completa
    if ZombRand(100) >= (chance * 100) then return end
    
    -- Efectos de thunder
    local x, y, z = victim:getX(), victim:getY(), victim:getZ()
    
    -- Sonido épico de rayo
    getSoundManager():PlaySound("LightningStrike", false, 3.0)
    getSoundManager():PlaySound("ThunderClap", false, 2.5)
    addSound(victim, x, y, z, 60, 40)  -- Extremadamente ruidoso
    
    -- Daño masivo de rayo
    victim:getBodyDamage():AddDamage(BodyPartType.Torso, 3.0)
    
    -- Stun prolongado
    if victim:isZombie() then
        victim:setStun(true, 90)
    end
    
    -- Chain lightning a múltiples enemigos
    ThunderBat.chainLightningMassive(victim, 3, 2.0)
    
    -- Efecto visual épico
    VisualEffects.areaEffect(x, y, z, 5, "lightning")
    
    -- Degradar carga
    modData.ElectricCharge = charge - 10
    
    -- Mensaje dramático
    if attacker and attacker:isPlayer() then
        attacker:Say("THUNDER STRIKES!")
    end
end

-- Chain lightning masivo
function ThunderBat.chainLightningMassive(source, maxTargets, damage)
    local x, y, z = source:getX(), source:getY(), source:getZ()
    local cell = getCell()
    local targets = {}
    
    -- Buscar zombies en área amplia
    for dx = -8, 8 do
        for dy = -8, 8 do
            local square = cell:getGridSquare(x + dx, y + dy, z)
            if square then
                for i = 0, square:getMovingObjects():size() - 1 do
                    local obj = square:getMovingObjects():get(i)
                    if obj:isZombie() and obj ~= source then
                        local distance = math.sqrt(dx * dx + dy * dy)
                        table.insert(targets, {zombie = obj, distance = distance})
                    end
                end
            end
        end
    end
    
    -- Ordenar por distancia
    table.sort(targets, function(a, b) return a.distance < b.distance end)
    
    -- Aplicar chain lightning
    for i = 1, math.min(maxTargets, #targets) do
        local target = targets[i].zombie
        
        -- Daño decreciente con la distancia
        local chainDamage = damage * (1 - (i - 1) * 0.3)
        
        target:getBodyDamage():AddDamage(BodyPartType.Torso, chainDamage)
        getSoundManager():PlaySound("ElectricZap", false, 1.5)
        
        if target:isZombie() then
            target:setStun(true, 60 - (i * 15))
        end
        
        -- Efecto visual para cada salto
        VisualEffects.createEffect(target:getX(), target:getY(), target:getZ(), "lightning")
    end
end

-- Sistema de recarga del Thunder Bat
function ThunderBat.rechargeWeapon(weapon, player)
    if not ThunderBat.isThunderBat(weapon) then return end
    
    local modData = weapon:getModData()
    local currentCharge = modData.ElectricCharge or 0
    
    if currentCharge >= 100 then
        player:Say("Thunder Bat is fully charged.")
        return
    end
    
    -- Buscar generador o fuente de energía
    local generator = player:getInventory():getItemFromType("Generator")
    local battery = player:getInventory():getItemFromType("Battery")
    
    if generator and generator:getUsedDelta() > 0.5 then
        -- Recarga completa con generador
        modData.ElectricCharge = 100
        generator:setUsedDelta(generator:getUsedDelta() - 0.3)
        player:Say("Thunder Bat fully recharged with generator!")
        
    elseif battery and battery:getUsedDelta() > 0.3 then
        -- Recarga parcial con batería
        modData.ElectricCharge = currentCharge + 30
        battery:setUsedDelta(battery:getUsedDelta() - 0.3)
        player:Say("Thunder Bat partially recharged.")
    else
        player:Say("Need a generator (50%+) or battery (30%+) to recharge.")
        return
    end
    
    -- Efecto de recarga
    getSoundManager():PlaySound("ElectricRecharge", false, 2.0)
    VisualEffects.createEffect(player:getX(), player:getY(), player:getZ(), "lightning")
end

-- Registrar eventos
Events.OnWeaponHitCharacter.Add(ThunderBat.onThunderHit)
```

---

## 8. EJEMPLOS PRÁCTICOS

### 8.1 EJEMPLO: Crear Bate Eléctrico Completo

#### Paso 1: Definir el Item
```text
# Archivo: media/scripts/items/ElectricWeapons.txt
module ModName
{
    item ElectricBat
    {
        Type = Weapon,
        DisplayName = Electric Baseball Bat,
        DisplayCategory = Weapon,
        Icon = ModName_ElectricBat,
        Weight = 3.2,
        
        # Combate
        MinDamage = 1.8,
        MaxDamage = 3.5,
        MinRange = 0.61,
        MaxRange = 1.6,
        WeaponSprite = ModName_ElectricBatSprite,
        
        # Efectos eléctricos
        ElectricDamage = 2.5,
        ElectricChance = 35,
        ElectricStun = 60,
        
        # Sonidos únicos
        SwingSound = ElectricHum,
        HitSound = Thunder,
        SpecialHitSound = Lightning,
        
        # Durabilidad
        ConditionMax = 25,
        ConditionLowerChanceOneIn = 20,
        WeaponWeight = 3.2,
        
        # Animación
        SwingAnim = Bat,
        SwingAmountBeforeImpact = 0.02,
        MinimumSwingTime = 4,
        
        # Críticos mejorados
        CriticalChance = 25,
        CritDmgMultiplier = 2.8,
        
        # Efectos de combate
        KnockdownMod = 1.8,
        PushBackMod = 1.0,
        MaxHitCount = 2,
        
        # Modelos
        WorldStaticModel = ModName_ElectricBat,
        StaticModel = ModName_ElectricBatBackpack,
        
        # Categorización
        Categories = Weapon;Blunt;Electric,
        SubCategory = Bat,
        
        # Tags
        Tags = Electric;Special;Lightning;Weapon;Rechargeable,
        
        # Tooltip
        Tooltip = Tooltip_ElectricBat,
    }
}
```

#### Paso 2: Recipe de Crafting
```text
# Archivo: media/scripts/recipes/ElectricWeapons.txt
recipe Craft Electric Bat
{
    keep Battery,
    destroy BaseballBat,
    destroy Wire,
    destroy ElectronicsScrap,
    destroy AluminumBar,
    
    Result:ModName.ElectricBat,
    
    Time:450.0,
    Category:Weapon,
    OriginalRecipe:true,
    
    OnCreate:Recipe.OnCreate.CraftElectricBat,
    
    AnimNode:Craft,
    SoundCategory:craftingElectronics,
    
    RequiredSkills:Electrical:4;Metalwork:3,
    Tooltip:Tooltip_CraftElectricBat,
}

recipe Recharge Electric Weapon
{
    keep [any electric weapon],
    destroy Battery=2,
    
    Result:[same electric weapon],
    
    Time:60.0,
    Category:Weapon,
    OriginalRecipe:true,
    
    OnCreate:Recipe.OnCreate.RechargeElectricWeapon,
    
    RequiredSkills:Electrical:2,
}
```

#### Paso 3: Script Completo de Efectos
```lua
-- Archivo: media/lua/shared/ModName_ElectricBat.lua
local ElectricBat = {}

-- Inicializar sistema
function ElectricBat.init()
    print("Electric Bat system initialized")
end

-- Efecto principal al golpear
function ElectricBat.onHit(attacker, victim, weapon, damage)
    if weapon:getFullType() ~= "ModName.ElectricBat" then return end
    
    local modData = weapon:getModData()
    local charge = modData.ElectricCharge or 0
    
    -- Sin carga, sin efectos especiales
    if charge <= 0 then 
        if attacker and attacker:isPlayer() then
            attacker:Say("Battery depleted!")
        end
        return 
    end
    
    -- Probabilidad basada en carga
    local baseChance = weapon:getModData().ElectricChance or 0.35
    local chanceModified = baseChance * (charge / 100)
    
    if ZombRand(100) >= (chanceModified * 100) then 
        -- Consumir carga mínima incluso sin efecto
        modData.ElectricCharge = charge - 1
        return 
    end
    
    -- ¡EFECTO DE RAYO!
    local x, y, z = victim:getX(), victim:getY(), victim:getZ()
    
    -- Sonidos épicos superpuestos
    getSoundManager():PlaySound("Thunder", false, 3.0)
    getSoundManager():PlaySound("Lightning", false, 2.5)
    getSoundManager():PlaySound("ElectricCrackle", false, 1.5)
    
    -- Sonido para IA (MUY ruidoso)
    addSound(victim, x, y, z, 50, 35)
    
    -- Daño eléctrico masivo
    local electricDamage = modData.ElectricDamage or 2.5
    victim:getBodyDamage():AddDamage(BodyPartType.Torso, electricDamage)
    
    -- Stun eléctrico
    if victim:isZombie() then
        local stunTime = modData.ElectricStun or 60
        victim:setStun(true, stunTime)
    end
    
    -- Chain lightning
    ElectricBat.chainLightning(victim, 3, electricDamage * 0.6)
    
    -- Efectos visuales épicos
    VisualEffects.areaEffect(x, y, z, 6, "lightning")
    
    -- Consumir carga considerable
    modData.ElectricCharge = charge - 8
    
    -- Mensaje dramático
    if attacker and attacker:isPlayer() then
        attacker:Say("⚡ LIGHTNING STRIKE! ⚡")
    end
end

-- Chain lightning específico del Thunder Bat
function ElectricBat.chainLightning(source, maxTargets, damage)
    local x, y, z = source:getX(), source:getY(), source:getZ()
    local cell = getCell()
    local chainTargets = {}
    
    -- Buscar objetivos en radio amplio
    for dx = -10, 10 do
        for dy = -10, 10 do
            local square = cell:getGridSquare(x + dx, y + dy, z)
            if square then
                for i = 0, square:getMovingObjects():size() - 1 do
                    local obj = square:getMovingObjects():get(i)
                    if obj:isZombie() and obj ~= source then
                        local distance = math.sqrt(dx * dx + dy * dy)
                        if distance <= 10 then
                            table.insert(chainTargets, {zombie = obj, distance = distance})
                        end
                    end
                end
            end
        end
    end
    
    -- Ordenar por distancia y limitar
    table.sort(chainTargets, function(a, b) return a.distance < b.distance end)
    
    for i = 1, math.min(maxTargets, #chainTargets) do
        local target = chainTargets[i]
        local zombie = target.zombie
        
        -- Delay escalonado para efecto visual
        getGameTime():addEvent(function()
            -- Daño decreciente
            local chainDamage = damage * (1 - (i - 1) * 0.2)
            zombie:getBodyDamage():AddDamage(BodyPartType.Torso, chainDamage)
            
            -- Sonido de chain
            getSoundManager():PlaySound("ElectricZap", false, 2.0)
            addSound(zombie, zombie:getX(), zombie:getY(), zombie:getZ(), 25, 20)
            
            -- Stun reducido
            zombie:setStun(true, 45 - (i * 10))
            
            -- Efecto visual
            VisualEffects.createEffect(zombie:getX(), zombie:getY(), zombie:getZ(), "lightning")
            
        end, i * 5)  -- 5 ticks de delay entre cada salto
    end
end

-- Context menu para recargar
Events.OnFillInventoryObjectContextMenu.Add(function(player, context, items)
    for i = 1, #items do
        local item = items[i]
        if not instanceof(item, "InventoryItem") then
            item = item.items[1]
        end
        
        if ElectricBat.isThunderBat(item) then
            local charge = item:getModData().ElectricCharge or 0
            
            -- Mostrar carga actual
            local chargePercent = math.floor(charge)
            context:addOption("Electric Charge: " .. chargePercent .. "%", nil, nil)
            
            -- Opción de recarga si hay batería
            local battery = player:getInventory():getItemFromType("Battery")
            if battery and battery:getUsedDelta() > 0.2 and charge < 100 then
                local rechargeOption = context:addOption("Recharge from Battery", item,
                                                        ElectricBat.rechargeBat, player)
                rechargeOption.toolTip = ISInventoryTooltip:new("Recharge electric weapon using battery")
            end
            
            -- Opción de descarga de emergencia
            if charge > 20 then
                local dischargeOption = context:addOption("Emergency Lightning Discharge", item,
                                                         ElectricBat.emergencyDischarge, player)
                dischargeOption.toolTip = ISInventoryTooltip:new("Release massive lightning burst")
            end
        end
    end
end)

-- Recargar bate
function ElectricBat.rechargeBat(item, player)
    local battery = player:getInventory():getItemFromType("Battery")
    if not battery then return end
    
    local batteryCharge = battery:getUsedDelta() * 100
    local currentCharge = item:getModData().ElectricCharge or 0
    local rechargeAmount = math.min(batteryCharge, 100 - currentCharge)
    
    -- Aplicar recarga
    item:getModData().ElectricCharge = currentCharge + rechargeAmount
    battery:setUsedDelta(battery:getUsedDelta() - (rechargeAmount / 100))
    
    -- Efectos
    getSoundManager():PlaySound("ElectricRecharge", false, 2.0)
    player:Say("Thunder Bat recharged to " .. math.floor(item:getModData().ElectricCharge) .. "%")
end

-- Descarga de emergencia
function ElectricBat.emergencyDischarge(item, player)
    local charge = item:getModData().ElectricCharge or 0
    if charge < 20 then return end
    
    -- Consumir toda la carga para efecto masivo
    item:getModData().ElectricCharge = 0
    
    local x, y, z = player:getX(), player:getY(), player:getZ()
    
    -- Efectos épicos
    getSoundManager():PlaySound("ThunderClap", false, 4.0)
    getSoundManager():PlaySound("LightningStorm", false, 3.0)
    addSound(player, x, y, z, 100, 50)  -- Extremadamente ruidoso
    
    -- Daño masivo en área grande
    ElectricBat.massiveLightningStorm(player, 10, 4.0)
    
    -- Efectos visuales épicos
    VisualEffects.areaEffect(x, y, z, 12, "lightning")
    
    player:Say("⚡⚡⚡ LIGHTNING STORM UNLEASHED! ⚡⚡⚡")
end

-- Tormenta de rayos masiva
function ElectricBat.massiveLightningStorm(player, radius, damage)
    local x, y, z = player:getX(), player:getY(), player:getZ()
    local cell = getCell()
    
    for dx = -radius, radius do
        for dy = -radius, radius do
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance <= radius then
                local square = cell:getGridSquare(x + dx, y + dy, z)
                if square then
                    for i = 0, square:getMovingObjects():size() - 1 do
                        local obj = square:getMovingObjects():get(i)
                        if obj:isZombie() then
                            -- Daño decreciente con distancia
                            local actualDamage = damage * (1 - distance / radius)
                            
                            obj:getBodyDamage():AddDamage(BodyPartType.Torso, actualDamage)
                            getSoundManager():PlaySound("ElectricZap", false, 1.5)
                            
                            if obj:isZombie() then
                                obj:setStun(true, 120)  -- Stun muy largo
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Registrar eventos
Events.OnWeaponHitCharacter.Add(ElectricBat.onHit)
Events.OnGameStart.Add(ElectricBat.init)
```

#### Paso 3: Sounds.txt
```text
# Archivo: media/sound/sounds.txt
sound Thunder
{
    category = Items,
    clip
    {
        event = Sounds/ModName/Thunder.ogg,
        volume = 1.0,
    }
}

sound Lightning
{
    category = Items,
    clip
    {
        event = Sounds/ModName/Lightning.ogg,
        volume = 1.0,
    }
}

sound ElectricHum
{
    category = Items,
    clip
    {
        event = Sounds/ModName/ElectricHum.ogg,
        volume = 0.8,
    }
}

sound ElectricRecharge
{
    category = Items,
    clip
    {
        event = Sounds/ModName/Recharge.ogg,
        volume = 1.2,
    }
}
```

#### Paso 4: Translations.txt
```text
# Archivo: media/lua/shared/Translate/ES/IG_UI_ES.txt
IG_UI_ES = {
    Tooltip_ElectricBat = "Un bate de béisbol modificado con tecnología eléctrica. <LINE> <LINE> <RGB:0.7,0.7,1> • Daño eléctrico adicional <LINE> • Probabilidad de stun eléctrico <LINE> • Chain lightning en área <LINE> • Requiere batería para funcionar <RGB:1,1,1>",
    Tooltip_CraftElectricBat = "Combina un bate de béisbol con componentes eléctricos para crear un arma devastadora.",
}
```

### 8.2 EJEMPLO: Arma con Múltiples Efectos
```text
item ModName_ElementalSword
{
    Type = Weapon,
    DisplayName = Elemental Sword,
    Icon = ModName_ElementalSword,
    Weight = 2.8,
    
    # Combate base
    MinDamage = 2.5,
    MaxDamage = 4.2,
    MinRange = 0.61,
    MaxRange = 1.8,
    WeaponSprite = ModName_ElementalSwordSprite,
    
    # Múltiples efectos especiales
    FireDamage = 1.8,
    FireChance = 25,
    IceDamage = 1.5,
    IceChance = 25,
    LightningDamage = 2.2,
    LightningChance = 25,
    
    # Sonidos variables
    SwingSound = ElementalHum,
    HitSound = ElementalBurst,
    
    # Efectos de combate superiores
    CriticalChance = 35,
    CritDmgMultiplier = 3.5,
    MaxHitCount = 4,
    
    # Durabilidad especial
    ConditionMax = 50,
    ConditionLowerChanceOneIn = 30,
    
    Categories = Weapon;Blade;Elemental;Legendary,
    Tags = Fire;Ice;Lightning;Elemental;Magical,
}
```

### 8.3 EJEMPLO RÁPIDO: Comando de Creación
**Para crear rápidamente un bate eléctrico:**

```lua
-- Función de utilidad para desarrollo/testing
function DevUtils.createElectricBat(player)
    local bat = InventoryItemFactory.CreateItem("ModName.ElectricBat")
    if bat then
        -- Configurar con carga completa
        bat:getModData().ElectricCharge = 100
        bat:getModData().ElectricActive = true
        bat:getModData().ElectricDamage = 2.5
        bat:getModData().ElectricChance = 0.35
        
        player:getInventory():AddItem(bat)
        player:Say("Electric bat created and charged!")
        getSoundManager():PlaySound("ElectricCharge", false, 1.0)
    end
end

-- Comando para testing (activar en sandbox)
if isDebugEnabled() then
    LuaEventManager.AddEvent("OnKeyPressed")
    Events.OnKeyPressed.Add(function(key)
        if key == Keyboard.KEY_F8 then  -- F8 para crear bate eléctrico
            DevUtils.createElectricBat(getPlayer())
        end
    end)
end
```

---

## 9. PATRONES CRÍTICOS DE IMPLEMENTACIÓN

### 9.1 Gestión de Carga/Energía
```lua
-- Sistema de gestión de energía para armas especiales
local EnergySystem = {}

function EnergySystem.updateWeaponEnergy(weapon, player)
    if not weapon or not weapon:getModData().ElectricCharge then return end
    
    local modData = weapon:getModData()
    local currentCharge = modData.ElectricCharge or 0
    
    -- Degradación pasiva de carga (1% por minuto)
    if currentCharge > 0 then
        modData.ElectricCharge = currentCharge - 0.02
        if modData.ElectricCharge < 0 then
            modData.ElectricCharge = 0
            modData.ElectricActive = false
            if player then
                player:Say("Electric weapon power depleted.")
            end
        end
    end
end

-- Actualizar cada minuto
Events.EveryOneMinute.Add(function()
    local player = getPlayer()
    if player then
        local inventory = player:getInventory()
        for i = 0, inventory:getItems():size() - 1 do
            local item = inventory:getItems():get(i)
            if item:getModData().ElectricCharge then
                EnergySystem.updateWeaponEnergy(item, player)
            end
        end
    end
end)
```

### 9.2 Validación y Debugging
```lua
-- Sistema de debugging para armas especiales
local WeaponDebug = {}

function WeaponDebug.logWeaponStats(weapon, event)
    if not isDebugEnabled() then return end
    
    local modData = weapon:getModData()
    local weaponType = weapon:getFullType()
    
    print("=== WEAPON DEBUG: " .. event .. " ===")
    print("Type: " .. weaponType)
    print("Condition: " .. weapon:getCondition() .. "/" .. weapon:getConditionMax())
    
    if modData.ElectricCharge then
        print("Electric Charge: " .. (modData.ElectricCharge or 0) .. "%")
        print("Electric Active: " .. tostring(modData.ElectricActive or false))
        print("Electric Damage: " .. (modData.ElectricDamage or 0))
        print("Electric Chance: " .. (modData.ElectricChance or 0))
    end
    
    print("================================")
end

-- Hooks de debugging (solo en modo debug)
if isDebugEnabled() then
    Events.OnWeaponSwing.Add(function(player, weapon)
        WeaponDebug.logWeaponStats(weapon, "SWING")
    end)
    
    Events.OnWeaponHitCharacter.Add(function(attacker, victim, weapon, damage)
        WeaponDebug.logWeaponStats(weapon, "HIT")
    end)
end
```

---

## 10. MEJORES PRÁCTICAS

### 10.1 Optimización de Rendimiento
- **Caché de configuraciones**: Almacenar configuraciones de efectos en variables locales
- **Verificaciones tempranas**: Salir rápido si el item no tiene efectos especiales
- **Límites de efectos**: Evitar efectos en área demasiado grandes o frecuentes
- **Gestión de memoria**: Limpiar modData innecesaria periódicamente

### 10.2 Balanceado de Gameplay
- **Costo de recursos**: Armas especiales deben requerir materiales raros
- **Degradación**: Efectos especiales deben consumir energía/durabilidad
- **Contrabalances**: Mayor poder = mayor ruido, peso, o requisitos de skill
- **Progresión**: Efectos más potentes requieren skills más altos

### 10.3 Compatibilidad con Mods
- **Namespace único**: Usar prefijos consistentes para evitar conflictos
- **Eventos estándar**: Utilizar eventos nativos de PZ cuando sea posible
- **Verificaciones de existencia**: Comprobar que otros mods no interfieran
- **Configuración modular**: Permitir desactivar efectos específicos via sandbox

---

## CONCLUSIÓN

Este sistema de crafting avanzado permite crear items con propiedades únicas que van más allá de las capacidades estándar de Project Zomboid. Los patrones presentados son escalables y modulares, permitiendo crear desde armas eléctricas simples hasta sistemas de combate completamente nuevos.

**Uso recomendado**: Comenzar con items simples (bate eléctrico básico) y gradualmente agregar complejidad (chain lightning, efectos de área, múltiples elementos).

---

*Documentación generada por análisis de mods avanzados de Project Zomboid*  
*Última actualización: Sesión de análisis actual*