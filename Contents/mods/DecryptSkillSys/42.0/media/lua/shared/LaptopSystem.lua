-- Laptop System - Power and Health Management
-- Handles laptop power requirements and durability system

LaptopSystem = {}

-- Check if player has access to electricity (DISABLED - laptops work without power)
function LaptopSystem.hasElectricity(player)
    -- Power requirement disabled for laptops
    return true
    
    --[[
    if not player then return false end
    
    local square = player:getCurrentSquare()
    if not square then return false end
    
    -- Check if current square has electricity
    if square:haveElectricity() then
        return true
    end
    
    -- Check for nearby generators (within 20 tiles)
    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()
    
    for dx = -20, 20 do
        for dy = -20, 20 do
            local checkSquare = getCell():getGridSquare(x + dx, y + dy, z)
            if checkSquare then
                local objects = checkSquare:getObjects()
                for i = 0, objects:size() - 1 do
                    local obj = objects:get(i)
                    if obj and obj:getSprite() then
                        local spriteName = obj:getSprite():getName()
                        -- Check for generator sprites (common generator names in PZ)
                        if spriteName and (
                            string.find(spriteName:lower(), "generator") or
                            string.find(spriteName:lower(), "gen_") or
                            obj:getObjectName() == "Generator"
                        ) then
                            -- Check if generator is activated/running
                            local generator = obj:getModData().generator
                            if generator and generator.isActivated and generator.fuelAmount > 0 then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    
    return false
    --]]
end

-- Get laptop health/durability from item
function LaptopSystem.getLaptopHealth(item)
    if not item then return 0 end
    local modData = item:getModData()
    if not modData then return 0 end -- Safety check for nil modData
    if not modData.laptopHealth then
        -- Initialize laptop health (100 = perfect, 0 = broken)
        modData.laptopHealth = SandboxVars.GVDrive.Laptop_Initial_Health or 100
    end
    return modData.laptopHealth
end

-- Set laptop health
function LaptopSystem.setLaptopHealth(item, health)
    if not item then return end
    local modData = item:getModData()
    if not modData then return end -- Safety check for nil modData
    modData.laptopHealth = math.max(0, math.min(100, health))
    
    -- Update item condition based on health
    local condition = health / 100
    item:setCondition(condition)
    
    -- Change item name/description based on health
    if health <= 0 then
        item:setName(getText("GVDrive_Laptop_Broken"))
        item:setTooltip(getText("GVDrive_Laptop_Broken_Tooltip"))
    elseif health <= 25 then
        item:setName(getText("GVDrive_Laptop_Critical"))
        item:setTooltip(getText("GVDrive_Laptop_Critical_Tooltip"))
    elseif health <= 50 then
        item:setName(getText("GVDrive_Laptop_Damaged"))
        item:setTooltip(getText("GVDrive_Laptop_Damaged_Tooltip"))
    elseif health <= 75 then
        item:setName(getText("GVDrive_Laptop_Worn"))
        item:setTooltip(getText("GVDrive_Laptop_Worn_Tooltip"))
    end
end

-- Damage laptop (normal use)
function LaptopSystem.damageLaptop(item, damage)
    if not item then return end
    local currentHealth = LaptopSystem.getLaptopHealth(item)
    local newHealth = currentHealth - (damage or 1)
    LaptopSystem.setLaptopHealth(item, newHealth)
    return newHealth
end

-- Check if laptop can be used (health only, power requirement disabled)
function LaptopSystem.canUseLaptop(player, laptop)
    if not player or not laptop then return false, "GVDrive_Error_Invalid" end
    
    -- Check laptop health
    local health = LaptopSystem.getLaptopHealth(laptop)
    if health <= 0 then
        return false, "GVDrive_Error_Laptop_Broken"
    end
    
    -- Power requirement disabled - laptops can work without electricity
    -- if not LaptopSystem.hasElectricity(player) then
    --     return false, "GVDrive_Error_No_Power"
    -- end
    
    return true, nil
end

-- Apply malware to laptop
function LaptopSystem.applyMalware(item)
    if not item then return end
    
    local modData = item:getModData()
    if not modData then return end -- Safety check for nil modData
    if not modData.hasMalware then
        modData.hasMalware = true
        modData.malwareLevel = 1
        
        -- Malware causes extra damage over time
        local malwareDamage = SandboxVars.GVDrive.Malware_Damage_Per_Use or 5
        LaptopSystem.damageLaptop(item, malwareDamage)
        
        return true -- New malware infection
    else
        -- Existing malware gets worse
        modData.malwareLevel = (modData.malwareLevel or 1) + 1
        local malwareDamage = (SandboxVars.GVDrive.Malware_Damage_Per_Use or 5) * modData.malwareLevel
        LaptopSystem.damageLaptop(item, malwareDamage)
        
        return false -- Existing malware worsened
    end
end

-- Check if laptop has malware
function LaptopSystem.hasMalware(item)
    if not item then return false end
    local modData = item:getModData()
    if not modData then return false end -- Safety check for nil modData
    return modData.hasMalware or false
end

-- Get malware level
function LaptopSystem.getMalwareLevel(item)
    if not item then return 0 end
    local modData = item:getModData()
    if not modData then return 0 end -- Safety check for nil modData
    return modData.malwareLevel or 0
end

-- Clean malware with antivirus
function LaptopSystem.cleanMalware(item, antivirusStrength)
    if not item then return false end
    
    local modData = item:getModData()
    if not modData then return false end -- Safety check for nil modData
    if not modData.hasMalware then return false end
    
    -- Remove malware
    modData.hasMalware = false
    modData.malwareLevel = 0
    
    -- Restore some health based on antivirus strength
    local currentHealth = LaptopSystem.getLaptopHealth(item)
    local healAmount = antivirusStrength or 25
    local newHealth = currentHealth + healAmount
    LaptopSystem.setLaptopHealth(item, newHealth)
    
    return true
end

-- Get laptop type from item
function LaptopSystem.getLaptopType(item)
    if not item then return "unknown" end
    
    local itemType = item:getType()
    if string.find(itemType, "Asus") then
        return "asus"
    elseif string.find(itemType, "90s") or string.find(itemType, "IBM") then
        return "retro"
    else
        return "modern"
    end
end