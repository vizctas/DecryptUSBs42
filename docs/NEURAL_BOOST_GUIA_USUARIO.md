# 🧠 Neural Boost System - Guía Completa del Usuario

**Versión:** v1.5.14  
**Fecha:** 2025-10-01  
**Mod:** DecryptUSBs42

---

## 📖 **¿Qué son los Neural Boosts?**

Los **Neural Boosts** son buffs temporales poderosos que se obtienen al usar ciertos USBs especiales. A diferencia de los USBs normales que otorgan XP permanente, estos USBs activan efectos temporales durante **30-120 minutos** que pueden mejorar drásticamente tu rendimiento en el juego.

---

## 🎯 **Tipos de Boosts Disponibles**

### **1. ⚡ Neural Focus**
- **Efecto:** +50% de ganancia de XP en TODAS las skills
- **Duración:** 60 minutos (1 hora)
- **Uso ideal:** Training intensivo, farming de XP
- **Ejemplo:** Si ganarías 100 XP en Carpentry, con el boost ganas 150 XP

### **2. 💪 Adrenaline Surge**
- **Efecto:** +30% de velocidad de ataque
- **Duración:** 30 minutos
- **Uso ideal:** Combat contra hordas, clearing de edificios
- **Ejemplo:** Ataques más rápidos = más zombies muertos por minuto

### **3. 🧠 Iron Mind**
- **Efecto:** Inmunidad total a pánico y estrés
- **Duración:** 60 minutos (1 hora)
- **Uso ideal:** Situaciones de alto estrés, hordas masivas
- **Ejemplo:** No entras en pánico al ver 50 zombies

### **4. 🔋 Metabolic Boost**
- **Efecto:** 50% menos hambre y sed
- **Duración:** 45 minutos
- **Uso ideal:** Expediciones largas, loot runs extendidas
- **Ejemplo:** Puedes explorar el doble de tiempo sin comer

### **5. 🎯 Enhanced Precision**
- **Efecto:** +25% de precisión y chance de critical hit
- **Duración:** 30 minutos
- **Uso ideal:** Combat de precisión, sniper gameplay
- **Ejemplo:** Más headshots, más crits = menos munición desperdiciada

### **6. 🎒 Pack Mule Enhancement**
- **Efecto:** +8kg de capacidad de carga
- **Duración:** 120 minutos (2 horas)
- **Uso ideal:** Loot runs, mudanzas, transport masivo
- **Ejemplo:** Puedes cargar 8kg extra (equivalente a ~40 latas)

---

## 🔍 **Cómo Obtener USBs de Neural Boost**

### **Método 1: Loot de Zombies (10% chance)**
- **Zombies élite** (zombies con armadura, policías, militares)
- **Drop rate:** ~10% de chance
- **Ubicación:** En cualquier lugar del mapa

### **Método 2: Desktop Computers**
- **Computadoras de escritorio** en oficinas, hogares
- **Búsqueda:** "Search computer for USBs"
- **Drop rate:** Variable según configuración del mod

### **Método 3: Crafting (si está implementado)**
- **Requisitos:** Laptop dañada + componentes electrónicos
- **Skill necesaria:** Electrical 3+
- **Receta:** Ver `GV_usb_recipes.txt`

### **Método 4: Traders/NPCs (si está implementado)**
- **Comerciantes especializados** en tecnología
- **Precio:** Variable (usualmente caro)

---

## 🎮 **Cómo Activar un Neural Boost**

### **Paso a paso:**

1. **Tener laptop funcional**
   - La laptop debe estar en tu inventario
   - Debe tener condición > 0%
   - No necesita estar "abierta"

2. **Insertar USB de Neural Boost**
   - Clic derecho en laptop → "Insert USB"
   - Seleccionar el USB de boost del inventario
   - El USB se insertará en la laptop

3. **Completar el minijuego**
   - Se abrirá uno de los minijuegos (Fallout, Encryption, etc.)
   - **Ganas:** El boost se activa automáticamente ✅
   - **Pierdes:** El USB se consume SIN activar el boost ❌
   - **Cierras prematuramente:** El USB se consume SIN activar el boost ❌

4. **Confirmación de activación**
   - Mensaje del jugador: "⚡ Neural Focus ACTIVATED!"
   - HaloText flotante verde: "Neural Focus (60min)"
   - El boost ahora está activo

---

## 👁️ **Indicadores Visuales: ¿Cómo Sé que Está Activo?**

### **Al activarse (inmediato):**
- **Mensaje del personaje** (speech bubble): "⚡ Neural Focus ACTIVATED!"
- **HaloText flotante verde** sobre tu cabeza: "Neural Focus (60min)"
- **Sonido de confirmación** (si disponible)

### **Durante el efecto (continuo):**
- **NO hay indicador visual permanente en el HUD** (por diseño del mod)
- El boost está "silencioso" una vez activado
- Solo se nota al expirar

### **Al expirar:**
- **Mensaje del personaje:** "Neural Focus has expired."
- **Log en consola:** "[NeuralBoost] Boost expired: focus"

### **Verificación manual:**
Puedes verificar si tienes boosts activos usando la consola de debug:

```lua
-- Abrir consola: Ctrl + F2 (o configuración de teclas)
local player = getPlayer()
local boosts = player:getModData().GVDrive_ActiveBoosts or {}

if next(boosts) then
    print("=== BOOSTS ACTIVOS ===")
    for boostType, info in pairs(boosts) do
        print("• " .. boostType)
        print("  Expira: " .. tostring(info.expiration))
        print("  Duración: " .. tostring(info.duration) .. " min")
    end
else
    print("No hay boosts activos")
end
```

---

## ⏰ **Gestión de Tiempo de Boosts**

### **Importante: El tiempo es IN-GAME, no tiempo real**

- **1 minuto in-game** ≠ 1 minuto real
- **Depende de la velocidad del juego:**
  - Velocidad 1x: 1 minuto in-game = ~2-3 segundos real
  - Velocidad 10x: 1 minuto in-game = ~0.2-0.3 segundos real
  - Velocidad máxima (fast forward): 1 minuto in-game = instantáneo

### **El tiempo CONTINÚA corriendo si:**
- ❌ Pausas el juego (Escape) → El boost SIGUE activo
- ❌ Duermes → El boost SIGUE activo y puede expirar mientras duermes
- ❌ Fast-forward → El boost se consume MÁS RÁPIDO

### **El tiempo SE DETIENE si:**
- ✅ Cierras el juego completamente (guardado)
- ✅ Sales al menú principal

### **Tips de gestión:**
- No uses boosts si vas a dormir inmediatamente
- Planea actividades largas antes de activar boosts
- Usa fast-forward con precaución

---

## 💡 **Múltiples Boosts Simultáneos**

### **✅ SÍ, puedes tener múltiples boosts activos a la vez**

- **No hay límite** de cantidad de boosts activos
- Cada boost tiene su **propio timer independiente**
- Los efectos **se acumulan**

### **Ejemplo de Combo Letal:**
```
1. Neural Focus (+50% XP)
2. Adrenaline Surge (+30% attack speed)
3. Enhanced Precision (+25% accuracy/crit)
4. Iron Mind (inmunidad a pánico)

Resultado: Máquina de matar XP
- Matas zombies más rápido (adrenaline)
- Con más precisión (enhanced precision)
- Sin entrar en pánico (iron mind)
- Ganando 1.5x XP por cada kill (neural focus)
```

### **Combo Recomendados:**

**🔥 Combo "XP Farming"**
- Neural Focus + Iron Mind
- Duración: 60 minutos
- Uso: Training skills en áreas peligrosas

**🎒 Combo "Loot Master"**
- Pack Mule + Metabolic Boost
- Duración: 45-120 minutos
- Uso: Loot runs extendidas sin cansarte

**⚔️ Combo "Warrior"**
- Adrenaline + Enhanced Precision + Iron Mind
- Duración: 30-60 minutos
- Uso: Clearing de hordas masivas

---

## 📊 **Ejemplos Prácticos de Uso**

### **Escenario 1: Grinding de Carpentry**

**Situación:**
- Necesitas farmear Carpentry level 5 → 7
- Tienes madera y clavos preparados

**Estrategia:**
1. Activa **Neural Focus** (+50% XP)
2. Construye paredes/puertas/ventanas durante 60 minutos
3. **Resultado:** En vez de ganar 800 XP, ganas 1,200 XP

**Cálculo:**
```
Sin boost: 60 min × 13.3 XP/min = 800 XP
Con boost: 60 min × 20 XP/min = 1,200 XP
Ahorro: ~27 minutos de grinding
```

---

### **Escenario 2: Loot Run a Louisville**

**Situación:**
- Viaje largo desde base → Louisville
- Necesitas cargar muchos items
- No quieres parar a comer constantemente

**Estrategia:**
1. Activa **Pack Mule** (+8kg carry)
2. Activa **Metabolic Boost** (50% menos hambre)
3. Haz el loot run completo (2-3 horas)
4. **Resultado:**
   - Cargas 8kg más items
   - Comes la mitad de veces
   - Viaje más eficiente

---

### **Escenario 3: Clearing de Horda en Warehouse**

**Situación:**
- Warehouse con 100+ zombies
- Necesitas clearear para establecer base

**Estrategia:**
1. Activa **Adrenaline Surge** (+30% attack speed)
2. Activa **Enhanced Precision** (+25% accuracy/crit)
3. Activa **Iron Mind** (inmunidad a pánico)
4. **Resultado:**
   - Matas zombies 30% más rápido
   - Más headshots/crits = menos hits necesarios
   - No entras en pánico al ver horda

---

### **Escenario 4: Night Watch/Guard Duty**

**Situación:**
- Base en zona peligrosa
- Necesitas hacer guardia nocturna

**Estrategia:**
1. Activa **Iron Mind** (60 min)
2. Activa **Enhanced Precision** (30 min)
3. **Resultado:**
   - No te asustas en la oscuridad
   - Disparos más precisos = menos munición desperdiciada

---

## ❓ **Troubleshooting**

### **"No veo el boost activo en ningún lado"**

**Solución:**
1. Verifica en ModData con comando Lua (ver sección "Indicadores Visuales")
2. El boost **solo muestra mensaje al activarse**, no hay HUD permanente
3. Si no ves mensaje al activar, es posible que hayas perdido el minijuego

---

### **"Mi boost desapareció antes de tiempo"**

**Posibles causas:**
1. **Dormiste:** El tiempo in-game siguió corriendo mientras dormías
2. **Fast-forward:** Aceleraste el tiempo y el boost expiró más rápido
3. **Error de cálculo:** Los boosts usan tiempo in-game, no tiempo real

**Verificación:**
```lua
-- Abrir consola
local player = getPlayer()
local gameTime = getGameTime()
local currentTime = gameTime:getTimeInMillis()
print("Tiempo actual in-game: " .. currentTime)

-- Verificar expiration del boost
local boosts = player:getModData().GVDrive_ActiveBoosts or {}
for boostType, info in pairs(boosts) do
    print("Boost: " .. boostType)
    print("  Expira en: " .. (info.expiration - currentTime) .. " ms")
end
```

---

### **"El boost no se activó al ganar el minijuego"**

**Posibles causas:**
1. **USB incorrecto:** El USB no es de tipo "Neural Boost"
   - Verifica nombre del USB: debe decir "Neural Boost" en descripción
   - Algunos USBs dan XP permanente, no boosts
   
2. **Error de mod:** Verifica logs de consola
   ```
   // Buscar en console.txt
   [NeuralBoost] WARNING: ...
   [NeuralBoost] ERROR: ...
   ```

3. **Laptop no válida:** La laptop puede estar dañada o corrupta

**Solución:**
- Usa un USB definitivamente de tipo "Neural Boost"
- Verifica condición de laptop (>20% recomendado)
- Revisa logs para errores específicos

---

### **"¿Los boosts se pierden al morir?"**

**Respuesta:** **SÍ**
- Al morir, pierdes TODOS los boosts activos
- Los boosts están ligados al **personaje**, no al mundo
- Al respawnear, debes activar nuevos boosts

---

### **"¿Puedo pausar un boost?"**

**Respuesta:** **NO**
- No hay forma de pausar un boost una vez activado
- El boost durará su tiempo completo o hasta que mueras
- Planea tus actividades antes de activar boosts

---

### **"¿Los boosts funcionan en multiplayer?"**

**Respuesta:** **SÍ**
- Los boosts funcionan igual en singleplayer y multiplayer
- Cada jugador tiene sus propios boosts independientes
- Los efectos no afectan a otros jugadores (excepto indirect benefits)

---

## 🎓 **Tips Avanzados**

### **1. Combo Timing**
Activa boosts de distinta duración en orden:
```
1. Pack Mule (120 min)
2. Metabolic Boost (45 min)
3. Adrenaline Surge (30 min)

Resultado: Tendrás al menos 30 min con los 3 activos
```

### **2. Pre-activación**
Activa boosts ANTES de comenzar la actividad:
- No actives Neural Focus a mitad de training
- No actives Pack Mule cuando ya estás sobrecargado

### **3. Gestión de Inventario**
Guarda USBs de boost para situaciones críticas:
- No gastes Neural Focus en farming basura
- Guarda Adrenaline para hordas reales

### **4. Verificación Periódica**
Cada 10-15 minutos, verifica si tus boosts siguen activos:
```lua
-- Macro rápido
local b=getPlayer():getModData().GVDrive_ActiveBoosts or {}
for k,_ in pairs(b) do print("✅ "..k) end
```

---

## 📚 **Resumen Rápido (TL;DR)**

1. **Neural Boosts** = Buffs temporales (30-120 min)
2. **Obtención:** Zombies élite (10%), computers, crafting
3. **Activación:** Insertar USB → Ganar minijuego → Boost activo
4. **Múltiples boosts:** ✅ SÍ, se acumulan
5. **Indicador visual:** Mensaje al activar, NO HUD permanente
6. **Tiempo:** IN-GAME, no tiempo real
7. **Al morir:** Se pierden TODOS los boosts
8. **Mejor uso:** Planear actividades largas antes de activar

---

## 🆘 **Soporte**

Si necesitas ayuda:
1. Revisa esta guía completa
2. Verifica logs de consola (`console.txt`)
3. Usa comando Lua para verificar estado de boosts
4. Reporta bugs con contexto completo

**Mod:** DecryptUSBs42  
**Autor:** joshg (vizctas)  
**Versión:** v1.5.14
