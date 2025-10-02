# 🌡️ Sistema de Temperatura de Laptops - Guía Completa

**Versión:** v1.5.14  
**Fecha:** 2025-10-01

---

## 📊 **Cómo funciona la temperatura**

### **Rangos de temperatura:**

| Temperatura | Estado | Color | Efecto |
|-------------|--------|-------|--------|
| **20-40°C** | Cool ❄️ | Azul | Sin penalizaciones |
| **40-60°C** | Warm 🟢 | Verde | Sin penalizaciones |
| **60-85°C** | Hot 🟡 | Amarillo | Sin penalizaciones (todavía) |
| **85-95°C** | CRITICAL 🟠 | Naranja | **30% chance de fallo** en próximo minigame |
| **95-100°C** | OVERHEAT! 🔴 | Rojo | **Daño inmediato** a la laptop (5-10%) |

---

## 🔥 **Qué calienta la laptop**

### **Cada minigame suma calor:**
- **Easy**: +15°C
- **Moderate**: +25°C
- **Expert**: +35°C

### **Ejemplo:**
```
Temperatura inicial: 20°C
Completas 3 minigames Expert: 20 + 35 + 35 + 35 = 125°C (capeado a 100°C)
Resultado: OVERHEAT! 🔴
```

---

## ❄️ **Cómo BAJAR la temperatura**

### **Método 1: Enfriamiento pasivo (laptop abierta)** ⏱️
- **Velocidad:** -2°C por segundo
- **Tiempo:** De 90°C a 20°C = ~35 segundos
- **Cómo:** Simplemente espera sin hacer minigames

### **Método 2: Enfriamiento rápido (laptop cerrada)** ⚡
- **Velocidad:** -5°C por segundo (2.5x más rápido)
- **Tiempo:** De 90°C a 20°C = ~14 segundos
- **Cómo:** **CIERRA la laptop en tu inventario**

### **Paso a paso para cerrar la laptop:**

#### **En el inventario:**
1. Haz **clic derecho** en la laptop
2. Selecciona **"Close Laptop"** (o similar)
3. Espera 14-35 segundos
4. Vuelve a abrir cuando esté más fría

#### **Visual:**
```
Laptop Abierta (GVDrive_Laptop_T1) → Enfriamiento lento (-2°C/seg)
      ↓ (clic derecho → Close)
Laptop Cerrada (GVDrive_Laptop_T1_Closed) → Enfriamiento rápido (-5°C/seg)
      ↓ (clic derecho → Open)
Laptop Abierta (enfriada) → Lista para usar
```

---

## ⚠️ **Consecuencias del sobrecalentamiento**

### **85-95°C (CRITICAL):**
- ⚠️ Mensaje: "The laptop is running very hot..."
- 🎲 **30% chance** de penalización en próximo minigame:
  - Dificultad aumentada
  - Menos tiempo
  - Más fallos forzados

### **95-100°C (OVERHEAT):**
- 🚨 Mensaje: "CRITICAL OVERHEAT! The laptop is burning up!"
- 💥 **Daño inmediato** a la laptop:
  - Mínimo: 5% de daño
  - Máximo: 10% de daño (a 100°C)
- 🔧 **Reduce durabilidad** de la laptop
- 🔊 Sonido de alarma
- ⚡ Enfriamiento forzado a 85°C

### **Si la laptop llega a 0% de durabilidad:**
- 💀 **Laptop destruida permanentemente**
- 📀 Pierdes todos los USBs conectados
- 💰 Necesitas conseguir/comprar otra laptop

---

## 💡 **Estrategias para evitar sobrecalentamiento**

### **1. Monitorear temperatura constantemente:**
```
Temperatura visible en:
- Tooltip de la laptop (al pasar el mouse)
- Context menu (al hacer clic derecho)
- Antes de iniciar minigame
```

### **2. Planificar sesiones de juego:**
```
✅ BUENO: 
- 1 minigame Expert (20→55°C)
- Esperar 18 segundos (laptop cerrada)
- 1 minigame Expert (20→55°C)
- Repetir

❌ MALO:
- 3 minigames Expert seguidos
- 20→55→90→100°C (OVERHEAT!)
- Laptop dañada
```

### **3. Usar enfriamiento óptimo:**
```
Temperatura < 60°C:
→ Puedes jugar directamente (no esperar)

Temperatura 60-85°C:
→ Esperar 10-20 segundos (laptop cerrada)

Temperatura > 85°C:
→ Esperar hasta < 40°C antes de continuar
```

### **4. Conseguir Liquid Cooling (futuro):**
```
Item: GVDrive_LiquidCooling
Efecto: -50% calor por minigame
Costo: [Por determinar]
```

---

## 🎮 **Ejemplo de uso en juego**

### **Sesión típica:**
```
1. Abrir laptop (20°C) ✅
2. Minigame Easy (+15°C = 35°C) ✅
3. Minigame Moderate (+25°C = 60°C) ✅
4. Minigame Expert (+35°C = 95°C) ⚠️ CRITICAL
5. ⏸️ PAUSA: Cerrar laptop 14 segundos
6. Abrir laptop (20°C) ✅
7. Continuar...
```

### **Señales de advertencia:**
```
🟡 60-85°C: "Laptop está caliente"
→ Considera enfriar pronto

🟠 85-95°C: "The laptop is running very hot..."
→ ¡ENFRIAR AHORA! (30% chance de fallo)

🔴 95-100°C: "CRITICAL OVERHEAT! The laptop is burning up!"
→ ¡DAÑO INMEDIATO! (5-10% de durabilidad)
```

---

## 🔧 **Troubleshooting**

### **"No veo la temperatura en ningún lado"**
- Pasa el mouse sobre la laptop en tu inventario
- Debe aparecer tooltip con temperatura
- Si no aparece, reportar bug

### **"La laptop se sobrecalentó y perdí durabilidad"**
- Es intencional, parte del sistema de balance
- Solución: Monitorear temperatura y enfriar entre sesiones
- Prevención: No hacer 3+ minigames seguidos sin enfriar

### **"No sé si mi laptop está cerrada o abierta"**
- Cerrada: Nombre termina en "..._Closed"
- Abierta: Nombre normal sin "_Closed"
- También visible en el ícono del item

### **"El enfriamiento es muy lento"**
- Laptop abierta: 2°C/seg (lento)
- **Laptop cerrada: 5°C/seg (rápido)** ⚡
- Tip: Siempre cerrar la laptop al enfriar

---

## 📈 **Cálculos útiles**

### **Tiempo de enfriamiento (90°C → 20°C):**
```
Laptop ABIERTA:
(90 - 20) / 2 = 35 segundos

Laptop CERRADA:
(90 - 20) / 5 = 14 segundos ⚡ (2.5x más rápido)
```

### **Minigames seguidos sin sobrecalentar:**
```
Easy (desde 20°C):
(85 - 20) / 15 = ~4 minigames seguidos

Moderate (desde 20°C):
(85 - 20) / 25 = ~2-3 minigames seguidos

Expert (desde 20°C):
(85 - 20) / 35 = ~1-2 minigames seguidos ⚠️
```

---

## ✅ **Checklist de buenas prácticas**

- [ ] Reviso temperatura antes de cada minigame
- [ ] Cierro la laptop para enfriar (no solo esperar)
- [ ] No hago más de 2 Expert seguidos sin enfriar
- [ ] Monitoreo durabilidad de la laptop constantemente
- [ ] Tengo laptop de respaldo en caso de daño crítico

---

## 🆘 **¿Necesitas ayuda?**

Si tienes dudas sobre el sistema de temperatura:
1. Lee esta guía completa
2. Experimenta con 1-2 minigames para ver el comportamiento
3. Observa los mensajes de advertencia del personaje
4. Ajusta tu estrategia según la temperatura

**Recuerda:** El sistema de temperatura añade **estrategia** y **realismo** al juego. No es un castigo, sino un recurso a administrar. 🎯
