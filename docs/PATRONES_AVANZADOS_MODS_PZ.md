# PATRONES AVANZADOS DE CONSTRUCCIÓN DE MODS PZ

## ANÁLISIS DETALLADO POR CATEGORÍA DE MOD

---

## 1. MODS DE VEHÍCULOS - PATRÓN COMPLETO

### Estructura de Archivos Obligatoria
```
VehicleMod/
├── mod.info
├── media/
│   ├── scripts/vehicles/
│   │   ├── VehicleName.txt              # Definición principal
│   │   ├── VehicleName_models.txt       # Modelos 3D
│   │   ├── VehicleName_recipes.txt      # Recetas de crafting
│   │   ├── VehicleName_items.txt        # Items específicos
│   │   ├── VehicleName_dismantle.txt    # Desmantelamiento
│   │   └── template_*.txt               # Templates de partes
│   ├── textures/Vehicles/
│   ├── models_X/vehicles/
│   └── sound/vehicles/
```

### Patrón de Definición de Vehículo
```
module Base
{
    model VehicleNameBase
    {
        mesh = vehicles/VehicleMesh|part_name,
        shader = damn_vehicle_shader,
        static = TRUE,
        scale = 0.1,
    }
    
    vehicle VehicleName
    {
        mechanicType = 3,                    # Tipo de mecánica
        offRoadEfficiency = 0.75,            # Eficiencia off-road
        engineRepairLevel = 6,               # Nivel requerido para reparar
        playerDamageProtection = 0.9,        # Protección al jugador
        engineRPMType = firebird,            # Tipo de RPM del motor
        
        model
        {
            file = VehicleNameBase,
            scale = 0.9000,
            offset = 0.0000 0.4889 0.0000,
        }
        
        skin
        {
            texture = Vehicles/VehicleName_Shell,
        }
        
        # Definición de partes del vehículo
        part Engine
        {
            model EngineModel
            {
                file = VehicleNameEngine,
            }
        }
    }
}
```

### Sistema de Templates para Partes
Los mods de vehículos usan templates para definir partes intercambiables:
```
template part VehicleName_Hood
{
    model VehicleNameHood
    {
        file = VehicleNameHood,
    }
    
    lua
    {
        create = Vehicles.Create.Hood,
    }
}
```

---

## 2. MODS DE FRAMEWORK/UI - PATRÓN MODULAR

### Estructura Típica de Framework
```
FrameworkMod/
├── mod.info
├── media/
│   ├── lua/
│   │   ├── client/
│   │   │   ├── UI/                      # Componentes de UI
│   │   │   ├── Events/                  # Manejadores de eventos
│   │   │   └── Utils/                   # Utilidades
│   │   ├── server/
│   │   │   ├── Commands/                # Comandos del servidor
│   │   │   └── Network/                 # Comunicación red
│   │   └── shared/
│   │       ├── Config/                  # Configuraciones
│   │       └── Constants/               # Constantes
│   ├── ui/
│   └── textures/ui/
```

### Patrón de Inicialización de Framework
```lua
-- Framework principal
local FrameworkName = {}
FrameworkName.version = "1.0.0"
FrameworkName.modules = {}

-- Sistema de registro de módulos
function FrameworkName.registerModule(name, module)
    FrameworkName.modules[name] = module
    print("Registered module: " .. name)
end

-- Inicialización
function FrameworkName.init()
    for name, module in pairs(FrameworkName.modules) do
        if module.init then
            module.init()
        end
    end
end

Events.OnGameStart.Add(FrameworkName.init)
```

---

## 3. MODS DE ITEMS/BEBIDAS - PATRÓN EXTENSIVO

### Estructura de Items Complejos
```
module ModuleName
{
    imports
    {
        Base
    }
    
    item DrinkName
    {
        Type = Drainable,                    # Tipo bebible
        DisplayName = Display Name,
        Icon = DrinkIcon,
        Weight = 0.3,
        UseWhileEquipped = FALSE,
        UseDelta = 0.25,                     # Cantidad por uso
        
        # Propiedades de bebida
        ThirstChange = -20,                  # Reduce sed
        UnhappyChange = -5,                  # Reduce tristeza
        BoredomChange = -10,                 # Reduce aburrimiento
        
        # Efectos especiales
        CustomContextMenu = Drink,
        OnEat = DrinkScript.onDrink,         # Script personalizado
        
        # Propiedades físicas
        IsCookable = FALSE,
        MinutesToBurn = 0,
        MinutesToCook = 0,
        
        # Propiedades de contenedor
        ReplaceOnUse = EmptyBottle,          # Item resultante
        
        # Efectos de estado
        PoisonPower = 0,
        FatigueChange = -10,
        EnduranceChange = 5,
    }
}
```

### Script Lua para Efectos Personalizados
```lua
local DrinkScript = {}

function DrinkScript.onDrink(food, character, percent)
    -- Efectos inmediatos
    character:getStats():setThirst(character:getStats():getThirst() - 0.2)
    
    -- Efectos temporales con moodles
    character:getModData().energyBoost = true
    character:getModData().energyBoostTime = getGameTime():getWorldAgeHours() + 2
    
    -- Sonido
    character:playSound("DrinkSound")
end

Events.OnPlayerUpdate.Add(function(player)
    if player:getModData().energyBoost then
        local currentTime = getGameTime():getWorldAgeHours()
        if currentTime >= player:getModData().energyBoostTime then
            player:getModData().energyBoost = false
            player:getModData().energyBoostTime = nil
        else
            -- Aplicar efectos mientras dura el boost
            player:getStats():setEndurance(player:getStats():getEndurance() + 0.001)
        end
    end
end)
```

---

## 4. MODS DE ROPA - PATRÓN DE VESTIMENTA

### Definición de Ropa
```
module ModuleName
{
    item ClothingName
    {
        Type = Clothing,
        DisplayName = Clothing Display Name,
        ClothingItem = ClothingName,         # Referencia al modelo 3D
        BodyLocation = Torso,                # Parte del cuerpo
        Icon = ClothingIcon,
        
        # Propiedades físicas
        Weight = 1.2,
        Insulation = 0.5,                    # Aislamiento térmico
        WindResistance = 0.3,                # Resistencia al viento
        WaterResistance = 0.1,               # Resistencia al agua
        
        # Protección
        NeckProtection = 0.1,
        UpperTorsoProtection = 0.2,
        LowerTorsoProtection = 0.2,
        
        # Propiedades de juego
        RunSpeedModifier = 0.95,             # Modificador de velocidad
        CombatSpeedModifier = 0.98,          # Modificador de combate
        
        # Durabilidad
        ConditionLowerChanceOneIn = 500,     # Probabilidad de deterioro
        ConditionMax = 10,                   # Condición máxima
    }
}
```

---

## 5. MODS DE MAPAS - PATRÓN DE WORLDGEN

### Estructura de Mods de Mapa
```
MapMod/
├── mod.info
├── media/
│   ├── maps/                            # Archivos de mapa
│   │   └── MapName/
│   │       ├── worldmap.xml             # Configuración del mundo
│   │       ├── spawnpoints.lua          # Puntos de spawn
│   │       └── lots/                    # Lotes del mapa
│   ├── lua/server/
│   │   └── MapName_spawn.lua            # Lógica de spawn
│   └── textures/
│       └── worldmap/                    # Texturas del mapa mundial
```

### Configuración de Spawn Points
```lua
function addSpawnPoints()
    local spawnPoint = {
        x = 12345,
        y = 6789,
        z = 0,
        name = "SpawnPointName"
    }
    
    SpawnPoints.add(spawnPoint)
end

Events.OnInitWorld.Add(addSpawnPoints)
```

---

## 6. MODS DE ARMAS - PATRÓN DE COMBATE

### Definición de Arma
```
module ModuleName
{
    item WeaponName
    {
        Type = Weapon,
        DisplayName = Weapon Display Name,
        Icon = WeaponIcon,
        Weight = 2.5,
        
        # Propiedades de combate
        MinDamage = 1.2,                     # Daño mínimo
        MaxDamage = 2.8,                     # Daño máximo
        CriticalChance = 15,                 # Probabilidad crítico
        CritDmgMultiplier = 2.0,             # Multiplicador crítico
        
        # Propiedades físicas del arma
        MinRange = 0.61,                     # Rango mínimo
        MaxRange = 1.5,                      # Rango máximo
        WeaponSprite = WeaponSprite,         # Sprite del arma
        
        # Sonidos
        SwingSound = WeaponSwing,
        HitSound = WeaponHit,
        
        # Durabilidad
        ConditionLowerChanceOneIn = 30,
        ConditionMax = 15,
        
        # Categorías
        Categories = Weapon;Blade,
        SubCategory = Sword,
        
        # Animaciones
        SwingAnim = Bat,
        WeaponWeight = 2.5,
    }
}
```

---

## 7. SISTEMA DE TRADUCCIONES

### Estructura de Archivos de Traducción
```
media/lua/shared/Translate/
├── EN/                                  # Inglés
│   └── ItemName_EN.txt
├── ES/                                  # Español
│   └── ItemName_ES.txt
└── [Idioma]/
    └── ItemName_[Idioma].txt
```

### Formato de Archivo de Traducción
```
ItemName_EN = {
    ItemName_DisplayName = "Item Display Name",
    ItemName_Description = "Item description text",
    
    # Recetas
    Recipe_RecipeName = "Recipe Display Name",
    
    # Contexto de menú
    ContextMenu_ActionName = "Action Name",
    
    # Tooltips
    Tooltip_ItemName = "Tooltip text for item",
}
```

### Uso en Scripts Lua
```lua
-- Obtener texto traducido
local displayName = getText("ItemName_DisplayName")
local description = getText("ItemName_Description")

-- Usar en UI
local label = ISLabel:new(x, y, height, displayName, 1, 1, 1, 1, UIFont.Medium, true)
```

---

## 8. PATRONES DE OPTIMIZACIÓN Y RENDIMIENTO

### Carga Lazy de Recursos
```lua
local ResourceManager = {}
ResourceManager.cache = {}

function ResourceManager.getTexture(name)
    if not ResourceManager.cache[name] then
        ResourceManager.cache[name] = getTexture(name)
    end
    return ResourceManager.cache[name]
end
```

### Manejo Eficiente de Eventos
```lua
-- Evitar eventos que se ejecutan muy frecuentemente
local lastUpdate = 0
local UPDATE_INTERVAL = 60 -- Actualizar cada 60 ticks

Events.OnTick.Add(function()
    local currentTick = getGameTime():getMultiplier()
    if currentTick - lastUpdate >= UPDATE_INTERVAL then
        -- Lógica de actualización
        lastUpdate = currentTick
    end
end)
```

---

*Este documento complementa la guía principal con patrones específicos y avanzados para cada tipo de mod.*
