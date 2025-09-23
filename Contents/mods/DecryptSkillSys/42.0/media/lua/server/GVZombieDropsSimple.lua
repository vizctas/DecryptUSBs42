-- Sistema simplificado de zombie drops usando OnZombieDead nativo
-- Reemplaza el sistema complejo anterior con approach directo

require "shared/GVDrive_Utils"
local ok_debug, GVDebug = pcall(require, "shared/GVDebug")
if not ok_debug or not GVDebug then
    GVDebug = { debugPrint = function(...) end }
end

local DEBUG = false
pcall(function()
    local ok_cfg, GVDrive_Config = pcall(require, "shared/GVDrive_Config")
    if ok_cfg and GVDrive_Config and GVDrive_Config.getDebug then
        DEBUG = GVDrive_Config.getDebug()
    end
end)

local function debugPrint(...)
    if DEBUG then
        GVDebug.debugPrint(...)
    end
end

-- CONFIGURACIÓN SIMPLE: Probabilidades y items
local DROP_CONFIG = {
    -- Probabilidades base (en porcentaje)
    chances = {
        skillDrive = 8.0,  -- 8% chance de drop de skilldrive
        laptop = 3.0,      -- 3% chance de drop de laptop  
        elite = 0.5,       -- 0.5% chance de drop elite (muy raro)
        antivirus = 4.0    -- 4% chance de drop antivirus
    },
    
    -- Listas de items disponibles
    items = {
        skillDrives = {
            "GValley.SkillDrive_Woodwork_Facil",
            "GValley.SkillDrive_Mechanics_Facil", 
            "GValley.SkillDrive_Electricity_Facil",
            "GValley.SkillDrive_Cooking_Facil",
            "GValley.SkillDrive_Farming_Facil",
            "GValley.SkillDrive_Aiming_Facil",
            "GValley.SkillDrive_Woodwork_Moderado",
            "GValley.SkillDrive_Mechanics_Moderado",
            "GValley.SkillDrive_Woodwork_Dificil",
            "GValley.SkillDrive_Mechanics_Dificil"
        },
        laptops = {
            "GValley.AsusZephLaptopClosed",
            "GValley.Laptop90sClosed",
            "GValley.PBIBM_LP90Closed"
        },
        elites = {
            "GValley.EliteDrive_Strength",
            "GValley.EliteDrive_Endurance", 
            "GValley.EliteDrive_Capacity",
            "GValley.EliteDrive_Speed",
            "GValley.EliteDrive_Luck"
        },
        antivirus = {
            "GValley.Antivirus_Norton",
            "GValley.Antivirus_Kaspersky",
            "GValley.Antivirus_McAfee",
            "GValley.Antivirus_MalwareBytes"
        }
    }
}

-- Función simple para añadir item al zombie o al suelo
local function addItemToZombie(zombie, itemType)
    if not zombie then return false end
    
    local success = false
    
    -- Intentar añadir al inventario del zombie primero
    pcall(function()
        local inv = zombie:getInventory()
        if inv then
            inv:AddItem(itemType)
            success = true
            debugPrint("✅ Added", itemType, "to zombie inventory")
        end
    end)
    
    -- Si falla, añadir al suelo
    if not success then
        pcall(function()
            local square = zombie:getCurrentSquare()
            if square then
                square:AddWorldInventoryItem(itemType, 0, 0, 0)
                success = true
                debugPrint("✅ Added", itemType, "to ground")
            end
        end)
    end
    
    return success
end

-- Función principal de drops simplificada
local function onZombieDeadSimple(zombie)
    if not zombie or instanceof(zombie, "IsoPlayer") then
        return
    end
    
    debugPrint("🧟 Zombie killed, checking drops...")
    
    -- Verificar cada tipo de drop independientemente
    local dropTypes = {
        {name = "skillDrive", chance = DROP_CONFIG.chances.skillDrive, items = DROP_CONFIG.items.skillDrives},
        {name = "laptop", chance = DROP_CONFIG.chances.laptop, items = DROP_CONFIG.items.laptops},
        {name = "elite", chance = DROP_CONFIG.chances.elite, items = DROP_CONFIG.items.elites},
        {name = "antivirus", chance = DROP_CONFIG.chances.antivirus, items = DROP_CONFIG.items.antivirus}
    }
    
    for _, dropType in ipairs(dropTypes) do
        local roll = ZombRand(0, 10000) / 100.0  -- 0.00 a 100.00
        
        if roll < dropType.chance then
            -- Seleccionar item aleatorio de la categoría
            -- Defensive: ensure items is a table with a usable length
            local itemsTbl = (type(dropType.items) == "table") and dropType.items or {}
            local itemCount = 0
            if itemsTbl then
                -- protect against non-array-like tables
                local ok, cnt = pcall(function() return #itemsTbl end)
                if ok and type(cnt) == "number" then
                    itemCount = cnt
                end
            end
            local randomItem = nil
            if itemCount > 0 then
                randomItem = itemsTbl[ZombRand(itemCount) + 1]
            end
            local success = addItemToZombie(zombie, randomItem)
            
            debugPrint(string.format("🎯 %s DROP: %.2f%% < %.2f%% = %s (%s)", 
                dropType.name:upper(), roll, dropType.chance, 
                success and "SUCCESS" or "FAILED", randomItem))
        else
            debugPrint(string.format("❌ %s: %.2f%% >= %.2f%% = NO DROP", 
                dropType.name, roll, dropType.chance))
        end
    end
end

-- Registro simple del evento
local function registerSimpleHandler()
    if Events and Events.OnZombieDead then
        Events.OnZombieDead.Add(onZombieDeadSimple)
        debugPrint("✅ Simple zombie drop handler registered")
        
        -- Log configuración
        debugPrint("📊 DROP CONFIGURATION:")
        for category, chance in pairs(DROP_CONFIG.chances) do
                local itemsList = DROP_CONFIG.items[category .. "s"] or DROP_CONFIG.items[category]
                local itemCount = 0
                if type(itemsList) == "table" then
                    local ok, cnt = pcall(function() return #itemsList end)
                    if ok and type(cnt) == "number" then itemCount = cnt end
                end
                debugPrint(string.format("   %s: %.1f%% chance, %d items available", category, chance, itemCount))
        end
    else
        debugPrint("❌ Events.OnZombieDead not available")
    end
end

-- Ejecutar registro
registerSimpleHandler()

debugPrint("Simple zombie loot system loaded")