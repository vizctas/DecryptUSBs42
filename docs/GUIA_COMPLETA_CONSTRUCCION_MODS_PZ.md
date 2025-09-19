# GUÍA COMPLETA DE CONSTRUCCIÓN DE MODS PARA PROJECT ZOMBOID

## ANÁLISIS EXHAUSTIVO DE ESTRUCTURAS Y PATRONES DE MODS

*Documento generado a partir del análisis de 8 mods representativos*

---

## 1. ESTRUCTURA FUNDAMENTAL DE CARPETAS

### Estructura Base Obligatoria
```
ModName/
├── mod.info                    # Archivo de configuración principal
├── preview.png                 # Imagen de vista previa (Steam Workshop)
├── poster.png                  # Imagen del poster (opcional)
├── icon.png                    # Icono del mod (opcional)
├── media/                      # Contenido multimedia y scripts
│   ├── lua/                    # Scripts Lua del lado cliente/servidor
│   ├── scripts/                # Definiciones de items, recetas, vehículos
│   ├── textures/               # Texturas e imágenes
│   ├── models_X/               # Modelos 3D (X = versión del juego)
│   ├── sound/                  # Archivos de audio
│   └── ui/                     # Elementos de interfaz de usuario
└── 42.0/                       # Carpeta específica de versión (B42)
    └── media/                  # Misma estructura que media/ principal
```

### Variaciones por Tipo de Mod

#### Mods de Vehículos (Ejemplo: 92 Nissan GTR)
```
92nissanGTR/
├── mod.info
├── preview.png
├── media/
│   ├── scripts/vehicles/       # Scripts específicos de vehículos
│   ├── textures/Vehicles/      # Texturas de vehículos
│   ├── models_X/vehicles/      # Modelos 3D de vehículos
│   └── sound/vehicles/         # Sonidos de motor, etc.
└── 42.0/                       # Versión B42
```

#### Mods de Framework/UI (Ejemplo: NeatUI Framework)
```
NeatUI_Framework/
├── mod.info
├── media/
│   ├── lua/client/             # Scripts del lado cliente
│   ├── lua/server/             # Scripts del lado servidor
│   ├── lua/shared/             # Scripts compartidos
│   ├── ui/                     # Elementos de UI
│   └── textures/ui/            # Texturas de interfaz
```

---

## 2. ARCHIVO MOD.INFO - CONFIGURACIÓN PRINCIPAL

### Campos Obligatorios
```ini
name=Nombre del Mod
id=ModID_SinEspacios
description=Descripción detallada del mod
```

### Campos Opcionales Importantes
```ini
poster=preview.png              # Imagen principal
icon=icon.png                   # Icono pequeño
author=NombreAutor              # Autor del mod
versionMin=42.0.0               # Versión mínima del juego
require=ModDependencia          # Dependencias requeridas
pack=PackName                   # Nombre del pack de texturas
tiledef=PackName StartID        # Definición de tiles
```

### Ejemplos por Tipo de Mod

#### Mod de Vehículo
```ini
name='92 NISSAN Skyline GT-R (R32)
id=92nissanGTR
require=damnlib
description=This mod adds NISSAN Skyline GT-R (R32) from 1992
poster=preview.png
```

#### Mod de Funcionalidad
```ini
name=Caster Plus Realistic
id=CasterPlusRealistic
poster=poster.png
description=ONLY SELECT ONE MOD! Removes features that may make the game too easy
versionMin=42.0.0
author=zitronic
pack=fishtrophies
tiledef=fishtrophies 7275
```

---

## 3. SISTEMA DE SCRIPTS - MEDIA/SCRIPTS/

### Tipos de Archivos de Script

#### 3.1 Items (items.txt)
**Propósito**: Definir objetos del juego
**Ubicación**: `media/scripts/items.txt` o `media/scripts/items/`

**Estructura Base**:
```
module ModuleName
{
    imports
    {
        Base
    }
    
    item ItemID
    {
        Type = Normal,
        DisplayName = Nombre Mostrado,
        Icon = IconName,
        Weight = 0.5,
        // Propiedades específicas
    }
}
```

#### 3.2 Recetas (recipes.txt)
**Propósito**: Definir recetas de crafting
**Ubicación**: `media/scripts/recipes.txt`

**Estructura Base**:
```
module ModuleName
{
    recipe RecipeName
    {
        Time = 30,
        category = CategoryName,
        inputs
        {
            item 1 [ModuleName.ItemName],
        }
        outputs
        {
            item 1 ModuleName.ResultItem,
        }
    }
}
```

#### 3.3 Vehículos (vehicles/)
**Propósito**: Definir vehículos y sus componentes
**Ubicación**: `media/scripts/vehicles/`

**Archivos Típicos**:
- `VehicleName.txt` - Definición principal del vehículo
- `VehicleName_models.txt` - Modelos 3D
- `VehicleName_recipes.txt` - Recetas de crafting
- `VehicleName_items.txt` - Items específicos
- `VehicleName_dismantle.txt` - Reglas de desmantelamiento

---

## 4. SISTEMA LUA - MEDIA/LUA/

### Estructura de Carpetas Lua
```
media/lua/
├── client/                     # Scripts del lado cliente
├── server/                     # Scripts del lado servidor
├── shared/                     # Scripts compartidos
└── TimedActions/               # Acciones con tiempo
```

### Patrones de Programación Lua

#### 4.1 Estructura Básica de Módulo
```lua
-- Definición del módulo
local ModuleName = {}

-- Variables locales
local variable = nil

-- Función principal
function ModuleName.mainFunction()
    -- Lógica del mod
end

-- Eventos del juego
Events.OnGameStart.Add(ModuleName.mainFunction)

return ModuleName
```

#### 4.2 Manejo de Eventos Comunes
```lua
-- Eventos de inicio
Events.OnGameStart.Add(function() end)
Events.OnCreatePlayer.Add(function(playerNum, player) end)

-- Eventos de items
Events.OnFillInventoryObjectContextMenu.Add(function(player, context, items) end)

-- Eventos de tiempo
Events.EveryOneMinute.Add(function() end)
Events.EveryTenMinutes.Add(function() end)
```

---

## 5. SISTEMA DE TEXTURAS Y RECURSOS

### Organización de Texturas
```
media/textures/
├── Items/                      # Texturas de items
├── Vehicles/                   # Texturas de vehículos
├── Clothing/                   # Texturas de ropa
├── UI/                         # Texturas de interfaz
└── Tiles/                      # Texturas de tiles del mundo
```

### Formatos y Convenciones
- **Formato**: PNG preferido
- **Resolución Items**: 64x64 píxeles típico
- **Resolución UI**: Variable según necesidad
- **Nomenclatura**: CamelCase o snake_case consistente

---

## 6. PATRONES DE INTEGRACIÓN ENTRE SISTEMAS

### 6.1 Conexión Item → Texture → Script
```
1. Definir item en scripts/items.txt:
   Icon = ItemIconName,

2. Crear textura en textures/Items/ItemIconName.png

3. Referenciar en Lua si necesario:
   local item = InventoryItemFactory.CreateItem("ModName.ItemID")
```

### 6.2 Conexión Recipe → Items → Actions
```
1. Definir items necesarios en scripts/items.txt
2. Crear receta en scripts/recipes.txt referenciando items
3. Implementar lógica especial en lua/ si necesario
```

---

## 7. MEJORES PRÁCTICAS Y CONVENCIONES

### Nomenclatura
- **ModID**: Sin espacios, CamelCase
- **Items**: ModuleName.ItemName
- **Archivos**: snake_case o CamelCase consistente
- **Variables Lua**: camelCase

### Organización
- Un módulo por funcionalidad principal
- Separar cliente/servidor/compartido en Lua
- Agrupar recursos por tipo en carpetas específicas

### Compatibilidad
- Usar `versionMin` para especificar versión mínima
- Declarar dependencias en `require`
- Probar con mods populares para evitar conflictos

---

## 8. ERRORES COMUNES Y SOLUCIONES ROBUSTAS

### 8.1 Errores de Nomenclatura y Referencias

#### Error: Item no aparece en juego
**Síntomas**: Icono de "?" o textura faltante
**Causas Comunes**:
- Prefijo incorrecto: `Icon = Item_Sword` (debería ser `Icon = Sword`)
- Archivo faltante: Script dice `Icon = Sword` pero no existe `Item_Sword.png`
- Ubicación incorrecta: Archivo en carpeta equivocada

**Solución Robusta**:
```
1. Verificar patrón: Script usa Icon = NombreIcono
2. Archivo debe ser: Item_NombreIcono.png
3. Ubicación: textures/Items/Item_NombreIcono.png
4. Debugging: Usar getTexture("Item_NombreIcono") en Lua
```

#### Error: Referencias de Módulo Incorrectas
**Síntomas**: "Unknown item" en logs, items no aparecen en recetas
**Causas Comunes**:
- Falta módulo: `[ItemName]` en lugar de `[ModuleName.ItemName]`
- Módulo incorrecto: `[Base.ItemName]` cuando debería ser `[ModName.ItemName]`

**Solución**:
```
✅ Formato correcto en recetas:
inputs { item 1 [ModuleName.ItemName], }
```

### 8.2 Errores de Sintaxis en Scripts

#### Error: Mod no carga por sintaxis
**Síntomas**: "Syntax error" en logs, mod no aparece en lista
**Causas Comunes**:
- Comas faltantes o incorrectas
- Llaves desbalanceadas `{` vs `}`
- Case sensitivity: `Module` vs `module`
- Caracteres especiales sin encoding

**Debugging Sistemático**:
```
1. Verificar cada línea termina con coma (excepto la última)
2. Contar llaves: número de { debe igualar número de }
3. Verificar palabras clave en minúsculas: module, item, recipe
4. Usar editor con syntax highlighting
```

### 8.3 Errores de Estructura de Archivos

#### Error: Archivos no se cargan
**Síntomas**: Mod instalado pero no funciona
**Causas Comunes**:
- Estructura incorrecta: archivos fuera de `media/`
- Versioning incorrecto: falta carpeta `42.0/` para B42
- Nombres con espacios o caracteres especiales

**Estructura Obligatoria**:
```
ModName/
├── mod.info                    # Configuración principal
├── media/                      # Para versiones antiguas
│   ├── scripts/
│   ├── lua/
│   └── textures/
└── 42.0/                       # Para Build 42
    └── media/
        ├── scripts/
        ├── lua/
        └── textures/
```

### 8.4 Errores en Scripts Lua

#### Error: Variables Globales Conflictivas
**Síntomas**: Crashes aleatorios, comportamiento extraño
**Causa**: Sobrescribir variables globales del juego
**Solución**:
```lua
❌ INCORRECTO:
player = getPlayer()        # Sobrescribe variable global

✅ CORRECTO:
local MyMod = {}
local player = getPlayer()  # Variable local
```

#### Error: Memory Leaks en Eventos
**Síntomas**: Performance degrada con el tiempo
**Causa**: Eventos añadidos múltiples veces
**Solución**:
```lua
-- Remover antes de añadir
Events.OnGameStart.Remove(myFunction)
Events.OnGameStart.Add(myFunction)
```

### 8.5 Errores de Sandbox Options

#### Error: Opciones no aparecen
**Síntomas**: Configuraciones no visibles en sandbox
**Causas Comunes**:
- Tipo de dato incorrecto: `default = 1.5` en `type = integer`
- Traducción faltante: clave no existe en archivo de traducción
- Sintaxis incorrecta en sandbox-options.txt

**Validación**:
```
option ModName.OptionName
{
    type = boolean,                    # Tipo válido
    default = false,                   # Valor compatible con tipo
    page = ModName,                    # Página de agrupación
    translation = ModName_OptionName,  # Clave de traducción
}
```

### 8.6 Errores de Performance

#### Error: FPS Bajo / Lag
**Síntomas**: Juego lento cuando mod está activo
**Causas Comunes**:
- Eventos de alta frecuencia sin throttling
- Loops costosos en OnTick o OnPlayerUpdate
- Memory leaks en tablas grandes

**Optimización**:
```lua
local updateCounter = 0
Events.OnTick.Add(function()
    updateCounter = updateCounter + 1
    if updateCounter % 60 ~= 0 then  -- Solo cada segundo
        return
    end
    -- Código pesado aquí
end)
```

### 8.7 Errores de Compatibilidad

#### Error: Conflictos con Otros Mods
**Síntomas**: Mods dejan de funcionar cuando se combinan
**Causas Comunes**:
- IDs duplicados: mismo nombre de item en diferentes mods
- Dependencias faltantes: mod requerido no instalado
- Orden de carga incorrecto

**Prevención**:
```
1. Usar namespace único: module MiModUnico
2. Declarar dependencias: require=ModRequerido en mod.info
3. Verificar compatibilidad con mods populares
```

### 8.8 Herramientas de Debugging

#### Sistema de Logging Robusto
```lua
local Logger = {}
function Logger.error(message)
    print("[ERROR] ModName: " .. message)
end

function Logger.debug(message)
    if SandBoxVars.ModName.DebugMode then
        print("[DEBUG] ModName: " .. message)
    end
end
```

#### Validación de Configuración
```lua
function validateConfiguration()
    -- Verificar texturas críticas
    if not getTexture("Item_MainItem") then
        Logger.error("Critical texture missing: Item_MainItem")
        return false
    end
    
    -- Verificar sandbox variables
    if not SandBoxVars.ModName then
        Logger.error("Sandbox variables not found")
        return false
    end
    
    return true
end
```

### 8.9 Checklist de Debugging

#### Antes de Publicar:
- [ ] Todas las texturas referenciadas existen
- [ ] Nombres de archivos sin espacios ni caracteres especiales
- [ ] Sintaxis verificada en todos los scripts
- [ ] Traducciones completas para todos los idiomas
- [ ] Performance testing realizado
- [ ] Compatibilidad con mods populares verificada
- [ ] Logs revisados sin errores o warnings

#### Para Debugging de Crashes:
1. Revisar console.txt para errores específicos
2. Probar mod aislado (sin otros mods)
3. Verificar versión del juego vs versionMin
4. Comprobar que dependencias están instaladas
5. Usar sistema de logging para rastrear problemas

---

*Este documento sirve como guía fundamental para la construcción de mods en Project Zomboid y base para sistemas de IA automatizados.*
