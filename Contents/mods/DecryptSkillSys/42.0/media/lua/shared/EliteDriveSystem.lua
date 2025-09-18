-- Elite Drive System (SIMPLIFIED - DIRECT BENEFITS)
-- Each elite USB gives immediate permanent benefits when used
-- No need to combine - each USB works independently

EliteDriveSystem = {}

-- Apply elite enhancement to player based on drive type
function EliteDriveSystem.useEliteDrive(player, driveType)
    if not player then return false end
    
    local modData = player:getModData()
    if not modData.eliteEnhancements then
        modData.eliteEnhancements = {}
    end
    
    -- Initialize counter table
    if not modData.eliteEnhancements[driveType] then
        modData.eliteEnhancements[driveType] = 0
    end
    -- Allow up to 2 uses per elite enhancement
    if modData.eliteEnhancements[driveType] >= 2 then
        player:Say(getText("GVDrive_Msg_Enhancement_Already_Used") or "Ya alcanzaste el limite de usos para esta mejora elite!")
        return false
    end
    
    local applied = false
    local message = ""
    
    if driveType == "Strength" then
        -- Increase combat effectiveness
        player:getTraits():add("Brawler") -- Add brawler trait if not present
        message = "¡Mejora Elite aplicada! +Eficacia en combate cuerpo a cuerpo!"
        applied = true
        
    elseif driveType == "Endurance" then
        -- Increase endurance and stamina
        player:getStats():setEndurance(player:getStats():getEndurance() + 1)
        message = "¡Mejora Elite aplicada! +1 Resistencia!"
        applied = true
        
    elseif driveType == "Capacity" then
        -- Increase carry weight by 8kg
        player:setMaxWeight(player:getMaxWeight() + 8)
        message = "¡Mejora Elite aplicada! +8kg Capacidad de carga!"
        applied = true
        
    elseif driveType == "Speed" then
        -- Add speed demon trait for movement bonus
        if not player:HasTrait("SpeedDemon") then
            player:getTraits():add("SpeedDemon")
        end
        message = "¡Mejora Elite aplicada! +Velocidad de movimiento!"
        applied = true
        
    elseif driveType == "Luck" then
        -- Add lucky trait
        if not player:HasTrait("Lucky") then
            player:getTraits():add("Lucky")
        end
        message = "¡Mejora Elite aplicada! +Suerte mejorada!"
        applied = true
    end
    
    if applied then
        -- Increment use count for this enhancement
        modData.eliteEnhancements[driveType] = (modData.eliteEnhancements[driveType] or 0) + 1
        player:Say(message)
        return true
    end
    
    return false
end

-- Check what elite enhancements player has used
function EliteDriveSystem.getUsedEnhancements(player)
    if not player then return {} end
    local modData = player:getModData()
    return modData.eliteEnhancements or {}
end

-- Check if specific enhancement was used
function EliteDriveSystem.hasUsedEnhancement(player, driveType)
    if not player then return false end
    local modData = player:getModData()
    if not modData.eliteEnhancements then return false end
    -- Return numeric count of how many times this enhancement was applied (0..2)
    return modData.eliteEnhancements[driveType] or 0
end

print("[DecryptSkillSys] EliteDriveSystem loaded (simplified direct benefits)")