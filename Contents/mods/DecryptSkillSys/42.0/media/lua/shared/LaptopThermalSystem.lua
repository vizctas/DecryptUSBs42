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

-- Velocidad de enfriamiento natural (°C por minuto in-game)
-- Objetivo: 20°C en 30 minutos = 0.667°C por minuto
-- ⚠️ NOTA: Sistema de cerrar/abrir laptop DESHABILITADO (buggy)
LaptopThermalSystem.COOLING_RATE_PER_MINUTE = 0.667  -- Tasa única para todas las laptops

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
    
    -- ✨ BONUS: Pasta térmica reduce calentamiento en 50%
    if LaptopThermalSystem.hasThermalPasteBonus(laptop) then
        heatIncrease = heatIncrease * 0.5
        print("[ThermalSystem] Thermal paste bonus active - heat reduced by 50%")
    end
    
    local newTemp = LaptopThermalSystem.setTemperature(laptop, currentTemp + heatIncrease)
    
    print("[ThermalSystem] Laptop heated: " .. currentTemp .. "°C -> " .. newTemp .. "°C (+" .. heatIncrease .. ")")
    
    return newTemp
end

-- Enfriar laptop pasivamente (deltaTime en MINUTOS in-game)
function LaptopThermalSystem.coolDown(laptop, deltaTime)
    if not laptop then return end
    
    local currentTemp = LaptopThermalSystem.getTemperature(laptop)
    if currentTemp <= 20 then return 20 end  -- Ya está a temperatura ambiente
    
    local modData = laptop:getModData()
    local coolingRate = LaptopThermalSystem.COOLING_RATE_PER_MINUTE
    
    -- ⚠️ SISTEMA DE CERRAR/ABRIR LAPTOP DESHABILITADO (buggy)
    -- Todas las laptops enfrían a la misma velocidad independientemente del estado
    
    -- Aplicar modificadores
    if modData.GVDrive_HasLiquidCooling then
        coolingRate = coolingRate * 2  -- Enfría 2x más rápido
    end
    
    -- deltaTime debe ser en MINUTOS in-game para que funcione correctamente
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
        
        -- Emitir sonido de advertencia que ATRAE ZOMBIES
        if getSoundManager() and player then
            local square = player:getCurrentSquare()
            if square then
                -- PlayWorldSound para que los zombies lo escuchen y sean atraídos
                getSoundManager():PlayWorldSound("alarm", square, 0, 80, 60, true)
                print("[ThermalSystem] Overheat alarm triggered - zombies attracted!")
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

-- ============================================================================
-- SISTEMA DE PASTA TÉRMICA
-- ============================================================================

-- Aplicar pasta térmica a la laptop (enfriamiento instantáneo)
function LaptopThermalSystem.applyThermalPaste(laptop)
    if not laptop then return false end
    
    local currentTemp = LaptopThermalSystem.getTemperature(laptop)
    
    -- Enfriar laptop a temperatura ambiente (20°C) + bonus de enfriamiento temporal
    LaptopThermalSystem.setTemperature(laptop, 20)
    
    -- Aplicar bonus de enfriamiento mejorado temporal (30 minutos de juego)
    local modData = laptop:getModData()
    modData.GVDrive_ThermalPasteActive = true
    modData.GVDrive_ThermalPasteExpiry = os.time() + (30 * 60)  -- 30 minutos reales
    
    print("[ThermalSystem] Thermal paste applied: " .. currentTemp .. "°C -> 20°C (bonus active for 30 minutes)")
    
    return true
end

-- Verificar si tiene bonus de pasta térmica activo
function LaptopThermalSystem.hasThermalPasteBonus(laptop)
    if not laptop then return false end
    
    local modData = laptop:getModData()
    if not modData.GVDrive_ThermalPasteActive then
        return false
    end
    
    -- Verificar si expiró
    local currentTime = os.time()
    if currentTime >= (modData.GVDrive_ThermalPasteExpiry or 0) then
        -- Expiró, limpiar
        modData.GVDrive_ThermalPasteActive = nil
        modData.GVDrive_ThermalPasteExpiry = nil
        return false
    end
    
    return true
end

-- Obtener tiempo restante de bonus (en minutos)
function LaptopThermalSystem.getThermalPasteBonusRemaining(laptop)
    if not laptop or not LaptopThermalSystem.hasThermalPasteBonus(laptop) then
        return 0
    end
    
    local modData = laptop:getModData()
    local currentTime = os.time()
    local remaining = (modData.GVDrive_ThermalPasteExpiry or 0) - currentTime
    
    return math.max(0, math.floor(remaining / 60))  -- Convertir a minutos
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

-- ============================================================================
-- SISTEMA DE ENFRIAMIENTO AUTOMÁTICO (Cada 10 minutos in-game)
-- ============================================================================

-- Enfriar todas las laptops del jugador pasivamente cada 10 minutos
local function onEveryTenMinutes()
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
                    if item and item:getType() and item:getType():find("Laptop") then
                        -- Enfriar 10 minutos (deltaTime = 10)
                        local oldTemp = LaptopThermalSystem.getTemperature(item)
                        local newTemp = LaptopThermalSystem.coolDown(item, 10)
                        
                        if oldTemp ~= newTemp then
                            print("[ThermalSystem] Laptop cooled: " .. oldTemp .. "°C -> " .. newTemp .. "°C")
                        end
                    end
                end
            end
        end
    end
end

-- Registrar evento de enfriamiento
if Events and Events.EveryTenMinutes then
    Events.EveryTenMinutes.Add(onEveryTenMinutes)
    print("[ThermalSystem] Auto-cooling system registered (every 10 minutes)")
end

print("[LaptopThermalSystem] Module loaded successfully")
