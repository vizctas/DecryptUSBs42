# PATRONES AVANZADOS DE SANDBOX OPTIONS

## ANÁLISIS EXHAUSTIVO DE CONFIGURACIONES Y CONEXIONES

---

## 1. PATRONES DE NOMENCLATURA SANDBOX

### 1.1 Convención de Nombres Completos
**Patrón Descubierto**: Los nombres de opciones pueden usar notación de punto para jerarquía.

#### Ejemplos Reales:
```
# Proximity Inventory - Notación simple
option ProxInv.ZombieOnly = {
    type = boolean, default = false, 
    page = ProxInv, translation = ZombieOnly,
}

# Inventory Tetris - Notación completa
option InventoryTetris.EnforceCarryWeight
{
    type = boolean, default = false,
    page = InventoryTetris,
    translation = InventoryTetris_EnforceCarryWeight,
}
```

### 1.2 Patrón de Agrupación por Página:
```
# Todas las opciones del mismo mod en la misma página
page = ModName

# Esto crea una pestaña separada en las opciones de sandbox
# con todas las configuraciones del mod agrupadas
```

---

## 2. TIPOS AVANZADOS DE SANDBOX OPTIONS

### 2.1 Boolean Options (Más Comunes):
```
option ModName.FeatureName
{
    type = boolean,
    default = false,                    # Valor por defecto
    page = ModName,                     # Página de agrupación
    translation = ModName_FeatureName,  # Clave de traducción
}
```

### 2.2 Integer Options con Rangos:
```
option ModName.NumberSetting
{
    type = integer,
    min = 1,                           # Valor mínimo
    max = 100,                         # Valor máximo
    default = 10,                      # Valor por defecto
    page = ModName,
    translation = ModName_NumberSetting,
}
```

### 2.3 Double Options para Decimales:
```
option ModName.MultiplierSetting
{
    type = double,
    min = 0.1,
    max = 5.0,
    default = 1.0,
    page = ModName,
    translation = ModName_MultiplierSetting,
}
```

### 2.4 Enum Options para Múltiples Opciones:
```
option ModName.DifficultyLevel
{
    type = enum,
    numValues = 4,                     # Número de opciones
    valueTranslation = ModName_DifficultyLevel,
    default = 2,                       # Opción por defecto (1-indexed)
    page = ModName,
    translation = ModName_DifficultyLevel,
}
```

---

## 3. PATRONES DE ACCESO DESDE LUA

### 3.1 Lectura Básica de Sandbox Variables:
```lua
-- Acceso directo a variable boolean
local isEnabled = SandBoxVars.ModName.FeatureName

-- Acceso a variable numérica
local maxValue = SandBoxVars.ModName.NumberSetting

-- Uso en condicionales
if SandBoxVars.ModName.FeatureName then
    -- Lógica cuando está habilitado
end
```

### 3.2 Patrón de Configuración Dinámica:
```lua
-- Sistema de configuración que se adapta a sandbox
local ModConfig = {}

function ModConfig.init()
    -- Leer todas las configuraciones al inicio
    ModConfig.enforceWeight = SandBoxVars.InventoryTetris.EnforceCarryWeight
    ModConfig.encumbranceSlow = SandBoxVars.InventoryTetris.EncumbranceSlow
    ModConfig.preventStacking = SandBoxVars.InventoryTetris.PreventTardisStacking
    ModConfig.useTransferTime = SandBoxVars.InventoryTetris.UseItemTransferTime
end

function ModConfig.shouldEnforceWeight()
    return ModConfig.enforceWeight
end

function ModConfig.shouldSlowOnEncumbrance()
    return ModConfig.encumbranceSlow
end

-- Inicializar al cargar el juego
Events.OnGameStart.Add(ModConfig.init)
```

### 3.3 Patrón de Validación de Configuración:
```lua
-- Validar configuraciones y aplicar valores por defecto
local function validateConfig()
    -- Verificar que las variables existen
    if SandBoxVars.ModName == nil then
        print("ERROR: Sandbox variables not found for ModName")
        return false
    end
    
    -- Aplicar límites a valores numéricos
    local maxItems = SandBoxVars.ModName.MaxItems
    if maxItems < 1 then
        SandBoxVars.ModName.MaxItems = 1
    elseif maxItems > 1000 then
        SandBoxVars.ModName.MaxItems = 1000
    end
    
    return true
end
```

---

## 4. PATRONES DE TRADUCCIONES PARA SANDBOX

### 4.1 Estructura de Traducciones Sandbox:
```
# Archivo: Sandbox_EN.txt
ModName_EN = {
    # Nombre de la opción
    ModName_FeatureName = "Feature Name",
    
    # Tooltip explicativo
    ModName_FeatureName_tooltip = "Detailed explanation of what this feature does",
    
    # Para opciones enum - cada valor
    ModName_DifficultyLevel = "Difficulty Level",
    ModName_DifficultyLevel_tooltip = "Choose the difficulty level",
    ModName_DifficultyLevel_1 = "Easy",
    ModName_DifficultyLevel_2 = "Normal", 
    ModName_DifficultyLevel_3 = "Hard",
    ModName_DifficultyLevel_4 = "Nightmare",
}
```

### 4.2 Patrón de Tooltips Informativos:
```
# Tooltips deben ser descriptivos y explicar el impacto
ModName_EnforceCarryWeight_tooltip = "When enabled, items will have physical weight that affects movement speed and carrying capacity",

ModName_PreventTardisStacking_tooltip = "Prevents unrealistic stacking of large items inside small containers",
```

---

## 5. PATRONES DE INTEGRACIÓN CON GAMEPLAY

### 5.1 Modificación de Mecánicas Existentes:
```lua
-- Ejemplo: Modificar velocidad de movimiento basado en sandbox
local originalCalculateSpeed = IsoPlayer.calculateSpeed

function IsoPlayer:calculateSpeed()
    local speed = originalCalculateSpeed(self)
    
    -- Aplicar modificación si está habilitada en sandbox
    if SandBoxVars.InventoryTetris.EncumbranceSlow then
        local encumbrance = self:getEncumbrance()
        if encumbrance > 0.8 then
            speed = speed * 0.5  -- Reducir velocidad al 50%
        end
    end
    
    return speed
end
```

### 5.2 Patrón de Características Opcionales:
```lua
-- Sistema que habilita/deshabilita características completas
local FeatureManager = {}

function FeatureManager.init()
    -- Solo registrar eventos si la característica está habilitada
    if SandBoxVars.ModName.EnableFeatureA then
        Events.OnPlayerUpdate.Add(FeatureManager.updateFeatureA)
    end
    
    if SandBoxVars.ModName.EnableFeatureB then
        Events.OnFillInventoryObjectContextMenu.Add(FeatureManager.addContextMenuB)
    end
end

function FeatureManager.updateFeatureA(player)
    -- Lógica de la característica A
end

function FeatureManager.addContextMenuB(player, context, items)
    -- Lógica de la característica B
end
```

---

## 6. PATRONES DE CONFIGURACIÓN COMPLEJA

### 6.1 Múltiples Opciones Relacionadas:
```
# Inventory Tetris - Ejemplo de opciones que trabajan juntas
option InventoryTetris.EnforceCarryWeight
{
    type = boolean, default = false,
    page = InventoryTetris,
    translation = InventoryTetris_EnforceCarryWeight,
}

option InventoryTetris.EncumbranceSlow
{
    type = boolean, default = true,
    page = InventoryTetris,
    translation = InventoryTetris_EncumbranceSlow,
}

option InventoryTetris.PreventTardisStacking
{
    type = boolean, default = true,
    page = InventoryTetris,
    translation = InventoryTetris_PreventTardisStacking,
}
```

### 6.2 Patrón de Configuración Jerárquica:
```lua
-- Lógica que respeta jerarquía de configuraciones
function InventorySystem.canStackItem(container, item)
    -- Si el sistema completo está deshabilitado, usar lógica vanilla
    if not SandBoxVars.InventoryTetris.EnableSystem then
        return true  -- Comportamiento original
    end
    
    -- Si está habilitado, aplicar reglas específicas
    if SandBoxVars.InventoryTetris.PreventTardisStacking then
        local containerSize = container:getCapacity()
        local itemSize = item:getActualWeight()
        
        if itemSize > containerSize * 0.8 then
            return false  -- Item demasiado grande
        end
    end
    
    return true
end
```

---

## 7. PATRONES DE DEBUGGING Y DESARROLLO

### 7.1 Opciones de Debug:
```
option ModName.DebugMode
{
    type = boolean, default = false,
    page = ModName,
    translation = ModName_DebugMode,
}

option ModName.LogLevel
{
    type = enum,
    numValues = 4,
    valueTranslation = ModName_LogLevel,
    default = 2,  # Normal
    page = ModName,
    translation = ModName_LogLevel,
}
```

### 7.2 Sistema de Logging Configurable:
```lua
local Logger = {}
Logger.levels = {
    [1] = "ERROR",
    [2] = "WARN", 
    [3] = "INFO",
    [4] = "DEBUG"
}

function Logger.log(level, message)
    local configLevel = SandBoxVars.ModName.LogLevel or 2
    
    if level <= configLevel then
        local levelName = Logger.levels[level] or "UNKNOWN"
        print("[" .. levelName .. "] ModName: " .. message)
    end
end

function Logger.debug(message)
    if SandBoxVars.ModName.DebugMode then
        Logger.log(4, message)
    end
end
```

---

## 8. MEJORES PRÁCTICAS SANDBOX

### 8.1 Nomenclatura Consistente:
```
# BUENO - Consistente y claro
option ModName.EnableFeature
option ModName.FeatureIntensity
option ModName.FeatureRange

# MALO - Inconsistente
option ModName.feat1
option ModName.FeatureTwo_enabled
option ModName.range_of_feature
```

### 8.2 Valores por Defecto Sensatos:
```
# Características que pueden romper el juego = false por defecto
option ModName.UnlimitedResources { default = false }

# Mejoras de calidad de vida = true por defecto  
option ModName.ShowHelpTooltips { default = true }

# Valores numéricos en rangos razonables
option ModName.SpawnRate { min = 0.1, max = 10.0, default = 1.0 }
```

### 8.3 Documentación Clara:
```
# Tooltips deben explicar:
# - Qué hace la opción
# - Cuál es el impacto en el gameplay
# - Si requiere reinicio del juego
ModName_FeatureName_tooltip = "Enables advanced inventory management. Requires game restart to take effect. May impact performance on older systems."
```

---

*Este documento detalla los patrones avanzados para crear y manejar sandbox options de manera profesional y user-friendly.*
