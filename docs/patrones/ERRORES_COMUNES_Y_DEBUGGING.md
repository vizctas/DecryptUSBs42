# ERRORES COMUNES Y DEBUGGING EN PROJECT ZOMBOID MODS

## ANÁLISIS EXHAUSTIVO DE PROBLEMAS Y SOLUCIONES

---

## 1. ERRORES DE NOMENCLATURA Y REFERENCIAS

### 1.1 Error: Textura no Encontrada
**Síntomas**: Item aparece con icono de "?" o textura faltante
**Causas Comunes**:
```
❌ INCORRECTO:
Script: Icon = Item_Sword,
Archivo: Sword.png

❌ INCORRECTO:
Script: Icon = sword,
Archivo: Item_Sword.png

✅ CORRECTO:
Script: Icon = Sword,
Archivo: Item_Sword.png
Ubicación: textures/Items/Item_Sword.png
```

**Debugging**:
```lua
-- Verificar si la textura existe
local texture = getTexture("Item_Sword")
if not texture then
    print("ERROR: Texture Item_Sword not found!")
end
```

### 1.2 Error: Referencias de Módulo Incorrectas
**Síntomas**: Items no aparecen en recetas, "Unknown item" en logs
**Causas Comunes**:
```
❌ INCORRECTO:
recipe TestRecipe
{
    inputs { item 1 [Sword], }  # Falta el módulo
}

❌ INCORRECTO:
recipe TestRecipe
{
    inputs { item 1 [Base.Sword], }  # Módulo incorrecto
}

✅ CORRECTO:
recipe TestRecipe
{
    inputs { item 1 [ModName.Sword], }  # Módulo correcto
}
```

### 1.3 Error: Case Sensitivity
**Síntomas**: Mod no carga, errores de sintaxis
**Causas Comunes**:
```
❌ INCORRECTO:
Module ModName  # M mayúscula
{
    Item sword  # I mayúscula, s minúscula
}

✅ CORRECTO:
module ModName  # m minúscula
{
    item Sword  # i minúscula, S mayúscula
}
```

---

## 2. ERRORES DE SINTAXIS EN SCRIPTS

### 2.1 Error: Comas y Punto y Coma
**Síntomas**: Mod no carga, "Syntax error" en logs
**Causas Comunes**:
```
❌ INCORRECTO:
item Sword
{
    Type = Weapon;        # Punto y coma incorrecto
    Weight = 2.5          # Falta coma
    Icon = SwordIcon,     # Coma innecesaria al final
}

✅ CORRECTO:
item Sword
{
    Type = Weapon,        # Coma correcta
    Weight = 2.5,         # Coma añadida
    Icon = SwordIcon      # Sin coma al final
}
```

### 2.2 Error: Llaves Desbalanceadas
**Síntomas**: "Unexpected end of file", mod no carga
**Debugging**:
```
# Contar llaves en el archivo
Abiertas: {  = 15
Cerradas: } = 14
ERROR: Falta 1 llave de cierre
```

**Solución**: Usar editor con highlighting de llaves

### 2.3 Error: Caracteres Especiales
**Síntomas**: Caracteres raros en el juego, encoding errors
**Causas Comunes**:
```
❌ INCORRECTO:
DisplayName = Épée,     # Caracteres especiales sin encoding

✅ CORRECTO:
DisplayName = Epee,     # ASCII seguro
# O usar archivo de traducción:
DisplayName = Sword,
# En traducción: Sword = "Épée"
```

---

## 3. ERRORES DE ESTRUCTURA DE ARCHIVOS

### 3.1 Error: Ubicación Incorrecta de Archivos
**Síntomas**: Archivos no se cargan, mod no funciona
**Estructura Incorrecta**:
```
❌ INCORRECTO:
ModName/
├── mod.info
├── scripts/              # Debería estar en media/
│   └── items.txt
└── lua/                  # Debería estar en media/
    └── client.lua
```

**Estructura Correcta**:
```
✅ CORRECTO:
ModName/
├── mod.info
└── media/
    ├── scripts/
    │   └── items.txt
    └── lua/
        └── client/
            └── client.lua
```

### 3.2 Error: Versioning de Carpetas
**Síntomas**: Mod funciona en una versión pero no en otra
**Causas Comunes**:
```
❌ PROBLEMÁTICO:
ModName/
├── mod.info
└── media/              # Solo funciona en versiones antiguas

✅ MEJOR:
ModName/
├── mod.info
├── media/              # Fallback para versiones antiguas
└── 42.0/               # Específico para B42
    └── media/
```

### 3.3 Error: Nombres de Archivo con Espacios
**Síntomas**: Archivos no se cargan en algunos sistemas
**Causas Comunes**:
```
❌ INCORRECTO:
My Mod Items.txt        # Espacios problemáticos
My-Mod_Items.txt        # Mezcla de convenciones

✅ CORRECTO:
MyModItems.txt          # CamelCase
my_mod_items.txt        # snake_case
```

---

## 4. ERRORES EN SCRIPTS LUA

### 4.1 Error: Variables Globales No Declaradas
**Síntomas**: "Attempt to index nil value", crashes aleatorios
**Causas Comunes**:
```lua
❌ INCORRECTO:
function doSomething()
    myGlobalVar = "test"    # Variable global implícita
    player = getPlayer()    # Sobrescribe variable global del juego
end

✅ CORRECTO:
local MyMod = {}
MyMod.myVar = "test"       # Variable en namespace del mod

function MyMod.doSomething()
    local player = getPlayer()  # Variable local
end
```

### 4.2 Error: Eventos No Removidos
**Síntomas**: Funciones se ejecutan múltiples veces, memory leaks
**Causas Comunes**:
```lua
❌ INCORRECTO:
Events.OnGameStart.Add(myFunction)
Events.OnGameStart.Add(myFunction)  # Añadido dos veces

✅ CORRECTO:
-- Remover antes de añadir
Events.OnGameStart.Remove(myFunction)
Events.OnGameStart.Add(myFunction)

-- O verificar si ya existe
if not MyMod.initialized then
    Events.OnGameStart.Add(myFunction)
    MyMod.initialized = true
end
```

### 4.3 Error: Acceso a Objetos Nil
**Síntomas**: "Attempt to call method on nil value"
**Debugging Robusto**:
```lua
❌ INCORRECTO:
local player = getPlayer()
player:getInventory():AddItem("Base.Axe")  # Crash si player es nil

✅ CORRECTO:
local player = getPlayer()
if not player then
    print("ERROR: Player not found")
    return
end

local inventory = player:getInventory()
if not inventory then
    print("ERROR: Player inventory not found")
    return
end

inventory:AddItem("Base.Axe")
```

### 4.4 Error: Loops Infinitos
**Síntomas**: Juego se congela, high CPU usage
**Causas Comunes**:
```lua
❌ INCORRECTO:
local i = 0
while i < 10 do
    print("Loop")
    -- Falta i = i + 1, loop infinito
end

❌ INCORRECTO:
Events.OnPlayerUpdate.Add(function(player)
    -- Código pesado que se ejecuta cada frame
    for i = 1, 10000 do
        -- Operación costosa
    end
end)

✅ CORRECTO:
local lastUpdate = 0
Events.OnPlayerUpdate.Add(function(player)
    local currentTime = getGameTime():getMultiplier()
    if currentTime - lastUpdate < 60 then  # Solo cada 60 ticks
        return
    end
    lastUpdate = currentTime
    
    -- Código pesado aquí
end)
```

---

## 5. ERRORES DE SANDBOX OPTIONS

### 5.1 Error: Tipos de Datos Incorrectos
**Síntomas**: Opciones no aparecen, valores por defecto incorrectos
**Causas Comunes**:
```
❌ INCORRECTO:
option ModName.NumberOption
{
    type = integer,
    default = 1.5,        # Float en integer
    min = "1",            # String en lugar de número
    max = one,            # Palabra en lugar de número
}

✅ CORRECTO:
option ModName.NumberOption
{
    type = integer,
    default = 1,          # Integer válido
    min = 1,              # Número válido
    max = 100,            # Número válido
}
```

### 5.2 Error: Referencias de Traducción Faltantes
**Síntomas**: Opciones aparecen con claves en lugar de texto
**Debugging**:
```
# En sandbox-options.txt:
translation = ModName_OptionName,

# Verificar en archivo de traducción:
ModName_EN = {
    ModName_OptionName = "Option Display Name",     # ✅ Existe
    ModName_OptionName_tooltip = "Description",     # ✅ Existe
}

# Si falta:
ModName_MissingOption = "???",                      # ❌ Aparece como ???
```

### 5.3 Error: Acceso Incorrecto desde Lua
**Síntomas**: Configuraciones no se aplican, valores siempre por defecto
**Causas Comunes**:
```lua
❌ INCORRECTO:
local value = SandBoxVars.OptionName              # Falta el módulo
local value = SandBoxVars.ModName.WrongName       # Nombre incorrecto

✅ CORRECTO:
-- Verificar que existe
if not SandBoxVars.ModName then
    print("ERROR: Sandbox variables not found for ModName")
    return
end

local value = SandBoxVars.ModName.OptionName
if value == nil then
    print("WARNING: OptionName not found, using default")
    value = false  -- Valor por defecto
end
```

---

## 6. ERRORES DE PERFORMANCE

### 6.1 Error: Eventos de Alta Frecuencia
**Síntomas**: FPS bajo, lag, high CPU usage
**Causas Comunes**:
```lua
❌ INCORRECTO:
Events.OnTick.Add(function()
    -- Código que se ejecuta 60 veces por segundo
    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        -- Operación costosa por cada jugador cada tick
    end
end)

✅ CORRECTO:
local updateCounter = 0
Events.OnTick.Add(function()
    updateCounter = updateCounter + 1
    if updateCounter % 60 ~= 0 then  -- Solo cada segundo
        return
    end
    
    -- Código optimizado aquí
end)
```

### 6.2 Error: Memory Leaks en Tablas
**Síntomas**: Uso de memoria aumenta constantemente
**Causas Comunes**:
```lua
❌ INCORRECTO:
local MyMod = {}
MyMod.playerData = {}

Events.OnCreatePlayer.Add(function(playerNum, player)
    MyMod.playerData[playerNum] = {}  # Nunca se limpia
end)

✅ CORRECTO:
Events.OnPlayerDeath.Add(function(player)
    local playerNum = player:getPlayerNum()
    MyMod.playerData[playerNum] = nil  # Limpiar datos
end)

Events.OnDisconnect.Add(function(player)
    local playerNum = player:getPlayerNum()
    MyMod.playerData[playerNum] = nil  # Limpiar al desconectar
end)
```

### 6.3 Error: Texturas No Liberadas
**Síntomas**: Uso de VRAM alto, crashes por memoria
**Causas Comunes**:
```lua
❌ INCORRECTO:
function loadManyTextures()
    local textures = {}
    for i = 1, 1000 do
        textures[i] = getTexture("Item_" .. i)  # Carga todas a la vez
    end
    return textures
end

✅ CORRECTO:
local textureCache = {}
function getTextureOptimized(name)
    if not textureCache[name] then
        textureCache[name] = getTexture(name)
    end
    return textureCache[name]
end

-- Limpiar cache cuando sea necesario
function clearTextureCache()
    textureCache = {}
end
```

---

## 7. ERRORES DE COMPATIBILIDAD

### 7.1 Error: Conflictos de ID
**Síntomas**: Items de otros mods desaparecen, comportamiento extraño
**Causas Comunes**:
```
❌ INCORRECTO:
# Mod A:
item Sword { ... }

# Mod B:
item Sword { ... }    # Mismo nombre, conflicto

✅ CORRECTO:
# Mod A:
module ModA
{
    item Sword { ... }  # ModA.Sword
}

# Mod B:
module ModB
{
    item Sword { ... }  # ModB.Sword, sin conflicto
}
```

### 7.2 Error: Dependencias Faltantes
**Síntomas**: Mod no carga, "Required mod not found"
**Debugging**:
```
# En mod.info:
require=RequiredMod

# Verificar que RequiredMod existe y está habilitado
# Verificar que el nombre coincide exactamente con el ID del mod requerido
```

### 7.3 Error: Versiones Incompatibles
**Síntomas**: Mod funciona en una versión pero no en otra
**Solución Robusta**:
```
# En mod.info:
versionMin=42.0.0      # Versión mínima requerida
versionMax=42.9.9      # Versión máxima soportada (opcional)

# En Lua, verificar versión:
local gameVersion = getCore():getVersionNumber()
if gameVersion < 42.0 then
    print("ERROR: This mod requires game version 42.0 or higher")
    return
end
```

---

## 8. HERRAMIENTAS DE DEBUGGING

### 8.1 Sistema de Logging Robusto
```lua
local Logger = {}
Logger.levels = {
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4
}

Logger.currentLevel = Logger.levels.INFO

function Logger.log(level, message)
    if level <= Logger.currentLevel then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        local levelName = ""
        for name, num in pairs(Logger.levels) do
            if num == level then
                levelName = name
                break
            end
        end
        print("[" .. timestamp .. "] [" .. levelName .. "] ModName: " .. message)
    end
end

function Logger.error(message)
    Logger.log(Logger.levels.ERROR, message)
end

function Logger.debug(message)
    Logger.log(Logger.levels.DEBUG, message)
end
```

### 8.2 Validación de Configuración
```lua
function validateModConfiguration()
    local errors = {}
    
    -- Verificar sandbox variables
    if not SandBoxVars.ModName then
        table.insert(errors, "Sandbox variables not found")
    end
    
    -- Verificar texturas críticas
    local criticalTextures = {"Item_MainWeapon", "Item_MainTool"}
    for _, textureName in ipairs(criticalTextures) do
        if not getTexture(textureName) then
            table.insert(errors, "Critical texture missing: " .. textureName)
        end
    end
    
    -- Verificar dependencias
    local requiredMods = {"RequiredMod1", "RequiredMod2"}
    for _, modName in ipairs(requiredMods) do
        if not getActivatedMods():contains(modName) then
            table.insert(errors, "Required mod not found: " .. modName)
        end
    end
    
    if #errors > 0 then
        Logger.error("Configuration validation failed:")
        for _, error in ipairs(errors) do
            Logger.error("  - " .. error)
        end
        return false
    end
    
    Logger.info("Configuration validation passed")
    return true
end
```

### 8.3 Monitoreo de Performance
```lua
local PerformanceMonitor = {}
PerformanceMonitor.timers = {}

function PerformanceMonitor.startTimer(name)
    PerformanceMonitor.timers[name] = getTimestampMs()
end

function PerformanceMonitor.endTimer(name)
    local startTime = PerformanceMonitor.timers[name]
    if startTime then
        local elapsed = getTimestampMs() - startTime
        if elapsed > 100 then  -- Warn if operation takes more than 100ms
            Logger.warn("Slow operation detected: " .. name .. " took " .. elapsed .. "ms")
        end
        PerformanceMonitor.timers[name] = nil
    end
end

-- Uso:
PerformanceMonitor.startTimer("heavyOperation")
-- ... código pesado ...
PerformanceMonitor.endTimer("heavyOperation")
```

---

## 9. CHECKLIST DE DEBUGGING

### 9.1 Antes de Publicar
- [ ] Todos los archivos tienen encoding UTF-8
- [ ] No hay caracteres especiales en nombres de archivo
- [ ] Todas las texturas referenciadas existen
- [ ] Todas las traducciones están completas
- [ ] No hay variables globales sin namespace
- [ ] Eventos están correctamente registrados/removidos
- [ ] Performance testing realizado
- [ ] Compatibilidad con mods populares verificada

### 9.2 Debugging de Crashes
1. **Revisar console.txt** para errores específicos
2. **Verificar mod loading order** en logs
3. **Probar con mod aislado** (sin otros mods)
4. **Verificar versión del juego** vs versionMin
5. **Comprobar dependencias** están instaladas

### 9.3 Debugging de Performance
1. **Usar PerformanceMonitor** para operaciones costosas
2. **Revisar eventos de alta frecuencia** (OnTick, OnPlayerUpdate)
3. **Verificar memory leaks** en tablas grandes
4. **Optimizar loops** y operaciones repetitivas

---

*Este documento proporciona una guía exhaustiva para identificar, debuggear y prevenir los errores más comunes en el desarrollo de mods para Project Zomboid.*
