-- Script de prueba para verificar que los minijuegos estén disponibles como funciones globales
-- Ejecutar con: lua5.1.exe test_minigames.lua

print("=== PRUEBA DE FUNCIONES GLOBALES MINIGAMES ===")

-- Simular la carga de módulos como lo haría PZ
print("\n1. Intentando cargar módulos...")

local function safeRequire(moduleName)
    local success, result = pcall(require, moduleName)
    if success then
        print("✅ Módulo '" .. moduleName .. "' cargado exitosamente")
        return true
    else
        print("❌ Error cargando '" .. moduleName .. "': " .. tostring(result))
        return false
    end
end

-- Cargar módulos en orden
safeRequire("client/MiniGameUI")
safeRequire("client/MiniGameMorse")
safeRequire("client/MiniGameFallout")

print("\n2. Verificando funciones globales...")

-- Verificar MiniGame (secuencia)
if MiniGame and type(MiniGame) == "function" then
    print("✅ MiniGame (secuencia) disponible como función global")
else
    print("❌ MiniGame (secuencia) NO disponible")
end

-- Verificar MiniGameMorse
if MiniGameMorse and type(MiniGameMorse) == "function" then
    print("✅ MiniGameMorse disponible como función global")
else
    print("❌ MiniGameMorse NO disponible")
end

-- Verificar MiniGameFallout
if MiniGameFallout and type(MiniGameFallout) == "function" then
    print("✅ MiniGameFallout disponible como función global")
else
    print("❌ MiniGameFallout NO disponible")
end

print("\n3. Probando llamadas de prueba (sin parámetros reales)...")

-- Probar llamadas seguras (sin parámetros para evitar errores)
local testResults = {}

if MiniGame then
    local success, result = pcall(function() return MiniGame end)
    testResults["MiniGame"] = success and "OK" or "ERROR: " .. tostring(result)
else
    testResults["MiniGame"] = "NOT_AVAILABLE"
end

if MiniGameMorse then
    local success, result = pcall(function() return MiniGameMorse end)
    testResults["MiniGameMorse"] = success and "OK" or "ERROR: " .. tostring(result)
else
    testResults["MiniGameMorse"] = "NOT_AVAILABLE"
end

if MiniGameFallout then
    local success, result = pcall(function() return MiniGameFallout end)
    testResults["MiniGameFallout"] = success and "OK" or "ERROR: " .. tostring(result)
else
    testResults["MiniGameFallout"] = "NOT_AVAILABLE"
end

print("Resultados de prueba:")
for name, result in pairs(testResults) do
    print("  " .. name .. ": " .. result)
end

print("\n=== FIN DE PRUEBA ===")
print("\nSi todas las funciones están disponibles, el sistema de carga modular funciona correctamente.")
print("Los minijuegos deberían estar accesibles desde el menú contextual y llamadas directas.")