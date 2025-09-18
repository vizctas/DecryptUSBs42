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
    
    -- Get sandbox values for configurable bonuses
    local sandboxVars = SandboxVars and SandboxVars.GVDrive or {}
    
    local applied = false
    local message = ""
    
    if driveType == "Strength" then
        -- Configurable strength bonus (default 1)
        local bonus = sandboxVars.Elite_Strength_Bonus or 1
        for i = 1, bonus do
            if not player:HasTrait("Strong") then
                player:getTraits():add("Strong")
                break
            elseif not player:HasTrait("Stout") then
                player:getTraits():add("Stout")
                break
            end
        end
        message = "¡Mejora Elite aplicada! +" .. bonus .. " Fuerza física!"
        applied = true
        
    elseif driveType == "Endurance" then
        -- Configurable endurance bonus (default 1)
        local bonus = sandboxVars.Elite_Endurance_Bonus or 1
        player:getStats():setEndurance(player:getStats():getEndurance() + bonus)
        message = "¡Mejora Elite aplicada! +" .. bonus .. " Resistencia!"
        applied = true
        
    elseif driveType == "Capacity" then
        -- Configurable capacity bonus (default 4kg, reduced from 8kg)
        local bonus = sandboxVars.Elite_Capacity_Bonus or 4
        player:setMaxWeight(player:getMaxWeight() + bonus)
        message = "¡Mejora Elite aplicada! +" .. bonus .. "kg Capacidad de carga!"
        applied = true
        
    elseif driveType == "Speed" then
        -- Configurable speed bonus (default 1)
        local bonus = sandboxVars.Elite_Speed_Bonus or 1
        if bonus >= 1 and not player:HasTrait("Fast") then
            player:getTraits():add("Fast")
        end
        if bonus >= 2 and not player:HasTrait("Runner") then
            player:getTraits():add("Runner")
        end
        message = "¡Mejora Elite aplicada! +" .. bonus .. " Velocidad de movimiento!"
        applied = true
        
    elseif driveType == "Luck" then
        -- Configurable luck bonus (default 2)
        local bonus = sandboxVars.Elite_Luck_Bonus or 2
        if bonus >= 1 and not player:HasTrait("Lucky") then
            player:getTraits():add("Lucky")
        end
        if bonus >= 2 and not player:HasTrait("Resilient") then
            player:getTraits():add("Resilient")
        end
        message = "¡Mejora Elite aplicada! +" .. bonus .. " Suerte y resistencia!"
        applied = true
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