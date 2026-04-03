-- ============================================================================
-- STRATEGY PATTERN - Menu Creation Strategies
-- ============================================================================

-- Safe debug print function
if not debugPrint then
    debugPrint = function(msg) print("[DecryptSkillSys][DEBUG] " .. tostring(msg)) end
end

-- Base Strategy Interface
MenuCreationStrategy = {}

-- Create a new strategy instance
function MenuCreationStrategy:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Abstract method - must be implemented by concrete strategies
function MenuCreationStrategy:createMenu(player, context, laptop, usbList)
    error("MenuCreationStrategy:createMenu() must be implemented by subclass")
end

-- Validate common parameters
function MenuCreationStrategy:validateParameters(player, context, laptop, usbList)
    if not player then
        debugPrint("[ERROR] MenuCreationStrategy: player is nil")
        return false
    end
    if not context then
        debugPrint("[ERROR] MenuCreationStrategy: context is nil")
        return false
    end
    if not laptop then
        debugPrint("[ERROR] MenuCreationStrategy: laptop is nil")
        return false
    end
    if not usbList or #usbList == 0 then
        debugPrint("[WARN] MenuCreationStrategy: usbList is empty or nil")
        return false
    end
    return true
end

-- Common utility: Group USBs by skill
function MenuCreationStrategy:groupUSBsBySkill(usbList)
    debugPrint("MenuCreationStrategy:groupUSBsBySkill called with " .. #usbList .. " USBs")
    local grouped = {}

    for _, usbData in ipairs(usbList) do
        local skill = usbData.skill
        if not grouped[skill] then
            grouped[skill] = {}
        end
        table.insert(grouped[skill], usbData)
        debugPrint("  Added USB to skill: " .. skill)
    end

    -- Count skills safely
    local skillCount = 0
    for _ in pairs(grouped) do
        skillCount = skillCount + 1
    end

    debugPrint("Grouping complete. Skills found: " .. skillCount)
    return grouped
end

-- Common utility: Create main menu option
function MenuCreationStrategy:createMainMenuOption(context, text)
    local mainOption = context:addOption(text, nil, nil)
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(mainOption, subMenu)
    -- Mark context to indicate modern menu has been attached (defensive against other handlers)
    context._DecryptDrives_ModernMenu = true
    return subMenu
end

return MenuCreationStrategy