-- ============================================================================
-- FACTORY PATTERN - Menu Component Factory
-- Centralizes creation of menu components (options, submenus, etc.)
-- ============================================================================

-- Safe debug print function
if not debugPrint then
    debugPrint = function(msg) print("[DecryptSkillSys][DEBUG] " .. tostring(msg)) end
end

MenuComponentFactory = {}

-- Create a new factory instance
function MenuComponentFactory:new()
    local factory = {
        config = DECRYPT_CONFIG or {}
    }
    setmetatable(factory, self)
    self.__index = self
    return factory
end

-- Create a menu option
function MenuComponentFactory:createOption(text, target, method, ...)
    debugPrint("MenuComponentFactory: Creating option '" .. text .. "'")

    local option = {
        text = text,
        target = target,
        method = method,
        args = {...},
        notAvailable = false
    }

    return option
end

-- Create a submenu
function MenuComponentFactory:createSubMenu(parentContext)
    debugPrint("MenuComponentFactory: Creating submenu")

    if not parentContext then
        debugPrint("[ERROR] MenuComponentFactory: parentContext is nil")
        return nil
    end

    local subMenu = ISContextMenu:getNew(parentContext)
    return subMenu
end

-- Create main menu option with submenu
function MenuComponentFactory:createMainMenuOption(context, text)
    debugPrint("MenuComponentFactory: Creating main menu option '" .. text .. "'")
    if not context or not text then
        debugPrint("[ERROR] MenuComponentFactory: Invalid parameters for main menu option")
        return nil, nil
    end

    local mainOption = context:addOption(text, nil, nil)
    local subMenu = self:createSubMenu(context)

    if subMenu then
        context:addSubMenu(mainOption, subMenu)
        -- Mark context to indicate modern menu has been attached
        context._DecryptDrives_ModernMenu = true
        context._DecryptDrives_MainOption = mainOption
        context._DecryptDrives_MainMenu = context
        debugPrint("MenuComponentFactory: Main menu option created successfully")
        return mainOption, subMenu
    else
        debugPrint("[ERROR] MenuComponentFactory: Failed to create submenu")
        return nil, nil
    end
end

-- Create skill category option with submenu
function MenuComponentFactory:createSkillCategoryOption(parentMenu, skillName)
    if not parentMenu or not skillName then
        debugPrint("[ERROR] MenuComponentFactory: Invalid parameters for skill category")
        return nil, nil
    end

    local displayText = (self.config.MENU_TEXT and self.config.MENU_TEXT.USB_PREFIX or "USB ") .. skillName
    local skillOption = parentMenu:addOption(displayText, nil, nil)
    local skillSubMenu = self:createSubMenu(parentMenu)

    if skillSubMenu then
        parentMenu:addSubMenu(skillOption, skillSubMenu)
        debugPrint("MenuComponentFactory: Skill category created successfully")
        return skillOption, skillSubMenu
    else
        debugPrint("[ERROR] MenuComponentFactory: Failed to create skill submenu")
        return nil, nil
    end
end

-- Create difficulty option
function MenuComponentFactory:createDifficultyOption(parentMenu, difficultyName, count, target, method, ...)
    debugPrint("MenuComponentFactory: Creating difficulty option '" .. difficultyName .. " x" .. count .. "'")

    if not parentMenu or not difficultyName then
        debugPrint("[ERROR] MenuComponentFactory: Invalid parameters for difficulty option")
        return nil
    end

    local displayText = difficultyName .. " x" .. count
    local option = parentMenu:addOption(displayText, target, method, ...)

    debugPrint("MenuComponentFactory: Difficulty option created successfully")
    return option
end

-- Create disabled/unavailable option
function MenuComponentFactory:createDisabledOption(parentMenu, text)
    debugPrint("MenuComponentFactory: Creating disabled option '" .. text .. "'")

    if not parentMenu or not text then
        debugPrint("[ERROR] MenuComponentFactory: Invalid parameters for disabled option")
        return nil
    end

    local option = parentMenu:addOption(text, nil, nil)
    option.notAvailable = true

    debugPrint("MenuComponentFactory: Disabled option created successfully")
    return option
end

-- Validate factory state
function MenuComponentFactory:validate()
    if not ISContextMenu or not ISContextMenu.getNew then
        debugPrint("[ERROR] MenuComponentFactory: ISContextMenu not available")
        return false
    end

    debugPrint("MenuComponentFactory: Validation passed")
    return true
end

return MenuComponentFactory