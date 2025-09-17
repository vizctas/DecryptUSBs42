-- Clean test for EliteDriveSystem apply via RPC or direct call
-- Run with: lua Scripts/tests/elite_system_test_clean.lua

-- Add mod paths
package.path = package.path .. ';Contents/mods/DecryptSkillSys/42.0/media/lua/?.lua'

-- Stubs
function getText(k) return k end

-- Minimal engine stubs required by server code
Events = Events or {}
Events.OnZombieDead = Events.OnZombieDead or { Add = function(_) end }
Events.OnPlayerUpdate = Events.OnPlayerUpdate or { Add = function(_) end }
Events.OnClientCommand = Events.OnClientCommand or { Add = function(_) end }
Events.OnServerCommand = Events.OnServerCommand or { Add = function(_) end }
Events.OnFillWorldObjectContextMenu = Events.OnFillWorldObjectContextMenu or { Add = function(_) end }

function ZombRand(a, b)
    -- mimic Project Zomboid's ZombRand(a,b) which returns integer in [a, b-1]
    a = a or 0; b = b or 1
    if b - a <= 1 then return a end
    return math.random(a, b - 1)
end

function getOnlinePlayers()
    return { size = function() return 0 end, size = function() return 0 end, get = function() return nil end, size = function() return 0 end, }
end

IsoUtils = IsoUtils or { DistanceTo = function(a,b) return 0 end }
HaloTextHelper = HaloTextHelper or { addTextWithArrow = function() end, getColorGreen = function() return {r=0,g=255,b=0} end }
function instanceof(a,b) return false end

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
