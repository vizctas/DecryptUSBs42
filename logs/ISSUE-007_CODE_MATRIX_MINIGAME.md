# ISSUE-007: Code Matrix Minigame - Adivinanza Lógica

## Fecha
2025-09-22

## Estado
📋 PENDIENTE - Esperando ISSUE-006

## Severidad
MEDIA - Segundo minijuego, valida extensibilidad del framework

## Descripción del Problema
Implementar "Code Matrix": un minijuego de lógica donde el jugador debe identificar símbolos correctos en una matriz, escalando en complejidad según la dificultad del drive.

## Escalado por Dificultad

### Easy Mode
- **Matriz**: 3x3 (9 celdas)
- **Símbolos correctos**: 2 símbolos
- **Tiempo límite**: 15 segundos
- **Pistas**: Números indicando cantidad de símbolos correctos por fila/columna
- **Recompensa XP**: Base × 1.1

### Moderate Mode
- **Matriz**: 4x4 (16 celdas)
- **Símbolos correctos**: 3 símbolos
- **Tiempo límite**: 20 segundos
- **Pistas**: Pistas parciales (solo algunas filas/columnas)
- **Recompensa XP**: Base × 1.25

### Expert Mode
- **Matriz**: 5x5 (25 celdas)
- **Símbolos correctos**: 4 símbolos
- **Tiempo límite**: 25 segundos
- **Pistas**: Sin pistas numéricas
- **Recompensa XP**: Base × 1.5

## Mecánica de Juego

### Generación de Matriz
- **Símbolos disponibles**: 🔷 🔶 🔴 🔵 🟢 🟡 🟠 🟣
- **Patrón de símbolos correctos**: Generado aleatoriamente
- **Distribución**: Símbolos correctos colocados aleatoriamente en la matriz
- **Relleno**: Resto de celdas con símbolos aleatorios (pueden repetirse)

### Sistema de Pistas (Easy/Moderate)
- **Pistas de fila**: Número de símbolos correctos en cada fila
- **Pistas de columna**: Número de símbolos correctos en cada columna
- **Visual**: Números pequeños en bordes de matriz

### Input del Jugador
- **Selección**: Click en celdas para marcar/desmarcar
- **Validación**: Al presionar "Verify", compara selección con patrón correcto
- **Feedback**: Celdas correctas se iluminan verde, incorrectas roja

## UI/UX Design

### Layout de la Ventana
```
+-------------------------------+
| 🔍 CODE MATRIX - [DIFICULTAD]   |
+-------------------------------+
|  1 🔷 🔶 🔴  2                 |
|  0 🔵 🟢 🟡  1                 |
|  2 🟠 🟣 🔷  0                 |
|                               |
|     [VERIFY] [CLEAR]           |
|                               |
|     [TIMER: 15s]              |
|                               |
|     [❌ CLOSE]                 |
+-------------------------------+
```

### Estados Visuales
- **Celda normal**: Opaca, hover effect
- **Celda seleccionada**: Borde azul, ligeramente elevada
- **Celda correcta**: Glow verde al verificar
- **Celda incorrecta**: Shake rojo al verificar
- **Pistas**: Números grises en bordes

## Sistema de Sonido
- **Celda seleccionada**: Click suave
- **Verificación correcta**: Confirmación positiva
- **Verificación incorrecta**: Error negativo
- **Éxito**: Arpegio de victoria
- **Fallo**: Descendente de derrota

## Lógica de Juego

### Generación de Patrón
```lua
function CodeMatrix:generatePattern()
    local symbols = {"🔷", "🔶", "🔴", "🔵", "🟢", "🟡", "🟠", "🟣"}
    local matrixSize = self:getMatrixSizeForDifficulty()
    local correctCount = self:getCorrectCountForDifficulty()

    -- Generar patrón correcto
    self.correctPattern = {}
    for i = 1, correctCount do
        local symbol = symbols[ZombRand(1, #symbols + 1)]
        table.insert(self.correctPattern, symbol)
    end

    -- Colocar en matriz
    self.matrix = {}
    for row = 1, matrixSize do
        self.matrix[row] = {}
        for col = 1, matrixSize do
            if ZombRand(1, 101) <= 30 then -- 30% chance de símbolo correcto
                self.matrix[row][col] = self.correctPattern[ZombRand(1, #self.correctPattern + 1)]
            else
                self.matrix[row][col] = symbols[ZombRand(1, #symbols + 1)]
            end
        end
    end
end
```

### Validación
```lua
function CodeMatrix:validateSelection()
    local selectedCorrect = 0
    local totalCorrect = #self.correctPattern

    for _, selectedSymbol in ipairs(self.playerSelection) do
        for _, correctSymbol in ipairs(self.correctPattern) do
            if selectedSymbol == correctSymbol then
                selectedCorrect = selectedCorrect + 1
                break
            end
        end
    end

    return selectedCorrect == totalCorrect
end
```

## Integración con Framework
- Extiende `MinigameController` con `gameType = "code_matrix"`
- Usa sistema de timers para límite de tiempo
- Implementa feedback visual para celdas correctas/incorrectas
- Sistema de pistas opcional según dificultad

## Archivos a Crear
- `media/lua/client/MinigameSystem/UI/CodeMatrix.lua`
- `media/lua/client/MinigameSystem/Config/CodeMatrixConfig.lua`
- Texturas: `media/textures/ui/minigames/code_matrix/`

## Testing Cases
- [ ] Easy mode: identificación correcta otorga XP
- [ ] Moderate mode: pistas parciales funcionan
- [ ] Expert mode: sin pistas, tiempo límite estricto
- [ ] Selección múltiple y validación correcta
- [ ] Edge case: selección vacía
- [ ] Edge case: timeout con selección parcial

## Balance Esperado
- **Easy**: 75% tasa de éxito, XP moderado
- **Moderate**: 55% tasa de éxito, XP bueno
- **Expert**: 35% tasa de éxito, XP excelente

## Dependencias
- ISSUE-005: Minigame Framework Base
- ISSUE-006: Sequence Breaker Minigame (para validar framework)

## Estimación de Esfuerzo
- **Complejidad**: Media-Alta (lógica de matriz, pistas)
- **Tiempo estimado**: 1.5-2 días
- **Testing**: Moderado (lógica de validación, UI de matriz)

## Próximos Pasos
ISSUE-008: Memory Decrypt Minigame</content>
<parameter name="filePath">c:\Users\joshg\Zomboid42\Workshop\DecryptUSBs42\logs\ISSUE-007_CODE_MATRIX_MINIGAME.md