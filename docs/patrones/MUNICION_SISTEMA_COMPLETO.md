# SISTEMA DE MUNICIÓN PERSONALIZADA - PROJECT ZOMBOID

## CREACIÓN Y MANEJO COMPLETO DE MUNICIÓN AVANZADA

*Basado en análisis de patrones de armas y sistema de distribución automática*

---

## 1. ARQUITECTURA FUNDAMENTAL DE MUNICIÓN

### 1.1 Tipos de Munición en PZ
```
CATEGORÍAS PRINCIPALES:
├── Bullets (Balas simples)      # Base.Bullets9mm, Base.556Bullets
├── Shells (Cartuchos)           # Base.ShotgunShells  
├── Boxes (Cajas de munición)    # Base.Bullets9mmBox, Base.556Box
├── Magazines (Cargadores)       # Base.9mmClip, Base.556Clip
├── Special Ammo (Especial)      # Incendiaria, perforante, etc.
└── Exotic Ammo (Exótica)        # Energía, plasma, química
```

### 1.2 Jerarquía de Archivos para Munición
```
ModName/
├── media/scripts/items/
│   ├── ModName_Ammunition.txt       # Definición de munición
│   ├── ModName_Magazines.txt        # Cargadores y clips
│   ├── ModName_AmmoBoxes.txt        # Cajas de munición
│   └── ModName_SpecialAmmo.txt      # Munición especial
├── media/lua/server/
│   ├── ModName_AmmoEffects.lua      # Efectos especiales al disparar
│   ├── ModName_AmmoDistribution.lua # Distribución en mundo
│   └── ModName_WeaponCompatibility.lua # Compatibilidad arma-munición
└── media/textures/Items/
    ├── ModName_Bullet_*.png         # Texturas de balas
    ├── ModName_Magazine_*.png       # Texturas de cargadores
    └── ModName_AmmoBox_*.png        # Texturas de cajas
```

---

## 2. DEFINICIÓN DE MUNICIÓN BÁSICA

### 2.1 Estructura Base de Bala
```text
item ModName_Bullet_9mm
{
    DisplayName = 9mm Special Round,
    DisplayCategory = Ammo,
    Type = Normal,
    Weight = 0.01,
    Icon = ModName_Bullet_9mm,
    WorldStaticModel = ModName_Bullet_9mm,
    
    # Propiedades balísticas
    BulletType = 9mm,                   # Tipo de bala
    BulletDamage = 1.2,                 # Multiplicador de daño
    BulletPenetration = 1.1,            # Penetración de armadura
    BulletRange = 1.0,                  # Multiplicador de alcance
    BulletAccuracy = 1.0,               # Multiplicador de precisión
    
    # Efectos especiales
    BulletSound = ModName_9mmSpecial,   # Sonido personalizado
    BulletEffect = incendiary,          # Efecto especial
    
    # Propiedades físicas
    StackSize = 100,                    # Cantidad apilable
    Tags = Ammo;9mm;Special,           # Tags para identificación
    
    # Valor y rareza
    BasePrice = 5,                      # Precio base
    SpawnChance = 0.8,                  # Probabilidad de spawn
}
```

### 2.2 Munición con Efectos Especiales
```text
item ModName_Bullet_Incendiary
{
    DisplayName = Incendiary Round,
    DisplayCategory = Ammo,
    Type = Normal,
    Weight = 0.012,
    Icon = ModName_Bullet_Fire,
    WorldStaticModel = ModName_Bullet_Fire,
    
    # Propiedades balísticas
    BulletType = 556,
    BulletDamage = 0.9,                 # Menos daño base
    BulletPenetration = 0.8,            # Menos penetración
    BulletRange = 1.1,                  # Mayor alcance
    BulletAccuracy = 0.9,               # Menos precisión
    
    # Efectos especiales críticos
    BulletEffect = fire,                # Causa fuego
    ExplosionRadius = 2,                # Radio de explosión
    IgnitionChance = 0.8,               # 80% probabilidad de incendio
    BurnDuration = 30,                  # Duración del fuego (segundos)
    
    # Audio y visuales
    BulletSound = ModName_IncendiaryShot,
    MuzzleFlash = ModName_FireFlash,
    ProjectileTrail = fire_trail,
    
    # Restricciones
    IllegalItem = true,                 # Item ilegal (NPCs alertan)
    Rarity = VeryRare,                 # Muy raro
    StackSize = 50,                    # Menos apilable
    Tags = Ammo;556;Incendiary;Illegal,
}

item ModName_Bullet_AP
{
    DisplayName = Armor Piercing Round,
    DisplayCategory = Ammo,
    Type = Normal,
    Weight = 0.011,
    Icon = ModName_Bullet_AP,
    
    # Propiedades anti-armor
    BulletType = 762,
    BulletDamage = 0.85,                # Menos daño a flesh
    BulletPenetration = 2.5,            # Alta penetración
    ArmorPiercing = 0.9,                # 90% ignora armadura
    WallPenetration = 3,                # Atraviesa 3 paredes
    
    # Efectos balísticos
    BulletRange = 1.3,                  # Mayor alcance
    BulletAccuracy = 1.1,               # Mayor precisión
    Recoil = 1.2,                       # Mayor retroceso
    
    Tags = Ammo;762;ArmorPiercing;Military,
}
```

### 2.3 Munición Química/Exótica
```text
item ModName_Bullet_Tranquilizer
{
    DisplayName = Tranquilizer Dart,
    DisplayCategory = Ammo,
    Type = Normal,
    Weight = 0.008,
    Icon = ModName_Dart_Tranq,
    
    # Propiedades especiales
    BulletType = dart,
    BulletDamage = 0.1,                 # Mínimo daño
    BulletPenetration = 0.1,            # Sin penetración
    
    # Efectos químicos
    ChemicalEffect = sedative,          # Efecto sedante
    EffectDuration = 300,               # 5 minutos
    EffectStrength = 0.8,               # Intensidad del efecto
    OnHitScript = ModName_TranquilizerHit, # Script personalizado
    
    # Restricciones
    RequiresSpecialWeapon = true,       # Solo ciertas armas
    CompatibleWeapons = ModName.DartGun;ModName.TranqRifle,
    
    Tags = Ammo;Dart;Chemical;NonLethal,
}

item ModName_Bullet_EMP
{
    DisplayName = EMP Round,
    DisplayCategory = Ammo,
    Type = Normal,
    Weight = 0.015,
    Icon = ModName_Bullet_EMP,
    
    # Propiedades electromagnéticas
    BulletType = emp,
    BulletDamage = 0.05,                # Mínimo daño físico
    EMPRadius = 5,                      # Radio EMP
    EMPDuration = 60,                   # Duración efecto
    
    # Efectos sobre electronics
    DisableElectronics = true,          # Desactiva electrónicos
    DisableVehicles = true,             # Desactiva vehículos
    DisableLights = true,               # Desactiva luces
    
    OnHitScript = ModName_EMPHit,
    
    Tags = Ammo;EMP;Electronic;Futuristic,
}
```

---

## 3. SISTEMA DE CARGADORES AVANZADOS

### 3.1 Cargadores Estándar
```text
item ModName_Magazine_9mm_Extended
{
    DisplayName = Extended 9mm Magazine,
    DisplayCategory = Ammo,
    Type = Normal,
    Weight = 0.3,
    Icon = ModName_Magazine_9mm_Ext,
    WorldStaticModel = ModName_Magazine_9mm,
    
    # Propiedades del cargador
    MagazineType = 9mm,                 # Tipo de munición que acepta
    MaxAmmo = 30,                       # Capacidad máxima
    InsertAmmoSound = ModName_MagLoad,  # Sonido al cargar
    EjectAmmoSound = ModName_MagEject,  # Sonido al expulsar
    
    # Compatibilidad con armas
    CompatibleWeapons = Base.Pistol;ModName.Pistol_Advanced;ModName.SMG_9mm,
    
    # Modificadores de rendimiento
    ReloadTimeModifier = 1.2,           # 20% más lento de recargar
    AccuracyModifier = 0.95,            # 5% menos precisión
    WeightPenalty = 0.1,                # Peso adicional equipado
    
    # Durabilidad
    ConditionMax = 15,
    ConditionLowerChanceOneIn = 20,     # Resistente al desgaste
    
    Tags = Magazine;9mm;Extended,
}

item ModName_Magazine_Drum_556
{
    DisplayName = 5.56 Drum Magazine,
    DisplayCategory = Ammo,
    Type = Normal,
    Weight = 1.2,
    Icon = ModName_Magazine_Drum,
    
    # Propiedades de tambor
    MagazineType = 556,
    MaxAmmo = 100,
    InsertAmmoSound = ModName_DrumLoad,
    EjectAmmoSound = ModName_DrumEject,
    
    # Compatibilidad limitada
    CompatibleWeapons = ModName.AssaultRifle_Heavy;ModName.LMG_556,
    RestrictedWeapons = Base.AssaultRifle, # No compatible con vanilla
    
    # Modificadores severos
    ReloadTimeModifier = 2.5,           # Muy lento de recargar
    MovementSpeedModifier = 0.9,        # Reduce velocidad de movimiento
    AimTimeModifier = 1.3,              # Más lento de apuntar
    
    # Muy resistente
    ConditionMax = 25,
    ConditionLowerChanceOneIn = 50,
    
    Tags = Magazine;556;Drum;Heavy,
}
```

### 3.2 Cargadores con Munición Pre-cargada
```text
item ModName_Magazine_Mixed_Loaded
{
    DisplayName = Mixed Ammo Magazine (Loaded),
    DisplayCategory = Ammo,
    Type = Normal,
    Weight = 0.4,
    Icon = ModName_Magazine_Mixed,
    
    # Pre-cargado con munición especial
    MagazineType = mixed,
    MaxAmmo = 20,
    PreloadedAmmo = ModName.Bullet_AP;ModName.Bullet_Incendiary;Base.Bullets9mm,
    PreloadedPattern = "APII",          # Patrón de carga: AP, Incendiary, Incendiary, normal
    CurrentAmmo = 18,                   # Viene parcialmente cargado
    
    # Efectos especiales
    RandomAmmoType = true,              # Cada disparo tipo aleatorio
    AmmoMixBonus = 1.1,                 # 10% bonus por diversidad
    
    # Advertencias
    UnpredictableAmmo = true,           # Resultados impredecibles
    DangerousToHandle = true,           # Puede causar mal funcionamiento
    
    Tags = Magazine;Mixed;Loaded;Experimental,
}
```

---

## 4. SISTEMA DE EFECTOS BALÍSTICOS

### 4.1 Scripts de Efectos al Disparar
```lua
-- Script: ModName_AmmoEffects.lua
local AmmoEffects = {}

-- Efecto incendiario
function AmmoEffects.onIncendiaryHit(attacker, victim, weapon, ammo)
    if not victim then return end
    
    -- Verificar tipo de munición
    if ammo:getFullType() ~= "ModName.Bullet_Incendiary" then return end
    
    -- Aplicar fuego a victim
    if instanceof(victim, "IsoZombie") or instanceof(victim, "IsoPlayer") then
        victim:getBodyDamage():setBurning(true)
        victim:getBodyDamage():setBurnTime(30) -- 30 segundos
        
        -- Efecto visual
        local square = victim:getSquare()
        if square then
            square:startFire()
            addSound(victim, victim:getX(), victim:getY(), victim:getZ(), 15, 10)
        end
    end
    
    -- Crear explosión de fuego
    local x, y, z = victim:getX(), victim:getY(), victim:getZ()
    createExplosion(x, y, z, 2, attacker) -- Radio 2
end

-- Efecto EMP
function AmmoEffects.onEMPHit(attacker, victim, weapon, ammo)
    if ammo:getFullType() ~= "ModName.Bullet_EMP" then return end
    
    local x, y, z = victim:getX(), victim:getY(), victim:getZ()
    local empRadius = 5
    
    -- Buscar todos los objetos electrónicos en el área
    for dx = -empRadius, empRadius do
        for dy = -empRadius, empRadius do
            local square = getCell():getGridSquare(x + dx, y + dy, z)
            if square then
                local objects = square:getObjects()
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    
                    -- Desactivar radios
                    if obj:getName():contains("Radio") then
                        obj:getModData().EMPDisabled = getGameTime():getWorldAgeHours() + 1 -- 1 hora
                    end
                    
                    -- Desactivar generadores
                    if obj:getName():contains("Generator") then
                        obj:setActivated(false)
                        obj:getModData().EMPDisabled = getGameTime():getWorldAgeHours() + 2 -- 2 horas
                    end
                end
                
                -- Efectos en vehículos
                local vehicle = square:getVehicle()
                if vehicle and vehicle:isEngineRunning() then
                    vehicle:setEngineRunning(false)
                    vehicle:getModData().EMPDisabled = getGameTime():getWorldAgeHours() + 0.5 -- 30 min
                end
            end
        end
    end
    
    -- Efecto visual EMP
    createEMPEffect(x, y, z, empRadius)
end

-- Efecto tranquilizante
function AmmoEffects.onTranquilizerHit(attacker, victim, weapon, ammo)
    if ammo:getFullType() ~= "ModName.Bullet_Tranquilizer" then return end
    
    if instanceof(victim, "IsoZombie") then
        -- Reducir velocidad del zombie
        victim:setSpeedMod(0.3) -- 30% velocidad normal
        victim:getModData().TranquilizerEffect = getGameTime():getWorldAgeHours() + 5 -- 5 horas
        
        -- Reducir agresión
        victim:setTargetAlpha(0.2) -- Menos probable que ataque
        
    elseif instanceof(victim, "IsoPlayer") then
        -- Efectos en jugador
        local stats = victim:getStats()
        stats:setFatigue(math.min(1.0, stats:getFatigue() + 0.8))
        stats:setPain(math.max(0, stats:getPain() - 50))
        
        -- Aplicar moodle de sedación
        victim:getBodyDamage():setPoisonLevel(victim:getBodyDamage():getPoisonLevel() + 5)
    end
end

-- Registrar efectos
Events.OnWeaponHitCharacter.Add(AmmoEffects.onIncendiaryHit)
Events.OnWeaponHitCharacter.Add(AmmoEffects.onEMPHit)
Events.OnWeaponHitCharacter.Add(AmmoEffects.onTranquilizerHit)
```

### 4.2 Sistema de Sonidos Personalizados
```lua
-- Script: ModName_AmmoSounds.lua
local AmmoSounds = {}

-- Configuración de sonidos por tipo de munición
local ammoSoundConfig = {
    ["ModName.Bullet_Incendiary"] = {
        fireSound = "ModName_IncendiaryShot",
        hitSound = "ModName_FireBurst",
        echoSound = "ModName_IncendiaryEcho",
        volume = 25,
        range = 100,
    },
    ["ModName.Bullet_AP"] = {
        fireSound = "ModName_APShot",
        hitSound = "ModName_MetalPenetration", 
        echoSound = "ModName_APEcho",
        volume = 30,
        range = 120,
    },
    ["ModName.Bullet_Subsonic"] = {
        fireSound = "ModName_SuppressedShot",
        hitSound = "ModName_SoftHit",
        echoSound = nil, -- Sin eco
        volume = 8,
        range = 20,
    },
}

function AmmoSounds.playCustomAmmoSound(weapon, ammo, soundType)
    local ammoType = ammo:getFullType()
    local config = ammoSoundConfig[ammoType]
    
    if config and config[soundType] then
        local player = weapon:getContainer():getParent()
        if instanceof(player, "IsoPlayer") then
            local x, y, z = player:getX(), player:getY(), player:getZ()
            
            -- Reproducir sonido
            getSoundManager():PlayWorldSound(
                config[soundType], 
                x, y, z, 
                config.volume, 
                config.range, 
                1.0, -- Volume
                true, -- Is3D
                1.0   -- Pitch
            )
            
            -- Añadir sonido para IA de zombies
            addSound(player, x, y, z, config.range, config.volume)
        end
    end
end

-- Hook para interceptar disparos
local originalFireWeapon = ISInventoryPane.onFireWeapon
ISInventoryPane.onFireWeapon = function(self, weapon, player)
    local result = originalFireWeapon(self, weapon, player)
    
    -- Obtener munición utilizada
    local ammo = weapon:getCurrentAmmo()
    if ammo then
        AmmoSounds.playCustomAmmoSound(weapon, ammo, "fireSound")
    end
    
    return result
end
```

---

## 5. SISTEMA DE COMPATIBILIDAD ARMA-MUNICIÓN

### 5.1 Definición de Compatibilidades
```lua
-- Script: ModName_WeaponCompatibility.lua
local WeaponCompatibility = {}

-- Tabla de compatibilidades arma-munición
WeaponCompatibility.ammoTypes = {
    ["9mm"] = {
        standard = {"Base.Bullets9mm", "ModName.Bullet_9mm"},
        special = {"ModName.Bullet_9mm_HP", "ModName.Bullet_9mm_AP"},
        magazines = {"Base.9mmClip", "ModName.Magazine_9mm_Extended"},
        incompatible = {"ModName.Bullet_Incendiary"}, -- Incompatible con 9mm
    },
    ["556"] = {
        standard = {"Base.556Bullets", "ModName.Bullet_556"},
        special = {"ModName.Bullet_Incendiary", "ModName.Bullet_AP"},
        magazines = {"Base.556Clip", "ModName.Magazine_Drum_556"},
        incompatible = {},
    },
    ["shotgun"] = {
        standard = {"Base.ShotgunShells"},
        special = {"ModName.Shell_Slug", "ModName.Shell_Dragon"},
        magazines = {}, -- Shotguns no usan cargadores
        incompatible = {"ModName.Bullet_Tranquilizer"},
    },
    ["dart"] = {
        standard = {"ModName.Bullet_Tranquilizer"},
        special = {"ModName.Dart_Poison", "ModName.Dart_Paralysis"},
        magazines = {"ModName.DartCartridge"},
        weaponsOnly = {"ModName.DartGun", "ModName.TranqRifle"},
    },
}

-- Verificar compatibilidad antes de cargar
function WeaponCompatibility.canLoadAmmo(weapon, ammo)
    local weaponType = weapon:getAmmoType() or weapon:getFullType()
    local ammoType = ammo:getFullType()
    
    -- Buscar configuración para el tipo de arma
    for gunType, config in pairs(WeaponCompatibility.ammoTypes) do
        if weaponType:contains(gunType) then
            -- Verificar si la munición es compatible
            local isStandard = tbl_contains(config.standard, ammoType)
            local isSpecial = tbl_contains(config.special, ammoType)
            local isIncompatible = tbl_contains(config.incompatible, ammoType)
            
            if isIncompatible then
                return false, "Incompatible ammunition type"
            end
            
            if isStandard or isSpecial then
                return true, nil
            end
        end
    end
    
    return false, "Unknown ammunition type"
end

-- Hook para interceptar carga de munición
local originalLoadMagazine = ISInventoryPane.loadMagazine
ISInventoryPane.loadMagazine = function(self, magazine, ammo, player)
    local weapon = player:getPrimaryHandItem()
    if weapon and weapon:isRanged() then
        local canLoad, reason = WeaponCompatibility.canLoadAmmo(weapon, ammo)
        
        if not canLoad then
            player:Say("This ammo won't work with this weapon: " .. reason)
            return
        end
    end
    
    return originalLoadMagazine(self, magazine, ammo, player)
end
```

---

## 6. SISTEMA DE CRAFTING DE MUNICIÓN

### 6.1 Recetas de Munición Básica
```text
recipe Craft_ModName_Bullet_9mm
{
    OnCreate = Recipe.OnCreate.CraftAmmo9mm,
    
    Result: ModName.Bullet_9mm = 10,
    
    # Ingredientes
    Lead = 1,
    Gunpowder = 1,
    BrassCasing_9mm = 10,
    Primer = 10,
    
    # Herramientas
    keep Hammer,
    keep ModName.ReloadingPress,
    keep ModName.BulletMold_9mm,
    
    # Requisitos
    Skills: Metalworking:4;Engineering:2,
    Time: 60,
    Category: Weapons,
    Sound: MetalworkHammer,
}

recipe Craft_ModName_Bullet_Incendiary
{
    OnCreate = Recipe.OnCreate.CraftIncendiaryAmmo,
    
    Result: ModName.Bullet_Incendiary = 5,
    
    # Ingredientes especiales
    Lead = 1,
    Gunpowder = 2,
    BrassCasing_556 = 5,
    Primer = 5,
    WhitePhosphorus = 1,              # Ingrediente especial
    ChemicalIgniter = 1,              # Ingrediente especial
    
    # Herramientas especializadas
    keep ModName.ReloadingPress,
    keep ModName.ChemicalKit,
    keep ModName.SafetyEquipment,
    
    # Requisitos avanzados
    Skills: Metalworking:6;Engineering:5;Chemistry:4,
    Time: 180,
    Category: Weapons,
    Sound: ChemicalMixing,
    
    # Peligros
    DangerousRecipe = true,
    FailureChance = 0.05,             # 5% probabilidad de fallo
    OnFailure = Recipe.OnFailure.ChemicalExplosion,
}
```

### 6.2 Sistema de Fallos en Crafting
```lua
-- Script: ModName_CraftingFailures.lua
function Recipe.OnCreate.CraftAmmo9mm(craftRecipeData, character)
    local items = craftRecipeData:getAllCreatedItems()
    local ammo = items:get(0)
    
    if ammo then
        -- Calidad basada en skill
        local metalworking = character:getPerkLevel(Perks.Metalworking)
        local engineering = character:getPerkLevel(Perks.Engineering)
        
        local quality = (metalworking + engineering) / 20 -- 0.0 - 1.0
        
        -- Aplicar modificadores de calidad
        ammo:getModData().Quality = quality
        ammo:getModData().Reliability = math.min(1.0, quality + 0.2)
        
        -- Munición de baja calidad puede fallar
        if quality < 0.3 then
            ammo:getModData().JamChance = 0.1 -- 10% probabilidad de atasco
        elseif quality < 0.6 then
            ammo:getModData().JamChance = 0.03 -- 3% probabilidad
        else
            ammo:getModData().JamChance = 0.01 -- 1% probabilidad
        end
        
        -- Modificar propiedades según calidad
        if quality > 0.8 then
            -- Munición de alta calidad
            ammo:setName(ammo:getName() .. " (High Quality)")
            ammo:getModData().DamageBonus = 1.1
            ammo:getModData().AccuracyBonus = 1.05
        elseif quality < 0.4 then
            -- Munición de baja calidad
            ammo:setName(ammo:getName() .. " (Poor Quality)")
            ammo:getModData().DamageBonus = 0.9
            ammo:getModData().AccuracyBonus = 0.95
        end
    end
end

function Recipe.OnFailure.ChemicalExplosion(craftRecipeData, character)
    -- Explosión química al fallar crafting de munición incendiaria
    local x, y, z = character:getX(), character:getY(), character:getZ()
    
    -- Crear explosión
    IsoFireManager.StartFire(getCell(), character:getSquare(), true, 2000)
    
    -- Dañar al jugador
    local bodyDamage = character:getBodyDamage()
    bodyDamage:addDamage(BodyPartType.Hands, 20)
    bodyDamage:setBurning(true)
    bodyDamage:setBurnTime(15)
    
    -- Mensaje de error
    character:Say("The chemicals exploded!")
    
    -- Destruir algunos ingredientes
    character:getInventory():Remove("ChemicalIgniter")
    character:getInventory():Remove("WhitePhosphorus")
end
```

---

## 7. SISTEMA DE DISTRIBUCIÓN DE MUNICIÓN

### 7.1 Distribución Inteligente por Zona
```lua
-- Script: ModName_AmmoDistribution.lua
function ModName_AmmoDistribution()
    if not SandboxVars.ModName.AmmoSpawning then return end
    
    local multiplier = SandboxVars.ModName.AmmoSpawnRate or 1.0
    
    -- Munición estándar en tiendas civiles
    local standardAmmo = {
        {"ModName.Bullet_9mm", 0.3 * multiplier},
        {"ModName.Magazine_9mm_Extended", 0.15 * multiplier},
        {"Base.Bullets9mm", 0.5 * multiplier}, -- Vanilla también
    }
    
    -- Munición militar en bases/policía
    local militaryAmmo = {
        {"ModName.Bullet_AP", 0.1 * multiplier},
        {"ModName.Bullet_556", 0.4 * multiplier},
        {"ModName.Magazine_Drum_556", 0.05 * multiplier},
    }
    
    -- Munición especial en laboratorios/instalaciones
    local specialAmmo = {
        {"ModName.Bullet_EMP", 0.02 * multiplier},
        {"ModName.Bullet_Tranquilizer", 0.03 * multiplier},
        {"ModName.Dart_Poison", 0.01 * multiplier},
    }
    
    -- Distribuir en zonas apropiadas
    distributeAmmoInZones("GunStoreAmmunition", standardAmmo)
    distributeAmmoInZones("GunStoreShelf", standardAmmo)
    
    distributeAmmoInZones("PoliceLockers", militaryAmmo)
    distributeAmmoInZones("ArmyStorageAmmo", militaryAmmo)
    
    distributeAmmoInZones("LaboratoryStorage", specialAmmo)
    distributeAmmoInZones("ScienceStorage", specialAmmo)
end

function distributeAmmoInZones(zoneName, ammoList)
    local zone = ProceduralDistributions.list[zoneName]
    if not zone or not zone.items then return end
    
    for _, ammoData in ipairs(ammoList) do
        table.insert(zone.items, ammoData[1]) -- Item name
        table.insert(zone.items, ammoData[2]) -- Chance
    end
end

-- Registrar distribución
Events.OnInitGlobalModData.Add(ModName_AmmoDistribution)
```

### 7.2 Munición en Zombies con Armas
```lua
-- Lógica específica para munición en zombies armados
function ModName_ZombieAmmoLoot(zombie)
    if not SandboxVars.ModName.ZombieAmmo then return end
    
    local attachedItems = zombie:getAttachedItems()
    if not attachedItems or attachedItems:size() == 0 then return end
    
    local inv = zombie:getInventory()
    
    for i = 0, attachedItems:size() - 1 do
        local weapon = attachedItems:getItemByIndex(i)
        if weapon and instanceof(weapon, "HandWeapon") and weapon:isRanged() then
            addCompatibleAmmo(zombie, weapon, inv)
        end
    end
end

function addCompatibleAmmo(zombie, weapon, inv)
    local weaponType = weapon:getAmmoType() or weapon:getFullType()
    local ammoConfig = getAmmoConfigForWeapon(weaponType)
    
    if ammoConfig then
        -- Munición estándar (alta probabilidad)
        for _, standardAmmo in ipairs(ammoConfig.standard) do
            local amount = ZombRand(ammoConfig.bulletMin, ammoConfig.bulletMax + 1)
            for j = 1, amount do
                if ZombRand(100) < 80 then -- 80% probabilidad por bala
                    inv:AddItem(standardAmmo)
                end
            end
        end
        
        -- Munición especial (baja probabilidad)
        for _, specialAmmo in ipairs(ammoConfig.special) do
            local amount = ZombRand(1, 4)
            for j = 1, amount do
                if ZombRand(100) < 10 then -- 10% probabilidad por bala especial
                    inv:AddItem(specialAmmo)
                end
            end
        end
        
        -- Cargadores
        for _, magazine in ipairs(ammoConfig.magazines) do
            if ZombRand(100) < 25 then -- 25% probabilidad de cargador
                local mag = inv:AddItem(magazine)
                if mag and mag.setCurrentAmmoCount then
                    -- Cargador con munición aleatoria
                    local maxAmmo = mag:getMaxAmmo()
                    local currentAmmo = ZombRand(0, maxAmmo + 1)
                    mag:setCurrentAmmoCount(currentAmmo)
                end
            end
        end
    end
end

function getAmmoConfigForWeapon(weaponType)
    local configs = {
        ["Pistol"] = {
            standard = {"Base.Bullets9mm", "ModName.Bullet_9mm"},
            special = {"ModName.Bullet_9mm_HP"},
            magazines = {"Base.9mmClip", "ModName.Magazine_9mm_Extended"},
            bulletMin = 3, bulletMax = 15,
        },
        ["AssaultRifle"] = {
            standard = {"Base.556Bullets", "ModName.Bullet_556"},
            special = {"ModName.Bullet_Incendiary", "ModName.Bullet_AP"},
            magazines = {"Base.556Clip", "ModName.Magazine_Drum_556"},
            bulletMin = 8, bulletMax = 30,
        },
        ["DartGun"] = {
            standard = {"ModName.Bullet_Tranquilizer"},
            special = {"ModName.Dart_Poison", "ModName.Dart_Paralysis"},
            magazines = {"ModName.DartCartridge"},
            bulletMin = 2, bulletMax = 8,
        },
    }
    
    for weaponPattern, config in pairs(configs) do
        if weaponType:contains(weaponPattern) then
            return config
        end
    end
    
    return nil
end

-- Registrar para loot en zombies
Events.OnCreateLivingCharacter.Add(ModName_ZombieAmmoLoot)
```

---

## 8. SISTEMA DE BALÍSTICA AVANZADA

### 8.1 Modificadores Balísticos por Munición
```lua
-- Script: ModName_BallisticEffects.lua
local BallisticEffects = {}

-- Aplicar modificadores antes del disparo
function BallisticEffects.applyAmmoModifiers(weapon, ammo, attacker)
    local ammoType = ammo:getFullType()
    local modifiers = getAmmoModifiers(ammoType)
    
    if modifiers then
        -- Modificar propiedades temporalmente
        weapon:getModData().OriginalDamage = weapon:getMinDamage()
        weapon:getModData().OriginalRange = weapon:getMaxRange()
        weapon:getModData().OriginalAccuracy = weapon:getBaseAccuracy()
        
        -- Aplicar modificadores
        weapon:setMinDamage(weapon:getMinDamage() * modifiers.damage)
        weapon:setMaxDamage(weapon:getMaxDamage() * modifiers.damage)
        weapon:setMaxRange(weapon:getMaxRange() * modifiers.range)
        weapon:setBaseAccuracy(weapon:getBaseAccuracy() * modifiers.accuracy)
        
        -- Modificadores de sonido
        if modifiers.volumeModifier then
            weapon:getModData().VolumeModifier = modifiers.volumeModifier
        end
        
        -- Efectos especiales
        if modifiers.penetration then
            weapon:getModData().WallPenetration = modifiers.penetration
        end
        
        if modifiers.armorPiercing then
            weapon:getModData().ArmorPiercing = modifiers.armorPiercing
        end
    end
end

-- Restaurar propiedades después del disparo
function BallisticEffects.restoreWeaponStats(weapon)
    if weapon:getModData().OriginalDamage then
        weapon:setMinDamage(weapon:getModData().OriginalDamage)
        weapon:setMaxDamage(weapon:getModData().OriginalDamage * weapon:getDamageModifier())
        weapon:setMaxRange(weapon:getModData().OriginalRange)
        weapon:setBaseAccuracy(weapon:getModData().OriginalAccuracy)
        
        -- Limpiar modificadores temporales
        weapon:getModData().OriginalDamage = nil
        weapon:getModData().OriginalRange = nil
        weapon:getModData().OriginalAccuracy = nil
        weapon:getModData().VolumeModifier = nil
        weapon:getModData().WallPenetration = nil
        weapon:getModData().ArmorPiercing = nil
    end
end

function getAmmoModifiers(ammoType)
    local modifiers = {
        ["ModName.Bullet_AP"] = {
            damage = 0.85,              # Menos daño a flesh
            range = 1.3,                # Mayor alcance
            accuracy = 1.1,             # Mayor precisión
            penetration = 3,            # Atraviesa paredes
            armorPiercing = 0.9,        # 90% ignora armadura
            volumeModifier = 1.2,       # Más ruidoso
        },
        ["ModName.Bullet_Incendiary"] = {
            damage = 0.9,               # Menos daño directo
            range = 1.1,                # Poco más de alcance
            accuracy = 0.9,             # Menos precisión
            volumeModifier = 1.5,       # Mucho más ruidoso
            fireEffect = true,          # Causa fuego
            explosionRadius = 2,        # Radio de explosión
        },
        ["ModName.Bullet_Subsonic"] = {
            damage = 0.95,              # Poco menos daño
            range = 0.8,                # Menor alcance
            accuracy = 1.05,            # Poco más precisión
            volumeModifier = 0.3,       # Mucho más silencioso
            suppressedEffect = true,    # Efecto suprimido
        },
        ["ModName.Bullet_Tranquilizer"] = {
            damage = 0.1,               # Mínimo daño letal
            range = 0.7,                # Menor alcance
            accuracy = 0.8,             # Menos precisión
            nonLethal = true,           # No mata
            sedativeEffect = true,      # Efecto sedante
        },
    }
    
    return modifiers[ammoType]
end

-- Hooks para aplicar efectos
Events.OnWeaponSwing.Add(function(player, weapon)
    if weapon:isRanged() and weapon:getCurrentAmmo() then
        BallisticEffects.applyAmmoModifiers(weapon, weapon:getCurrentAmmo(), player)
    end
end)

Events.OnWeaponHitCharacter.Add(function(attacker, victim, weapon, damage)
    if weapon:isRanged() then
        BallisticEffects.restoreWeaponStats(weapon)
    end
end)
```

---

## 9. SISTEMA DE MANTENIMIENTO DE ARMAS

### 9.1 Degradación por Tipo de Munición
```lua
-- Munición que afecta durabilidad del arma
function updateWeaponConditionFromAmmo(weapon, ammo)
    local ammoType = ammo:getFullType()
    local degradationRates = {
        ["ModName.Bullet_AP"] = 1.5,           # Desgasta más el arma
        ["ModName.Bullet_Incendiary"] = 2.0,   # Mucho desgaste
        ["ModName.Bullet_Subsonic"] = 0.8,     # Menos desgaste
        ["Base.Bullets9mm"] = 1.0,             # Desgaste normal
    }
    
    local rate = degradationRates[ammoType] or 1.0
    local condition = weapon:getCondition()
    local maxCondition = weapon:getConditionMax()
    
    -- Aplicar degradación
    local degradation = (maxCondition * 0.001) * rate -- 0.1% por disparo base
    weapon:setCondition(math.max(0, condition - degradation))
    
    -- Advertir si el arma está muy dañada
    if condition < (maxCondition * 0.2) then
        local player = weapon:getContainer():getParent()
        if instanceof(player, "IsoPlayer") and ZombRand(100) < 20 then
            player:Say("This weapon is wearing out from the special ammo...")
        end
    end
end

-- Sistema de limpieza de armas
function cleanWeaponFromAmmoResidue(weapon, cleaningKit)
    local residue = weapon:getModData().AmmoResidue or 0
    
    if residue > 0 then
        -- Limpiar residuo químico
        weapon:getModData().AmmoResidue = math.max(0, residue - 50)
        
        -- Restaurar algo de condición
        local maxCondition = weapon:getConditionMax()
        local newCondition = math.min(maxCondition, weapon:getCondition() + (maxCondition * 0.1))
        weapon:setCondition(newCondition)
        
        -- Consumir kit de limpieza
        cleaningKit:Use()
        
        return true
    end
    
    return false
end
```

---

## 10. PATRONES PARA IA - GENERACIÓN AUTOMÁTICA

### 10.1 Template de Munición Personalizada
```lua
function generateCustomAmmo(ammoName, properties)
    local template = [[
item ]] .. properties.modName .. [[.]] .. ammoName .. [[
{
    DisplayName = ]] .. properties.displayName .. [[,
    DisplayCategory = Ammo,
    Type = Normal,
    Weight = ]] .. (properties.weight or 0.01) .. [[,
    Icon = ]] .. properties.modName .. [[_]] .. ammoName .. [[,
    WorldStaticModel = ]] .. properties.modName .. [[_]] .. ammoName .. [[,
    
    # Ballistic properties
    BulletType = ]] .. properties.caliber .. [[,
    BulletDamage = ]] .. (properties.damage or 1.0) .. [[,
    BulletPenetration = ]] .. (properties.penetration or 1.0) .. [[,
    BulletRange = ]] .. (properties.range or 1.0) .. [[,
    BulletAccuracy = ]] .. (properties.accuracy or 1.0) .. [[,
    
]]

    if properties.effects then
        for _, effect in ipairs(properties.effects) do
            template = template .. "    " .. effect .. ",\n"
        end
    end
    
    template = template .. [[
    
    StackSize = ]] .. (properties.stackSize or 100) .. [[,
    Tags = Ammo;]] .. properties.caliber .. [[;]] .. (properties.tags or "") .. [[,
}
]]

    -- Generar script de efectos si es necesario
    if properties.specialEffects then
        template = template .. generateAmmoEffectScript(ammoName, properties)
    end
    
    return template
end

-- Ejemplo de uso por IA
local exampleAmmo = generateCustomAmmo("Bullet_Lightning", {
    modName = "ThunderStrike",
    displayName = "Lightning Round",
    weight = 0.015,
    caliber = "9mm",
    damage = 1.5,
    range = 1.2,
    effects = {
        "BulletEffect = lightning",
        "ChainLightning = true",
        "EMPRadius = 3"
    },
    specialEffects = {
        onHit = "createLightningStrike",
        onMiss = "createGroundDischarge"
    },
    tags = "Lightning;Electric;Rare"
})
```

### 10.2 Checklist de Validación para IA
```
✅ VALIDACIÓN MUNICIÓN:
1. ✅ Definición de item con propiedades balísticas
2. ✅ Compatibilidad con armas específicas definida  
3. ✅ Texturas para bala, cargador y caja creadas
4. ✅ Efectos especiales implementados en Lua
5. ✅ Sonidos personalizados configurados
6. ✅ Distribución en zonas apropiadas
7. ✅ Recetas de crafting (si corresponde)
8. ✅ Sistema de degradación de arma
9. ✅ Manejo de fallos y seguridad
10. ✅ Balanceado con munición vanilla
```

---

*Esta documentación proporciona el sistema más completo para la creación de munición personalizada en Project Zomboid, desde balas básicas hasta munición exótica con efectos especiales.*