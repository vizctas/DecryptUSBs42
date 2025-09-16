print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
print("!!!           LaptopBatteryUI.lua IS RUNNING!                 !!!")
print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

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

-- Define the list of laptop item types to search for
local laptopItemTypes = {
    "GValley.AsusZephLaptopOpened",
    "GValley.AsusZephLaptopClosed",
    "GValley.Laptop90sClosed",
    "GValley.Laptop90sOpened",
    "GValley.IBM_LP90Opened",
    "GValley.PBIBM_LP90Closed"
}
-- Create a lookup table for faster checks
local laptopLookup = {}
for _, itemType in ipairs(laptopItemTypes) do
    laptopLookup[itemType] = true
end

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

    local searchRadius = 3
    local foundLaptopItem = nil

    for x = -searchRadius, searchRadius do
        for y = -searchRadius, searchRadius do
            local square = getCell():getGridSquare(playerSquare:getX() + x, playerSquare:getY() + y, playerSquare:getZ())
            if square then
                for i = 0, square:getObjects():size() - 1 do
                    local worldObj = square:getObjects():get(i)
                    -- ** NEW LOGIC **
                    -- Check if the world object has an .item property
                    if worldObj and worldObj.item and worldObj.item.getFullType then
                        local item = worldObj.item
                        local itemFullType = item:getFullType()

                        -- Check if this item is one of our laptops
                        if laptopLookup[itemFullType] then
                            print("MATCH FOUND on worldObj.item: " .. itemFullType)
                            foundLaptopItem = item -- We found the actual item!
                            break
                        end
                    end
                end
            end
            if foundLaptopItem then break end
        end
        if foundLaptopItem then break end
    end

    if foundLaptopItem then
        local health = LaptopSystem.getLaptopHealth(foundLaptopItem)
        g_LaptopBatteryUI:updateBattery(health)
        g_LaptopBatteryUI:setVisible(true)
    else
        g_LaptopBatteryUI:setVisible(false)
    end
end

-- Create the global instance and add it to the manager
g_LaptopBatteryUI = LaptopBatteryUI:new(50, 50, 100, 25)
g_LaptopBatteryUI:addToUIManager()

-- Hook the update function to a regular game event
Events.OnPlayerUpdate.Add(updateLaptopUI)

print("[DecryptSkillSys] LaptopBatteryUI.lua (v2) Initialized and OnPlayerUpdate event hooked.")