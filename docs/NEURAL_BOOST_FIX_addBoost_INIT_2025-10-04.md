# NeuralBoostSystem: Fix "Object tried to call nil in addBoost"

- Fecha/Hora: 2025-10-04 00:40
- Autor: Codex (AI)
- Archivos: `Contents/mods/DecryptSkillSys/42.0/media/lua/shared/NeuralBoostSystem.lua`

## Descripción del cambio

El error se producía al finalizar/activar minijuegos cuando `NeuralBoostSystem.addBoost()` invocaba `shouldPrintWarning()` antes de que éste fuera definido (la función estaba al final del archivo como `local`). En Lua, las funciones locales no existen hasta que la asignación se ejecuta; si `addBoost()` se llama antes, el upvalue es `nil` y se lanza el error.

Se movió la implementación de `shouldPrintWarning()` (y su estado `lastWarningTime`/`WARNING_COOLDOWN`) al inicio del archivo, justo después de inicializar `NeuralBoostSystem`, para que esté disponible para cualquier llamada temprana a `addBoost()`.

## Justificación técnica

- Evita referencias a funciones locales no inicializadas durante el tiempo de carga.
- No cambia la API pública ni la lógica de los boosts; sólo reordena utilidades.

## Impacto esperado

- El error "Object tried to call nil in addBoost" desaparece al terminar/ganar/fallar minijuegos.
- Logs mantienen el throttling de advertencias sin spam.

