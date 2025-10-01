-- ContextualMessages.lua - Sistema de Mensajes Contextuales Dinámicos
-- Mensajes que reaccionan a la situación del jugador durante minijuegos

ContextualMessages = ContextualMessages or {}

-- ============================================================================
-- CONFIGURACIÓN
-- ============================================================================

-- Cache de última situación para evitar mensajes repetidos
ContextualMessages.lastContext = {
    type = nil,
    timestamp = 0
}

-- Cooldown entre mensajes (en ticks, 60 = 1 segundo)
ContextualMessages.MESSAGE_COOLDOWN = 120  -- 2 segundos

-- ============================================================================
-- ANÁLISIS DE CONTEXTO
-- ============================================================================

-- Analizar situación del jugador
function ContextualMessages.analyzeContext(player, laptop)
    if not player then return {} end
    
    local context = {
        lowLaptopHealth = false,
        highLaptopHealth = false,
        zombiesNear = false,
        stressed = false,
        injured = false,
        lowHealth = false,
        night = false,
        inSafehouse = false,
        hasFailures = false,
        highTemperature = false
    }
    
    -- Verificar salud de laptop
    if laptop and LaptopSystem then
        local laptopHealth = LaptopSystem.getLaptopHealth(laptop)
        if laptopHealth <= 15 then
            context.lowLaptopHealth = true
            context.laptopHealth = laptopHealth
        elseif laptopHealth >= 90 then
            context.highLaptopHealth = true
        end
        
        -- Verificar fallos acumulados
        if LaptopSystem.getFailureCount then
            local failures = LaptopSystem.getFailureCount(laptop)
            if failures >= 3 then
                context.hasFailures = true
                context.failureCount = failures
            end
        end
        
        -- Verificar temperatura
        if LaptopThermalSystem and LaptopThermalSystem.getTemperature then
            local temp = LaptopThermalSystem.getTemperature(laptop)
            if temp >= 85 then
                context.highTemperature = true
                context.temperature = temp
            end
        end
    end
    
    -- Verificar zombies cercanos
    local square = player:getCurrentSquare()
    if square then
        local zombies = 0
        local x = square:getX()
        local y = square:getY()
        local z = square:getZ()
        
        for dx = -10, 10 do
            for dy = -10, 10 do
                local checkSquare = getCell():getGridSquare(x + dx, y + dy, z)
                if checkSquare then
                    local zombiesInSquare = checkSquare:getMovingObjects()
                    if zombiesInSquare then
                        for i = 0, zombiesInSquare:size() - 1 do
                            local zombie = zombiesInSquare:get(i)
                            if zombie and zombie:isZombie() then
                                zombies = zombies + 1
                            end
                        end
                    end
                end
            end
        end
        
        if zombies > 0 then
            context.zombiesNear = true
            context.zombieCount = zombies
        end
    end
    
    -- Verificar estado del jugador
    local bodyDamage = player:getBodyDamage()
    if bodyDamage then
        if bodyDamage:getStressLevel() > 50 then
            context.stressed = true
        end
        
        if bodyDamage:getOverallBodyHealth() < 50 then
            context.injured = true
        end
        
        if bodyDamage:getOverallBodyHealth() < 30 then
            context.lowHealth = true
        end
    end
    
    -- Verificar hora del día
    local gameTime = getGameTime()
    if gameTime then
        local hour = gameTime:getHour()
        if hour >= 21 or hour <= 5 then
            context.night = true
        end
    end
    
    -- Verificar si está en safehouse
    if square and SafeHouse then
        local safehouse = SafeHouse.getSafeHouse(square)
        if safehouse then
            context.inSafehouse = true
        end
    end
    
    return context
end

-- ============================================================================
-- MENSAJES CONTEXTUALES
-- ============================================================================

-- Mensajes para diferentes situaciones
ContextualMessages.MESSAGES = {
    -- INICIO DE MINIJUEGO
    start_normal = {
        "Let's do this.",
        "Time to decrypt...",
        "Focus...",
        "Here we go.",
    },
    start_zombiesNear = {
        "Quick, before they notice...",
        "Gotta make this fast!",
        "No time to waste!",
        "Come on, come on...",
    },
    start_lowLaptop = {
        "Please don't die on me...",
        "This laptop won't last much longer...",
        "One more time, old friend...",
        "Careful... very careful...",
    },
    start_night = {
        "Working in the dark...",
        "At least they can't see the screen...",
        "Night shift again...",
    },
    start_highTemp = {
        "It's already hot...",
        "This thing is burning up...",
        "Need to be quick before it overheats...",
    },
    
    -- ÉXITO
    success_normal = {
        "Done!",
        "Success!",
        "Got it!",
        "Yes!",
    },
    success_zombiesNear = {
        "Done! Now RUN!",
        "Got it! Move, MOVE!",
        "Finally! Get out of here!",
        "Success! Time to go!",
    },
    success_clutch = {
        "That was close... too close.",
        "By the skin of my teeth...",
        "I can't believe that worked!",
        "Never doing that again...",
    },
    success_streak = {
        "Another one!",
        "I'm getting good at this!",
        "On a roll!",
        "This is easy!",
    },
    success_highTemp = {
        "Done! Let it cool down...",
        "Made it before it fried!",
        "That was cutting it close!",
    },
    
    -- FALLO
    failure_normal = {
        "Damn it!",
        "No, no, no...",
        "I messed up...",
        "Not again...",
    },
    failure_lowLaptop = {
        "No... NO! Not like this!",
        "Please still work...",
        "Oh god, what did I do...",
        "This was a mistake...",
    },
    failure_zombiesNear = {
        "Shit! They're coming!",
        "No time for this!",
        "I need to move NOW!",
        "Forget it, gotta run!",
    },
    failure_critical = {
        "CRITICAL FAILURE!",
        "Everything's falling apart!",
        "This is bad... really bad...",
        "How did this go so wrong?!",
    },
    failure_repeated = {
        "Again?! Seriously?!",
        "I'm losing my touch...",
        "Maybe I should stop...",
        "This isn't my day...",
    },
    
    -- EVENTOS ESPECIALES
    overheat_warning = {
        "It's getting HOT!",
        "Temperature critical!",
        "This thing is gonna melt!",
        "Too hot! Too hot!",
    },
    malware_detected = {
        "Wait... something's wrong...",
        "This file is corrupted!",
        "MALWARE! MALWARE!",
        "Oh no, it's infected!",
    },
    surprise_found = {
        "Wait, there's more here...",
        "What's this?!",
        "Hidden data found!",
        "Jackpot!",
    },
}

-- ============================================================================
-- SELECCIÓN Y ENVÍO DE MENSAJES
-- ============================================================================

-- Seleccionar mensaje apropiado según contexto
function ContextualMessages.selectMessage(situation, context)
    local messageKey = situation
    
    -- Modificar clave según contexto (priorizar situaciones críticas)
    if situation == "start" then
        if context.highTemperature then
            messageKey = "start_highTemp"
        elseif context.lowLaptopHealth then
            messageKey = "start_lowLaptop"
        elseif context.zombiesNear then
            messageKey = "start_zombiesNear"
        elseif context.night then
            messageKey = "start_night"
        else
            messageKey = "start_normal"
        end
    elseif situation == "success" then
        if context.zombiesNear then
            messageKey = "success_zombiesNear"
        elseif context.lowLaptopHealth and context.laptopHealth <= 5 then
            messageKey = "success_clutch"
        elseif context.highTemperature then
            messageKey = "success_highTemp"
        else
            messageKey = "success_normal"
        end
    elseif situation == "failure" then
        if context.lowLaptopHealth then
            messageKey = "failure_lowLaptop"
        elseif context.zombiesNear then
            messageKey = "failure_zombiesNear"
        elseif context.hasFailures and context.failureCount >= 5 then
            messageKey = "failure_critical"
        else
            messageKey = "failure_normal"
        end
    end
    
    -- Obtener lista de mensajes
    local messages = ContextualMessages.MESSAGES[messageKey]
    if not messages or #messages == 0 then
        return nil
    end
    
    -- Seleccionar mensaje aleatorio
    local index = ZombRand(#messages) + 1
    return messages[index]
end

-- Verificar cooldown de mensajes
function ContextualMessages.canSendMessage()
    local currentTick = getTimestamp()
    local timeSinceLastMessage = currentTick - ContextualMessages.lastContext.timestamp
    
    return timeSinceLastMessage >= ContextualMessages.MESSAGE_COOLDOWN
end

-- Enviar mensaje al jugador
function ContextualMessages.sendMessage(player, situation, context)
    if not player then return false end
    
    -- Verificar cooldown
    if not ContextualMessages.canSendMessage() then
        return false
    end
    
    -- Seleccionar mensaje
    local message = ContextualMessages.selectMessage(situation, context)
    if not message then return false end
    
    -- Enviar mensaje
    player:Say(message)
    
    -- Actualizar timestamp
    ContextualMessages.lastContext.timestamp = getTimestamp()
    ContextualMessages.lastContext.type = situation
    
    print("[ContextualMessages] Sent: " .. message .. " (situation: " .. situation .. ")")
    
    return true
end

-- ============================================================================
-- FUNCIONES PRINCIPALES (API)
-- ============================================================================

-- Mensaje al iniciar minijuego
function ContextualMessages.onMinigameStart(player, laptop)
    local context = ContextualMessages.analyzeContext(player, laptop)
    return ContextualMessages.sendMessage(player, "start", context)
end

-- Mensaje al completar minijuego con éxito
function ContextualMessages.onMinigameSuccess(player, laptop)
    local context = ContextualMessages.analyzeContext(player, laptop)
    return ContextualMessages.sendMessage(player, "success", context)
end

-- Mensaje al fallar minijuego
function ContextualMessages.onMinigameFailure(player, laptop)
    local context = ContextualMessages.analyzeContext(player, laptop)
    return ContextualMessages.sendMessage(player, "failure", context)
end

-- Mensaje especial (sobrecalentamiento, malware, sorpresa)
function ContextualMessages.onSpecialEvent(player, laptop, eventType)
    if not player then return false end
    
    -- Verificar cooldown
    if not ContextualMessages.canSendMessage() then
        return false
    end
    
    local messages = ContextualMessages.MESSAGES[eventType]
    if not messages or #messages == 0 then
        return false
    end
    
    local index = ZombRand(#messages) + 1
    local message = messages[index]
    
    player:Say(message)
    
    ContextualMessages.lastContext.timestamp = getTimestamp()
    ContextualMessages.lastContext.type = eventType
    
    print("[ContextualMessages] Special event: " .. message .. " (" .. eventType .. ")")
    
    return true
end

-- ============================================================================
-- FUNCIONES DE DEBUG
-- ============================================================================

function ReloadContextualMessages()
    print("[DEBUG] Reloading ContextualMessages...")
    package.loaded["shared/ContextualMessages"] = nil
    local success, result = pcall(require, "shared/ContextualMessages")
    if success then
        print("[DEBUG] ContextualMessages reloaded successfully!")
    else
        print("[DEBUG] Failed to reload: " .. tostring(result))
    end
end

function TestContextMessage(situation)
    local player = getPlayer()
    if not player then
        print("❌ No player found")
        return
    end
    
    local inventory = player:getInventory()
    local laptop = nil
    
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
    
    print("🗣️ Testing contextual message: " .. (situation or "start"))
    
    if situation == "start" then
        ContextualMessages.onMinigameStart(player, laptop)
    elseif situation == "success" then
        ContextualMessages.onMinigameSuccess(player, laptop)
    elseif situation == "failure" then
        ContextualMessages.onMinigameFailure(player, laptop)
    elseif situation == "overheat" then
        ContextualMessages.onSpecialEvent(player, laptop, "overheat_warning")
    elseif situation == "malware" then
        ContextualMessages.onSpecialEvent(player, laptop, "malware_detected")
    elseif situation == "surprise" then
        ContextualMessages.onSpecialEvent(player, laptop, "surprise_found")
    else
        ContextualMessages.onMinigameStart(player, laptop)
    end
end

print("[ContextualMessages] Module loaded successfully")
