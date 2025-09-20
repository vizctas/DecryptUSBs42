# WORKFLOW - DecryptUSBs42 Project

## Registro de Cambios y Actividades

### 2025-09-19 17:30 - Investigación y Corrección: Sistema de Drops de Zombies

**Estado anterior del código:** Inestable - drops de zombies no funcionaban
**Problema identificado:** Probabilidades extremadamente bajas en sandbox-options.txt
**Impacto esperado:** Restaurar funcionalidad de drops de zombies del mod

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

### Deuda de documentación pendiente:
- Crear documentación técnica del sistema de minijuegos (pendiente implementación)
- Documentar sistema de traducción DisplayName → claves
- Crear guía de configuración de probabilidades de drop

### Limitaciones técnicas identificadas:
- **Sin acceso directo al CODEBASE:** No puedo acceder a C:\Users\joshg\repos\pzomboid_mod_study\docs desde el workspace
- **Alternativa implementada:** Solicitar contenido relevante del CODEBASE como attachments para usar como fuente de verdad
- **Necesidades de CODEBASE:** Documentación sobre sistema de loot, probabilidades estándar, definición de items

### Herramientas utilizadas:
- PowerShell para navegación de archivos
- VS Code para edición de código LUA
- Project Zomboid logs para debugging

---
**Última actualización:** 2025-09-19 17:35