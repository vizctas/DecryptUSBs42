-- Elite Drive System Functions
-- Handles special elite drives and permanent enhancements

require "shared/GVDrive_Utils"
require "shared/EliteDriveSystem"

-- Elite drive drop chances (very rare)
local ELITE_DROP_CHANCE = 0.15 -- 0.15% chance per zombie

-- Track player enhancements in ModData
function getPlayerEnhancements(player)
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
            TotalTokensUsed = 0
        }
    end
    return data.GVDrive_Enhancements
end

-- Check if player can use enhancement token (must choose which stat to enhance)
function canUseEnhancementToken(player)
    local enhancements = getPlayerEnhancements(player)
    -- Can use token if not all stats have been enhanced
    return not (enhancements.CapacityTokenUsed and 
                enhancements.SpeedTokenUsed and 
                enhancements.StrengthTokenUsed and 
                enhancements.EnduranceTokenUsed and 
                enhancements.LuckTokenUsed)
end

-- Apply specific permanent enhancement to player
function applySpecificEnhancement(player, enhancementType)
    local enhancements = getPlayerEnhancements(player)
    
    -- Check if this specific enhancement has already been used
    local tokenKey = enhancementType .. "TokenUsed"
    if enhancements[tokenKey] then
        player:Say(getText("GVDrive_Msg_Enhancement_Already_Used") or "You have already used an enhancement for " .. enhancementType .. "!")
        return false
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
        enhancements.BaseMoveSpeed = enhancements.BaseMoveSpeed or player:getMoveSpeed()
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
function applyPermanentEnhancement(player)
    -- This now creates a context menu for choosing enhancement type
    if not canUseEnhancementToken(player) then
        player:Say(getText("GVDrive_Msg_Enhancement_Max_Used") or "You have already used elite enhancements for all available stats!")
        return
    end
    
    -- In a real implementation, this would show a context menu
    -- For now, we'll apply a random available enhancement
    local enhancements = getPlayerEnhancements(player)
    local availableEnhancements = {}
    
    if not enhancements.CapacityTokenUsed then table.insert(availableEnhancements, "Capacity") end
    if not enhancements.SpeedTokenUsed then table.insert(availableEnhancements, "Speed") end
    if not enhancements.StrengthTokenUsed then table.insert(availableEnhancements, "Strength") end
    if not enhancements.EnduranceTokenUsed then table.insert(availableEnhancements, "Endurance") end
    if not enhancements.LuckTokenUsed then table.insert(availableEnhancements, "Luck") end
    
    if #availableEnhancements > 0 then
        local randomChoice = availableEnhancements[ZombRand(1, #availableEnhancements + 1)]
        applySpecificEnhancement(player, randomChoice)
    end
end

-- Apply runtime bonuses during gameplay
function EliteDriveSystem.applyRuntimeBonuses(player)
    if not player then
        return
    end

    local enhancements = getPlayerEnhancements(player)
    if not enhancements then
        return
    end

    if (enhancements.TotalTokensUsed or 0) <= 0 then
        return
    end

    local speedBonus = enhancements.SpeedBonus or 0
    if speedBonus > 0 and player.getMoveSpeed and player.setMoveSpeed then
        local base = enhancements.BaseMoveSpeed
        if not base or base <= 0 then
            base = player:getMoveSpeed()
            enhancements.BaseMoveSpeed = base
        end
        if base and base > 0 then
            local target = base * (1 + speedBonus)
            player:setMoveSpeed(target)
        end
    end

    -- Strength and endurance bonuses are reserved for future implementation
end

-- Handle elite drive drops from zombies
function onZombieDeath(zombie)
    if not zombie then return end
    
    -- Check if it's actually a zombie (not a player)
    if instanceof(zombie, "IsoPlayer") then return end
    
    -- Get elite drop chance from sandbox (convert to 0-1 range)
    local eliteDropChance = ((SandboxVars and SandboxVars.GVDrive and SandboxVars.GVDrive.EliteDrive_ZombieDrop_Chance) or 0.15)
    
    -- Check for elite drive drop
    local chance = ZombRand(1, 10000) / 100.0
    if chance <= eliteDropChance then
        local driveTypes = {
            "GValley.EliteDrive_Strength",
            "GValley.EliteDrive_Endurance", 
            "GValley.EliteDrive_Capacity",
            "GValley.EliteDrive_Speed",
            "GValley.EliteDrive_Luck"
        }
        
        local randomDrive = driveTypes[ZombRand(1, #driveTypes + 1)]
        zombie:getCurrentSquare():AddWorldInventoryItem(randomDrive, 0, 0, 0)
        
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

-- Register events
Events.OnZombieDead.Add(onZombieDeath)

if Events and Events.OnPlayerUpdate and Events.OnPlayerUpdate.Add then
    Events.OnPlayerUpdate.Add(function(player)
        EliteDriveSystem.applyRuntimeBonuses(player)
    end)
end
