# ANÁLISIS DE ERROR - Widget de Batería de Laptop para Project Zomboid

## RESUMEN DEL PROYECTO

Estamos desarrollando un widget visual para mostrar el porcentaje de batería de laptops en Project Zomboid. El widget está basado en el sistema de iconos del mod "Survival HUD" y se activa desde un menú contextual.

## OBJETIVO PRINCIPAL

Crear un widget que:
1. Se active al hacer clic derecho en una laptop → "Check Laptop Status"
2. Muestre un icono de batería con porcentaje visual (similar a Survival HUD)
3. Se muestre por 5 segundos y luego desaparezca
4. Use texturas dinámicas según el nivel de batería

## ESTADO ACTUAL DEL PROBLEMA

### ✅ LO QUE FUNCIONA:
- **Test con F10**: El widget aparece correctamente cuando se presiona F10 (test directo)
- **Menú contextual**: La opción "Check Laptop Status" aparece en el menú
- **Carga de archivos**: Todos los archivos se cargan sin errores de sintaxis

### ❌ LO QUE FALLA:
- **Activación desde menú**: Al seleccionar "Check Laptop Status" se produce un error de runtime
- **Error en stack trace**: `java.lang.RuntimeException: Object tried to call nil in showLaptopBatteryWidget`

## ARCHIVOS PRINCIPALES

### 1. LaptopBatteryWidget.lua
**Ubicación:** `42.0/media/lua/client/UI/LaptopBatteryWidget.lua`
**Propósito:** Widget principal con lógica de renderizado
**Estado:** Reorganizado múltiples veces para resolver dependencias

### 2. LaptopFill.lua  
**Ubicación:** `42.0/media/lua/client/TimedActions/LaptopFill.lua`
**Propósito:** Maneja el menú contextual y llama al widget
**Función clave:** `showLaptopStatus(laptop, player)` llama a `showLaptopBatteryWidget(laptop)`

### 3. ClientInit.lua
**Ubicación:** `42.0/media/lua/client/ClientInit.lua`  
**Propósito:** Carga módulos y proporciona test con F10
**Test:** Presionar F10 ejecuta `showLaptopBatteryWidget(nil)`

## HISTORIAL DE ERRORES Y CORRECCIONES

### Error 1: Parámetros incorrectos
**Problema:** `showLaptopBatteryWidget(laptop, duration)` vs `showLaptopBatteryWidget(laptop, 5000)`
**Solución:** Cambié a `showLaptopBatteryWidget(laptop)` con duración fija

### Error 2: Función no definida
**Problema:** `createLaptopBatteryWidget()` se llamaba antes de definirse
**Solución:** Moví `createLaptopBatteryWidget` antes de `showLaptopBatteryWidget`

### Error 3: Variables globales undefined
**Problema:** `LAPTOP_TYPES` y `BATTERY_CONFIG` no estaban disponibles
**Solución:** Moví todas las definiciones al principio del archivo

### Error 4: LaptopSystem undefined
**Problema:** `LaptopSystem.getLaptopHealth(laptop)` causaba nil call
**Solución:** Agregué `pcall` y import seguro de LaptopSystem

## ESTRUCTURA ACTUAL DEL ARCHIVO

```lua
-- 1. Imports
require "ISUI/ISPanel"

-- 2. LaptopSystem import seguro
local LaptopSystem = nil
pcall(function() LaptopSystem = require("shared/LaptopSystem") end)

-- 3. Definiciones globales
local LAPTOP_TYPES = { ... }
local BATTERY_CONFIG = { ... }
local laptopBatteryWidget = nil

-- 4. Función de creación
local function createLaptopBatteryWidget() ... end

-- 5. Función principal
function showLaptopBatteryWidget(laptop) ... end

-- 6. Clase del widget
LaptopBatteryWidget = ISPanel:derive("LaptopBatteryWidget")
```

## COMPORTAMIENTO ACTUAL

### Test F10 (FUNCIONA):
1. Se ejecuta `showLaptopBatteryWidget(nil)`
2. Crea el widget con valores de prueba
3. Muestra el widget por 5 segundos
4. Se ve correctamente en pantalla

### Menú contextual (FALLA):
1. Usuario hace clic derecho en laptop
2. Aparece menú con "Check Laptop Status"
3. Usuario selecciona la opción
4. Se ejecuta `showLaptopStatus(laptop, player)` en LaptopFill.lua
5. Esta función llama `showLaptopBatteryWidget(laptop)`
6. **ERROR:** Runtime exception en la línea 27 del widget

## ANÁLISIS DEL STACK TRACE

```
function: showLaptopBatteryWidget -- file: LaptopBatteryWidget.lua line # 27
function: showLaptopStatus -- file: LaptopFill.lua line # 418
function: onMouseUp -- file: ISContextMenu.lua line # 92
```

**Línea 27:** Probablemente en el bloque donde se procesa el objeto laptop
**Causa probable:** Alguna llamada a método/propiedad que retorna nil

## TEORÍAS SOBRE EL ERROR

### Teoría 1: Objeto laptop inválido
- El objeto `laptop` pasado desde el menú contextual podría estar corrupto
- Métodos como `laptop:getFullType()` o `laptop:getDisplayName()` fallan

### Teoría 2: Timing de carga
- Los módulos no están completamente cargados cuando se ejecuta desde menú
- F10 funciona porque se ejecuta después, cuando todo está listo

### Teoría 3: Contexto diferente
- El contexto de ejecución desde menú contextual es diferente
- Variables globales no están disponibles en ese contexto

## PRÓXIMOS PASOS SUGERIDOS

1. **Debug extensivo:** Agregar más prints para identificar exactamente qué variable es nil
2. **Validación del objeto laptop:** Verificar que el objeto laptop sea válido antes de usarlo
3. **Simplificación:** Crear una versión mínima que solo muestre un mensaje
4. **Comparación:** Analizar por qué F10 funciona pero el menú contextual no

## ARCHIVOS DE TEXTURAS REQUERIDOS

El widget necesita estos archivos copiados desde Survival HUD:
- **Iconos de batería:** `5.png` a `100.png` (en incrementos de 5)
- **Fondos:** `background-0.png` a `background-4.png`

**Rutas:**
- Origen: `3495906499/mods/Survival HUD/42/media/textures/ui/needs/`
- Destino iconos: `DecryptSkillSys/42.0/media/textures/ui/`
- Destino fondos: `DecryptSkillSys/42.0/media/textures/ui/battery/`

## CÓDIGO RELEVANTE

### Llamada desde menú (LaptopFill.lua):
```lua
function showLaptopStatus(laptop, player)
    print("[DecryptSkillSys] showLaptopStatus called - showing widget")
    
    if showLaptopBatteryWidget then
        showLaptopBatteryWidget(laptop) -- LÍNEA QUE CAUSA EL ERROR
    else
        -- fallback message
    end
end
```

### Función principal (LaptopBatteryWidget.lua):
```lua
function showLaptopBatteryWidget(laptop)
    print("[LaptopBatteryWidget] showLaptopBatteryWidget called")
    
    if not laptopBatteryWidget then
        createLaptopBatteryWidget()
    end
    
    -- LÍNEA 27 APROXIMADAMENTE - PROCESAMIENTO DE LAPTOP
    if laptop then
        local itemType = "Unknown"
        pcall(function()
            itemType = laptop:getFullType() or "Unknown" -- POSIBLE CAUSA
        end)
        -- ... más código
    end
end
```

## CONCLUSIÓN

El error es consistente y específico del contexto de menú contextual. El mismo código funciona perfectamente cuando se ejecuta vía F10, lo que sugiere un problema de timing, contexto de ejecución, o validez del objeto laptop pasado desde el menú contextual.