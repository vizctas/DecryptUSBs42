# 📋 **MI COMPRENSIÓN DEL PROYECTO DECRYPT USBs**

Basándome en el análisis exhaustivo del código y archivos, aquí está mi comprensión del proyecto:

## 🎯 **¿De Qué Trata el Proyecto?**

### **Proyecto Principal: "DecryptSkillSys"**
**Propósito:** Sistema de mod para Project Zomboid que permite a los jugadores **decryptar USBs** encontrados en laptops para obtener **bonos de experiencia en habilidades**.

---

## 🏗️ **Componentes Principales del Sistema**

### **1. Sistema de Laptops Interactivas**
```lua
-- Laptops en el mundo del juego que pueden:
- Tener diferentes estados de salud (0-100%)
- Contener malware que las daña
- Ser reparadas con antivirus
- Mostrar iconos visuales según su estado
```

### **2. Sistema de USBs con Datos**
```lua
-- USBs que contienen información de habilidades:
- Carpintería, Electricidad, Mecánica, Medicina
- Cada USB tiene un nivel de dificultad (Fácil, Moderado, Difícil)
- Contienen "datos" que otorgan XP al ser decryptados
```

### **3. Minijuego DECRYPT SEQUENCE TERMINAL**
```lua
-- Minijuego principal de 826 líneas:
- Grid 4x4 de botones configurable
- Secuencias aleatorias que recordar
- Sistema de dificultad con múltiples patrones
- Estética ALIEN CRT con efectos visuales
- Cierre automático configurable
```

### **4. Menú Contextual Avanzado**
```lua
-- Sistema de 1,007 líneas para:
- Detectar laptops en el mundo
- Mostrar opciones de interacción
- Sistema jerárquico de USBs por skill
- Opciones de antivirus y mejoras
- Iconos visuales de batería
```

### **5. Sistema de Loot y Probabilidades**
```lua
-- Configuración de chances:
- lootChance: Probabilidad de obtener loot (0.1-0.3)
- successBonus: Bonus de éxito por dificultad
- malwareChance: Probabilidad de malware
- laptopDamage: Daño potencial a laptops
```

---

## 🎮 **Flujo de Juego Principal**

### **Paso 1: Encontrar Laptop**
```lua
1. Jugador encuentra laptop en el mundo
2. Laptop tiene salud variable (0-100%)
3. Icono visual muestra estado (🔋/🪫)
```

### **Paso 2: Interacción con Menú Contextual**
```lua
1. Click derecho en laptop → Menú contextual
2. Opciones disponibles:
   - Health status (con icono visual)
   - USBs disponibles organizadas por skill
   - Opciones de antivirus si hay disponibles
   - Mejoras elite si tiene suficientes drives
```

### **Paso 3: Minijuego de Decrypt**
```lua
1. Seleccionar USB → Abre minijuego
2. Recordar secuencia de botones
3. Sistema de dificultad:
   - Fácil: Solo patrón verde
   - Moderado: Verde + Rojo (distractores)
   - Difícil: Verde + Rojo + Azul
4. Completar secuencia → Obtener XP de habilidad
```

### **Paso 4: Consecuencias**
```lua
- Éxito: +XP en habilidad + loot posible
- Fallo: Daño a laptop + posible malware
- Sistema de riesgo/recompensa
```

---

## 💰 **Sistema Económico**

### **Riesgos:**
- **Daño a laptop**: 3-20% según dificultad
- **Malware**: Probabilidad de infección
- **Pérdida de USB**: Si la laptop muere

### **Recompensas:**
- **XP de habilidad**: 2.0-6.5x bonus según dificultad
- **Loot**: 0.1-0.3 chance de items
- **Elite drives**: Mejoras permanentes del jugador

### **Reparación:**
- **Antivirus**: Diferentes tipos (Basic, Advanced, Premium)
- **Elite drives**: 2 del mismo tipo = mejora permanente

---

## 🎨 **Características Técnicas Avanzadas**

### **Estética ALIEN CRT**
- Fondo verde oscuro translúcido
- Líneas de escaneo horizontales
- Bordes verdes brillantes
- Título "DECRYPT SEQUENCE TERMINAL"
- Efectos de parpadeo y animación

### **Sistema de Timers Ultra Simple**
- Sin closures problemáticos
- Limpieza automática de recursos
- Eventos diferidos seguros

### **Validación Ultra Segura**
- pcall en todas las operaciones riesgosas
- Validación de tipos exhaustiva
- Fallbacks para todos los casos

---

## 🔧 **Configuración del Sistema**

### **Dificultades Disponibles:**
```lua
Normal = { successBonus = 2.0, lootChance = 0.1 }    -- Básico
Facil = { successBonus = 4.5, lootChance = 0.1 }     -- Fácil
Dificil = { successBonus = 6.5, lootChance = 0.3 }   -- Difícil
```

### **Habilidades Soportadas:**
- Carpintería (Carpentry)
- Electricidad (Electrical)
- Mecánica (Mechanics)
- Medicina (FirstAid)
- Cocina (Cooking)
- Metalurgia (MetalWelding)
- Sastrería (Tailoring)
- Puntería (Aiming)
- Farmacia (Pharmacy)

---

## 🎯 **¿Estoy en lo Correcto?**

**¿Es esto una comprensión precisa del proyecto?** Por favor corrígeme si:

1. **¿Me equivoqué en el propósito principal?**
2. **¿Hay componentes que no identifiqué?**
3. **¿La mecánica del juego es diferente?**
4. **¿Hay sistemas adicionales importantes?**
5. **¿El flujo de juego es incorrecto?**

**¿Quieres que profundice en algún aspecto específico o que corrija mi comprensión?**
