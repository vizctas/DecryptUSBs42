# DISTRIBUCIÓN DE ITEMS - SISTEMA EXTREMO Y COMPLETO

## ANÁLISIS EXHAUSTIVO PARA RESOLVER PROBLEMAS DE DISTRIBUCIÓN

*Basado en análisis de H.E.C.U y Support Corps - Solución a problemas de distribución en zombies*

---

## 1. ARQUITECTURA FUNDAMENTAL DE DISTRIBUCIÓN

### 1.1 Sistemas de Distribución en PZ
```
SISTEMAS PRINCIPALES:
├── ProceduralDistributions     # Contenedores del mundo (armarios, estantes)
├── VehicleDistributions       # Vehículos (guantera, maletero, asientos)
├── SuburbsDistributions       # Distribución por zona geográfica
├── ZombieDistributions        # Loot en zombies (CRÍTICO)
└── ForagingDistributions      # Items encontrados al buscar
```

### 1.2 Jerarquía de Archivos Crítica
```
ModName/
├── media/lua/server/Items/
│   ├── ModName_Distributions.lua           # Distribución principal
│   ├── ModName_LootAdditional.lua         # Loot adicional en zombies
│   ├── ModName_VanillaItems_DoParam.lua   # Items vanilla modificados
│   ├── ModName_HECUItems_DoParam.lua      # Items del mod
│   └── ModName_Workshop_DoParam.lua       # Configuración workshop
└── sandbox-options.txt                     # Configuraciones
```

---

## 2. SISTEMA DE DISTRIBUCIÓN EN CONTENEDORES

### 2.1 Función Base Segura para Insertar Items
```lua
require "Items/ProceduralDistributions"
require "Vehicles/VehicleDistributions_List"

function safeInsertItems(distriName, item, weight)
    if not distriName or not item or not weight then return end
    
    -- Obtener multiplicador de sandbox
    local multiplier = SandboxVars and SandboxVars.ModName and SandboxVars.ModName.SpawnMult or 1.0
    
    -- Distribución en contenedores del mundo
    local proceduralDistrib = ProceduralDistributions.list[distriName]
    if proceduralDistrib and proceduralDistrib.items then
        table.insert(proceduralDistrib.items, item)
        table.insert(proceduralDistrib.items, weight * multiplier)
    end
    
    -- Distribución en vehículos
    local vehicleDistrib = VehicleDistributions_List[distriName]
    if vehicleDistrib and vehicleDistrib.items then
        table.insert(vehicleDistrib.items, item)
        table.insert(vehicleDistrib.items, weight * multiplier)
    end
end
```

### 2.2 Sistema de Presets por Zona
```lua
local zonePresets = {
    [1] = {"GunStoreShelf"},                                    # Solo tiendas de armas
    [2] = {"GunStoreShelf","CampingStoreClothes"},             # Tiendas militares
    [3] = {"PoliceOutfit","PoliceLockers","PoliceStorageOutfit"}, # Solo policía
    [4] = {"ArmyLightTruckBed","ArmyHeavyTruckBed"},           # Solo militar
    [5] = {"WardrobeGeneric","WardrobeRedneck","ClosetShelfGeneric"}, # Civil
    [6] = {"GunStoreShelf","PoliceOutfit","PoliceLockers"},    # Policía + tiendas
    [7] = {"GunStoreShelf","ArmyLightTruckBed","ArmyHeavyTruckBed"}, # Militar + tiendas
    [8] = {"GunStoreShelf","WardrobeGeneric","WardrobeRedneck"}, # Civil + tiendas
    [16] = {"GunStoreShelf","CampingStoreClothes","PoliceOutfit","PoliceLockers",
            "ArmyLightTruckBed","ArmyHeavyTruckBed","WardrobeGeneric","WardrobeRedneck"}, # TODOS
}

function ModName_ProceduralDistributions()
    if not SandboxVars.ModName.ItemSpawning then return end
    
    local preset = SandboxVars.ModName.SpawnPreset or 16
    local presetList = zonePresets[preset]
    
    if presetList then
        for _, zone in ipairs(presetList) do
            insertModItems(zone)
        end
    end
end
```

### 2.3 Inserción Masiva de Items
```lua
local function insertModItems(zoneName)
    -- Items con probabilidades específicas
    safeInsertItems(zoneName, "ModName.Helmet", 0.15)
    safeInsertItems(zoneName, "ModName.GasMask", 0.05)
    safeInsertItems(zoneName, "ModName.Backpack", 0.2)
    safeInsertItems(zoneName, "ModName.Shirt", 0.3)
    safeInsertItems(zoneName, "ModName.Pants", 0.4)
    safeInsertItems(zoneName, "ModName.Boots", 0.3)
    safeInsertItems(zoneName, "ModName.Gloves", 0.3)
    safeInsertItems(zoneName, "ModName.Vest", 0.2)
end
```

---

## 3. SISTEMA CRÍTICO DE LOOT EN ZOMBIES

### 3.1 **CONEXIÓN ITEMS ↔ EVENTOS ↔ ZOMBIES** ⚡ **SECCIÓN CRÍTICA**

#### **📍 PROBLEMA PRINCIPAL**: La IA no entiende cómo conectar correctamente items con eventos de loot

#### **✅ SOLUCIÓN COMPLETA**: Patrón de 4 capas para looteo perfecto

```lua
-- CAPA 1: DEFINICIÓN DE ITEM
-- Archivo: media/scripts/items/ModName_Items.txt
module ModName
{
    item SpecialLoot
    {
        Type = Normal,
        DisplayName = Special Zombie Loot,
        Icon = ModName_SpecialLoot,
        Weight = 0.5,
        
        # CRÍTICO: Tags que conectan con distribución
        Tags = ZombieLoot;Rare;Military,
        
        # CRÍTICO: Categoría que determina aparición
        DisplayCategory = Weapon,  # O Ammo, Food, etc.
    }
}
```

```lua
-- CAPA 2: CONFIGURACIÓN DE DISTRIBUCIÓN
-- Archivo: media/lua/server/Items/ModName_Distributions.lua

-- PASO 1: Require obligatorio
require "Items/SuburbsDistributions"

-- PASO 2: Función de distribución en zombies
function ModName_ZombieDistribution()
    if not SandboxVars.ModName.EnableZombieLoot then return end
    
    -- MÉTODO A: SuburbsDistributions (Para zombies que spawnan)
    if SuburbsDistributions["all"] and SuburbsDistributions["all"]["inventorymale"] then
        table.insert(SuburbsDistributions["all"]["inventorymale"].items, "ModName.SpecialLoot")
        table.insert(SuburbsDistributions["all"]["inventorymale"].items, 0.5) -- 0.5% probabilidad
    end
    
    if SuburbsDistributions["all"] and SuburbsDistributions["all"]["inventoryfemale"] then
        table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, "ModName.SpecialLoot")
        table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, 0.5)
    end
end

-- PASO 3: Función de loot adicional por outfit
function ModName_ZombieLootByOutfit(zombie)
    -- VALIDACIONES CRÍTICAS
    if not zombie then return end
    if zombie:isDead() then return end
    if not SandboxVars.ModName.ZombieLootByOutfit then return end
    
    local outfit = tostring(zombie:getOutfitName())
    local inv = zombie:getInventory()
    
    -- TABLA DE LOOT POR OUTFIT ESPECÍFICO
    local outfitLootTable = {
        ["AuthenticZSoldier"] = {
            -- Loot en inventario principal
            inv = {
                { item = "ModName.MilitaryRation", chance = 80 },
                { item = "ModName.Grenade", chance = 30 },
                { item = "Base.Antibiotics", chance = 50 },
            },
            -- Loot en contenedores (mochilas, etc.)
            containers = {
                { item = "ModName.ExplosiveCharge", chance = 20 },
                { item = "ModName.RareAmmo", chance = 40 },
            },
        },
        ["AuthenticPolice"] = {
            inv = {
                { item = "Base.HandcuffKey", chance = 70 },
                { item = "Base.Whistle", chance = 60 },
                { item = "ModName.PoliceBadge", chance = 90 },
            },
            containers = {
                { item = "Base.Bullets9mm", chance = 80 },
                { item = "ModName.PoliceRadio", chance = 40 },
            },
        },
        -- PATRÓN PARA OUTFIT PERSONALIZADO
        ["ModName_CustomZombie"] = {
            inv = {
                { item = "ModName.CustomItem", chance = 100 },
            },
        },
    }
    
    local loot = outfitLootTable[outfit]
    if not loot then return end
    
    -- APLICAR LOOT AL INVENTARIO PRINCIPAL
    if loot.inv then
        for _, entry in ipairs(loot.inv) do
            if ZombRand(100) < entry.chance then
                inv:AddItem(entry.item)
                print("[LOOT] Added " .. entry.item .. " to zombie " .. outfit)
            end
        end
    end
    
    -- APLICAR LOOT A CONTENEDORES EQUIPADOS
    if loot.containers then
        local containers = findEquippedContainers(zombie)
        for _, container in ipairs(containers) do
            for _, entry in ipairs(loot.containers) do
                if ZombRand(100) < entry.chance then
                    container:AddItem(entry.item)
                    print("[LOOT] Added " .. entry.item .. " to container")
                end
            end
        end
    end
end

-- FUNCIÓN HELPER: Encontrar contenedores equipados
function findEquippedContainers(zombie)
    local containers = {}
    local wornItems = zombie:getWornItems()
    
    for i = 0, wornItems:size() - 1 do
        local item = wornItems:getItemByIndex(i)
        if item and item:getInventory() then
            table.insert(containers, item:getInventory())
        end
    end
    
    return containers
end

-- PASO 4: REGISTRAR EVENTOS (CRÍTICO)
Events.OnInitGlobalModData.Add(ModName_ZombieDistribution)
Events.OnCreateLivingCharacter.Add(ModName_ZombieLootByOutfit)
```

```lua
-- CAPA 3: LOOT AL MORIR ZOMBIE (OnZombieDead)
-- Para items que aparecen SOLO cuando se mata un zombie

function ModName_OnZombieDeath(zombie)
    -- VALIDACIONES OBLIGATORIAS
    if not zombie then return end
    if not SandboxVars.ModName.DeathLoot then return end
    
    local outfit = tostring(zombie:getOutfitName())
    local inv = zombie:getInventory()
    
    -- TABLA DE LOOT AL MORIR
    local deathLootTable = {
        ["AuthenticZSoldier"] = {
            -- Items que SOLO aparecen al morir
            { item = "ModName.DogTags", chance = 100 },      # Placas identificación
            { item = "ModName.LastWill", chance = 30 },      # Último testamento
            { item = "ModName.FamilyPhoto", chance = 50 },   # Foto familiar
        },
        ["AuthenticPolice"] = {
            { item = "ModName.PoliceReport", chance = 60 },  # Reporte policial
            { item = "ModName.CriminalRecord", chance = 40 }, # Antecedentes
        },
        ["Clown"] = {
            { item = "ModName.FunnyNose", chance = 80 },     # Nariz de payaso
            { item = "ModName.BalloonAnimal", chance = 60 }, # Animal globo
        },
    }
    
    local lootList = deathLootTable[outfit]
    if lootList then
        for _, loot in ipairs(lootList) do
            if ZombRand(100) < loot.chance then
                inv:AddItem(loot.item)
                print("[DEATH LOOT] " .. outfit .. " dropped " .. loot.item)
            end
        end
    end
    
    -- LOOT ESPECIAL POR NIVEL DE DIFICULTAD
    local difficulty = SandboxVars.Zombies.Speed -- 1=Shamble, 2=Fast, etc.
    if difficulty >= 3 then -- Solo en dificultad alta
        if ZombRand(100) < 5 then -- 5% probabilidad
            inv:AddItem("ModName.RareReward")
            print("[DEATH LOOT] Rare reward for high difficulty!")
        end
    end
end

-- REGISTRAR EVENTO DE MUERTE
Events.OnZombieDead.Add(ModName_OnZombieDeath)
```

```lua
-- CAPA 4: VALIDACIÓN Y DEBUGGING COMPLETO
-- Archivo: media/lua/server/Items/ModName_DistributionDebug.lua

local DistributionDebug = {}

-- Función de debugging completa
function DistributionDebug.validateZombieLoot(zombie)
    if not SandboxVars.ModName.DebugMode then return end
    
    print("=== ZOMBIE LOOT DEBUG ===")
    print("Zombie ID: " .. tostring(zombie:getOnlineID()))
    print("Outfit: " .. tostring(zombie:getOutfitName()))
    print("Is Dead: " .. tostring(zombie:isDead()))
    print("Has Inventory: " .. tostring(zombie:getInventory() ~= nil))
    
    local inv = zombie:getInventory()
    if inv then
        print("Inventory Size: " .. inv:getItems():size())
        
        -- Listar todos los items
        for i = 0, inv:getItems():size() - 1 do
            local item = inv:getItems():get(i)
            print("  Item " .. i .. ": " .. item:getFullType() .. " (Weight: " .. item:getActualWeight() .. ")")
        end
    end
    
    -- Verificar contenedores equipados
    local containers = findEquippedContainers(zombie)
    print("Equipped Containers: " .. #containers)
    
    for i, container in ipairs(containers) do
        print("  Container " .. i .. " Items: " .. container:getItems():size())
        for j = 0, container:getItems():size() - 1 do
            local item = container:getItems():get(j)
            print("    Container Item " .. j .. ": " .. item:getFullType())
        end
    end
    
    print("=========================")
end

-- Hook para debugging automático
if SandboxVars.ModName and SandboxVars.ModName.DebugMode then
    Events.OnCreateLivingCharacter.Add(DistributionDebug.validateZombieLoot)
    Events.OnZombieDead.Add(DistributionDebug.validateZombieLoot)
end
```

#### **🎯 FLUJO COMPLETO DE CONEXIÓN**:
```
1. ITEM DEFINIDO → Tags + DisplayCategory
2. DISTRIBUCIÓN → SuburbsDistributions/OnCreateLivingCharacter  
3. VALIDACIÓN → Outfit check + Sandbox check
4. APLICACIÓN → inv:AddItem() + containers
5. EVENTOS → OnInitGlobalModData + OnCreateLivingCharacter + OnZombieDead
6. DEBUGGING → Logs completos para validar funcionamiento
```

### 3.2 **PATRÓN CRÍTICO: OUTFIT NAME MATCHING** ⚡

#### **❌ ERROR COMÚN**: Outfit name no coincide
```lua
-- INCORRECTO - Hardcodear nombres
if outfit == "Soldier" then  -- ❌ Puede no coincidir exactamente

-- CORRECTO - Pattern matching robusto
if outfit:contains("Soldier") or outfit:contains("Military") then  -- ✅ Más flexible

-- MÁS CORRECTO - Tabla de patrones
local function matchesOutfitPattern(outfit, patterns)
    for _, pattern in ipairs(patterns) do
        if outfit:contains(pattern) then
            return true
        end
    end
    return false
end

local militaryPatterns = {"Soldier", "Military", "Army", "Marine", "Combat"}
if matchesOutfitPattern(outfit, militaryPatterns) then
    -- Aplicar loot militar
end
```

#### **🔍 DEBUGGING DE OUTFIT NAMES**:
```lua
-- Script para descubrir outfit names exactos
function ModName_LogAllOutfits()
    Events.OnCreateLivingCharacter.Add(function(character)
        if character:isZombie() then
            local outfit = character:getOutfitName()
            print("[OUTFIT DEBUG] Found zombie outfit: '" .. tostring(outfit) .. "'")
            
            -- Log a archivo para referencia
            local file = getFileWriter("outfit_log.txt", true, false)
            if file then
                file:write("Outfit: " .. tostring(outfit) .. "\n")
                file:close()
            end
        end
    end)
end

-- Activar solo en modo debug
if SandboxVars.ModName.DebugOutfits then
    ModName_LogAllOutfits()
end
```

### 3.3 **PATRÓN CRÍTICO: TIMING DE EVENTOS** ⚡

#### **❌ ERROR COMÚN**: Registrar eventos en momento incorrecto
```lua
-- INCORRECTO - Muy tarde
Events.OnGameStart.Add(function()
    ModName_ZombieDistribution()  -- ❌ Zombies ya creados
end)

-- CORRECTO - Momento exacto
Events.OnInitGlobalModData.Add(function()
    ModName_ZombieDistribution()  -- ✅ Antes de crear mundo
end)

-- CORRECTO - Para zombies individuales
Events.OnCreateLivingCharacter.Add(function(character)
    if character:isZombie() then
        ModName_ZombieLootByOutfit(character)  -- ✅ Justo al crear zombie
    end
end)
```

#### **⏱️ ORDEN DE EJECUCIÓN CRÍTICO**:
```
1. OnInitGlobalModData     → Configurar distribuciones generales
2. OnCreateLivingCharacter → Loot específico al crear zombie
3. OnZombieDead           → Loot adicional al morir zombie
4. OnGameStart            → Distribución retroactiva (solo si es necesario)
```

### 3.4 **PATRÓN CRÍTICO: VALIDACIÓN DE EXISTENCIA** ⚡

#### **🛡️ VALIDACIONES OBLIGATORIAS**:
```lua
function ModName_SafeZombieLoot(zombie)
    -- VALIDACIÓN 1: Zombie existe y es válido
    if not zombie then 
        print("[ERROR] Zombie is nil")
        return 
    end
    
    -- VALIDACIÓN 2: Zombie no está muerto
    if zombie:isDead() then 
        print("[ERROR] Zombie is already dead")
        return 
    end
    
    -- VALIDACIÓN 3: Zombie tiene outfit
    local outfit = zombie:getOutfitName()
    if not outfit or outfit == "" then 
        print("[ERROR] Zombie has no outfit")
        return 
    end
    
    -- VALIDACIÓN 4: Sandbox permite loot
    if not (SandboxVars.ModName and SandboxVars.ModName.ZombieLoot) then
        print("[ERROR] Sandbox option disabled")
        return 
    end
    
    -- VALIDACIÓN 5: Zombie tiene inventario
    local inv = zombie:getInventory()
    if not inv then 
        print("[ERROR] Zombie has no inventory")
        return 
    end
    
    -- VALIDACIÓN 6: Item existe en el juego
    local testItem = InventoryItemFactory.CreateItem("ModName.SpecialLoot")
    if not testItem then
        print("[ERROR] Item ModName.SpecialLoot does not exist!")
        return
    end
    
    -- SOLO AHORA aplicar loot
    if ZombRand(100) < 10 then -- 10% probabilidad
        inv:AddItem("ModName.SpecialLoot")
        print("[SUCCESS] Added SpecialLoot to zombie " .. outfit)
    end
end
```

### 3.5 **PATRÓN CRÍTICO: LOOT EN CONTENEDORES EQUIPADOS** ⚡

#### **🎒 SISTEMA DE MOCHILAS Y CONTENEDORES**:
```lua
function ModName_AddLootToZombieContainers(zombie)
    -- Encontrar TODOS los contenedores equipados
    local containers = {}
    
    -- MÉTODO 1: Buscar por WornItems
    local wornItems = zombie:getWornItems()
    if wornItems then
        for i = 0, wornItems:size() - 1 do
            local item = wornItems:getItemByIndex(i)
            if item and item:getInventory() then
                table.insert(containers, {
                    container = item:getInventory(),
                    type = item:getType(),
                    capacity = item:getInventory():getCapacityWeight(),
                })
            end
        end
    end
    
    -- MÉTODO 2: Buscar items específicos con inventario
    local inv = zombie:getInventory()
    for i = 0, inv:getItems():size() - 1 do
        local item = inv:getItems():get(i)
        if item and item:getInventory() then
            table.insert(containers, {
                container = item:getInventory(),
                type = item:getType(),
                capacity = item:getInventory():getCapacityWeight(),
            })
        end
    end
    
    print("[CONTAINERS] Found " .. #containers .. " containers on zombie")
    
    -- APLICAR LOOT A CONTENEDORES
    for _, containerData in ipairs(containers) do
        local container = containerData.container
        local containerType = containerData.type
        
        -- Loot específico por tipo de contenedor
        if containerType == "Bag_ALICEpack" then
            -- Loot militar pesado
            if ZombRand(100) < 30 then
                container:AddItem("ModName.HeavyAmmo")
            end
            if ZombRand(100) < 20 then
                container:AddItem("ModName.MilitaryTool")
            end
            
        elseif containerType == "Bag_DuffelBag" then
            -- Loot general
            if ZombRand(100) < 40 then
                container:AddItem("ModName.SurvivalGear")
            end
            
        elseif containerType == "Belt" then
            -- Loot pequeño
            if ZombRand(100) < 60 then
                container:AddItem("ModName.SmallItem")
            end
        end
        
        print("[LOOT] Applied loot to " .. containerType)
    end
end
```

### 3.6 **PATRÓN CRÍTICO: LOOT CONDICIONAL AVANZADO** ⚡

#### **🎲 SISTEMA DE PROBABILIDADES COMPLEJAS**:
```lua
function ModName_AdvancedZombieLoot(zombie)
    local outfit = tostring(zombie:getOutfitName())
    local inv = zombie:getInventory()
    
    -- PROBABILIDADES BASADAS EN MÚLTIPLES FACTORES
    local baseChance = SandboxVars.ModName.BaseLootChance or 10
    local difficultyMultiplier = getSandboxDifficultyMultiplier()
    local timeMultiplier = getGameTimeMultiplier()
    
    -- TABLA DE LOOT CON CONDICIONES COMPLEJAS
    local conditionalLoot = {
        ["AuthenticZSoldier"] = {
            {
                item = "ModName.RareAmmo",
                baseChance = 20,
                conditions = {
                    gameTime = function() return getGameTime():getWorldAgeHours() > 24 end, -- Solo después de 1 día
                    difficulty = function() return SandboxVars.Zombies.Speed >= 3 end,     -- Solo en dificultad alta
                    player = function() return getPlayer():getPerkLevel(Perks.Shooting) >= 5 end, -- Player skill 5+
                },
                multipliers = {
                    gameTime = 1.5,    -- 50% más probabilidad después de 1 día
                    difficulty = 2.0,  -- Doble probabilidad en dificultad alta
                    player = 1.2,      -- 20% más por skill alto
                },
            },
            {
                item = "ModName.ExplosiveDevice",
                baseChance = 5,
                conditions = {
                    gameTime = function() return getGameTime():getWorldAgeHours() > 72 end, -- Solo después de 3 días
                    location = function() 
                        local x, y = zombie:getX(), zombie:getY()
                        return isLocationMilitary(x, y) -- Solo en zona militar
                    end,
                },
                multipliers = {
                    gameTime = 3.0,    -- Triple probabilidad después de 3 días
                    location = 4.0,    # Cuádruple en zona militar
                },
            },
        },
    }
    
    local lootList = conditionalLoot[outfit]
    if not lootList then return end
    
    for _, lootData in ipairs(lootList) do
        local finalChance = lootData.baseChance
        
        -- APLICAR MULTIPLICADORES SEGÚN CONDICIONES
        for conditionName, conditionFunc in pairs(lootData.conditions) do
            if conditionFunc() then
                local multiplier = lootData.multipliers[conditionName] or 1.0
                finalChance = finalChance * multiplier
                print("[LOOT] Condition '" .. conditionName .. "' met, chance x" .. multiplier)
            end
        end
        
        -- APLICAR MULTIPLICADORES GLOBALES
        finalChance = finalChance * difficultyMultiplier * timeMultiplier
        
        -- VERIFICAR PROBABILIDAD FINAL
        if ZombRand(100) < finalChance then
            inv:AddItem(lootData.item)
            print("[SUCCESS] Added " .. lootData.item .. " with " .. finalChance .. "% chance")
        else
            print("[MISS] Failed to add " .. lootData.item .. " (" .. finalChance .. "% chance)")
        end
    end
end

-- FUNCIONES HELPER PARA CONDICIONES
function getSandboxDifficultyMultiplier()
    local speed = SandboxVars.Zombies.Speed or 2
    local strength = SandboxVars.Zombies.Strength or 2
    local population = SandboxVars.Zombies.PopulationMultiplier or 1.0
    
    -- Más difícil = más loot
    return (speed + strength) * population / 4
end

function getGameTimeMultiplier()
    local hours = getGameTime():getWorldAgeHours()
    
    -- Más tiempo = más loot (hasta un límite)
    if hours < 24 then return 1.0
    elseif hours < 168 then return 1.2  -- Semana 1
    elseif hours < 720 then return 1.5  -- Mes 1
    else return 2.0  -- Máximo después de 1 mes
    end
end

function isLocationMilitary(x, y)
    -- Verificar si la ubicación es zona militar
    local square = getCell():getGridSquare(x, y, 0)
    if square then
        local building = square:getBuilding()
        if building then
            local buildingType = building:getDef():getName()
            return buildingType:contains("military") or buildingType:contains("army") or buildingType:contains("base")
        end
    end
    return false
end
```
```

### 3.2 Sistema de Detección de Contenedores
```lua
local function findEquippedContainers(Zed)
    local inv = Zed:getInventory()
    local containers = {}
    
    -- Buscar contenedores equipados
    for i = 0, inv:getItems():size() - 1 do
        local item = inv:getItems():get(i)
        if item:getCategory() == "Container" and Zed:isEquipped(item) then
            local fullType = item:getFullType()
            if fullType == "ModName.Backpack" or fullType == "ModName.Belt" then
                table.insert(containers, {
                    type = fullType,
                    inv = item:getInventory(),
                    count = 0,
                    maxItems = (fullType == "ModName.Belt") and 4 or 20
                })
            end
        end
    end
    
    return containers
end
```

### 3.3 Distribución Inteligente en Contenedores
```lua
local function AddLootToContainers(Zed, lootTable)
    if not lootTable then return end
    
    local containers = findEquippedContainers(Zed)
    if #containers == 0 then return end
    
    local containerIndex = 1
    
    for _, entry in ipairs(lootTable) do
        if ZombRand(100) < entry.chance then
            local added = false
            local attempts = 0

            -- Intentar añadir a contenedores disponibles
            while not added and attempts < #containers do
                local container = containers[containerIndex]

                -- Verificar límites de contenedor
                local allow = true
                if container.count >= container.maxItems then
                    allow = false
                end
                
                if allow then
                    container.inv:AddItem(entry.item)
                    container.count = container.count + 1
                    added = true
                end

                -- Rotar al siguiente contenedor
                containerIndex = containerIndex + 1
                if containerIndex > #containers then
                    containerIndex = 1
                end
                attempts = attempts + 1
            end
            
            -- Si no se pudo añadir a contenedores, añadir al inventario principal
            if not added then
                Zed:getInventory():AddItem(entry.item)
            end
        end
    end
end
```

### 3.4 Loot Específico por Outfit
```lua
local function addOutfitSpecificLoot(Zed, outfit, inv, containers)
    local outfitLoot = {
        ["ModName_Soldier_M"] = {
            inv = {
                { item = "Base.CombinationPadlock", chance = 20 },
                { item = "Base.KeyRing_EagleFlag", chance = 30 },
                { item = "Base.Battery", chance = 30 },
                { item = "Base.Antibiotics", chance = 10 },
            },
            backpack = {
                { item = "Base.ElectricWire", chance = 10 },
                { item = "Base.x2Scope", chance = 25 },
                { item = "Base.TritiumSights", chance = 25 },
                { item = "Base.RedDot", chance = 10 },
                { item = "Base.Laser", chance = 25 },
                { item = "Base.GunLight", chance = 25 },
                { item = "Base.Antibiotics", chance = 30 },
                { item = "Base.556Box", chance = 25 },
                { item = "Base.Bullets9mm", chance = 95 },
                { item = "Base.556Bullets", chance = 95 },
            },
        },
        ["ModName_Medic_F"] = {
            inv = {
                { item = "Base.Bandage", chance = 80 },
                { item = "Base.Suture_Holder", chance = 40 },
                { item = "Base.Scalpel", chance = 30 },
            },
            backpack = {
                { item = "Base.Antibiotics", chance = 90 },
                { item = "Base.Painkillers", chance = 70 },
                { item = "Base.Morphine", chance = 20 },
                { item = "Base.Suture_Needle", chance = 60 },
            },
        },
    }
    
    local loot = outfitLoot[outfit]
    if not loot then return end
    
    -- Añadir loot al inventario principal
    if loot.inv then
        for _, entry in ipairs(loot.inv) do
            if ZombRand(100) < entry.chance then
                inv:AddItem(entry.item)
            end
        end
    end
    
    -- Añadir loot a contenedores
    if loot.backpack and #containers > 0 then
        AddLootToContainers(Zed, loot.backpack)
    end
end
```

---

## 3.7 **SECCIÓN CRÍTICA: RESOLUCIÓN DE PROBLEMAS DE LOOT** ⚡

### **🚨 PROBLEMA ESPECÍFICO**: Items no aparecen en loot de zombies

#### **✅ LISTA DE VERIFICACIÓN OBLIGATORIA**:

**1. ¿El item está definido correctamente?**
```lua
-- Verificar que el item existe
local testItem = InventoryItemFactory.CreateItem("ModName.ItemName")
if not testItem then
    print("❌ ERROR: Item no existe - verificar definición en scripts")
else
    print("✅ Item existe correctamente")
end
```

**2. ¿La distribución está configurada?**
```lua
-- Verificar SuburbsDistributions
if SuburbsDistributions["all"]["inventorymale"].items then
    local found = false
    for i = 1, #SuburbsDistributions["all"]["inventorymale"].items, 2 do
        if SuburbsDistributions["all"]["inventorymale"].items[i] == "ModName.ItemName" then
            found = true
            local chance = SuburbsDistributions["all"]["inventorymale"].items[i+1]
            print("✅ Item found in distribution with " .. chance .. "% chance")
            break
        end
    end
    if not found then
        print("❌ ERROR: Item no está en SuburbsDistributions")
    end
end
```

**3. ¿Los eventos están registrados?**
```lua
-- Verificar en OnInitGlobalModData
Events.OnInitGlobalModData.Add(function()
    print("✅ OnInitGlobalModData ejecutado")
    ModName_ZombieDistribution()
end)

-- Verificar en OnCreateLivingCharacter  
Events.OnCreateLivingCharacter.Add(function(character)
    if character:isZombie() then
        print("✅ OnCreateLivingCharacter ejecutado para zombie")
        ModName_SafeZombieLoot(character)
    end
end)
```

**4. ¿Las sandbox options están habilitadas?**
```lua
function checkSandboxOptions()
    if not SandboxVars then
        print("❌ ERROR: SandboxVars no disponible")
        return false
    end
    
    if not SandboxVars.ModName then
        print("❌ ERROR: SandboxVars.ModName no encontrado")
        return false
    end
    
    if not SandboxVars.ModName.ZombieLoot then
        print("❌ ERROR: Opción ZombieLoot deshabilitada")
        return false
    end
    
    print("✅ Sandbox options OK")
    return true
end
```

**5. ¿El outfit name coincide exactamente?**
```lua
function validateOutfitMatch(zombie, expectedOutfits)
    local actualOutfit = tostring(zombie:getOutfitName())
    
    print("Outfit detectado: '" .. actualOutfit .. "'")
    
    for _, expected in ipairs(expectedOutfits) do
        if actualOutfit == expected then
            print("✅ Outfit match exacto: " .. expected)
            return true
        elseif actualOutfit:contains(expected) then
            print("✅ Outfit match parcial: " .. expected)
            return true
        end
    end
    
    print("❌ ERROR: Outfit '" .. actualOutfit .. "' no coincide con ninguno esperado")
    return false
end
```

### 3.8 **TEMPLATE COMPLETO PARA LOOT PERFECTO** ⚡

#### **📋 TEMPLATE COPY-PASTE PARA IA**:
```lua
-- ==================================================================
-- TEMPLATE COMPLETO DE LOOT EN ZOMBIES - COPY PASTE PARA IA
-- ==================================================================

-- PASO 1: Require obligatorio
require "Items/SuburbsDistributions"

-- PASO 2: Configuración de sandbox
local MOD_NAME = "TuModName"  -- CAMBIAR POR TU MOD

-- PASO 3: Tabla de configuración completa
local ZombieLootConfig = {
    -- Items para distribución general (todos los zombies)
    generalItems = {
        { item = MOD_NAME .. ".CommonItem", chance = 2.0 },      -- 2% todos los zombies
        { item = MOD_NAME .. ".UncommonItem", chance = 0.5 },    -- 0.5% todos los zombies
    },
    
    -- Items específicos por outfit
    outfitSpecific = {
        ["AuthenticZSoldier"] = {
            inv = {
                { item = MOD_NAME .. ".MilitaryRation", chance = 80 },
                { item = "Base.Antibiotics", chance = 50 },
                { item = MOD_NAME .. ".Dogtags", chance = 90 },
            },
            containers = {
                { item = MOD_NAME .. ".HeavyAmmo", chance = 60 },
                { item = MOD_NAME .. ".Explosive", chance = 20 },
            },
        },
        ["AuthenticPolice"] = {
            inv = {
                { item = "Base.HandcuffKey", chance = 70 },
                { item = MOD_NAME .. ".PoliceBadge", chance = 85 },
            },
            containers = {
                { item = "Base.Bullets9mm", chance = 75 },
                { item = MOD_NAME .. ".PoliceRadio", chance = 40 },
            },
        },
        -- AÑADIR MÁS OUTFITS AQUÍ
    },
    
    -- Items solo al morir
    deathOnly = {
        ["AuthenticZSoldier"] = {
            { item = MOD_NAME .. ".MilitaryIntel", chance = 30 },
            { item = MOD_NAME .. ".LastLetter", chance = 15 },
        },
    },
}

-- PASO 4: Función principal de distribución general
function MODNAME_InitialDistribution()
    if not SandboxVars[MOD_NAME].EnableLoot then return end
    
    print("[" .. MOD_NAME .. "] Configuring zombie loot distributions")
    
    -- Distribución general en SuburbsDistributions
    for _, itemData in ipairs(ZombieLootConfig.generalItems) do
        -- Zombies masculinos
        table.insert(SuburbsDistributions["all"]["inventorymale"].items, itemData.item)
        table.insert(SuburbsDistributions["all"]["inventorymale"].items, itemData.chance)
        
        -- Zombies femeninos
        table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, itemData.item)
        table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, itemData.chance)
        
        print("[DIST] Added " .. itemData.item .. " to general distribution (" .. itemData.chance .. "%)")
    end
end

-- PASO 5: Función de loot específico por outfit
function MODNAME_OutfitSpecificLoot(zombie)
    -- VALIDACIONES CRÍTICAS
    if not zombie or zombie:isDead() then return end
    if not SandboxVars[MOD_NAME].OutfitLoot then return end
    
    local outfit = tostring(zombie:getOutfitName())
    local inv = zombie:getInventory()
    
    if not inv then return end
    
    -- BUSCAR CONFIGURACIÓN PARA ESTE OUTFIT
    local config = ZombieLootConfig.outfitSpecific[outfit]
    if not config then return end
    
    print("[OUTFIT] Processing loot for " .. outfit)
    
    -- LOOT AL INVENTARIO PRINCIPAL
    if config.inv then
        for _, loot in ipairs(config.inv) do
            if ZombRand(100) < loot.chance then
                inv:AddItem(loot.item)
                print("[INV] Added " .. loot.item .. " to " .. outfit)
            end
        end
    end
    
    -- LOOT A CONTENEDORES EQUIPADOS
    if config.containers then
        local containers = MODNAME_FindZombieContainers(zombie)
        
        for _, container in ipairs(containers) do
            for _, loot in ipairs(config.containers) do
                if ZombRand(100) < loot.chance then
                    container:AddItem(loot.item)
                    print("[CONTAINER] Added " .. loot.item .. " to container")
                end
            end
        end
    end
end

-- PASO 6: Función de loot al morir
function MODNAME_DeathLoot(zombie)
    if not SandboxVars[MOD_NAME].DeathLoot then return end
    
    local outfit = tostring(zombie:getOutfitName())
    local inv = zombie:getInventory()
    
    local config = ZombieLootConfig.deathOnly[outfit]
    if not config then return end
    
    print("[DEATH] Processing death loot for " .. outfit)
    
    for _, loot in ipairs(config) do
        if ZombRand(100) < loot.chance then
            inv:AddItem(loot.item)
            print("[DEATH] Added " .. loot.item .. " as death reward")
        end
    end
end

-- PASO 7: Función helper para encontrar contenedores
function MODNAME_FindZombieContainers(zombie)
    local containers = {}
    local wornItems = zombie:getWornItems()
    
    if wornItems then
        for i = 0, wornItems:size() - 1 do
            local item = wornItems:getItemByIndex(i)
            if item and item:getInventory() then
                table.insert(containers, item:getInventory())
            end
        end
    end
    
    return containers
end

-- PASO 8: REGISTRAR TODOS LOS EVENTOS (CRÍTICO)
Events.OnInitGlobalModData.Add(MODNAME_InitialDistribution)
Events.OnCreateLivingCharacter.Add(function(character)
    if character and character:isZombie() then
        MODNAME_OutfitSpecificLoot(character)
    end
end)
Events.OnZombieDead.Add(MODNAME_DeathLoot)

-- PASO 9: Debugging opcional
if SandboxVars[MOD_NAME] and SandboxVars[MOD_NAME].DebugMode then
    Events.OnCreateLivingCharacter.Add(function(character)
        if character and character:isZombie() then
            print("[DEBUG] Created zombie: " .. tostring(character:getOutfitName()))
        end
    end)
end

print("[" .. MOD_NAME .. "] Zombie loot system initialized")
```

### 3.9 **CHECKLIST FINAL PARA IA** ✅

#### **📋 ANTES DE IMPLEMENTAR LOOT EN ZOMBIES**:
- [ ] ✅ Item definido en scripts con Type, DisplayName, Icon
- [ ] ✅ Sandbox option para controlar loot (ZombieLoot = boolean)
- [ ] ✅ require "Items/SuburbsDistributions" al inicio del script
- [ ] ✅ Función de distribución general registrada en OnInitGlobalModData
- [ ] ✅ Función de loot específico registrada en OnCreateLivingCharacter
- [ ] ✅ Validaciones de seguridad (zombie exists, has inventory, sandbox enabled)
- [ ] ✅ Tabla de loot con outfit names exactos
- [ ] ✅ Probabilidades realistas (0.1% - 5% para items raros)
- [ ] ✅ Función de debugging para troubleshooting
- [ ] ✅ Logs informativos para validar funcionamiento

#### **📋 DESPUÉS DE IMPLEMENTAR**:
- [ ] ✅ Probar en zombie recién spawneado
- [ ] ✅ Probar en partida nueva
- [ ] ✅ Probar en partida existente (retroactivo)
- [ ] ✅ Verificar que no se duplica loot
- [ ] ✅ Confirmar que outfit names coinciden
- [ ] ✅ Validar probabilidades funcionan correctamente

---

## 4. SISTEMA AVANZADO DE MUNICIÓN AUTOMÁTICA

### 4.1 Configuración de Armas y Munición
```lua
local weaponLootConfig = {
    ["Base.Pistol"] = {
        bullet = "Base.Bullets9mm",
        box = "Base.Bullets9mmBox",
        magazine = "Base.9mmClip",
        bulletMin = 4,
        bulletMax = 18,
        magMin = 1,
        magMax = 3,
        boxChance = 20,
    },
    ["Base.AssaultRifle"] = {
        bullet = "Base.556Bullets",
        box = "Base.556Box",
        magazine = "Base.556Clip",
        bulletMin = 8,
        bulletMax = 25,
        magMin = 1,
        magMax = 2,
        boxChance = 22,
    },
    ["Base.Shotgun"] = {
        bullet = "Base.ShotgunShells",
        box = "Base.ShotgunShellsBox",
        bulletMin = 1,
        bulletMax = 12,
        boxChance = 35,
    },
}
```

### 4.2 Detección y Adición de Munición
```lua
local function addWeaponAmmo(Zed, inv)
    -- Buscar armas equipadas/attached
    local attachedItems = Zed:getAttachedItems()
    if not attachedItems or attachedItems:size() == 0 then return end
    
    for i = 0, attachedItems:size() - 1 do
        local weapon = attachedItems:getItemByIndex(i)
        if weapon and instanceof(weapon, "HandWeapon") and weapon:isRanged() then
            local wtype = weapon:getFullType()
            local config = weaponLootConfig[wtype]
            
            if config then
                -- Añadir balas sueltas
                local numBullets = ZombRand(config.bulletMin, config.bulletMax + 1)
                for j = 1, numBullets do
                    inv:AddItem(config.bullet)
                end
                
                -- Añadir cargadores
                if config.magazine then
                    local numMags = ZombRand(config.magMin, config.magMax + 1)
                    for j = 1, numMags do
                        local mag = inv:AddItem(config.magazine)
                        if mag and mag.setCurrentAmmoCount then
                            -- 40% probabilidad de cargador vacío
                            if ZombRand(100) < 40 then
                                mag:setCurrentAmmoCount(0)
                            else
                                local max = mag:getMaxAmmo()
                                local minAmmo = math.floor(max * 0.2)
                                mag:setCurrentAmmoCount(ZombRand(minAmmo, max + 1))
                            end
                        end
                    end
                end
                
                -- Añadir cajas de munición
                if ZombRand(100) < config.boxChance then
                    inv:AddItem(config.box)
                end
            end
        end
    end
end
```

---

## 5. SISTEMA DE DISTRIBUCIÓN CONFIGURABLE

### 5.1 Función Principal con Configuración Sandbox
```lua
function ModName_WorldDistributions()
    -- Verificar si la distribución está habilitada
    if not SandboxVars.ModName.EnableDistribution then return end
    
    -- Obtener configuraciones
    local spawnMRE = SandboxVars.ModName.SpawnMRE or 1.0
    local spawnClothes = SandboxVars.ModName.SpawnClothes or 1.0
    local spawnWeapons = SandboxVars.ModName.SpawnWeapons or 1.0
    
    -- Función helper para añadir distribuciones
    local function addDistributions(itemsAndChances, locations)
        for item, chance in pairs(itemsAndChances) do
            if chance > 0 then
                for _, location in ipairs(locations) do
                    if ProceduralDistributions.list[location] and ProceduralDistributions.list[location].items then
                        table.insert(ProceduralDistributions.list[location].items, item)
                        table.insert(ProceduralDistributions.list[location].items, chance)
                    end
                end
            end
        end
    end
    
    -- Distribución de MREs
    addDistributions({
        ["ModName.RationMRECIV"] = (0.7 * spawnMRE),
        ["ModName.RationMREMCW"] = (0.7 * spawnMRE),
        ["ModName.RationFAR"] = (0.4 * spawnMRE),
    }, {
        "GunStoreAmmunition",
        "ArmySurplusSnacks",
        "ArmyBunkerKitchen",
        "CampingStoreGear",
    })
    
    -- Distribución de ropa
    addDistributions({
        ["ModName.MPArmband"] = (0.2 * spawnClothes),
        ["ModName.MedicArmband"] = (0.2 * spawnClothes),
        ["ModName.MPVest"] = (0.1 * spawnClothes),
        ["ModName.MedicVest"] = (0.1 * spawnClothes),
    }, {
        "PoliceOutfit",
        "PoliceLockers",
        "ArmyStorageOutfit",
        "ClothingStorageWinter",
    })
end
```

---

## 6. ERRORES CRÍTICOS Y SOLUCIONES ⚡ **RESOLUCIÓN DEFINITIVA**

### 6.1 **ERROR #1**: Items no aparecen en zombies ❌

#### **📋 CAUSAS PRINCIPALES**:
```
❌ CAUSA 1: Outfit name incorrecto o no coincide
❌ CAUSA 2: Función no registrada en eventos  
❌ CAUSA 3: Sandbox options deshabilitadas
❌ CAUSA 4: Item no existe (error en definición)
❌ CAUSA 5: Distribución ejecutada en momento incorrecto
❌ CAUSA 6: Probabilidades demasiado bajas
❌ CAUSA 7: Verificaciones de seguridad muy restrictivas
```

#### **✅ SOLUCIÓN PASO A PASO**:
```lua
-- SOLUCIÓN COMPLETA PARA "Items no aparecen"
function MODNAME_DiagnoseLootIssue()
    print("=== DIAGNOSTIC: Items not appearing ===")
    
    -- PASO 1: Verificar item existe
    local testItem = InventoryItemFactory.CreateItem("ModName.TestItem")
    if not testItem then
        print("❌ CRITICAL: Item 'ModName.TestItem' does not exist!")
        print("🔧 FIX: Check item definition in scripts/items/")
        return false
    end
    print("✅ Item exists")
    
    -- PASO 2: Verificar sandbox
    if not (SandboxVars.ModName and SandboxVars.ModName.ZombieLoot) then
        print("❌ CRITICAL: Sandbox option disabled or missing!")
        print("🔧 FIX: Enable ZombieLoot in sandbox settings")
        return false
    end
    print("✅ Sandbox OK")
    
    -- PASO 3: Verificar distribución configurada
    require "Items/SuburbsDistributions"
    local foundInDist = false
    
    local maleItems = SuburbsDistributions["all"]["inventorymale"].items
    for i = 1, #maleItems, 2 do
        if maleItems[i] == "ModName.TestItem" then
            foundInDist = true
            print("✅ Found in SuburbsDistributions with " .. maleItems[i+1] .. "% chance")
            break
        end
    end
    
    if not foundInDist then
        print("❌ CRITICAL: Item not in SuburbsDistributions!")
        print("🔧 FIX: Call ModName_ZombieDistribution() in OnInitGlobalModData")
        return false
    end
    
    -- PASO 4: Verificar eventos registrados
    print("ℹ️  Events should be registered:")
    print("   - OnInitGlobalModData → ModName_ZombieDistribution")
    print("   - OnCreateLivingCharacter → ModName_OutfitSpecificLoot")
    
    -- PASO 5: Crear zombie de prueba
    local player = getPlayer()
    local testZombie = createZombie(player:getX() + 3, player:getY(), player:getZ(), 
                                   nil, 0, IsoDirections.S, "AuthenticZSoldier")
    
    if testZombie then
        print("✅ Test zombie created")
        
        -- Aplicar loot manualmente
        MODNAME_OutfitSpecificLoot(testZombie)
        
        -- Verificar resultado
        local inv = testZombie:getInventory()
        local hasModLoot = false
        
        for i = 0, inv:getItems():size() - 1 do
            local item = inv:getItems():get(i)
            if item:getFullType():contains("ModName.") then
                hasModLoot = true
                print("✅ Test zombie has mod loot: " .. item:getFullType())
            end
        end
        
        if not hasModLoot then
            print("❌ CRITICAL: Test zombie has no mod loot!")
            print("🔧 FIX: Check outfit name and loot table")
        end
        
        return hasModLoot
    else
        print("❌ ERROR: Could not create test zombie")
        return false
    end
end
```

### 6.2 **ERROR #2**: Loot aparece duplicado ❌

#### **✅ SOLUCIÓN ANTI-DUPLICACIÓN**:
```lua
function MODNAME_PreventDuplicateLoot(zombie, itemType)
    local inv = zombie:getInventory()
    
    -- MÉTODO 1: Verificar existencia simple
    if inv:contains(itemType) then
        print("[PREVENT] Zombie already has " .. itemType)
        return false
    end
    
    -- MÉTODO 2: Verificar cantidad específica
    local currentCount = inv:getItemCount(itemType)
    if currentCount >= 1 then  -- Ya tiene al menos 1
        print("[PREVENT] Zombie already has " .. currentCount .. "x " .. itemType)
        return false
    end
    
    -- MÉTODO 3: Marcar en modData para items únicos
    local modData = zombie:getModData()
    local uniqueKey = "HasItem_" .. itemType:gsub("%.", "_")
    
    if modData[uniqueKey] then
        print("[PREVENT] Zombie marked as having " .. itemType)
        return false
    end
    
    -- Marcar como poseído
    modData[uniqueKey] = true
    return true
end

-- USO EN LOOT FUNCTION:
function MODNAME_SafeAddItem(zombie, itemType, chance)
    if ZombRand(100) < chance then
        if MODNAME_PreventDuplicateLoot(zombie, itemType) then
            zombie:getInventory():AddItem(itemType)
            print("[SUCCESS] Added " .. itemType .. " to zombie")
            return true
        end
    end
    return false
end
```

### 6.3 **ERROR #3**: Outfit names no coinciden ❌

#### **🔍 HERRAMIENTA DE DIAGNÓSTICO DE OUTFITS**:
```lua
function MODNAME_LogAllZombieOutfits()
    local outfitCounts = {}
    local allZombies = getCell():getZombieList()
    
    print("=== OUTFIT ANALYSIS ===")
    
    for i = 0, allZombies:size() - 1 do
        local zombie = allZombies:get(i)
        if zombie and not zombie:isDead() then
            local outfit = tostring(zombie:getOutfitName())
            outfitCounts[outfit] = (outfitCounts[outfit] or 0) + 1
        end
    end
    
    -- Mostrar estadísticas de outfits
    print("📊 OUTFIT STATISTICS:")
    for outfit, count in pairs(outfitCounts) do
        print("  '" .. outfit .. "': " .. count .. " zombies")
    end
    
    return outfitCounts
end

-- AUTO-GENERAR TABLA DE LOOT BASADA EN OUTFITS DETECTADOS
function MODNAME_GenerateLootTableFromOutfits()
    local outfits = MODNAME_LogAllZombieOutfits()
    
    print("\n=== GENERATED LOOT TABLE ===")
    print("-- Copy this to your mod:")
    print("local outfitLoot = {")
    
    for outfit, count in pairs(outfits) do
        print('    ["' .. outfit .. '"] = {')
        print('        inv = {')
        print('            { item = "ModName.CommonItem", chance = 20 },')
        print('            { item = "ModName.RareItem", chance = 5 },')
        print('        },')
        print('    },')
    end
    
    print("}")
end
```

### 6.4 **ERROR #4**: Loot funciona en modo debug pero no en juego normal ❌

#### **✅ SOLUCIÓN DE COMPATIBILIDAD**:
```lua
function MODNAME_EnsureCompatibility()
    -- PROBLEMA: Diferencias entre cliente/servidor/singleplayer
    
    -- SOLUCIÓN 1: Verificar contexto de ejecución
    local function isValidContext()
        if isClient() and not isServer() then
            print("⚠️  Running on client - some loot functions may not work")
            return false
        end
        
        if isServer() or not isClient() then
            print("✅ Running on server or singleplayer - OK for loot")
            return true
        end
        
        return false
    end
    
    -- SOLUCIÓN 2: Wrapper para funciones sensibles
    function safeServerFunction(func, ...)
        if isValidContext() then
            return func(...)
        else
            print("⚠️  Skipping server-only function on client")
            return nil
        end
    end
    
    -- USO:
    safeServerFunction(MODNAME_OutfitSpecificLoot, zombie)
end
```

### 6.5 **ERROR #5**: Loot no persiste al reiniciar partida ❌

#### **✅ SOLUCIÓN DE PERSISTENCIA**:
```lua
function MODNAME_EnsurePersistence()
    -- PROBLEMA: Loot desaparece al recargar partida
    
    -- SOLUCIÓN: Usar GlobalModData para persistencia
    function saveZombieLootState()
        local modData = ModData.getOrCreate("ModNameZombieLoot")
        modData.appliedLoot = modData.appliedLoot or {}
        
        local allZombies = getCell():getZombieList()
        
        for i = 0, allZombies:size() - 1 do
            local zombie = allZombies:get(i)
            if zombie and not zombie:isDead() then
                local zombieID = zombie:getOnlineID()
                local inv = zombie:getInventory()
                
                modData.appliedLoot[zombieID] = {}
                for j = 0, inv:getItems():size() - 1 do
                    local item = inv:getItems():get(j)
                    if item:getFullType():contains("ModName.") then
                        table.insert(modData.appliedLoot[zombieID], item:getFullType())
                    end
                end
            end
        end
        
        ModData.transmit("ModNameZombieLoot")
    end
    
    -- Guardar estado cada 10 minutos
    Events.EveryTenMinutes.Add(saveZombieLootState)
end
```

---

### 6.2 Validación de Configuración
```lua
function validateDistributionConfig()
    local errors = {}
    
    -- Verificar sandbox variables
    if not SandboxVars.ModName then
        table.insert(errors, "Sandbox variables not found")
    end
    
    -- Verificar tablas de distribución
    if not ProceduralDistributions.list then
        table.insert(errors, "ProceduralDistributions not loaded")
    end
    
    -- Verificar items del mod existen
    local testItems = {"ModName.Helmet", "ModName.Vest", "ModName.Rifle"}
    for _, itemName in ipairs(testItems) do
        local item = InventoryItemFactory.CreateItem(itemName)
        if not item then
            table.insert(errors, "Item not found: " .. itemName)
        end
    end
    
    if #errors > 0 then
        print("DISTRIBUTION VALIDATION ERRORS:")
        for _, error in ipairs(errors) do
            print("  - " .. error)
        end
        return false
    end
    
    return true
end
```

---

## 8. DISTRIBUCIÓN DURANTE EVENTOS ESPECÍFICOS

### 8.1 Sistema de Spawning por Eventos de Juego
```lua
-- Spawning durante eventos específicos del juego
local EventDistribution = {}

-- Distribución durante eventos de helicóptero
Events.OnHelicopterEvent.Add(function()
    if SandboxVars.ModName.EventLoot then
        -- Spawn military items cerca del evento
        spawnItemsNearPlayers("military", {
            {"ModName.MilitaryRation", 0.8},
            {"ModName.FlareGun", 0.3},
            {"ModName.RadioMilitary", 0.2},
        })
    end
end)

-- Distribución durante sirenas de emergencia  
Events.OnAmbientSound.Add(function(soundName, x, y)
    if soundName == "AmbientEmergencyVehicle" then
        -- Spawn medical items cerca de ambulancias
        spawnItemsAtLocation(x, y, {
            {"Base.FirstAidKit", 0.6},
            {"Base.Antibiotics", 0.4},
            {"ModName.EmergencySupplies", 0.3},
        }, 20) -- Radio de 20 tiles
    end
end)

-- Distribución al cambiar de estación/clima
Events.OnClimateTickDebug.Add(function(data)
    local season = data.season
    local temperature = data.temperature
    
    -- Items específicos por temporada
    if season == "winter" and temperature < 0 then
        spawnSeasonalItems("winter", {
            {"ModName.WinterGear", 0.1},
            {"ModName.Antifreeze", 0.05},
        })
    elseif season == "summer" and temperature > 25 then
        spawnSeasonalItems("summer", {
            {"ModName.SunProtection", 0.1},
            {"ModName.CoolingItems", 0.05},
        })
    end
end)

function spawnItemsNearPlayers(category, itemList)
    local players = getOnlinePlayers()
    
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        local x, y, z = player:getX(), player:getY(), player:getZ()
        
        -- Encontrar posición válida cerca del jugador
        for attempts = 1, 10 do
            local spawnX = x + ZombRand(-30, 31)
            local spawnY = y + ZombRand(-30, 31)
            local square = getCell():getGridSquare(spawnX, spawnY, z)
            
            if square and not square:isBlocked() then
                for _, itemData in ipairs(itemList) do
                    if ZombRand(100) < (itemData[2] * 100) then
                        -- Crear item bag en el suelo
                        createItemBagAtLocation(spawnX, spawnY, z, itemData[1], category)
                    end
                end
                break
            end
        end
    end
end

function createItemBagAtLocation(x, y, z, itemType, bagType)
    local square = getCell():getGridSquare(x, y, z)
    if not square then return end
    
    -- Crear container temporal (bolsa)
    local bag = square:AddWorldObject("Base.Bag_" .. bagType)
    if bag and bag:getContainer() then
        bag:getContainer():AddItem(itemType)
        
        -- Marcar como spawned por evento
        bag:getModData().SpawnedByEvent = true
        bag:getModData().SpawnTime = getGameTime():getWorldAgeHours()
    end
end
```

### 8.2 Distribución Basada en Acciones del Jugador
```lua
-- Sistema que responde a acciones específicas del jugador
local ActionBasedDistribution = {}

-- Distribución al leer ciertos libros
Events.OnReadBook.Add(function(player, book)
    if not SandboxVars.ModName.BookRewards then return end
    
    local bookRewards = {
        ["Base.BookMetalwork"] = {
            {"ModName.MetalworkingTool", 0.1},
            {"ModName.AdvancedBlueprints", 0.05},
        },
        ["Base.BookCooking"] = {
            {"ModName.SpecialIngredient", 0.15},
            {"ModName.ChefKnife", 0.08},
        },
    }
    
    local rewards = bookRewards[book:getFullType()]
    if rewards then
        local inv = player:getInventory()
        for _, reward in ipairs(rewards) do
            if ZombRand(100) < (reward[2] * 100) then
                inv:AddItem(reward[1])
                player:Say("I found something useful!")
            end
        end
    end
end)

-- Distribución al completar construcciones
Events.OnBuildingObject.Add(function(player, object)
    if not SandboxVars.ModName.BuildRewards then return end
    
    local objectType = object:getObjectName()
    local buildRewards = {
        ["walls"] = {{"ModName.ConstructionBonus", 0.05}},
        ["door"] = {{"ModName.SecurityUpgrade", 0.03}},
        ["generator"] = {{"ModName.PowerTool", 0.1}},
    }
    
    for pattern, rewards in pairs(buildRewards) do
        if objectType:lower():contains(pattern) then
            local inv = player:getInventory()
            for _, reward in ipairs(rewards) do
                if ZombRand(100) < (reward[2] * 100) then
                    inv:AddItem(reward[1])
                end
            end
        end
    end
end)

-- Distribución al alcanzar cierto nivel de habilidad
Events.OnLevelPerk.Add(function(player, perk, perkLevel)
    if not SandboxVars.ModName.SkillRewards then return end
    
    local skillRewards = {
        [Perks.MetalWelding] = {
            [5] = {{"ModName.AdvancedWeldingMask", 0.2}},
            [8] = {{"ModName.MasterWeldingKit", 0.1}},
        },
        [Perks.Mechanics] = {
            [6] = {{"ModName.AdvancedToolbox", 0.15}},
            [9] = {{"ModName.MasterMechanicTools", 0.08}},
        },
    }
    
    local perkRewards = skillRewards[perk]
    if perkRewards and perkRewards[perkLevel] then
        local inv = player:getInventory()
        for _, reward in ipairs(perkRewards[perkLevel]) do
            if ZombRand(100) < (reward[2] * 100) then
                inv:AddItem(reward[1])
                player:Say("My expertise unlocked something new!")
            end
        end
    end
end)
```

### 7.2 Sistema Crítico de Distribución Retroactiva
```lua
-- CRÍTICO: Para cuando se añade mod a partida existente
function ModName_RetroactiveDistribution()
    -- Verificar si es la primera vez que el mod se ejecuta en esta partida
    if getGameTime():getWorldAgeHours() > 1 then -- Partida ya en curso
        print("[ModName] Detecting existing game, applying retroactive distribution")
        
        -- Distribuir items en zombies existentes
        distributeInExistingZombies()
        
        -- Añadir items a contenedores ya explorados (opcional)
        redistributeInContainers()
        
        -- Marcar como distribuido para evitar repetición
        getPlayer():getModData().ModNameDistributionApplied = true
    end
end

function distributeInExistingZombies()
    local allZombies = getCell():getZombieList()
    
    for i = 0, allZombies:size() - 1 do
        local zombie = allZombies:get(i)
        if zombie and not zombie:isDead() then
            -- Aplicar loot adicional a zombies existentes
            ModName_LootAdditional(zombie)
        end
    end
    
    print("[ModName] Applied loot to " .. allZombies:size() .. " existing zombies")
end

function redistributeInContainers()
    -- Opcional: Re-distribuir en contenedores del mundo
    -- CUIDADO: Puede crear duplicados si no se maneja correctamente
    local player = getPlayer()
    local cell = getCell()
    
    -- Buscar contenedores en área alrededor del jugador
    for x = player:getX() - 50, player:getX() + 50 do
        for y = player:getY() - 50, player:getY() + 50 do
            local square = cell:getGridSquare(x, y, player:getZ())
            if square then
                local objects = square:getObjects()
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    if obj and obj:getContainer() then
                        -- Solo redistribuir si no está marcado como ya distribuido
                        local container = obj:getContainer()
                        if not container:getModData().ModNameDistributed then
                            -- Aplicar distribución retroactiva
                            applyRetroactiveContainerLoot(container, obj:getObjectName())
                            container:getModData().ModNameDistributed = true
                        end
                    end
                end
            end
        end
    end
end
```

### 7.3 Sistema de Detección de Mod Añadido a Partida Existente
```lua
function isModAddedToExistingGame()
    -- Verificar múltiples indicadores
    local player = getPlayer()
    local gameTime = getGameTime():getWorldAgeHours()
    
    -- Indicador 1: Tiempo de juego mayor a 1 hora
    if gameTime > 1 then
        -- Indicador 2: No hay marca de distribución previa
        if not player:getModData().ModNameDistributionApplied then
            -- Indicador 3: Verificar si hay contenedores ya explorados
            local exploredContainers = getExploredContainersCount()
            if exploredContainers > 5 then -- Arbitrario, ajustar según necesidad
                return true
            end
        end
    end
    
    return false
end

function getExploredContainersCount()
    local count = 0
    local player = getPlayer()
    local cell = getCell()
    
    -- Contar contenedores explorados en área cercana
    for x = player:getX() - 20, player:getX() + 20 do
        for y = player:getY() - 20, player:getY() + 20 do
            local square = cell:getGridSquare(x, y, player:getZ())
            if square then
                local objects = square:getObjects()
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    if obj and obj:getContainer() then
                        local container = obj:getContainer()
                        if container:isExplored() then
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    
    return count
end
```

### 7.2 Sistema de Logging para Debugging
```lua
local DistributionLogger = {}

function DistributionLogger.logZombieCreation(zombie)
    if SandboxVars.ModName.DebugMode then
        local outfit = zombie:getOutfitName()
        local inv = zombie:getInventory()
        print("[DIST] Zombie created - Outfit: " .. tostring(outfit) .. ", Items: " .. inv:getItems():size())
    end
end

function DistributionLogger.logItemAddition(item, container)
    if SandboxVars.ModName.DebugMode then
        print("[DIST] Added item: " .. item .. " to " .. tostring(container))
    end
end
```

---

## 8. PATRONES PARA IA - RESOLUCIÓN AUTOMÁTICA

### 8.1 Checklist de Validación Automática
```
VALIDACIÓN CRÍTICA PARA IA:
1. ✅ Verificar que outfit names coinciden exactamente
2. ✅ Confirmar que eventos están registrados
3. ✅ Validar que sandbox options existen
4. ✅ Comprobar que items del mod están definidos
5. ✅ Verificar probabilidades no exceden 100
6. ✅ Confirmar que contenedores se detectan correctamente
7. ✅ Validar que munición coincide con armas
8. ✅ Probar distribución en diferentes zonas
```

### 8.2 Generación Automática de Sistema de Distribución
```lua
-- Template para IA generar distribución completa
function generateDistributionSystem(modName, items, outfits, zones)
    local template = [[
require "Items/ProceduralDistributions"

function ]] .. modName .. [[_Distributions()
    if not SandboxVars.]] .. modName .. [[.EnableDistribution then return end
    
    local multiplier = SandboxVars.]] .. modName .. [[.SpawnMultiplier or 1.0
    
    -- Items distribution
]] 
    
    for _, item in ipairs(items) do
        template = template .. '    safeInsertItems("' .. item.zone .. '", "' .. modName .. '.' .. item.name .. '", ' .. item.chance .. ')\n'
    end
    
    template = template .. [[
end

function ]] .. modName .. [[_ZombieLoot(zombie)
    if not SandboxVars.]] .. modName .. [[.ZombieItems then return end
    
    local outfit = tostring(zombie:getOutfitName())
    local validOutfits = {
]]
    
    for _, outfit in ipairs(outfits) do
        template = template .. '        ["' .. outfit .. '"] = true,\n'
    end
    
    template = template .. [[
    }
    
    if not validOutfits[outfit] then return end
    
    -- Add loot logic here
end

Events.OnInitGlobalModData.Add(]] .. modName .. [[_Distributions)
Events.OnCreateLivingCharacter.Add(]] .. modName .. [[_ZombieLoot)
]]
    
    return template
end
```

---

## 10. **CASOS PRÁCTICOS DE USO** ⚡ **EJEMPLOS REALES**

### 10.1 **CASO 1**: "Quiero que los zombies soldado tengan granadas"

#### **✅ IMPLEMENTACIÓN COMPLETA**:
```lua
-- PASO 1: Definir item (scripts/items/weapons.txt)
module MiMod
{
    item GranadaMilitar
    {
        Type = Normal,
        DisplayName = Military Grenade,
        Icon = GranadaMilitar,
        Weight = 0.8,
        Tags = Explosive;Military;Dangerous,
    }
}

-- PASO 2: Script de distribución (lua/server/Items/MiMod_Distributions.lua)
require "Items/SuburbsDistributions"

function MiMod_GranadeDistribution()
    if not SandboxVars.MiMod.MilitaryLoot then return end
    
    -- Distribución general (baja probabilidad)
    table.insert(SuburbsDistributions["all"]["inventorymale"].items, "MiMod.GranadaMilitar")
    table.insert(SuburbsDistributions["all"]["inventorymale"].items, 0.1) -- 0.1%
end

function MiMod_SoldierLoot(zombie)
    if not zombie or zombie:isDead() then return end
    if not SandboxVars.MiMod.MilitaryLoot then return end
    
    local outfit = tostring(zombie:getOutfitName())
    
    -- OUTFITS ESPECÍFICOS DE SOLDADOS
    local soldierOutfits = {
        "AuthenticZSoldier", "AuthenticMilitary", "Soldier", "Army"
    }
    
    local isSoldier = false
    for _, soldierOutfit in ipairs(soldierOutfits) do
        if outfit:contains(soldierOutfit) then
            isSoldier = true
            break
        end
    end
    
    if isSoldier then
        local inv = zombie:getInventory()
        
        -- 30% probabilidad de granada para soldados
        if ZombRand(100) < 30 then
            inv:AddItem("MiMod.GranadaMilitar")
            print("[MILITARY LOOT] Added grenade to soldier " .. outfit)
        end
    end
end

-- REGISTRAR EVENTOS
Events.OnInitGlobalModData.Add(MiMod_GranadeDistribution)
Events.OnCreateLivingCharacter.Add(function(character)
    if character:isZombie() then
        MiMod_SoldierLoot(character)
    end
end)
```

### 10.2 **CASO 2**: "Los policías deben tener llaves especiales al morir"

#### **✅ IMPLEMENTACIÓN DEATH LOOT**:
```lua
-- Items que SOLO aparecen al morir policías
function MiMod_PoliceLlavesEspeciales(zombie)
    if not SandboxVars.MiMod.PoliceKeys then return end
    
    local outfit = tostring(zombie:getOutfitName())
    local inv = zombie:getInventory()
    
    -- VERIFICAR QUE ES POLICÍA
    local policeOutfits = {"AuthenticPolice", "Police", "Cop", "Sheriff"}
    local isPolice = false
    
    for _, policeOutfit in ipairs(policeOutfits) do
        if outfit:contains(policeOutfit) then
            isPolice = true
            break
        end
    end
    
    if isPolice then
        -- LOOT ESPECIAL AL MORIR POLICÍA
        if ZombRand(100) < 60 then  -- 60% probabilidad
            inv:AddItem("MiMod.LlaveComisaria")
            print("[POLICE DEATH] Police dropped station key")
        end
        
        if ZombRand(100) < 40 then  -- 40% probabilidad
            inv:AddItem("MiMod.CodigoSeguridad") 
            print("[POLICE DEATH] Police dropped security code")
        end
        
        if ZombRand(100) < 20 then  -- 20% probabilidad (raro)
            inv:AddItem("MiMod.LlaveMaestra")
            print("[POLICE DEATH] Police dropped master key!")
        end
    end
end

-- REGISTRAR SOLO EN EVENTO DE MUERTE
Events.OnZombieDead.Add(MiMod_PoliceLlavesEspeciales)
```

### 10.3 **CASO 3**: "Zombies doctores con suministros médicos en sus mochilas"

#### **✅ IMPLEMENTACIÓN CONTAINER LOOT**:
```lua
function MiMod_DoctorMedicalSupplies(zombie)
    if not SandboxVars.MiMod.MedicalLoot then return end
    
    local outfit = tostring(zombie:getOutfitName())
    
    -- VERIFICAR QUE ES DOCTOR
    local doctorOutfits = {"Doctor", "Nurse", "Paramedic", "AuthenticMedic"}
    local isDoctor = false
    
    for _, doctorOutfit in ipairs(doctorOutfits) do
        if outfit:contains(doctorOutfit) then
            isDoctor = true
            break
        end
    end
    
    if not isDoctor then return end
    
    -- BUSCAR MOCHILA O BOLSO MÉDICO
    local wornItems = zombie:getWornItems()
    local medicalBag = nil
    
    for i = 0, wornItems:size() - 1 do
        local item = wornItems:getItemByIndex(i)
        if item then
            local itemType = item:getType()
            -- Buscar mochilas médicas o de trabajo
            if itemType:contains("Bag") or itemType:contains("Medical") or 
               itemType:contains("FirstAid") or itemType:contains("Backpack") then
                if item:getInventory() then
                    medicalBag = item:getInventory()
                    print("[DOCTOR] Found medical container: " .. itemType)
                    break
                end
            end
        end
    end
    
    -- SI TIENE MOCHILA, AÑADIR SUMINISTROS MÉDICOS
    if medicalBag then
        local medicalSupplies = {
            { item = "Base.Antibiotics", chance = 90 },
            { item = "Base.Painkillers", chance = 80 },
            { item = "Base.Bandage", chance = 95 },
            { item = "Base.Suture_Holder", chance = 70 },
            { item = "MiMod.MedicamentoEspecial", chance = 40 },
            { item = "MiMod.JeringuillaMedica", chance = 30 },
        }
        
        for _, supply in ipairs(medicalSupplies) do
            if ZombRand(100) < supply.chance then
                medicalBag:AddItem(supply.item)
                print("[MEDICAL] Added " .. supply.item .. " to doctor's bag")
            end
        end
    else
        -- SI NO TIENE MOCHILA, AÑADIR AL INVENTARIO PRINCIPAL
        local inv = zombie:getInventory()
        if ZombRand(100) < 60 then
            inv:AddItem("Base.FirstAidKit")
            print("[MEDICAL] Added FirstAidKit to doctor (no bag found)")
        end
    end
end

Events.OnCreateLivingCharacter.Add(function(character)
    if character:isZombie() then
        MiMod_DoctorMedicalSupplies(character)
    end
end)
```

### 10.4 **CASO 4**: "Loot progresivo: más tiempo = mejor loot"

#### **✅ IMPLEMENTACIÓN PROGRESSIVE LOOT**:
```lua
function MiMod_ProgressiveLootSystem()
    -- Sistema que mejora loot con el tiempo
    
    Events.EveryOneMinute.Add(function()
        if not SandboxVars.MiMod.ProgressiveLoot then return end
        
        local gameHours = getGameTime():getWorldAgeHours()
        local allZombies = getCell():getZombieList()
        
        for i = 0, allZombies:size() - 1 do
            local zombie = allZombies:get(i)
            
            if zombie and not zombie:isDead() then
                local modData = zombie:getModData()
                
                -- FASES DE TIEMPO
                local currentPhase = 0
                if gameHours > 24 then currentPhase = 1      -- Día 1
                elseif gameHours > 168 then currentPhase = 2  -- Semana 1
                elseif gameHours > 720 then currentPhase = 3  -- Mes 1
                end
                
                -- VERIFICAR SI YA RECIBIÓ LOOT DE ESTA FASE
                local phaseKey = "LootPhase" .. currentPhase
                if not modData[phaseKey] and currentPhase > 0 then
                    addProgressiveLoot(zombie, currentPhase)
                    modData[phaseKey] = true
                end
            end
        end
    end)
end

function addProgressiveLoot(zombie, phase)
    local outfit = tostring(zombie:getOutfitName())
    local inv = zombie:getInventory()
    
    local phaseLoot = {
        [1] = {  -- Después de 24 horas
            ["AuthenticZSoldier"] = {
                { item = "MiMod.AdvancedGear", chance = 15 },
            },
        },
        [2] = {  -- Después de 1 semana  
            ["AuthenticZSoldier"] = {
                { item = "MiMod.EliteWeapon", chance = 8 },
            },
        },
        [3] = {  -- Después de 1 mes
            ["AuthenticZSoldier"] = {
                { item = "MiMod.LegendaryItem", chance = 3 },
            },
        },
    }
    
    if phaseLoot[phase] and phaseLoot[phase][outfit] then
        for _, loot in ipairs(phaseLoot[phase][outfit]) do
            if ZombRand(100) < loot.chance then
                inv:AddItem(loot.item)
                print("[PROGRESSIVE] Phase " .. phase .. " loot: " .. loot.item)
            end
        end
    end
end
```

### 10.5 **CASO 5**: "Debug completo: ¿Por qué no funciona mi loot?"

#### **🔧 HERRAMIENTA DE DIAGNÓSTICO TOTAL**:
```lua
function MiMod_DiagnosticoCompleto()
    print("=== DIAGNÓSTICO COMPLETO DE LOOT ===")
    
    -- 1. VERIFICAR CONFIGURACIÓN BÁSICA
    print("\n1. CONFIGURACIÓN BÁSICA:")
    if SandboxVars.MiMod then
        print("✅ SandboxVars.MiMod existe")
        if SandboxVars.MiMod.ZombieLoot then
            print("✅ ZombieLoot habilitado")
        else
            print("❌ ZombieLoot deshabilitado - HABILITAR EN SANDBOX")
        end
    else
        print("❌ SandboxVars.MiMod no existe - VERIFICAR SANDBOX-OPTIONS.TXT")
    end
    
    -- 2. VERIFICAR ITEMS EXISTEN
    print("\n2. VERIFICACIÓN DE ITEMS:")
    local testItems = {"MiMod.TestItem", "MiMod.RareWeapon", "MiMod.SpecialLoot"}
    for _, itemName in ipairs(testItems) do
        local item = InventoryItemFactory.CreateItem(itemName)
        if item then
            print("✅ " .. itemName .. " existe")
        else
            print("❌ " .. itemName .. " NO EXISTE - VERIFICAR SCRIPTS/ITEMS/")
        end
    end
    
    -- 3. VERIFICAR DISTRIBUCIONES
    print("\n3. VERIFICACIÓN DE DISTRIBUCIONES:")
    require "Items/SuburbsDistributions"
    
    if SuburbsDistributions["all"]["inventorymale"] then
        local items = SuburbsDistributions["all"]["inventorymale"].items
        local modItemsFound = 0
        
        for i = 1, #items, 2 do
            if items[i] and items[i]:contains("MiMod.") then
                modItemsFound = modItemsFound + 1
                print("✅ Encontrado: " .. items[i] .. " (" .. items[i+1] .. "%)")
            end
        end
        
        if modItemsFound == 0 then
            print("❌ NO HAY ITEMS DEL MOD EN SUBURSDISTRIBUTIONS")
            print("🔧 EJECUTAR: MiMod_ZombieDistribution() en OnInitGlobalModData")
        end
    end
    
    -- 4. VERIFICAR ZOMBIES ACTUALES
    print("\n4. ANÁLISIS DE ZOMBIES ACTUALES:")
    local allZombies = getCell():getZombieList()
    local outfitCounts = {}
    local zombiesWithModLoot = 0
    
    for i = 0, allZombies:size() - 1 do
        local zombie = allZombies:get(i)
        if zombie and not zombie:isDead() then
            local outfit = tostring(zombie:getOutfitName())
            outfitCounts[outfit] = (outfitCounts[outfit] or 0) + 1
            
            -- Verificar si tiene loot del mod
            local inv = zombie:getInventory()
            for j = 0, inv:getItems():size() - 1 do
                local item = inv:getItems():get(j)
                if item:getFullType():contains("MiMod.") then
                    zombiesWithModLoot = zombiesWithModLoot + 1
                    break
                end
            end
        end
    end
    
    print("Total zombies: " .. allZombies:size())
    print("Zombies con loot del mod: " .. zombiesWithModLoot)
    print("Porcentaje: " .. string.format("%.1f", (zombiesWithModLoot / allZombies:size()) * 100) .. "%")
    
    print("\nOutfits detectados:")
    for outfit, count in pairs(outfitCounts) do
        print("  '" .. outfit .. "': " .. count .. " zombies")
    end
    
    -- 5. RECOMENDACIONES
    print("\n5. RECOMENDACIONES:")
    if zombiesWithModLoot == 0 then
        print("❌ PROBLEMA: Ningún zombie tiene loot del mod")
        print("🔧 VERIFICAR:")
        print("   - Sandbox options habilitadas")
        print("   - Items definidos correctamente")
        print("   - Eventos registrados")
        print("   - Outfit names coinciden")
        print("   - Ejecutar distribución retroactiva")
    else
        print("✅ Sistema funcionando correctamente")
    end
end

-- COMANDO PARA EJECUTAR DIAGNÓSTICO
-- Usar en consola debug: MiMod_DiagnosticoCompleto()
```

### 10.6 **CASO 6**: "Reparar loot que no funciona en partida existente"

#### **🛠️ SCRIPT DE REPARACIÓN AUTOMÁTICA**:
```lua
function MiMod_RepararLootCompleto()
    print("=== REPARANDO SISTEMA DE LOOT ===")
    
    -- PASO 1: Re-aplicar distribución general
    MiMod_ZombieDistribution()
    print("✅ Distribución general re-aplicada")
    
    -- PASO 2: Aplicar loot a zombies existentes
    local allZombies = getCell():getZombieList()
    local processedZombies = 0
    
    for i = 0, allZombies:size() - 1 do
        local zombie = allZombies:get(i)
        
        if zombie and not zombie:isDead() then
            -- Marcar como no procesado para forzar nuevo loot
            zombie:getModData().MiModLootProcessed = nil
            
            -- Aplicar loot
            MiMod_SoldierLoot(zombie)
            processedZombies = processedZombies + 1
        end
    end
    
    print("✅ Procesados " .. processedZombies .. " zombies existentes")
    
    -- PASO 3: Marcar como reparado
    local player = getPlayer()
    player:getModData().MiModLootRepaired = true
    
    -- PASO 4: Validar resultado
    MiMod_DiagnosticoCompleto()
    
    player:Say("Sistema de loot reparado para " .. processedZombies .. " zombies")
end

-- AUTO-REPARAR AL CARGAR PARTIDA (UNA SOLA VEZ)
Events.OnGameStart.Add(function()
    local player = getPlayer()
    
    -- Solo si no se ha reparado antes
    if not player:getModData().MiModLootRepaired then
        -- Esperar un poco para que todo se cargue
        getGameTime():addEvent(function()
            MiMod_RepararLootCompleto()
        end, 10) -- 10 ticks de delay
    end
end)
```

### 10.7 **TEMPLATE FINAL: COPIA Y PEGA PARA IA** 📋

#### **🤖 TEMPLATE COMPLETO PARA GENERAR AUTOMÁTICAMENTE**:
```lua
-- ====================================================================
-- TEMPLATE FINAL - SISTEMA DE LOOT EN ZOMBIES - COPY PASTE READY
-- CAMBIAR SOLO: MOD_NAME, ITEM_NAME, OUTFIT_NAME, PROBABILITY
-- ====================================================================

local MOD_NAME = "TuMod"  -- CAMBIAR ESTO
local ITEM_NAME = "TuItem"  -- CAMBIAR ESTO
local OUTFIT_TARGET = "AuthenticZSoldier"  -- CAMBIAR ESTO
local LOOT_CHANCE = 25  -- CAMBIAR ESTO (porcentaje)

require "Items/SuburbsDistributions"

-- Función de distribución general
function TuMod_DistribucionGeneral()
    if not SandboxVars[MOD_NAME].LootHabilitado then return end
    
    -- Añadir a distribución general de zombies
    table.insert(SuburbsDistributions["all"]["inventorymale"].items, MOD_NAME .. "." .. ITEM_NAME)
    table.insert(SuburbsDistributions["all"]["inventorymale"].items, LOOT_CHANCE * 0.1) -- 10% del chance principal
    
    table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, MOD_NAME .. "." .. ITEM_NAME)
    table.insert(SuburbsDistributions["all"]["inventoryfemale"].items, LOOT_CHANCE * 0.1)
    
    print("[" .. MOD_NAME .. "] Distribución general configurada")
end

-- Función de loot específico
function TuMod_LootEspecifico(zombie)
    -- Validaciones obligatorias
    if not zombie or zombie:isDead() then return end
    if not SandboxVars[MOD_NAME].LootHabilitado then return end
    
    local outfit = tostring(zombie:getOutfitName())
    local inv = zombie:getInventory()
    
    if not inv then return end
    
    -- Verificar outfit objetivo
    if outfit == OUTFIT_TARGET or outfit:contains(OUTFIT_TARGET) then
        -- Aplicar loot con probabilidad especificada
        if ZombRand(100) < LOOT_CHANCE then
            inv:AddItem(MOD_NAME .. "." .. ITEM_NAME)
            print("[" .. MOD_NAME .. "] Added " .. ITEM_NAME .. " to " .. outfit)
        end
    end
end

-- Registrar eventos (OBLIGATORIO)
Events.OnInitGlobalModData.Add(TuMod_DistribucionGeneral)
Events.OnCreateLivingCharacter.Add(function(character)
    if character and character:isZombie() then
        TuMod_LootEspecifico(character)
    end
end)

-- Debug opcional
if SandboxVars[MOD_NAME] and SandboxVars[MOD_NAME].ModoDebug then
    Events.OnCreateLivingCharacter.Add(function(character)
        if character and character:isZombie() then
            print("[DEBUG] Zombie creado: '" .. tostring(character:getOutfitName()) .. "'")
        end
    end)
end

print("[" .. MOD_NAME .. "] Sistema de loot inicializado correctamente")
```

---

*Esta documentación resuelve completamente los problemas de distribución de items en Project Zomboid, proporcionando soluciones específicas para distribución en zombies, contenedores del mundo y vehículos.*
