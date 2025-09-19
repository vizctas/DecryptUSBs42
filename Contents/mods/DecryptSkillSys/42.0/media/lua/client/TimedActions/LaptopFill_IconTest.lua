-- VERSION ALTERNATIVA PARA PROBAR ICONOS DE BATERÍA
-- Esta es una versión de prueba que intenta diferentes formatos de íconos

-- Función de prueba para iconos de batería
local function getBatteryIcon(laptopHealth, testMode)
    local batteryIcon = ""
    
    if testMode == 1 then
        -- Método 1: Ruta relativa con <IMAGE:>
        if laptopHealth >= 80 then
            batteryIcon = " <IMAGE:media/textures/ui/battery/background-4.png> "
        elseif laptopHealth >= 60 then
            batteryIcon = " <IMAGE:media/textures/ui/battery/background-3.png> "
        elseif laptopHealth >= 40 then
            batteryIcon = " <IMAGE:media/textures/ui/battery/background-2.png> "
        elseif laptopHealth >= 20 then
            batteryIcon = " <IMAGE:media/textures/ui/battery/background-1.png> "
        else
            batteryIcon = " <IMAGE:media/textures/ui/battery/background-0.png> "
        end
        
    elseif testMode == 2 then
        -- Método 2: Ruta absoluta con <IMAGE:>
        if laptopHealth >= 80 then
            batteryIcon = " <IMAGE:ui/battery/background-4.png> "
        elseif laptopHealth >= 60 then
            batteryIcon = " <IMAGE:ui/battery/background-3.png> "
        elseif laptopHealth >= 40 then
            batteryIcon = " <IMAGE:ui/battery/background-2.png> "
        elseif laptopHealth >= 20 then
            batteryIcon = " <IMAGE:ui/battery/background-1.png> "
        else
            batteryIcon = " <IMAGE:ui/battery/background-0.png> "
        end
        
    elseif testMode == 3 then
        -- Método 3: Sin prefijo de carpeta
        if laptopHealth >= 80 then
            batteryIcon = " <IMAGE:background-4.png> "
        elseif laptopHealth >= 60 then
            batteryIcon = " <IMAGE:background-3.png> "
        elseif laptopHealth >= 40 then
            batteryIcon = " <IMAGE:background-2.png> "
        elseif laptopHealth >= 20 then
            batteryIcon = " <IMAGE:background-1.png> "
        else
            batteryIcon = " <IMAGE:background-0.png> "
        end
        
    else
        -- Método 4: Fallback con texto ASCII mejorado
        if laptopHealth >= 80 then
            batteryIcon = " [████] "  -- Full battery
        elseif laptopHealth >= 60 then
            batteryIcon = " [███▒] "  -- 3/4 battery
        elseif laptopHealth >= 40 then
            batteryIcon = " [██▒▒] "  -- Half battery
        elseif laptopHealth >= 20 then
            batteryIcon = " [█▒▒▒] "  -- Low battery
        else
            batteryIcon = " [▒▒▒▒] "  -- Dead battery
        end
    end
    
    return batteryIcon
end

-- INSTRUCCIONES PARA PROBAR:
-- 1. Reemplaza la función getBatteryIcon en LaptopFill.lua
-- 2. Llama getBatteryIcon(laptopHealth, 1) para probar el método 1
-- 3. Si no funciona, prueba con testMode = 2, 3, o 4
-- 4. El método 4 usa caracteres Unicode como fallback

pcall(require, "shared/GVDrive_Config")
local function debugPrint(...)
    if type(GVDrive_Config) == 'table' and GVDrive_Config.getDebug and GVDrive_Config.getDebug() then
        print("[DecryptSkillSys][DEBUG]", ...)
    end
end

debugPrint("Icon test helper loaded")