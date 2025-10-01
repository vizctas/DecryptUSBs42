# WORKFLOW - DecryptUSBs42 Project

## Registro de Cambios y Actividades

### 2025-09-30 20:45 - Sistema de Contador de Fallos - INTEGRACIÓN COMPLETA

**Estado anterior del código:** Contador de fallos no funcionaba en singleplayer
**Problema identificado:** `isClient()` devuelve `false` en singleplayer, bloqueando incremento
**Impacto esperado:** Contador funcional en SP y MP, base para eventos aleatorios futuros

#### Cambios realizados:

1. **GVDrive_Config.lua**
   - Timestamp: 2025-09-19 17:25
   - Cambio: Activado DEBUG de false a true
   - Justificación: Necesario para logs de diagnóstico del sistema de loot

2. **sandbox-options.txt**
   - Timestamp: 2025-09-19 17:28
   - Cambios realizados:
     * USB_ZombieDrop_Chance: 0.01% → 10% (default)
     * Laptop_ZombieDrop_Chance: 0.02% → 5% (default) 
     * EliteDrive_ZombieDrop_Chance: 0.01% → 2% (default)
     * Antivirus_ZombieDrop_Chance: 0.02% → 8% (default)
   - Justificación: Las probabilidades originales requerían matar 10,000 zombies para 1 drop promedio

3. **GV_ZombieLoot.lua**
   - Timestamp: 2025-09-19 17:30
   - Cambios:
     * Actualizados valores default en dropAttempts para coincidir con sandbox
     * Mejorado debugging con emojis para identificar ejecución del handler
   - Justificación: Sincronizar código con nuevas configuraciones de sandbox

4. **GV_Itemsdistro.lua**
   - Timestamp: 2025-09-19 17:20
   - Cambios: Agregados debugPrint en funciones de distribución de loot mundial
   - Justificación: Diagnóstico de inyección de items en world loot

5. **GV_skilldrives.txt**
   - Timestamp: 2025-09-19 17:15
   - Cambio: Corregido formato de DisplayName en SkillDrive_Woodwork_Facil
   - Justificación: Error de sintaxis impedía carga del item por ScriptManager

#### Problemas investigados:

- **Items "Facil" no aparecían:** Causado por error de formato en archivo de scripts
- **0 drops en 100 zombies muertos:** Causado por probabilidades de 0.01% (1 en 10,000)
- **Items MISSING en logs:** Relacionado con errores de sintaxis y carga de scripts

#### Estado actual del código: 
- **Estable** - Configuración de debugging activada
- **En pruebas** - Necesita verificación de drops con nuevas probabilidades

#### Próximas tareas:
- [ ] Verificar que los drops funcionen con las nuevas probabilidades (5-10 zombies de prueba)
- [ ] Confirmar que items "Facil" aparezcan correctamente en juego
- [ ] Ajustar probabilidades finales según feedback del usuario

#### Métricas esperadas:
- USB drops: ~1 cada 10 zombies (10%)
- Laptop drops: ~1 cada 20 zombies (5%)
- Antivirus drops: ~1 cada 12 zombies (8%)
- Elite drops: ~1 cada 50 zombies (2%)

---

### 2025-09-28 19:55 - Corrección Crítica: Error en MiniGameUI.lua onStart

**Estado anterior del código:** Error crítico - minijuego no iniciaba al presionar START
**Problema identificado:** Función `clearAllTimers()` no definida, causando "Object tried to call nil"
**Impacto esperado:** Restaurar funcionalidad completa del minijuego de secuencias

#### Cambios realizados:

1. **MiniGameUI.lua**
   - Timestamp: 2025-09-28 19:55
   - Cambio: Agregada función `MiniGameWindow:clearAllTimers()` que limpia `SimpleTimer.activeTimers = {}`
   - Ubicación: Insertada antes de `onStart()` (línea ~697)
   - Justificación: La función era llamada en `onStart()`, `onReset()` y `resetForNextGame()` pero no existía

#### Problemas resueltos:

- **Error "Object tried to call nil in onStart":** Causado por llamada a función inexistente `self:clearAllTimers()`
- **Minijuego no iniciaba:** El error impedía que la secuencia comenzara al presionar START
- **Stack trace:** `onStart` → `clearAllTimers` (nil) → RuntimeException

#### Estado actual del código: 
- **Estable** - Función implementada y probada sintácticamente
- **Pendiente verificación** - Necesita testeo en juego para confirmar funcionamiento

#### Próximas tareas:
- [ ] Probar minijuego en juego: presionar START y verificar que inicie secuencia
- [ ] Verificar que no haya otros errores relacionados con timers
- [ ] Documentar resultados de pruebas

#### Detalles técnicos:
- Sistema de timers: `SimpleTimer` global con `activeTimers` table
- Función agregada: Limpia todos los timers activos para evitar conflictos entre sesiones
- Compatibilidad: Mantiene llamadas existentes en `onReset()` y `resetForNextGame()`

---

### 2025-09-28 20:00 - Corrección Crítica: Animación final y cierre de ventana en MiniGameUI.lua

**Estado anterior del código:** Error crítico - minijuego terminaba sin animación final ni cierre automático
**Problema identificado:** `processFinalResult()` llamaba `resetForNextGame()` antes de `fillGridWithResult()`, limpiando timers necesarios
**Impacto esperado:** Restaurar animación final completa y cierre automático de ventana

#### Cambios realizados:

1. **MiniGameUI.lua**
   - Timestamp: 2025-09-28 20:00
   - Cambio: Reordenado flujo en `processFinalResult()` - `resetForNextGame()` movido al callback de `fillGridWithResult()`
   - Ubicación: Función `processFinalResult()` (línea ~355)
   - Justificación: Los timers de la animación se limpiaban prematuramente, impidiendo la animación y el cierre

#### Problemas resueltos:

- **Animación final no ejecutaba:** `resetForNextGame()` limpiaba timers antes de que `fillGridWithResult()` pudiera completar
- **Ventana no se cerraba:** El timer de cierre se eliminaba junto con otros timers activos
- **Flujo interrumpido:** Reset prematuro impedía el pipeline completo de finalización

#### Estado actual del código: 
- **Estable** - Flujo de finalización corregido y probado sintácticamente
- **Pendiente verificación** - Necesita testeo en juego para confirmar animación y cierre funcionan

#### Próximas tareas:
- [ ] Probar finalización del minijuego: completar secuencia y verificar animación + cierre automático
- [ ] Verificar que tanto éxito como fracaso ejecuten correctamente el pipeline
- [ ] Documentar resultados de pruebas

#### Detalles técnicos:
- Pipeline corregido: XP/Daño → Animación fillGrid → Reset → Cierre automático
- Función afectada: `processFinalResult(success)` llamada desde `onSequencePress()`
- Callback pattern: `fillGridWithResult()` ahora ejecuta reset y cierre en su callback
- Timer management: Evita limpieza prematura de timers de animación

---

### Deuda de documentación pendiente:
- Crear documentación técnica del sistema de minijuegos (pendiente implementación)
- Documentar sistema de traducción DisplayName → claves
- Crear guía de configuración de probabilidades de drop

### Herramientas utilizadas:
- PowerShell para navegación de archivos
- VS Code para edición de código LUA
- Project Zomboid logs para debugging

---
**Última actualización:** 2025-09-28 20:00