# MiniGameFallout: Ajuste Dinámico de Layout de Palabras

- Fecha/Hora: 2025-10-04 00:00
- Autor: Codex (AI)
- Archivo afectado: `Contents/mods/DecryptSkillSys/42.0/media/lua/client/MiniGameFallout.lua`

## Descripción del cambio

Se agregó un recalculo dinámico del layout para los botones de palabras del minijuego estilo Fallout. Antes, al aumentar la cantidad de palabras, la lista quedaba pegada a la parte superior y se generaba un gran espacio vacío hasta los botones de acción (START/DECODE). Ahora, la lista se distribuye verticalmente para ocupar el alto disponible de la ventana.

## Justificación técnica

- La creación original de botones usaba un `startY` fijo y un `buttonHeight` precomputado con `wordCount` total, sin considerar las filas reales por columna ni el espacio reservado superior/inferior.
- Se añadió una función `MiniGameFalloutWindow:layoutWordButtons()` que:
  - Calcula un área útil: `topReserved` (título/hint) y `bottomReserved` (botones/estado), y reparte el espacio restante.
  - Ajusta dinámicamente `buttonHeight` y `buttonSpacing` en base a `wordsPerColumn`.
  - Reposiciona y redimensiona todos los botones de palabras para llenar el alto disponible en dos columnas.
  - Reubica START/DECODE para mantenerlos alineados sobre el margen inferior reservado.
- La llamada se ejecuta una sola vez desde `render()` tras inicializar el panel, evitando modificar el bloque original de `createChildren()` (que contiene caracteres especiales sensibles a codificación en algunos entornos).

## Cambios principales

- Nuevo método: `MiniGameFalloutWindow:layoutWordButtons()`
- Inserción en `render()` para invocación única post-inicialización:
  ```lua
  if not self._layoutAdjusted then
      if self.layoutWordButtons then self:layoutWordButtons() end
      self._layoutAdjusted = true
  end
  ```

## Impacto esperado

- La lista de palabras se adapta correctamente al alto de la ventana, eliminando espacios vacíos.
- Mejor legibilidad y consistencia visual con cualquier cantidad de palabras configurada.

## Notas

- No se alteró la lógica del juego ni el ciclo de estados; solo el layout.
- Evitamos reescritura directa del cuerpo de `createChildren()` para minimizar riesgos de codificación en Windows/PowerShell.

