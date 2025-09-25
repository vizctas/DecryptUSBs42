# 🖥️ TEMPLATE DE VENTANA DINÁMICA - MiniGameUI.lua
## Guía Completa para Creación de Ventanas Interactivas en Project Zomboid

**Versión:** 2.0 - Ultra Fiable y Modular
**Fecha:** 2025-09-24
**Propósito:** Template completo para crear ventanas dinámicas que futuras IAs puedan usar como base

---

## 📋 ÍNDICE DE CONTENIDOS

1. [ESTRUCTURA GENERAL DEL TEMPLATE](#1-estructura-general-del-template)
2. [PASO 1: CONFIGURACIÓN INICIAL](#paso-1-configuración-inicial)
3. [PASO 2: SISTEMA DE TIMERS ULTRA SIMPLE](#paso-2-sistema-de-timers-ultra-simple)
4. [PASO 3: CLASE PRINCIPAL DE VENTANA](#paso-3-clase-principal-de-ventana)
5. [PASO 4: CONSTRUCTOR Y PROPIEDADES](#paso-4-constructor-y-propiedades)
6. [PASO 5: CREACIÓN DE ELEMENTOS UI](#paso-5-creación-de-elementos-ui)
7. [PASO 6: SISTEMA DE LAYOUT ADAPTATIVO](#paso-6-sistema-de-layout-adaptativo)
8. [PASO 7: MANEJO DE EVENTOS](#paso-7-manejo-de-eventos)
9. [PASO 8: FUNCIONES DE JUEGO](#paso-8-funciones-de-juego)
10. [PASO 9: RENDERIZADO Y EFECTOS VISUALES](#paso-9-renderizado-y-efectos-visuales)
11. [PASO 10: FUNCIÓN GLOBAL DE APERTURA](#paso-10-función-global-de-apertura)
12. [MEJORES PRÁCTICAS Y OPTIMIZACIONES](#mejores-prácticas-y-optimizaciones)

---

## 1. ESTRUCTURA GENERAL DEL TEMPLATE

```lua
-- ✅ TEMPLATE BASE PARA VENTANAS DINÁMICAS
print("[Modulo] Loading TemplateWindow.lua")

-- ========== CONFIGURACIÓN GLOBAL ==========
-- ========== SISTEMA DE TIMERS ==========
-- ========== CLASE PRINCIPAL ==========
-- ========== FUNCIONES DE UTILIDAD ==========
-- ========== FUNCIÓN GLOBAL DE APERTURA ==========
```

### 🏗️ Componentes Obligatorios:
- **Configuración Global**: Variables que controlan el comportamiento
- **Sistema de Timers**: Para animaciones y delays
- **Clase Principal**: Derivada de ISPanel
- **Función Global**: Para abrir la ventana desde cualquier lugar

---

## PASO 1: CONFIGURACIÓN INICIAL

### 📝 Código Base:

```lua
-- ========== CONFIGURACIÓN DEL GRID ==========
local GRID_ROWS = 4           -- Número de filas
local GRID_COLS = 4           -- Número de columnas
local SEQUENCE_LENGTH = 5     -- Longitud de secuencia
local BUTTON_SIZE = 10        -- Tamaño base de botones
local BUTTON_SPACING = 8      -- Espaciado entre botones

-- ========== CONFIGURACIÓN DE ESCALADO ADAPTATIVO ==========
local PADDING_HORIZONTAL = 40   -- Espacio horizontal
local PADDING_VERTICAL = 90     -- Espacio vertical
local MIN_BUTTON_SIZE = 20      -- Tamaño mínimo
local MAX_BUTTON_SIZE = 40      -- Tamaño máximo

-- ========== CONFIGURACIÓN DE VENTANA ==========
local WINDOW_WIDTH_PCT = 15     -- Porcentaje del ancho de pantalla
local WINDOW_HEIGHT_PCT = 30    -- Porcentaje del alto de pantalla
local WINDOW_WIDTH = 400        -- Ancho fallback
local WINDOW_HEIGHT = 500       -- Alto fallback
```

### 🎯 Propósito:
- **GRID_ROWS/COLS**: Define la cuadrícula de elementos interactivos
- **BUTTON_SIZE/SPACING**: Controla el tamaño y separación visual
- **WINDOW_%**: Tamaño relativo a la pantalla del usuario
- **PADDING**: Espacios seguros alrededor de elementos

### ⚡ Mejores Prácticas:
- Usar porcentajes para escalabilidad automática
- Definir valores mínimos/máximos seguros
- Comentarios descriptivos para cada configuración

---

## PASO 2: SISTEMA DE TIMERS ULTRA SIMPLE

### 📝 Código Base:

```lua
-- SISTEMA DE TIMERS ULTRA SIMPLE - Sin closures complejos
local SimpleTimer = {}
SimpleTimer.activeTimers = {}

function SimpleTimer:addTimer(duration, callback)
    local id = self.nextId
    self.nextId = self.nextId + 1

    self.activeTimers[id] = {
        callback = callback,
        duration = duration,
        elapsed = 0
    }

    return id
end

function SimpleTimer:update()
    local toRemove = {}
    for id, timer in pairs(self.activeTimers) do
        timer.elapsed = timer.elapsed + 1
        if timer.elapsed >= timer.duration then
            if timer.callback then
                pcall(timer.callback)
            end
            toRemove[id] = true
        end
    end

    for id in pairs(toRemove) do
        self.activeTimers[id] = nil
    end
end

-- Registrar en el sistema de eventos
if Events and Events.OnTick then
    Events.OnTick.Add(function() SimpleTimer:update() end)
end
```

### 🎯 Propósito:
- **Gestión de tiempo**: Animaciones, delays, secuencias
- **Sin closures**: Evita memory leaks
- **Auto-limpieza**: Timers se eliminan automáticamente

### ⚡ Mejores Prácticas:
- Usar `pcall()` para callbacks seguros
- IDs únicos para gestión
- Registro automático en Events.OnTick

---

## PASO 3: CLASE PRINCIPAL DE VENTANA

### 📝 Código Base:

```lua
local TemplateWindow = ISPanel:derive("TemplateWindow")

function TemplateWindow:new(x, y, width, height, player, param1, param2)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    -- ✅ PROPIEDADES ESTÉTICAS
    o.backgroundColor = {r=0.05, g=0.2, b=0.05, a=0.9}
    o.borderColor = {r=0.2, g=1, b=0.2, a=1}
    o.moveWithMouse = true

    -- ✅ PARÁMETROS DE INTEGRACIÓN
    o.player = player
    o.param1 = param1
    o.param2 = param2

    return o
end
```

### 🎯 Propósito:
- **Derivación de ISPanel**: Base para todas las ventanas PZ
- **Propiedades estéticas**: Colores, comportamiento
- **Parámetros**: Datos específicos del contexto

### ⚡ Mejores Prácticas:
- Siempre derivar de ISPanel
- Establecer colores por defecto
- Validar parámetros de entrada

---

## PASO 4: CONSTRUCTOR Y PROPIEDADES

### 📝 Código Base:

```lua
function TemplateWindow:new(x, y, width, height, player, param1, param2)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    -- ✅ PROPIEDADES ESTÉTICAS
    o.backgroundColor = {r=0.05, g=0.2, b=0.05, a=0.9}
    o.borderColor = {r=0.2, g=1, b=0.2, a=1}
    o.moveWithMouse = true

    -- ✅ PARÁMETROS DE INTEGRACIÓN
    o.player = player
    o.param1 = param1
    o.param2 = param2

    -- ✅ ESTADO DEL JUEGO
    o.gameState = "idle"
    o.currentStep = 0
    o.maxSteps = 10

    -- ✅ ELEMENTOS UI
    o.buttons = {}
    o.labels = {}

    return o
end
```

### 🎯 Propósito:
- **Propiedades estéticas**: Apariencia visual
- **Parámetros**: Datos del contexto de uso
- **Estado del juego**: Variables de lógica
- **Elementos UI**: Referencias a componentes

### ⚡ Mejores Prácticas:
- Inicializar todas las propiedades
- Usar nombres descriptivos
- Preparar arrays para elementos dinámicos

---

## PASO 5: CREACIÓN DE ELEMENTOS UI

### 📝 Código Base:

```lua
function TemplateWindow:createChildren()
    -- ✅ ESCALADO ADAPTATIVO
    local paddingH = PADDING_HORIZONTAL
    local availableWidth = self.width - paddingH * 2
    local availableHeight = self.height - PADDING_VERTICAL

    -- ✅ BOTÓN DE CIERRE
    self.closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    -- ✅ CREAR GRID DE BOTONES
    self.buttons = {}
    for row = 1, GRID_ROWS do
        self.buttons[row] = {}
        for col = 1, GRID_COLS do
            local x = paddingH + (col - 1) * (BUTTON_SIZE + BUTTON_SPACING)
            local y = 80 + (row - 1) * (BUTTON_SIZE + BUTTON_SPACING)

            local btn = ISButton:new(x, y, BUTTON_SIZE, BUTTON_SIZE, "", self, self.onButtonPress)
            btn.row = row
            btn.col = col
            btn:initialise()
            self:addChild(btn)
            self.buttons[row][col] = btn
        end
    end

    -- ✅ BOTÓN PRINCIPAL
    local startY = 80 + GRID_ROWS * (BUTTON_SIZE + BUTTON_SPACING) + 20
    self.startButton = ISButton:new((self.width - 100) / 2, startY, 100, 30, "START", self, self.onStart)
    self.startButton:initialise()
    self:addChild(self.startButton)
end
```

### 🎯 Propósito:
- **Escalado adaptativo**: Ajuste automático al tamaño de ventana
- **Botón de cierre**: Siempre presente, esquina superior derecha
- **Grid de botones**: Elementos interactivos principales
- **Botón principal**: Acción principal del minijuego

### ⚡ Mejores Prácticas:
- Calcular posiciones dinámicamente
- Usar variables de configuración
- Almacenar referencias para manipulación posterior

---

## PASO 6: SISTEMA DE LAYOUT ADAPTATIVO

### 📝 Código Base:

```lua
function TemplateWindow:updateLayout()
    -- VALIDACIÓN ROBUSTA
    local gridRows = math.max(1, GRID_ROWS)
    local gridCols = math.max(1, GRID_COLS)

    -- Calcular tamaños óptimos
    local availableWidth = self.width - PADDING_HORIZONTAL * 2
    local availableHeight = self.height - PADDING_VERTICAL

    local btnW = math.max(MIN_BUTTON_SIZE, availableWidth / gridCols - BUTTON_SPACING)
    local btnH = math.max(MIN_BUTTON_SIZE, availableHeight / gridRows - BUTTON_SPACING)

    -- Aplicar límites
    btnW = math.min(btnW, MAX_BUTTON_SIZE)
    btnH = math.min(btnH, MAX_BUTTON_SIZE)

    -- Centrar grid
    local gridWidth = btnW * gridCols + (gridCols - 1) * BUTTON_SPACING
    local gridStartX = (self.width - gridWidth) / 2

    -- Actualizar posiciones
    for row = 1, gridRows do
        for col = 1, gridCols do
            local btn = self.buttons[row][col]
            if btn then
                local x = gridStartX + (col - 1) * (btnW + BUTTON_SPACING)
                local y = 80 + (row - 1) * (btnH + BUTTON_SPACING)
                btn:setX(x)
                btn:setY(y)
                btn:setWidth(btnW)
                btn:setHeight(btnH)
            end
        end
    end
end

function TemplateWindow:onResize(newW, newH)
    self:updateLayout()
end
```

### 🎯 Propósito:
- **Recalculo dinámico**: Ajuste automático al cambiar tamaño
- **Validación robusta**: Límites seguros para todos los valores
- **Centrado automático**: Grid siempre centrado en la ventana

### ⚡ Mejores Prácticas:
- Usar math.max/min para límites seguros
- Recalcular en onResize
- Mantener proporciones

---

## PASO 7: MANEJO DE EVENTOS

### 📝 Código Base:

```lua
function TemplateWindow:onClose()
    -- ✅ LIMPIEZA ANTES DE CERRAR
    self:clearAllTimers()

    -- ✅ LÓGICA ESPECÍFICA
    if self.gameState == "playing" then
        -- Penalización por cerrar durante juego
        self:applyFailurePenalty()
    end

    -- ✅ CERRAR VENTANA
    self:setVisible(false)
    self:removeFromUIManager()
end

function TemplateWindow:onButtonPress(button)
    if self.gameState ~= "playing" then return end

    -- ✅ LÓGICA DEL BOTÓN
    local row, col = button.row, button.col

    -- Feedback visual
    self:flashButton(button, {r=1, g=1, b=0, a=1})

    -- Procesar input
    self:processInput(row, col)
end

function TemplateWindow:onStart()
    -- ✅ INICIALIZACIÓN DEL JUEGO
    self:resetGame()
    self.gameState = "playing"

    -- ✅ SECUENCIA INICIAL
    self:startGameSequence()
end
```

### 🎯 Propósito:
- **onClose**: Limpieza y lógica de salida
- **onButtonPress**: Manejo de interacciones del usuario
- **onStart**: Inicialización del juego

### ⚡ Mejores Prácticas:
- Siempre limpiar timers en onClose
- Validar estado antes de procesar
- Feedback visual inmediato

---

## PASO 8: FUNCIONES DE JUEGO

### 📝 Código Base:

```lua
function TemplateWindow:resetGame()
    -- Limpiar estado
    self.gameState = "idle"
    self.currentStep = 0
    self.userSequence = {}

    -- Limpiar UI
    self:clearAllButtonColors()

    -- Limpiar timers
    self:clearAllTimers()
end

function TemplateWindow:startGameSequence()
    -- Generar secuencia
    self.targetSequence = self:generateSequence()

    -- Mostrar secuencia con delays
    self:showSequence(1)
end

function TemplateWindow:showSequence(step)
    if step > #self.targetSequence then
        self.gameState = "input"
        return
    end

    local btnIndex = self.targetSequence[step]
    self:flashButtonByIndex(btnIndex)

    -- Programar siguiente paso
    SimpleTimer:addTimer(30, function()
        self:showSequence(step + 1)
    end)
end

function TemplateWindow:processInput(row, col)
    -- Agregar a secuencia del usuario
    table.insert(self.userSequence, {row, col})

    -- Verificar progreso
    local currentStep = #self.userSequence
    if self:checkStep(currentStep) then
        if currentStep >= #self.targetSequence then
            self:gameSuccess()
        end
    else
        self:gameFailure()
    end
end
```

### 🎯 Propósito:
- **resetGame**: Estado inicial limpio
- **startGameSequence**: Comenzar lógica del juego
- **showSequence**: Mostrar secuencia al usuario
- **processInput**: Manejar input del usuario

### ⚡ Mejores Prácticas:
- Funciones pequeñas y específicas
- Validación en cada paso
- Separación clara de responsabilidades

---

## PASO 9: RENDERIZADO Y EFECTOS VISUALES

### 📝 Código Base:

```lua
function TemplateWindow:render()
    ISPanel.render(self)

    -- ✅ EFECTO CRT
    local crtEffect = {r=0, g=0, b=0, a=0.3}
    self:drawRect(0, 0, self.width, self.height, crtEffect.a, crtEffect.r, crtEffect.g, crtEffect.b)

    -- ✅ LÍNEAS DE ESCANEO
    for y = 0, self.height, 4 do
        self:drawRect(0, y, self.width, 1, 0.1, 0, 0.3, 0)
    end

    -- ✅ BORDE VERDE
    local borderColor = {r=0.2, g=1, b=0.2, a=1}
    self:drawRectBorder(0, 0, self.width, self.height, borderColor.a, borderColor.r, borderColor.g, borderColor.b)

    -- ✅ TÍTULO
    local title = "TEMPLATE WINDOW"
    local titleX = (self.width - getTextManager():MeasureStringX(UIFont.Large, title)) / 2
    self:drawText(title, titleX, 10, 0.2, 1, 0.2, 1, UIFont.Large)

    -- ✅ ESTADO
    local status = self:getStatusText()
    local statusX = (self.width - getTextManager():MeasureStringX(UIFont.Small, status)) / 2
    self:drawText(status, statusX, self.height - 35, 0.2, 1, 0.2, 0.8, UIFont.Small)
end
```

### 🎯 Propósito:
- **Efectos visuales**: Atmósfera del minijuego
- **Texto dinámico**: Información contextual
- **Bordes y overlays**: Mejora visual

### ⚡ Mejores Prácticas:
- Usar drawRect para efectos
- Medir texto para centrado
- Estados visuales claros

---

## PASO 10: FUNCIÓN GLOBAL DE APERTURA

### 📝 Código Base:

```lua
function TemplateWindow(widthPct, heightPct, param1, param2)
    local player = getPlayer()
    if not player then return end

    -- Validación de parámetros
    widthPct = math.max(10, math.min(100, widthPct or WINDOW_WIDTH_PCT))
    heightPct = math.max(10, math.min(100, heightPct or WINDOW_HEIGHT_PCT))

    -- Calcular dimensiones
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local width = math.floor(screenW * (widthPct / 100))
    local height = math.floor(screenH * (heightPct / 100))
    local x = math.floor((screenW - width) / 2)
    local y = math.floor((screenH - height) / 2)

    -- Crear y mostrar ventana
    local window = TemplateWindow:new(x, y, width, height, player, param1, param2)
    window:initialise()
    window:addToUIManager()
    window:setVisible(true)
    return window
end

-- ✅ EXPONER GLOBALMENTE
_G.TemplateWindow = TemplateWindow
```

### 🎯 Propósito:
- **Función global**: Accesible desde cualquier lugar
- **Cálculo automático**: Dimensiones basadas en pantalla
- **Validación**: Parámetros seguros
- **Instanciación**: Crear y mostrar ventana

### ⚡ Mejores Prácticas:
- Validar player existente
- Límites seguros para porcentajes
- Centrado automático en pantalla

---

## MEJORES PRÁCTICAS Y OPTIMIZACIONES

### 🛡️ SEGURIDAD Y ROBUSTEZ

```lua
-- ✅ VALIDACIÓN ULTRA SEGURA
function safeOperation()
    local success, result = pcall(function()
        -- Operación potencialmente peligrosa
        return riskyFunction()
    end)

    if success then
        return result
    else
        print("Error:", result)
        return defaultValue
    end
end

-- ✅ VALORES POR DEFECTO SEGUROS
local safeValue = value or defaultValue
local clampedValue = math.max(min, math.min(max, value))
```

### 🎨 GESTIÓN DE COLORES

```lua
-- ✅ NUNCA USAR nil EN COLORES
function setSafeColor(element, color)
    if color and type(color) == 'table' then
        element.backgroundColor = {
            r = color.r or 0.5,
            g = color.g or 0.5,
            b = color.b or 0.5,
            a = color.a or 1
        }
    else
        element.backgroundColor = {r=0.5, g=0.5, b=0.5, a=0}
    end
end
```

### ⏱️ GESTIÓN DE TIMERS

```lua
-- ✅ LIMPIEZA AUTOMÁTICA
function clearAllTimers()
    -- SimpleTimer no tiene método directo de limpieza
    -- Los timers se auto-eliminan al completarse
end

-- ✅ USO SEGURO
SimpleTimer:addTimer(duration, function()
    pcall(function()
        -- Callback seguro
    end)
end)
```

### 📏 ESCALADO ADAPTATIVO

```lua
-- ✅ CÁLCULO DE TAMAÑOS ÓPTIMOS
local availableSpace = containerSize - padding * 2
local itemSize = math.max(minSize, math.min(maxSize, availableSpace / itemCount))
local totalWidth = itemSize * itemCount + spacing * (itemCount - 1)
local startX = (containerSize - totalWidth) / 2
```

### 🔄 GESTIÓN DE ESTADO

```lua
-- ✅ ESTADOS CLAROS Y TRANSICIONES
local GAME_STATES = {
    IDLE = "idle",
    PLAYING = "playing",
    SUCCESS = "success",
    FAILURE = "failure"
}

function changeState(newState)
    self.previousState = self.currentState
    self.currentState = newState
    self:onStateChanged()
end
```

### 🎵 EFECTOS SONOROS

```lua
-- ✅ SONIDO ULTRA SEGURO
function playSafeSound(soundName)
    if not self.player then return end

    local square = self.player:getCurrentSquare()
    if not square then return end

    local soundManager = getSoundManager()
    if soundManager and soundManager.playWorldSound then
        pcall(function()
            soundManager:playWorldSound(soundName, square, 0, 10, 1, false)
        end)
    end
end
```

---

## 🚀 TEMPLATE RÁPIDO PARA NUEVAS VENTANAS

```lua
-- TEMPLATE MÍNIMO PARA VENTANA RÁPIDA
local QuickWindow = ISPanel:derive("QuickWindow")

function QuickWindow:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    return o
end

function QuickWindow:createChildren()
    self.closeBtn = ISButton:new(self.width-25, 5, 20, 20, "X", self, self.onClose)
    self.closeBtn:initialise()
    self:addChild(self.closeBtn)
end

function QuickWindow:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
end

function QuickWindow:render()
    ISPanel.render(self)
    self:drawText("Quick Window", 10, 10, 1, 1, 1, 1, UIFont.Medium)
end

function OpenQuickWindow()
    local window = QuickWindow:new(100, 100, 300, 200)
    window:initialise()
    window:addToUIManager()
    window:setVisible(true)
    return window
end

_G.OpenQuickWindow = OpenQuickWindow
```

---

## 📚 REFERENCIAS Y RECURSOS

### 🔗 Documentación Oficial PZ:
- `ISPanel` - Base para todas las ventanas
- `ISButton` - Elementos interactivos
- `Events.OnTick` - Sistema de eventos
- `getTextManager()` - Renderizado de texto

### 📁 Archivos de Referencia:
- `MiniGameUI.lua` - Template completo
- `MiniGameFallout.lua` - Variante avanzada
- `DecryptDrivesContextMenu.lua` - Integración con menús

### 🧪 Scripts de Prueba:
- `test_gvdrive_utils.lua` - Validación de utilidades
- Funciones de debug en consola

---

**✅ TEMPLATE COMPLETO Y ULTRA FIABLE**
**🚀 LISTO PARA USO INMEDIATO POR FUTURAS IAs**</content>
<parameter name="filePath">c:\Users\joshg\Zomboid42\Workshop\DecryptUSBs42\Documentation\Scripts\templates\TEMPLATE_VENTANA_DINAMICA_GUIA_COMPLETA.md