# ISSUE-005: Minigame Framework Base - Sistema de Minijuegos Interactivos

## Fecha
2025-09-22

## Estado
📋 PENDIENTE - Diseño aprobado, listo para implementación

## Severidad
ALTA - Feature principal del mod, requiere arquitectura sólida

## Descripción del Problema
El mod actual carece de sistema de minijuegos interactivos. Los USB drives actualmente solo otorgan experiencia de forma pasiva. Necesitamos un framework base que permita crear minijuegos escalables por dificultad que otorguen experiencia y puedan dañar laptops al fallar.

## Objetivos
- ✅ Crear sistema de UI modal para minijuegos
- ✅ Implementar sistema de timers para diferentes fases del juego
- ✅ Desarrollar MinigameController que gestione estados y comunicación
- ✅ Sistema desacoplado para otorgar XP y aplicar daño
- ✅ Variables SANDBOXVARS para configuración de XP y daño por dificultad
- ✅ Framework extensible para múltiples tipos de minijuegos

## Arquitectura Propuesta
```
MinigameSystem/
├── MinigameController.lua          # Orquestador principal
├── UI/
│   ├── MinigameWindow.lua          # Ventana modal base
│   └── components/                 # Componentes reutilizables
├── Utils/
│   ├── TimerSystem.lua             # Sistema de timers
│   ├── DifficultyScaler.lua        # Escalado por dificultad
│   └── FeedbackSystem.lua          # Efectos visuales/sonido
└── Config/
    └── MinigameConfig.lua          # Configuración centralizada
```

## Variables SANDBOXVARS Nuevas Requeridas
```lua
-- Multiplicadores de XP por dificultad de minijuego
GVDrive.Minigame_Easy_XP_Multiplier = 1.1
GVDrive.Minigame_Moderate_XP_Multiplier = 1.25
GVDrive.Minigame_Expert_XP_Multiplier = 1.5

-- Límites de tiempo por dificultad
GVDrive.Minigame_Easy_Time_Limit = 0        -- 0 = ilimitado
GVDrive.Minigame_Moderate_Time_Limit = 12
GVDrive.Minigame_Expert_Time_Limit = 8

-- Configuración de UI
GVDrive.Minigame_Window_Width = 400
GVDrive.Minigame_Window_Height = 300
GVDrive.Minigame_Auto_Close_Success = 3     -- segundos
GVDrive.Minigame_Auto_Close_Fail = 2        -- segundos
```

## API del Framework
```lua
-- Lanzar minijuego
MinigameController.launchMinigame({
    gameType = "sequence_breaker",           -- Tipo de minijuego
    difficulty = "Easy",                     -- Dificultad del drive
    skill = "Farming",                       -- Habilidad a entrenar
    player = player,                         -- Jugador
    laptop = laptopItem,                     -- Laptop que puede dañarse
    onSuccess = function(xpGained) ... end,  -- Callback de éxito
    onFailure = function(damage) ... end     -- Callback de fallo
})

-- Sistema de timers
TimerSystem.startTimer(duration, callback)
TimerSystem.cancelTimer(timerId)

-- Sistema de feedback
FeedbackSystem.showSuccess(message, duration)
FeedbackSystem.showFailure(message, duration)
FeedbackSystem.playSound(soundType)
```

## Estados del Minijuego
1. **LOADING**: Inicialización y preparación
2. **SHOWING_PATTERN**: Mostrando secuencia/patrón al jugador
3. **PLAYER_INPUT**: Esperando input del jugador
4. **VALIDATING**: Verificando si el input es correcto
5. **SUCCESS**: Minijuego completado exitosamente
6. **FAILURE**: Minijuego fallado
7. **ABANDONED**: Jugador cerró la ventana

## Comunicación con Sistemas Existentes
- **DecryptDrivesContextMenu**: Pasa datos de dificultad y skill
- **LaptopSystem**: Aplica daño por fallos
- **GVDrive_Utils**: Calcula experiencia ganada
- **SANDBOXVARS**: Configuración de rangos y multiplicadores

## Criterios de Aceptación
- [ ] MinigameController puede lanzar minijuegos con diferentes dificultades
- [ ] Sistema de timers funciona correctamente
- [ ] UI modal se muestra y se cierra apropiadamente
- [ ] Callbacks de éxito/fallo funcionan con XP y daño
- [ ] Variables SANDBOXVARS nuevas agregadas y funcionales
- [ ] Sistema extensible para agregar nuevos minijuegos
- [ ] Debug logging completo para troubleshooting

## Riesgos y Mitigaciones
- **Riesgo**: UI modal puede interferir con otros sistemas de PZ
  - **Mitigación**: Usar ISModalDialog como base, probar extensivamente
- **Riesgo**: Timers pueden causar memory leaks
  - **Mitigación**: Sistema de cleanup automático, referencias débiles
- **Riesgo**: Estados del juego pueden corromperse
  - **Mitigación**: State machine robusta con validaciones

## Dependencias
- LaptopSystem (ya implementado)
- GVDrive_Utils (ya implementado)
- DecryptDrivesContextMenu (ya implementado)

## Estimación de Esfuerzo
- **Complejidad**: Alta (nueva arquitectura de UI)
- **Tiempo estimado**: 2-3 días de desarrollo
- **Testing**: Extensivo (UI, timers, estados, edge cases)

## Próximos Pasos
1. Implementar MinigameController base
2. Crear sistema de UI modal
3. Implementar TimerSystem
4. Agregar variables SANDBOXVARS
5. Testing integrado con menú contextual
6. ISSUE-006: Sequence Breaker Minigame</content>
<parameter name="filePath">c:\Users\joshg\Zomboid42\Workshop\DecryptUSBs42\logs\ISSUE-005_MINIGAME_FRAMEWORK_BASE.md