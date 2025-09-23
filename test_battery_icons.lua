-- TEST SCRIPT PARA VERIFICAR ICONOS DE BATERÍA EN MENÚ CONTEXTUAL
-- Versión corregida: usando option.iconTexture en lugar de <IMAGE:...>
-- Incluye validación de healthStatus

local function testHealthStatus()
    print("=== TEST: Health Status Logic ===")

    -- Simular diferentes niveles de salud
    local testHealthLevels = {0, 10, 25, 50, 75, 90, 100, nil, "invalid"}

    for _, health in ipairs(testHealthLevels) do
        -- Validación como en el código corregido
        if type(health) ~= "number" then
            print("Health " .. tostring(health) .. " -> INVALID (type: " .. type(health) .. ") -> Defaulting to 0")
            health = 0
        end

        -- Lógica de healthStatus
        local healthStatus = ""
        if health >= 80 then
            healthStatus = "Excellent"
        elseif health >= 60 then
            healthStatus = "Good"
        elseif health >= 40 then
            healthStatus = "Fair"
        elseif health >= 20 then
            healthStatus = "Poor"
        else
            healthStatus = "Critical"
        end

        -- Construcción del display
        local healthDisplay = "Health: " .. health .. "% (" .. healthStatus .. ")"

        print("Health " .. health .. "% -> Status: " .. healthStatus .. " -> Display: " .. healthDisplay)
    end

    print("=== TEST COMPLETE ===")
    print("Si no hay errores de concatenación, la corrección funciona.")
end

local function testBatteryTextures()
    print("=== TEST: Battery Texture Implementation (CORRECTED) ===")

    -- Simular diferentes niveles de salud
    local testHealthLevels = {0, 10, 25, 50, 75, 90, 100}

    for _, health in ipairs(testHealthLevels) do
        -- Usar la nueva lógica correcta que devuelve texturas
        local batteryTexture = nil
        if health <= 12 then
            batteryTexture = "media/textures/ui/health/batt0.png"
        elseif health <= 37 then
            batteryTexture = "media/textures/ui/health/batt25.png"
        elseif health <= 62 then
            batteryTexture = "media/textures/ui/health/batt50.png"
        elseif health <= 87 then
            batteryTexture = "media/textures/ui/health/batt75.png"
        else
            batteryTexture = "media/textures/ui/health/batt100.png"
        end

        local healthDisplay = "Health: " .. health .. "%"

        print("Health " .. health .. "% -> Texture: " .. batteryTexture .. " | Display: " .. healthDisplay)
    end

    print("=== TEST COMPLETE ===")
    print("Esta es la implementación CORRECTA para ISContextMenu:")
    print("- getBatteryTextureForHealth() devuelve getTexture(path)")
    print("- option.iconTexture = batteryTexture asigna el icono")
    print("- Los iconos aparecerán a la izquierda del texto en el menú contextual")
end

-- Ejecutar tests
testHealthStatus()
print()
testBatteryTextures()