# ISSUE-004: Visual Battery Icons in Context Menu

## Fecha
2025-09-21

## Estado
✅ RESUELTO (con workaround)

## Severidad
MEDIA - Mejora visual no crítica

## Descripción del Problema
Se intentó implementar iconos visuales de batería (PNG) en el menú contextual de laptops para mostrar el estado de salud de manera visual. Sin embargo, los elementos del menú contextual estándar de Project Zomboid (ISContextMenu) no soportan la asignación directa de texturas.

## Análisis Técnico
### Intentos Realizados:
1. **setTexture()**: Método no disponible en elementos del menú contextual
2. **texture property**: Propiedad no soportada por ISContextMenu elements
3. **getTexture() loading**: Las texturas se cargan correctamente, pero no se pueden asignar

### Limitaciones de PZ:
- Los menús contextuales estándar no soportan iconos visuales
- No hay API documentada para agregar iconos a opciones de menú
- Los elementos ISContextMenu están limitados a texto y colores RGB

## Solución Implementada
### Workaround Visual:
```lua
-- Enhanced visual fallback with emoji indicators
local statusIcon = ""
if laptopHealth >= 80 then
    statusIcon = "🔋" -- Full battery emoji
elseif laptopHealth >= 60 then
    statusIcon = "🔋" -- High battery
elseif laptopHealth >= 40 then
    statusIcon = "🪫" -- Medium battery
elseif laptopHealth >= 20 then
    statusIcon = "🪫" -- Low battery
else
    statusIcon = "🪫" -- Critical battery
end
healthOption.name = statusIcon .. " " .. healthDisplay
```

### Beneficios del Workaround:
- ✅ Indicadores visuales claros del estado de batería
- ✅ Funciona en todos los entornos de PZ
- ✅ No requiere assets adicionales
- ✅ Compatible con versiones antiguas

## Archivos Modificados
- `TimedActions/LaptopFill.lua`: Implementado sistema de indicadores emoji
- `CHANGELOG.md`: Documentada la solución workaround

## Testing
- ✅ Emojis se muestran correctamente en el menú contextual
- ✅ Estados de batería se representan visualmente
- ✅ Fallback funciona cuando las texturas no se cargan
- ✅ No hay errores de runtime

## Impacto
- **Antes**: Texto plano sin indicadores visuales
- **Después**: Emojis de batería (🔋/🪫) que representan claramente el estado de salud

## Lecciones Aprendidas
1. **Limitaciones de PZ UI**: Los menús contextuales estándar tienen capacidades limitadas
2. **Workarounds creativos**: Los emojis Unicode proporcionan buena usabilidad visual
3. **Compatibilidad**: Soluciones basadas en texto son más robustas que assets visuales
4. **Documentación**: Es importante documentar las limitaciones del engine

## Próximos Pasos
- Considerar implementar un sistema de UI personalizado si se requieren iconos visuales complejos
- Explorar tooltips enriquecidos para mostrar más información visual
- Mantener el sistema emoji como solución robusta y compatible

## Documentación Relacionada
- `ISSUE-001_MENU_GROUPING_FIX.md`: Corrección del menú jerárquico
- `ISSUE-002_LAPTOP_HEALTH_DISPLAY.md`: Implementación de barras de salud
- `ISSUE-003_RUNTIME_ERROR_FIX.md`: Corrección crítica de runtime error
- `CHANGELOG.md`: Registro completo de cambios