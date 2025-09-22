-- ============================================================================
-- MENU CONTROLLER
-- Main controller that orchestrates menu creation using strategies
-- ============================================================================

local hierarchicalStrategyLoaded, hierarchicalStrategyError = pcall(require, "DecryptDrivesContextMenu.strategies.HierarchicalMenuStrategy")
if not hierarchicalStrategyLoaded then
    debugPrint("[ERROR] MenuController: Failed to load HierarchicalMenuStrategy: " .. tostring(hierarchicalStrategyError))
else
    debugPrint("MenuController: HierarchicalMenuStrategy loaded successfully")
end

MenuController = {}

-- Initialize controller with default strategy
function MenuController:new()
    local controller = {
        strategy = hierarchicalStrategyLoaded and HierarchicalMenuStrategy:new() or nil,
        config = DECRYPT_CONFIG or {}
    }
    setmetatable(controller, self)
    self.__index = self
    return controller
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

    if not self.strategy then
        debugPrint("[ERROR] MenuController: No strategy set")
        return false
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