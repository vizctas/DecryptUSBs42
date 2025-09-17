 -- Test for EliteDriveSystem apply via RPC or direct call
package.path = package.path .. ';Contents/mods/DecryptSkillSys/42.0/media/lua/?.lua'

-- Stubs
function getText(k) return k end

-- Minimal player stub
local playerObj = {
    playerNum = 0,
    getPlayerNum = function(self) return self.playerNum end,
    getModData = function(self)
        if not self._mod then self._mod = {} end
        return self._mod
    end,
    getInventory = function(self)
        return {
            getItemCount = function(_, fullType) return (fullType == 'GValley.EliteEnhancement_Token') and 1 or 0 end,
            RemoveOneOf = function(_, fullType) if fullType == 'GValley.EliteEnhancement_Token' then end end,
        }
    end,
    getMaxWeight = function() return 50 end,
    setMaxWeight = function(self, w) self._max = w end,
    Say = function(self, msg) print('[Say] ' .. tostring(msg)) end,
}

function getSpecificPlayer(i) return playerObj end

-- Load server file
local ok, err = pcall(function() dofile('Contents/mods/DecryptSkillSys/42.0/media/lua/server/EliteDriveSystem.lua') end)
if not ok then
    error('Failed to load server EliteDriveSystem: ' .. tostring(err))
end

-- Ensure initial state
local ed = EliteDriveSystem.getPlayerEnhancements(playerObj)
assert(ed.TotalTokensUsed == 0)

-- Simulate client command
local payload = { enhancement = 'Capacity', playerIndex = 0 }

-- Call handler directly (as if Events.OnClientCommand invoked)
if handleClientCommand then
    handleClientCommand(0, 'DecryptSkillSys', 'ApplyEliteEnhancement', payload)
else
    -- Fallback direct call
    EliteDriveSystem.applySpecificEnhancement(playerObj, 'Capacity')
end

-- Check that token was consumed (TotalTokensUsed incremented)
local ed2 = EliteDriveSystem.getPlayerEnhancements(playerObj)
assert(ed2.TotalTokensUsed == 1, 'Expected TotalTokensUsed == 1')
print('[OK] Elite enhancement applied and tracked in ModData')


