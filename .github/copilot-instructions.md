# Project Zomboid Mod: Decrypt USBs 42 - AI Development Guide

## Project Overview
This is a Project Zomboid mod that adds encrypted USB drives containing skill-based tutorials. Players find USBs from zombies, decrypt them using laptops, and gain skill experience. The mod is being ported from version 41 to version 42 with USB-only focus (floppy drives removed).

## Architecture & Key Components

### Core Systems
- **USB Drive System**: Skill-specific encrypted USB drives with difficulty levels (Facil/Moderado/Dificil)
- **Laptop System**: Health-based laptop mechanics for decryption (no power requirement)
- **Antivirus System**: Real antivirus brands with specific recovery rates (5%-12%)
- **Elite Drive System**: Rare military protocol USBs for character enhancements
- **Rarity System**: Three difficulty tiers with different success rates and experience bonuses

### File Structure
```
Contents/mods/DecryptSkillSys/42.0/media/
├── lua/
│   ├── client/          # UI, context menus, client-side actions
│   ├── server/          # Item distribution, server logic
│   └── shared/          # Cross-environment utilities, translations
├── scripts/             # Item definitions (.txt files)
└── sandbox-options.txt  # Configurable game parameters
```

## Critical Development Patterns

### 1. Item Naming Convention
USBs follow strict format: `{Brand Name} - {Skill} - {Difficulty}`
```lua
DisplayName = "USB CarpinterIA - Carpinteria - Facil"
```

### 2. Multi-Environment Code Structure
- **shared/GVDrive_Utils.lua**: Cross-environment utility functions
- **shared/LaptopSystem.lua**: Laptop health/power management
- Client and server directories for environment-specific logic

### 3. Translation System
Both English and Spanish translations in `shared/Translate/`:
- Files use table structures: `GVDrive_EN = { key = "value" }`
- Keys follow pattern: `GVDrive_[Category]_[Item]_[Variant]`

### 4. Sandbox Integration
All configurable values use `SandboxVars.GVDrive.*` pattern for user customization

## Development Workflows

### Adding New USB Items
1. Define in `scripts/GV_skilldrives_*.txt` with proper naming
2. Add translations in both EN/ES files
3. Update `GVDrive_Utils.lua` if new skill types
4. Add to item distribution in `server/items/GV_Itemsdistro.lua`

### Modifying Success Rates
Edit `sandbox-options.txt` and corresponding logic in `GVDrive_Utils.getRaritySettings()`

### Testing
Use `Scripts/tests/` directory with Lua 5.1.5:
```bash
lua Scripts/tests/context_menu_test.lua
```

## Project-Specific Conventions

### Error Handling
Always use `pcall()` for API calls that might fail:
```lua
local ok, result = pcall(function() return item:getModData() end)
if ok and result then -- use result end
```

### Item Type Detection
Use string pattern matching for item classification:
```lua
if string.find(itemType, "SkillDrive_") then
    -- Handle skill-specific USB
end
```

### Rarity System Integration
Three-tier system affects all mechanics:
- **Normal/Facil**: Lower risk, lower reward
- **Common/Moderado**: Balanced risk/reward
- **Advanced/Dificil**: Higher risk, higher reward

## Integration Points

### Project Zomboid API
- Item system through `InventoryItem` objects
- Context menus via `ISContextMenu`
- Timed actions using `ISBaseTimedAction`
- World object interactions for laptop placement

### Mod-Specific Dependencies
- Requires specific laptop items: AsusZephLaptop, Laptop90s, IBM_LP90
- Uses custom world static models for visual representation
- Integrates with game's skill system (`Perks.*`)

## Critical Notes

- **No Floppy Support**: All floppy-related code has been removed in this version
- **USB-Only Focus**: All drive mechanics now use USB items exclusively  
- **Reduced Antivirus Recovery**: New rates are 5%, 8%, 10%, 12% (down from previous 25%+ values)
- **Random Laptop Health**: Laptops spawn with random health (30-85%) instead of fixed 100%
- **Balanced Drop Rates**: Zombie drops are carefully balanced - USB: 1.2%, Laptop: 0.2%, Elite: 0.05%, Antivirus: 0.3%
- **Simplified Elite System**: Each Elite USB gives immediate benefits when used, no combining required
- **Bilingual Support**: Maintain both English and Spanish translations
- **Sandbox First**: All mechanics should be configurable via sandbox options

## Elite Drive System (Simplified)

The Elite system has been completely redesigned for clarity and balance:
- **Direct Benefits**: Each Elite USB gives immediate permanent benefits when used
- **No Combining**: No need to collect all 5 drives - each works independently  
- **One-Time Use**: Each enhancement type can only be used once per player
- **Clear Benefits**: Strength (+combat), Endurance (+1 stat), Capacity (+8kg), Speed (+movement), Luck (+trait)
- **Extremely Rare**: Only 0.05% drop chance from zombies to maintain balance

## Mod Vision & Balance Philosophy

This mod follows a specific balance philosophy:
- **Risk vs Reward**: Higher difficulty USBs give better rewards but more risk
- **Time Efficiency**: Helps players with limited time progress faster through skilled zombie killing
- **No Game Breaking**: Maintains Project Zomboid's challenging survival balance
- **Encourages Combat**: Players must kill many zombies to find USBs, promoting active gameplay
- **Laptop Maintenance**: Antivirus items are essential but rare, creating resource management

## Common Pitfalls

1. **ModData Safety**: Always check `item:getModData()` exists before accessing
2. **Translation Fallbacks**: Provide fallbacks when `getText()` returns the key unchanged
3. **Rarity Consistency**: Ensure all three systems (Normal/Common/Advanced) are updated together
4. **Item Normalization**: Use helper functions to handle both direct items and world object wrappers

This mod emphasizes configurability, bilingual support, and a balanced risk/reward progression system centered around USB-based skill acquisition.