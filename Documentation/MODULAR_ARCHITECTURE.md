# Arquitectura Modular - DecryptUSBs42

## Estado: EN DESARROLLO

### Visión General
La refactorización de ISSUE-003 busca implementar una arquit### Plan de Implementación

1. ✅ **Fase 1:** Debug output centralizado (Completado)
2. ✅ **Fase 2:** Implementar patrón Strategy (Completado)
3. ✅ **Fase 3:** Implementar patrón Factory (Completado)
4. ✅ **Fase 4:** Crear MenuController (Completado)
5. ✅ **Fase 5:** Integrar sistema modular (Completado)
6. 🔄 **Fase 6:** Implementar patrón Observer (En progreso)
7. ⏳ **Fase 7:** Crear handlers separados
8. ⏳ **Fase 8:** Documentar arquitectura finalodular y mantenible aplicando patrones de diseño reconocidos.

### Cambios Implementados

#### 1. Debug Output Centralizado ✅ COMPLETADO
- **Antes:** `print()` directos dispersos por el código
- **Después:** Función `debugPrint()` centralizada condicional en `GVDrive_Config.getDebug()`
- **Beneficio:** Debug output configurable, reducción de ruido en producción

**Archivos modificados:**
- `DecryptDrivesContextMenu.lua`: Todas las funciones principales actualizadas

#### 2. Patrón Strategy ✅ COMPLETADO
**Implementación:** Estrategias intercambiables para diferentes tipos de menú
- `MenuCreationStrategy`: Clase base abstracta
- `HierarchicalMenuStrategy`: Implementación concreta para menú Skill → Difficulty

**Archivos creados:**
- `DecryptDrivesContextMenu/strategies/MenuCreationStrategy.lua`
- `DecryptDrivesContextMenu/strategies/HierarchicalMenuStrategy.lua`

#### 3. Patrón Factory ✅ COMPLETADO
**Implementación:** Centralización de creación de componentes de menú
- `MenuComponentFactory`: Factory para crear opciones, submenús, etc.
- Métodos: `createMainMenuOption()`, `createSkillCategoryOption()`, `createDifficultyOption()`

**Archivos creados:**
- `DecryptDrivesContextMenu/factories/MenuComponentFactory.lua`

#### 4. MenuController ✅ COMPLETADO
**Implementación:** Orquestador principal que usa estrategias
- `MenuController`: Gestiona estrategias y valida parámetros
- Integración con fallback a implementación legacy

**Archivos creados:**
- `DecryptDrivesContextMenu/MenuController.lua`

#### 5. Integración Modular ✅ COMPLETADO
**Implementación:** Sistema modular con compatibilidad hacia atrás
- Actualización de `DecryptDrivesContextMenu.lua` para usar componentes modulares
- Fallback automático a implementación legacy si módulos no están disponibles

### Estructura de Directorios Actual

```
DecryptDrivesContextMenu/
├── MenuController.lua                    # Controlador principal
├── strategies/                           # Estrategias de menú
│   ├── MenuCreationStrategy.lua         # Clase base Strategy
│   └── HierarchicalMenuStrategy.lua     # Implementación concreta
├── factories/                            # Factorías de componentes
│   └── MenuComponentFactory.lua         # Factory para componentes
└── handlers/                             # Handlers específicos (pendiente)
    └── (por implementar)
```

### Próximos Cambios Planificados

#### 2. Patrón Strategy - Estrategias de Creación de Menú
**Objetivo:** Permitir diferentes estrategias de creación de menú sin modificar el código cliente.

```lua
-- Estrategia base
MenuCreationStrategy = {
    createMenu = function(player, context, laptop, usbList) end
}

-- Estrategia jerárquica actual
HierarchicalMenuStrategy = {
    createMenu = function(player, context, laptop, usbList)
        -- Lógica actual de createHierarchicalMenu
    end
}

-- Estrategia futura (ejemplo)
FlatMenuStrategy = {
    createMenu = function(player, context, laptop, usbList)
        -- Menú plano sin jerarquía
    end
}
```

#### 3. Patrón Factory - Creación de Componentes de Menú
**Objetivo:** Centralizar la creación de componentes de menú (opciones, submenús, etc.)

```lua
MenuComponentFactory = {
    createOption = function(text, target, method, ...)
        return {text = text, target = target, method = method, args = {...}}
    end,

    createSubMenu = function(parentOption, context)
        local subMenu = ISContextMenu:getNew(context)
        context:addSubMenu(parentOption, subMenu)
        return subMenu
    end
}
```

#### 4. Patrón Observer - Cambios de Estado del Menú
**Objetivo:** Permitir que componentes reaccionen a cambios en el estado del menú.

```lua
MenuStateObserver = {
    observers = {},

    subscribe = function(observer)
        table.insert(self.observers, observer)
    end,

    notify = function(event, data)
        for _, observer in ipairs(self.observers) do
            if observer[event] then
                observer[event](data)
            end
        end
    end
}
```

#### 5. Separación de Handlers
**Objetivo:** Separar responsabilidades en clases dedicadas.

```
DecryptDrivesContextMenu/           # Módulo principal
├── MenuController.lua             # Controlador principal
├── strategies/                    # Estrategias de menú
│   ├── HierarchicalStrategy.lua
│   └── FlatStrategy.lua
├── factories/                     # Factorías de componentes
│   └── MenuComponentFactory.lua
└── handlers/                      # Handlers específicos
    ├── USBDetector.lua
    ├── LaptopValidator.lua
    └── LegacyMenuSuppressor.lua
```

### Beneficios Esperados

1. **Mantenibilidad:** Código más fácil de modificar y extender
2. **Testabilidad:** Componentes desacoplados facilitan pruebas unitarias
3. **Reutilización:** Componentes reutilizables en diferentes contextos
4. **Legibilidad:** Separación clara de responsabilidades
5. **Escalabilidad:** Fácil agregar nuevas funcionalidades

### Plan de Implementación

1. ✅ **Fase 1:** Debug output centralizado (Completado)
2. 🔄 **Fase 2:** Implementar patrón Strategy (En progreso)
3. ⏳ **Fase 3:** Implementar patrón Factory
4. ⏳ **Fase 4:** Implementar patrón Observer
5. ⏳ **Fase 5:** Separar handlers en módulos dedicados
6. ⏳ **Fase 6:** Documentar y probar nueva arquitectura

### Riesgos y Consideraciones

- **Compatibilidad:** Asegurar que cambios no rompan funcionalidad existente
- **Performance:** Patrones de diseño pueden agregar overhead mínimo
- **Complejidad:** No sobre-ingenierizar para funcionalidad simple
- **Testing:** Implementar tests para validar nueva arquitectura

### Métricas de Éxito

- Reducción de código duplicado: >50%
- Facilidad de agregar nuevas estrategias de menú: Alta
- Mantenibilidad del código: Mejorada significativamente
- Performance impact: <5% degradation

---

**Fecha:** 2025-09-19
**Estado:** Primera fase completada, arquitectura planificada