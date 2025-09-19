# PATRONES DE UI Y MINIJUEGOS EN PROJECT ZOMBOID

## ANÁLISIS PROFUNDO DE INTERFACES Y MECÁNICAS INTERACTIVAS

---

## 1. PATRÓN DE MODIFICACIÓN DE INVENTARIO (PROXIMITY INVENTORY)

### 1.1 Estructura del Mod de Proximidad
**Funcionalidad**: Muestra inventarios de contenedores cercanos automáticamente.

#### Arquitectura del Sistema:
```
ProximityInventory/
├── media/
│   ├── lua/
│   │   ├── client/
│   │   │   ├── 1ProximityInventory.core.lua      # ← Núcleo del sistema
│   │   │   └── 2ProximityInventory.client.lua    # ← Lógica cliente
│   │   └── shared/
│   ├── ui/                                       # ← Texturas de UI
│   └── sandbox-options.txt                       # ← Configuración
```

### 1.2 Patrón de Modificación de UI Existente:
```lua
-- Módulo principal
ProxInv = {}
ProxInv.isToggled = true
ProxInv.isHighlightEnable = true
ProxInv.isForceSelected = false

-- Carga de texturas de UI
ProxInv.inventoryIcon = getTexture("media/ui/ProximityInventory.png")
ProxInv.forceSelectIcon = getTexture("media/ui/Panel_Icon_Pin.png")
ProxInv.highlightIcon = getTexture("media/textures/Item_LightBulb.png")

-- Función de toggle del estado
ProxInv.toggleState = function()
    ProxInv.isToggled = not ProxInv.isToggled
    ISInventoryPage.dirtyUI() -- ← Fuerza actualización de UI
end

-- Integración con sistema de traducciones
ProxInv.getTooltip = function()
    if ProxInv.isToggled then
        return getText("IGUI_ProxInv_Tooltip_ToggleOn")
    else
        return getText("IGUI_ProxInv_Tooltip_ToggleOff")
    end
end
```

### 1.3 Patrón de Filtrado Condicional:
```lua
-- Definición de tipos válidos
ProxInv.zombieTypes = {
    inventoryfemale = true,
    inventorymale = true,
}

-- Función de validación con sandbox options
ProxInv.canBeAdded = function(container, playerObj)
    local object = container:getParent()
    
    -- Usar configuración de sandbox para filtrar
    if SandboxVars.ProxInv.ZombieOnly then
        return ProxInv.zombieTypes[container:getType()]
    end
    
    -- Validaciones adicionales
    if object and instanceof(object, "IsoThumpable") and object:isLockedToCharacter(playerObj) then
        return false
    end
    
    return true
end
```

---

## 2. PATRÓN DE CREACIÓN DE VENTANAS PERSONALIZADAS

### 2.1 Estructura Base de Ventana ISPanel:
```lua
-- Definición de clase de ventana personalizada
local CustomWindow = ISPanel:derive("CustomWindow")

function CustomWindow:new(x, y, width, height, player)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    -- Propiedades de la ventana
    o.player = player
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.moveWithMouse = true
    
    return o
end

-- Inicialización de componentes
function CustomWindow:initialise()
    ISPanel.initialise(self)
    
    -- Crear botones y elementos
    self:createChildren()
end

-- Creación de elementos hijos
function CustomWindow:createChildren()
    -- Botón de cierre
    self.closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)
    
    -- Label de título
    self.titleLabel = ISLabel:new(10, 10, 20, getText("UI_CustomWindow_Title"), 1, 1, 1, 1, UIFont.Medium, true)
    self:addChild(self.titleLabel)
end

-- Renderizado personalizado
function CustomWindow:render()
    ISPanel.render(self)
    
    -- Renderizado adicional personalizado
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
end

-- Manejo de eventos
function CustomWindow:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
end
```

### 2.2 Patrón de Widgets Complejos:
```lua
-- ComboBox personalizado
function CustomWindow:createComboBox(x, y, width, height, items)
    local combo = ISComboBox:new(x, y, width, height, self, self.onComboChange)
    
    for i, item in ipairs(items) do
        combo:addOption(item.text, item.data)
    end
    
    combo:initialise()
    self:addChild(combo)
    return combo
end

-- TextBox con validación
function CustomWindow:createValidatedTextBox(x, y, width, height, validator)
    local textBox = ISTextEntryBox:new("", x, y, width, height)
    textBox.font = UIFont.Medium
    textBox:initialise()
    
    -- Override del evento de cambio de texto
    local originalOnTextChange = textBox.onTextChange
    textBox.onTextChange = function()
        originalOnTextChange(textBox)
        if validator and not validator(textBox:getInternalText()) then
            textBox.borderColor = {r=1, g=0, b=0, a=1} -- Rojo para error
        else
            textBox.borderColor = {r=0.4, g=0.4, b=0.4, a=1} -- Normal
        end
    end
    
    self:addChild(textBox)
    return textBox
end
```

---

## 3. PATRÓN DE MOODLES PERSONALIZADOS

### 3.1 Definición de Moodle en Scripts:
```
module ModuleName
{
    moodle CustomMoodle
    {
        GoodBadNeutral = Bad,           # Tipo: Good, Bad, Neutral
        Type = Endurance,               # Categoría del moodle
        Level4 = 80,                    # Umbrales de nivel
        Level3 = 60,
        Level2 = 40,
        Level1 = 20,
    }
}
```

### 3.2 Manejo de Moodles en Lua:
```lua
-- Sistema de moodles personalizado
local MoodleSystem = {}

-- Aplicar moodle
function MoodleSystem.applyMoodle(player, moodleName, level)
    local moodles = player:getMoodles()
    moodles:setMoodleLevel(MoodleType[moodleName], level)
end

-- Obtener nivel de moodle
function MoodleSystem.getMoodleLevel(player, moodleName)
    local moodles = player:getMoodles()
    return moodles:getMoodleLevel(MoodleType[moodleName])
end

-- Sistema de efectos temporales
function MoodleSystem.applyTemporaryEffect(player, moodleName, level, duration)
    -- Aplicar efecto
    MoodleSystem.applyMoodle(player, moodleName, level)
    
    -- Programar remoción
    local removeTime = getGameTime():getWorldAgeHours() + duration
    player:getModData().tempEffects = player:getModData().tempEffects or {}
    table.insert(player:getModData().tempEffects, {
        moodle = moodleName,
        removeTime = removeTime
    })
end

-- Actualización de efectos temporales
Events.OnPlayerUpdate.Add(function(player)
    local tempEffects = player:getModData().tempEffects
    if not tempEffects then return end
    
    local currentTime = getGameTime():getWorldAgeHours()
    for i = #tempEffects, 1, -1 do
        local effect = tempEffects[i]
        if currentTime >= effect.removeTime then
            MoodleSystem.applyMoodle(player, effect.moodle, 0)
            table.remove(tempEffects, i)
        end
    end
end)
```

---

## 4. PATRÓN DE MINIJUEGOS

### 4.1 Estructura Base de Minijuego:
```lua
-- Clase base para minijuegos
local MiniGame = ISPanel:derive("MiniGame")

function MiniGame:new(x, y, width, height, onSuccess, onFailure)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.onSuccess = onSuccess
    o.onFailure = onFailure
    o.gameState = "waiting" -- waiting, playing, success, failure
    o.startTime = 0
    o.timeLimit = 30 -- segundos
    
    return o
end

-- Iniciar minijuego
function MiniGame:startGame()
    self.gameState = "playing"
    self.startTime = getTimestampMs()
    self:setupGameElements()
end

-- Configurar elementos del juego
function MiniGame:setupGameElements()
    -- Implementar en subclases
end

-- Actualización del juego
function MiniGame:update()
    ISPanel.update(self)
    
    if self.gameState == "playing" then
        local elapsed = (getTimestampMs() - self.startTime) / 1000
        
        if elapsed >= self.timeLimit then
            self:endGame(false) -- Tiempo agotado
        else
            self:updateGameLogic(elapsed)
        end
    end
end

-- Finalizar juego
function MiniGame:endGame(success)
    self.gameState = success and "success" or "failure"
    
    if success and self.onSuccess then
        self.onSuccess()
    elseif not success and self.onFailure then
        self.onFailure()
    end
    
    -- Cerrar después de mostrar resultado
    self:setVisible(false)
    self:removeFromUIManager()
end
```

### 4.2 Minijuego de Lockpicking:
```lua
local LockpickingGame = MiniGame:derive("LockpickingGame")

function LockpickingGame:setupGameElements()
    -- Crear pins del candado
    self.pins = {}
    self.pinCount = 5
    self.solvedPins = 0
    
    for i = 1, self.pinCount do
        self.pins[i] = {
            x = 50 + (i * 40),
            y = 100,
            height = ZombRand(20, 60),
            targetHeight = ZombRand(10, 50),
            currentHeight = 0,
            solved = false
        }
    end
    
    -- Crear herramientas
    self.lockpick = {
        x = 100,
        y = 200,
        selectedPin = 1
    }
end

function LockpickingGame:updateGameLogic(elapsed)
    -- Lógica de input del jugador
    if isKeyPressed(Keyboard.KEY_LEFT) and self.lockpick.selectedPin > 1 then
        self.lockpick.selectedPin = self.lockpick.selectedPin - 1
    elseif isKeyPressed(Keyboard.KEY_RIGHT) and self.lockpick.selectedPin < self.pinCount then
        self.lockpick.selectedPin = self.lockpick.selectedPin + 1
    end
    
    -- Ajustar altura del pin seleccionado
    local selectedPin = self.pins[self.lockpick.selectedPin]
    if isKeyDown(Keyboard.KEY_SPACE) then
        selectedPin.currentHeight = selectedPin.currentHeight + 1
        
        -- Verificar si está en la posición correcta
        if math.abs(selectedPin.currentHeight - selectedPin.targetHeight) < 3 then
            if not selectedPin.solved then
                selectedPin.solved = true
                self.solvedPins = self.solvedPins + 1
                
                -- Verificar victoria
                if self.solvedPins >= self.pinCount then
                    self:endGame(true)
                end
            end
        end
    end
end

function LockpickingGame:render()
    MiniGame.render(self)
    
    -- Renderizar pins
    for i, pin in ipairs(self.pins) do
        local color = pin.solved and {0, 1, 0, 1} or {0.5, 0.5, 0.5, 1}
        if i == self.lockpick.selectedPin then
            color = {1, 1, 0, 1} -- Amarillo para seleccionado
        end
        
        self:drawRect(pin.x, pin.y, 20, pin.height, color[4], color[1], color[2], color[3])
        
        -- Mostrar objetivo
        self:drawRect(pin.x + 25, pin.y + pin.targetHeight, 15, 3, 1, 1, 0, 0)
        
        -- Mostrar posición actual
        if pin.currentHeight > 0 then
            self:drawRect(pin.x + 5, pin.y + pin.currentHeight, 10, 2, 1, 0, 0, 1)
        end
    end
    
    -- Renderizar lockpick
    local selectedPin = self.pins[self.lockpick.selectedPin]
    self:drawRect(selectedPin.x + 10, selectedPin.y + 70, 2, 20, 1, 0.8, 0.8, 0.8)
end
```

---

## 5. PATRÓN DE INTEGRACIÓN CON SISTEMA DE FOTOS (ZOMBAROID)

### 5.1 Captura de Screenshots In-Game:
```lua
local PhotoSystem = {}

-- Tomar foto
function PhotoSystem.takePhoto(player, camera, film)
    -- Verificar que tiene film
    if not PhotoSystem.hasFilm(camera) then
        player:Say(getText("Photo_NoFilm"))
        return false
    end
    
    -- Capturar screenshot
    local screenshot = captureScreenshot()
    
    -- Crear item de foto
    local photo = InventoryItemFactory.CreateItem("Zombaroid.Photo")
    photo:getModData().screenshot = screenshot
    photo:getModData().timestamp = getGameTime():getWorldAgeHours()
    photo:getModData().location = player:getCurrentSquare():getX() .. "," .. player:getCurrentSquare():getY()
    
    -- Añadir al inventario
    player:getInventory():AddItem(photo)
    
    -- Consumir film si no es ilimitado
    if not SandBoxVars.Zombaroid.UnlimitedFilm then
        PhotoSystem.consumeFilm(camera)
    end
    
    -- Sonido de cámara
    player:playSound("CameraShutter")
    
    return true
end

-- Verificar film disponible
function PhotoSystem.hasFilm(camera)
    return camera:getModData().filmCount and camera:getModData().filmCount > 0
end

-- Consumir film
function PhotoSystem.consumeFilm(camera)
    local filmCount = camera:getModData().filmCount or 0
    camera:getModData().filmCount = math.max(0, filmCount - 1)
end

-- Cargar film en cámara
function PhotoSystem.loadFilm(camera, filmRoll)
    local filmAmount = filmRoll:getUsedDelta() * 24 -- 24 fotos por rollo
    camera:getModData().filmCount = (camera:getModData().filmCount or 0) + filmAmount
end
```

### 5.2 Visualización de Fotos:
```lua
-- Ventana de visualización de fotos
local PhotoViewer = ISPanel:derive("PhotoViewer")

function PhotoViewer:new(x, y, width, height, photo)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.photo = photo
    o.screenshot = photo:getModData().screenshot
    
    return o
end

function PhotoViewer:render()
    ISPanel.render(self)
    
    -- Renderizar screenshot
    if self.screenshot then
        self:drawTexture(self.screenshot, 10, 30, 1, 1, 1, 1)
    end
    
    -- Información de la foto
    local timestamp = self.photo:getModData().timestamp
    local location = self.photo:getModData().location
    
    self:drawText(getText("Photo_Timestamp") .. ": " .. timestamp, 10, 10, 1, 1, 1, 1, UIFont.Small)
    self:drawText(getText("Photo_Location") .. ": " .. location, 10, self.height - 20, 1, 1, 1, 1, UIFont.Small)
end
```

---

*Este documento detalla los patrones avanzados para crear interfaces de usuario, minijuegos y sistemas interactivos complejos en Project Zomboid.*
