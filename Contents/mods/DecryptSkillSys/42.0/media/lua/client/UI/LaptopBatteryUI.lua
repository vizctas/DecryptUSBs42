-- LaptopStatusWindow.lua - Laptop battery status window with context menu
-- Version 5.1 - Fixed context menu issues

print("[DecryptSkillSys] Loading LaptopStatusWindow v5.1...")

require "UI/ISPanel"
require "UI/ISButton"

-- ==============================================================================
-- LAPTOP STATUS WINDOW CLASS
-- ==============================================================================

LaptopStatusWindow = ISPanel:derive("LaptopStatusWindow")

function LaptopStatusWindow:new(x, y)
    local width = 250
    local height = 120
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    -- Window properties
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    o.backgroundColor = {r=0.05, g=0.05, b=0.05, a=0.95}
    o.width = width
    o.height = height
    o.moveWithMouse = true
    
    -- Laptop data
    o.laptopItem = nil
    o.batteryPercent = 100
    o.laptopName = "Unknown Laptop"
    o.status = "Good"
    
    o:initialise()
    o:setAlwaysOnTop(true)
    o:setVisible(false)
    
    return o
end

function LaptopStatusWindow:initialise()
    ISPanel.initialise(self)
    self:createCloseButton()
end

function LaptopStatusWindow:createCloseButton()
    -- Create close button (X) in top-right corner
    local closeBtn = ISButton:new(self.width - 25, 5, 20, 20, "X", self, LaptopStatusWindow.onClose)
    closeBtn:setAnchorLeft(false)
    closeBtn:setAnchorRight(true)
    closeBtn:setAnchorTop(true)
    closeBtn:setAnchorBottom(false)
    closeBtn.backgroundColor = {r=0.7, g=0.2, b=0.2, a=0.8}
    closeBtn.backgroundColorMouseOver = {r=0.9, g=0.3, b=0.3, a=1}
    closeBtn:setFont(UIFont.Small)
    self:addChild(closeBtn)
    self.closeButton = closeBtn
end

function LaptopStatusWindow:setLaptopData(laptop)
    if not laptop then return end
    
    self.laptopItem = laptop
    local itemType = laptop:getFullType()
    
    -- Get laptop name from type
    local laptopNames = {
        ["GValley.AsusZephLaptopOpened"] = "Asus Zephyrus (Open)",
        ["GValley.AsusZephLaptopClosed"] = "Asus Zephyrus (Closed)",
        ["GValley.Laptop90sClosed"] = "Toshiba Satellite (Closed)", 
        ["GValley.Laptop90sOpened"] = "Toshiba Satellite (Open)",
        ["GValley.IBM_LP90Opened"] = "IBM Palm Top (Open)",
        ["GValley.PBIBM_LP90Closed"] = "IBM Palm Top (Closed)"
    }
    
    self.laptopName = laptopNames[itemType] or laptop:getDisplayName()
    self.batteryPercent = LaptopSystem.getLaptopHealth(laptop) or 100
    
    -- Determine status
    if self.batteryPercent > 75 then
        self.status = "Excellent"
    elseif self.batteryPercent > 50 then
        self.status = "Good"
    elseif self.batteryPercent > 25 then
        self.status = "Warning"
    elseif self.batteryPercent > 10 then
        self.status = "Critical"
    else
        self.status = "Failing"
    end
end

function LaptopStatusWindow:render()
    if not self:getIsVisible() then return end
    
    -- Draw window background
    ISPanel.render(self)
    
    -- Title bar
    local titleY = 8
    self:drawTextCentre("Laptop Status", self.width / 2, titleY, 1, 1, 1, 1, UIFont.Medium)
    
    -- Laptop name
    local nameY = 30
    self:drawTextCentre(self.laptopName, self.width / 2, nameY, 0.9, 0.9, 0.9, 1, UIFont.Small)
    
    -- Battery section
    local batteryY = 50
    self:drawText("Battery Health:", 15, batteryY, 0.8, 0.8, 0.8, 1, UIFont.Small)
    
    -- Battery bar
    local barX = 15
    local barY = batteryY + 15
    local barWidth = self.width - 30
    local barHeight = 20
    
    -- Battery border
    self:drawRectBorder(barX, barY, barWidth, barHeight, 1.0, 0.6, 0.6, 0.6)
    
    -- Battery fill
    local fillWidth = (self.batteryPercent / 100) * (barWidth - 2)
    local r, g, b = self:getBatteryColor()
    
    if fillWidth > 0 then
        self:drawRect(barX + 1, barY + 1, fillWidth, barHeight - 2, 1, r, g, b)
    end
    
    -- Battery percentage text
    local percentText = self.batteryPercent .. "%"
    self:drawTextCentre(percentText, self.width / 2, barY + 4, 1, 1, 1, 1, UIFont.Small)
    
    -- Status text
    local statusY = barY + 25
    local statusColor = self:getStatusColor()
    self:drawTextCentre("Status: " .. self.status, self.width / 2, statusY, statusColor.r, statusColor.g, statusColor.b, 1, UIFont.Small)
end

function LaptopStatusWindow:getBatteryColor()
    if self.batteryPercent > 60 then
        return 0.2, 0.8, 0.2  -- Green
    elseif self.batteryPercent > 30 then
        return 0.9, 0.9, 0.2  -- Yellow
    elseif self.batteryPercent > 10 then
        return 1.0, 0.6, 0.0  -- Orange
    else
        return 0.9, 0.2, 0.2  -- Red
    end
end

function LaptopStatusWindow:getStatusColor()
    if self.batteryPercent > 75 then
        return {r=0.2, g=0.8, b=0.2}  -- Green
    elseif self.batteryPercent > 50 then
        return {r=0.6, g=0.8, b=0.2}  -- Light green
    elseif self.batteryPercent > 25 then
        return {r=0.9, g=0.9, b=0.2}  -- Yellow
    elseif self.batteryPercent > 10 then
        return {r=1.0, g=0.6, b=0.0}  -- Orange
    else
        return {r=0.9, g=0.2, b=0.2}  -- Red
    end
end

function LaptopStatusWindow:onClose()
    self:setVisible(false)
    self:removeFromUIManager()
end

-- ==============================================================================
-- CONTEXT MENU INTEGRATION
-- ==============================================================================

-- Global variable for the current window
local g_currentStatusWindow = nil

-- Function to check if an item is a laptop
local function isLaptop(item)
    if not item then 
        print("[LaptopStatusWindow] isLaptop: item is nil")
        return false 
    end
    
    if not item.getFullType then 
        print("[LaptopStatusWindow] isLaptop: item has no getFullType method")
        return false 
    end
    
    local itemType = item:getFullType()
    print("[LaptopStatusWindow] isLaptop: checking type: " .. tostring(itemType))
    
    local laptopTypes = {
        "GValley.AsusZephLaptopOpened",
        "GValley.AsusZephLaptopClosed", 
        "GValley.Laptop90sClosed",
        "GValley.Laptop90sOpened",
        "GValley.IBM_LP90Opened",
        "GValley.PBIBM_LP90Closed"
    }
    
    for _, laptopType in ipairs(laptopTypes) do
        if itemType == laptopType then
            print("[LaptopStatusWindow] isLaptop: MATCH found for " .. laptopType)
            return true
        end
    end
    
    print("[LaptopStatusWindow] isLaptop: No match found")
    return false
end

-- Function to show laptop status window
local function showLaptopStatus(laptop, player)
    -- Close existing window if open
    if g_currentStatusWindow then
        g_currentStatusWindow:setVisible(false)
        g_currentStatusWindow:removeFromUIManager()
        g_currentStatusWindow = nil
    end
    
    -- Create new window in center of screen
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    local windowX = (screenWidth - 250) / 2
    local windowY = (screenHeight - 120) / 2
    
    g_currentStatusWindow = LaptopStatusWindow:new(windowX, windowY)
    g_currentStatusWindow:setLaptopData(laptop)
    g_currentStatusWindow:addToUIManager()
    g_currentStatusWindow:setVisible(true)
    
    print("[LaptopStatusWindow] Showing status for: " .. laptop:getDisplayName())
end

-- Context menu handler for inventory items
local function onFillInventoryObjectContextMenu(player, context, items)
    print("[LaptopStatusWindow] Context menu triggered for inventory")
    
    if not items then 
        print("[LaptopStatusWindow] No items provided")
        return 
    end
    
    local item = nil
    
    -- Handle different item structures
    if type(items) == "table" then
        if #items > 0 then
            item = items[1]
            if item and item.items and #item.items > 0 then
                item = item.items[1]
            end
        end
    else
        item = items
    end
    
    print("[LaptopStatusWindow] Checking item: " .. tostring(item))
    
    if item then
        local itemType = item:getFullType()
        print("[LaptopStatusWindow] Item type: " .. tostring(itemType))
        
        if isLaptop(item) then
            print("[LaptopStatusWindow] Adding context menu option for laptop")
            context:addOption("Check Laptop Status", item, showLaptopStatus, item, player)
        end
    end
end

-- Context menu handler for world objects
local function onFillWorldObjectContextMenu(player, context, worldobjects, test)
    print("[LaptopStatusWindow] Context menu triggered for world objects")
    
    if not worldobjects then 
        print("[LaptopStatusWindow] No world objects provided")
        return 
    end
    
    for i, worldObj in ipairs(worldobjects) do
        print("[LaptopStatusWindow] Checking world object " .. i)
        
        if worldObj then
            -- Try different ways to get the item
            local item = nil
            
            if worldObj.getItem then
                item = worldObj:getItem()
            elseif worldObj.item then
                item = worldObj.item
            end
            
            if item then
                local itemType = item:getFullType()
                print("[LaptopStatusWindow] World object item type: " .. tostring(itemType))
                
                if isLaptop(item) then
                    print("[LaptopStatusWindow] Adding context menu option for world laptop")
                    context:addOption("Check Laptop Status", item, showLaptopStatus, item, player)
                    break -- Only add once
                end
            else
                print("[LaptopStatusWindow] World object has no item")
            end
        end
    end
end

-- Test function with G key
local function onKeyPressed(key)
    if key == 34 then -- G key
        local player = getPlayer()
        if not player then return end
        
        -- Try to find a laptop in inventory for testing
        local inventory = player:getInventory()
        local items = inventory:getItems()
        
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if isLaptop(item) then
                showLaptopStatus(item, player)
                return
            end
        end
        
        -- If no laptop found, create a test window
        print("[LaptopStatusWindow] No laptop found in inventory. Creating test window...")
        
        if g_currentStatusWindow then
            g_currentStatusWindow:setVisible(false)
            g_currentStatusWindow:removeFromUIManager()
        end
        
        local screenWidth = getCore():getScreenWidth()
        local screenHeight = getCore():getScreenHeight()
        local windowX = (screenWidth - 250) / 2
        local windowY = (screenHeight - 120) / 2
        
        g_currentStatusWindow = LaptopStatusWindow:new(windowX, windowY)
        g_currentStatusWindow.laptopName = "Test Laptop"
        g_currentStatusWindow.batteryPercent = math.random(10, 100)
        g_currentStatusWindow.status = "Test Mode"
        g_currentStatusWindow:addToUIManager()
        g_currentStatusWindow:setVisible(true)
    end
end

-- ==============================================================================
-- EVENT REGISTRATION
-- ==============================================================================

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
Events.OnKeyPressed.Add(onKeyPressed)

print("[DecryptSkillSys] LaptopStatusWindow v5.1 loaded successfully")
print("[LaptopStatusWindow] Context menu events registered")
print("[LaptopStatusWindow] Right-click laptops to check status")
print("[LaptopStatusWindow] Press 'G' to test (if laptop in inventory)")
print("[LaptopStatusWindow] Debug mode enabled - check console for details")

-- Displays a small UI widget with the battery status of a nearby laptop.
-- This version is self-contained and draws a dynamic battery bar.

require "UI/ISPanel"

LaptopBatteryUI = ISPanel:derive("LaptopBatteryUI")

function LaptopBatteryUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.borderColor = {r=0, g=0, b=0, a=0}
    o.backgroundColor = {r=0, g=0, b=0, a=0.7}
    o.width = width
    o.height = height
    o.anchorLeft = true
    o.anchorRight = false
    o.anchorTop = true
    o.anchorBottom = false
    o.percentage = 100
    o:initialise()
    o:setAlwaysOnTop(true)
    return o
end

function LaptopBatteryUI:initialise()
    ISPanel.initialise(self)
    self:setVisible(false)
end

function LaptopBatteryUI:updateBattery(percentage)
    self.percentage = math.floor(percentage)
end

function LaptopBatteryUI:render()
    if not self:getIsVisible() then return end
    
    -- Debug: This will help us know if render is being called
    -- Remove this line after debugging
    if math.random(1, 300) == 1 then  -- Print occasionally to avoid spam
        print("[DEBUG] LaptopBatteryUI rendering with " .. self.percentage .. "% battery")
    end
    
    ISPanel.render(self)

    local barX = 5
    local barY = 5
    local barWidth = self.width - 10
    local barHeight = self.height - 10

    self:drawRectBorder(barX, barY, barWidth, barHeight, 1.0, 0.6, 0.6, 0.6)

    local currentBarWidth = (self.percentage / 100) * (barWidth - 2)
    local r, g, b = 0.9, 0.1, 0.1
    if self.percentage > 50 then
        r, g, b = 0.1, 0.8, 0.1
    elseif self.percentage > 25 then
        r, g, b = 1, 1, 0.1
    end

    if currentBarWidth > 0 then
        self:drawRect(barX + 1, barY + 1, currentBarWidth, barHeight - 2, 1, r, g, b)
    end

    local text = self.percentage .. "%"
    self:drawTextCentre(text, barWidth / 2 + barX, barY, 1, 1, 1, 1, UIFont.Small)
end

-- =========================================================================
-- Proximity Logic and Event Handling
-- =========================================================================

-- Define the list of laptop world models to search for
local laptopModels = {
    "AsusLaptop_Open",
    "AsusLaptop_Close", 
    "Laptop90Opened",
    "Laptop90Closed",
    "IBM_LP90Opened",
    "PBIBM_LP90Closed"
}

-- Create a lookup table for faster checks
local laptopModelLookup = {}
for _, model in ipairs(laptopModels) do
    laptopModelLookup[model] = true
end

-- Debug counter to avoid spam
local debugCounter = 0

-- Main update function
local function updateLaptopUI()
    local player = getPlayer()
    if not player then
        if g_LaptopBatteryUI then g_LaptopBatteryUI:setVisible(false) end
        return
    end

    local playerSquare = player:getCurrentSquare()
    if not playerSquare then
        if g_LaptopBatteryUI then g_LaptopBatteryUI:setVisible(false) end
        return
    end

    -- Debug every 300 updates (roughly every 10 seconds)
    debugCounter = debugCounter + 1
    local shouldDebug = (debugCounter % 300 == 0)
    
    if shouldDebug then
        print("[DEBUG] Searching for laptops near player position: " .. playerSquare:getX() .. "," .. playerSquare:getY())
    end

    local searchRadius = 3
    local foundLaptopItem = nil

    for x = -searchRadius, searchRadius do
        for y = -searchRadius, searchRadius do
            local square = getCell():getGridSquare(playerSquare:getX() + x, playerSquare:getY() + y, playerSquare:getZ())
            if square then
                -- Check for placed items in the square
                local worldItems = square:getWorldObjects()
                if worldItems then
                    for i = 0, worldItems:size() - 1 do
                        local worldObj = worldItems:get(i)
                        if worldObj and worldObj:getItem() then
                            local item = worldObj:getItem()
                            if item and item:getFullType() then
                                local itemType = item:getFullType()
                                if shouldDebug then
                                    print("[DEBUG] Found world item: " .. itemType)
                                end
                                
                                -- Check if this is one of our laptop types
                                if itemType == "GValley.AsusZephLaptopOpened" or 
                                   itemType == "GValley.AsusZephLaptopClosed" or
                                   itemType == "GValley.Laptop90sClosed" or
                                   itemType == "GValley.Laptop90sOpened" or
                                   itemType == "GValley.IBM_LP90Opened" or
                                   itemType == "GValley.PBIBM_LP90Closed" then
                                    print("[DEBUG] LAPTOP FOUND: " .. itemType)
                                    foundLaptopItem = item
                                    break
                                end
                            end
                        end
                    end
                end
                
                -- Also check regular objects with sprites
                local objects = square:getObjects()
                if objects then
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if obj and obj:getSprite() then
                            local spriteName = obj:getSprite():getName()
                            if spriteName then
                                if shouldDebug then
                                    print("[DEBUG] Found object with sprite: " .. spriteName)
                                end
                                -- Check for laptop models in sprites
                                if laptopModelLookup[spriteName] then
                                    print("[DEBUG] LAPTOP MODEL FOUND: " .. spriteName)
                                    -- Create a dummy item for health tracking
                                    foundLaptopItem = obj
                                    break
                                end
                            end
                        end
                    end
                end
            end
            if foundLaptopItem then break end
        end
        if foundLaptopItem then break end
    end

    if foundLaptopItem then
        local health = 100 -- Default health for now
        
        -- Try to get health from item if it has modData
        if foundLaptopItem.getModData then
            health = LaptopSystem.getLaptopHealth(foundLaptopItem)
        elseif foundLaptopItem:getModData then
            local modData = foundLaptopItem:getModData()
            if modData and modData.laptopHealth then
                health = modData.laptopHealth
            end
        end
        
        print("[DEBUG] Setting laptop health to: " .. health .. "% and showing widget")
        g_LaptopBatteryUI:updateBattery(health)
        g_LaptopBatteryUI:setVisible(true)
    else
        if shouldDebug then
            print("[DEBUG] No laptops found, hiding widget")
        end
        g_LaptopBatteryUI:setVisible(false)
    end
end

-- Create the global instance and add it to the manager
g_LaptopBatteryUI = LaptopBatteryUI:new(50, 50, 100, 25)
g_LaptopBatteryUI:addToUIManager()

-- Add debug for widget creation
print("[DEBUG] LaptopBatteryUI widget created and added to UI manager")
print("[DEBUG] Widget position: x=" .. g_LaptopBatteryUI.x .. ", y=" .. g_LaptopBatteryUI.y)
print("[DEBUG] Widget size: w=" .. g_LaptopBatteryUI.width .. ", h=" .. g_LaptopBatteryUI.height)

-- Hook the update function to a regular game event
Events.OnPlayerUpdate.Add(updateLaptopUI)

-- Test function to manually show the widget (remove after testing)
local function testShowWidget()
    if g_LaptopBatteryUI then
        print("[DEBUG TEST] Manually showing widget for 5 seconds")
        g_LaptopBatteryUI:updateBattery(75) -- Test with 75% battery
        g_LaptopBatteryUI:setVisible(true)
        
        -- Hide it after 5 seconds
        local hideTimer = function()
            print("[DEBUG TEST] Hiding test widget")
            g_LaptopBatteryUI:setVisible(false)
        end
        
        -- Schedule hiding the widget after 5 seconds (300 updates at 60fps)
        local counter = 0
        local hideFunction = function()
            counter = counter + 1
            if counter >= 300 then
                hideTimer()
                Events.OnPlayerUpdate.Remove(hideFunction)
            end
        end
        Events.OnPlayerUpdate.Add(hideFunction)
    end
end

-- Add a key press event for testing (press G to test the widget)
local function onKeyPressed(key)
    if key == 34 then -- G key
        testShowWidget()
    end
end
Events.OnKeyPressed.Add(onKeyPressed)

print("[DecryptSkillSys] LaptopBatteryUI.lua (v3) Initialized and OnPlayerUpdate event hooked.")
print("[DEBUG] Press 'G' in-game to test the widget manually")