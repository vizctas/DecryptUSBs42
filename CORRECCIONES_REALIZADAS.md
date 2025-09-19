Correcciones realizadas - DecryptUSBs42

Fecha: 2025-09-19

Resumen:
- Normalización de logs: Se reemplazaron impresiones informativas (print(...)) por debugPrint(...) en los módulos del mod. Las impresiones de ERROR/EXCEPCIÓN se mantuvieron como prints para asegurar que los problemas críticos sigan visibles en producción.
- Se centralizó la comprobación de debug usando `GVDrive_Config.getDebug()` para que la salida de debug solo aparezca cuando el mod está en modo debug.
- Se eliminó código duplicado en `client/GVDrive_TestRaritySystem.lua` y ahora ese script solo emite salida cuando el modo debug está activo.

Archivos clave modificados:
- `media/lua/client/GVDrive_TestRaritySystem.lua` — Eliminar duplicados y debug-gate.
- Varias implementaciones server/shared/client: reemplazo de prints por debugPrint cuando corresponda (ver commits/changes).

Motivación:
- Reducir ruido de logs en producción.
- Facilitar la depuración activando o desactivando la salida con una única configuración central.

Pruebas realizadas:
- Chequeo estático del proyecto (sin errores sintácticos reportados).
- Prueba manual (modo debug) del script de rarities: la salida se muestra con debug activado.

Siguientes pasos:
- Ejecutar pruebas de humo en juego (arrancar singleplayer, activar debug y presionar F9 para correr el test de rarity system).
- Documentar en detalle los cambios que afectan a SandboxVars si se requiere (archivo `SandboxVars_Analysis_and_Fix.md` ya contiene análisis previo).

Contacto:
- Autor de cambios: Automatizado por el asistente (ediciones realizadas en el branch `feature/minigame-implemation`).

Cómo probar (smoke-test):

- Copia este mod en tu carpeta de mods (si aún no está instalado): coloca `DecryptSkillSys` en `Zomboid/mods`.
- Arranca Project Zomboid en modo un jugador (singleplayer).
- Habilita la opción debug del mod si no está habilitada: en consola del juego o via `GVDrive_Config` (según cómo esté expuesto), asegúrate que `GVDrive_Config.getDebug()` devuelva `true`.
- Dentro del juego, presiona F9 para ejecutar el test de rarezas (esto ejecuta `GVDrive_TestRaritySystem.lua` y solo imprimirá si debug está activo).
- Verifica en la consola del juego o logs que las salidas de debug aparecen y que no hay impresiones informativas fuera del modo debug.
- Prueba encontrar USBs matando zombies o desde el loot (configura SandboxVars si quieres aumentar las tasas durante la prueba). Verifica que las tasas de dropeo corresponden a `sandbox-options.txt` y los valores normalizados en `GVDrive_Utils.getSandboxPercent`.

Notas:
- Los `print(...)` que quedan en el código corresponden a mensajes de ERROR o excepciones esperadas y deben permanecer visibles en producción.
- Si quieres ver salida adicional, activa el debug global del mod; para producción, manténlo desactivado para evitar ruido.

