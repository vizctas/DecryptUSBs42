#  DecryptUSBs42  Sistema de Desencriptación de USBs - (DEPRECATED - OUTDATED)

![Version](https://img.shields.io/badge/version-1.5.0-blue)
![Build](https://img.shields.io/badge/build-42.12%20Unstable-orange)
![Status](https://img.shields.io/badge/status-Estable-brightgreen)

Mod para Project Zomboid que introduce un ecosistema completo de desencriptación de unidades USB y minijuegos temáticos para desbloquear recompensas, buffs temporales y progresión de habilidades.

---

##  Características Clave
- **[Minijuegos dinámicos]** Tres experiencias únicas: Decrypt Sequence Terminal, Buffer Defense (tower-defense) y Packet Interceptor (ritmo/precisión).
- **[Sistemas conectados]** Salud de laptop, térmico, eventos aleatorios, Neural Boosts y recompensas sorpresa totalmente integrados.
- **[Dificultad escalable]** Configurable por sandbox y ajustable en tiempo real mediante comandos de debug (ReloadMiniGame*).
- **[XP y botín balanceado]** Cálculos dependientes de rareza, dificultad y multiplicadores sandbox, con soporte para bonificaciones como Neural Focus.
- **[Herramientas de desarrollo]** Recarga en vivo, pruebas dirigidas (TestMiniGame, TestBufferDefense, TestPacketInterceptor) y registro detallado.

---

##  Minijuegos Disponibles
- **Decrypt Sequence Terminal**  Memoria secuencial con estética CRT alienígena, patrones múltiples y feedback visual inmediato.
- **Buffer Defense**  Defiende firewalls contra exploits; incorpora oleadas, power-ups y eventos especiales.
- **Packet Interceptor**  Ritmo y reflejos para sincronizar paquetes; combo system y bonificaciones por precisión perfecta.

Cada minijuego expone funciones Reload* y Test* para ajustes rápidos desde la consola de debug (/ o L).

---

##  Sistemas Complementarios
- **LaptopSystem**: Durabilidad, daño escalado y sobrecalentamiento (LaptopThermalSystem).
- **NeuralBoostSystem**: Buffs temporales (Focus, Adrenaline, Iron Mind, Pack Mule, etc.) ahora con notificaciones seguras usando SafeHaloText.
- **USBSurpriseSystem**: Recetas, rare items, mapas y XP sorpresa basados en probabilidades configurables.
- **DynamicSoundSystem** & **ContextualMessages**: Audio y mensajes reactivos según éxito, fallo o eventos especiales.

---

##  Configuración Sandbox
Archivo: Contents/mods/DecryptSkillSys/42.0/media/sandbox-options.txt

- **Probabilidades** de aparición (loot/zombies), daños a laptop y XP por dificultad (Facil/Moderado/Dificil).
- **Modificadores** de Neural Boost, sorpresas y eventos (Event_*).
- **Multiplicadores** de XP por dificultad (Facil_XP_Bonus, Moderado_XP_Bonus, Dificil_XP_Bonus).

> Recuerda que Project Zomboid aplica además SandboxVars.XPMultiplier del mundo activo. Ajusta ambos valores si deseas XP final específica.

---

##  Instalación
- **Steam Workshop**: Suscríbete y activa el mod in-game.
- **Manual**: Copia el contenido de este repositorio a Zomboid/mods/DecryptUSBs42.
- **Dependencias**: Ninguna adicional; compatible con la build 42.12 Unstable.

---

##  Comandos de Debug Útiles
`lua
ReloadMiniGame()
ReloadMiniGameBufferDefense()
ReloadMiniGamePacket()
TestMiniGame(25, 35)
TestBufferDefense("Expert")
TestPacketInterceptor("Moderate")
`

---

##  Documentación
- **[CHANGELOG.md](CHANGELOG.md)**  Historial de versiones.
- **[WORKFLOW.md](WORKFLOW.md)**  Bitácora diaria y tareas pendientes.
- **docs/**  Auditorías, resúmenes ejecutivos y análisis detallados.

---

##  Roadmap
- **Fase 1  Entregado**: Separación modular de minijuegos, sistemas de eventos, balancing de XP/daño.
- **Fase 2  Planificado**: Nuevos puzzles, upgrades de laptops, reputación como hacker.
- **Fase 3  Futuro**: Data terminals en el mundo, crafteo avanzado de USBs, trader NPC y modo competitivo.

---

##  Cómo Contribuir
1. Haz fork del repositorio y crea tu rama (eature/<tu_feature> o ix/<bug>).
2. Mantén commits pequeños y descriptivos siguiendo convención conventional commits.
3. Ejecuta tus pruebas, actualiza documentación y abre un Pull Request detallado.

---

##  Reporte de Bugs
Abre un [Issue](../../issues) incluyendo:
- Pasos para reproducir.
- Resultado esperado vs actual.
- Logs relevantes (console.txt, debug log) y build del juego.

---

##  Licencia
Distribuido bajo licencia **MIT**. Revisa [LICENSE](LICENSE).

---

##  Autor
- **vizctas**  [@vizctas](https://github.com/vizctas)

---

##  Estado del Proyecto
- **Última actualización**: 5 de octubre de 2025
- **Versión**: 1.5.0  Enhanced Gameplay Update
- **Estado**: Production Ready 
