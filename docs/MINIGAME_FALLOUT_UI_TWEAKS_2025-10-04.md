# MiniGameFallout: Separación de botones y flujo START→DECODE

- Fecha/Hora: 2025-10-04 00:20
- Autor: Codex (AI)
- Archivo afectado: `Contents/mods/DecryptSkillSys/42.0/media/lua/client/MiniGameFallout.lua`

## Descripción del cambio

1) Se redujo la separación vertical entre botones de palabras y se aumentó el margen superior del área de juego para que no se superponga con el título y "LAST HINT".
2) Se unificó el flujo de acción: el botón START se oculta al comenzar y aparece un botón DECODE en su misma posición (centrado). DECODE permanece deshabilitado hasta que se seleccione una palabra.

## Justificación técnica

- `layoutWordButtons()` ahora usa `topReserved = 95` y un `buttonSpacing` por defecto de `8` para compactar filas y dejar aire con el encabezado.
- Los botones START y DECODE se reposicionan en el centro: el método establece `X/Y/Width` y visibilidad en función de `self.gameActive`.
- `updateActionButtons()` controla visibilidad/habilitación: START visible cuando no hay juego activo; DECODE visible solo durante el juego y habilitado al seleccionar una palabra.
- `onStart()` oculta START y fuerza que DECODE sea visible pero deshabilitado inicialmente.

## Impacto esperado

- Sin solapamientos con el título/Hint y menor espacio entre filas.
- Flujo más claro: START → DECODE (en el mismo lugar), consistente con la UI de la imagen de referencia.

## Notas

- No se modificó la lógica de cálculo de palabras ni de pistas, solo la presentación y control de botones.
- Si se requiere recalcular layout en cambios de tamaño de ventana, puede invocarse `layoutWordButtons()` desde un handler de `OnResize`.

