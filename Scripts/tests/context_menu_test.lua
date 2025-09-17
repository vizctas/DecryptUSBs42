-- Minimal Lua test for LaptopOnFillWorldObjectContextMenu
-- Run with: C:\\Users\\joshg\\lua_5_1_5\\lua5.1.exe Scripts/tests/context_menu_test.lua

-- Add mod paths
package.path = package.path .. ';Contents/mods/DecryptSkillSys/42.0/media/lua/?.lua'

-- Load reusable test environment (engine stubs, helpers)
local _ = dofile('Scripts/tests/test_env.lua')

-- Create a player stub and expose it globally so getSpecificPlayer() returns it
local player = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getInventory = function()
        local items = { size = function() return 0 end, get = function() return nil end }
        return { getItems = function() return items end, getItemCount = function() return 0 end, RemoveOneOf = function() end }
    end,
    Say = function(_, msg) print('[Say] ' .. tostring(msg)) end,
    getPlayerNum = function() return 0 end,
}
_G.playerObj = player

-- Stub required globals used by LaptopFill
ISTimedActionQueue = { add = function() end }
JoypadState = { players = {} }

-- Ensure predictable LaptopSystem
LaptopSystem = {
    getLaptopHealth = function(item) return (item and item.__health) or 42 end,
    hasMalware = function() return false end,
    cleanMalware = function() end,
    setLaptopHealth = function() end,
}
-- Make sure the mod's require('shared/LaptopSystem') returns our stub
package.loaded['shared/LaptopSystem'] = LaptopSystem

-- Context collector
local added = {}
local context = {
    addOptionOnTop = function(self, text, player, fn)
        local opt = { name = text, iconTexture = nil, notAvailable = false }
        table.insert(added, opt)
        return opt
    end,
    addOption = function(self, text, player, fn)
        local opt = { name = text, iconTexture = nil, notAvailable = false }
        table.insert(added, opt)
        return opt
    end,
    getNew = function() return { addOption = function() end, addOptionOnTop = function() end } end,
    addSubMenu = function() end,
}

-- World object + item stub
local item = { __health = 42, getFullType = function() return 'GValley.Laptop90sOpened' end, getCondition = function() return 42 end }
local worldObject = { getItem = function() return item end, getX = function() return 0 end, getY = function() return 0 end, getZ = function() return 0 end, getSquare = function() return { getWorldObjects = function() return { size=function() return 0 end } end } end }

-- Load the menu code
dofile('Contents/mods/DecryptSkillSys/42.0/media/lua/client/TimedActions/LaptopFill.lua')

-- Execute once
LaptopOnFillWorldObjectContextMenu(0, context, { worldObject }, false)

-- Assert: find the life entry with percentage and icon
local found = false
-- Debug: print collected options
print('\n[DEBUG] Collected context options:')
for i, o in ipairs(added) do
    print(i, tostring(o.name), tostring(o.iconTexture))
end
print('[DEBUG] End of collected options\n')
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
