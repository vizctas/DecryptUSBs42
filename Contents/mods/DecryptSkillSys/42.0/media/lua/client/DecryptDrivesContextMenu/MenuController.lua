-- ============================================================================
-- MENU CONTROLLER
-- Main controller that orchestrates menu creation using strategies
-- ============================================================================

-- Safe debug print function
if not debugPrint then
    debugPrint = function(msg) print("[DecryptSkillSys][DEBUG] " .. tostring(msg)) end
end

MenuController = {}

-- Initialize controller with default strategy
function MenuController:new()
    local controller = {
        strategy = nil, -- Will be loaded lazily
        config = DECRYPT_CONFIG or {}
    }
    setmetatable(controller, self)
    self.__index = self
    return controller
end

-- Lazy load the hierarchical strategy - SIMPLIFIED VERSION
function MenuController:getHierarchicalStrategy()
    if not self.hierarchicalStrategy then
        -- Try to load external strategy first
        local ok, modOrErr = pcall(require, "DecryptDrivesContextMenu.strategies.HierarchicalMenuStrategy")
        if ok and type(modOrErr) == "table" then
            -- prefer returned module table; keep global for compatibility
            local stratModule = modOrErr
            if not HierarchicalMenuStrategy then HierarchicalMenuStrategy = stratModule end
            if stratModule.new and type(stratModule.new) == "function" then
                self.hierarchicalStrategy = stratModule:new()
                debugPrint("MenuController: HierarchicalMenuStrategy loaded successfully (module returned)")
            else
                debugPrint("[ERROR] MenuController: HierarchicalMenuStrategy module has no constructor")
                self.hierarchicalStrategy = nil
            end
        else
            debugPrint("[WARN] MenuController: Failed to load HierarchicalMenuStrategy: " .. tostring(modOrErr))
            debugPrint("[INFO] MenuController: Using built-in fallback strategy")
            -- Create a simple built-in strategy instead of failing
            self.hierarchicalStrategy = self:createBuiltInStrategy()
        end
    end
    return self.hierarchicalStrategy
end

-- Create a simple built-in strategy as fallback
function MenuController:createBuiltInStrategy()
    debugPrint("MenuController: Creating built-in fallback strategy")

    local strategy = {}

    -- Simple menu creation method
    function strategy:createMenu(player, context, laptop, usbList)
        debugPrint("BuiltInStrategy:createMenu called")
        debugPrint("BuiltInStrategy: USB count: " .. #usbList)

        -- Validate parameters
        if not player or not context or not laptop or not usbList or #usbList == 0 then
            debugPrint("[ERROR] BuiltInStrategy: Invalid parameters")
            return false
        end

        -- Group USBs by skill (simple implementation)
        local groupedUSBs = {}
        for _, usb in ipairs(usbList) do
            local skill = usb.skill
            if not groupedUSBs[skill] then
                groupedUSBs[skill] = {}
            end
            table.insert(groupedUSBs[skill], usb)
        end

        -- Create main menu option
        local mainOption = context:addOption("Decrypt USB Drives", nil, nil)
        local subMenu = ISContextMenu:getNew(context)
        context:addSubMenu(mainOption, subMenu)
        -- Mark context to indicate modern menu has been attached
        context._DecryptDrives_ModernMenu = true

        -- Add skill categories
        for skill, usbs in pairs(groupedUSBs) do
            local skillOption = subMenu:addOption("USB " .. skill, nil, nil)
            local skillSubMenu = ISContextMenu:getNew(subMenu)
            subMenu:addSubMenu(skillOption, skillSubMenu)

            -- Group by difficulty
            local difficulties = {}
            for _, usbData in ipairs(usbs) do
                local diff = usbData.difficulty_spanish
                if not difficulties[diff] then
                    difficulties[diff] = {}
                end
                table.insert(difficulties[diff], usbData)
            end

            -- Create difficulty options with proper order
            local diffOrder = {"Facil", "Moderado", "Dificil"}
            for _, difficultyName in ipairs(diffOrder) do
                if difficulties[difficultyName] and #difficulties[difficultyName] > 0 then
                    local count = #difficulties[difficultyName]
                    local firstUSB = difficulties[difficultyName][1]

                    -- Add difficulty option that directly triggers action
                    skillSubMenu:addOption(
                        difficultyName .. " x" .. count,
                        player,
                        function(playerObj, laptopObj)
                            -- Call onUSBSelected with correct parameters
                            if DecryptDrivesContextMenu and DecryptDrivesContextMenu.onUSBSelected then
                                DecryptDrivesContextMenu.onUSBSelected(playerObj, laptop, firstUSB)
                            else
                                debugPrint("[ERROR] BuiltInStrategy: DecryptDrivesContextMenu.onUSBSelected not available")
                            end
                        end
                    )
                end
            end
        end

        debugPrint("BuiltInStrategy: Menu created successfully")
        return true
    end

    return strategy
end

-- Set the menu creation strategy
function MenuController:setStrategy(strategy)
    if strategy and type(strategy.createMenu) == "function" then
        self.strategy = strategy
        debugPrint("MenuController: Strategy changed to " .. tostring(strategy))
    else
        debugPrint("[ERROR] MenuController: Invalid strategy provided")
    end
end

-- Main menu creation method - delegates to current strategy
function MenuController:createMenu(player, context, laptop, usbList)
    debugPrint("MenuController:createMenu called")

    -- Try to use current strategy, or load default if none
    if not self.strategy then
        self.strategy = self:getHierarchicalStrategy()
    end

    if not self.strategy then
        debugPrint("[ERROR] MenuController: No strategy available - cannot create menu")
        error("MenuController: No strategy available - modular menu system failed to initialize")
    end

    -- Delegate to strategy
    local success = self.strategy:createMenu(player, context, laptop, usbList)

    if success then
        debugPrint("MenuController: Menu created successfully")
    else
        debugPrint("[ERROR] MenuController: Menu creation failed")
    end

    return success
end

-- Get current strategy
function MenuController:getStrategy()
    return self.strategy
end

-- Validate menu creation parameters
function MenuController:validateMenuRequest(player, context, worldobjects, test)
    if test then
        debugPrint("MenuController: Test mode - skipping validation")
        return false
    end

    if not player then
        debugPrint("[ERROR] MenuController: player is nil")
        return false
    end

    if not context then
        debugPrint("[ERROR] MenuController: context is nil")
        return false
    end

    if not worldobjects or #worldobjects == 0 then
        debugPrint("[WARN] MenuController: worldobjects is empty")
        return false
    end

    return true
end

return MenuController