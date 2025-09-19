---
applyTo: '**'
---
Proporciona contexto del proyecto y pautas de codificación que la IA debe seguir al **generar código LUA**, **responder preguntas** o **revisar cambios**.

# Instrucciones del Codebase de Project Zomboid — Guía para IA

**Ubicación del CODEBASE:** `C:\Users\joshg\repos\pzomboid_mod_study\docs`

La IA debe **consultar primero el CODEBASE**. El **CODEBASE es la fuente de verdad**. Si el CODEBASE **no** contiene la respuesta, la IA puede usar conocimiento externo **citando la fuente** y proponiendo **cómo** incorporar la información al CODEBASE (PR/issue/ADR).

---

## 📤 Formato de las respuestas de la IA (salidas)
- **Idioma:** siempre **español**.
- **Estilo:** **resumido, claro y conciso**; evitar verborrea.
- **Estructura:** usar **títulos** y **subtítulos**; listas cuando ayuden.
- **Emojis:** usar con moderación para mejorar legibilidad (p. ej., ✅, 📌, ⚠️, 🧪, 🧠).
- **Citaciones:**
  - Si la respuesta proviene del **CODEBASE**, indicar **ruta de archivo** y, si aplica, sección/líneas.
  - Si proviene de **fuentes externas**, enlazar **documentación oficial** o repos reputados.
- **Prioridad de contenido:** 1) CODEBASE → 2) Docs oficiales del proyecto → 3) Otras fuentes confiables.
- **Ejemplos de código:** breves, compilables, con comentarios **solo si aportan claridad**.

---

## 🧭 Principios rectores
1. **Fuente de la verdad:** el CODEBASE manda. No inventar APIs ni comportamientos.
2. **Trazabilidad:** cada decisión importante debe dejar rastro (PR, issue, ADR, Changelog).
3. **Iteración segura:** cambios pequeños, atómicos, con pruebas y reversibilidad.
4. **Consistencia:** mismas convenciones en todo el repositorio (nombres, estilo, estructura).
5. **Documentar al cambiar:** “si cambias el comportamiento, cambias la documentación”.

---

- **Ramas:**
  - `main` o `release/*`: estable/protegida.
  - `feature/<tema>`: nuevas funciones.
  - `fix/<issue>`: correcciones.
  - `chore/docs/build`: tareas de soporte.
- **Commits:** **Conventional Commits** (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `build:`, `chore:`).
- **PRs:** pequeños, con descripción clara y checklist (ver sección de revisiones).

---

## 📚 Documentación (ampliada)
**Tipos de documentación:**
- **Javadoc**: API pública siempre documentada y generable.
- **README.md por módulo**: propósito, instalación, uso, ejemplos, limitaciones.
- **ADR (Architecture Decision Record)**: `/docs/adr/ADR-YYYYMMDD-titulo.md` (si aplica).
- **How-To / Recetas**: `/docs/howto/...` (pasos concretos por tarea).
- **Ejemplos ejecutables**: `/docs/examples/` (snippets mínimos).
- **Diagramas**: `/docs/diagrams/` (mermaid/PlantUML).

**Reglas:**
- La **doc se actualiza junto con el cambio** (misma PR o PR encadenada).
- Enlazar entre README ↔ Javadoc ↔ ejemplos ↔ ADR.
- Si no puedes completar doc, crear **issue** de **deuda de documentación** con checklist y due date.
- Mantener **índice** en `docs/README.md` para navegación.

**Plantillas rápidas:**
- `README.md`:
  ```md
  # Nombre del módulo
  **Propósito** | **Cómo usar** | **Ejemplos** | **Limitaciones** | **Changelog local**
  ```
- `ADR`:
  ```md
  # ADR: Título
  **Fecha** | **Estado** | **Contexto** | **Decisión** | **Consecuencias** | **Alternativas**
  ```

---

## �🔍 Revisiones punto a punto (file-by-file)
**Severidad de comentarios:**
- `[BLOQUEANTE]` rompe compilación/contrato/seguridad/compatibilidad.
- `[MAYOR]` diseño/arquitectura/rendimiento cuestionable.
- `[MENOR]` legibilidad/estilo.
- `[NIT]` sugerencia opcional.

**Cada PR debe incluir:**
- **Contexto** (problema/objetivo) y alcance.
- **Diseño** (decisiones clave; link a ADR si aplica).
- **Impacto** (API, compatibilidad, mods afectados).
- **Plan de pruebas** (qué y cómo se probó; casos borde; datos).
- **Docs actualizadas** (README/ADR/how-to).
- **Riesgos y mitigación**.
- **Changelog** actualizado.
- **Métricas** (si aplica: latencia, memoria, cobertura).

**Checklist de revisión:**
- [ ] Compila y pasa CI (lint, tests, análisis estático).
- [ ] Nombres y estructura claros; sin código muerto.
- [ ] Manejo de errores y logs adecuados.
- [ ] Tests suficientes, deterministas y aislados.
- [ ] Documentación y Changelog al día.
- [ ] Sin fugas de secretos ni licencias problemáticas.

---

## 🧹 Código limpio & 🧪 pruebas **aisladas del src**
**Principios de clean code:**
- Nombres expresivos; funciones/Clases pequeñas; **DRY** y **KISS**.
- Evitar acoplamiento; favorecer composición sobre herencia.
- Eliminar código comentado y TODOs eternos (abrir issues si es necesario).
- Sin side-effects inesperados; limitar alcance de variables.


**Automatización de calidad:**
- Build falla si: formateo/lint incorrecto, reglas estáticas rotas o cobertura por debajo de umbral.
- Sonar/PMD/SpotBugs sin **code smells** nuevos ni deuda técnica neta positiva.

---

## 📌 CODEBASE como **fuente de verdad**
- **Orden de consulta:** CODEBASE → docs oficiales → externas.
- **Canonicalización de funciones (mods):**
  - Si varios mods implementan **la misma función** con **nombres distintos**, documentar **una API canónica** y listar **aliases/sinónimos**.
  - Mantener un **repositorio/índice de funciones extraídas** para trazabilidad (quién, dónde, por qué).
  - En documentación final, **presentar una sola función** representativa con nombre consistente y explicación detallada.
- **Gaps del CODEBASE (LUA):**
  - Si algo **no existe**, declararlo explícitamente y proponer **plan de incorporación** (issue/PR/ADR) o alternativa segura.

---

## 🗒️ Changelog continuo
- Seguir **Keep a Changelog** + **SemVer**.
- `CHANGELOG.md` **global** y, si aplica, **por módulo**.
- Categorías: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.
- **Regla:** **todo PR** que cambie comportamiento **debe** actualizar el Changelog con fecha, versión y links a issues/PRs.
- Ejemplo:
  ```md
  ## [1.4.0] - 2025-09-19
  ### Added
  - API canónica `Inventory.addItem(...)` (aliases: `AddItem`, `PutItem`) [#123]
  ### Changed
  - Refactor de carga de scripts; -15% latencia [#127]
  ### Fixed
  - NPE en `LootTableResolver` con config nula [#130]
  ```

---

## 🧠 Investigación y propuestas creativas
**Dentro del CODEBASE:**
- Detectar **patrones repetidos**, deuda técnica, APIs divergentes, hotpaths.
- Funciones
- Estructura de los mods. 
- Resolucion de errores.
- Documentación y ejemplos.
- Proponer **refactors incrementales** con impacto estimado (latencia, memoria, mantenibilidad).
- Sugerir **convergencia** de funciones equivalentes entre mods.

**Fuera del CODEBASE (LUA):**
- Revisar **docs oficiales**, foros y repos reputados; **citar**.
- Traer ideas **aplicables**: rendimiento, seguridad, DX (developer experience), compatibilidad.
- Preparar **RFC/ADR** cuando implique cambios de arquitectura.
- **No copiar** código con licencias incompatibles; priorizar referencias y reimplementación propia.

**Prototipado seguro:**
- Experimentos tras `feature flags` y detrás de interfaces estables.
- Medir antes/después; abandonar si no aporta beneficio claro.

---

## 🛡️ Seguridad (mínimos exigibles)
- Validar entradas (tipos/rangos); evitar inyección/XXE/deserialización insegura (específico de LUA).
- Evitar uso peligroso de `reflection`; restringir clasecargadores.
- Gestionar secretos por variables de entorno o vault; **nunca** en repos.
- Revisar licencias de dependencias; actualizar CVEs con rapidez.
- Registrar eventos de seguridad relevantes (sin datos personales).

---

## 🚀 Rendimiento y escalabilidad
- Evitar asignaciones innecesarias; preferir estructuras adecuadas.
- Complejidad razonable; evitar N^2 en colecciones grandes.
- Cachés con políticas de expiración claras; medir **hit rate**.
- Concurrencia controlada; no bloquear en operaciones IO.
- Microbenchmarks (JMH) y perfiles en cambios críticos.

---

## 🧩 Especificidades de Project Zomboid (mods LUA)
- **Ámbitos:** `server`, `client`, `shared`; documentar claramente en la API canónica.
- **Orden de carga de scripts:** documentar **qué se carga primero/último** y **tipos de llamados/eventos**.
- **Eventos/Hooking:** especificar contractos y orden; evitar side-effects globales.
- **UI desde cero:** guías y ejemplos mínimos en `/docs/examples/ui/`.
- **Items/recetas/scripts/loot:** plantillas y convenciones; colorización y reglas de nombres.
- **Compatibilidad:** evitar romper mods existentes; ofrecer rutas de migración.

---

## ✅ Checklist final para la IA (antes de entregar)
- [ ] Consulté **CODEBASE** y cito rutas/archivos relevantes.
- [ ] Solución **pequeña y atómica**, con **tests** y **docs**.
- [ ] Código **limpio**, **formateado** y sin **code smells**.
- [ ] **Changelog** y, si aplica, **ADR/README** actualizados.
- [ ] Riesgos identificados y plan de **mitigación/rollback**.
- [ ] Si usé info externa, quedó **citada** y propuse cómo integrarla al CODEBASE.

---

> **Contexto:** Estas son **instrucciones para una IA que codifica por mí** y debe producir salidas **claras, concisas y bien citadas** en español, priorizando siempre el **CODEBASE LUA** como **fuente de verdad**.
