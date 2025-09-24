-- ✅ MINIJUEGO MORSE CODE - Sistema de decodificación Morse para DecryptSkillSys
-- MiniGameMorse.lua - Minijuego independiente de decodificación Morse
-- Basado en patrones del CODEBASE y MiniGameUI.lua

print("[DecryptSkillSys] Loading MiniGameMorse.lua - Morse Code minigame system")

-- ✅ FUNCIÓN DE RECARGA PARA DEBUG
function ReloadMiniGameMorse()
    print("[DEBUG] Reloading Morse minigame system...")
    if MiniGameMorse then
        MiniGameMorse = nil
        print("[DEBUG] Previous MiniGameMorse function cleared")
    end
    package.loaded["client/MiniGameMorse"] = nil
    local success, result = pcall(require, "client/MiniGameMorse")
    if success then
        print("[DEBUG] Morse minigame reloaded successfully!")
    else
        print("[DEBUG] Failed to reload Morse: " .. tostring(result))
    end
end

-- ✅ FUNCIÓN DE PRUEBA RÁPIDA PARA DEBUG
function TestMiniGameMorse(widthPct, heightPct)
    widthPct = widthPct or 25
    heightPct = heightPct or 35
    print("[DEBUG] Testing Morse minigame with size: " .. widthPct .. "% x " .. heightPct .. "%")
    if MiniGameMorse then
        return MiniGameMorse(widthPct, heightPct, "TestSkill", "Easy", nil, {skill="TestSkill", difficulty_english="Easy", displayName="Test USB"})
    else
        print("[DEBUG] MiniGameMorse function not available. Try ReloadMiniGameMorse() first.")
    end
end

-- ========== CONFIGURACIÓN DEL MINIJUEGO MORSE ==========
local TIME_LIMIT = 120     -- Tiempo límite en segundos (configurable)
local MESSAGE_LENGTH = 5   -- Longitud del mensaje Morse (configurable)
local DIFFICULTY_TEXT = "DIFFICULTY: MORSE BASIC" -- Texto configurable
-- =============================================

-- Tabla Morse simplificada
local MORSE_CODE = {
    A = ".-", B = "-...", C = "-.-.", D = "-..", E = ".", F = "..-.",
    G = "--.", H = "....", I = "..", J = ".---", K = "-.-", L = ".-..",
    M = "--", N = "-.", O = "---", P = ".--.", Q = "--.-", R = ".-.",
    S = "...", T = "-", U = "..-", V = "...-", W = ".--", X = "-..-",
    Y = "-.--", Z = "--..",
    ["0"] = "-----", ["1"] = ".----", ["2"] = "..---", ["3"] = "...--",
    ["4"] = "....-", ["5"] = ".....", ["6"] = "-....", ["7"] = "--...",
    ["8"] = "---..", ["9"] = "----."
}

-- Función para decodificar Morse
local function decodeMorse(morse)
    for letter, code in pairs(MORSE_CODE) do
        if code == morse then
            return letter
        end
    end
    return "?"
end

-- Función para generar mensaje Morse aleatorio
local function generateMorseMessage(length)
    local letters = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","0","1","2","3","4","5","6","7","8","9"}
    local message = ""
    local morseSequence = ""
    
    for i = 1, length do
        local letter = letters[ZombRand(1, #letters + 1)]
        message = message .. letter
        morseSequence = morseSequence .. MORSE_CODE[letter] .. " "
    end
    
    return message, morseSequence
end

-- SISTEMA DE TIMERS ULTRA SIMPLE (copiado de MiniGameUI.lua)
local SimpleTimer = {}
SimpleTimer.activeTimers = {}

SimpleTimer.nextId = 1

function SimpleTimer:addTimer(duration, callback)
    local id = self.nextId
    self.nextId = self.nextId + 1
    
    self.activeTimers[id] = {
        callback = callback,
        duration = duration,
        elapsed = 0
    }
    
    return id
end

function SimpleTimer:removeTimer(id)
    self.activeTimers[id] = nil
end

function SimpleTimer:update()
    local toRemove = {}
    
    for id, timer in pairs(self.activeTimers) do
        timer.elapsed = timer.elapsed + 1
        if timer.elapsed >= timer.duration then
            if timer.callback and type(timer.callback) == 'function' then
                local success, err = pcall(timer.callback)
                if not success then
                    print("SimpleTimer: Callback error:", err)
                end
            end
            toRemove[id] = true
        end
    end
    
    for id in pairs(toRemove) do
        self.activeTimers[id] = nil
    end
end

-- Registrar el sistema de timers ultra simple (solo si Events existe)
if Events and Events.OnTick and Events.OnTick.Add then
    Events.OnTick.Add(function() SimpleTimer:update() end)
else
    print("[MiniGameMorse] Events not available - timers will not be registered (expected in test environment)")
end

local MiniGameMorseWindow = ISPanel:derive("MiniGameMorseWindow")

function MiniGameMorseWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    -- ✅ PROPIEDADES ESTÉTICA ALIEN CRT (copiado de MiniGameUI.lua)
    o.player = player
    o.backgroundColor = {r=0.05, g=0.2, b=0.05, a=0.9}
    o.borderColor = {r=0.2, g=1, b=0.2, a=1}
    o.moveWithMouse = true
    
    -- ✅ INTEGRACIÓN USB (copiado de MiniGameUI.lua)
    o.usbType = usbType
    o.difficulty = difficulty  
    o.laptopItem = laptopItem
    o.usbData = usbData
    
    -- ✅ ESTADO DEL JUEGO MORSE
    o.correctMessage = ""
    o.morseSequence = ""
    o.userInput = ""
    o.timeRemaining = TIME_LIMIT
    o.gameActive = false
    
    -- ✅ CONFIGURACIÓN AUTOMÁTICA SEGÚN USB
    o:configureFromUSB()
    
    return o
end

function MiniGameMorseWindow:configureFromUSB()
    if not self.usbType or not self.difficulty then
        print("MorseGame: No USB parameters provided, using default configuration")
        return
    end

    local config = self:getDifficultyConfig(self.difficulty)
    TIME_LIMIT = config.timeLimit
    MESSAGE_LENGTH = config.messageLength
    DIFFICULTY_TEXT = config.displayText

    print(string.format("MorseGame: Configured for USB %s - Difficulty: %s - Time: %ds, Length: %d",
        self.usbType, self.difficulty, config.timeLimit, config.messageLength))
end

function MiniGameMorseWindow:getDifficultyConfig(difficulty)
    local configs = {
        ["Easy"] = {
            timeLimit = 180,      -- 3 minutos
            messageLength = 4,    -- 4 caracteres
            displayText = "DIFFICULTY: MORSE EASY"
        },
        ["Moderate"] = {
            timeLimit = 120,      -- 2 minutos
            messageLength = 5,    -- 5 caracteres
            displayText = "DIFFICULTY: MORSE MODERATE"
        },
        ["Expert"] = {
            timeLimit = 90,       -- 1.5 minutos
            messageLength = 6,    -- 6 caracteres
            displayText = "DIFFICULTY: MORSE EXPERT"
        }
    }
    
    -- Retornar configuración específica o fallback a Easy
    return configs[difficulty] or configs["Easy"]
end

function MiniGameMorseWindow:createChildren()
    -- ✅ BOTÓN DE CIERRE
    self.closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    -- ✅ CAMPO DE TEXTO PARA INPUT DEL USUARIO
    self.inputField = ISTextEntryBox:new("", 20, 120, self.width - 40, 30)
    self.inputField:initialise()
    self.inputField:instantiate()
    self.inputField:setMaxTextLength(20)
    self.inputField:setOnlyNumbers(false)
    self:addChild(self.inputField)

    -- ✅ BOTÓN SUBMIT
    self.submitButton = ISButton:new((self.width - 100) / 2, 160, 100, 30, "DECODE", self, self.onSubmit)
    self.submitButton:initialise()
    self:addChild(self.submitButton)

    -- ✅ BOTÓN START
    self.startButton = ISButton:new(20, 200, 100, 30, "START", self, self.onStart)
    self.startButton:initialise()
    self:addChild(self.startButton)

    -- ✅ BOTÓN RESET
    self.resetButton = ISButton:new(self.width - 120, 200, 100, 30, "RESET", self, self.onReset)
    self.resetButton:initialise()
    self:addChild(self.resetButton)
end

function MiniGameMorseWindow:onStart()
    self:clearAllTimers()
    
    -- Generar nuevo mensaje Morse
    self.correctMessage, self.morseSequence = generateMorseMessage(MESSAGE_LENGTH)
    self.userInput = ""
    self.timeRemaining = TIME_LIMIT
    self.gameActive = true
    
    -- Limpiar input field
    if self.inputField then
        self.inputField:setText("")
    end
    
    -- Iniciar timer
    self:startTimer()
    
    if self.player then
        self.player:Say("Decode the Morse sequence!")
    end
end

function MiniGameMorseWindow:startTimer()
    self.timerId = SimpleTimer:addTimer(60, function()  -- Cada segundo
        self.timeRemaining = self.timeRemaining - 1
        if self.timeRemaining <= 0 then
            self:onTimeUp()
        else
            self:startTimer()  -- Continuar timer
        end
    end)
end

function MiniGameMorseWindow:onTimeUp()
    self.gameActive = false
    self:clearAllTimers()
    
    -- Mostrar resultado de fracaso
    self:showResult(false, "TIME UP")
    
    -- Aplicar daño por fracaso
    self:applyResult(false)
end

function MiniGameMorseWindow:onSubmit()
    if not self.gameActive then return end
    
    local userText = string.upper(self.inputField:getText() or "")
    self.userInput = userText
    
    -- Verificar si es correcto
    local success = (userText == self.correctMessage)
    
    self.gameActive = false
    self:clearAllTimers()
    
    self:showResult(success, success and "DECODED" or "ERROR")
    self:applyResult(success)
end

function MiniGameMorseWindow:showResult(success, message)
    -- Mostrar resultado en el campo de input
    if self.inputField then
        self.inputField:setText(message)
    end
    
    -- Cerrar después de tiempo
    SimpleTimer:addTimer(120, function()  -- 6 segundos
        self:onClose()
    end)
end

function MiniGameMorseWindow:applyResult(success)
    -- ✅ CONSUMIR USB DEL INVENTARIO
    if self.usbData and self.usbData.item then
        local inventory = self.player:getInventory()
        if inventory:contains(self.usbData.item) then
            inventory:Remove(self.usbData.item)
            print("[SUCCESS] USB consumed from inventory: " .. tostring(self.usbData.displayName))
        end
    end
    
    -- ✅ INTEGRACIÓN USB: Aplicar resultado
    if self.usbType and self.difficulty and self.laptopItem then
        if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
            local result = GVDrive_Utils.applyMinigameResult(self.player, self.laptopItem, self.usbType, self.difficulty, success)
            if success then
                self.player:Say("Morse decoded! Experience gained!")
            else
                self.player:Say("Failed to decode Morse. Laptop damaged!")
            end
        else
            print("[ERROR] GVDrive_Utils not available")
            self.player:Say(success and "Decoded successfully!" or "Decoding failed.")
        end
    end
end

function MiniGameMorseWindow:onReset()
    self:clearAllTimers()
    self.correctMessage = ""
    self.morseSequence = ""
    self.userInput = ""
    self.timeRemaining = TIME_LIMIT
    self.gameActive = false
    
    if self.inputField then
        self.inputField:setText("")
    end
    
    if self.player then
        self.player:Say("Morse game reset")
    end
end

function MiniGameMorseWindow:clearAllTimers()
    if self.timerId then
        SimpleTimer:removeTimer(self.timerId)
        self.timerId = nil
    end
end

function MiniGameMorseWindow:onClose()
    self:clearAllTimers()
    self:setVisible(false)
    self:removeFromUIManager()
end

-- Función global para abrir la ventana Morse
function MiniGameMorse(widthPct, heightPct, usbType, difficulty, laptopItem, usbData)
    local player = getPlayer()
    if not player then 
        print("MiniGameMorse: No player found")
        return 
    end

    widthPct = tonumber(widthPct) or 25
    heightPct = tonumber(heightPct) or 35

    if type(widthPct) ~= 'number' or widthPct < 10 or widthPct > 100 then widthPct = 25 end
    if type(heightPct) ~= 'number' or heightPct < 10 or heightPct > 100 then heightPct = 35 end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local width = math.max(300, math.floor(screenW * (widthPct / 100)))
    local height = math.max(250, math.floor(screenH * (heightPct / 100)))
    local x = math.floor((screenW - width) / 2)
    local y = math.floor((screenH - height) / 2)

    local window = MiniGameMorseWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData)
    window:initialise()
    window:addToUIManager()
    window:bringToTop()
    window:setVisible(true)
    return window
end

-- Mejorar renderizado: EFECTO CRT VERDE ESTILO ALIEN (copiado de MiniGameUI.lua)
function MiniGameMorseWindow:render()
    ISPanel.render(self)

    -- EFECTO CRT
    local crtGreen = {r=0, g=0, b=0, a=0.3}
    self:drawRect(0, 0, self.width, self.height, crtGreen.a, crtGreen.r, crtGreen.g, crtGreen.b)
    
    for y = 0, self.height, 4 do
        self:drawRect(0, y, self.width, 1, 0.1, 0, 0.3, 0)
    end
    
    local borderGreen = {r=0.2, g=1, b=0.2, a=1}
    self:drawRectBorder(0, 0, self.width, self.height, borderGreen.a, borderGreen.r, borderGreen.g, borderGreen.b)
    self:drawRectBorder(1, 1, self.width-2, self.height-2, borderGreen.a * 0.5, borderGreen.r, borderGreen.g, borderGreen.b)

    -- TÍTULO
    local titleText = "MORSE CODE DECODER"
    local titleWidth = 200
    local textManager = getTextManager()
    if textManager and textManager.MeasureStringX then
        local success, width = pcall(function()
            return textManager:MeasureStringX(UIFont.Large, titleText)
        end)
        if success and width then titleWidth = width end
    end
    local titleX = (self.width - titleWidth) / 2
    self:drawText(titleText, titleX + 1, 11, 0.1, 0.5, 0.1, 0.8, UIFont.Large)
    self:drawText(titleText, titleX, 10, 0.2, 1, 0.2, 1, UIFont.Large)

    -- Dificultad
    local diffText = DIFFICULTY_TEXT or "DIFFICULTY: MORSE BASIC"
    local diffWidth = 150
    if textManager and textManager.MeasureStringX then
        local success, width = pcall(function()
            return textManager:MeasureStringX(UIFont.Small, diffText)
        end)
        if success and width then diffWidth = width end
    end
    local diffX = (self.width - diffWidth) / 2
    self:drawText(diffText, diffX, 35, 0.2, 0.8, 0.2, 0.9, UIFont.Small)

    -- Mostrar secuencia Morse si hay una activa
    if self.morseSequence and self.morseSequence ~= "" then
        self:drawText("MORSE SEQUENCE:", 20, 70, 0.2, 1, 0.2, 1, UIFont.Medium)
        self:drawText(self.morseSequence, 20, 90, 0.2, 1, 0.2, 1, UIFont.Small)
    end

    -- Mostrar tiempo restante
    if self.gameActive then
        local timeText = "TIME: " .. self.timeRemaining .. "s"
        local timeWidth = 80
        if textManager and textManager.MeasureStringX then
            local success, width = pcall(function()
                return textManager:MeasureStringX(UIFont.Small, timeText)
            end)
            if success and width then timeWidth = width end
        end
        local timeX = self.width - timeWidth - 10
        self:drawText(timeText, timeX, self.height - 20, 0.2, 1, 0.2, 1, UIFont.Small)
    end

    -- Estado
    local statusText = self.gameActive and "DECODING..." or "READY"
    local statusWidth = 100
    if textManager and textManager.MeasureStringX then
        local success, width = pcall(function()
            return textManager:MeasureStringX(UIFont.Small, statusText)
        end)
        if success and width then statusWidth = width end
    end
    local statusX = (self.width - statusWidth) / 2
    self:drawText(statusText, statusX, self.height - 35, 0.2, 1, 0.2, 1, UIFont.Small)
end