# PATRONES DE NOMENCLATURA Y CONEXIONES ENTRE SISTEMAS

## ANÁLISIS PROFUNDO DE SUFIJOS Y CONVENCIONES

---

## 1. PATRÓN DE NOMENCLATURA DE TEXTURAS VS DEFINICIONES

### 1.1 Items - Patrón Icon/Texture
**Regla Fundamental**: Los archivos de textura llevan prefijos/sufijos que NO aparecen en la definición del script.

#### Ejemplo Real - Armas Blancas (Rain's Axes & Blades):
```
# En el script (module_RainsToolsandBlades.txt):
item MacheteBush
{
    Icon = MacheteB,    # ← SIN prefijo "Item_"
}

# En el sistema de archivos:
textures/Items/Item_MacheteB.png    # ← CON prefijo "Item_"
```

#### Patrón General de Items:
```
Definición Script:     Icon = NombreIcono
Archivo Físico:        Item_NombreIcono.png
Ubicación:            textures/Items/
```

### 1.2 Vehículos - Patrón de Texturas Múltiples
```
# Script de vehículo:
skin
{
    texture = Vehicles/VehicleName_Shell,
}

# Archivos físicos:
textures/Vehicles/VehicleName_Shell.png
textures/Vehicles/VehicleName_Interior.png
textures/Vehicles/VehicleName_Lights.png
```

### 1.3 UI Elements - Patrón de Interfaz
```
# Script Lua:
local texture = getTexture("media/ui/ButtonName.png")

# Archivo físico:
textures/ui/ButtonName.png    # ← Ruta completa en script
```

---

## 2. SISTEMA SANDBOX-OPTIONS Y TRADUCCIONES

### 2.1 Conexión Sandbox → Traducciones
**Patrón Descubierto en Zombaroid (Mod de Fotos)**:

#### Archivo sandbox-options.txt:
```
VERSION = 1,

option UnlimitedFilm
{
    type = boolean,
    default = false,
    page = Zombaroid,
    translation = Zombaroid_UnlimitedFilm,    # ← Clave de traducción
}
```

#### Archivo de Traducción (EN.txt):
```
Zombaroid_EN = {
    Zombaroid_UnlimitedFilm = "Unlimited Film",
    Zombaroid_UnlimitedFilm_tooltip = "Allow unlimited camera film",
}
```

### 2.2 Patrón de Nomenclatura Sandbox:
```
Opción Sandbox:        NombreOpcion
Clave Traducción:      ModName_NombreOpcion
Tooltip:              ModName_NombreOpcion_tooltip
Página:               ModName (agrupa opciones)
```

---

## 3. PATRONES DE CONEXIÓN ENTRE SISTEMAS

### 3.1 Item → Recipe → Lua Script
**Flujo Completo de Integración**:

```
1. Definición Item (scripts/items.txt):
   item CameraFilm
   {
       Type = Normal,
       Icon = FilmRoll,           # ← Referencia a textura
       OnEat = CameraScript.useFilm,  # ← Referencia a script Lua
   }

2. Textura (textures/Items/):
   Item_FilmRoll.png             # ← Archivo físico con prefijo

3. Script Lua (lua/client/):
   CameraScript = {}
   function CameraScript.useFilm(item, player)
       -- Lógica personalizada
   end

4. Receta (scripts/recipes.txt):
   recipe LoadCamera
   {
       inputs { item 1 [ModName.CameraFilm], }
       OnCreate = CameraScript.onLoadFilm,
   }
```

### 3.2 Sandbox → Item → Behavior
**Patrón de Configuración Dinámica**:

```
1. Sandbox Option:
   option UnlimitedFilm { type = boolean, default = false }

2. Lua Script Reading Sandbox:
   local unlimited = SandBoxVars.Zombaroid.UnlimitedFilm
   if unlimited then
       -- Comportamiento alternativo
   end

3. Item Behavior Modification:
   function CameraScript.useFilm(item, player)
       if not SandBoxVars.Zombaroid.UnlimitedFilm then
           item:setUsedDelta(item:getUsedDelta() + 0.1)  # Consume film
       end
   end
```

---

## 4. PATRONES DE ARMAS BLANCAS AVANZADOS

### 4.1 Estructura Completa de Arma (Rain's Axes & Blades):
```
item MacheteBush
{
    DisplayName = Bush Machete,
    DisplayCategory = GardeningWeapon,      # ← Categoría de display
    Type = Weapon,
    Weight = 1.5,
    Icon = MacheteB,                        # ← Sin prefijo Item_
    AttachmentType = Sword,                 # ← Tipo de attachment al cuerpo
    
    # Propiedades de combate avanzadas
    BaseSpeed = 1,
    BreakSound = MacheteBreak,
    Categories = LongBlade,                 # ← Categoría para recetas/lógica
    ConditionLowerChanceOneIn = 40,         # ← Probabilidad de deterioro
    ConditionMax = 20,
    CritDmgMultiplier = 4,
    CriticalChance = 15,
    DamageCategory = Slash,                 # ← Tipo de daño
    DamageMakeHole = TRUE,                  # ← Hace agujeros en ropa
    
    # Interacción con entorno
    DoorDamage = 10,                        # ← Daño a puertas
    TreeDamage = 10,                        # ← Daño a árboles
    
    # Sonidos específicos
    DoorHitSound = MacheteHit,
    DropSound = MacheteDrop,
    HitFloorSound = MacheteHit,
    HitSound = MacheteHit,
    ImpactSound = MacheteHit,
    SwingSound = MacheteSwing,
    
    # Mecánicas de combate
    KnockBackOnNoDeath = FALSE,
    KnockdownMod = 2,
    MaxDamage = 3,
    MaxHitCount = 2,                        # ← Múltiples enemigos por swing
    MaxRange = 1.23,
    MinAngle = 0.7,
    MinDamage = 2,
    MinRange = 0.61,
    MinimumSwingTime = 4,
    PushBackMod = 0.3,
    
    # Efectos visuales
    SplatBloodOnNoDeath = TRUE,
    SplatNumber = 2,
    
    # Animación y timing
    SwingAmountBeforeImpact = 0.02,
    SwingAnim = Bat,                        # ← Animación base a usar
    SwingTime = 4,
    WeaponLength = 0.3,
}
```

### 4.2 Patrón de Sonidos de Armas:
```
Nomenclatura de Sonidos:
- [WeaponName]Break    # Al romperse
- [WeaponName]Drop     # Al caer al suelo
- [WeaponName]Hit      # Al impactar
- [WeaponName]Swing    # Al hacer swing

Ubicación:
media/sound/weapons/[WeaponName]/
```

---

## 5. PATRONES DE MODULARIZACIÓN DE SCRIPTS

### 5.1 Separación por Funcionalidad (Rain's Axes):
```
Estructura Modular:
├── module_RainsToolsandBladesBase.txt      # Definiciones base/comunes
├── module_RainsToolsandBlades.txt          # Items principales
├── module_RainsToolsandBladesParts.txt     # Partes/componentes
└── module_RainsToolsandBladesRecipes.txt   # Recetas de crafting
```

### 5.2 Patrón de Imports Entre Módulos:
```
module RainsToolsandBlades
{
    imports
    {
        Base,                    # ← Módulo base del juego
        RainsToolsandBladesBase, # ← Módulo base del mod
    }
    
    # Definiciones que usan elementos de módulos importados
}
```

---

## 6. PATRONES DE SANDBOX OPTIONS AVANZADOS

### 6.1 Tipos de Opciones Sandbox:
```
# Boolean (true/false)
option OptionName
{
    type = boolean,
    default = false,
    page = ModName,
    translation = ModName_OptionName,
}

# Integer (números enteros)
option NumberOption
{
    type = integer,
    min = 1,
    max = 100,
    default = 10,
    page = ModName,
    translation = ModName_NumberOption,
}

# Double (números decimales)
option DecimalOption
{
    type = double,
    min = 0.1,
    max = 5.0,
    default = 1.0,
    page = ModName,
    translation = ModName_DecimalOption,
}

# Enum (lista de opciones)
option ChoiceOption
{
    type = enum,
    numValues = 3,
    valueTranslation = ModName_ChoiceOption,
    default = 1,
    page = ModName,
    translation = ModName_ChoiceOption,
}
```

### 6.2 Acceso desde Lua:
```lua
-- Leer valor de sandbox
local boolValue = SandBoxVars.ModName.OptionName
local intValue = SandBoxVars.ModName.NumberOption
local enumValue = SandBoxVars.ModName.ChoiceOption

-- Usar en lógica del mod
if SandBoxVars.ModName.OptionName then
    -- Comportamiento cuando está activado
end
```

---

## 7. PATRONES DE TRADUCCIONES MULTIIDIOMA

### 7.1 Estructura de Archivos de Traducción:
```
media/lua/shared/Translate/
├── EN/
│   ├── ItemName_EN.txt
│   ├── Recipes_EN.txt
│   ├── UI_EN.txt
│   └── Sandbox_EN.txt
├── ES/
│   ├── ItemName_ES.txt
│   ├── Recipes_ES.txt
│   ├── UI_ES.txt
│   └── Sandbox_ES.txt
└── [OtherLanguages]/
```

### 7.2 Patrón de Claves de Traducción:
```
# Para Items:
ModName_ItemName = "Display Name"
ModName_ItemName_Description = "Item description"

# Para Recetas:
Recipe_ModName_RecipeName = "Recipe Display Name"

# Para UI:
UI_ModName_WindowTitle = "Window Title"
UI_ModName_ButtonText = "Button Text"

# Para Sandbox:
ModName_OptionName = "Option Display Name"
ModName_OptionName_tooltip = "Option description"

# Para Enum Values:
ModName_OptionName_1 = "First Choice"
ModName_OptionName_2 = "Second Choice"
```

---

*Este documento detalla los patrones críticos de nomenclatura y conexiones entre sistemas que son fundamentales para el desarrollo correcto de mods.*
