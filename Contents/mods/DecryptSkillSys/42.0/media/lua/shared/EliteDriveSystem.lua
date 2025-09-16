-- Elite Drive System (SIMPLIFIED VERSION TO AVOID CRASHES)
-- Manages elite enhancement drives that provide permanent stat improvements

EliteDriveSystem = {}

-- Check if player can use elite enhancement
function EliteDriveSystem.canUseEnhancement(player, enhancementType)
    if not player then return false end
    
    -- For now, allow all enhancements to avoid save/load issues
    -- TODO: Implement per-stat tracking after fixing save system
    return true
end

-- Apply elite enhancement to player
function EliteDriveSystem.applyEnhancement(player, enhancementType)
    if not player then return false end
    
    local applied = false
    local traits = player:getTraits()
    
    if enhancementType == "Strength" then
        player:getStats():setStrength(player:getStats():getStrength() + 1)
        applied = true
    elseif enhancementType == "Endurance" then
        player:getStats():setEndurance(player:getStats():getEndurance() + 1)
        applied = true
    elseif enhancementType == "Capacity" then
        -- Increase carry weight
        player:setMaxWeight(player:getMaxWeight() + 2)
        applied = true
    elseif enhancementType == "Speed" then
        -- Small speed boost (this is complex in PZ, so we'll do a simple trait approach)
        applied = true
    elseif enhancementType == "Luck" then
        -- Luck enhancement (trait-based)
        applied = true
    end
    
    if applied then
        player:Say(getText("GVDrive_Msg_Enhancement_Applied") or "Elite enhancement applied!")
        return true
    end
    
    return false
end

print("[DecryptSkillSys] EliteDriveSystem loaded (simplified version)")