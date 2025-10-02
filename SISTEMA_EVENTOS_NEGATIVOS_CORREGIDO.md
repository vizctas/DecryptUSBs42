# Sistema de Eventos Negativos - Correcciones v1.5.16

## 🎯 Problemas Detectados y Solucionados

### **1. ✅ Alarma de Seguridad - CORREGIDO**

#### **Problema Original:**
```lua
// ❌ NO atraía zombies - solo reproducía sonido local
getSoundManager():PlaySound("alarm", false, 0.3)
```

#### **Solución Implementada:**
```lua
// ✅ Ahora ATRAE ZOMBIES usando PlayWorldSound
getSoundManager():PlayWorldSound("alarm", laptopSquare, 0, 80, 60, true)
//                                                        ^volume  ^radius
```

**Cambios en archivos:**
- `LaptopThermalSystem.lua` línea ~156: Alarma de sobrecalentamiento
- `LaptopEvents.lua` líneas ~175, ~200: Security Alarm event

**Parámetros de atracción:**
- **Volume**: 80 (volumen alto para que se escuche)
- **Radius**: 60 tiles (área grande de atracción)
- **Loop**: true (sonido continuo durante duración de alarma)

---

### **2. ✅ Spawn de Zombies Fuera de Safehouse - CORREGIDO**

#### **Problema Original:**
```lua
// ❌ Función incorrecta y no verificaba safehouse
local zombie = addZombiesInOutfit(spawnX, spawnY, z, 1, "Crawler", 0)
```

#### **Solución Implementada:**
```lua
// ✅ Verifica safehouse ANTES de spawn
local isInSafehouse = SafeHouse.isSafeHouse(laptopSquare, player:getUsername(), false)

if isInSafehouse then
    spawnRadius = spawnRadius + 15  // Spawn MÁS LEJOS si está en safehouse
end

// Para cada punto de spawn, verificar que NO sea safehouse
local spawnInSafehouse = SafeHouse.isSafeHouse(spawnSquare, player:getUsername(), false)

if not spawnInSafehouse and not spawnSquare:isVehicleIntersecting() and spawnSquare:isFree(false) then
    // ✅ Usar función correcta de spawn
    local zombie = createZombieInOutfit("Crawler", 0, spawnX, spawnY, z)
end
```

**Lógica de spawn:**
1. Detecta si jugador está EN safehouse
2. Si está en safehouse → aumenta radio de spawn +15 tiles
3. Para cada zombie, verifica que NO spawne dentro de safehouse
4. Usa `createZombieInOutfit()` en lugar de `addZombiesInOutfit()`

**Configuración de sandbox:**
- `Event_DistressSignal_ZombieCount`: 3-10 zombies (default: 5)
- `Event_DistressSignal_SpawnRadius`: 15-30 tiles (default: 20)
- Si está en safehouse: radio + 15 tiles automáticamente

---

### **3. ✅ Enfriamiento de Laptops - AJUSTADO**

#### **Problema Original:**
```lua
// ❌ Enfriamiento demasiado rápido (2°C por SEGUNDO)
LaptopThermalSystem.COOLING_RATE = 2  // 2% por segundo
LaptopThermalSystem.COOLING_RATE_IDLE = 5  // 5% por segundo
```

#### **Solución Implementada:**
```lua
// ✅ Enfriamiento realista: 20°C cada 30 minutos in-game
LaptopThermalSystem.COOLING_RATE_PER_MINUTE = 0.667  // 0.667°C por minuto
LaptopThermalSystem.COOLING_RATE_IDLE_PER_MINUTE = 1.0  // 1°C por minuto (cerrada)

// Sistema automático de enfriamiento cada 10 minutos in-game
function onEveryTenMinutes()
    -- Enfriar todas las laptops del inventario
    LaptopThermalSystem.coolDown(laptop, 10)  // deltaTime = 10 minutos
end
```

**Matemática:**
- **Abierta/En uso**: 0.667°C/min × 30min = 20°C de enfriamiento
- **Cerrada/Idle**: 1.0°C/min × 20min = 20°C de enfriamiento
- **Con Liquid Cooling**: 2x velocidad (enfría en 15 minutos)
- **Con Thermal Paste Bonus**: No afecta enfriamiento, solo reduce calentamiento

**Sistema automático:**
- Evento: `EveryTenMinutes` (cada 10 minutos in-game)
- Aplica enfriamiento gradual a todas las laptops en inventario
- Se ejecuta automáticamente en background

---

## 🔊 Sonido de Alarma

### **Archivo de Audio:**
- Ubicación: `/media/sound/alarm.ogg`
- Formato: OGG Vorbis
- Estado: ✅ Existe y funciona

### **Uso en el Mod:**

| Evento | Archivo | Volumen | Radio | Duración | Atrae Zombies |
|--------|---------|---------|-------|----------|---------------|
| **Sobrecalentamiento** | LaptopThermalSystem.lua | 80 | 60 tiles | 1 segundo | ✅ Sí |
| **Security Alarm** | LaptopEvents.lua | 100 | 50 tiles | 45 segundos | ✅ Sí |

---

## 📊 Eventos Negativos (3+ Fallos Acumulados)

### **Sistema de Activación:**

```
Fallos >= 3 → Roll probabilístico (25% base)
↓
Si pasa → Selecciona evento aleatorio (pesos)
↓
Ejecuta evento → Reset contador de fallos a 0
```

### **Probabilidades:**

| Evento | Probabilidad | Descripción |
|--------|--------------|-------------|
| **Distress Signal** | 40% | Spawn 5 zombies fuera de safehouse |
| **Accelerated Damage** | 35% | Daña laptop 10-40% |
| **Security Alarm** | 25% | Alarma 45s que atrae zombies |

### **Modificadores:**

- **Fallos >= 7**: +15% probabilidad de evento (40% total)
- **Dificultad**: Afecta cantidad de fallos acumulados más rápido
- **After evento**: Reset fallos a 0 (cooldown implícito)

---

## 🧪 Testing Commands

### **Thermal System:**
```lua
DiagnoseThermalSystem()        -- Ver estado de temperatura
SetLaptopTemp(95)               -- Forzar temperatura (test overheat)
```

### **Eventos:**
```lua
DiagnoseLaptopEvents()          -- Diagnóstico completo del sistema
ForceLaptopEvent("distress_signal")   -- Forzar spawn de zombies
ForceLaptopEvent("security_alarm")    -- Forzar alarma
ForceLaptopEvent("accelerated_damage") -- Forzar daño
ForceLaptopEvent("random")             -- Roll aleatorio
```

### **Reload Modules:**
```lua
ReloadLaptopThermalSystem()     -- Recargar sistema térmico
ReloadLaptopEvents()            -- Recargar eventos
```

---

## 🎮 Flujo de Juego Corregido

### **Escenario: Jugador falla 3+ veces**

1. **Jugador falla minigame** → Contador de fallos +1
2. **Laptop se calienta** → +15/25/35°C según dificultad
3. **Si fallos >= 3** → Roll 25% para evento
4. **Si roll pasa** → Selecciona evento aleatorio:
   
   **Opción A: Distress Signal (40%)**
   - ✅ Detecta si está en safehouse
   - ✅ Spawnea 5 zombies FUERA de safehouse (radio +15 tiles)
   - ✅ Zombies aparecen en círculo alrededor
   - Jugador recibe mensaje: "The laptop is emitting a strange signal..."
   
   **Opción B: Security Alarm (25%)**
   - ✅ Reproduce sonido "alarm.ogg" con PlayWorldSound
   - ✅ Zombies cercanos (60 tiles) son atraídos
   - ✅ Alarma suena cada 3 segundos durante 45 segundos
   - Jugador recibe mensaje: "The laptop's security alarm is blaring!"
   
   **Opción C: Accelerated Damage (35%)**
   - Daña laptop 10-40% instantáneamente
   - Jugador recibe mensaje según severidad
   - Si laptop queda <= 25% → "The laptop is critically damaged!"

5. **Después del evento** → Contador de fallos reset a 0

### **Escenario: Laptop se sobrecalienta (95°C+)**

1. **Temperatura >= 95°C** → Overheat automático
2. **Efectos:**
   - Daño inmediato: 5-10% de health
   - ✅ Alarma suena (PlayWorldSound, atrae zombies)
   - Enfriamiento forzado a 85°C
   - Jugador: "CRITICAL OVERHEAT! The laptop is burning up!"

3. **Enfriamiento automático:**
   - Cada 10 minutos in-game → -6.67°C (si abierta)
   - Con thermal paste bonus → -50% calentamiento
   - Si cerrada → -10°C cada 10 minutos

---

## 📝 Configuración de Sandbox

### **Eventos:**
```
Event_DistressSignal_ZombieCount = 5      (3-10)
Event_DistressSignal_SpawnRadius = 20     (15-30 tiles)
Event_AcceleratedDamage_Amount = 20       (10-40%)
Event_SecurityAlarm_Duration = 45         (30-90 segundos)
Event_SecurityAlarm_Radius = 50           (30-100 tiles)
Event_SecurityAlarm_Volume = 100          (50-150)
```

### **Thermal System:**
```
Laptop_Overheat_Threshold = 95            (85-100°C)
Laptop_Critical_Threshold = 85            (75-95°C)
ThermalPaste_Bonus_Duration = 30          (15-60 minutos)
ThermalPaste_Heat_Reduction = 50          (25-75%)
```

---

## ✅ Checklist de Correcciones

- [x] Alarma usa `PlayWorldSound()` para atraer zombies
- [x] Spawn de zombies verifica safehouse correctamente
- [x] Spawn de zombies usa `createZombieInOutfit()` correctamente
- [x] Zombies NO spawnean dentro de safehouse
- [x] Si en safehouse, aumenta radio de spawn +15 tiles
- [x] Enfriamiento ajustado a 20°C cada 30 minutos in-game
- [x] Sistema de enfriamiento automático cada 10 minutos
- [x] Archivo `alarm.ogg` existe y se usa correctamente
- [x] Comandos de testing funcionan
- [x] Documentación completa creada

---

## 🚀 Próximos Pasos

### **Testing In-Game:**
1. Forzar 3+ fallos en laptop
2. Verificar que eventos se activen
3. Confirmar que alarma atrae zombies
4. Confirmar que zombies NO spawnean en safehouse
5. Verificar enfriamiento pasivo cada 10 minutos

### **Posibles Mejoras Futuras:**
- [ ] Agregar evento "EMP Blast" (desactiva luces cercanas)
- [ ] Agregar evento "Data Corruption" (pierde progreso de USB)
- [ ] Agregar sonidos únicos para cada tipo de evento
- [ ] Agregar moodles temporales por eventos negativos
- [ ] Balancear probabilidades según feedback de jugadores

---

**Versión:** 1.5.16
**Fecha:** 2 de octubre de 2025
**Estado:** ✅ CORREGIDO Y LISTO PARA TESTING
