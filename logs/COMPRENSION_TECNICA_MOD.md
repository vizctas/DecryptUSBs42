# 🔧 **COMPRENSIÓN TÉCNICA DEL MOD DECRYPTSKILLSYS**

## 🎯 **ARQUITECTURA TÉCNICA COMPLETA**

### **📁 Estructura de Archivos del Mod:**
```
DecryptSkillSys/
├── 📄 mod.info (metadatos del mod)
├── 📁 media/
│   ├── 📁 lua/
│   │   ├── 📁 client/
│   │   │   ├── 📄 DecryptDrivesContextMenu.lua (1,007 líneas) ← MENÚ CONTEXTUAL
│   │   │   ├── 📄 MiniGameUI.lua (826 líneas) ← MINIJUEGO
│   │   │   ├── 📄 TimedActions/
│   │   │   │   └── 📄 LaptopFill.lua (acciones temporizadas)
│   │   │   └── 📄 ISUI/ (interfaz de usuario)
│   │   ├── 📁 server/ (lógica del servidor)
│   │   └── 📁 shared/
│   │       └── 📄 GVDrive_Utils.lua (utilidades compartidas)
│   ├── 📁 scripts/
│   │   └── 📄 GV_skilldrives.txt (72 USBs definidos)
│   ├── 📁 sandbox-options.txt (configuración sandbox)
│   └── 📁 textures/ (iconos y texturas)
```

---

## 🔗 **FLUJO TÉCNICO COMPLETO DEL SISTEMA**

### **1️⃣ DETECCIÓN DE LAPTOPS**
```lua
-- En DecryptDrivesContextMenu.lua
function DecryptDrivesContextMenu.createMenu(player, context, items)
    -- Busca laptops en el área del jugador
    local laptop = getLaptopNearby(player)

    if laptop and laptop:getHealth() > 0 then
        -- Crea menú contextual "Decrypt Drives"
        context:addOption("Decrypt Drives", player, function()
            openDecryptMenu(laptop, player)
        end)
    end
end
```

### **2️⃣ GENERACIÓN DEL MENÚ CONTEXTUAL**
```lua
-- Jerarquía de USBs por habilidad
USBs_DISPONIBLES = {
    ["Cooking"] = {Easy, Moderate, Expert},
    ["Aiming"] = {Easy, Moderate, Expert},
    ["Electricity"] = {Easy, Moderate, Expert},
    -- ... 21 habilidades más
}

function openDecryptMenu(laptop, player)
    -- Crea ventana con lista jerárquica
    -- Muestra health de laptop con icono visual
    -- Lista USBs organizados por habilidad
    -- Cada USB tiene: nombre, dificultad, tooltip
end
```

### **3️⃣ CONEXIÓN USB → MINIJUEGO**
```lua
-- Cuando jugador selecciona USB
function onUSBSelected(usbType, difficulty, player, laptop)
    -- 1. Determina configuración del minijuego
    local config = getMinigameConfig(difficulty)

    -- 2. Abre minijuego con configuración específica
    local minigame = MiniGame(30, 50) -- 30% ancho, 50% alto

    -- 3. Configura dificultad del minijuego
    setMinigameDifficulty(config)

    -- 4. Conecta resultado con sistema de experiencia
    connectMinigameResult(player, laptop, usbType, difficulty)
end

-- Configuración por dificultad
function getMinigameConfig(difficulty)
    return {
        ["Easy"] = {patterns = 1, sequence = 4},
        ["Moderate"] = {patterns = 2, sequence = 5},
        ["Expert"] = {patterns = 3, sequence = 6}
    }
end
```

### **4️⃣ INTEGRACIÓN DEL MINIJUEGO**
```lua
-- MiniGameUI.lua modificado para integración
function MiniGameWindow:new(x, y, width, height, player, usbType, difficulty)
    local o = ISPanel:new(x, y, width, height)
    -- ... configuración base ...

    -- NUEVO: Conexión con sistema de USBs
    o.usbType = usbType              -- "Cooking", "Aiming", etc.
    o.difficulty = difficulty         -- "Easy", "Moderate", "Expert"
    o.player = player                 -- Referencia al jugador
    o.laptop = laptop                 -- Referencia a laptop

    return o
end

-- Configuración automática por dificultad
function setMinigameDifficulty(config)
    DIFFICULTY_PATTERNS = config.patterns
    SEQUENCE_LENGTH = config.sequence
    DIFFICULTY_TEXT = "DIFICULTAD: " .. string.upper(config.difficulty)
end
```

### **5️⃣ RESULTADO DEL MINIJUEGO → EXPERIENCIA**
```lua
-- En onSequencePress() cuando completa o falla
function MiniGameWindow:onSequencePress(button)
    if btnIndex == self.sequence[self.currentIndex] then
        -- ✅ ÉXITO
        self:onSuccess()
    else
        -- ❌ FALLO
        self:onFailure()
    end
end

function MiniGameWindow:onSuccess()
    -- 1. Calcular XP usando fórmula del mod
    local xp = calculateXP(self.usbType, self.difficulty)

    -- 2. Otorgar XP al jugador
    self.player:getXp():AddXP(Perks[self.usbType], xp)

    -- 3. Cerrar minijuego
    self:onClose()

    -- 4. Mostrar mensaje de éxito
    self.player:Say("¡Éxito! +" .. xp .. " XP en " .. self.usbType)
end

function MiniGameWindow:onFailure()
    -- 1. Calcular daño a laptop
    local damage = calculateDamage(self.difficulty)

    -- 2. Aplicar daño a laptop
    self.laptop:setHealth(self.laptop:getHealth() - damage)

    -- 3. Cerrar minijuego
    self:onClose()

    -- 4. Mostrar mensaje de fallo
    self.player:Say("¡Falló! Laptop dañada -" .. damage .. "%")
end
```

### **6️⃣ FÓRMULAS TÉCNICAS DEL SISTEMA**

#### **Cálculo de Experiencia:**
```lua
function calculateXP(skillType, difficulty)
    -- 1. Obtener valores base de sandbox
    local minXP = SandboxVars.GVDrive.USB_Min_Experience or 25
    local maxXP = SandboxVars.GVDrive.USB_Max_Experience or 50

    -- 2. Generar valor aleatorio
    local baseXP = ZombRand(minXP, maxXP + 1)

    -- 3. Aplicar multiplicador por dificultad
    local multiplier = getDifficultyMultiplier(difficulty)
    local finalXP = math.floor(baseXP * multiplier)

    return finalXP
end

function getDifficultyMultiplier(difficulty)
    return {
        ["Easy"] = SandboxVars.GVDrive.Facil_Success_Bonus or 0.8,
        ["Moderate"] = SandboxVars.GVDrive.Moderado_Success_Bonus or 1.2,
        ["Expert"] = SandboxVars.GVDrive.Dificil_Success_Bonus or 1.5
    }[difficulty]
end
```

#### **Cálculo de Daño a Laptop:**
```lua
function calculateDamage(difficulty)
    local minDamage = getMinDamage(difficulty)
    local maxDamage = getMaxDamage(difficulty)

    return ZombRand(minDamage, maxDamage + 1)
end

function getMinDamage(difficulty)
    return {
        ["Easy"] = SandboxVars.GVDrive.Facil_Laptop_Damage_Min or 3,
        ["Moderate"] = SandboxVars.GVDrive.Moderado_Laptop_Damage_Min or 8,
        ["Expert"] = SandboxVars.GVDrive.Dificil_Laptop_Damage_Min or 15
    }[difficulty]
end
```

---

## 🔧 **CONFIGURACIÓN TÉCNICA DEL SISTEMA**

### **Opciones de Sandbox Requeridas:**
```lua
-- Experiencia base
GVDrive.USB_Min_Experience (25-50 default)
GVDrive.USB_Max_Experience (25-50 default)

-- Multiplicadores por dificultad
GVDrive.Facil_Success_Bonus (0.8 default)
GVDrive.Moderado_Success_Bonus (1.2 default)
GVDrive.Dificil_Success_Bonus (1.5 default)

-- Daño a laptop por dificultad
GVDrive.Facil_Laptop_Damage_Min (3 default)
GVDrive.Facil_Laptop_Damage_Max (5 default)
GVDrive.Moderado_Laptop_Damage_Min (8 default)
GVDrive.Moderado_Laptop_Damage_Max (12 default)
GVDrive.Dificil_Laptop_Damage_Min (15 default)
GVDrive.Dificil_Laptop_Damage_Max (20 default)
```

### **Habilidades Soportadas (24 total):**
```lua
SKILLS = {
    "Woodwork", "Electricity", "Farming", "Aiming", "Cooking",
    "Sneak", "Axe", "Fitness", "Doctor", "Survivalist",
    "Mechanics", "Tailoring", "Maintenance", "SmallBlade", "LongBlade",
    "SmallBlunt", "LongBlunt", "Spear", "Trapping", "Fishing",
    "Sprinting", "Strength", "Nimble", "Lightfoot"
}
```

---

## 📊 **ESTADO ACTUAL DEL SISTEMA**

### **✅ Componentes Implementados:**
- ✅ **72 USBs definidos** (24 habilidades × 3 dificultades)
- ✅ **Minijuego funcional** (826 líneas, validado)
- ✅ **Menú contextual** (1,007 líneas, funcional)
- ✅ **Sistema de laptop** (health, daño, reparación)
- ✅ **Configuración sandbox** (parcial)

### **❌ Componentes Faltantes:**
- ❌ **Integración técnica** entre menú y minijuego
- ❌ **Fórmulas de XP y daño** implementadas
- ❌ **Conexión con sistema de experiencia** del juego
- ❌ **Gestión de estado de laptop** persistente

### **🔄 Próximos Pasos Técnicos:**
1. **Implementar conexión** USB → configuración minijuego
2. **Crear fórmulas** de XP y daño en GVDrive_Utils.lua
3. **Modificar MiniGameUI.lua** para aceptar parámetros
4. **Conectar resultado** minijuego con experiencia del jugador
5. **Implementar daño** a laptop por fallo

---

## 🎯 **FLUJO TÉCNICO COMPLETO**

```
1. JUGADOR encuentra LAPTOP en el mundo
2. CLICK DERECHO → Menú "Decrypt Drives"
3. SELECCIONA USB por HABILIDAD y DIFICULTAD
4. SE ABRE MINIJUEGO con configuración específica
5. RESULTADO MINIJUEGO:
   ✅ ÉXITO → XP = random(min,max) × bonus_dificultad
   ❌ FALLO → Daño = random(min_damage, max_damage)
6. ACTUALIZACIÓN de experiencia del jugador
7. ACTUALIZACIÓN de health de laptop
```

**¿Esta comprensión técnica es lo que estabas buscando? ¿Quieres que profundice en algún componente específico del sistema?**
