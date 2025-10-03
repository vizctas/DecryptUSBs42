# Sistema de Eventos Aleatorios por Fallos - Guía de Integración

## 📋 Estado Actual

### ✅ Archivos Creados:
1. **LaptopEvents.lua** (shared/) - Sistema completo de eventos
2. **Carga automática** en ClientInit.lua y server/Init.lua

### ⚠️ Integración Pendiente:
El sistema está listo pero necesita ser llamado desde `GVDrive_Utils.applyMinigameResult()`

---

## 🔧 Integración Manual Requerida

### **Archivo:** `shared/GVDrive_Utils.lua`

**Ubicación:** Línea ~643, después de `LaptopSystem.damageLaptop(laptopItem, damage)`

**Código a agregar:**

```lua
            -- Obtener health actual usando LaptopSystem si está disponible
            if LaptopSystem and LaptopSystem.getLaptopHealth then
                currentHealth = LaptopSystem.getLaptopHealth(laptopItem)
                LaptopSystem.damageLaptop(laptopItem, damage)
                print("GVDrive_Utils: Laptop damaged by " .. damage .. "% (" .. currentHealth .. "% -> " .. (currentHealth - damage) .. "%)")
            end
            
            -- ⚠️ VERIFICAR Y EJECUTAR EVENTOS ALEATORIOS POR FALLOS
            if LaptopEvents and LaptopEvents.checkAndTriggerEvent then
                -- Obtener square de la laptop
                local laptopSquare = nil
                
                -- Intentar obtener square del worldItem
                if laptopItem.getWorldItem and type(laptopItem.getWorldItem) == "function" then
                    local worldItem = laptopItem:getWorldItem()
                    if worldItem and worldItem.getSquare then
                        laptopSquare = worldItem:getSquare()
                    end
                end
                
                -- Fallback: usar square del jugador
                if not laptopSquare and player and player.getCurrentSquare then
                    laptopSquare = player:getCurrentSquare()
                end
                
                -- Ejecutar verificación de eventos
                if laptopSquare then
                    LaptopEvents.checkAndTriggerEvent(player, laptopItem, laptopSquare)
                else
                    print("GVDrive_Utils: Could not determine laptop square for event trigger")
                end
            end
        end
        return false
```

---

## ⚙️ Configuraciones Sandbox a Agregar

### **Archivo:** `sandbox-options.txt`

Agregar al final del archivo:

```txt
option GVDrive.Event_Trigger_Chance
{
    type = integer,
    min = 0,
    max = 100,
    default = 25,
    page = GVDrive,
    translation = GVDrive_Event_Trigger_Chance,
}

option GVDrive.Event_Threshold_Low
{
    type = integer,
    min = 1,
    max = 10,
    default = 3,
    page = GVDrive,
    translation = GVDrive_Event_Threshold_Low,
}

option GVDrive.Event_Threshold_High
{
    type = integer,
    min = 5,
    max = 20,
    default = 7,
    page = GVDrive,
    translation = GVDrive_Event_Threshold_High,
}

option GVDrive.Event_DistressSignal_ZombieCount
{
    type = integer,
    min = 3,
    max = 15,
    default = 5,
    page = GVDrive,
    translation = GVDrive_Event_DistressSignal_ZombieCount,
}

option GVDrive.Event_DistressSignal_SpawnRadius
{
    type = integer,
    min = 15,
    max = 40,
    default = 20,
    page = GVDrive,
    translation = GVDrive_Event_DistressSignal_SpawnRadius,
}

option GVDrive.Event_AcceleratedDamage_Amount
{
    type = integer,
    min = 10,
    max = 50,
    default = 20,
    page = GVDrive,
    translation = GVDrive_Event_AcceleratedDamage_Amount,
}

option GVDrive.Event_SecurityAlarm_Duration
{
    type = integer,
    min = 30,
    max = 120,
    default = 45,
    page = GVDrive,
    translation = GVDrive_Event_SecurityAlarm_Duration,
}

option GVDrive.Event_SecurityAlarm_Radius
{
    type = integer,
    min = 30,
    max = 150,
    default = 50,
    page = GVDrive,
    translation = GVDrive_Event_SecurityAlarm_Radius,
}

option GVDrive.Event_SecurityAlarm_Volume
{
    type = integer,
    min = 50,
    max = 200,
    default = 100,
    page = GVDrive,
    translation = GVDrive_Event_SecurityAlarm_Volume,
}
```

---

## 🌍 Traducciones a Agregar

### **Archivo:** `Translate/EN/Sandbox_EN.txt`

```lua
Sandbox_EN = {
    -- ... traducciones existentes ...
    
    -- Eventos de Laptop
    Sandbox_GVDrive_Event_Trigger_Chance = "Event Trigger Chance (%)",
    Sandbox_GVDrive_Event_Threshold_Low = "Low Failure Threshold",
    Sandbox_GVDrive_Event_Threshold_High = "High Failure Threshold",
    Sandbox_GVDrive_Event_DistressSignal_ZombieCount = "Distress Signal: Zombie Count",
    Sandbox_GVDrive_Event_DistressSignal_SpawnRadius = "Distress Signal: Spawn Radius",
    Sandbox_GVDrive_Event_AcceleratedDamage_Amount = "Accelerated Damage: Amount (%)",
    Sandbox_GVDrive_Event_SecurityAlarm_Duration = "Security Alarm: Duration (seconds)",
    Sandbox_GVDrive_Event_SecurityAlarm_Radius = "Security Alarm: Sound Radius",
    Sandbox_GVDrive_Event_SecurityAlarm_Volume = "Security Alarm: Volume",
}
```

---

## 🎮 Eventos Implementados

### **1. Señal de Socorro Falsa** (40% probabilidad)
- **Descripción:** Spawns 3-10 zombies en perímetro exterior (15-30 tiles)
- **Respeta safehouse:** ✅ Zombies aparecen FUERA, no dentro
- **Configurable:** Cantidad de zombies y radio de spawn

### **2. Daño Acelerado** (35% probabilidad)
- **Descripción:** Laptop pierde 10-40% de salud instantáneamente
- **Consecuencia:** Acelera degradación, necesita antivirus urgente
- **Configurable:** Cantidad de daño

### **3. Alarma de Seguridad** (25% probabilidad)
- **Descripción:** Emite sonido fuerte por 30-90 segundos
- **Consecuencia:** Atrae zombies cercanos (radio 30-100 tiles)
- **Configurable:** Duración, radio y volumen

---

## 🧪 Testing

### **Comandos de Debug:**

```lua
-- Recargar sistema de eventos
ReloadLaptopEvents()

-- Forzar evento manualmente (en consola Lua)
local player = getPlayer()
local laptop = player:getInventory():getItemFromType("AsusZephLaptopOpened")
local square = player:getCurrentSquare()

if LaptopEvents and laptop and square then
    -- Forzar evento específico
    LaptopEvents.triggerDistressSignal(player, laptop, square)
    LaptopEvents.triggerAcceleratedDamage(player, laptop, square)
    LaptopEvents.triggerSecurityAlarm(player, laptop, square)
    
    -- O usar el sistema de verificación normal
    LaptopEvents.checkAndTriggerEvent(player, laptop, square)
end
```

### **Verificar que funciona:**

1. Acumular 3+ fallos en una laptop
2. Fallar un minijuego
3. Observar logs para ver si se ejecuta evento
4. Verificar que el evento ocurre según probabilidad configurada

---

## 📊 Flujo Completo

```
Usuario falla minijuego
    ↓
MiniGameWindow:processFinalResult(false)
    ↓
Incrementa contador de fallos
    ↓
GVDrive_Utils.applyMinigameResult(..., success=false)
    ↓
Aplica daño a laptop
    ↓
LaptopEvents.checkAndTriggerEvent()
    ↓
Verifica fallos >= 3
    ↓
Tira dado (25% probabilidad base)
    ↓
Selecciona evento aleatorio (40/35/25%)
    ↓
Ejecuta evento seleccionado
    ↓
Jugador experimenta consecuencias
```

---

## ✅ Checklist de Implementación

- [x] Crear LaptopEvents.lua
- [x] Cargar en ClientInit.lua
- [x] Cargar en server/Init.lua
- [ ] Integrar en GVDrive_Utils.applyMinigameResult()
- [ ] Agregar configuraciones sandbox
- [ ] Agregar traducciones
- [ ] Probar en juego
- [ ] Ajustar probabilidades según feedback

---

## 🚀 Próximos Pasos

1. **Agregar integración manual** en GVDrive_Utils.lua (línea ~643)
2. **Agregar configuraciones** en sandbox-options.txt
3. **Agregar traducciones** en Sandbox_EN.txt
4. **Probar en juego** con diferentes configuraciones
5. **Ajustar balance** según experiencia de juego

**Estado:** Sistema implementado al 80%, falta integración final y configuraciones.
