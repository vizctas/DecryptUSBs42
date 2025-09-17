-- Minimal Lua test for LaptopOnFillWorldObjectContextMenu
-- Run with: lua Scripts/tests/context_menu_test.lua

-- Add mod paths
package.path = package.path .. ';Contents/mods/DecryptSkillSys/42.0/media/lua/?.lua'

-- Global stubs
ISTimedActionQueue = { add = function() end }
JoypadState = { players = {} }

-- Translations
function getText(key)
    if key == 'GVDrive_Ctx_LaptopLife_Short' then return 'Laptop Condition: %d%%' end
    if key == 'GVDrive_Laptop_Status_Excellent' then return 'Excellent' end
    if key == 'GVDrive_Laptop_Status_Good' then return 'Good' end
    if key == 'GVDrive_Laptop_Status_Warning' then return 'Warning' end
    if key == 'GVDrive_Laptop_Status_Critical' then return 'Critical' end
    if key == 'GVDrive_Laptop_Status_Failing' then return 'Failing' end
    return key
end

-- Textures
function getTexture(path)
    return path -- any non-nil truthy value
end

-- Player stub
local playerObj = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getInventory = function()
        local items = { size = function() return 0 end, get = function() return nil end }
        return {
            getItems = function() return items end,
            getItemCount = function() return 0 end,
        }
    end,
    Say = function(_, msg) print('[Say] ' .. tostring(msg)) end,
}

function getSpecificPlayer()
    return playerObj
end

-- Stub requires used by LaptopFill
package.loaded['TimedActions/ISBaseTimedAction'] = {}
package.loaded['client/TimedActions/ISUsbSys'] = {}
package.loaded['client/TimedActions/ISFloppySys'] = {}
package.loaded['client/TimedActions/DecryptSkillDrive'] = { new = function() return {} end }

-- LaptopSystem stub
LaptopSystem = {
    getLaptopHealth = function(item)
        return item.__health or 42
    end
}

-- Context
local added = {}
local context = {
    addOptionOnTop = function(self, text, player, fn)
        local opt = { name = text }
        table.insert(added, opt)
        return opt
    end
}

-- World object + item stub
local item = {
    __health = 42,
    getFullType = function() return 'GValley.Laptop90sOpened' end,
    getCondition = function() return 42 end,
}
local worldObject = {
    getItem = function() return item end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getSquare = function() return { getWorldObjects = function() return { size=function() return 0 end } end } end,
}

-- Load the menu code
dofile('Contents/mods/DecryptSkillSys/42.0/media/lua/client/TimedActions/LaptopFill.lua')

-- Execute
LaptopOnFillWorldObjectContextMenu(0, context, { worldObject }, false)

-- Assert: find the life entry with percentage, state, and icon
local found = false
for _, opt in ipairs(added) do
    if opt.name:find('Laptop Condition') and opt.name:find('42') and opt.name:find('%(') then
        found = true
        assert(opt.iconTexture ~= nil, 'Expected iconTexture on life option')
        break
    end
end

if not found then
    error('Life entry not found in context menu')
end

print('[OK] Context menu life entry added with icon and correct percentage')
