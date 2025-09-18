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
local function getSandboxGV()
    return (SandboxVars and SandboxVars.GVDrive) or nil
end

local function normalizeItem(item)
    if item and item.getItem then
        local ok, inner = pcall(item.getItem, item)
        if ok and inner then
            return inner
        end
    end
    return item
end

function LaptopSystem.getLaptopHealth(item)
    item = normalizeItem(item)
    if not item then return 0 end
    local modData = item:getModData()
    if not modData then return 0 end -- Safety check for nil modData
    if not modData.laptopHealth then
        -- Initialize laptop health with random value based on sandbox settings
        local sandboxGV = getSandboxGV()
        local minHealth = (sandboxGV and sandboxGV.Laptop_Random_Health_Min) or 30
        local maxHealth = (sandboxGV and sandboxGV.Laptop_Random_Health_Max) or 85
        
        -- Use ZombRand for random health between min and max
        local randomHealth = ZombRand(minHealth, maxHealth + 1)
        modData.laptopHealth = randomHealth
    end
    return modData.laptopHealth
end

-- Set laptop health
function LaptopSystem.setLaptopHealth(item, health)
    item = normalizeItem(item)
    if not item then return end
    local modData = item:getModData()
    if not modData then return end -- Safety check for nil modData

    local clamped = math.floor(math.max(0, math.min(100, health or 0)))
    modData.laptopHealth = clamped

    if item.setCondition then
        local maxCondition = 100
        if item.getConditionMax then
            local ok, value = pcall(function() return item:getConditionMax() end)
            if ok and type(value) == "number" and value > 0 then
                maxCondition = value
            end
        end
        local newCondition = math.floor((clamped / 100) * maxCondition)
        newCondition = math.max(0, math.min(maxCondition, newCondition))
        item:setCondition(newCondition)
    end

    if item.setName and getText then
        local nameKey = ""
        if clamped <= 0 then
            nameKey = "GVDrive_Laptop_Broken"
        elseif clamped <= 25 then
            nameKey = "GVDrive_Laptop_Critical"
        elseif clamped <= 50 then
            nameKey = "GVDrive_Laptop_Damaged"
        elseif clamped <= 75 then
            nameKey = "GVDrive_Laptop_Worn"
        else
            nameKey = "GVDrive_Laptop_Healthy"
        end
        
        local translatedName = getText(nameKey)
        if translatedName and translatedName ~= nameKey then
            item:setName(translatedName)
        else
            -- Fallback to English names
            local fallbackNames = {
                GVDrive_Laptop_Broken = "Broken Laptop (Unusable)",
                GVDrive_Laptop_Critical = "Laptop (Critical Condition)",
                GVDrive_Laptop_Damaged = "Laptop (Heavily Damaged)",
                GVDrive_Laptop_Worn = "Laptop (Worn)",
                GVDrive_Laptop_Healthy = "Laptop (Good Condition)"
            }
            item:setName(fallbackNames[nameKey] or "Laptop")
        end
    end

    if item.setTooltip and getText then
        local healthStr = getText("GVDrive_Laptop_Health_Label") or "Health"
        item:setTooltip(healthStr .. ": " .. clamped .. "%")
    end
end

-- Damage laptop (normal use)
function LaptopSystem.damageLaptop(item, damage)
    item = normalizeItem(item)
    if not item then return end
    local currentHealth = LaptopSystem.getLaptopHealth(item)
    local newHealth = currentHealth - (damage or 1)
    LaptopSystem.setLaptopHealth(item, newHealth)
    return newHealth
end

-- Check if laptop can be used (health only, power requirement disabled)
function LaptopSystem.canUseLaptop(player, laptop)
    laptop = normalizeItem(laptop)
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
    item = normalizeItem(item)
    if not item then return end
    
    local modData = item:getModData()
    if not modData then return end -- Safety check for nil modData
    if not modData.hasMalware then
        modData.hasMalware = true
        modData.malwareLevel = 1
        
        -- Malware causes extra damage over time
        local sandboxGV = getSandboxGV()
        local malwareDamage = (sandboxGV and sandboxGV.Malware_Damage_Per_Use) or 5
        LaptopSystem.damageLaptop(item, malwareDamage)
        
        return true -- New malware infection
    else
        -- Existing malware gets worse
        modData.malwareLevel = (modData.malwareLevel or 1) + 1
        local sandboxGV = getSandboxGV()
        local baseDamage = (sandboxGV and sandboxGV.Malware_Damage_Per_Use) or 5
        local malwareDamage = baseDamage * (modData.malwareLevel or 1)
        LaptopSystem.damageLaptop(item, malwareDamage)
        
        return false -- Existing malware worsened
    end
end

-- Check if laptop has malware
function LaptopSystem.hasMalware(item)
    item = normalizeItem(item)
    if not item then return false end
    local modData = item:getModData()
    if not modData then return false end -- Safety check for nil modData
    return modData.hasMalware or false
end

-- Get malware level
function LaptopSystem.getMalwareLevel(item)
    item = normalizeItem(item)
    if not item then return 0 end
    local modData = item:getModData()
    if not modData then return 0 end -- Safety check for nil modData
    return modData.malwareLevel or 0
end

-- Clean malware with specific antivirus items (reduced recovery rates)
function LaptopSystem.cleanMalwareWithAntivirus(item, antivirusType)
    item = normalizeItem(item)
    if not item then return false end
    
    local modData = item:getModData()
    if not modData then return false end -- Safety check for nil modData
    if not modData.hasMalware then return false end
    
    -- Remove malware
    modData.hasMalware = false
    modData.malwareLevel = 0
    
    -- Restore health based on antivirus type (reduced rates)
    local currentHealth = LaptopSystem.getLaptopHealth(item)
    local healAmount = 5 -- Default Norton
    
    if antivirusType == "Norton" then
        healAmount = 5
    elseif antivirusType == "Kaspersky" then
        healAmount = 8
    elseif antivirusType == "McAfee" then
        healAmount = 10
    elseif antivirusType == "MalwareBytes" then
        healAmount = 12
    end
    
    local newHealth = currentHealth + healAmount
    LaptopSystem.setLaptopHealth(item, newHealth)
    
    return true
end

-- Backwards-compatible wrapper used by server/client calls in the mod.
-- Accepts either a numeric heal amount or a compatibility antivirus identifier.
function LaptopSystem.cleanMalware(item, healOrType)
    item = normalizeItem(item)
    if not item then return false end
    local modData = item:getModData()
    if not modData then return false end
    if not modData.hasMalware then
        -- If there was no malware, still allow small heal if numeric was passed
        if type(healOrType) == 'number' and healOrType > 0 then
            local current = LaptopSystem.getLaptopHealth(item)
            LaptopSystem.setLaptopHealth(item, current + healOrType)
            return false
        end
        return false
    end

    -- Determine heal amount
    local healAmount = 0
    if type(healOrType) == 'number' then
        healAmount = healOrType
    elseif type(healOrType) == 'string' then
        -- Map known compatibility identifiers to heal amounts
        local map = {
            AntivirusDisk_Basic = 25,
            AntivirusDisk_Advanced = 50,
            AntivirusDisk_Premium = 75,
            Norton = 5,
            Kaspersky = 8,
            McAfee = 10,
            MalwareBytes = 12,
        }
        healAmount = map[healOrType] or 0
    end

    -- Remove malware and reset level
    modData.hasMalware = false
    modData.malwareLevel = 0

    local currentHealth = LaptopSystem.getLaptopHealth(item)
    LaptopSystem.setLaptopHealth(item, currentHealth + healAmount)
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
