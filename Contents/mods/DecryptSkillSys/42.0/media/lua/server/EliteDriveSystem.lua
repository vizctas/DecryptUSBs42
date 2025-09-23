-- Elite Drive System Functions
-- Handles special elite drives and permanent enhancements

require "shared/GVDrive_Utils"
require "shared/EliteDriveSystem"
pcall(require, "shared/GVDrive_Config")

local ok_debug, GVDebug = pcall(require, "shared/GVDebug")
if not ok_debug or not GVDebug then
    GVDebug = { debugPrint = function(...) end, testPrint = function(...) end }
end

-- Ensure table exists (shared file provides a simplified table)
EliteDriveSystem = EliteDriveSystem or {}

-- Elite drive drop chances (very rare)
local ELITE_DROP_CHANCE = 0.05 -- 0.05% chance per zombie

-- Track player enhancements in ModData
function EliteDriveSystem.getPlayerEnhancements(player)
    local data = player:getModData()
    if not data.GVDrive_Enhancements then
        data.GVDrive_Enhancements = {
            -- Track which specific bonuses have been used
            CapacityTokenUsed = false,
            SpeedTokenUsed = false,
            StrengthTokenUsed = false,
            EnduranceTokenUsed = false,
            LuckTokenUsed = false,
            -- Cumulative bonuses
            CapacityBonus = 0,
            SpeedBonus = 0,
            StrengthBonus = 0,
            EnduranceBonus = 0,
            LuckBonus = 0,
            TotalTokensUsed = 0,
            -- internal flags
            _speedApplied = false,
            BaseMoveSpeed = nil,
        }
    end
    return data.GVDrive_Enhancements
end

-- Check if player can use enhancement token (must choose which stat to enhance)
function EliteDriveSystem.canUseEnhancementToken(player)
    local enhancements = EliteDriveSystem.getPlayerEnhancements(player)
    -- Can use token if not all stats have been enhanced
    return not (enhancements.CapacityTokenUsed and 
                enhancements.SpeedTokenUsed and 
                enhancements.StrengthTokenUsed and 
                enhancements.EnduranceTokenUsed and 
                enhancements.LuckTokenUsed)
end

-- Apply specific permanent enhancement to player
function EliteDriveSystem.applySpecificEnhancement(player, enhancementType)
    local enhancements = EliteDriveSystem.getPlayerEnhancements(player)
    
    -- Check if this specific enhancement has already been used
    local tokenKey = enhancementType .. "TokenUsed"
    if enhancements[tokenKey] then
        player:Say(getText("GVDrive_Msg_Enhancement_Already_Used") or "You have already used an enhancement for " .. enhancementType .. "!")
        return false
    end
    
    -- Try remove one token from inventory (safe - only if present)
    if player and player.getInventory then
        local inv = player:getInventory()
        if inv and inv.getItemCount and inv:getItemCount("GValley.EliteEnhancement_Token") > 0 then
            inv:RemoveOneOf("GValley.EliteEnhancement_Token")
        end
    end

    -- Mark this enhancement as used
    enhancements[tokenKey] = true
    enhancements.TotalTokensUsed = enhancements.TotalTokensUsed + 1
    
    -- Apply specific bonuses
    if enhancementType == "Capacity" then
        enhancements.CapacityBonus = enhancements.CapacityBonus + 5
        local maxWeight = player:getMaxWeight()
        player:setMaxWeight(maxWeight + 5)
        player:Say(getText("GVDrive_Msg_Enhancement_Capacity") or "Elite enhancement applied! +5 Carry Weight!")

    elseif enhancementType == "Speed" then
        enhancements.SpeedBonus = (enhancements.SpeedBonus or 0) + 0.1
        -- BaseMoveSpeed will be captured on next update if missing
        player:Say(getText("GVDrive_Msg_Enhancement_Speed") or "Elite enhancement applied! +10% Movement Speed!")

    elseif enhancementType == "Strength" then
        enhancements.StrengthBonus = enhancements.StrengthBonus + 1
        player:Say(getText("GVDrive_Msg_Enhancement_Strength") or "Elite enhancement applied! Enhanced combat abilities!")
        
    elseif enhancementType == "Endurance" then
        enhancements.EnduranceBonus = enhancements.EnduranceBonus + 1
        player:Say(getText("GVDrive_Msg_Enhancement_Endurance") or "Elite enhancement applied! Enhanced endurance!")
        
    elseif enhancementType == "Luck" then
        enhancements.LuckBonus = enhancements.LuckBonus + 1
        player:Say(getText("GVDrive_Msg_Enhancement_Luck") or "Elite enhancement applied! Enhanced luck!")
    end
    
    return true
end

-- Apply permanent enhancement to player (legacy function - now asks for choice)
function EliteDriveSystem.applyPermanentEnhancement(player)
    -- This now creates a context menu for choosing enhancement type
    if not canUseEnhancementToken(player) then
        player:Say(getText("GVDrive_Msg_Enhancement_Max_Used") or "You have already used elite enhancements for all available stats!")
        return
    end
    
    -- In a real implementation, this would show a context menu
    -- For now, we'll apply a random available enhancement
    local enhancements = EliteDriveSystem.getPlayerEnhancements(player)
    local availableEnhancements = {}
    
    if not enhancements.CapacityTokenUsed then table.insert(availableEnhancements, "Capacity") end
    if not enhancements.SpeedTokenUsed then table.insert(availableEnhancements, "Speed") end
    if not enhancements.StrengthTokenUsed then table.insert(availableEnhancements, "Strength") end
    if not enhancements.EnduranceTokenUsed then table.insert(availableEnhancements, "Endurance") end
    if not enhancements.LuckTokenUsed then table.insert(availableEnhancements, "Luck") end
    
    if #availableEnhancements > 0 then
        local randomChoice = availableEnhancements[ZombRand(1, #availableEnhancements + 1)]
        EliteDriveSystem.applySpecificEnhancement(player, randomChoice)
    end
end

-- Apply runtime bonuses during gameplay
function EliteDriveSystem.applyRuntimeBonuses(player)
    if not player then
        return
    end

    local enhancements = EliteDriveSystem.getPlayerEnhancements(player)
    if not enhancements then
        return
    end

    if (enhancements.TotalTokensUsed or 0) <= 0 then
        return
    end

    -- Safe speed handling: store player's base move speed and apply multiplier without drifting.
    local speedBonus = enhancements.SpeedBonus or 0
    if player.getMoveSpeed and player.setMoveSpeed then
        local base = enhancements.BaseMoveSpeed
        if not base or base <= 0 then
            base = player:getMoveSpeed()
            enhancements.BaseMoveSpeed = base
        end

        if base and base > 0 then
            if (speedBonus or 0) > 0 then
                local target = base * (1 + speedBonus)
                -- Only set if different to avoid repeated writes
                if math.abs((player:getMoveSpeed() or 0) - target) > 0.0001 then
                    player:setMoveSpeed(target)
                end
                enhancements._speedApplied = true
            else
                -- If speed bonus removed, restore original speed if we applied it before
                if enhancements._speedApplied then
                    player:setMoveSpeed(base)
                    enhancements._speedApplied = false
                end
            end
        end
    end

    -- Strength and endurance bonuses are reserved for future implementation
end

-- Handle elite drive drops from zombies
function onZombieDeath(zombie)
    GVDebug.testPrint("onZombieDeath called with zombie:", tostring(zombie))
    if not zombie then 
    GVDebug.testPrint("Elite: zombie is nil, returning")
        return 
    end
    
    -- Check if it's actually a zombie (not a player)
    if instanceof(zombie, "IsoPlayer") then 
    GVDebug.testPrint("Elite: zombie is IsoPlayer, returning")
        return 
    end
    
    -- Get elite drop chance from sandbox (convert to 0-1 range)
    local eliteDropChance = ELITE_DROP_CHANCE
    GVDebug.testPrint("Getting elite drop chance from sandbox...")
    if GVDrive_Utils and GVDrive_Utils.getSandboxPercent then
        local pct = GVDrive_Utils.getSandboxPercent("EliteDrive_ZombieDrop_Chance", 1.0)  -- 0.05 * 100 / 5 = 1%
    GVDebug.testPrint("getSandboxPercent returned:", tostring(pct))
        -- getSandboxPercent now returns 0..100 scale always
        eliteDropChance = pct / 100.0
    GVDebug.testPrint("Final eliteDropChance:", tostring(eliteDropChance))
    else
        local raw = ELITE_DROP_CHANCE
        if GVDrive_Utils and GVDrive_Utils.getSandboxNumber then
            raw = GVDrive_Utils.getSandboxNumber('EliteDrive_ZombieDrop_Chance', ELITE_DROP_CHANCE)
        else
            local gv = (SandboxVars and SandboxVars.GVDrive) or {}
            raw = gv.EliteDrive_ZombieDrop_Chance or ELITE_DROP_CHANCE
        end
        if type(raw) == 'number' and raw > 1 then
            eliteDropChance = raw / 100.0
        else
            eliteDropChance = raw
        end
    end

        -- Ensure eliteDropChance is a numeric value and normalized to 0..1
        if type(eliteDropChance) ~= 'number' then
            eliteDropChance = tonumber(eliteDropChance) or ELITE_DROP_CHANCE
        end
        -- If someone configured percent as 0..100, normalize to 0..1
        if eliteDropChance > 1 then
            eliteDropChance = eliteDropChance / 100.0
        end

    -- Check for elite drive drop using high-resolution roll
    local chance = ZombRand(0, 10000) / 100.0
    local threshold = eliteDropChance * 100.0
    GVDebug.testPrint(string.format("Elite drive roll: %.2f vs threshold: %.4f (eliteDropChance=%s) - %s", chance, threshold, tostring(eliteDropChance), chance < threshold and "SUCCESS" or "FAILED"))
    if chance < threshold then
        local driveTypes = {
            "GValley.EliteDrive_Strength",
            "GValley.EliteDrive_Endurance", 
            "GValley.EliteDrive_Capacity",
            "GValley.EliteDrive_Speed",
            "GValley.EliteDrive_Luck"
        }
        
        local randomDrive = driveTypes[ZombRand(1, #driveTypes + 1)]
    zombie:getCurrentSquare():AddWorldInventoryItem(randomDrive, 0, 0, 0)
    GVDebug.debugPrint("Spawned elite drive:", randomDrive)
        
        -- Rare message for nearby players
        local players = getOnlinePlayers()
        for i = 0, players:size() - 1 do
            local player = players:get(i)
            local distance = IsoUtils.DistanceTo(player, zombie)
            if distance <= 10 then
                player:Say(getText("GVDrive_Msg_Elite_Found") or "Found something unusual...")
            end
        end
    end
end

-- Recipe callback for creating elite token
function OnCreateEliteToken(items, result, player)
    -- Remove the used elite drives from result (they're already consumed by recipe)
    if HaloTextHelper and HaloTextHelper.addTextWithArrow then
        HaloTextHelper.addTextWithArrow(player, getText("GVDrive_Msg_Elite_Token_Created") or "Elite enhancement protocol created!", true, HaloTextHelper.getColorGreen())
    end
end

-- Recipe callback for using elite enhancement
function OnUseEliteEnhancement(items, result, player)
    applyPermanentEnhancement(player)
end

-- Register events (server-only for persistent world spawns)
do
    local canRegister = false
    pcall(function()
        canRegister = isServer() or not isClient()
    end)
    if canRegister then
        if Events and Events.OnZombieDead and Events.OnZombieDead.Add then
            Events.OnZombieDead.Add(onZombieDeath)
            GVDebug.debugPrint("EliteDriveSystem registered OnZombieDead handler (server/SP)")
        end
    else
    GVDebug.debugPrint("Skipping EliteDriveSystem OnZombieDead registration: not server or SP")
    end
end

if Events and Events.OnPlayerUpdate and Events.OnPlayerUpdate.Add then
    Events.OnPlayerUpdate.Add(function(player)
        EliteDriveSystem.applyRuntimeBonuses(player)
    end)
end

-- RPC: handle client requests to apply an enhancement (defensive)
-- Expect data table: {command="ApplyEliteEnhancement", playerIndex=..., enhancement="Speed"}
local function handleClientCommand(playerIndexOrModule, moduleOrCommand, commandOrArgs, argsMaybe)
    -- Support multiple possible signatures. We try to extract:
    -- playerIndex, moduleName, command, args
    local playerIndex
    local moduleName
    local cmd
    local payload

    if type(playerIndexOrModule) == 'number' then
        -- signature: (playerIndex, module, command, args)
        playerIndex = playerIndexOrModule
        moduleName = moduleOrCommand
        cmd = commandOrArgs
        payload = argsMaybe
    else
        -- signature: (module, command, args)
        moduleName = playerIndexOrModule
        cmd = moduleOrCommand
        payload = commandOrArgs
    end

    -- If payload is a table with fields, prefer those
    local enhancement = nil
    local claimedPlayerIndex = nil
    if type(payload) == 'table' then
        enhancement = payload.enhancement or payload[1]
        claimedPlayerIndex = payload.playerIndex or payload[2]
    end

    -- Derive final playerIndex to act on
    local targetIndex = claimedPlayerIndex or playerIndex

    -- Authorization: if handler received a numeric playerIndex, ensure it matches claimedPlayerIndex if provided
    if playerIndex and claimedPlayerIndex and playerIndex ~= claimedPlayerIndex then
    GVDebug.debugPrint('[Unauthorized client command] playerIndex mismatch', tostring(playerIndex), tostring(claimedPlayerIndex))
        return
    end

    if cmd == "ApplyEliteEnhancement" and enhancement and targetIndex ~= nil then
        local player = getSpecificPlayer(targetIndex)
        if player then
            EliteDriveSystem.applySpecificEnhancement(player, enhancement)
        end
    end
end

-- Try to register server-side command listener if available
if Events and Events.OnClientCommand and Events.OnClientCommand.Add then
    Events.OnClientCommand.Add(handleClientCommand)
elseif Events and Events.OnServerCommand and Events.OnServerCommand.Add then
    Events.OnServerCommand.Add(handleClientCommand)
else
    -- No event exposed on this build; server will still accept direct calls via recipe callbacks.
    GVDebug.debugPrint("RPC handler not available: OnClientCommand/OnServerCommand missing")
end

-- Defensive RPC: handle direct UseEliteDrive requests from client (driveType, playerIndex)
local function handleUseEliteDrive(playerIndexOrModule, moduleOrCommand, commandOrArgs, argsMaybe)
    local playerIndex
    local moduleName
    local cmd
    local payload

    if type(playerIndexOrModule) == 'number' then
        playerIndex = playerIndexOrModule
        moduleName = moduleOrCommand
        cmd = commandOrArgs
        payload = argsMaybe
    else
        moduleName = playerIndexOrModule
        cmd = moduleOrCommand
        payload = commandOrArgs
    end

    local driveType = nil
    local claimedIndex = nil
    if type(payload) == 'table' then
        driveType = payload.driveType or payload[1]
        claimedIndex = payload.playerIndex or payload[2]
    end

    local targetIndex = claimedIndex or playerIndex
    if cmd == "UseEliteDrive" and driveType and targetIndex ~= nil then
        local player = getSpecificPlayer(targetIndex)
        if player then
            -- Apply shared logic if available
            if EliteDriveSystem and EliteDriveSystem.useEliteDrive then
                local ok = EliteDriveSystem.useEliteDrive(player, driveType)
                if ok and player.getInventory then
                    -- remove two item instances if present (require 2 items to apply)
                    local fullname = "GValley.EliteDrive_" .. driveType
                    local inv = player:getInventory()
                    local cnt = inv:getItemCount(fullname)
                    if cnt and cnt >= 2 then
                        -- remove two copies
                        inv:RemoveOneOf(fullname)
                        inv:RemoveOneOf(fullname)
                    elseif cnt and cnt == 1 then
                        -- Only one present: remove it and inform player (shouldn't happen because client checks for 2)
                        inv:RemoveOneOf(fullname)
                    end
                end
            else
                -- Fallback: try the applySpecificEnhancement path if tokens are used
                if EliteDriveSystem and EliteDriveSystem.applySpecificEnhancement then
                    EliteDriveSystem.applySpecificEnhancement(player, driveType)
                end
            end
        end
    end
end

if Events and Events.OnClientCommand and Events.OnClientCommand.Add then
    Events.OnClientCommand.Add(handleUseEliteDrive)
elseif Events and Events.OnServerCommand and Events.OnServerCommand.Add then
    Events.OnServerCommand.Add(handleUseEliteDrive)
end
