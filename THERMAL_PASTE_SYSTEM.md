# 🧊 SISTEMA DE PASTA TÉRMICA

## 📋 DESCRIPCIÓN

El **ThermalPasteTube** (Tubo de Pasta Térmica) es un nuevo ítem consumible que permite enfriar laptops sobrecalentadas de manera efectiva, reemplazando el antiguo sistema de "cerrar laptop para enfriar".

---

## 🎯 CARACTERÍSTICAS

### **Enfriamiento Instantáneo**
- ✅ Reduce la temperatura de la laptop a **20°C** (temperatura ambiente) inmediatamente
- ✅ No requiere esperar tiempo de enfriamiento
- ✅ Mucho más efectivo que el enfriamiento pasivo

### **Bonus Temporal de Enfriamiento**
- ✅ Otorga un **bonus activo por 30 minutos** después de aplicar
- ✅ Durante el bonus:
  - **-50% calentamiento** al usar minijuegos
  - Stacks con otros modificadores (liquid cooling, etc.)
- ✅ El bonus se muestra en el menú contextual

### **Consumible con Feedback Visual**
- ✅ Se consume al usar (1 aplicación = 1 tubo)
- ✅ Mensaje de feedback con temperaturas antes/después
- ✅ Sonido de éxito al aplicar
- ✅ Indicador visual en health status

---

## 🔧 CÓMO FUNCIONA

### **Paso 1: Obtener Pasta Térmica**
El ítem `ThermalPasteTube` debe ser añadido al loot pool o crafteable (definido en `GV_items_usb.txt`):

```plaintext
item ThermalPasteTube
{
    DisplayCategory = Electronics,
    Weight          = 0.1,
    Type            = Normal,
    DisplayName     = Thermal Paste,
    Icon            = ThermalPaste,
    WorldStaticModel = USB_Opened,
    Tooltip         = Tooltip_ThermalPaste,
}
```

### **Paso 2: Usar en Laptop**
1. Jugador tiene `ThermalPasteTube` en inventario
2. Click derecho en laptop abierta
3. Opción en menú contextual: **"Apply Thermal Paste (X) - Current: XXX°C"**
4. Al hacer click:
   - Temperatura baja a 20°C
   - Bonus de enfriamiento se activa por 30 minutos
   - Tubo se consume
   - Mensaje de feedback

### **Paso 3: Beneficiarse del Bonus**
- Durante 30 minutos, cada minijuego genera **50% menos calor**
- El tiempo restante se muestra en:
  - Menú contextual (opción de pasta térmica)
  - Health status de la laptop: `[🧊15m]` (ejemplo: 15 minutos restantes)

---

## 📊 INTEGRACIÓN CON SISTEMAS EXISTENTES

### **LaptopThermalSystem.lua**
Se agregaron las siguientes funciones:

```lua
-- Aplicar pasta térmica (enfriamiento + bonus)
LaptopThermalSystem.applyThermalPaste(laptop)

-- Verificar si tiene bonus activo
LaptopThermalSystem.hasThermalPasteBonus(laptop)

-- Obtener tiempo restante del bonus (minutos)
LaptopThermalSystem.getThermalPasteBonusRemaining(laptop)
```

### **DecryptDrivesContextMenu.lua**
Se agregaron las siguientes funciones:

```lua
-- Agregar opciones de pasta térmica al menú
DecryptDrivesContextMenu.addThermalPasteOptions(context, player, worldObject)

-- Usar pasta térmica en laptop
DecryptDrivesContextMenu.useThermalPaste(player, worldObject)
```

### **Modificación en addHeat()**
La función `LaptopThermalSystem.addHeat()` ahora verifica el bonus:

```lua
-- ✨ BONUS: Pasta térmica reduce calentamiento en 50%
if LaptopThermalSystem.hasThermalPasteBonus(laptop) then
    heatIncrease = heatIncrease * 0.5
    print("[ThermalSystem] Thermal paste bonus active - heat reduced by 50%")
end
```

---

## 🎨 UI/UX

### **Opción en Menú Contextual**
```
Apply Thermal Paste (3) - Current: 75°C
```

Si el bonus está activo:
```
Apply Thermal Paste (2) - Current: 45°C [BONUS ACTIVE: 15m]
```

### **Health Status Display**
Sin bonus:
```
Health: 85% (Excellent) - 65°C (Hot) - 3 Fails
```

Con bonus activo:
```
Health: 85% (Excellent) - 45°C (Warm) [🧊15m] - 3 Fails
```

### **Feedback al Aplicar**
```
Player says: "Thermal paste applied! Temperature: 85°C -> 20°C. Cooling bonus active for 30 minutes."
Console log: [ThermalPaste] Successfully applied to laptop. Temp reduced from 85°C to 20°C
```

---

## 🔥 COMPARACIÓN: ANTIGUO VS NUEVO SISTEMA

### **Antiguo Sistema (Cerrar Laptop)**
- ❌ Requiere cerrar laptop (no es realista)
- ❌ Enfriamiento lento (5% por segundo = 13 minutos para enfriar de 85°C a 20°C)
- ❌ No se puede usar laptop mientras enfría
- ❌ No hay feedback claro
- ❌ No hay beneficios adicionales

### **Nuevo Sistema (Pasta Térmica)**
- ✅ Enfriamiento instantáneo (85°C -> 20°C al momento)
- ✅ Bonus temporal de enfriamiento mejorado (30 minutos)
- ✅ Laptop se puede seguir usando inmediatamente
- ✅ Feedback visual y auditivo claro
- ✅ Consumible: añade estrategia de gestión de recursos
- ✅ Más realista: aplicar pasta térmica es una solución real

---

## ⚙️ CONFIGURACIÓN TÉCNICA

### **Valores de Configuración**
```lua
-- En LaptopThermalSystem.lua:
COOLING_TARGET = 20  -- Temperatura objetivo al aplicar pasta (°C)
BONUS_DURATION = 30 * 60  -- Duración del bonus (30 minutos reales en segundos)
HEAT_REDUCTION_BONUS = 0.5  -- 50% menos calentamiento durante bonus
```

### **ModData Usado**
```lua
laptop:getModData() = {
    GVDrive_ThermalPasteActive = true,  -- Indica si bonus está activo
    GVDrive_ThermalPasteExpiry = 1234567890  -- Timestamp UNIX de expiración
}
```

---

## 🧪 TESTING

### **Comandos de Debug**
```lua
-- Diagnóstico del sistema térmico
DiagnoseThermalSystem()

-- Forzar temperatura para testing
SetLaptopTemp(85)  -- Establece temperatura a 85°C

-- Recargar sistema térmico
ReloadThermalSystem()
```

### **Escenarios de Testing**

#### Test 1: Aplicar Pasta Térmica
1. Agregar pasta térmica al inventario: `/additem "GValley.ThermalPasteTube" 3`
2. Colocar laptop con temperatura alta: `SetLaptopTemp(85)`
3. Click derecho en laptop → "Apply Thermal Paste"
4. Verificar:
   - ✅ Temperatura baja a 20°C
   - ✅ Mensaje de feedback
   - ✅ Tubo consumido (count disminuye)
   - ✅ Bonus activo aparece en health status

#### Test 2: Bonus de Enfriamiento
1. Aplicar pasta térmica
2. Usar minijuego en dificultad Expert (normalmente +35°C)
3. Verificar que solo sube ~17-18°C (50% reducción)
4. Verificar log: `[ThermalSystem] Thermal paste bonus active - heat reduced by 50%`

#### Test 3: Expiración del Bonus
1. Aplicar pasta térmica
2. Esperar 30 minutos (o modificar `BONUS_DURATION` para testing rápido)
3. Verificar que bonus desaparece
4. Usar minijuego y confirmar calentamiento normal

---

## 📈 BALANCE

### **Valores Recomendados**
- **Rareza:** Uncommon (similar a antivirus)
- **Precio:** Moderado-Alto (ítem estratégico)
- **Loot locations:** Electronics stores, office buildings, mechanic shops
- **Crafteable:** Opcional (requeriría pasta + contenedor)

### **Stacking con Otros Modificadores**
```lua
Ejemplo con laptop + liquid cooling + pasta térmica:
- Base heat (Expert): 35°C
- Con liquid cooling: 35 * 0.5 = 17.5°C
- Con pasta térmica: 17.5 * 0.5 = 8.75°C
- TOTAL: Solo ~9°C de aumento (vs 35°C sin modificadores)
```

---

## 🎉 VENTAJAS DEL NUEVO SISTEMA

1. **Más Realista**
   - Aplicar pasta térmica es una solución real para sobrecalentamiento
   - Cerrar laptop no es tan efectivo en la vida real

2. **Más Estratégico**
   - Jugadores deben gestionar recursos (tubos limitados)
   - Decisión táctica: ¿usar ahora o guardar para después?

3. **Mejor UX**
   - Feedback inmediato y claro
   - No interrumpe el gameplay (laptop sigue usable)
   - Visual: indicadores de bonus activo

4. **Más Balanceado**
   - Consumible: no infinito
   - Bonus temporal: incentiva uso estratégico
   - Cooldown implícito (30 minutos)

5. **Integración Completa**
   - Se integra con sistemas existentes
   - Compatible con multiplayer
   - No rompe balance de otros sistemas

---

## 📝 TAREAS PENDIENTES

### **Implementación Completa**
- [x] Funciones de aplicar pasta térmica
- [x] Bonus temporal de enfriamiento
- [x] Integración con menú contextual
- [x] Display en health status
- [x] Feedback visual y auditivo
- [ ] Icono de textura (ThermalPaste.png)
- [ ] Tooltip traducido
- [ ] Loot distribution (spawn tables)
- [ ] Receta de crafting (opcional)

### **Testing**
- [ ] Testing in-game completo
- [ ] Validar consumo correcto del ítem
- [ ] Verificar expiración del bonus
- [ ] Testing multiplayer
- [ ] Balance testing (frecuencia de uso)

### **Documentación**
- [x] Documento técnico (este archivo)
- [ ] Actualizar README principal
- [ ] Agregar a CHANGELOG
- [ ] Tutorial in-game (opcional)

---

## 🚀 ESTADO

**✅ IMPLEMENTADO - Pendiente Testing**

El sistema está completamente codificado e integrado. Falta:
1. Testing in-game
2. Crear textura del icono
3. Configurar loot distribution
4. Balancear rareza/precio

---

*Fecha: 2 de octubre de 2025*  
*Mod: DecryptSkillSys 42.0*  
*Branch: feat/new_minigames*
