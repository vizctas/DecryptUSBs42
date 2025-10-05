# MiniGameEncryption: Separación vertical en HISTORY

- Fecha/Hora: 2025-10-04 00:45
- Autor: Codex (AI)
- Archivo: `Contents/mods/DecryptSkillSys/42.0/media/lua/client/MiniGameEncryption.lua`

## Descripción del cambio

Se ajustó la separación vertical del historial de intentos (HISTORY) para que los símbolos de feedback `O`/`X`/`-` queden claramente debajo de cada dígito y no colisionen con la siguiente línea de intentos.

## Detalles técnicos

- `attemptSpacing` incrementado de 35 a 45.
- Desplazamiento vertical del símbolo (`symbolYOffset`) incrementado de 15 a 18.

## Impacto esperado

- Lectura más clara del historial y evaluación visual correcta de cada intento.

