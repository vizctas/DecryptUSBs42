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
                -- LaptopBatteryWidget.lua — REMOVED
                -- Removed: 2025-09-19
                -- Rationale: client-side widget caused runtime errors and is unused. File kept only for history.
                -- This file intentionally exposes no globals and registers no events.

                return
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
