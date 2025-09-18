# Documentación: Configuración del Sandbox para Decrypt Drives

## Descripción General

Hemos implementado un sistema completo de configuración del Sandbox para el mod Decrypt Drives, permitiendo a los jugadores personalizar varias opciones relacionadas con las tasas de drop, probabilidades de desencriptación, experiencia y más.

## Archivos Modificados

1. **ClientInit.lua**
   - Añadida carga de traducciones
   - Añadida carga del panel de opciones del Sandbox

2. **Nuevos archivos creados:**
   - `client/OptionScreens/Sandbox/DecryptDriveSandbox.lua` - Configuración base del Sandbox
   - `client/OptionScreens/Sandbox/DecryptDriveSandboxPanel.lua` - Interfaz de usuario del Sandbox
   - `shared/Translate/EN/UI_EN.txt` - Traducciones al inglés
   - `shared/Translate/ES/UI_ES.txt` - Traducciones al español

## Opciones Configurables

### Tasas de Drop
- **Probabilidad de Drop de USB**: Controla la probabilidad de que los zombis suelten USBs.
- **Probabilidad de Drop de Laptop**: Controla la probabilidad de que los zombis suelten Laptops.
- **Probabilidad de Drop de Disco Élite**: Controla la probabilidad de que los zombis suelten Discos Élite.
- **Probabilidad de Drop de Antivirus**: Controla la probabilidad de que los zombis suelten software antivirus.

### Probabilidades de Desencriptación
- **Éxito en Desencriptar USB**: Probabilidad de éxito al desencriptar un USB.
- **Éxito en Desencriptar Disquete**: Probabilidad de éxito al desencriptar un disquete.

### Configuración de Experiencia
- **XP Mínima/Máxima de USB**: Rango de experiencia por desencriptar un USB.
- **XP Mínima/Máxima de Disquete**: Rango de experiencia por desencriptar un disquete.

### Loot en el Mundo
- **Activar Loot en el Mundo**: Habilita/deshabilita la generación de ítems en el mundo.
- **Probabilidades de Loot**: Controla la probabilidad de encontrar ítems en contenedores.

### Tasas de Antivirus
- **Tasas de Drop**: Controla la frecuencia relativa de los diferentes tipos de software antivirus.

## Cómo Acceder a la Configuración

1. Inicia Project Zomboid
2. Ve a "Juego de un jugador" o "Multijugador"
3. Selecciona "Opciones del Sandbox"
4. Busca la pestaña "Decrypt Drives Settings"
5. Ajusta las opciones según tus preferencias

## Solución de Problemas

Si las opciones no aparecen:
1. Verifica que el mod esté correctamente instalado
2. Asegúrate de que la versión del mod sea compatible con tu versión de Project Zomboid
3. Revisa los registros del juego para ver si hay errores de carga

## Notas para Desarrolladores

- Las opciones del Sandbox se guardan en el archivo de configuración del mundo.
- Los cambios en las opciones requieren reiniciar el mundo para que surtan efecto.
- Las traducciones se cargan automáticamente según el idioma del juego.

---
*Documentación actualizada: 2025-09-18*
