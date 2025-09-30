# 🔧 SISTEMA DE DEBUG CONFIGURABLE - GUÍA DE USO

**Archivo:** `DecryptDrivesContextMenu.lua`  
**Fecha:** 2025-01-XX  
**Estado:** ✅ IMPLEMENTADO Y FUNCIONAL

---

## 📋 RESUMEN DE CAMBIOS

Se ha implementado un **sistema de debug configurable con categorías** que permite controlar de forma granular qué mensajes de debug se muestran en la consola.

### ✅ Beneficios:
- **Control total**: Activa/desactiva debug globalmente o por categorías
- **Consola limpia**: Sin spam de mensajes innecesarios
- **Debug quirúrgico**: Activa solo las categorías que necesitas
- **Errores críticos siempre visibles**: Los errores importantes nunca se ocultan
- **Backup creado**: `DecryptDrivesContextMenu.lua.backup` disponible

---

## 🎛️ CONFIGURACIÓN DEL SISTEMA

### Interruptor Maestro

```lua
-- ========== SISTEMA DE DEBUG CONFIGURABLE ==========
-- Interruptor maestro de debug: true = debug activo, false = debug silencioso
local DEBUG_ENABLED = false  -- ⬅️ CAMBIAR AQUÍ
```

- **`DEBUG_ENABLED = false`**: Solo muestra errores críticos (RECOMENDADO para producción)
- **`DEBUG_ENABLED = true`**: Muestra todos los debugs habilitados por categoría

---

## 📂 CATEGORÍAS DE DEBUG

```lua
local DEBUG_CATEGORIES = {
    MINIGAME_SELECTION = false,  -- Selección aleatoria de minijuegos
    USB_SCANNING = false,        -- Escaneo de USBs en inventario
    LAPTOP_VALIDATION = false,   -- Validación de laptops
    MENU_CREATION = false,       -- Creación de menús contextuales
    USB_SELECTION = false,       -- Selección y uso de USBs
    EVENT_SYSTEM = false,        -- Sistema de eventos
    CRITICAL_ONLY = true         -- Solo errores críticos (siempre activo)
}
```

### 🔍 Descripción de Categorías:

| Categoría | Descripción | Cuándo activar |
|-----------|-------------|----------------|
| **MINIGAME_SELECTION** | Selección aleatoria entre minijuegos | Debugging de sistema de minijuegos |
| **USB_SCANNING** | Escaneo de USBs en inventario del jugador | Problemas con detección de USBs |
| **LAPTOP_VALIDATION** | Validación de laptops en el mundo | Laptops no detectadas correctamente |
| **MENU_CREATION** | Creación de menús contextuales | Menús no aparecen o están mal |
| **USB_SELECTION** | Selección y uso de USBs | Minijuegos no se abren al usar USB |
| **EVENT_SYSTEM** | Sistema de eventos de PZ | Problemas con registro de eventos |
| **CRITICAL_ONLY** | Solo errores críticos | **SIEMPRE ACTIVO** (no desactivar) |

---

## 🚀 CASOS DE USO COMUNES

### 1️⃣ Producción (Sin Debug)
```lua
local DEBUG_ENABLED = false

local DEBUG_CATEGORIES = {
    MINIGAME_SELECTION = false,
    USB_SCANNING = false,
    LAPTOP_VALIDATION = false,
    MENU_CREATION = false,
    USB_SELECTION = false,
    EVENT_SYSTEM = false,
    CRITICAL_ONLY = true  -- Solo errores críticos
}
```
**Resultado**: Consola limpia, solo errores críticos visibles

---

### 2️⃣ Debug de USBs No Detectados
```lua
local DEBUG_ENABLED = true

local DEBUG_CATEGORIES = {
    MINIGAME_SELECTION = false,
    USB_SCANNING = true,         -- ✅ ACTIVADO
    LAPTOP_VALIDATION = false,
    MENU_CREATION = false,
    USB_SELECTION = false,
    EVENT_SYSTEM = false,
    CRITICAL_ONLY = true
}
```
**Resultado**: Muestra solo mensajes de escaneo de USBs

---

### 3️⃣ Debug de Laptops No Reconocidas
```lua
local DEBUG_ENABLED = true

local DEBUG_CATEGORIES = {
    MINIGAME_SELECTION = false,
    USB_SCANNING = false,
    LAPTOP_VALIDATION = true,    -- ✅ ACTIVADO
    MENU_CREATION = false,
    USB_SELECTION = false,
    EVENT_SYSTEM = false,
    CRITICAL_ONLY = true
}
```
**Resultado**: Muestra solo mensajes de validación de laptops

---

### 4️⃣ Debug Completo (Desarrollo)
```lua
local DEBUG_ENABLED = true

local DEBUG_CATEGORIES = {
    MINIGAME_SELECTION = true,   -- ✅ TODO ACTIVADO
    USB_SCANNING = true,
    LAPTOP_VALIDATION = true,
    MENU_CREATION = true,
    USB_SELECTION = true,
    EVENT_SYSTEM = true,
    CRITICAL_ONLY = true
}
```
**Resultado**: Muestra TODOS los mensajes de debug

---

### 5️⃣ Debug de Minijuegos
```lua
local DEBUG_ENABLED = true

local DEBUG_CATEGORIES = {
    MINIGAME_SELECTION = true,   -- ✅ ACTIVADO
    USB_SCANNING = false,
    LAPTOP_VALIDATION = false,
    MENU_CREATION = false,
    USB_SELECTION = true,        -- ✅ ACTIVADO
    EVENT_SYSTEM = false,
    CRITICAL_ONLY = true
}
```
**Resultado**: Muestra selección de minijuegos y apertura de USBs

---

## 📊 FORMATO DE MENSAJES

### Mensajes por Categoría:
```
[DecryptSkillSys][MINIGAME_SELECTION] Selected game via ZombRand: fallout
[DecryptSkillSys][USB_SCANNING] USB scan completed, found 3 USBs
[DecryptSkillSys][LAPTOP_VALIDATION] Laptop válida detectada: ASUS Zephyrus M
[DecryptSkillSys][MENU_CREATION] USB menu created
[DecryptSkillSys][USB_SELECTION] USB selected: USB Cooking (Facil)
[DecryptSkillSys][EVENT_SYSTEM] DecryptDrivesContextMenu.lua starting to load...
[DecryptSkillSys][CRITICAL] Events is nil at module load time - creating fallback
```

---

## 🛠️ CÓMO USAR

### Paso 1: Abrir el Archivo
```
C:\Users\joshg\Zomboid42\Workshop\DecryptUSBs42\Contents\mods\DecryptSkillSys\42.0\media\lua\client\DecryptDrivesContextMenu.lua
```

### Paso 2: Localizar la Configuración
Buscar las líneas 44-57:
```lua
-- ========== SISTEMA DE DEBUG CONFIGURABLE ==========
local DEBUG_ENABLED = false
local DEBUG_CATEGORIES = {
    ...
}
```

### Paso 3: Modificar Según Necesidad
- Cambiar `DEBUG_ENABLED` a `true` o `false`
- Cambiar categorías específicas a `true` o `false`

### Paso 4: Guardar y Reiniciar
- Guardar el archivo
- Reiniciar Project Zomboid
- Los cambios se aplicarán automáticamente

---

## ⚠️ NOTAS IMPORTANTES

### ✅ Buenas Prácticas:
1. **Producción**: Siempre usar `DEBUG_ENABLED = false`
2. **Debug específico**: Activar solo las categorías necesarias
3. **CRITICAL_ONLY**: Nunca desactivar esta categoría
4. **Backup**: Se creó automáticamente `DecryptDrivesContextMenu.lua.backup`

### ❌ Evitar:
1. **No dejar debug activo en producción**: Afecta rendimiento
2. **No activar todas las categorías sin necesidad**: Spam en consola
3. **No desactivar CRITICAL_ONLY**: Perderás errores importantes

---

## 🔄 RESTAURAR VERSIÓN ANTERIOR

Si necesitas volver a la versión con todos los debugs:
```powershell
Copy-Item "DecryptDrivesContextMenu.lua.backup" "DecryptDrivesContextMenu.lua"
```

---

## 📝 EJEMPLOS DE DEBUG EN CONSOLA

### Con DEBUG_ENABLED = false:
```
[DecryptSkillSys][CRITICAL] Events is nil at module load time - creating fallback
```

### Con DEBUG_ENABLED = true y USB_SCANNING = true:
```
[DecryptSkillSys][USB_SCANNING] scanPlayerUSBs called
[DecryptSkillSys][USB_SCANNING] Inventory items count: 15
[DecryptSkillSys][USB_SCANNING] USB entry created via GVDrive_Utils: Cooking
[DecryptSkillSys][USB_SCANNING] USB scan completed, found 3 USBs
```

### Con DEBUG_ENABLED = true y MENU_CREATION = true:
```
[DecryptSkillSys][MENU_CREATION] addContextMenuOption STARTED
[DecryptSkillSys][MENU_CREATION] Checking worldObject 1
[DecryptSkillSys][MENU_CREATION] Valid laptop found!
[DecryptSkillSys][MENU_CREATION] USBs found: 3
[DecryptSkillSys][MENU_CREATION] USB menu created
```

---

## 🎯 RESUMEN

- **✅ Sistema implementado**: Control granular de debugs
- **✅ Backup creado**: Versión anterior guardada
- **✅ Consola limpia**: Sin spam innecesario
- **✅ Errores críticos**: Siempre visibles
- **✅ Fácil configuración**: Solo cambiar variables booleanas
- **✅ Mecánicas intactas**: Ninguna funcionalidad afectada

---

**Fecha de implementación**: 2025-01-XX  
**Archivo modificado**: `DecryptDrivesContextMenu.lua`  
**Backup disponible**: `DecryptDrivesContextMenu.lua.backup`  
**Estado**: ✅ LISTO PARA USO
