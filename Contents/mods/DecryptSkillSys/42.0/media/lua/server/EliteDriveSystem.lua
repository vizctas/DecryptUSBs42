-- Elite Drive System Functions
-- Handles special elite drives and permanent enhancements

require "shared/GVDrive_Utils"

-- Elite drive drop chances (very rare)
local ELITE_DROP_CHANCE = 0.15 -- 0.15% chance per zombie

-- Track player enhancements in ModData
function getPlayerEnhancements(player)
    local data = player:getModData()
    if not data.GVDrive_Enhancements then
        data.GVDrive_Enhancements = {
            CapacityBonus = 0,
            SpeedBonus = 0,
            StrengthBonus = 0,
            EnduranceBonus = 0,
            LuckBonus = 0,
            TokensUsed = 0
        }
    end
    return data.GVDrive_Enhancements
end

-- Apply permanent enhancement to player
function applyPermanentEnhancement(player)
    local enhancements = getPlayerEnhancements(player)
    
    -- Increase bonuses
    enhancements.CapacityBonus = enhancements.CapacityBonus + 5
    enhancements.SpeedBonus = enhancements.SpeedBonus + 0.1
    enhancements.StrengthBonus = enhancements.StrengthBonus + 1
    enhancements.EnduranceBonus = enhancements.EnduranceBonus + 1
    enhancements.LuckBonus = enhancements.LuckBonus + 1
    enhancements.TokensUsed = enhancements.TokensUsed + 1
    
    -- Apply capacity bonus immediately
    local maxWeight = player:getMaxWeight()
    player:setMaxWeight(maxWeight + 5)
    
    -- Show message
    player:Say(getText("GVDrive_Msg_Enhancement_Applied") or "Elite enhancement applied! You feel stronger and more capable.")
    
    -- Apply other bonuses (will be handled by events)
    Events.OnPlayerUpdate.Add(applyRuntimeBonuses)
end

-- Apply runtime bonuses during gameplay
function applyRuntimeBonuses(player)
    local enhancements = getPlayerEnhancements(player)
    
    if enhancements.TokensUsed > 0 then
        -- Speed bonus (very small but noticeable)
        local currentSpeed = player:getMoveSpeed()
        if currentSpeed > 0 then
            player:setMoveSpeed(currentSpeed * (1 + enhancements.SpeedBonus))
        end
        
        -- Strength and endurance bonuses are applied through trait modifications
        -- This would require more complex implementation
    end
end

-- Handle elite drive drops from zombies
function onZombieDeath(zombie)
    if not zombie or zombie:isPlayer() then return end
    
    -- Get elite drop chance from sandbox (convert to 0-1 range)
    local eliteDropChance = ((SandboxVars.GVDrive and SandboxVars.GVDrive.EliteDrive_ZombieDrop_Chance) or 0.15)
    
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