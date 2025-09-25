-- ✅ MINIJUEGO FALLOUT HACKING - Sistema de hacking estilo Fallout para DecryptSkillSys
-- MiniGameFallout.lua - Minijuego independiente de hacking de contraseñas
-- Basado en patrones del CODEBASE y MiniGameUI.lua

print("[DecryptSkillSys] Loading MiniGameFallout.lua - Fallout hacking minigame system")

-- ✅ FUNCIÓN DE RECARGA PARA DEBUG
function ReloadMiniGameFallout()
    print("[DEBUG] Reloading Fallout minigame system...")
    if MiniGameFallout then
        MiniGameFallout = nil
        print("[DEBUG] Previous MiniGameFallout function cleared")
    end
    package.loaded["client/MiniGameFallout"] = nil
    local success, result = pcall(require, "client/MiniGameFallout")
    if success then
        print("[DEBUG] Fallout minigame reloaded successfully!")
    else
        print("[DEBUG] Failed to reload Fallout: " .. tostring(result))
    end
end

-- ✅ FUNCIÓN DE PRUEBA RÁPIDA PARA DEBUG
function TestMiniGameFallout(widthPct, heightPct)
    widthPct = widthPct or 30
    heightPct = heightPct or 40
    print("[DEBUG] Testing Fallout minigame with size: " .. widthPct .. "% x " .. heightPct .. "%")
    if MiniGameFallout then
        return MiniGameFallout(widthPct, heightPct, "TestSkill", "Easy", nil, {skill="TestSkill", difficulty_english="Easy", displayName="Test USB"})
    else
        print("[DEBUG] MiniGameFallout function not available. Try ReloadMiniGameFallout() first.")
    end
end

-- ========== CONFIGURACIÓN DEL MINIJUEGO FALLOUT ==========
local TIME_LIMIT = 180         -- Tiempo límite en segundos
local PASSWORD_LENGTH = 6       -- Longitud de la contraseña
local WORD_COUNT = 8            -- Número de palabras candidatas
local MAX_ATTEMPTS = 4          -- Máximo número de intentos
local DIFFICULTY_TEXT = ""
-- ========== CONFIGURACIÓN DE ESCALADO ADAPTATIVO ==========
local PADDING_HORIZONTAL = 40   -- Espacio horizontal alrededor de elementos
local PADDING_VERTICAL = 90     -- Espacio vertical para título y controles
local MIN_BUTTON_SIZE = 20      -- Tamaño mínimo de botones
local MAX_BUTTON_SIZE = 40      -- Tamaño máximo de botones
local BUTTON_SIZE = 30          -- Tamaño preferido de botones
local BUTTON_SPACING = 10       -- Espaciado entre botones
-- ========== CONFIGURACIÓN DE VENTANA ==========
local WINDOW_WIDTH_PCT = 18     -- Porcentaje del ancho de pantalla
local WINDOW_HEIGHT_PCT = 45    -- Porcentaje del alto de pantalla
local WINDOW_WIDTH = 400        -- Ancho fallback en píxeles
local WINDOW_HEIGHT = 500       -- Alto fallback en píxeles
-- ============== DIFFICULTY SETTINGS==============================
local EASY_TIME = 240
local MODERATE_TIME = 180
local EXPERT_TIME = 120
local EASY_LENGTH = 5
local MODERATE_LENGTH = 6
local EXPERT_LENGTH = 7
local EASY_WORDS = 6
local MODERATE_WORDS = 8
local EXPERT_WORDS = 10
local EASY_ATTEMPTS = 5
local MODERATE_ATTEMPTS = 4
local EXPERT_ATTEMPTS = 3
-- =============================================

-- Lista de palabras para hacking (estilo Fallout)
local HACKING_WORDS = {
    "ACCESS", "ALERT", "ARMORY", "BLAST", "BREACH", "BRIDGE", "BYPASS",
    "CIPHER", "CIRCUIT", "CLEAR", "CODE", "COMMAND", "CONTROL", "CORE",
    "CRISIS", "CRYPTO", "DATA", "DEFEND", "DELTA", "DIGIT", "DOOR",
    "ENCRYPT", "ENTRY", "ERROR", "ESCAPE", "EVENT", "EXTERNAL", "FAIL",
    "FIELD", "FILE", "FIRE", "FLOOD", "FORCE", "FRAME", "FREEDOM",
    "GATE", "GLOBAL", "GREEN", "GUARD", "HACK", "HARD", "HATCH",
    "HEADER", "HIDDEN", "HIGH", "HORIZON", "HOST", "HUMAN", "HYPER",
    "IDLE", "IMAGE", "INDEX", "INPUT", "INTERNAL", "JAMMER", "JUMP",
    "KEY", "LASER", "LAUNCH", "LEVEL", "LIGHT", "LINK", "LOAD",
    "LOCK", "LOGIC", "LOOP", "MAIN", "MASTER", "MATRIX", "MEMORY",
    "MENU", "MESSAGE", "MODE", "MODULE", "MOTION", "NETWORK", "NODE",
    "NUCLEAR", "OBJECT", "OPEN", "OUTPUT", "OVERRIDE", "PACKET", "PANIC",
    "PASSWORD", "PATH", "PATTERN", "PHASE", "PORTAL", "POWER", "PRIMARY",
    "PRINT", "PRIORITY", "PROCESS", "PROGRAM", "PROTECT", "PROTOCOL",
    "QUERY", "QUEUE", "RANDOM", "RANGE", "READ", "REACTOR", "RECORD",
    "REMOTE", "REPEAT", "REPORT", "RESET", "RESTART", "ROBOT", "ROUTE",
    "RUN", "SAFE", "SCAN", "SCREEN", "SCRIPT", "SEARCH", "SECONDARY",
    "SECURE", "SECURITY", "SELECT", "SENSOR", "SEQUENCE", "SERVER",
    "SESSION", "SHIELD", "SHIFT", "SIGNAL", "SLEEP", "SOCKET", "SOURCE",
    "SPACE", "SPARE", "SPEED", "SPLIT", "STAGE", "START", "STATIC",
    "STATUS", "STEALTH", "STOP", "STORAGE", "STREAM", "STRING", "SUB",
    "SWITCH", "SYNC", "SYSTEM", "TABLE", "TARGET", "TASK", "TERMINAL",
    "TEST", "TEXT", "THREAD", "THREAT", "TIME", "TRACE", "TRACK",
    "TRANSFER", "TRIGGER", "TRUE", "TYPE", "UNIT", "UPDATE", "UPLOAD",
    "USER", "VALUE", "VECTOR", "VERSION", "VIEW", "VIRTUAL", "VOID",
    "WARNING", "WATCH", "WAVE", "WINDOW", "WIRE", "WORD", "WORK",
    "WORLD", "WRITE", "ZERO", "ZONE", "ZULU","RICOCHET","QUANTUM","PYTHON",
    "NEPTUNE","MERCURY","LUNAR","JUPITER","HYPERION","GALAXY","FUSION",
    "ECLIPSE","COSMIC","CRYSTAL","COSMOS","COMET","CELESTIAL","TANJIRO",
    "DEMO","INOSUKE","OCZY","KAMADO","ANKUI","BOO","SHIORY","JULY","JULS",
    "JOZH","BETTA","NODRIZA","MELOW","SUSHI","BOQT","BRRTE","JOEY",
    "BOOSY","HALLOWEEN","JERRY","IOUL","GHOUL","KIRARA","KATO","SHADOW",
    "LUCKY","BATMAN","JENJI","BREE"
}

-- Función para generar palabras candidatas y contraseña correcta
local function generateHackingSetup(length, wordCount)
    -- Seleccionar contraseña correcta
    local correctPassword = HACKING_WORDS[ZombRand(1, #HACKING_WORDS + 1)]
    
    -- Asegurar longitud correcta
    if string.len(correctPassword) ~= length then
        correctPassword = string.sub(correctPassword, 1, length)
        if string.len(correctPassword) < length then
            correctPassword = correctPassword .. string.rep("X", length - string.len(correctPassword))
        end
    end
    
    -- Generar palabras candidatas (incluyendo la correcta)
    local candidates = {correctPassword}
    local usedWords = {[correctPassword] = true}
    
    while #candidates < wordCount do
        local word = HACKING_WORDS[ZombRand(1, #HACKING_WORDS + 1)]
        if string.len(word) ~= length then
            word = string.sub(word, 1, length)
            if string.len(word) < length then
                word = word .. string.rep("X", length - string.len(word))
            end
        end
        
        if not usedWords[word] then
            table.insert(candidates, word)
            usedWords[word] = true
        end
    end
    
    -- Mezclar candidatos
    for i = #candidates, 2, -1 do
        local j = ZombRand(1, i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end
    
    return correctPassword, candidates
end

-- Función para calcular pistas (estilo Fallout)
local function calculateHints(guess, correct)
    local correctPositions = 0
    local correctLetters = 0
    local usedPositions = {}
    
    -- Contar posiciones correctas
    for i = 1, string.len(guess) do
        if string.sub(guess, i, i) == string.sub(correct, i, i) then
            correctPositions = correctPositions + 1
            usedPositions[i] = true
        end
    end
    
    -- Contar letras correctas en posiciones incorrectas
    for i = 1, string.len(guess) do
        if not usedPositions[i] then
            local letter = string.sub(guess, i, i)
            for j = 1, string.len(correct) do
                if not usedPositions[j] and string.sub(correct, j, j) == letter then
                    correctLetters = correctLetters + 1
                    usedPositions[j] = true
                    break
                end
            end
        end
    end
    
    return correctPositions, correctLetters
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
    print("[MiniGameFallout] Events not available - timers will not be registered (expected in test environment)")
end

local MiniGameFalloutWindow = ISPanel:derive("MiniGameFalloutWindow")

function MiniGameFalloutWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData, demoMode)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    
    -- ✅ PROPIEDADES ESTÉTICA ALIEN CRT
    o.player = player
    o.backgroundColor = {r=0.05, g=0.2, b=0.05, a=0.9}
    o.borderColor = {r=0.2, g=1, b=0.2, a=1}
    o.moveWithMouse = true
    
    -- ✅ INTEGRACIÓN USB
    o.usbType = usbType
    o.difficulty = difficulty  
    o.laptopItem = laptopItem
    o.usbData = usbData
    o.demoMode = demoMode or false  -- ✅ MODO DEMO
    
    -- ✅ ESTADO DEL JUEGO FALLOUT
    o.correctPassword = ""
    o.candidateWords = {}
    o.attemptsRemaining = MAX_ATTEMPTS
    o.timeRemaining = TIME_LIMIT
    o.gameActive = false
    o.selectedWordIndex = 0
    o.lastHint = ""
    
    -- ✅ CONFIGURACIÓN AUTOMÁTICA SEGÚN USB
    o:configureFromUSB()
    
    return o
end

function MiniGameFalloutWindow:configureFromUSB()
    if not self.usbType or not self.difficulty then
        print("FalloutGame: No USB parameters provided, using default configuration")
        return
    end

    local config = self:getDifficultyConfig(self.difficulty)
    TIME_LIMIT = config.timeLimit
    PASSWORD_LENGTH = config.passwordLength
    WORD_COUNT = config.wordCount
    MAX_ATTEMPTS = config.maxAttempts
    DIFFICULTY_TEXT = config.displayText

    print(string.format("FalloutGame: Configured for USB %s - Difficulty: %s - Time: %ds, Length: %d, Words: %d",
        tostring(self.usbType), tostring(self.difficulty), config.timeLimit or 0, config.passwordLength or 0, config.wordCount or 0))
end

function MiniGameFalloutWindow:getDifficultyConfig(difficulty)
    local configs = {
        ["Easy"] = {
            timeLimit = 240,      -- 4 minutos
            passwordLength = 5,   -- 5 letras
            wordCount = 6,        -- 6 palabras
            maxAttempts = 5,      -- 5 intentos
            displayText = "DIFFICULTY: HACKING EASY"
        },
        ["Moderate"] = {
            timeLimit = 180,      -- 3 minutos
            passwordLength = 6,   -- 6 letras
            wordCount = 8,        -- 8 palabras
            maxAttempts = 4,      -- 4 intentos
            displayText = "DIFFICULTY: HACKING MODERATE"
        },
        ["Expert"] = {
            timeLimit = 120,      -- 2 minutos
            passwordLength = 7,   -- 7 letras
            wordCount = 10,       -- 10 palabras
            maxAttempts = 3,      -- 3 intentos
            displayText = "DIFFICULTY: HACKING EXPERT"
        }
    }
    
    -- Retornar configuración específica o fallback a Easy
    return configs[difficulty] or configs["Easy"]
end

function MiniGameFalloutWindow:createChildren()
    -- ✅ BOTÓN DE CIERRE
    self.closeButton = ISButton:new(self.width - 25, 5, 20, 20, "X", self, self.onClose)
    self.closeButton:initialise()
    self:addChild(self.closeButton)

    -- ✅ ESCALADO ADAPTATIVO PARA BOTONES
    local paddingHorizontal = tonumber(PADDING_HORIZONTAL) or 40
    local paddingVertical = tonumber(PADDING_VERTICAL) or 60
    local availableWidth = math.max(100, self.width - paddingHorizontal * 2)
    local availableHeight = math.max(100, self.height - paddingVertical)
    
    local buttonSpacing = tonumber(BUTTON_SPACING) or 10
    local wordCount = tonumber(WORD_COUNT) or 8
    local maxButtonSizeByWidth = math.floor((availableWidth - (wordCount - 1) * buttonSpacing) / wordCount)
    local maxButtonSizeByHeight = math.floor(availableHeight / wordCount)
    
    local minButtonSize = tonumber(MIN_BUTTON_SIZE) or 20
    local maxButtonSize = tonumber(MAX_BUTTON_SIZE) or 40
    local buttonSize = math.max(minButtonSize, math.min(maxButtonSize, math.min(maxButtonSizeByWidth, maxButtonSizeByHeight)))
    local configuredMinSize = tonumber(BUTTON_SIZE) or 30
    buttonSize = math.max(buttonSize, math.min(configuredMinSize, maxButtonSize))

    -- Crear botones para palabras candidatas
    self.wordButtons = {}
    local buttonHeight = buttonSize
    local startY = 100
    
    for i = 1, wordCount do
        local btn = ISButton:new(20, startY + (i-1) * (buttonHeight + buttonSpacing), 
                                self.width - 40, buttonHeight, "", self, self.onWordSelect)
        btn.wordIndex = i
        btn:initialise()
        self:addChild(btn)
        self.wordButtons[i] = btn
    end

    -- ✅ BOTÓN TRY
    self.tryButton = ISButton:new((self.width - 100) / 2, self.height - 80, 100, 30, "TRY", self, self.onTry)
    self.tryButton:initialise()
    self:addChild(self.tryButton)

    -- ✅ BOTÓN START
    self.startButton = ISButton:new(20, self.height - 120, 100, 30, "START", self, self.onStart)
    self.startButton:initialise()
    self:addChild(self.startButton)

    -- ✅ BOTÓN RESET
    self.resetButton = ISButton:new(self.width - 120, self.height - 120, 100, 30, "RESET", self, self.onReset)
    self.resetButton:initialise()
    self:addChild(self.resetButton)
end

function MiniGameFalloutWindow:onStart()
    self:clearAllTimers()
    
    -- Generar nueva configuración de hacking
    self.correctPassword, self.candidateWords = generateHackingSetup(PASSWORD_LENGTH, WORD_COUNT)
    self.attemptsRemaining = MAX_ATTEMPTS
    self.timeRemaining = TIME_LIMIT
    self.gameActive = true
    self.selectedWordIndex = 0
    self.lastHint = ""
    
    -- Actualizar texto de botones
    for i, btn in ipairs(self.wordButtons) do
        if self.candidateWords[i] then
            btn:setTitle(self.candidateWords[i])
            btn:setVisible(true)
        else
            btn:setVisible(false)
        end
    end
    
    -- Iniciar timer
    self:startTimer()
    
    if self.player then
        self.player:Say("Initiating password hack...")
    end
end

function MiniGameFalloutWindow:startTimer()
    self.timerId = SimpleTimer:addTimer(60, function()
        self.timeRemaining = self.timeRemaining - 1
        if self.timeRemaining <= 0 then
            self:onTimeUp()
        else
            self:startTimer()
        end
    end)
end

function MiniGameFalloutWindow:onTimeUp()
    self.gameActive = false
    self:clearAllTimers()
    self:showResult(false, "TIME UP")
    self:applyResult(false)
end

function MiniGameFalloutWindow:onWordSelect(button)
    if not self.gameActive then return end
    
    -- Resaltar selección
    for i, btn in ipairs(self.wordButtons) do
        if btn == button then
            btn.backgroundColor = {r=0.3, g=1, b=0.3, a=1}  -- Verde para seleccionado
            self.selectedWordIndex = i
        else
            btn.backgroundColor = {r=0.5, g=0.5, b=0.5, a=0}  -- Normal
        end
    end
end

function MiniGameFalloutWindow:onTry()
    if not self.gameActive or self.selectedWordIndex == 0 then return end
    
    local selectedWord = self.candidateWords[self.selectedWordIndex]
    local success = (selectedWord == self.correctPassword)
    
    if success then
        self.gameActive = false
        self:clearAllTimers()
        self:showResult(true, "ACCESS GRANTED")
        self:applyResult(true)
    else
        -- Calcular pista
        local correctPos, correctLet = calculateHints(selectedWord, self.correctPassword)
        self.lastHint = string.format("%d/%d correct", correctPos, PASSWORD_LENGTH)
        self.attemptsRemaining = self.attemptsRemaining - 1
        
        if self.attemptsRemaining <= 0 then
            self.gameActive = false
            self:clearAllTimers()
            self:showResult(false, "LOCKOUT")
            self:applyResult(false)
        else
            if self.player then
                self.player:Say("Incorrect. " .. self.lastHint .. " remaining.")
            end
        end
    end
end

function MiniGameFalloutWindow:showResult(success, message)
    -- Mostrar resultado
    for i, btn in ipairs(self.wordButtons) do
        if success then
            if self.candidateWords[i] == self.correctPassword then
                btn:setTitle(message)
                btn.backgroundColor = {r=0, g=1, b=0, a=1}
            else
                btn:setVisible(false)
            end
        else
            btn:setTitle(message)
            btn.backgroundColor = {r=1, g=0, b=0, a=1}
        end
    end
    
    SimpleTimer:addTimer(180, function()
        self:onClose()
    end)
end

function MiniGameFalloutWindow:applyResult(success)
    -- ✅ MODO DEMO: NO APLICAR RESULTADOS REALES
    if self.demoMode then
        print("[DEMO] Demo mode - skipping USB consumption and result application")
        if self.player then
            self.player:Say(success and "[DEMO] Access granted!" or "[DEMO] Access denied.")
        end
        return
    end
    
    -- ✅ CONSUMIR USB CON VALIDACIONES ROBUSTAS
    if self.usbData and self.usbData.item then
        local inventory = self.player and self.player:getInventory()
        if inventory and inventory:contains(self.usbData.item) then
            inventory:Remove(self.usbData.item)
            print("[SUCCESS] USB consumed from inventory: " .. tostring(self.usbData.displayName))
        else
            print("[WARNING] USB not found in inventory or inventory not accessible")
        end
    end
    
    -- ✅ INTEGRACIÓN USB SEGURA
    if self.usbType and self.difficulty and self.laptopItem then
        if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
            local result = GVDrive_Utils.applyMinigameResult(self.player, self.laptopItem, self.usbType, self.difficulty, success)
            if success then
                if self.player then self.player:Say("Password cracked! Experience gained!") end
            else
                if self.player then self.player:Say("Hack failed. Laptop damaged!") end
            end
        else
            print("[ERROR] GVDrive_Utils not available for result application")
            if self.player then
                self.player:Say(success and "Access granted!" or "Access denied.")
            end
        end
    else
        print("[WARNING] Missing USB parameters for result application")
        if self.player then
            self.player:Say(success and "Access granted!" or "Access denied.")
        end
    end
end

function MiniGameFalloutWindow:onReset()
    self:clearAllTimers()
    self.correctPassword = ""
    self.candidateWords = {}
    self.attemptsRemaining = MAX_ATTEMPTS
    self.timeRemaining = TIME_LIMIT
    self.gameActive = false
    self.selectedWordIndex = 0
    self.lastHint = ""
    
    for i, btn in ipairs(self.wordButtons) do
        btn:setTitle("")
        btn:setVisible(false)
        btn.backgroundColor = {r=0.5, g=0.5, b=0.5, a=0}
    end
    
    if self.player then
        self.player:Say("Hacking system reset")
    end
end

function MiniGameFalloutWindow:clearAllTimers()
    if self.timerId then
        SimpleTimer:removeTimer(self.timerId)
        self.timerId = nil
    end
end

function MiniGameFalloutWindow:onClose()
    self:clearAllTimers()
    self:setVisible(false)
    self:removeFromUIManager()
end

-- Función global para abrir la ventana Fallout
function MiniGameFallout(widthPct, heightPct, usbType, difficulty, laptopItem, usbData, demoMode)
    local player = getPlayer()
    if not player then 
        print("MiniGameFallout: No player found")
        return 
    end

    widthPct = tonumber(widthPct) or WINDOW_WIDTH_PCT
    heightPct = tonumber(heightPct) or WINDOW_HEIGHT_PCT

    if type(widthPct) ~= 'number' or widthPct < 10 or widthPct > 100 then widthPct = WINDOW_WIDTH_PCT end
    if type(heightPct) ~= 'number' or heightPct < 10 or heightPct > 100 then heightPct = WINDOW_HEIGHT_PCT end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local width = math.max(350, math.floor(screenW * (widthPct / 100)))
    local height = math.max(300, math.floor(screenH * (heightPct / 100)))
    local x = math.floor((screenW - width) / 2)
    local y = math.floor((screenH - height) / 2)

    local window = MiniGameFalloutWindow:new(x, y, width, height, player, usbType, difficulty, laptopItem, usbData, demoMode)
    window:initialise()
    window:addToUIManager()
    window:bringToTop()
    window:setVisible(true)
    return window
end

-- Mejorar renderizado: EFECTO CRT VERDE ESTILO ALIEN
function MiniGameFalloutWindow:render()
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
    local titleText = self.demoMode and "PASSWORD HACK TERMINAL [DEMO]" or "PASSWORD HACK TERMINAL"
    local titleWidth = 220
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
    local diffText = DIFFICULTY_TEXT or "DIFFICULTY: HACKING BASIC"
    local diffWidth = 180
    if textManager and textManager.MeasureStringX then
        local success, width = pcall(function()
            return textManager:MeasureStringX(UIFont.Small, diffText)
        end)
        if success and width then diffWidth = width end
    end
    local diffX = (self.width - diffWidth) / 2
    self:drawText(diffText, diffX, 35, 0.2, 0.8, 0.2, 0.9, UIFont.Small)

    -- Mostrar hint si hay uno
    if self.lastHint and self.lastHint ~= "" then
        self:drawText("LAST HINT: " .. self.lastHint, 20, 60, 0.2, 1, 0.2, 1, UIFont.Small)
    end

    -- Información de estado
    if self.gameActive then
        local attemptsText = "ATTEMPTS: " .. self.attemptsRemaining
        local timeText = "TIME: " .. self.timeRemaining .. "s"
        
        self:drawText(attemptsText, 20, self.height - 50, 0.2, 1, 0.2, 1, UIFont.Small)
        self:drawText(timeText, self.width - 100, self.height - 50, 0.2, 1, 0.2, 1, UIFont.Small)
    end

    -- Estado
    local statusText = self.gameActive and "HACKING..." or "STANDBY"
    local statusWidth = 100
    if textManager and textManager.MeasureStringX then
        local success, width = pcall(function()
            return textManager:MeasureStringX(UIFont.Small, statusText)
        end)
        if success and width then statusWidth = width end
    end
    local statusX = (self.width - statusWidth) / 2
    self:drawText(statusText, statusX, self.height - 25, 0.2, 1, 0.2, 1, UIFont.Small)
end