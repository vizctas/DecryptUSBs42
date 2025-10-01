# 🔐 DecryptUSBs42 - USB Decryption System Mod

![Version](https://img.shields.io/badge/version-1.5.0-blue)
![Build](https://img.shields.io/badge/build-41+-green)
![Status](https://img.shields.io/badge/status-stable-brightgreen)

Un mod para Project Zomboid que añade un sistema completo de desencriptación de USBs con minijuegos, laptops con durabilidad, y sistemas de progresión avanzados.

---

## ✨ Características Principales

### 🎮 Sistema de Minijuegos
- **3 tipos de minijuegos** únicos para desencriptar USBs
- **Dificultades variables:** Easy, Moderate, Expert
- **Elite Drives** con mejoras permanentes
- **Sistema de fallos** con consecuencias dinámicas

### 💻 Sistema de Laptops
- **Durabilidad progresiva** con estados de salud
- **Sistema de sobrecalentamiento** (NUEVO en v1.5)
- **Malware y antivirus** para gestión de riesgos
- **Contador de fallos** con eventos aleatorios

### 🎁 Recompensas Mejoradas (NUEVO en v1.5)
- **Sorpresas en USBs:** Recetas, buffs, items raros
- **Neural Boosts:** Buffs temporales potentes
- **Fragmentos de mapa:** Colecciona 5 para tesoro
- **Bonus XP** en habilidades aleatorias

### 🔊 Experiencia Inmersiva (NUEVO en v1.5)
- **Sonidos dinámicos:** Tecleo, éxitos épicos, alarmas
- **Mensajes contextuales:** 40+ mensajes reactivos
- **Feedback rico:** Audio y texto según situación
- **Efectos visuales:** Temperatura, estados, notificaciones

---

## 🆕 Novedades en Versión 1.5.0

### 🌡️ Sistema de Sobrecalentamiento
Las laptops se calientan al usarlas. ¡Gestiona la temperatura o sufre las consecuencias!

### 🎁 Sorpresas en USBs
5-15% de USBs contienen recompensas ocultas: recetas, buffs, items raros.

### 💬 Mensajes Contextuales
El jugador reacciona según la situación: zombies cerca, laptop crítica, etc.

### 🔊 Sonidos Dinámicos
Tecleo rítmico, alarmas, ventilador, sonidos épicos para éxitos difíciles.

### ⚡ Neural Boosts
6 buffs temporales potentes: Focus (+50% XP), Adrenaline (+30% ataque), Iron Mind (inmunidad pánico), Metabolic (-50% hambre/sed), Precision (+25% precisión), **Pack Mule (+8kg capacidad x 2h)** ⭐

**[Ver changelog completo →](CHANGELOG.md)**

---

## 📦 Instalación

1. **Descargar** el mod desde [Releases](../../releases)
2. **Extraer** en la carpeta de mods de Project Zomboid:
   - Windows: `C:\Users\[Usuario]\Zomboid\mods`
   - Linux: `~/.zomboid/mods`
   - Mac: `~/Zomboid/mods`
3. **Activar** el mod en el menú de mods del juego
4. **Configurar** opciones de sandbox según preferencia
5. **¡Jugar!**

---

## 🎮 Cómo Jugar

### 1. Encontrar USBs
- **Zombie drops:** 10% chance (configurable)
- **World loot:** Oficinas, casas, escuelas
- **Elite drives:** 2% chance en zombies

### 2. Conseguir Laptop
- **Zombie drops:** 5% chance (configurable)
- **World loot:** Tiendas de electrónica, oficinas
- **Tipos:** Asus (moderna), IBM 90s (retro)

### 3. Desencriptar USBs
1. Abrir laptop en inventario (clic derecho)
2. Seleccionar "Decrypt USB Drive"
3. Completar minijuego de memoria
4. ¡Ganar XP en habilidades!

### 4. Gestionar Laptop
- **Salud:** Visible en menú contextual
- **Temperatura:** Enfriar si >85°C (NUEVO)
- **Malware:** Usar antivirus para limpiar
- **Fallos:** Evitar acumular 3+ o eventos aleatorios

---

## ⚙️ Configuración

Todas las opciones en **Sandbox → Drive_Decrypt**:

### Drops y Loot
- `USB_ZombieDrop_Chance` (0-100%, default: 10%)
- `Laptop_ZombieDrop_Chance` (0-100%, default: 5%)
- `USB_WorldLoot_Chance` (0-100%, default: 0.1%)

### Dificultad
- `USB_Min_Experience` (1-500, default: 25)
- `USB_Max_Experience` (1-1000, default: 150)
- `Malware_Chance` (0-100%, default: 15%)

### Nuevas Características (v1.5)
- `Thermal_System_Enabled` (bool, default: ON)
- `USB_Surprise_Chance_Modifier` (0-5x, default: 1.0)
- `NeuralBoost_Chance_Modifier` (0-5x, default: 1.0)
- `Contextual_Messages_Enabled` (bool, default: ON)
- `Dynamic_Sounds_Enabled` (bool, default: ON)

### Eventos Aleatorios
- `Event_Trigger_Chance` (0-100%, default: 25%)
- `Event_Threshold_Low` (1-10, default: 3 fallos)
- `Event_DistressSignal_ZombieCount` (3-15, default: 5)

**[Ver guía completa de configuración →](NEW_FEATURES_GUIDE.md)**

---

## 🧪 Testing y Debug

### Comandos de Debug (F11 console)

```lua
-- Sistema Térmico
DiagnoseThermalSystem()      -- Ver estado completo
SetLaptopTemp(90)            -- Forzar temperatura

-- Sorpresas
TestSurprise("rare")         -- Probar item raro
TestSurprise("map")          -- Probar fragmento

-- Mensajes
TestContextMessage("start")  -- Probar mensaje inicio
TestContextMessage("success")-- Probar mensaje éxito

-- Sonidos
TestSound("epic")            -- Probar sonido épico
StartTypingLoop(1.5)         -- Iniciar loop tecleo

-- Neural Boosts
TestNeuralBoost("focus")     -- Activar Focus (+50% XP)
TestNeuralBoost("pack_mule") -- Activar Pack Mule (+8kg) ⭐
ListActiveBoosts()           -- Ver buffs activos
ClearAllBoosts()             -- Limpiar todos

-- Recargar sistemas
ReloadThermalSystem()
ReloadSurpriseSystem()
ReloadContextualMessages()
ReloadDynamicSound()
ReloadNeuralBoost()
```

---

## 📊 Estadísticas del Mod

### Sistemas Implementados
- ✅ 5 sistemas de gameplay completos
- ✅ 3 tipos de minijuegos únicos
- ✅ 40+ mensajes contextuales
- ✅ 7 tipos de sonidos dinámicos
- ✅ 5 tipos de buffs temporales
- ✅ 5 tipos de sorpresas en USBs

### Código
- **~3,500 líneas** de código nuevo
- **+185 líneas** modificadas
- **30+ funciones** de debug
- **5 opciones** sandbox nuevas
- **0 errores** de sintaxis

### Compatibilidad
- ✅ Build 41+
- ✅ Singleplayer
- ✅ Multiplayer
- ✅ Partidas existentes
- ✅ Sin dependencias

---

## 📖 Documentación

- **[NEW_FEATURES_GUIDE.md](NEW_FEATURES_GUIDE.md)** - Guía técnica completa (inglés)
- **[NUEVAS_CARACTERISTICAS.md](NUEVAS_CARACTERISTICAS.md)** - Resumen ejecutivo (español)
- **[CHANGELOG.md](CHANGELOG.md)** - Historial de cambios
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Resumen visual

---

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

---

## 🐛 Reportar Bugs

¿Encontraste un bug? Abre un [Issue](../../issues) con:
- Descripción detallada del problema
- Pasos para reproducir
- Screenshots/logs si es posible
- Versión del mod y build de PZ

---

## 📝 Roadmap

### Fase 2 - Planificado
- [ ] Minijuegos alternativos (puzzles diferentes)
- [ ] Sistema de modding de laptops (upgrades)
- [ ] Sistema de reputación como hacker

### Fase 3 - Futuro
- [ ] Data Terminals en el mundo
- [ ] Workshop para craftear USBs custom
- [ ] NPC Black Market trader
- [ ] Multiplayer competitive features

**[Ver ideas completas →](WORKFLOW.md)**

---

## 📜 Licencia

Este proyecto está bajo la licencia MIT. Ver archivo [LICENSE](LICENSE) para más detalles.

---

## 👨‍💻 Autor

**vizctas**
- GitHub: [@vizctas](https://github.com/vizctas)

---

## 🙏 Agradecimientos

- Comunidad de Project Zomboid por feedback
- The Indie Stone por crear un juego tan moddeable
- Todos los que contribuyen y reportan bugs

---

## ⭐ ¿Te gusta el mod?

¡Dale una estrella al repositorio y comparte con amigos!

---

**Última actualización:** 1 de octubre de 2025  
**Versión:** 1.5.0 - Enhanced Gameplay Update  
**Estado:** Production Ready ✅
