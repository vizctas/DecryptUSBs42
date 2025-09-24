# 🔧 **SISTEMA DE CONFIGURACIÓN DE DIFICULTAD EQUILIBRADO**

## 📊 **ESCALA DE DIFICULTAD EQUILIBRADA**

### **🎯 Parámetros por Dificultad:**

| Dificultad | Patrones | Secuencia | Delay | Descripción |
|------------|----------|-----------|--------|-------------|
| **EASY** | 1 | 4 | 40 | Solo verde, lento, corto |
| **MODERATE** | 2 | 5 | 30 | Verde+Rojo, medio, medio |
| **EXPERT** | 3 | 6 | 25 | Verde+Rojo+Azul, rápido, largo |

### **⚙️ Configuración Técnica:**

```lua
-- ========== CONFIGURACIÓN DEL GRID ==========
-- GRID FIJO (NO TOCAR)
local GRID_ROWS = 4           -- MANTENER FIJO
local GRID_COLS = 4           -- MANTENER FIJO
local BUTTON_SIZE = 12        -- MANTENER FIJO
local RESULT_DISPLAY_TIME = 60 -- MANTENER FIJO

-- ========== CONFIGURACIÓN DE DIFICULTAD ==========
-- SE AJUSTA AUTOMÁTICAMENTE SEGÚN DIFICULTAD DEL USB
local SEQUENCE_LENGTH = 4     -- Se configura automáticamente
local SEQUENCE_DELAY = 40     -- Se configura automáticamente
local DIFFICULTY_PATTERNS = 1 -- Se configura automáticamente
local DIFFICULTY_TEXT = "DIFFICULTY: EASY" -- Se configura automáticamente
-- =============================================
```

### **🔧 Función de Configuración Automática:**

```lua
-- Función para configurar minijuego según dificultad del USB
function configureMinigameDifficulty(difficulty)
    local config = getDifficultyConfig(difficulty)

    -- Aplicar configuración
    SEQUENCE_LENGTH = config.sequenceLength
    SEQUENCE_DELAY = config.delay
    DIFFICULTY_PATTERNS = config.patterns
    DIFFICULTY_TEXT = config.displayText

    print(string.format("MiniGame: Configured for %s - Patterns: %d, Length: %d, Delay: %d",
        difficulty, config.patterns, config.sequenceLength, config.delay))
end

-- Configuración equilibrada por dificultad
function getDifficultyConfig(difficulty)
    return {
        ["Easy"] = {
            patterns = 1,           -- Solo verde
            sequenceLength = 4,     -- 4 pasos
            delay = 40,             -- 2 segundos entre pasos
            displayText = "DIFFICULTY: EASY"
        },
        ["Moderate"] = {
            patterns = 2,           -- Verde + Rojo
            sequenceLength = 5,     -- 5 pasos
            delay = 30,             -- 1.5 segundos entre pasos
            displayText = "DIFFICULTY: MODERATE"
        },
        ["Expert"] = {
            patterns = 3,           -- Verde + Rojo + Azul
            sequenceLength = 6,     -- 6 pasos
            delay = 25,             -- 1.25 segundos entre pasos
            displayText = "DIFFICULTY: EXPERT"
        }
    }[difficulty] or getDifficultyConfig("Easy") -- Fallback a Easy
end
```

### **🎮 Experiencia de Juego por Dificultad:**

#### **🟢 EASY (Principiante):**
```
✅ Solo 1 patrón (VERDE)
✅ 4 pasos de secuencia
✅ 2 segundos entre cada paso
✅ Tiempo total: ~8 segundos para ver secuencia
✅ Distractores: Ninguno
✅ Tasa de éxito esperada: 90%+
✅ Objetivo: Aprender la mecánica
```

#### **🟡 MODERATE (Intermedio):**
```
⚠️ 2 patrones (VERDE correcto + ROJO distractor)
⚠️ 5 pasos de secuencia
⚠️ 1.5 segundos entre cada paso
⚠️ Tiempo total: ~7.5 segundos para ver secuencia
⚠️ Distractores: 1 patrón que confunde
⚠️ Tasa de éxito esperada: 60-70%
⚠️ Objetivo: Desarrollar atención selectiva
```

#### **🔴 EXPERT (Avanzado):**
```
❌ 3 patrones (VERDE correcto + ROJO + AZUL distractores)
❌ 6 pasos de secuencia
❌ 1.25 segundos entre cada paso
❌ Tiempo total: ~7.5 segundos para ver secuencia
❌ Distractores: 2 patrones que confunden
❌ Tasa de éxito esperada: 30-40%
❌ Objetivo: Máximo desafío cognitivo
```

### **⚖️ Equilibrio de Dificultad:**

#### **✅ LO QUE HACE DIFÍCIL:**
- **Más patrones distractores** (atención dividida)
- **Secuencias más largas** (memoria de trabajo)
- **Ritmo más rápido** (menos tiempo de procesamiento)

#### **✅ LO QUE MANTIENE JUGABLE:**
- **Grid fijo 4x4** (tamaño manejable)
- **Colores distintos** (fácil identificación)
- **Delays mínimos** (no imposible)
- **Progreso visual** (feedback claro)

### **📈 Progresión de Dificultad:**

```lua
-- EASY → MODERATE → EXPERT
-- Dificultad: 1 → 2 → 3 (x2, x3 distractores)
-- Longitud: 4 → 5 → 6 (25% → 50% más larga)
-- Velocidad: 40 → 30 → 25 (37% → 62% más rápido)

-- Progresión equilibrada:
-- Cada nivel aumenta ~30-40% la dificultad
-- Sin llegar a ser frustrante o imposible
```

### **🎯 Integración con el Sistema:**

```lua
-- En DecryptDrivesContextMenu.lua
function onUSBSelected(usbType, difficulty, player, laptop)
    -- 1. Configurar minijuego automáticamente
    configureMinigameDifficulty(difficulty)

    -- 2. Crear ventana con configuración
    local window = MiniGameWindow:new(x, y, width, height, player, usbType, difficulty)
    window:initialise()
    window:addToUIManager()

    -- 3. El minijuego ya tiene la configuración aplicada
    -- SEQUENCE_LENGTH, SEQUENCE_DELAY, DIFFICULTY_PATTERNS ya configurados
end
```

### **📊 Resultado Final:**

```lua
-- EASY: 4 pasos, 2s entre cada uno, solo verde
-- MODERATE: 5 pasos, 1.5s entre cada uno, verde+rojo
-- EXPERT: 6 pasos, 1.25s entre cada uno, verde+rojo+azul

-- Progresión equilibrada que desafía sin frustrar
-- Grid fijo mantiene consistencia visual
-- Dificultad aumenta gradualmente en múltiples dimensiones
```

**¿Esta configuración equilibrada es lo que estabas buscando? ¿Quieres ajustar los valores específicos de delay o longitud de secuencia?**
