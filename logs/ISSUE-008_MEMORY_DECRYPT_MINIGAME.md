# ISSUE-008: Memory Decrypt Minigame - Memoria Visual

## Fecha
2025-09-22

## Estado
📋 PENDIENTE - Esperando ISSUE-007

## Severidad
MEDIA - Tercer y último minijuego base

## Descripción del Problema
Implementar "Memory Decrypt": un minijuego de memoria visual donde el jugador debe recordar y emparejar cartas, escalando en complejidad según la dificultad del drive.

## Escalado por Dificultad

### Easy Mode
- **Cartas totales**: 6 cartas (3 parejas)
- **Tiempo de muestra**: 15 segundos
- **Tiempo límite**: 30 segundos
- **Pistas**: Colores de fondo indican parejas
- **Recompensa XP**: Base × 1.1

### Moderate Mode
- **Cartas totales**: 8 cartas (4 parejas)
- **Tiempo de muestra**: 10 segundos
- **Tiempo límite**: 25 segundos
- **Pistas**: Sin pistas de color
- **Recompensa XP**: Base × 1.25

### Expert Mode
- **Cartas totales**: 10 cartas (5 parejas)
- **Tiempo de muestra**: 8 segundos
- **Tiempo límite**: 20 segundos
- **Pistas**: Sin pistas, cartas falsas aleatorias
- **Recompensa XP**: Base × 1.5

## Mecánica de Juego

### Fase 1: Preparación
- Cartas se generan con símbolos únicos por pareja
- En Easy: parejas tienen colores de fondo distintivos
- En Expert: 1-2 cartas falsas que no tienen pareja

### Fase 2: Mostrando Cartas (8-15 segundos)
- Todas las cartas se muestran boca arriba
- Jugador debe memorizar posiciones y símbolos
- Timer cuenta regresivamente
- En Easy: glow effects en parejas del mismo color

### Fase 3: Juego de Memoria
- Cartas se voltean boca abajo
- Jugador clickea para voltear cartas
- Al voltear dos cartas:
  - Si coinciden: permanecen boca arriba, pareja completada
  - Si no coinciden: se voltean de nuevo después de 1 segundo
- Timer general cuenta regresivamente

### Fase 4: Validación
- **Éxito**: Todas las parejas encontradas antes del timeout
- **Fallo**: Timeout alcanzado o cartas falsas seleccionadas incorrectamente

## Símbolos de Cartas
- **Tecnológicos**: 💿 💾 🖥️ 🖱️ ⌨️ 🔌 🔋
- **Abstractos**: 🔷 🔶 🔴 🔵 🟢 🟡 🟠 🟣
- **Especiales**: ❓ (carta falsa en Expert)

## UI/UX Design

### Layout de la Ventana
```
+-------------------------------+
| 🧠 MEMORY DECRYPT - [DIFICULTAD] |
+-------------------------------+
|                               |
|   [🖥️] [💿] [🔋] [❓]        |
|   [⌨️] [🖱️] [🔌] [💾]        |
|   [🔷] [🔶]                   |
|                               |
|   [PAIRS: 2/4] [TIMER: 25s]   |
|                               |
|     [❌ CLOSE]                 |
+-------------------------------+
```

### Estados Visuales
- **Carta boca abajo**: Símbolo ❓, hover effect
- **Carta volteada**: Símbolo visible, borde azul
- **Pareja correcta**: Glow verde, permanece visible
- **Pareja incorrecta**: Shake rojo, se voltea de nuevo
- **Carta falsa**: Al seleccionar, efecto de error

## Sistema de Sonido
- **Voltear carta**: Click suave
- **Pareja correcta**: Ding positivo
- **Pareja incorrecta**: Boop negativo
- **Carta falsa**: Error sonoro
- **Éxito**: Fanfare de victoria
- **Fallo**: Descendente de derrota

## Lógica de Juego

### Generación de Cartas
```lua
function MemoryDecrypt:generateCards()
    local symbols = {"💿", "💾", "🖥️", "🖱️", "⌨️", "🔌", "🔋", "🔷", "🔶", "🔴"}
    local pairCount = self:getPairCountForDifficulty()
    local hasFakeCards = (self.difficulty == "Expert")

    self.cards = {}
    self.pairs = {}

    -- Crear parejas
    for i = 1, pairCount do
        local symbol = symbols[i]
        table.insert(self.pairs, {symbol, symbol})
    end

    -- Agregar cartas falsas en Expert
    if hasFakeCards then
        table.insert(self.pairs, {"❓"}) -- Carta sin pareja
    end

    -- Barajar posiciones
    self:shuffleCards()
end
```

### Lógica de Volteo
```lua
function MemoryDecrypt:onCardClick(cardIndex)
    if self.flippedCards >= 2 then return end

    local card = self.cards[cardIndex]
    if card.isFlipped or card.isMatched then return end

    card.isFlipped = true
    self.flippedCards = self.flippedCards + 1
    table.insert(self.currentFlipped, cardIndex)

    if self.flippedCards == 2 then
        self:checkForMatch()
    end
end

function MemoryDecrypt:checkForMatch()
    local card1 = self.cards[self.currentFlipped[1]]
    local card2 = self.cards[self.currentFlipped[2]]

    if card1.symbol == card2.symbol and card1.symbol ~= "❓" then
        -- Pareja correcta
        card1.isMatched = true
        card2.isMatched = true
        self.matchedPairs = self.matchedPairs + 1

        if self.matchedPairs == self.totalPairs then
            self:gameWon()
        end
    else
        -- Pareja incorrecta o carta falsa
        TimerSystem.startTimer(1.0, function()
            card1.isFlipped = false
            card2.isFlipped = false
            self.flippedCards = 0
            self.currentFlipped = {}
        end)
    end
end
```

## Integración con Framework
- Extiende `MinigameController` con `gameType = "memory_decrypt"`
- Usa timers para fases de muestra y límite de juego
- Feedback visual para parejas correctas/incorrectas
- Sistema especial para cartas falsas en Expert

## Archivos a Crear
- `media/lua/client/MinigameSystem/UI/MemoryDecrypt.lua`
- `media/lua/client/MinigameSystem/Config/MemoryDecryptConfig.lua`
- Texturas: `media/textures/ui/minigames/memory_decrypt/`

## Testing Cases
- [ ] Easy mode: colores de pista ayudan en memorización
- [ ] Moderate mode: sin pistas, memoria pura
- [ ] Expert mode: cartas falsas causan fallo inmediato
- [ ] Timeout con parejas parcialmente completadas
- [ ] Múltiples intentos de volteo rápido
- [ ] Edge case: click en cartas ya emparejadas

## Balance Esperado
- **Easy**: 70% tasa de éxito, XP moderado
- **Moderate**: 50% tasa de éxito, XP bueno
- **Expert**: 30% tasa de éxito, XP excelente

## Dependencias
- ISSUE-005: Minigame Framework Base
- ISSUE-006: Sequence Breaker Minigame
- ISSUE-007: Code Matrix Minigame

## Estimación de Esfuerzo
- **Complejidad**: Media (lógica de memoria, estados de cartas)
- **Tiempo estimado**: 1-1.5 días
- **Testing**: Moderado (estados de cartas, lógica de parejas)

## Próximos Pasos
Una vez completados los 3 minijuegos base:
- ISSUE-009: Sistema de Rotación de Minijuegos
- ISSUE-010: Mejoras de Balance y UX
- ISSUE-011: Nuevos Minijuegos Adicionales (opcional)</content>
<parameter name="filePath">c:\Users\joshg\Zomboid42\Workshop\DecryptUSBs42\logs\ISSUE-008_MEMORY_DECRYPT_MINIGAME.md