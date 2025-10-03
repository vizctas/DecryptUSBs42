# 🎮 NEW FEATURES IMPLEMENTATION GUIDE
## DecryptUSBs42 - Enhanced Gameplay Systems

**Fecha de implementación:** 1 de octubre de 2025  
**Versión:** 1.5.0 - High Impact Features  
**Branch:** feat/failure-events

---

## 📋 RESUMEN DE NUEVAS CARACTERÍSTICAS

Se han implementado **5 sistemas de alto impacto y bajo esfuerzo** para añadir más vida, interacción y emoción al mod:

1. ✅ **Sistema de Sobrecalentamiento de Laptops** (LaptopThermalSystem)
2. ✅ **Sistema de Sorpresas en USBs** (USBSurpriseSystem)
3. ✅ **Mensajes Contextuales Dinámicos** (ContextualMessages)
4. ✅ **Sistema de Sonidos Dinámicos** (DynamicSoundSystem)
5. ✅ **Neural Boost - Buffs Temporales** (NeuralBoostSystem)

---

## 🌡️ 1. SISTEMA DE SOBRECALENTAMIENTO (LaptopThermalSystem)

### **Concepto:**
Las laptops ahora se calientan al usar minijuegos, especialmente los difíciles. Si se sobrecalientan, pueden fallar o dañarse.

### **Mecánicas:**
- **Temperatura inicial:** 20°C (ambiente)
- **Incremento por dificultad:**
  - Easy: +15°C
  - Moderate: +25°C
  - Expert: +35°C
- **Enfriamiento pasivo:** -2% por segundo (activo), -5% por segundo (cerrado)
- **Umbrales:**
  - 60-84°C: Caliente (advertencia)
  - 85-94°C: Crítico (penalización en próximo minijuego)
  - 95-100°C: Sobrecalentamiento (daño inmediato 5-10%)

### **Efectos visuales:**
- **Color en UI:** Azul (frío) → Verde → Amarillo → Naranja → Rojo (crítico)
- **Mostrado en:** Menú contextual junto a salud de laptop

### **Sandbox Options:**
- `GVDrive.Thermal_System_Enabled` (bool, default: true)

### **Funciones de Debug:**
```lua
ReloadThermalSystem()           -- Recargar sistema
DiagnoseThermalSystem()         -- Diagnóstico
SetLaptopTemp(85)              -- Forzar temperatura
```

---

## 🎁 2. SISTEMA DE SORPRESAS EN USBs (USBSurpriseSystem)

### **Concepto:**
Algunos USBs contienen recompensas adicionales ocultas al desencriptarlos exitosamente.

### **Probabilidades por dificultad:**
- Easy: 5% chance
- Moderate: 10% chance
- Expert: 15% chance
- Elite: 100% (siempre tiene sorpresa)

### **Tipos de Sorpresas:**
1. **Digital Schematic (25%)** - Desbloquea receta crafteable
   - Molotov Cocktail, Smoke Bomb, Remote Controller, Timer, etc.

2. **Survival Tip (35%)** - Buff instantáneo de moodle
   - Reduce estrés (-30), fatiga (-40%), hunger/thirst (-30%)
   - Cura salud (+5 overall health)

3. **Map Fragment (20%)** - Fragmento de mapa
   - Colecciona 5 fragmentos → Revela ubicación de tesoro

4. **Bonus XP (15%)** - XP extra en habilidad aleatoria
   - 50-100 XP en skill aleatorio

5. **Rare Item (5%)** - Item raro
   - Norton Antivirus (30%)
   - Kaspersky Antivirus (25%)
   - McAfee Antivirus (20%)
   - MalwareBytes Antivirus (15%)
   - Elite Drive (10%)

### **Sandbox Options:**
- `GVDrive.USB_Surprise_Chance_Modifier` (double, 0-5.0, default: 1.0)

### **Funciones de Debug:**
```lua
ReloadSurpriseSystem()
TestSurprise("recipe")    -- Test receta
TestSurprise("tip")       -- Test buff
TestSurprise("map")       -- Test fragmento
TestSurprise("xp")        -- Test XP bonus
TestSurprise("rare")      -- Test item raro
TestSurprise()            -- Test aleatorio
```

---

## 💬 3. MENSAJES CONTEXTUALES DINÁMICOS (ContextualMessages)

### **Concepto:**
Mensajes del jugador que reaccionan a la situación actual durante minijuegos.

### **Contextos detectados:**
- Salud baja de laptop (<15%)
- Zombies cerca (radio 10 tiles)
- Jugador estresado (>50% stress)
- Jugador herido (<50% health)
- Noche (21:00 - 05:00)
- En safehouse
- Temperatura alta de laptop (>85°C)
- Fallos acumulados (≥3)

### **Tipos de mensajes:**
- **Inicio:** "Quick, before they notice..." (con zombies)
- **Éxito:** "Done! Now RUN!" (con zombies)
- **Fallo:** "No... NO! Not like this!" (laptop crítica)
- **Especiales:** "It's getting HOT!" (sobrecalentamiento)

### **Ejemplos:**
```
[INICIO + ZOMBIES CERCA]
"Quick, before they notice..."
"Gotta make this fast!"

[ÉXITO + LAPTOP CRÍTICA]
"That was close... too close."
"By the skin of my teeth..."

[FALLO + ZOMBIES CERCA]
"Shit! They're coming!"
"No time for this!"

[SOBRECALENTAMIENTO]
"It's getting HOT!"
"This thing is gonna melt!"

[SORPRESA ENCONTRADA]
"Wait, there's more here..."
"Jackpot!"
```

### **Sandbox Options:**
- `GVDrive.Contextual_Messages_Enabled` (bool, default: true)

### **Funciones de Debug:**
```lua
ReloadContextualMessages()
TestContextMessage("start")
TestContextMessage("success")
TestContextMessage("failure")
TestContextMessage("overheat")
TestContextMessage("surprise")
```

---

## 🔊 4. SISTEMA DE SONIDOS DINÁMICOS (DynamicSoundSystem)

### **Concepto:**
Sonidos reactivos que mejoran la inmersión y feedback durante minijuegos.

### **Sonidos implementados:**
1. **Tecleo rítmico** - Durante minijuegos (se acelera con progreso)
2. **Sonido de éxito** - Al completar con éxito (épico para Elite)
3. **Sonido de fallo** - Al fallar minijuego
4. **Beep de advertencia** - Laptop <15% salud (urgente si <5%)
5. **Alarma de sobrecalentamiento** - Temperatura >85°C
6. **Sonido de ventilador** - Temperatura >60°C (volumen según temp)

### **Características:**
- **Volúmenes configurables** por tipo de sonido
- **Loops de sonido** durante minijuegos activos
- **Cooldown anti-spam** (2 segundos entre beeps)
- **Sonidos intensifican** según velocidad/dificultad

### **Integración:**
- Inicio de minijuego: Secuencia de "boot up"
- Durante minijuego: Loop de tecleo
- Fin de minijuego: Sonido épico o error
- Temperatura: Ventilador y alarmas automáticas

### **Sandbox Options:**
- `GVDrive.Dynamic_Sounds_Enabled` (bool, default: true)

### **Funciones de Debug:**
```lua
ReloadDynamicSound()
TestSound("typing")        -- Tecleo
TestSound("success")       -- Éxito normal
TestSound("epic")          -- Éxito épico
TestSound("failure")       -- Fallo
TestSound("warning")       -- Advertencia
TestSound("urgent")        -- Advertencia urgente
TestSound("overheat")      -- Sobrecalentamiento
TestSound("fan")           -- Ventilador
StartTypingLoop(1.5)       -- Iniciar loop a 1.5x velocidad
StopTypingLoop()           -- Detener loop
```

---

## ⚡ 5. NEURAL BOOST - BUFFS TEMPORALES (NeuralBoostSystem)

### **Concepto:**
Algunos USBs otorgan poderosos buffs temporales en vez de XP permanente.

### **Probabilidad:**
- Easy: 10%
- Moderate: 15%
- Expert: 20%
- (Modificable vía sandbox)

### **Tipos de Buffs:**

#### **1. Neural Focus (⚡)**
- **Duración:** 60 minutos
- **Efecto:** +50% XP en TODAS las habilidades
- **Uso ideal:** Antes de farming XP masivo

#### **2. Adrenaline Surge (💪)**
- **Duración:** 30 minutos
- **Efecto:** +30% velocidad de ataque
- **Uso ideal:** Antes de combate intenso

#### **3. Iron Mind (🧠)**
- **Duración:** 60 minutos
- **Efecto:** Inmunidad a pánico y estrés
- **Uso ideal:** Exploración peligrosa

#### **4. Metabolic Boost (🔋)**
- **Duración:** 45 minutos
- **Efecto:** 50% más lento hunger/thirst
- **Uso ideal:** Expediciones largas

#### **5. Enhanced Precision (🎯)**
- **Duración:** 30 minutos
- **Efecto:** +25% precisión y crit chance
- **Uso ideal:** Combate de largo alcance

### **Características:**
- **Buffs visibles** en UI con tiempo restante
- **No stackean** - solo 1 de cada tipo activo
- **Notificaciones visuales** al activarse y expirar
- **Integrado con XP** - Focus boost se aplica automáticamente

### **Sandbox Options:**
- `GVDrive.NeuralBoost_Chance_Modifier` (double, 0-5.0, default: 1.0)

### **Funciones de Debug:**
```lua
ReloadNeuralBoost()
TestNeuralBoost("focus")      -- Activar Focus
TestNeuralBoost("adrenaline") -- Activar Adrenaline
TestNeuralBoost("iron_mind")  -- Activar Iron Mind
TestNeuralBoost("metabolic")  -- Activar Metabolic
TestNeuralBoost("precision")  -- Activar Precision
TestNeuralBoost()             -- Activar aleatorio
ListActiveBoosts()            -- Ver buffs activos
ClearAllBoosts()              -- Limpiar todos
```

---

## 🔗 INTEGRACIÓN ENTRE SISTEMAS

### **Flujo completo de un minijuego:**

```
1. INICIO:
   ↓ ContextualMessages: Mensaje según situación
   ↓ DynamicSoundSystem: Sonido de inicio + loop de tecleo
   ↓ LaptopThermalSystem: Temperatura aumenta según dificultad

2. DURANTE:
   ↓ DynamicSoundSystem: Loop de tecleo se intensifica
   ↓ LaptopThermalSystem: Verificar sobrecalentamiento

3. ÉXITO:
   ↓ NeuralBoostSystem: Aplicar multiplicador Focus si activo
   ↓ USBSurpriseSystem: Verificar sorpresa (5-15% chance)
   ↓ NeuralBoostSystem: Activar buff temporal (10-20% chance)
   ↓ DynamicSoundSystem: Sonido de éxito (épico si Elite)
   ↓ ContextualMessages: Mensaje de éxito contextual

4. FALLO:
   ↓ LaptopThermalSystem: Temperatura aumenta + verificar overheat
   ↓ LaptopSystem: Daño a laptop
   ↓ LaptopEvents: Verificar eventos aleatorios (si ≥3 fallos)
   ↓ DynamicSoundSystem: Sonido de fallo + alarmas si crítico
   ↓ ContextualMessages: Mensaje de fallo contextual

5. POST-MINIJUEGO:
   ↓ DynamicSoundSystem: Detener loops
   ↓ LaptopThermalSystem: Enfriamiento pasivo automático
   ↓ NeuralBoostSystem: Buffs activos siguen corriendo
```

---

## 🎯 CÓMO PROBAR LAS NUEVAS CARACTERÍSTICAS

### **1. Sobrecalentamiento:**
```lua
-- En consola de debug:
SetLaptopTemp(90)              -- Forzar temperatura crítica
DiagnoseThermalSystem()        -- Ver estado completo
-- Usar minijuegos seguidos para ver acumulación de calor
```

### **2. Sorpresas:**
```lua
-- En consola de debug:
TestSurprise("map")            -- Probar fragmento de mapa
TestSurprise("rare")           -- Probar item raro
-- Descifrar USBs Expert para mayor chance (15%)
```

### **3. Mensajes Contextuales:**
```lua
-- Situaciones para probar:
-- • Descifrar con zombies cerca (10 tiles)
-- • Descifrar con laptop <15% salud
-- • Descifrar de noche (21:00-05:00)
-- • Fallar con 5+ fallos acumulados
TestContextMessage("start")    -- Probar mensaje de inicio
```

### **4. Sonidos:**
```lua
TestSound("epic")              -- Probar sonido épico
StartTypingLoop(2.0)           -- Loop rápido
-- Verificar que suenen durante minijuegos
```

### **5. Neural Boosts:**
```lua
TestNeuralBoost("focus")       -- Activar Focus
-- Descifrar USB y verificar +50% XP
ListActiveBoosts()             -- Ver buffs activos
-- Esperar 60 minutos in-game para expiración
```

---

## ⚙️ CONFIGURACIÓN SANDBOX

Todas las opciones están en la página **"Drive_Decrypt"** del sandbox:

### **Características Nuevas:**
- `Thermal_System_Enabled` (bool) - Habilitar sobrecalentamiento
- `USB_Surprise_Chance_Modifier` (0-5.0) - Multiplicador de sorpresas
- `NeuralBoost_Chance_Modifier` (0-5.0) - Multiplicador de buffs
- `Contextual_Messages_Enabled` (bool) - Habilitar mensajes
- `Dynamic_Sounds_Enabled` (bool) - Habilitar sonidos

### **Ajustes recomendados:**

**Para experiencia INTENSA:**
```
Thermal_System_Enabled = true
USB_Surprise_Chance_Modifier = 2.0    (doble chance)
NeuralBoost_Chance_Modifier = 2.0     (doble chance)
Contextual_Messages_Enabled = true
Dynamic_Sounds_Enabled = true
```

**Para experiencia CASUAL:**
```
Thermal_System_Enabled = false        (sin sobrecalentamiento)
USB_Surprise_Chance_Modifier = 3.0    (triple chance)
NeuralBoost_Chance_Modifier = 3.0     (triple chance)
Contextual_Messages_Enabled = true
Dynamic_Sounds_Enabled = true
```

---

## 📊 IMPACTO EN GAMEPLAY

### **Antes vs Después:**

| Aspecto | ANTES | DESPUÉS |
|---------|-------|---------|
| **Tensión** | Bajo - Solo preocupación por salud | Alto - Temperatura, zombies, fallos acumulados |
| **Recompensas** | Predecible - Solo XP | Variado - XP + sorpresas + buffs |
| **Feedback** | Básico - Texto simple | Rico - Sonidos + mensajes contextuales |
| **Estrategia** | Lineal - Descifrar siempre | Complejo - Cuándo descifrar, gestión de temperatura |
| **Emoción** | Monótono - Repetitivo | Dinámico - Cada USB es diferente |

### **Nuevas decisiones del jugador:**
- ¿Descifrar con laptop caliente arriesgando daño?
- ¿Esperar a enfriar o continuar rápidamente?
- ¿Usar Neural Boost ahora o guardarlo para momento crítico?
- ¿Arriesgar con zombies cerca por la sorpresa potencial?

---

## 🐛 TROUBLESHOOTING

### **Los sonidos no suenan:**
```lua
-- Verificar que el sistema esté cargado:
if DynamicSoundSystem then
    print("✅ Sistema cargado")
else
    print("❌ Sistema NO cargado")
    ReloadDynamicSound()
end

-- Verificar sandbox option:
-- Drive_Decrypt → Dynamic_Sounds_Enabled = true
```

### **Los mensajes no aparecen:**
```lua
-- Verificar cooldown (2 segundos entre mensajes):
TestContextMessage("start")
-- Esperar 2 segundos
TestContextMessage("success")

-- Verificar sandbox option:
-- Drive_Decrypt → Contextual_Messages_Enabled = true
```

### **La temperatura no sube:**
```lua
-- Verificar que el sistema esté habilitado:
-- Drive_Decrypt → Thermal_System_Enabled = true

DiagnoseThermalSystem()  -- Ver estado completo
```

### **No aparecen sorpresas:**
```lua
-- Aumentar chance en sandbox:
-- Drive_Decrypt → USB_Surprise_Chance_Modifier = 5.0

-- O forzar para testing:
TestSurprise()
```

---

## 📝 ARCHIVOS MODIFICADOS

### **Nuevos archivos creados:**
- `shared/LaptopThermalSystem.lua`
- `shared/USBSurpriseSystem.lua`
- `shared/ContextualMessages.lua`
- `shared/DynamicSoundSystem.lua`
- `shared/NeuralBoostSystem.lua`

### **Archivos modificados:**
- `client/ClientInit.lua` - Carga de nuevos sistemas
- `server/Init.lua` - Carga de nuevos sistemas
- `shared/GVDrive_Utils.lua` - Integración en applyMinigameResult()
- `client/MiniGameUI.lua` - Integración de sonidos y mensajes
- `client/DecryptDrivesContextMenu.lua` - Mostrar temperatura
- `sandbox-options.txt` - Nuevas opciones de configuración

---

## 🚀 PRÓXIMOS PASOS RECOMENDADOS

### **Fase 2 - Medio Impacto (Próxima actualización):**
1. **Minijuegos Alternativos** - 2-3 tipos diferentes de puzzles
2. **Laptop Modding** - Sistema de upgrades permanentes
3. **Hacking Reputation** - Progresión a largo plazo

### **Fase 3 - Alto Impacto (Futuro):**
1. **Data Terminals** - Puntos de descarga en el mundo
2. **Workshop** - Crafteo de USBs personalizados
3. **Black Market NPC** - Comercio de items tecnológicos

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

- [x] LaptopThermalSystem creado y funcional
- [x] USBSurpriseSystem creado y funcional
- [x] ContextualMessages creado y funcional
- [x] DynamicSoundSystem creado y funcional
- [x] NeuralBoostSystem creado y funcional
- [x] Integración en GVDrive_Utils.applyMinigameResult()
- [x] Integración en MiniGameUI.onStart()
- [x] Temperatura visible en menú contextual
- [x] Opciones de sandbox agregadas
- [x] Carga automática en ClientInit y server/Init
- [x] Funciones de debug para testing
- [x] Documentación completa

---

**¡Todas las características están listas para probar en juego!** 🎉

Para testear, inicia Project Zomboid, carga el mod, y usa las funciones de debug o simplemente juega normalmente para experimentar los nuevos sistemas en acción.
