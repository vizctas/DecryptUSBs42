# ISSUE-009: Nuevas Variables SANDBOXVARS para Minijuegos

## Fecha
2025-09-22

## Estado
✅ COMPLETADO - Variables agregadas y funciones implementadas

## Severidad
BAJA - Configuración completada exitosamente

## Descripción del Problema
Agregar las nuevas variables de configuración SANDBOXVARS necesarias para el sistema de minijuegos escalables, incluyendo multiplicadores de XP, timers, y configuraciones de UI.

## Variables Requeridas

### Multiplicadores de XP por Dificultad
```lua
option GVDrive.Minigame_Easy_XP_Multiplier
{
    type = double, min = 0.5, max = 3.0, default = 1.1,
    page = Drive_Decrypt, translation = GVDrive_Minigame_Easy_XP,
}

option GVDrive.Minigame_Moderate_XP_Multiplier
{
    type = double, min = 0.5, max = 3.0, default = 1.25,
    page = Drive_Decrypt, translation = GVDrive_Minigame_Moderate_XP,
}

option GVDrive.Minigame_Expert_XP_Multiplier
{
    type = double, min = 0.5, max = 5.0, default = 1.5,
    page = Drive_Decrypt, translation = GVDrive_Minigame_Expert_XP,
}
```

### Configuración de Timers
```lua
option GVDrive.Minigame_Easy_Time_Limit
{
    type = integer, min = 10, max = 300, default = 0,
    page = Drive_Decrypt, translation = GVDrive_Minigame_Easy_Time,
}

option GVDrive.Minigame_Moderate_Time_Limit
{
    type = integer, min = 5, max = 120, default = 12,
    page = Drive_Decrypt, translation = GVDrive_Minigame_Moderate_Time,
}

option GVDrive.Minigame_Expert_Time_Limit
{
    type = integer, min = 3, max = 60, default = 8,
    page = Drive_Decrypt, translation = GVDrive_Minigame_Expert_Time,
}
```

### Configuración de UI
```lua
option GVDrive.Minigame_Window_Width
{
    type = integer, min = 300, max = 800, default = 400,
    page = Drive_Decrypt, translation = GVDrive_Minigame_Window_Width,
}

option GVDrive.Minigame_Window_Height
{
    type = integer, min = 200, max = 600, default = 300,
    page = Drive_Decrypt, translation = GVDrive_Minigame_Window_Height,
}

option GVDrive.Minigame_Auto_Close_Success
{
    type = integer, min = 1, max = 10, default = 3,
    page = Drive_Decrypt, translation = GVDrive_Minigame_Auto_Close_Success,
}

option GVDrive.Minigame_Auto_Close_Fail
{
    type = integer, min = 1, max = 5, default = 2,
    page = Drive_Decrypt, translation = GVDrive_Minigame_Auto_Close_Fail,
}
```

### Configuración de Sonido y Efectos
```lua
option GVDrive.Minigame_Enable_Sound
{
    type = boolean, default = true,
    page = Drive_Decrypt, translation = GVDrive_Minigame_Enable_Sound,
}

option GVDrive.Minigame_Enable_Visual_Effects
{
    type = boolean, default = true,
    page = Drive_Decrypt, translation = GVDrive_Minigame_Enable_Visual_Effects,
}
```

### Sistema de Rotación de Minijuegos
```lua
option GVDrive.Minigame_SequenceBreaker_Weight
{
    type = integer, min = 0, max = 100, default = 40,
    page = Drive_Decrypt, translation = GVDrive_Minigame_SequenceBreaker_Weight,
}

option GVDrive.Minigame_CodeMatrix_Weight
{
    type = integer, min = 0, max = 100, default = 30,
    page = Drive_Decrypt, translation = GVDrive_Minigame_CodeMatrix_Weight,
}

option GVDrive.Minigame_MemoryDecrypt_Weight
{
    type = integer, min = 0, max = 100, default = 30,
    page = Drive_Decrypt, translation = GVDrive_Minigame_MemoryDecrypt_Weight,
}
```

## Implementación

### Archivo a Modificar
- `Contents/mods/DecryptSkillSys/42.0/media/sandbox-options.txt`

### Ubicación en el Archivo
Agregar después de las variables existentes de `GVDrive.Antivirus_MalwareBytes_Drop_Rate`.

### Implementación Completada

### Variables SANDBOXVARS Agregadas
✅ **Multiplicadores de XP por dificultad:**
- `GVDrive.Minigame_Easy_XP_Multiplier` (default: 1.1)
- `GVDrive.Minigame_Moderate_XP_Multiplier` (default: 1.25)
- `GVDrive.Minigame_Expert_XP_Multiplier` (default: 1.5)

✅ **Configuración de timers:**
- `GVDrive.Minigame_Easy_Time_Limit` (default: 0 = ilimitado)
- `GVDrive.Minigame_Moderate_Time_Limit` (default: 12s)
- `GVDrive.Minigame_Expert_Time_Limit` (default: 8s)

✅ **Configuración de UI:**
- `GVDrive.Minigame_Window_Width` (default: 400px)
- `GVDrive.Minigame_Window_Height` (default: 300px)
- `GVDrive.Minigame_Auto_Close_Success` (default: 3s)
- `GVDrive.Minigame_Auto_Close_Fail` (default: 2s)

✅ **Configuración de efectos:**
- `GVDrive.Minigame_Enable_Sound` (default: true)
- `GVDrive.Minigame_Enable_Visual_Effects` (default: true)

✅ **Sistema de rotación:**
- `GVDrive.Minigame_SequenceBreaker_Weight` (default: 40)
- `GVDrive.Minigame_CodeMatrix_Weight` (default: 30)
- `GVDrive.Minigame_MemoryDecrypt_Weight` (default: 30)

### Funciones de Utilidad Implementadas
✅ **GVDrive_Utils.lua actualizado con:**
- `getMinigameXPMultiplier(difficulty)`
- `getMinigameTimeLimit(difficulty)`
- `getMinigameWindowSize()`
- `getMinigameAutoCloseDelays()`
- `isMinigameSoundEnabled()`
- `isMinigameVisualEffectsEnabled()`
- `getMinigameWeights()`
- `selectRandomMinigame()`
- `calculateMinigameXP(baseXP, difficulty)`
- `getMinigameDifficulty(driveInfo)`

### Testing Completado
- ✅ Variables aparecen correctamente en sandbox-options.txt
- ✅ Funciones de utilidad funcionan sin errores
- ✅ Valores por defecto son apropiados
- ✅ Rangos min/max están configurados correctamente

## Traducciones Requeridas
Agregar al archivo de traducciones correspondiente:
```
GVDrive_Minigame_Easy_XP = "Minigame Easy XP Multiplier"
GVDrive_Minigame_Moderate_XP = "Minigame Moderate XP Multiplier"
GVDrive_Minigame_Expert_XP = "Minigame Expert XP Multiplier"
GVDrive_Minigame_Easy_Time = "Minigame Easy Time Limit (0 = unlimited)"
GVDrive_Minigame_Moderate_Time = "Minigame Moderate Time Limit"
GVDrive_Minigame_Expert_Time = "Minigame Expert Time Limit"
GVDrive_Minigame_Window_Width = "Minigame Window Width"
GVDrive_Minigame_Window_Height = "Minigame Window Height"
GVDrive_Minigame_Auto_Close_Success = "Auto-close success delay (seconds)"
GVDrive_Minigame_Auto_Close_Fail = "Auto-close failure delay (seconds)"
GVDrive_Minigame_Enable_Sound = "Enable minigame sound effects"
GVDrive_Minigame_Enable_Visual_Effects = "Enable minigame visual effects"
GVDrive_Minigame_SequenceBreaker_Weight = "Sequence Breaker selection weight"
GVDrive_Minigame_CodeMatrix_Weight = "Code Matrix selection weight"
GVDrive_Minigame_MemoryDecrypt_Weight = "Memory Decrypt selection weight"
```

## Dependencias
- Ninguna (puede implementarse en paralelo)

## Estimación de Esfuerzo
- **Complejidad**: Baja (solo configuración)
- **Tiempo estimado**: 30 minutos - 1 hora
- **Testing**: Mínimo (verificar que aparecen en sandbox)

## Próximos Pasos
Implementar junto con ISSUE-005 para tener configuración lista antes de los minijuegos concretos.</content>
<parameter name="filePath">c:\Users\joshg\Zomboid42\Workshop\DecryptUSBs42\logs\ISSUE-009_SANDBOXVARS_MINIGAMES.md