-- LaptopThermalSystem.lua - Sistema de Sobrecalentamiento de Laptops
-- Las laptops se calientan durante el uso y pueden fallar o causar daño si se sobrecalientan

LaptopThermalSystem = LaptopThermalSystem or {}

-- ============================================================================
-- CONFIGURACIÓN
-- ============================================================================

LaptopThermalSystem.MAX_TEMPERATURE = 100  -- Temperatura máxima (%)
LaptopThermalSystem.CRITICAL_TEMP = 85     -- Temperatura crítica (%)
LaptopThermalSystem.OVERHEAT_TEMP = 95     -- Temperatura de sobrecalentamiento (%)

-- Incrementos de temperatura por dificultad de minijuego
LaptopThermalSystem.HEAT_PER_MINIGAME = {
    Easy = 15,        -- +15% temperatura
    Moderate = 25,    -- +25% temperatura
    Expert = 35       -- +35% temperatura
}

-- Velocidad de enfriamiento natural (% por segundo)
LaptopThermalSystem.COOLING_RATE = 2       -- 2% por segundo cuando no se usa
LaptopThermalSystem.COOLING_RATE_IDLE = 5  -- 5% por segundo si laptop está cerrada

-- ============================================================================
-- FUNCIONES DE TEMPERATURA
-- ============================================================================

-- Obtener temperatura actual de la laptop
function LaptopThermalSystem.getTemperature(laptop)
    if not laptop then return 0 end
    local modData = laptop:getModData()
    if not modData.GVDrive_Temperature then
        modData.GVDrive_Temperature = 20  -- Temperatura ambiente inicial
    end
    return modData.GVDrive_Temperature
end

-- Establecer temperatura de la laptop
function LaptopThermalSystem.setTemperature(laptop, temp)
    if not laptop then return end
    local modData = laptop:getModData()
    -- Clamp entre 20 (ambiente) y 100 (máximo)
    modData.GVDrive_Temperature = math.max(20, math.min(100, temp))
    return modData.GVDrive_Temperature
end

-- Aumentar temperatura por usar minijuego
function LaptopThermalSystem.addHeat(laptop, difficulty)
    if not laptop then return 0 end
    
    local currentTemp = LaptopThermalSystem.getTemperature(laptop)
    local heatIncrease = LaptopThermalSystem.HEAT_PER_MINIGAME[difficulty] or 20
    
    -- Aplicar modificadores
    local modData = laptop:getModData()
    if modData.GVDrive_HasLiquidCooling then
        heatIncrease = heatIncrease * 0.5  -- -50% calor si tiene cooling
    end
    
    local newTemp = LaptopThermalSystem.setTemperature(laptop, currentTemp + heatIncrease)
    
    print("[ThermalSystem] Laptop heated: " .. currentTemp .. "°C -> " .. newTemp .. "°C (+" .. heatIncrease .. ")")
    
    return newTemp
end

-- Enfriar laptop pasivamente
function LaptopThermalSystem.coolDown(laptop, deltaTime)
    if not laptop then return end
    
    local currentTemp = LaptopThermalSystem.getTemperature(laptop)
    if currentTemp <= 20 then return 20 end  -- Ya está a temperatura ambiente
    
    local modData = laptop:getModData()
    local coolingRate = LaptopThermalSystem.COOLING_RATE
    
    -- Enfriar más rápido si está cerrada
    local laptopType = laptop:getType()
    if laptopType and laptopType:find("Closed") then
        coolingRate = LaptopThermalSystem.COOLING_RATE_IDLE
    end
    
    -- Aplicar modificadores
    if modData.GVDrive_HasLiquidCooling then
        coolingRate = coolingRate * 2  -- Enfría 2x más rápido
    end
    
    local tempDecrease = coolingRate * deltaTime
    local newTemp = LaptopThermalSystem.setTemperature(laptop, currentTemp - tempDecrease)
    
    return newTemp
end

-- ============================================================================
-- EFECTOS DE SOBRECALENTAMIENTO
-- ============================================================================

-- Verificar si laptop está sobrecalentada y aplicar efectos
function LaptopThermalSystem.checkOverheat(player, laptop)
    if not laptop then return false end
    
    local temp = LaptopThermalSystem.getTemperature(laptop)
    
    -- No hay problema si está bajo temperatura crítica
    if temp < LaptopThermalSystem.CRITICAL_TEMP then
        return false
    end
    
    print("[ThermalSystem] Laptop at critical temperature: " .. temp .. "°C")
    
    -- CRÍTICA (85-94°C): Advertencias y riesgo de fallo
    if temp >= LaptopThermalSystem.CRITICAL_TEMP and temp < LaptopThermalSystem.OVERHEAT_TEMP then
        if player then
            player:Say("The laptop is running very hot...")
        end
        
        -- 30% chance de fallo forzado en próximo minijuego
        local modData = laptop:getModData()
        if ZombRand(100) < 30 then
            modData.GVDrive_OverheatPenalty = true
            print("[ThermalSystem] Overheat penalty applied - next minigame has increased difficulty")
        end
        
        return true
    end
    
    -- SOBRECALENTAMIENTO (95-100°C): Daño inmediato
    if temp >= LaptopThermalSystem.OVERHEAT_TEMP then
        if player then
            player:Say("CRITICAL OVERHEAT! The laptop is burning up!")
        end
        
        -- Aplicar daño a la laptop
        if LaptopSystem and LaptopSystem.damageLaptop then
            local damage = math.floor((temp - LaptopThermalSystem.OVERHEAT_TEMP) * 2)  -- 0-10 daño
            damage = math.max(5, damage)  -- Mínimo 5% de daño
            
            LaptopSystem.damageLaptop(laptop, damage)
            print("[ThermalSystem] Overheat damage applied: " .. damage .. "%")
            
            -- Forzar enfriamiento de emergencia
            LaptopThermalSystem.setTemperature(laptop, LaptopThermalSystem.CRITICAL_TEMP)
        end
        
        -- Emitir sonido de advertencia si está disponible
        if getSoundManager() and player then
            local square = player:getCurrentSquare()
            if square then
                getSoundManager():PlaySound("alarm", false, 0.3)
            end
        end
        
        return true
    end
    
    return false
end

-- Obtener nivel de temperatura como string
function LaptopThermalSystem.getTemperatureLevel(temp)
    if temp < 40 then
        return "Cool", {r=0.3, g=0.7, b=1, a=1}  -- Azul
    elseif temp < 60 then
        return "Warm", {r=0.3, g=1, b=0.3, a=1}  -- Verde
    elseif temp < LaptopThermalSystem.CRITICAL_TEMP then
        return "Hot", {r=1, g=0.8, b=0.2, a=1}  -- Amarillo
    elseif temp < LaptopThermalSystem.OVERHEAT_TEMP then
        return "CRITICAL", {r=1, g=0.4, b=0, a=1}  -- Naranja
    else
        return "OVERHEAT!", {r=1, g=0.1, b=0.1, a=1}  -- Rojo
    end
end

-- Obtener penalización por sobrecalentamiento
function LaptopThermalSystem.getOverheatPenalty(laptop)
    if not laptop then return 0 end
    
    local temp = LaptopThermalSystem.getTemperature(laptop)
    
    if temp < LaptopThermalSystem.CRITICAL_TEMP then
        return 0
    elseif temp < LaptopThermalSystem.OVERHEAT_TEMP then
        -- Entre 85-95°C: penalización gradual (0-20%)
        local ratio = (temp - LaptopThermalSystem.CRITICAL_TEMP) / 
                      (LaptopThermalSystem.OVERHEAT_TEMP - LaptopThermalSystem.CRITICAL_TEMP)
        return math.floor(ratio * 20)  -- 0-20% de penalización
    else
        -- Más de 95°C: penalización máxima
        return 25  -- 25% de penalización
    end
end

-- Verificar si hay penalización activa de sobrecalentamiento previo
function LaptopThermalSystem.hasOverheatPenalty(laptop)
    if not laptop then return false end
    local modData = laptop:getModData()
    return modData.GVDrive_OverheatPenalty or false
end

-- Limpiar penalización de sobrecalentamiento
function LaptopThermalSystem.clearOverheatPenalty(laptop)
    if not laptop then return end
    local modData = laptop:getModData()
    modData.GVDrive_OverheatPenalty = nil
end

-- ============================================================================
-- SISTEMA DE ENFRIAMIENTO PASIVO (EVENTO)
-- ============================================================================

-- Timer para enfriamiento pasivo (se ejecuta cada segundo)
local lastCoolingUpdate = 0

local function onEveryOneMinute()
    -- Enfriar todas las laptops en inventarios de jugadores
    local players = getOnlinePlayers()
    if not players then return end
    
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player then
            local inventory = player:getInventory()
            if inventory then
                local items = inventory:getItems()
                for j = 0, items:size() - 1 do
                    local item = items:get(j)
                    if item and item:getType() then
                        local itemType = item:getType()
                        if itemType:find("Laptop") then
                            -- Enfriar laptop (1 minuto = 60 segundos)
                            LaptopThermalSystem.coolDown(item, 60)
                        end
                    end
                end
            end
        end
    end
end

-- Registrar evento de enfriamiento
Events.EveryOneMinute.Add(onEveryOneMinute)

-- ============================================================================
-- FUNCIONES DE DEBUG
-- ============================================================================

function ReloadThermalSystem()
    print("[DEBUG] Reloading LaptopThermalSystem...")
    package.loaded["shared/LaptopThermalSystem"] = nil
    local success, result = pcall(require, "shared/LaptopThermalSystem")
    if success then
        print("[DEBUG] LaptopThermalSystem reloaded successfully!")
    else
        print("[DEBUG] Failed to reload: " .. tostring(result))
    end
end

function DiagnoseThermalSystem()
    print("=== THERMAL SYSTEM DIAGNOSTIC ===")
    
    local player = getPlayer()
    if not player then
        print("❌ No player found")
        return
    end
    
    -- Buscar laptop en inventario
    local laptop = nil
    local inventory = player:getInventory()
    if inventory then
        local items = inventory:getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and item:getType() and item:getType():find("Laptop") then
                laptop = item
                break
            end
        end
    end
    
    if laptop then
        local temp = LaptopThermalSystem.getTemperature(laptop)
        local level, color = LaptopThermalSystem.getTemperatureLevel(temp)
        local penalty = LaptopThermalSystem.getOverheatPenalty(laptop)
        
        print("📱 Laptop found: " .. laptop:getType())
        print("🌡️  Temperature: " .. temp .. "°C (" .. level .. ")")
        print("⚠️  Penalty: " .. penalty .. "%")
        print("🔥 Overheat status: " .. (temp >= LaptopThermalSystem.OVERHEAT_TEMP and "YES" or "NO"))
    else
        print("❌ No laptop found in inventory")
    end
    
    print("=== DIAGNOSTIC COMPLETE ===")
end

-- Forzar temperatura para testing
function SetLaptopTemp(temperature)
    local player = getPlayer()
    if not player then
        print("❌ No player found")
        return
    end
    
    local inventory = player:getInventory()
    if inventory then
        local items = inventory:getItems()
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and item:getType() and item:getType():find("Laptop") then
                LaptopThermalSystem.setTemperature(item, temperature)
                print("✅ Laptop temperature set to " .. temperature .. "°C")
                return
            end
        end
    end
    
    print("❌ No laptop found")
end

print("[LaptopThermalSystem] Module loaded successfully")
