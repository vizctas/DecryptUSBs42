-- Minimal test environment for DecryptUSBs42 tests
-- Provides small stubs for Project Zomboid engine functions used in tests

-- Events stub
Events = {
    OnFillWorldObjectContextMenu = {
        _added = {},
        -- Support both Add(fn) and Add(self, fn) depending on how the mod calls it
        Add = function(a, b)
            local fn = b
            local tbl = a
            if type(a) == 'function' and b == nil then
                -- called as Add(fn)
                fn = a
                tbl = Events.OnFillWorldObjectContextMenu
            end
            table.insert(tbl._added, fn)
        end,
    }
}

-- Basic globals
ISTimedActionQueue = { add = function() end }
JoypadState = { players = {} }

-- Simple translation map (tests expect some keys)
local translations = {
    GVDrive_Ctx_LaptopLife = "Laptop Condition: %d%% (%s)",
    GVDrive_Laptop_Status_Excellent = "Excellent",
    GVDrive_Laptop_Status_Good = "Good",
    GVDrive_Laptop_Status_Warning = "Warning",
    GVDrive_Laptop_Status_Critical = "Critical",
    GVDrive_Laptop_Status_Failing = "Failing",
}
function getText(key)
    return translations[key] or key
end

function getTexture(path)
    -- return a truthy value representing a texture
    return { path = path }
end

-- getSpecificPlayer will return global playerObj if defined by the test
function getSpecificPlayer(i)
    return _G.playerObj
end

-- Lightweight LaptopSystem stub
LaptopSystem = {
    getLaptopHealth = function(item) return (item and item.__health) or 50 end,
    hasMalware = function() return false end,
    cleanMalware = function() end,
    setLaptopHealth = function() end,
    canUseLaptop = function() return true end,
}

-- ISModalDialog stub
ISModalDialog = { new = function() return nil end }

-- Minimal module stubs to satisfy require() calls inside the mod
package.loaded['TimedActions/ISBaseTimedAction'] = {}
package.loaded['client/TimedActions/ISUsbSys'] = {}
package.loaded['client/TimedActions/ISFloppySys'] = {}
package.loaded['client/TimedActions/DecryptSkillDrive'] = { new = function() return {} end }
package.loaded['shared/GVDrive_Utils'] = {}

return true
