# Safe HaloText Calls Across Systems

- Fecha/Hora: 2025-10-04 01:15
- Autor: Codex (AI)
- Archivos:
  - `Contents/mods/DecryptSkillSys/42.0/media/lua/shared/USBSurpriseSystem.lua`
  - `Contents/mods/DecryptSkillSys/42.0/media/lua/shared/DynamicSoundSystem.lua` (solo referencia en workflow)

## Descripción del cambio

Se implementó una función envolvente segura (`SafeHaloText`) en `USBSurpriseSystem.lua` para proteger llamadas a `HaloTextHelper.addText`. En Build 42 algunas firmas de la API pueden cambiar o no estar disponibles en ciertos contextos, provocando errores como:

- `No implementation found for function: addText(... Survival Tip Received! ...)`

La función segura intenta varias firmas con `pcall`, y si no logra dibujar halo text, hace fallback a `player:Say(text)` sin lanzar excepción.

## Detalles técnicos

- Se añadió `SafeHaloText(player, text, color)` en la cabecera de `USBSurpriseSystem.lua`.
- Reemplazos puntuales de `HaloTextHelper.addText(...)` por `SafeHaloText(...)` en:
  - Receta desbloqueada
  - Survival tip
  - Map complete
  - Fragmento de mapa
  - Bonus XP
  - Rare item

## Impacto esperado

- Evita crasheos al finalizar minijuegos (Encryption/Fallout) que activan sorpresas.
- No bloquea la entrega de XP ni el cierre de ventanas.

