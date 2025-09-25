-- ============================================================================
-- HIERARCHICAL MENU STRATEGY
-- Implements Skill → Difficulty hierarchical menu structure
-- ============================================================================

-- Lazy load dependencies
local function getMenuCreationStrategy()
    if not MenuCreationStrategy then
        local success, result = pcall(require, "DecryptDrivesContextMenu.strategies.MenuCreationStrategy")
        if success then
            MenuCreationStrategy = result
        else
            error("Failed to load MenuCreationStrategy: " .. tostring(result))
        end
    end
    return MenuCreationStrategy
end

local function getMenuComponentFactory()
    if not MenuComponentFactory then
        local success, result = pcall(require, "DecryptDrivesContextMenu.factories.MenuComponentFactory")
        if success then
            MenuComponentFactory = result
        else
            error("Failed to load MenuComponentFactory: " .. tostring(result))
        end
    end
    return MenuComponentFactory
end

-- Initialize base class safely
local baseStrategy = nil
local function getBaseStrategy()
    if not baseStrategy then
        baseStrategy = getMenuCreationStrategy()
    end
    return baseStrategy
end

-- Create HierarchicalMenuStrategy class
HierarchicalMenuStrategy = {}

-- Configuration constants
HierarchicalMenuStrategy.CONFIG = {
    MENU_TEXT = {
        MAIN = "Decrypt USB Drives",
        USB_PREFIX = "USB "
    },
    DIFFICULTY_ORDER = {"Facil", "Moderado", "Dificil"}
}

-- Initialize with factory
function HierarchicalMenuStrategy:new(o)
    o = o or {}
    -- Ensure the class table inherits from base strategy for fallback methods
    local base = getBaseStrategy()
    if base and type(base) == "table" then
        -- set base as fallback for class-level lookups
        setmetatable(HierarchicalMenuStrategy, { __index = base })
    end

    -- Standard instance creation using this class as metatable
    setmetatable(o, self)

    -- Initialize this instance
    o.factory = getMenuComponentFactory():new()
    o.config = HierarchicalMenuStrategy.CONFIG

    return o
end

-- Main menu creation method
function HierarchicalMenuStrategy:createMenu(player, context, laptop, usbList)
    debugPrint("HierarchicalMenuStrategy:createMenu called")
    debugPrint("HierarchicalMenuStrategy: USB count: " .. #usbList)

    -- Validate parameters
    if not self:validateParameters(player, context, laptop, usbList) then
        debugPrint("HierarchicalMenuStrategy: Parameter validation failed")
        return false
    end

    -- Validate factory
    if not self.factory or not self.factory:validate() then
        debugPrint("[ERROR] HierarchicalMenuStrategy: Factory not available")
        return false
    end

    -- Group USBs by skill
    local groupedUSBs = self:groupUSBsBySkill(usbList)

    debugPrint("HierarchicalMenuStrategy: Grouped USBs:")
    for skill, usbs in pairs(groupedUSBs) do
        debugPrint("HierarchicalMenuStrategy:   Skill: " .. skill .. " - Count: " .. #usbs)
    end

    -- Create main menu option using factory
    local mainOption, subMenu = self.factory:createMainMenuOption(context, self.config.MENU_TEXT.MAIN)
    if not subMenu then
        debugPrint("[ERROR] HierarchicalMenuStrategy: Failed to create main menu")
        return false
    end

    -- Mark context to indicate modern menu has been attached (prevent legacy menu)
    context._DecryptDrives_ModernMenu = true

    -- Add skill categories
    for skill, usbs in pairs(groupedUSBs) do
        local skillOption, skillSubMenu = self.factory:createSkillCategoryOption(subMenu, skill)
        if not skillSubMenu then
            debugPrint("[ERROR] HierarchicalMenuStrategy: Failed to create skill category for " .. skill)
        else
            -- Group USBs by difficulty within this skill
            local difficulties = {}
            for _, usbData in ipairs(usbs) do
                local diff = usbData.difficulty_spanish
                debugPrint("Processing USB: skill=" .. skill .. ", difficulty=" .. tostring(diff))
                if not difficulties[diff] then
                    difficulties[diff] = {}
                end
                table.insert(difficulties[diff], usbData)
            end

            debugPrint("Difficulties for skill " .. skill .. ":")
            for diffName, diffList in pairs(difficulties) do
                debugPrint("  " .. diffName .. ": " .. #diffList .. " USBs")
            end

            -- Create difficulty options with proper order
            for _, difficultyName in ipairs(self.config.DIFFICULTY_ORDER) do
                if difficulties[difficultyName] then
                    local count = #difficulties[difficultyName]
                    debugPrint("Adding difficulty option: " .. difficultyName .. " x" .. count .. " for skill " .. skill)

                    -- Create difficulty option that directly triggers action with the first USB
                    local option = self.factory:createDifficultyOption(
                        skillSubMenu,
                        difficultyName,
                        count,
                        DecryptDrivesContextMenu,
                        DecryptDrivesContextMenu.onUSBSelected,
                        player,
                        laptop,
                        difficulties[difficultyName][1]  -- Use the first USB in the list
                    )
                    if option then
                        debugPrint("Difficulty option created successfully")
                    else
                        debugPrint("[ERROR] Failed to create difficulty option")
                    end
                else
                    debugPrint("No USBs found for difficulty: " .. difficultyName .. " in skill " .. skill)
                end
            end
        end
    end

    debugPrint("Hierarchical menu created with " .. #usbList .. " USB options")
    return true
end

return HierarchicalMenuStrategy