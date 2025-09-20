-- LaptopBatteryWidget.lua — REMOVED
-- This file previously implemented a client-side laptop battery UI widget.
-- The feature has been intentionally removed (kept as an inert stub) per project maintainers' request.
-- Reason: feature will be reworked later; keeping a live implementation caused runtime errors and is unused.

-- No-op stub: do not register events or expose any functions. If other modules still call
-- `showLaptopBatteryWidget` or `createLaptopBatteryWidget`, they should guard the call (check existence)
-- or the call will be a no-op here. This avoids runtime errors while preserving the file for history.

-- Example of safe guard when calling this API elsewhere (recommended):
-- if showLaptopBatteryWidget then showLaptopBatteryWidget(laptop) end

return
        
        -- Get item type safely
        pcall(function()
            itemType = item:getFullType() or "Unknown"
        end)
        
        -- Get display name safely
        pcall(function()
            displayName = item:getDisplayName() or "Laptop"
        end)
        
        -- Try to get health safely
        if LaptopSystem and LaptopSystem.getLaptopHealth then
            pcall(function()
                local result = LaptopSystem.getLaptopHealth(item)
                if result then
                    health = result
                end
            end)
        else
            pcall(function()
                if item.getCondition then
                    local result = item:getCondition()
                    if result then
                        health = result
                    end
                end
            end)
        end
        
    debugPrint("Laptop processed: type=" .. tostring(itemType) .. ", health=" .. tostring(health))
        
        -- Get laptop name safely
        local laptopName = displayName
        if LAPTOP_TYPES and LAPTOP_TYPES[itemType] then
            laptopName = LAPTOP_TYPES[itemType]
        end
        
        laptopBatteryWidget.currentLaptop = {
            item = item,
            type = itemType,
            name = laptopName,
            health = health
        }
        laptopBatteryWidget.currentBattery = health
        
    debugPrint("Widget configured with laptop: " .. laptopName .. " (" .. health .. "%)")

        -- Decir estado por el personaje (incluye porcentaje)
        local player = getSpecificPlayer and getSpecificPlayer(0) or (getPlayer and getPlayer() or nil)
        if player then
            local pct = math.floor(tonumber(health) or 0)
            local statusText = ""
            if pct > 75 then
                statusText = getText and (getText("IGUI_Status_Excellent") or "Excelente") or "Excelente"
            elseif pct > 50 then
                statusText = getText and (getText("IGUI_Status_Good") or "Bueno") or "Bueno"
            elseif pct > 25 then
                statusText = getText and (getText("IGUI_Status_Warning") or "Advertencia") or "Advertencia"
            elseif pct > 10 then
                statusText = getText and (getText("IGUI_Status_Critical") or "Crítico") or "Crítico"
            else
                statusText = getText and (getText("IGUI_Status_Failing") or "Fallando") or "Fallando"
            end
            local msg = string.format("%s - Batería: %d%% (%s)", tostring(laptopName), pct, statusText)
            pcall(function() player:Say(msg) end)
        end
    else
        -- Laptop de prueba
        laptopBatteryWidget.currentLaptop = {
            name = "Test Laptop",
            health = 75
        }
        laptopBatteryWidget.currentBattery = 75
    end
    
    -- Mostrar widget
    laptopBatteryWidget.isVisible = true
    laptopBatteryWidget:setVisible(true)
    laptopBatteryWidget.lastVisibleTime = getTimestampMs()
    
    -- Programar que se oculte después del tiempo especificado
    local hideTime = getTimestampMs() + duration
    local hideFunction = nil
    
    hideFunction = function()
        local currentTime = getTimestampMs()
        if currentTime >= hideTime then
            if laptopBatteryWidget then
                debugPrint("Hiding widget after timeout")
                laptopBatteryWidget.isVisible = false
                laptopBatteryWidget:setVisible(false)
                laptopBatteryWidget.currentLaptop = nil
            end
            Events.OnTick.Remove(hideFunction)
        end
    end
    
    Events.OnTick.Add(hideFunction)
end

-- API sencilla para configurar la duración del widget desde otros módulos
function setLaptopBatteryWidgetDuration(ms)
    local v = tonumber(ms)
    if not v or v < 0 then return end
    BATTERY_CONFIG.displayDurationMs = v
end

function getLaptopBatteryWidgetDuration()
    return BATTERY_CONFIG.displayDurationMs or 10000
end

-- Definir las fases de batería (basado en Survival HUD)
local BATTERY_PHASES = {
    { 80, 100, 0, { 100, 95, 90, 85, 80 } },    -- Verde - Excelente
    { 60, 80,  1, { 75, 70, 65, 60 } },          -- Amarillo - Bueno
    { 40, 60,  2, { 55, 50, 45, 40 } },          -- Naranja - Regular
    { 20, 40,  3, { 35, 30, 25, 20 } },          -- Rojo claro - Bajo
    { 0,  20,  4, { 15, 10, 5 } }                -- Rojo - Crítico
}

LaptopBatteryWidget = ISPanel:derive("LaptopBatteryWidget")

function LaptopBatteryWidget:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }

    o.textureCache = {}
    o.lastUpdate = 0
    o.currentBattery = -1
    o.lastBatteryValue = -1
    o.currentLaptop = nil
    o.lastVisibleTime = 0
    o.isVisible = false

    return o
end

function LaptopBatteryWidget:initialise()
    debugPrint("Initializing widget...")
    
    local ok, err = pcall(function()
        ISPanel.initialise(self)
    end)
    
    if not ok then
        debugPrint("[LaptopBatteryWidget] Error in ISPanel.initialise: " .. tostring(err))
        return
    end
    
    self:setVisible(false)
    
    local posOk, posErr = pcall(function()
        self:updatePosition()
    end)
    
    if not posOk then
        debugPrint("[LaptopBatteryWidget] Error updating position: " .. tostring(posErr))
    end
    
    local texOk, texErr = pcall(function()
        self:preloadTextures()
    end)
    
    if not texOk then
        debugPrint("[LaptopBatteryWidget] Error preloading textures: " .. tostring(texErr))
    end
    
    debugPrint("Widget initialization completed")
end

function LaptopBatteryWidget:preloadTextures()
    debugPrint("Preloading battery textures...")
    
    -- Cargar fondos de batería (primero intentamos locales, luego fallback al Survival HUD)
    for i = 0, 4 do
        local bgKey = "battery_bg_" .. i
        
        -- Intentar cargar desde nuestro mod primero
        local localBgPath = "media/textures/ui/battery/background-" .. i .. ".png"
        self.textureCache[bgKey] = getTexture(localBgPath)
        
        if self.textureCache[bgKey] then
            debugPrint("Loaded local background: " .. localBgPath)
        else
            -- Fallback al Survival HUD
            local fallbackBgPath = "media/textures/ui/needs/fatigue/background-" .. i .. ".png"
            self.textureCache[bgKey] = getTexture(fallbackBgPath)
            if self.textureCache[bgKey] then
                debugPrint("Loaded fallback background: " .. fallbackBgPath)
            else
                debugPrint("Failed to load background for phase: " .. i)
            end
        end
    end

    -- Cargar iconos de batería (desde nuestro mod)
    local batteryValues = { 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100 }
    for _, value in ipairs(batteryValues) do
        local textureKey = "battery_" .. value
        
        -- Usar nuestros iconos locales
        local localTexturePath = "media/textures/ui/" .. value .. ".png"
        self.textureCache[textureKey] = getTexture(localTexturePath)
        
        if self.textureCache[textureKey] then
            debugPrint("Loaded local battery icon: " .. localTexturePath)
        else
            -- Fallback al Survival HUD si no existe local
            local fallbackTexturePath = "media/textures/ui/needs/fatigue/" .. value .. ".png"
            self.textureCache[textureKey] = getTexture(fallbackTexturePath)
            if self.textureCache[textureKey] then
                debugPrint("Loaded fallback battery icon: " .. fallbackTexturePath)
            else
                debugPrint("Failed to load battery icon: " .. value)
            end
        end
    end
    
    debugPrint("Texture preloading completed")
end

function LaptopBatteryWidget:updatePosition()
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()

    -- Posición más visible para debugging
    local x = screenWidth - BATTERY_CONFIG.iconSize - 50  -- Más cerca del borde
    local y = screenHeight - BATTERY_CONFIG.iconSize - 50 -- Más cerca del borde

    debugPrint("Setting widget position to: " .. x .. "," .. y)
    debugPrint("Screen size: " .. screenWidth .. "x" .. screenHeight)

    self:setX(x)
    self:setY(y)
    self:setWidth(BATTERY_CONFIG.iconSize)
    self:setHeight(BATTERY_CONFIG.iconSize)
    
    debugPrint("Widget bounds: " .. self:getX() .. "," .. self:getY() .. " " .. self:getWidth() .. "x" .. self:getHeight())
end

function LaptopBatteryWidget:getPhaseData(value)
    for _, phase in ipairs(BATTERY_PHASES) do
        if value >= phase[1] and value <= phase[2] then
            return phase
        end
    end
    return BATTERY_PHASES[#BATTERY_PHASES] -- Default to lowest phase
end

function LaptopBatteryWidget:getBestTexture(value, currentTextureValue)
    if value <= 0 then
        return nil
    end

    if currentTextureValue ~= -1 and math.abs(value - currentTextureValue) < BATTERY_CONFIG.updateThreshold then
        local phaseData = self:getPhaseData(value)
        for _, textureValue in ipairs(phaseData[4]) do
            if textureValue == currentTextureValue then
                return currentTextureValue
            end
        end
    end

    local phaseData = self:getPhaseData(value)
    local textures = phaseData[4]

    if #textures == 0 then
        return nil
    end

    local best = textures[1]
    local minDiff = math.abs(value - best)

    for _, texture in ipairs(textures) do
        local diff = math.abs(value - texture)
        if diff < minDiff then
            minDiff = diff
            best = texture
        end
    end

    return best
end

function LaptopBatteryWidget:findNearbyLaptop()
    local player = getSpecificPlayer(0)
    if not player then 
        debugPrint("No player found")
        return nil 
    end

    local playerSquare = player:getCurrentSquare()
    if not playerSquare then 
        debugPrint("No player square found")
        return nil 
    end

    debugPrint("Searching for laptops near player at " .. playerSquare:getX() .. "," .. playerSquare:getY())

    -- Buscar laptops en un radio específico
    for x = -BATTERY_CONFIG.searchRadius, BATTERY_CONFIG.searchRadius do
        for y = -BATTERY_CONFIG.searchRadius, BATTERY_CONFIG.searchRadius do
            local square = getCell():getGridSquare(
                playerSquare:getX() + x,
                playerSquare:getY() + y,
                playerSquare:getZ()
            )

            if square then
                -- Buscar objetos del mundo
                local worldObjects = square:getWorldObjects()
                if worldObjects and worldObjects:size() > 0 then
                    debugPrint("Found " .. worldObjects:size() .. " world objects at " .. (playerSquare:getX() + x) .. "," .. (playerSquare:getY() + y))
                    for i = 0, worldObjects:size() - 1 do
                        local worldObj = worldObjects:get(i)
                        if worldObj and worldObj:getItem() then
                            local item = worldObj:getItem()
                            local itemType = item:getFullType()
                            debugPrint("Found world item: " .. itemType)

                            if LAPTOP_TYPES[itemType] then
                                debugPrint("LAPTOP FOUND! Type: " .. itemType)
                                local healthVal = 100
                                if LaptopSystem and type(LaptopSystem.getLaptopHealth) == "function" then
                                    local ok, res = pcall(function() return LaptopSystem.getLaptopHealth(item) end)
                                    if ok and res then healthVal = res end
                                end
                                return {
                                    item = item,
                                    type = itemType,
                                    name = LAPTOP_TYPES[itemType],
                                    health = healthVal
                                }
                            end
                        end
                    end
                end
                
                -- También buscar en objetos regulares
                local objects = square:getObjects()
                if objects and objects:size() > 0 then
                    debugPrint("Found " .. objects:size() .. " regular objects at " .. (playerSquare:getX() + x) .. "," .. (playerSquare:getY() + y))
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if obj then
                            -- Intentar diferentes métodos para obtener el item
                            local item = nil
                            if obj.getItem then
                                item = obj:getItem()
                            elseif obj.item then
                                item = obj.item
                            end
                            
                            if item and item:getFullType() then
                                local itemType = item:getFullType()
                                debugPrint("Found regular object item: " .. itemType)
                                
                                if LAPTOP_TYPES[itemType] then
                                    debugPrint("LAPTOP FOUND in regular objects! Type: " .. itemType)
                                    local healthVal = 100
                                    if LaptopSystem and type(LaptopSystem.getLaptopHealth) == "function" then
                                        local ok, res = pcall(function() return LaptopSystem.getLaptopHealth(item) end)
                                        if ok and res then healthVal = res end
                                    end
                                    return {
                                        item = item,
                                        type = itemType,
                                        name = LAPTOP_TYPES[itemType],
                                        health = healthVal
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    debugPrint("No laptops found nearby")
    return nil
end

function LaptopBatteryWidget:getTooltip()
    if self.currentLaptop then
        local name = self.currentLaptop.name
        local battery = math.floor(self.currentBattery + 0.5)
        
        local statusText = ""
        if battery > 75 then
            statusText = "Excellent"
        elseif battery > 50 then
            statusText = "Good"
        elseif battery > 25 then
            statusText = "Warning"
        elseif battery > 10 then
            statusText = "Critical"
        else
            statusText = "Failing"
        end
        
        return string.format("%s\nBattery: %d%% (%s)", name, battery, statusText)
    end
    return nil
end

function LaptopBatteryWidget:drawTooltip(x, y, text)
    local font = UIFont.Small
    local fontHeight = getTextManager():getFontHeight(font)
    local padding = 8

    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end

    local maxWidth = 0
    for _, line in ipairs(lines) do
        local lineWidth = getTextManager():MeasureStringX(font, line)
        if lineWidth > maxWidth then
            maxWidth = lineWidth
        end
    end

    local tooltipWidth = maxWidth + padding * 2
    local tooltipHeight = (#lines * fontHeight) + padding * 2

    local screenWidth = getCore():getScreenWidth()

    if x + tooltipWidth > screenWidth then
        x = screenWidth - tooltipWidth
    end
    if y - tooltipHeight < 0 then
        y = tooltipHeight
    end

    -- Dibujar fondo del tooltip
    self:drawRect(x - self:getAbsoluteX(), y - tooltipHeight - self:getAbsoluteY(),
        tooltipWidth, tooltipHeight, 0.9, 0.1, 0.1, 0.1)

    -- Dibujar borde del tooltip
    self:drawRectBorder(x - self:getAbsoluteX(), y - tooltipHeight - self:getAbsoluteY(),
        tooltipWidth, tooltipHeight, 1.0, 0.7, 0.7, 0.7)

    -- Dibujar texto
    for i, line in ipairs(lines) do
        local lineY = y - tooltipHeight - self:getAbsoluteY() + padding + ((i - 1) * fontHeight)
        
        -- Color basado en el estado de la batería
        local color = { 1, 1, 1 } -- Blanco por defecto
        if i == 1 then -- Línea del título
            color = { 0.9, 0.9, 0.9 }
        elseif i == 2 and self.currentBattery then -- Línea de la batería
            if self.currentBattery > 60 then
                color = { 0.2, 0.8, 0.2 } -- Verde
            elseif self.currentBattery > 30 then
                color = { 1, 1, 0.2 } -- Amarillo
            elseif self.currentBattery > 10 then
                color = { 1, 0.6, 0 } -- Naranja
            else
                color = { 1, 0.2, 0.2 } -- Rojo
            end
        end

        self:drawText(line, x - self:getAbsoluteX() + padding, lineY, 
            color[1], color[2], color[3], 1, font)
    end
end

function LaptopBatteryWidget:render()
    -- Solo renderizar si está explícitamente visible
    if not self.isVisible or not self:getIsVisible() then 
        return 
    end
    
    -- Call parent render safely
    local ok, err = pcall(function()
        ISPanel.render(self)
    end)
    if not ok then
        print("[LaptopBatteryWidget] Error in ISPanel.render: " .. tostring(err))
        return
    end

    local player = getSpecificPlayer(0)
    if not player or player:isDead() then
        self:setVisible(false)
        return
    end

    if not self.currentLaptop or not self.currentBattery or self.currentBattery < 0 then
        debugPrint("No laptop data to render")
        return
    end

    debugPrint("Rendering battery widget with " .. self.currentBattery .. "% battery")

    -- Dibujar el widget de batería de forma segura
    local renderOk, renderErr = pcall(function()
        -- Dibujar fondo
        local phaseData = self:getPhaseData(self.currentBattery)
        local bgKey = "battery_bg_" .. phaseData[3]
        local bgTexture = self.textureCache[bgKey]
        
        if bgTexture then
            self:drawTextureScaled(bgTexture, 0, 0, BATTERY_CONFIG.iconSize, BATTERY_CONFIG.iconSize, 1, 1, 1, 1)
                debugPrint("Drew background texture: " .. bgKey)
        else
            debugPrint("Missing background texture: " .. bgKey .. ", using fallback")
            -- Fallback: dibujar un rectángulo con color según el estado
            local r, g, b = 0.3, 0.3, 0.3 -- gris por defecto
            if self.currentBattery > 60 then
                r, g, b = 0.2, 0.6, 0.2 -- verde
            elseif self.currentBattery > 30 then
                r, g, b = 0.6, 0.6, 0.2 -- amarillo
            else
                r, g, b = 0.6, 0.2, 0.2 -- rojo
            end
            self:drawRect(0, 0, BATTERY_CONFIG.iconSize, BATTERY_CONFIG.iconSize, 1, r, g, b)
        end

        -- Dibujar el icono de batería
        local newTextureValue = self:getBestTexture(self.currentBattery, self.lastBatteryValue)
        if newTextureValue then
            self.lastBatteryValue = newTextureValue
            local stateTexture = self.textureCache["battery_" .. newTextureValue]
            if stateTexture then
                self:drawTextureScaled(stateTexture, 0, 0, BATTERY_CONFIG.iconSize, BATTERY_CONFIG.iconSize, 1, 1, 1, 1)
                debugPrint("Drew battery texture: battery_" .. newTextureValue)
            else
                debugPrint("Missing battery texture: battery_" .. newTextureValue .. ", using text fallback")
                debugPrint("Widget initialization completed")
                -- Fallback: mostrar porcentaje como texto grande
                self:drawText(self.currentBattery .. "%", 8, 20, 1, 1, 1, 1, UIFont.Large)
            end
        else
            -- Fallback: mostrar solo el porcentaje
            self:drawText(self.currentBattery .. "%", 8, 20, 1, 1, 1, 1, UIFont.Large)
        end
        
        -- Dibujar el nombre de la laptop en la parte inferior
        if self.currentLaptop and self.currentLaptop.name then
            self:drawText(self.currentLaptop.name, 2, BATTERY_CONFIG.iconSize + 2, 0.9, 0.9, 0.9, 1, UIFont.Small)
        end
    end)
    
    if not renderOk then
        debugPrint("[LaptopBatteryWidget] Error rendering widget: " .. tostring(renderErr))
        -- Fallback rendering - just draw a simple indicator
        self:drawRect(0, 0, BATTERY_CONFIG.iconSize, BATTERY_CONFIG.iconSize, 0.8, 0.2, 0.2, 0.2)
        if self.currentBattery then
            self:drawText(self.currentBattery .. "%", 5, 20, 1, 1, 1, 1, UIFont.Medium)
        end
    end

    -- Tooltip simplificado
    if self:isMouseOver() and not player:isAiming() then
        local tooltipOk, tooltipErr = pcall(function()
            local tooltip = self:getTooltip()
            if tooltip then
                local mouseX = getMouseX()
                local mouseY = getMouseY()
                self:drawTooltip(mouseX, mouseY, tooltip)
            end
        end)
        if not tooltipOk then
            debugPrint("[LaptopBatteryWidget] Error drawing tooltip: " .. tostring(tooltipErr))
        end
    end
end

function LaptopBatteryWidget:update()
    ISPanel.update(self)
end

function LaptopBatteryWidget:onMouseDown() return false end
function LaptopBatteryWidget:onRightMouseDown() return false end
function LaptopBatteryWidget:onMouseMove() return false end

local function onPlayerDeath(player)
    if player == getSpecificPlayer(0) then
        if laptopBatteryWidget then
            laptopBatteryWidget:setVisible(false)
        end
    end
end

local function onResolutionChange()
    if laptopBatteryWidget then
        laptopBatteryWidget:updatePosition()
    end
end

-- Registrar eventos
Events.OnGameStart.Add(createLaptopBatteryWidget)
Events.OnCreatePlayer.Add(createLaptopBatteryWidget)
Events.OnPlayerDeath.Add(onPlayerDeath)
Events.OnResolutionChange.Add(onResolutionChange)

debugPrint("LaptopBatteryWidget.lua loaded successfully")
