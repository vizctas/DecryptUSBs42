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

-- Lazy load the hierarchical strategy
function MenuController:getHierarchicalStrategy()
    if not self.hierarchicalStrategy then
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
            debugPrint("[ERROR] MenuController: Failed to load HierarchicalMenuStrategy: " .. tostring(modOrErr))
            self.hierarchicalStrategy = nil
        end
    end
    return self.hierarchicalStrategy
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