# SISTEMAS AVANZADOS ESPECIALIZADOS - PROJECT ZOMBOID

## ANÁLISIS DE MECÁNICAS COMPLEJAS Y FRAMEWORKS

---

## 1. SISTEMA DE CLASES Y HABILIDADES (SOTO)

### 1.1 Estructura de Ocupaciones Personalizadas
**Patrón Descubierto**: Las ocupaciones se definen mediante definiciones de ropa específicas.

```lua
-- Definición de ropa por ocupación
ClothingSelectionDefinitions.deliverymanocc = {
    Female = {
        Neck = {
            chance = 70,
            items = {"Base.Tie_Full", },
        },
    },
}

ClothingSelectionDefinitions.loaderocc = {
    Female = {
        Hat = {
            chance = 10,
            items = {"Base.Hat_Beany",},
        },
        Shirt = {
            items = {"Base.Shirt_Denim", "Base.Shirt_Workman"},
        },
    },
}
```

### 1.2 Patrón de Creación de Clases Personalizadas
```lua
-- Para crear clase "Hacker"
ClothingSelectionDefinitions.hackerocc = {
    Male = {
        Shirt = {
            items = {"Base.Tshirt_DefaultTEXTURE_TINT"},
        },
        Pants = {
            items = {"Base.Trousers_DefaultTEXTURE_TINT"},
        },
        -- Probabilidades especiales
        Glasses = {
            chance = 80,  -- Alta probabilidad de lentes
            items = {"Base.Glasses_Normal"},
        },
    },
}
```

---

## 2. FRAMEWORK DE MOODLES PERSONALIZADOS

### 2.1 Sistema MoodleFramework
**Funcionalidad**: Framework para crear moodles personalizados fácilmente.

#### Estructura del Framework:
```lua
MF = MF or {}
MF.Moodles = MF.Moodles or {}
MF.MoodlesStorage = MF.MoodlesStorage or {}

-- Creación de moodle
function MF.createMoodle(moodleName)
    Events.OnCreatePlayer.Add(function(playerNum) 
        MF.ISMoodle:new(moodleName, getSpecificPlayer(playerNum)) 
    end);
end

-- Acceso a moodle
function MF.getMoodle(moodleName, playerNum)
    if not playerNum then playerNum = 0 end
    if not MF.MoodlesStorage[playerNum] then return nil end
    return MF.MoodlesStorage[playerNum][moodleName]
end
```

### 2.2 Uso del Framework
```lua
-- En tu mod:
require "MF_ISMoodle"

-- Crear moodle personalizado
MF.createMoodle("Hacking");

-- Usar el moodle
local hackingMoodle = MF.getMoodle("Hacking", 0)
if hackingMoodle then
    hackingMoodle:setValue(0.8) -- 0.0 a 1.0
end
```

### 2.3 Estructura de Traducciones para Moodles
```lua
Moodles_EN = {
    Moodles_Hacking_Good_lvl1 = "Focused",
    Moodles_Hacking_Good_desc_lvl1 = "Slightly better at hacking",
    Moodles_Hacking_Good_lvl2 = "In the Zone",
    Moodles_Hacking_Good_desc_lvl2 = "Much better at hacking",
    Moodles_Hacking_Bad_lvl1 = "Distracted",
    Moodles_Hacking_Bad_desc_lvl1 = "Worse at hacking",
}
```

---

## 3. SISTEMA DE DIBUJO EN MAPAS

### 3.1 Herramienta de Dibujo Libre
**Funcionalidad**: Permite dibujar líneas libres en el mapa del mundo.

```lua
WorldMapSymbolTool_FreeHandTool = ISWorldMapSymbolTool:derive("WorldMapSymbolTool_FreeHandTool")

function WorldMapSymbolTool_FreeHandTool:onMouseDown(x, y)
    self.drawingActive = true;
    self.lastWorldX = self.mapAPI:uiToWorldX(x, y);
    self.lastWorldY = self.mapAPI:uiToWorldY(x, y);
    self:addSymbol(self.lastWorldX, self.lastWorldY, true)
    return true
end

function WorldMapSymbolTool_FreeHandTool:onMouseMove(dx, dy)
    if self.drawingActive then
        local mouseX = self:getMouseX()
        local mouseY = self:getMouseY()
        self:drawLine(mouseX, mouseY);
    end
    return false
end
```

### 3.2 Patrón de Conversión Coordenadas
```lua
-- Convertir coordenadas UI a mundo
local worldX = self.mapAPI:uiToWorldX(x, y)
local worldY = self.mapAPI:uiToWorldY(x, y)

-- Dibujar línea entre puntos
function WorldMapSymbolTool_FreeHandTool:drawLine(x, y)
    local worldX = self.mapAPI:uiToWorldX(x, y)
    local worldY = self.mapAPI:uiToWorldY(x, y)
    
    -- Calcular distancia para suavizar línea
    local distance = math.sqrt((worldX - self.lastWorldX)^2 + (worldY - self.lastWorldY)^2)
    
    if distance > self.minDistance then
        self:addSymbol(worldX, worldY, false)
        self.lastWorldX = worldX
        self.lastWorldY = worldY
    end
end
```

---

## 4. SISTEMA DE ANIMACIONES Y POSICIONES

### 4.1 Modificación de Posición de Jugador (True Crawl)
**Funcionalidad**: Permite que los jugadores se acuesten en el suelo.

```lua
-- Cambiar estado de posición
function TrueCrawl.setCrawlState(player, isCrawling)
    if isCrawling then
        player:setVariable("CrawlState", "crawling")
        player:setVariable("BumpFall", true)
        -- Aplicar modificadores
        player:getStats():setEndurance(player:getStats():getEndurance() - 0.1)
    else
        player:setVariable("CrawlState", "standing")
        player:setVariable("BumpFall", false)
    end
end

-- Modificadores mientras está acostado
function TrueCrawl.updateCrawlEffects(player)
    if player:getVariable("CrawlState") == "crawling" then
        -- Mejor puntería pero movimiento lento
        player:setAimingMod(player:getAimingMod() + 0.2)
        player:setRunSpeedModifier(0.3) -- 30% velocidad
    end
end
```

### 4.2 Patrón de Modificadores Temporales
```lua
-- Sistema de bonificaciones por posición
local PositionBonuses = {}

function PositionBonuses.applyAimingBonus(player, position, duration)
    local bonusData = {
        player = player,
        position = position,
        startTime = getGameTime():getWorldAgeHours(),
        duration = duration,
        aimingBonus = 0.15
    }
    
    table.insert(PositionBonuses.activeBonuses, bonusData)
end

Events.OnPlayerUpdate.Add(function(player)
    for i = #PositionBonuses.activeBonuses, 1, -1 do
        local bonus = PositionBonuses.activeBonuses[i]
        local elapsed = getGameTime():getWorldAgeHours() - bonus.startTime
        
        if elapsed >= bonus.duration then
            -- Remover bonus
            table.remove(PositionBonuses.activeBonuses, i)
        else
            -- Aplicar bonus
            if bonus.position == "crouched" then
                player:setAimingMod(player:getAimingMod() + bonus.aimingBonus)
            end
        end
    end
end)
```

---

## 5. SISTEMA DE UI PERSONALIZADA PARA SALUD

### 5.1 Ventana de Monitoreo de Salud
```lua
HealthMonitorUI = ISPanel:derive("HealthMonitorUI")

function HealthMonitorUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    o.backgroundColor = {r=0, g=0, b=0, a=0.8}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    
    return o
end

function HealthMonitorUI:render()
    ISPanel.render(self)
    
    local player = getPlayer()
    if not player then return end
    
    -- Dibujar barras de salud
    local health = player:getStats():getHealth()
    local maxHealth = 100
    
    -- Barra de fondo
    self:drawRect(10, 30, 200, 20, 1, 0.2, 0.2, 0.2)
    
    -- Barra de salud
    local healthWidth = (health / maxHealth) * 200
    self:drawRect(10, 30, healthWidth, 20, 1, 0.8, 0.2, 0.2)
    
    -- Texto de salud
    self:drawText("Health: " .. math.floor(health) .. "/" .. maxHealth, 
                  10, 10, 1, 1, 1, 1, UIFont.Medium)
end
```

---

## 6. MODIFICACIÓN DE MECÁNICAS DEL JUEGO

### 6.1 Equipar Items Mientras Corres
```lua
-- Override de la función original
local originalCanPerformAction = ISInventoryPane.canPerformAction

function ISInventoryPane:canPerformAction(action, item)
    local player = getPlayer()
    
    -- Permitir equipar mientras corre
    if action == "equip" and player:isRunning() then
        return true
    end
    
    return originalCanPerformAction(self, action, item)
end

-- Modificar tiempo de equipado mientras corre
local originalGetEquipTime = ISWearClothing.getEquipTime

function ISWearClothing:getEquipTime()
    local baseTime = originalGetEquipTime(self)
    
    if self.character:isRunning() then
        return baseTime * 1.5 -- 50% más tiempo mientras corre
    end
    
    return baseTime
end
```

### 6.2 Patrón de Modificación de Acciones
```lua
-- Sistema genérico para modificar acciones
local ActionModifier = {}

function ActionModifier.modifyAction(actionType, condition, modifier)
    local originalFunction = ISTimedActionQueue[actionType]
    
    ISTimedActionQueue[actionType] = function(self, ...)
        local player = getPlayer()
        
        if condition(player) then
            -- Aplicar modificador
            local result = originalFunction(self, ...)
            modifier(player, result)
            return result
        else
            return originalFunction(self, ...)
        end
    end
end

-- Uso: Leer mientras camina
ActionModifier.modifyAction("ISReadABook", 
    function(player) return player:isWalking() end,
    function(player, result) 
        -- Reducir velocidad de lectura
        result.maxTime = result.maxTime * 1.3
    end
)
```

---

## 7. SISTEMA DE INTERCAMBIO DINÁMICO DE ARMAS

### 7.1 SwapIt - Cambio Rápido de Armas
```lua
SwapIt = {}
SwapIt.weaponSlots = {}

-- Registrar arma en slot
function SwapIt.registerWeapon(player, slotNumber, weapon)
    local playerNum = player:getPlayerNum()
    SwapIt.weaponSlots[playerNum] = SwapIt.weaponSlots[playerNum] or {}
    SwapIt.weaponSlots[playerNum][slotNumber] = weapon
end

-- Cambiar a arma específica
function SwapIt.swapToWeapon(player, slotNumber)
    local playerNum = player:getPlayerNum()
    local weapon = SwapIt.weaponSlots[playerNum][slotNumber]
    
    if weapon and player:getInventory():contains(weapon) then
        -- Desequipar arma actual
        local currentWeapon = player:getPrimaryHandItem()
        if currentWeapon then
            ISInventoryPaneContextMenu.unequipItem(currentWeapon, player)
        end
        
        -- Equipar nueva arma
        ISInventoryPaneContextMenu.equipWeapon(weapon, true, false, player:getPlayerNum())
    end
end

-- Eventos de teclado
Events.OnKeyPressed.Add(function(key)
    local player = getPlayer()
    if not player then return end
    
    -- Teclas 1-9 para cambiar armas
    if key >= Keyboard.KEY_1 and key <= Keyboard.KEY_9 then
        local slotNumber = key - Keyboard.KEY_1 + 1
        SwapIt.swapToWeapon(player, slotNumber)
    end
end)
```

---

*Este documento analiza sistemas avanzados que permiten crear mecánicas complejas como clases personalizadas, moodles, dibujo en mapas, modificación de animaciones y UI personalizada.*
