# SISTEMA COMPLETO DE VEHÍCULOS - PROJECT ZOMBOID

## ANÁLISIS EXHAUSTIVO DE MODS DE VEHÍCULOS

*Basado en análisis de 93 Ford Taurus, 87 Toyota MR2 y 93 Mazda RX-7*

---

## 1. ESTRUCTURA FUNDAMENTAL DE VEHÍCULOS

### 1.1 Jerarquía de Archivos Obligatoria
```
VehicleMod/
├── mod.info
├── 42.0/                                    # Versión específica B42
│   ├── icon.png
│   ├── preview.png
│   └── media/
│       ├── lua/                             # Scripts Lua opcionales
│       └── scripts/vehicles/
│           ├── VehicleName.txt              # Definición principal
│           ├── VehicleNameSHO.txt           # Variantes del vehículo
│           ├── VehicleNameWagon.txt         # Más variantes
│           ├── VehicleName_models.txt       # Modelos 3D
│           ├── VehicleName_recipes.txt      # Recetas de crafting
│           ├── VehicleName_vehiclesitems.txt # Items específicos
│           └── template_*.txt               # Templates de partes
└── common/                                  # Fallback versiones antiguas
    └── media/
```

### 1.2 Patrón de Nomenclatura Crítico
```
Archivo Principal:     93fordTaurus.txt
Variantes:            93fordTaurusSHO.txt, 93fordTaurusWagon.txt
Modelos:              93fordTaurus_models.txt
Recetas:              93fordTaurus_recipes.txt
Items:                93fordTaurus_vehiclesitems.txt
Templates:            template_TAU93_[parte].txt
```

---

## 2. DEFINICIÓN PRINCIPAL DEL VEHÍCULO

### 2.1 Estructura Base del Archivo Principal
```
module Base
{
    # Definición de modelos 3D
    model VehicleNameBase
    {
        mesh = vehicles/Vehicles_VehicleName_Body|part_name,
        shader = damn_vehicle_shader,
        scale = 0.1,
    }
    
    model VehicleNameInterior
    {
        mesh = vehicles/Vehicles_VehicleName_Body|interior_part,
        texture = Vehicles/Vehicles_VehicleName_Interior,
        shader = damn_wheel_shader,
        scale = 0.1,
    }
    
    # Definición principal del vehículo
    vehicle VehicleName
    {
        # Propiedades mecánicas
        mechanicType = 1,                    # Tipo de mecánica (1-3)
        offRoadEfficiency = 1.0,             # Eficiencia off-road (0.0-2.0)
        engineRepairLevel = 4,               # Nivel mecánica requerido
        playerDamageProtection = 1.1,        # Protección jugador
        
        # Modelo y escala
        model
        {
            file = VehicleNameBase,
            scale = 0.9000,
            offset = 0.0000 0.5222 -0.1444,
        }
        
        # Skins/Colores disponibles
        skin { texture = Vehicles/VehicleName_Shell_Color1, }
        skin { texture = Vehicles/VehicleName_Shell_Color2, }
        
        # Texturas de estado
        textureRust = Vehicles/VehicleName_Rust,
        textureMask = Vehicles/VehicleName_Mask,
        textureLights = Vehicles/VehicleName_Lights,
        textureDamage1Shell = Vehicles/VehicleName_Damage1,
        textureDamage2Shell = Vehicles/VehicleName_Damage2,
        textureShadow = Vehicles/VehicleName_Shadow,
        
        # Sistema de sonido
        sound
        {
            engine = VehicleEngineDefault,
            engineStart = VehicleEngineDefault,
            engineTurnOff = VehicleEngineDefault,
            horn = VehicleHornStandard,
            ignitionFail = VehicleIgnitionFailDefault,
        }
        
        # Propiedades físicas
        extents = 1.8000 1.2444 4.9333,     # Dimensiones físicas
        mass = 800,                          # Masa del vehículo
        physicsChassisShape = 1.8000 1.2444 4.9333,
        centerOfMassOffset = 0.0000 0.6222 0.0000,
        shadowExtents = 2.0875 4.7705,
        shadowOffset = 0.0000 -0.0143,
        
        # Propiedades del motor
        engineForce = 4165,                  # Fuerza del motor
        maxSpeed = 80f,                      # Velocidad máxima
        engineLoudness = 80,                 # Ruido del motor
        engineQuality = 82,                  # Calidad del motor
        brakingForce = 85,                   # Fuerza de frenado
        stoppingMovementForce = 4.0f,
        rollInfluence = 0.98f,
        
        # Sistema de dirección
        steeringIncrement = 0.04,
        steeringClamp = 0.3,
        
        # Suspensión
        suspensionStiffness = 40,
        suspensionCompression = 3.83,
        suspensionDamping = 2.88,
        maxSuspensionTravelCm = 10,
        suspensionRestLength = 0.20f,
        wheelFriction = 1.6f,
        
        # Salud del vehículo
        frontEndHealth = 205,
        rearEndHealth = 160,
        seats = 4,                           # Número de asientos
        
        # Definición de ruedas
        wheel FrontLeft
        {
            front = true,
            offset = 0.7444 -0.5222 1.5667,
            radius = 0.32f,
            width = 0.22f,
        }
        
        # Definición de asientos
        passenger FrontLeft
        {
            showPassenger = true,
            hasRoof = true,
            
            position inside
            {
                offset = 0.4111 -0.1333 0.2111,
                rotate = 0.0000 0.0000 0.0000,
            }
            
            position outside
            {
                offset = 1.3222 -0.8222 -0.2667,
                rotate = 0.0000 0.0000 0.0000,
                area = SeatFrontLeft,
            }
        }
        
        # Referencia a templates
        template = PassengerSeat4,
        template = TAU93Seats,
        template = TAU93Doors,
        template = TAU93Windows,
    }
}
```

---

## 3. SISTEMA DE TEMPLATES MODULAR

### 3.1 Patrón de Templates por Componente
Los vehículos usan un sistema modular de templates para cada tipo de parte:

```
template_TAU93_armor.txt      # Sistema de blindaje
template_TAU93_bumpers.txt    # Parachoques delantero/trasero
template_TAU93_doors.txt      # Puertas del vehículo
template_TAU93_hood.txt       # Capó del motor
template_TAU93_roofracks.txt  # Portaequipajes del techo
template_TAU93_seats.txt      # Sistema de asientos
template_TAU93_spareTire.txt  # Llanta de repuesto
template_TAU93_spoiler.txt    # Alerones aerodinámicos
template_TAU93_tires.txt      # Sistema de neumáticos
template_TAU93_trunk.txt      # Maletero
template_TAU93_trunkdoor.txt  # Puerta del maletero
template_TAU93_windows.txt    # Ventanas
template_TAU93_windshields.txt # Parabrisas
```

### 3.2 Estructura de Template de Asientos
```
module Base
{
    # Modelos 3D de cada asiento
    model VehicleNameSeatfl
    {
        mesh = vehicles/Vehicles_VehicleName_Body|seat_fl,
        texture = Vehicles/Vehicles_VehicleName_Interior,
        shader = damn_wheel_shader,
        scale = 0.1,
    }
    
    # Template del sistema de asientos
    template vehicle VehicleNameSeats
    {
        part SeatFrontLeft
        {
            model SeatFL
            {
                file = VehicleNameSeatfl,
                offset = 0 0 0,
                rotate = 0 0 0,
                scale = 1.0,
            }
            
            area = SeatFrontLeft,
            container
            {
                seat = FrontLeft,
            }
        }
        
        # Definición de parte intercambiable
        part SeatFront*
        {
            category = seat,
            itemType = Base.VehicleNameSeatFront,
            mechanicRequireKey = true,
            durability = 3,
            
            container
            {
                test = Vehicles.ContainerAccess.Seat,
            }
            
            # Proceso de instalación
            table install
            {
                items
                {
                    1
                    {
                        type = Base.Screwdriver,
                        count = 1,
                        keep = true,
                        equip = primary,
                    }
                }
                time = 300,
                skills = Mechanics:1,
                recipes = Intermediate Mechanics,
                test = Vehicles.InstallTest.Default,
            }
            
            # Proceso de desinstalación
            table uninstall
            {
                items
                {
                    1
                    {
                        type = Base.Screwdriver,
                        count = 1,
                        keep = true,
                        equip = primary,
                    }
                }
                time = 300,
                skills = Mechanics:1,
                recipes = Intermediate Mechanics,
                test = Vehicles.UninstallTest.Default,
                requireEmpty = true,
            }
            
            lua
            {
                create = Vehicles.Create.Default,
            }
        }
    }
}
```

---

## 4. SISTEMA DE SPAWN Y DISTRIBUCIÓN

### 4.1 Spawn Points de Vehículos
Los vehículos se spawnean usando el sistema de distribución de PZ:

```lua
-- En archivo Lua de distribución
local vehicleDistribution = {
    VehicleName = {
        spawnChance = 2,                     # Probabilidad base de spawn
        spawnLocations = {
            "trailerpark",
            "suburban",
            "urban"
        }
    }
}

-- Registrar en sistema de spawn
Events.OnInitWorld.Add(function()
    VehicleZoneDistribution.parkingstall.vehicles["Base.VehicleName"] = vehicleDistribution.VehicleName
    VehicleZoneDistribution.trailerpark.vehicles["Base.VehicleName"] = vehicleDistribution.VehicleName
end)
```

### 4.2 Configuración de Colores Aleatorios
```lua
-- Sistema de colores aleatorios para spawn
VehicleDistributions.VehicleName = {
    Normal = VehicleDistributions.Normal,
    Specific = {
        -- Colores con probabilidades
        VehicleName_Crimson = 10,
        VehicleName_Silver = 15,
        VehicleName_Black = 12,
        VehicleName_White = 20,
    }
}
```

---

## 5. SISTEMA DE RECETAS Y CRAFTING

### 5.1 Estructura de Recetas de Vehículo
```
module Base
{
    recipe Dismantle VehicleName Hood
    {
        category = Dismantling,
        
        inputs
        {
            item 1 [Base.VehicleNameHood],
        }
        
        outputs
        {
            item 2-4 Base.MetalPipe,
            item 1-3 Base.ScrapMetal,
            item 1 Base.SheetMetal,
        }
        
        time = 300,
        skills = Mechanics:2,
        tools = Base.Crowbar,
    }
    
    recipe Install VehicleName Armor
    {
        category = Vehicle Modification,
        
        inputs
        {
            item 1 [Base.VehicleNameArmor],
            item 4 [Base.Screw],
            item 2 [Base.MetalPipe],
        }
        
        outputs
        {
            # Se instala directamente en el vehículo
        }
        
        time = 600,
        skills = Mechanics:4;Metalworking:3,
        tools = Base.Screwdriver;Base.Wrench,
    }
}
```

---

## 6. SISTEMA DE ITEMS ESPECÍFICOS

### 6.1 Items de Partes de Vehículo
```
module Base
{
    item VehicleNameHood
    {
        Type = Normal,
        DisplayName = Vehicle Name Hood,
        Icon = VehicleNameHood,
        Weight = 15.0,
        
        # Propiedades de parte de vehículo
        VehiclePart = true,
        Category = Vehicle Parts,
        
        # Compatibilidad
        VehicleType = VehicleName,
        PartCategory = hood,
        
        # Durabilidad
        ConditionMax = 100,
        ConditionLowerChanceOneIn = 5,
        
        # Valor económico
        BasePrice = 150,
    }
    
    item VehicleNameSeatFront
    {
        Type = Normal,
        DisplayName = Vehicle Name Front Seat,
        Icon = VehicleNameSeat,
        Weight = 8.0,
        
        VehiclePart = true,
        Category = Vehicle Parts,
        VehicleType = VehicleName,
        PartCategory = seat,
        
        # Propiedades de asiento
        Container = true,
        Capacity = 10,
        
        ConditionMax = 50,
        BasePrice = 80,
    }
}
```

---

## 7. TEXTURAS Y RECURSOS MULTIMEDIA

### 7.1 Organización de Texturas de Vehículo
```
media/textures/Vehicles/
├── Vehicles_VehicleName_Shell_Color1.png    # Carrocería color 1
├── Vehicles_VehicleName_Shell_Color2.png    # Carrocería color 2
├── Vehicles_VehicleName_Interior.png        # Interior del vehículo
├── Vehicles_VehicleName_Rust.png           # Textura de óxido
├── Vehicles_VehicleName_Mask.png           # Máscara de color
├── Vehicles_VehicleName_Lights.png         # Luces del vehículo
├── Vehicles_VehicleName_Damage1.png        # Daño nivel 1
├── Vehicles_VehicleName_Damage2.png        # Daño nivel 2
├── Vehicles_VehicleName_Blood1.png         # Sangre/suciedad
└── Vehicles_VehicleName_Shadow.png         # Sombra del vehículo
```

### 7.2 Modelos 3D
```
media/models_X/vehicles/
├── Vehicles_VehicleName_Body.X             # Modelo principal
├── VehicleName_parts.X                     # Partes intercambiables
└── VehicleName_interior.X                  # Modelo del interior
```

---

## 8. PATRONES CRÍTICOS PARA IA

### 8.1 Generación Automática de Vehículo
Para que una IA genere un vehículo completo:

```
1. ESTRUCTURA BASE:
   - Crear carpeta con nombre del vehículo
   - Generar mod.info con dependencias correctas
   - Crear estructura 42.0/media/scripts/vehicles/

2. ARCHIVOS PRINCIPALES:
   - VehicleName.txt (definición principal)
   - VehicleName_models.txt (modelos 3D)
   - VehicleName_recipes.txt (recetas)
   - VehicleName_vehiclesitems.txt (items)

3. TEMPLATES MODULARES:
   - template_PREFIX_seats.txt
   - template_PREFIX_doors.txt
   - template_PREFIX_windows.txt
   - template_PREFIX_tires.txt

4. TEXTURAS REQUERIDAS:
   - Shell textures (colores)
   - Interior texture
   - Damage/rust/lights textures
   - Shadow texture

5. INTEGRACIÓN:
   - Spawn distribution
   - Color variants
   - Part recipes
```

### 8.2 Errores Comunes en Vehículos
```
❌ ERRORES FRECUENTES:
- Falta de templates requeridos
- Offsets incorrectos en asientos
- Texturas mal referenciadas
- Propiedades físicas desbalanceadas
- Falta de variantes de color

✅ VALIDACIÓN AUTOMÁTICA:
- Verificar que todos los templates existen
- Validar offsets de pasajeros
- Comprobar referencias de texturas
- Balancear propiedades del motor
- Generar al menos 3 colores
```

---

## 9. CASOS DE USO AVANZADOS

### 9.1 Comandos para IA
```
"Crea un vehículo deportivo rápido con 2 asientos"
→ maxSpeed = 120f, seats = 2, engineForce = 5000+

"Genera un camión resistente para off-road"
→ offRoadEfficiency = 1.5+, mass = 1200+, frontEndHealth = 300+

"Diseña un vehículo militar blindado"
→ playerDamageProtection = 2.0+, armor templates, military colors

"Crea una motocicleta ágil"
→ seats = 1, mass = 200-, maxSpeed = 100+, steeringIncrement = 0.06+
```

### 9.2 Sistema de Modificaciones
```lua
-- Patrón para modificaciones de vehículo
local VehicleMods = {}

function VehicleMods.addArmorPlating(vehicle, armorLevel)
    local part = vehicle:getPartById("ArmorPlating")
    if part then
        part:setCondition(100)
        vehicle:setPlayerDamageProtection(vehicle:getPlayerDamageProtection() * (1 + armorLevel * 0.2))
    end
end

function VehicleMods.upgradeEngine(vehicle, upgradeLevel)
    local engine = vehicle:getPartById("Engine")
    if engine then
        vehicle:setEngineForce(vehicle:getEngineForce() * (1 + upgradeLevel * 0.15))
        vehicle:setEngineLoudness(vehicle:getEngineLoudness() * (1 + upgradeLevel * 0.1))
    end
end
```

---

*Esta documentación proporciona el sistema completo para crear, modificar y gestionar vehículos en Project Zomboid, incluyendo todos los patrones necesarios para generación automática por IA.*
