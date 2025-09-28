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
    end
end

-- ✅ FUNCIÓN DE DEBUG PARA PROBAR CONSUMO DE USB ESPECÍFICO
function TestFalloutUSBConsumption()
    print("[FALLOUT DEBUG] Testing USB consumption logic...")

    local player = getPlayer()
    if not player then
        print("[ERROR] No player found for testing")
        return
    end

    local inventory = player:getInventory()
    if not inventory then
        print("[ERROR] No inventory found")
        return
    end

    -- Buscar un USB en el inventario
    local usbItem = nil
    local items = inventory:getItems()
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item:getFullType() and string.find(item:getFullType(), "SkillDrive_") then
            usbItem = item
            break
        end
    end

    if not usbItem then
        print("[ERROR] No USB found in inventory for testing")
        return
    end

    print("[DEBUG] Found USB: " .. tostring(usbItem:getName()) .. " (" .. tostring(usbItem:getFullType()) .. ")")

    -- Crear datos USB de prueba
    local testUSBData = {
        item = usbItem,
        skill = "Cooking",
        difficulty_english = "Easy",
        displayName = "USB Cooking (Easy)"
    }

    print("[DEBUG] Created test USB data:")
    for key, value in pairs(testUSBData) do
        print("[DEBUG]   " .. tostring(key) .. ": " .. tostring(value))
    end

    -- Simular la lógica de consumo de USB
    print("[DEBUG] Testing inventory:contains()...")
    local containsUSB = inventory:contains(usbItem)
    print("[DEBUG] inventory:contains(usbItem): " .. tostring(containsUSB))

    if containsUSB then
        print("[DEBUG] Calling inventory:Remove()...")
        inventory:Remove(usbItem)
        print("[SUCCESS] USB consumed from inventory: " .. tostring(usbItem:getName()))

        -- Verificar que el USB ya no esté en el inventario
        local stillContains = inventory:contains(usbItem)
        print("[DEBUG] After removal - inventory:contains(usbItem): " .. tostring(stillContains))

        if not stillContains then
            print("[SUCCESS] USB consumption test PASSED - USB was successfully removed")
        else
            print("[ERROR] USB consumption test FAILED - USB still in inventory after removal")
        end
    else
        print("[WARNING] USB not found in inventory for consumption test")
    end
end

-- ========== CONFIGURACIÓN DEL MINIJUEGO FALLOUT ==========
-- Configuraciones principales del hacking de contraseñas
local TIME_LIMIT = 180         -- Tiempo límite en segundos
local PASSWORD_LENGTH = 6       -- Longitud de la contraseña
local WORD_COUNT = 8            -- Número de palabras candidatas
local MAX_ATTEMPTS = 4          -- Máximo número de intentos
local DIFFICULTY_TEXT = ""
-- ========== CONFIGURACIÓN DE ESCALADO ADAPTATIVO ==========
local PADDING_HORIZONTAL = 40   -- Espacio horizontal alrededor de elementos
local PADDING_VERTICAL = 80     -- Espacio vertical para título y controles
local MIN_BUTTON_SIZE = 20      -- Tamaño mínimo de botones
local MAX_BUTTON_SIZE = 35      -- Tamaño máximo de botones
local BUTTON_SIZE = 25          -- Tamaño preferido de botones
local BUTTON_SPACING = 15       -- Espaciado entre botones
-- ========== CONFIGURACIÓN DE VENTANA ==========
local WINDOW_WIDTH_PCT = 18     -- Porcentaje del ancho de pantalla
local WINDOW_HEIGHT_PCT = 39    -- Porcentaje del alto de pantalla
local WINDOW_WIDTH = 400        -- Ancho fallback en píxeles
local WINDOW_HEIGHT = 500       -- Alto fallback en píxeles
-- ============== DIFFICULTY SETTINGS==============================
local EASY_TIME = 240           -- Tiempo para dificultad fácil
local MODERATE_TIME = 180       -- Tiempo para dificultad moderada
local EXPERT_TIME = 120         -- Tiempo para dificultad experta
local EASY_LENGTH = 5           -- Longitud de contraseña fácil
local MODERATE_LENGTH = 6       -- Longitud de contraseña moderada
local EXPERT_LENGTH = 7         -- Longitud de contraseña experta
local EASY_WORDS = 8            -- Número de palabras fáciles
local MODERATE_WORDS = 8        -- Número de palabras moderadas
local EXPERT_WORDS = 10         -- Número de palabras expertas
local EASY_ATTEMPTS = 5         -- Intentos para dificultad fácil
local MODERATE_ATTEMPTS = 4     -- Intentos para dificultad moderada
local EXPERT_ATTEMPTS = 4       -- Intentos para dificultad experta
-- ============== RESULTADO Y TIEMPOS =============================
local RESULT_DISPLAY_TIME = 180 -- Ticks para mostrar resultado antes de cerrar (180 = 9 segundos)
local AUTO_CLOSE_DELAY = 60     -- Ticks para cierre automático después de resultado (60 = 3 segundos)
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
    "LUCKY","BATMAN","JENJI","BREE","GINGERSNAP","SNAP","KENSHI","ALICE"
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
        -- Verificar que el timer sea una tabla válida
        if timer and type(timer) == 'table' and timer.elapsed and timer.duration and timer.callback then
            timer.elapsed = timer.elapsed + 1
            if timer.elapsed >= timer.duration then
                -- Ejecutar callback de forma segura
                if timer.callback and type(timer.callback) == 'function' then
                    local success, err = pcall(timer.callback)
                    if not success then
                        print("SimpleTimer: Callback error:", err)
                    end
                end
                toRemove[id] = true
            end
        else
            -- Timer inválido, marcar para remover
            toRemove[id] = true
        end
    end

    -- Remover timers completados o inválidos
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
    o.wordFeedback = {}

    -- ✅ EFECTOS VISUALES Y DE AUDIO
    o.flashTicks = 0
    o.flashColor = {r=0.2, g=1, b=0.2}
    o.scanOffset = 0
    o.scanDelay = 4
    o.scanStep = 6
    o.statusMessages = {"LINK ESTABLISHED", "BRUTE FORCE IN PROGRESS", "WARNING: FIREWALL"}
    o.statusTextManual = "STANDBY"
    o.statusCycleDelay = 180
    o.statusIndex = 1
    o.shakeTicks = 0
    o.baseX = x
    o.baseY = y
    o.statusCycleEnabled = true
    o.scanAnimationActive = true
    o.scanTickCounter = 0
    o.statusTickCounter = 0
    o.statusPulseTick = 0
    o.statusPulseValue = 1
    
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
            timeLimit = 45,      -- 45 segundos
            passwordLength = 5,   -- 5 letras
            wordCount = 6,        -- 6 palabras
            maxAttempts = 4,      -- 5 intentos
            displayText = ""
        },
        ["Moderate"] = {
            timeLimit = 35,      -- 35 segundos
            passwordLength = 6,   -- 6 letras
            wordCount = 8,        -- 8 palabras
            maxAttempts = 3,      -- 4 intentos
            displayText = ""
        },
        ["Expert"] = {
            timeLimit = 30,      -- 30 segundos
            passwordLength = 7,   -- 7 letras
            wordCount = 10,       -- 10 palabras
            maxAttempts = 3,      -- 3 intentos
            displayText = ""
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

    -- ✅ BOTÓN DECODE - ALINEADO A LA IZQUIERDA
    self.tryButton = ISButton:new(20, self.height - 70, 100, 30, "DECODE", self, self.onTry)
    self.tryButton:initialise()
    self:addChild(self.tryButton)

    -- ✅ BOTÓN START - AL LADO DE DECODE
    self.startButton = ISButton:new(130, self.height - 70, 100, 30, "START", self, self.onStart)
    self.startButton:initialise()
    self:addChild(self.startButton)

    -- ✅ BOTÓN RESET - COMENTADO: Un usuario no debe poder resetear el desafío
    -- self.resetButton = ISButton:new(self.width - 120, self.height - 120, 100, 30, "RESET", self, self.onReset)
    -- self.resetButton:initialise()
    -- self:addChild(self.resetButton)

    self.wordFeedback = self.wordFeedback or {}
    self:startScanAnimation()
    self:startStatusCycle(true)
    self:updateActionButtons()
    self:updateWordButtonStyles()
end

function MiniGameFalloutWindow:cancelTimer(fieldName)
    if not fieldName then return end
    local timerId = self[fieldName]
    if timerId then
        SimpleTimer:removeTimer(timerId)
        self[fieldName] = nil
    end
end

function MiniGameFalloutWindow:startScanAnimation()
    self:cancelTimer("scanTimerId")
    if not self.scanStep or self.scanStep <= 0 then return end

    local delay = math.max(1, self.scanDelay or 4)
    self.scanTimerId = SimpleTimer:addTimer(delay, function()
        if not self:getIsVisible() then
            self:cancelTimer("scanTimerId")
            return
        end

        local height = self.height or 0
        self.scanOffset = (self.scanOffset or -20) + (self.scanStep or 6)
        if self.scanOffset > height + 20 then
            self.scanOffset = -20
        end

        self:startScanAnimation()
    end)
end

function MiniGameFalloutWindow:startStatusCycle(forceReset)
    self:cancelTimer("statusTimerId")
    if not self.gameActive then return end

    local messages = self.statusMessages or {}
    if #messages == 0 then return end

    local delay = math.max(30, self.statusCycleDelay or 180)
    self.statusTimerId = SimpleTimer:addTimer(delay, function()
        if not self.gameActive then
            self:cancelTimer("statusTimerId")
            return
        end

        local count = #messages
        if count > 0 then
            self.statusIndex = (self.statusIndex or 1) + 1
            if self.statusIndex > count then self.statusIndex = 1 end
            self.statusTextManual = messages[self.statusIndex]
        end

        self:startStatusCycle()
    end)
end

function MiniGameFalloutWindow:updateActionButtons()
    if self.tryButton then
        local canTry = self.gameActive and self.selectedWordIndex and self.selectedWordIndex > 0
        self.tryButton:setEnable(canTry)
        self.tryButton:setVisible(true)
    end

    if self.startButton then
        local canStart = not self.gameActive
        self.startButton:setEnable(canStart)
        if not canStart then
            self.startButton:setVisible(false)
        end
    end
end

function MiniGameFalloutWindow:updateWordButtonStyles(successMode)
    if not self.wordButtons then return end

    local length = PASSWORD_LENGTH or (self.correctPassword and string.len(self.correctPassword)) or 1
    for index, btn in ipairs(self.wordButtons) do
        if btn then
            local isSelected = self.gameActive and self.selectedWordIndex == index
            local feedback = self.wordFeedback and self.wordFeedback[index] or nil
            local color = {r=0.15, g=0.35, b=0.2, a=0.6}

            if successMode and self.candidateWords and self.candidateWords[index] == self.correctPassword then
                color = {r=0.0, g=0.7, b=0.2, a=0.9}
            elseif feedback then
                local correctness = math.min(1, (feedback.pos or 0) / length)
                local letterBonus = math.min(1, (feedback.letters or 0) / length)
                color = {
                    r = 0.15 + 0.6 * letterBonus,
                    g = 0.4 + 0.5 * correctness,
                    b = 0.15,
                    a = 0.75
                }
            end

            if isSelected then
                color = {r=0.2, g=0.9, b=0.2, a=0.95}
            end

            if not self.gameActive then
                color.a = math.min(color.a, 0.4)
            end

            btn.backgroundColor = color
            btn.borderColor = {r=color.r, g=color.g, b=color.b, a=1}
        end
    end
end

function MiniGameFalloutWindow:triggerFlash(ticks, color)
    self.flashTicks = math.max(self.flashTicks or 0, ticks or 20)
    if color then
        self.flashColor = color
    end
end

function MiniGameFalloutWindow:triggerShake(ticks)
    local amount = tonumber(ticks) or 20
    if amount < 0 then amount = 0 end
    self.shakeTicks = math.max(self.shakeTicks or 0, amount)
end

function MiniGameFalloutWindow:playSound(soundName)
    if not soundName or type(soundName) ~= "string" then
        return
    end

    local success = false

    if self.player and type(self.player) == "table" then
        local square = nil
        if self.player.getCurrentSquare and type(self.player.getCurrentSquare) == "function" then
            square = self.player:getCurrentSquare()
        end

        if square then
            local sm = getSoundManager()
            if sm and type(sm) == "table" and sm.playWorldSound then
                local status, err = pcall(function()
                    sm:playWorldSound(soundName, square, 0, 10, 1, false)
                end)
                if status then
                    success = true
                else
                    print("MiniGameFallout: Sound error:", err)
                end
            end
        end
    end

    if not success then
        local sm = getSoundManager()
        if sm and sm.playUISound then
            pcall(function()
                sm:playUISound(soundName)
            end)
        end
    end
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
    self.wordFeedback = {}
    
    -- Actualizar texto de botones
    for i, btn in ipairs(self.wordButtons) do
        if self.candidateWords[i] then
            btn:setTitle(self.candidateWords[i])
            btn:setVisible(true)
        else
            btn:setVisible(false)
        end
    end
    
    -- ✅ OCULTAR BOTÓN START para evitar re-roll
    if self.startButton then
        self.startButton:setVisible(false)
    end

    -- ✅ FEEDBACK AUDIO/VISUAL
    self:triggerFlash(30, {r=0.2, g=1, b=0.2})
    if self.playSound then
        self:playSound("UIActivate")
    end

    self.statusCycleEnabled = true
    self.statusIndex = 1
    if self.statusMessages and #self.statusMessages > 0 then
        self.statusTextManual = self.statusMessages[1]
    else
        self.statusTextManual = "LINK ESTABLISHED"
    end
    self:startStatusCycle(true)
    self:startScanAnimation()
    self:updateWordButtonStyles()
    self:updateActionButtons()
    
    -- Iniciar timer
    self:startTimer()
    
    if self.player then
        self.player:Say("Initiating password hack...")
    end
end

-- ✅ FUNCIÓN RESET - COMENTADA: Un jugador no debe poder resetear el desafío
-- function MiniGameFalloutWindow:onReset()
--     self:clearAllTimers()
--     
--     -- Reiniciar estado del juego
--     self.gameActive = false
--     self.correctPassword = ""
--     self.candidateWords = {}
--     self.attemptsRemaining = MAX_ATTEMPTS
--     self.timeRemaining = TIME_LIMIT
--     self.selectedWordIndex = 0
--     self.lastHint = ""
--     
--     -- Limpiar texto de botones de palabras
--     for i, btn in ipairs(self.wordButtons) do
--         btn:setTitle("")
--         btn:setVisible(false)
--     end
--     
--     -- ✅ MOSTRAR BOTÓN START nuevamente
--     if self.startButton then
--         self.startButton:setVisible(true)
--     end
--     
--     -- Limpiar mensajes de estado
--     if self.statusLabel then
--         self.statusLabel:setName("")
--     end
--     
--     if self.player then
--         self.player:Say("Hacking terminal reset...")
--     end
-- end

function MiniGameFalloutWindow:startTimer()
    self:cancelTimer("timerId")
    self.timerId = SimpleTimer:addTimer(60, function()
        self.timeRemaining = math.max((self.timeRemaining or 0) - 1, 0)
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
    self:cancelTimer("statusTimerId")
    self.statusTextManual = "TIME UP"
    self.selectedWordIndex = 0
    self:updateActionButtons()
    self:updateWordButtonStyles()
    self:showResult(false, "TIME UP")
    self:applyResult(false)
end

function MiniGameFalloutWindow:onWordSelect(button)
    if not self.gameActive then return end

    if self.wordButtons then
        for i, btn in ipairs(self.wordButtons) do
            if btn == button then
                self.selectedWordIndex = i
                break
            end
        end
    end

    self:updateWordButtonStyles()
    self:updateActionButtons()

    if self.playSound then
        self:playSound("UIToggle")
    end
end

function MiniGameFalloutWindow:onTry()
    if not self.gameActive or self.selectedWordIndex == 0 then return end
    
    local selectedIndex = self.selectedWordIndex
    local selectedWord = self.candidateWords[selectedIndex]
    local success = (selectedWord == self.correctPassword)

    if success then
        self:triggerFlash(35, {r=0.2, g=1, b=0.2})
        if self.playSound then
            self:playSound("UIUnlock")
        end
        self.gameActive = false
        self:clearAllTimers()
        self:cancelTimer("statusTimerId")
        self.statusTextManual = "ACCESS GRANTED"
        self:updateActionButtons()
        self:updateWordButtonStyles(true)
        self:showResult(true, "ACCESS GRANTED")
        self:applyResult(true)
        return
    end

    local correctPos, correctLet = calculateHints(selectedWord, self.correctPassword)
    self.wordFeedback[selectedIndex] = {pos = correctPos, letters = correctLet}
    self.lastHint = string.format("%d/%d correct", correctPos, PASSWORD_LENGTH)
    self.attemptsRemaining = self.attemptsRemaining - 1
    self.selectedWordIndex = 0
    self:updateWordButtonStyles()

    if self.attemptsRemaining <= 0 then
        self:triggerFlash(40, {r=1, g=0.2, b=0.2})
        if self.playSound then
            self:playSound("UIObjectiveFailed")
        end
        self.gameActive = false
        self:clearAllTimers()
        self:cancelTimer("statusTimerId")
        self.statusTextManual = "LOCKOUT"
        self:triggerShake(40)
        self:showResult(false, "LOCKOUT")
        self:applyResult(false)
    else
        self:triggerFlash(20, {r=1, g=0.6, b=0.2})
        if self.playSound then
            self:playSound("UIError")
        end
        self.statusTextManual = string.format("FIREWALL: %s", self.lastHint)
        self:startStatusCycle()
        if self.player then
            self.player:Say("Incorrect. " .. self.lastHint .. " remaining.")
        end
    end

    self:updateActionButtons()
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
    
    self:cancelTimer("resultTimerId")
    self.resultTimerId = SimpleTimer:addTimer(RESULT_DISPLAY_TIME or 180, function()
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

    -- ✅ DEBUG: Información detallada del estado del USB
    print("[FALLOUT DEBUG] applyResult called with success=" .. tostring(success))
    print("[FALLOUT DEBUG] self.usbData exists: " .. tostring(self.usbData ~= nil))
    if self.usbData then
        print("[FALLOUT DEBUG] self.usbData.item exists: " .. tostring(self.usbData.item ~= nil))
        print("[FALLOUT DEBUG] self.usbData.displayName: " .. tostring(self.usbData.displayName))
        if self.usbData.item then
            print("[FALLOUT DEBUG] self.usbData.item type: " .. type(self.usbData.item))
            print("[FALLOUT DEBUG] self.usbData.item name: " .. tostring(self.usbData.item:getName()))
            print("[FALLOUT DEBUG] self.usbData.item fullType: " .. tostring(self.usbData.item:getFullType()))
        end
    end

    print("[FALLOUT DEBUG] self.player exists: " .. tostring(self.player ~= nil))
    print("[FALLOUT DEBUG] self.usbType: " .. tostring(self.usbType))
    print("[FALLOUT DEBUG] self.difficulty: " .. tostring(self.difficulty))
    print("[FALLOUT DEBUG] self.laptopItem exists: " .. tostring(self.laptopItem ~= nil))

    -- ✅ CONSUMIR USB CON VALIDACIONES ROBUSTAS
    if self.usbData and self.usbData.item then
        local inventory = self.player and self.player:getInventory()
        print("[FALLOUT DEBUG] inventory obtained: " .. tostring(inventory ~= nil))

        if inventory then
            print("[FALLOUT DEBUG] Checking if inventory contains USB item...")
            local containsUSB = inventory:contains(self.usbData.item)
            print("[FALLOUT DEBUG] inventory:contains(usbData.item): " .. tostring(containsUSB))

            if containsUSB then
                print("[FALLOUT DEBUG] Removing USB from inventory...")
                inventory:Remove(self.usbData.item)
                print("[SUCCESS] USB consumed from inventory: " .. tostring(self.usbData.displayName))
            else
                print("[WARNING] USB not found in inventory for consumption")
            end
        else
            print("[WARNING] Could not get player inventory")
        end
    else
        print("[WARNING] usbData or usbData.item is nil - cannot consume USB")
        if self.usbData then
            print("[DEBUG] usbData contents:")
            for key, value in pairs(self.usbData) do
                print("[DEBUG]   " .. tostring(key) .. ": " .. tostring(value))
            end
        end
    end

    -- ✅ INTEGRACIÓN USB SEGURA
    if self.usbType and self.difficulty and self.laptopItem then
        if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
            print("[FALLOUT DEBUG] Calling GVDrive_Utils.applyMinigameResult...")
            local result = GVDrive_Utils.applyMinigameResult(self.player, self.laptopItem, self.usbType, self.difficulty, success)
            print("[FALLOUT DEBUG] applyMinigameResult returned: " .. tostring(result))
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
    self:cancelTimer("statusTimerId")
    self:cancelTimer("resultTimerId")
    self.correctPassword = ""
    self.candidateWords = {}
    self.attemptsRemaining = MAX_ATTEMPTS
    self.timeRemaining = TIME_LIMIT
    self.gameActive = false
    self.selectedWordIndex = 0
    self.lastHint = ""
    self.scanOffset = -20
    self.statusIndex = 1
    self.statusTextManual = "STANDBY"
    self.wordFeedback = {}
    
    for i, btn in ipairs(self.wordButtons) do
        btn:setTitle("")
        btn:setVisible(false)
        btn.backgroundColor = {r=0.5, g=0.5, b=0.5, a=0}
    end
    
    if self.player then
        self.player:Say("Hacking system reset")
    end

    self:updateActionButtons()
    self:updateWordButtonStyles()
end

function MiniGameFalloutWindow:playSound(soundName)
    if self.player and soundName then
        -- Usa el método local del jugador para reproducir sonidos
        if self.player.playSoundLocal then
            self.player:playSoundLocal(soundName)
        elseif getPlayer() and getPlayer().playSoundLocal then
            getPlayer():playSoundLocal(soundName)
        else
            print("[MiniGameFallout] Audio system not available for sound: " .. soundName)
        end
    end
end

function MiniGameFalloutWindow:clearAllTimers()
    local fields = {"timerId", "statusTimerId", "scanTimerId", "resultTimerId"}
    for _, field in ipairs(fields) do
        if self[field] then
            SimpleTimer:removeTimer(self[field])
            self[field] = nil
        end
    end
end

function MiniGameFalloutWindow:onClose()
    -- ✅ VERIFICACIÓN CRÍTICA: Si el minijuego está en progreso al cerrar, contar como FAILURE
    if self.usbData and self.usbData.item then
        print("[CLOSE FAILURE] Fallout minigame closed while in progress - treating as failure")

        -- ✅ CONSUMIR USB DEL INVENTARIO (cierre = fracaso)
        if self.usbData and self.usbData.item then
            local inventory = self.player and self.player:getInventory()
            if inventory and inventory:contains(self.usbData.item) then
                inventory:Remove(self.usbData.item)
                print("[CLOSE FAILURE] USB consumed from inventory due to early closure: " .. tostring(self.usbData.displayName))
            else
                print("[WARNING] USB not found in inventory for consumption on close")
            end
        end

        -- ✅ INTEGRACIÓN USB: Aplicar resultado del minijuego (FRACASO por cierre)
        if self.usbType and self.difficulty and self.laptopItem then
            -- Verificar que GVDrive_Utils esté disponible
            if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
                local success = GVDrive_Utils.applyMinigameResult(self.player, self.laptopItem, self.usbType, self.difficulty, false)
                if not success then
                    self.player:Say("Laptop damaged from interrupted " .. self.usbType .. " hack!")
                end
            else
                print("[ERROR] GVDrive_Utils not available for damage calculation on close")
                self.player:Say("Hack interrupted, but damage system unavailable.")
            end
        end

        -- Mensaje al jugador sobre el cierre prematuro
        if self.player then
            self.player:Say("Password hack interrupted! You gave up too early.")
        end
    end

    -- Cerrar la ventana normalmente
    self:clearAllTimers()
    self:setVisible(false)
    self:removeFromUIManager()
end

-- Función global para abrir la ventana Fallout
function MiniGameFallout(widthPct, heightPct, usbType, difficulty, laptopItem, usbData, demoMode)
    return MiniGame_Fallout(widthPct, heightPct, usbType, difficulty, laptopItem, usbData, demoMode)
end

-- Función principal Fallout - NO sobrescribir MiniGame global para evitar conflictos
function MiniGame_Fallout(widthPct, heightPct, usbType, difficulty, laptopItem, usbData, demoMode)
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
    -- Verificar que math esté disponible y proporcionar fallbacks
    local mathLib = math
    if not mathLib then
        mathLib = {}
    end

    -- Proporcionar fallbacks para funciones matemáticas críticas
    local mathRandom = mathLib.random or function() return 0.5 end
    local mathFloor = mathLib.floor or function(x) return x end
    local mathMax = mathLib.max or function(a, b) return a > b and a or b end

    local shaking = self.shakeTicks and self.shakeTicks > 0
    local originalX, originalY

    if shaking then
        originalX = self:getX()
        originalY = self:getY()
        self.baseX = self.baseX or originalX
        self.baseY = self.baseY or originalY
        local strength = mathMax(1, mathFloor(self.shakeTicks / 6) + 1)
        local offsetX = mathFloor(((mathRandom() * 2) - 1) * strength)
        local offsetY = mathFloor(((mathRandom() * 2) - 1) * strength)
        self:setX(self.baseX + offsetX)
        self:setY(self.baseY + offsetY)
    else
        self.baseX = self:getX()
        self.baseY = self:getY()
    end

    ISPanel.render(self)

    if shaking then
        self:setX(originalX)
        self:setY(originalY)
        self.shakeTicks = mathMax(self.shakeTicks - 1, 0)
        if self.shakeTicks == 0 then
            self.baseX = originalX
            self.baseY = originalY
        end
    end

    -- EFECTO CRT
    local crtGreen = {r=0, g=0, b=0, a=0.3}
    self:drawRect(0, 0, self.width, self.height, crtGreen.a, crtGreen.r, crtGreen.g, crtGreen.b)
    
    for y = 0, self.height, 4 do
        self:drawRect(0, y, self.width, 1, 0.1, 0, 0.3, 0)
    end

    if self.scanOffset then
        local scanY = (self.scanOffset % (self.height + 40)) - 20
        if scanY < self.height then
            self:drawRect(0, math.floor(scanY), self.width, 12, 0.12, 0.1, 0.8, 0.1)
        end
    end
    
    local borderGreen = {r=0.2, g=1, b=0.2, a=1}
    self:drawRectBorder(0, 0, self.width, self.height, borderGreen.a, borderGreen.r, borderGreen.g, borderGreen.b)
    self:drawRectBorder(1, 1, self.width-2, self.height-2, borderGreen.a * 0.5, borderGreen.r, borderGreen.g, borderGreen.b)

    if self.flashTicks and self.flashTicks > 0 then
        local fc = self.flashColor or borderGreen
        local flashAlpha = math.min(0.45, 0.1 + (self.flashTicks / 80))
        self:drawRect(0, 0, self.width, self.height, flashAlpha, fc.r, fc.g, fc.b)
        self:drawRectBorder(0, 0, self.width, self.height, flashAlpha + 0.15, fc.r, fc.g, fc.b)
        self.flashTicks = math.max(self.flashTicks - 1, 0)
    end

    -- TÍTULO DINÁMICO (reemplaza el título estático)
    local statusText = self.statusTextManual
    if not statusText or statusText == "" then
        statusText = self.gameActive and "HACKING..." or "STANDBY"
    end

    local titleText = self.demoMode and "PASSWORD HACK TERMINAL [DEMO]" or statusText
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
        
        self:drawText(attemptsText, 20, self.height - 35, 0.2, 1, 0.2, 1, UIFont.Small)
        self:drawText(timeText, self.width - 120, self.height - 35, 0.2, 1, 0.2, 1, UIFont.Small)
    end
end