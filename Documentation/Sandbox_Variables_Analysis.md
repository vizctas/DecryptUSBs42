# Análisis Completo de Variables del Sandbox - DecryptSkillSys

**Fecha:** 2025-01-18  
**Estado:** En Revisión

## Variables Verificadas 1:1 con el Código

### ✅ **Variables de Drop de Zombies (Correctas)**

| Variable Sandbox | Tipo | Rango | Default | Uso en Código | Estado |
|------------------|------|-------|---------|---------------|--------|
| `USB_ZombieDrop_Chance` | double | 0-10 | 0.4 | `* 100` de 10000 | ✅ Correcto |
| `Laptop_ZombieDrop_Chance` | double | 0-5 | 0.125 | `* 100` de 10000 | ✅ Correcto |
| `EliteDrive_ZombieDrop_Chance` | double | 0-1 | 0.05 | `* 100` de 10000 | ✅ Correcto |
| `Antivirus_ZombieDrop_Chance` | double | 0-2 | 0.167 | `* 100` de 10000 | ✅ Correcto |

**Explicación:** El código multiplica por 100 y compara contra ZombRand(10000), por lo que:
- 0.4 = 40/10000 = 0.4% de probabilidad
- 1.5 = 150/10000 = 1.5% de probabilidad

### ✅ **Variables de Spawn en Mundo (Correctas)**

| Variable Sandbox | Tipo | Rango | Default | Uso en Código | Estado |
|------------------|------|-------|---------|---------------|--------|
| `EnableWorldLoot` | boolean | - | true | Condicional ON/OFF | ✅ Correcto |
| `USB_WorldLoot_Chance` | double | 0-100 | 100 | Multiplicador % | ✅ Correcto |
| `Laptop_WorldLoot_Chance` | double | 0-100 | 100 | Multiplicador % | ✅ Correcto |
| `EliteDrive_WorldLoot_Chance` | double | 0-100 | 10 | Multiplicador % | ✅ Correcto |
| `SkillUSB_WorldLoot_Chance` | double | 0-100 | 20 | Multiplicador % | ✅ Correcto |
| `Antivirus_Spawn_Rate` | integer | 0-500 | 100 | Multiplicador % | ✅ Correcto |

### ✅ **Variables de Mecánicas de Desencriptación (Correctas)**

| Variable Sandbox | Tipo | Rango | Default | Uso en Código | Estado |
|------------------|------|-------|---------|---------------|--------|
| `USB_Decrypt_Success_Chance` | integer | 0-100 | 33 | Porcentaje directo | ✅ Correcto |
| `Drive_Preserve_Chance` | integer | 0-100 | 30 | `/100` para decimal | ✅ Correcto |
| `Malware_Chance` | integer | 0-100 | 15 | Porcentaje directo | ✅ Correcto |
| `Malware_Damage_Per_Use` | integer | 1-50 | 5 | Valor directo | ✅ Correcto |

### ✅ **Variables de Experiencia (Correctas)**

| Variable Sandbox | Tipo | Rango | Default | Uso en Código | Estado |
|------------------|------|-------|---------|---------------|--------|
| `USB_Min_Experience` | double | 1-500 | 35 | Valor directo | ✅ Correcto |
| `USB_Max_Experience` | double | 1-1000 | 245 | Valor directo | ✅ Correcto |

### ✅ **Variables de Salud de Laptops (Correctas)**

| Variable Sandbox | Tipo | Rango | Default | Uso en Código | Estado |
|------------------|------|-------|---------|---------------|--------|
| `Laptop_Initial_Health` | integer | 10-200 | 75 | Valor directo | ✅ Correcto |
| `Laptop_Random_Health_Min` | integer | 10-100 | 30 | Porcentaje | ✅ Correcto |
| `Laptop_Random_Health_Max` | integer | 10-100 | 85 | Porcentaje | ✅ Correcto |

### ✅ **Variables de Bonificaciones Elite (Correctas)**

| Variable Sandbox | Tipo | Rango | Default | Uso en Código | Estado |
|------------------|------|-------|---------|---------------|--------|
| `Elite_Strength_Bonus` | integer | 1-5 | 1 | Valor directo | ✅ Correcto |
| `Elite_Endurance_Bonus` | integer | 1-5 | 1 | Valor directo | ✅ Correcto |
| `Elite_Capacity_Bonus` | integer | 1-20 | 4 | Valor directo (kg) | ✅ Correcto |
| `Elite_Speed_Bonus` | integer | 1-3 | 1 | Valor directo | ✅ Correcto |
| `Elite_Luck_Bonus` | integer | 1-5 | 2 | Valor directo | ✅ Correcto |

### ⚠️ **Variables de Modificadores por Rareza (Revisar)**

| Variable Sandbox | Tipo | Rango | Default | Uso en Código | Estado |
|------------------|------|-------|---------|---------------|--------|
| `Facil_Success_Bonus` | double | 0-100 | 2.0 | ❓ No encontrado | ⚠️ Revisar |
| `Facil_Malware_Chance` | double | 0-100 | 5.0 | ❓ No encontrado | ⚠️ Revisar |
| `Facil_Laptop_Damage_Min` | integer | 0-100 | 3 | ❓ No encontrado | ⚠️ Revisar |
| `Facil_Laptop_Damage_Max` | integer | 0-100 | 5 | ❓ No encontrado | ⚠️ Revisar |
| `Facil_XP_Bonus` | double | 0-100 | 0 | ❓ No encontrado | ⚠️ Revisar |
| `Facil_Loot_Chance` | double | 0-100 | 5.0 | ❓ No encontrado | ⚠️ Revisar |

### ✅ **Variables de Antivirus (Correctas)**

| Variable Sandbox | Tipo | Rango | Default | Uso en Código | Estado |
|------------------|------|-------|---------|---------------|--------|
| `Antivirus_Norton_Drop_Rate` | double | 0-10 | 0.4 | `* 100` de 10000 | ✅ Correcto |
| `Antivirus_Kaspersky_Drop_Rate` | double | 0-10 | 0.3 | `* 100` de 10000 | ✅ Correcto |
| `Antivirus_McAfee_Drop_Rate` | double | 0-10 | 0.2 | `* 100` de 10000 | ✅ Correcto |
| `Antivirus_MalwareBytes_Drop_Rate` | double | 0-10 | 0.05 | `* 100` de 10000 | ✅ Correcto |

## Problemas Identificados

### 1. ⚠️ **Variables de Rareza No Implementadas**
Las variables `Facil_*`, `Moderado_*`, y `Dificil_*` están definidas en el sandbox pero no se usan en el código.

**Recomendación:** 
- Eliminar estas variables del sandbox si no se van a usar
- O implementar la lógica en el código para usarlas

### 2. ✅ **Tipos de Datos Correctos**
Todos los tipos de datos están correctamente definidos:
- `boolean` para toggles
- `integer` para valores enteros
- `double` para valores decimales

### 3. ✅ **Rangos Apropiados**
Los rangos están bien definidos según el uso:
- Drop rates: 0-10 (porcentajes bajos)
- World spawn: 0-100 (porcentajes normales)
- Bonuses: 1-5 (valores pequeños)
- Health: 10-200 (valores de vida)

## Próximos Pasos

1. **Decidir sobre variables de rareza:** ¿Implementar o eliminar?
2. **Verificar distribución de loot**
3. **Revisar iconos faltantes**
4. **Probar todas las configuraciones en el juego**

---

**Estado:** ✅ **MAYORÍA DE VARIABLES CORRECTAS**  
**Acción Requerida:** Decidir sobre variables de modificadores por rareza
