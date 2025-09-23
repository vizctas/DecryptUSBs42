QA / Certificación Checklist — DecryptUSBs42
=============================================

Fecha: 2025-09-19
Autor: GitHub Copilot (automatized)

Objetivo
--------
Proveer una lista reproducible de pasos para certificar que el mod DecryptUSBs42 está listo para publicación. Incluir smoke tests, sandbox tests, acceptance criteria, rollback instructions y hallazgos esperados.

Alcance
-------
- Código: todos los scripts bajo `Contents/mods/DecryptSkillSys/42.0/` y `shared/`.
- Datos: `scripts/*.txt`, `media/`, `textures/`.
- Entorno: Project Zomboid 42.x compatible.

Checklist
---------
1) Preparación
- [ ] Crear rama de prueba: `feature/working_state_v1` y empujar a remoto.
- [ ] Asegurar que `CHANGELOG.md` y `Documentation/QA-CHECKLIST.md` están incluidos en la rama.

2) Smoke tests (rápidos)
- [ ] Iniciar juego en modo Sandbox local.
- [ ] Cargar un personaje y abrir consola de distribución (spawn loot) cerca de una zona de computadoras/usbs.
- [ ] Confirmar que skilldrives aparecen en loot (registro mínimo de 5 drops por tipo) — ver `logs/loot_smoke_test.log`.
- [ ] Confirmar que no hay errores Lua en consola ni stacktraces.

3) Sandbox tests (automatizados/manuales)
- [ ] Correr simulación con sandbox options: `sandbox-options-testing.txt` y `sandbox-options.txt` backups.
- [ ] Verificar SandboxVars sólo contienen entradas necesarias para este mod (no keys redundantes).
- [ ] Ejecutar script de generación de ítems y comparar con `logs/items_catalog.json`.

4) Acceptance criteria
- [ ] No más de 2 non-critical warnings en carga.
- [ ] Ningún crash durante los primeros 10 minutos de juego.
- [ ] Skilldrives aparecen con probabilidad incrementada según `GVDistributions.lua`.
- [ ] Todos los `print()` han sido eliminados o redirigidos a `shared/GVDebug.lua`.

5) Rollback
- [ ] Si falla, revertir a rama `main` y restaurar archivos desde `logs/deleted_backups/`.
- [ ] Registrar incident en `logs/` y abrir issue `fix/<short-desc>`.

6) Reporting
- [ ] Llenar `logs/qa_report_<YYYYMMDD>.md` con resultados y evidencias (screenshots, logs).
- [ ] Actualizar `CHANGELOG.md` con la versión y notas de release.
- [ ] Marcar ticket como `CERTIFICATION` y pedir sign-off.

Notas técnicas
--------------
- Ejecutar con `-debug` activado para ver `GVDebug` si es necesario.
- Los logs se deben guardar en `logs/` y limpiarse periódicamente.

Pruebas sugeridas (comandos)
---------------------------
# Ejecutar smoke test manual:
# - Arrancar Project Zomboid
# - Cargar juego con sandbox-options-testing.txt
# - Recoger loot en 5 ubicaciones distintas y anotar drops

Checklist de aceptación final
----------------------------
- [ ] QA engineer sign-off
- [ ] Owner sign-off
- [ ] Docs actualizadas
- [ ] PR merged
