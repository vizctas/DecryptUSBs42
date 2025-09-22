# ISSUE-006: Sequence Breaker Minigame - "Sigue el Patrón"

## Fecha
2025-09-22

## Estado
📋 PENDIENTE - Esperando ISSUE-005

## Severidad
MEDIA - Primer minijuego concreto, valida el framework

## Descripción del Problema
Implementar el primer minijuego interactivo: "Sequence Breaker" (sigue el patrón). Este minijuego debe escalar en dificultad según el drive seleccionado y validar que todo el framework de minijuegos funcione correctamente.

## Escalado por Dificultad

### Easy Mode
- **Botones**: 4 botones coloreados (Rojo, Azul, Verde, Amarillo)
- **Longitud de secuencia**: 4 elementos
- **Tiempo de muestra**: 6 segundos
- **Tiempo límite**: Ilimitado
- **Pistas**: 1 pista visual (flecha indicando próximo botón)
- **Recompensa XP**: Base × 1.1

### Moderate Mode
- **Botones**: 4 botones coloreados
- **Longitud de secuencia**: 5 elementos
- **Tiempo de muestra**: 4 segundos
- **Tiempo límite**: 12 segundos
- **Pistas**: Sin pistas visuales
- **Recompensa XP**: Base × 1.25

### Expert Mode
- **Botones**: 4 botones coloreados
- **Longitud de secuencia**: 6 elementos
- **Tiempo de muestra**: 3 segundos
- **Tiempo límite**: 8 segundos
- **Pistas**: Sin pistas, con distracciones visuales (botones parpadean aleatoriamente)
- **Recompensa XP**: Base × 1.5

## Flujo del Minijuego

### Fase 1: Inicialización (2 segundos)
- Aparece ventana modal con título "Decrypt Sequence"
- Muestra "Preparando secuencia..." con animación de carga
- Genera secuencia aleatoria según dificultad

### Fase 2: Mostrando Patrón (3-6 segundos según dificultad)
- Botones se iluminan en secuencia
- Sonido de beep por cada botón
- Si hay pistas, muestra flecha indicando próximo
- En Expert: botones aleatorios parpadean como distracción

### Fase 3: Input del Jugador
- Botones se activan para click
- Jugador debe repetir la secuencia exacta
- Timer cuenta regresivamente (según dificultad)
- Feedback visual inmediato por cada click correcto/incorrecto

### Fase 4: Validación
- Verifica si la secuencia completa es correcta
- Si correcta: SUCCESS → otorga XP → cierra en 3s
- Si incorrecta: FAILURE → daña laptop → cierra en 2s
- Si timeout: FAILURE → daña laptop → cierra en 2s

### Fase 5: Resultado
- **Éxito**: "¡Secuencia completada!" + partículas verdes + sonido victory
- **Fallo**: "Secuencia incorrecta" + screen shake + sonido error
- Auto-cierre con timer

## UI/UX Design

### Layout de la Ventana
```
+-------------------------------+
| 🔐 DECRYPT SEQUENCE - [DIFICULTAD] |
+-------------------------------+
|                               |
|     [🔴] [🔵] [🟢] [🟡]       |
|                               |
|     [STATUS MESSAGE]          |
|                               |
|     [TIMER: 12s]              |
|                               |
|     [❌ CLOSE]                 |
+-------------------------------+
```

### Estados Visuales
- **Botones inactivos**: Opacos, sin hover
- **Botón activo en patrón**: Glow effect + sonido
- **Botón clickeado correctamente**: Checkmark verde temporal
- **Botón clickeado incorrectamente**: X roja + shake
- **Timer warning**: Texto rojo cuando quedan < 3 segundos

## Sistema de Sonido
- **Botón rojo**: Beep bajo (C4)
- **Botón azul**: Beep medio (E4)
- **Botón verde**: Beep alto (G4)
- **Botón amarillo**: Beep muy alto (C5)
- **Éxito**: Arpegio ascendente
- **Fallo**: Descendente disonante
- **Timeout**: Tick-tock urgente

## Lógica de Juego

### Generación de Secuencia
```lua
function SequenceBreaker:generateSequence()
    local colors = {"red", "blue", "green", "yellow"}
    local length = self:getSequenceLengthForDifficulty()
    self.sequence = {}

    for i = 1, length do
        local randomColor = colors[ZombRand(1, #colors + 1)]
        table.insert(self.sequence, randomColor)
    end
end
```

### Validación de Input
```lua
function SequenceBreaker:validateInput()
    if #self.playerInput ~= #self.sequence then
        return false
    end

    for i, input in ipairs(self.playerInput) do
        if input ~= self.sequence[i] then
            return false
        end
    end

    return true
end
```

## Integración con Framework
- Usa `MinigameController.launchMinigame()` con `gameType = "sequence_breaker"`
- Implementa callbacks `onSuccess(xpGained)` y `onFailure(damage)`
- Usa `TimerSystem` para todas las fases temporizadas
- Usa `FeedbackSystem` para efectos visuales y sonido

## Archivos a Crear
- `media/lua/client/MinigameSystem/UI/SequenceBreaker.lua`
- `media/lua/client/MinigameSystem/Config/SequenceBreakerConfig.lua`
- Texturas: `media/textures/ui/minigames/sequence_breaker/`

## Testing Cases
- [ ] Easy mode: completar secuencia otorga XP correcto
- [ ] Moderate mode: timeout causa daño correcto
- [ ] Expert mode: secuencia incorrecta causa daño correcto
- [ ] Abandono (cerrar ventana): causa daño igual que fallo
- [ ] Múltiples intentos en secuencia
- [ ] Edge case: clicks muy rápidos
- [ ] Edge case: spam clicks

## Métricas de Balance Esperadas
- **Easy**: 85% tasa de éxito, XP moderado
- **Moderate**: 65% tasa de éxito, XP bueno
- **Expert**: 45% tasa de éxito, XP excelente

## Dependencias
- ISSUE-005: Minigame Framework Base (debe completarse primero)

## Estimación de Esfuerzo
- **Complejidad**: Media (primera implementación concreta)
- **Tiempo estimado**: 1-2 días
- **Testing**: Moderado (lógica de secuencia, timers, UI)

## Próximos Pasos
Después de validar que Sequence Breaker funciona perfectamente con todo el framework (XP, daño, UI, timers, efectos), proceder con:
- ISSUE-007: Code Matrix Minigame
- ISSUE-008: Memory Decrypt Minigame</content>
<parameter name="filePath">c:\Users\joshg\Zomboid42\Workshop\DecryptUSBs42\logs\ISSUE-006_SEQUENCE_BREAKER_MINIGAME.md