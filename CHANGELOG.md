Keep a Changelog
=================

All notable changes to this project will be documented in this file.

The format is based on https://keepachangelog.com/en/1.0.0/

## [Unreleased]
### Fixed
- **CRITICAL MODULAR MENU FIX**: Fixed nil error in MenuController:createMenu when strategy fails to load - implemented robust fallback system with pcall error handling in DecryptDrivesContextMenu.createHierarchicalMenu
- **MODULAR MENU ERROR HANDLING**: Enhanced MenuController to throw descriptive error when no strategy is available instead of returning false, enabling proper fallback to legacy implementation
- **MENU COMPILATION VERIFIED**: Confirmed all modular menu components (MenuController, HierarchicalMenuStrategy, MenuComponentFactory) compile successfully after error handling improvements
- **CRITICAL RUNTIME FIX**: Fixed "Object tried to call nil" errors in MiniGameUI.lua onResize() and onStart() functions - added missing updateLayout() and clearAllTimers() method definitions to prevent crashes when resizing window or starting minigame
- **CRITICAL FIX**: Fixed runtime error "__concat not defined for operands: null and )" in LaptopFill.lua line 613 - added missing healthStatus variable definition and laptopHealth validation to prevent null concatenation errors
- **UI FIX**: Removed duplicate "Health" option in context menu - eliminated redundant code block that was creating two identical health display options
- **VISUAL ENHANCEMENT**: Enhanced battery status display with emoji indicators (🔋/🪫) when texture loading fails - provides clear visual health status even without PNG icons
- Fixed menu duplication issue - removed duplicate event registration in DecryptDrivesContextMenu.lua to prevent "Decrypt Drives" appearing twice
- Fixed critical syntax error in DecryptDrivesContextMenu.lua line 29 - malformed 'endnd' statement was causing "'end' expected" error
- Fixed critical syntax error in DecryptDrivesContextMenu.lua line 10-11 - incomplete if statement was causing "'then' expected near function" error
- Fixed require path in LaptopFill.lua - changed "client/DecryptDrivesContextMenu" to "DecryptDrivesContextMenu" to match PZ Lua require conventions
- Reverted health bar display changes - now uses simple characters (||||||....) instead of Unicode blocks
- Fixed USB drives menu disappearing by improving modern menu detection logic
- Reverted difficulty emojis in context menu to avoid conflicts
- Fixed hierarchical menu detection - modern menu now properly sets context marker to prevent legacy menu duplication
- Added extensive debug logging to troubleshoot hierarchical menu creation and difficulty grouping
- Fixed CONFIG reference bug in HierarchicalMenuStrategy - now properly initializes self.config
- Fixed syntax error in LaptopBatteryWidget.lua - removed orphaned code after early return
- Made HierarchicalMenuStrategy require safe in MenuController.lua to prevent runtime errors
- Fixed menu execution order issue - LaptopFill.lua now calls modern menu directly instead of relying on event execution order
- Added comprehensive debug logging to diagnose why hierarchical menu is not showing difficulty submenus
- **CRITICAL GVDRIVE_UTILS EXPOSURE FIX**: Added explicit global exposure `_G.GVDrive_Utils = GVDrive_Utils` at end of shared module to ensure availability across all contexts
- **MODULAR MENU FALLBACK STRATEGY**: Implemented built-in fallback strategy in MenuController when external HierarchicalMenuStrategy fails to load, preventing "No strategy available" errors
- **CONTEXT MENU STRATEGY RESOLUTION**: Resolved "No strategy available - cannot create menu" error by adding robust fallback mechanism in MenuController

### Changed
- Changed main menu text from "Decrypt Drives" to "Insert Drive..." for better user experience

### Added
- **MINIGAME INTEGRATION COMPLETE**: Successfully integrated MiniGameMorse and MiniGameFallout as modular minigames with automatic selection based on USB type
- **INTELLIGENT MINIGAME SELECTION**: Implemented smart minigame routing - Electrical USBs trigger Morse Code Decoding, Security USBs trigger Fallout Password Hacking, other skills use Sequence Memory
- **ROBUST MODULE LOADING**: Enhanced module loading system in DecryptDrivesContextMenu.lua with fallback mechanisms and comprehensive error handling for all minigame modules
- **GLOBAL FUNCTION REGISTRATION**: Ensured MiniGameMorse and MiniGameFallout are available as global functions after module loading, enabling direct console calls
- **TEST SCRIPT CREATED**: Added test_minigames.lua for validating global function availability and module loading integrity
- **PNG BATTERY ICONS CORRECTED**: Fixed battery icon implementation in context menu - corrected from incorrect `<IMAGE:...>` markup to proper `option.iconTexture = getTexture(...)` assignment
- Renamed function to `getBatteryTextureForHealth()` that returns Texture objects instead of strings
- Implemented proper texture assignment using `healthOption.iconTexture = batteryTexture` for visual battery status display
- Removed incorrect `<IMAGE:...>` markup approach that doesn't work in ISContextMenu
- Added debug logging to track texture assignment success
- Implemented battery icon mapping system for laptop health display - maps health percentages to appropriate battery PNG icons (batt0.png through batt100.png)
- Added texture loading logic for battery icons using getTexture() function
- Prepared foundation for visual battery icon rendering in context menus

### Changed
## [Unreleased]
### Changed
- Changed main menu text from "Decrypt Drives" to "Insert Drive..." for better user experience

### Added
- **MINIGAME INTEGRATION COMPLETE**: Successfully integrated MiniGameMorse and MiniGameFallout as modular minigames with automatic selection based on USB type
- **INTELLIGENT MINIGAME SELECTION**: Implemented smart minigame routing - Electrical USBs trigger Morse Code Decoding, Security USBs trigger Fallout Password Hacking, other skills use Sequence Memory
- **ROBUST MODULE LOADING**: Enhanced module loading system in DecryptDrivesContextMenu.lua with fallback mechanisms and comprehensive error handling for all minigame modules
- **GLOBAL FUNCTION REGISTRATION**: Ensured MiniGameMorse and MiniGameFallout are available as global functions after module loading, enabling direct console calls
- **TEST SCRIPT CREATED**: Added test_minigames.lua for validating global function availability and module loading integrity
- **PNG BATTERY ICONS CORRECTED**: Fixed battery icon implementation in context menu - corrected from incorrect `<IMAGE:...>` markup to proper `option.iconTexture = getTexture(...)` assignment
- Renamed function to `getBatteryTextureForHealth()` that returns Texture objects instead of strings
- Implemented proper texture assignment using `healthOption.iconTexture = batteryTexture` for visual battery status display
- Removed incorrect `<IMAGE:...>` markup approach that doesn't work in ISContextMenu
- Added debug logging to track texture assignment success
- Implemented battery icon mapping system for laptop health display - maps health percentages to appropriate battery PNG icons (batt0.png through batt100.png)
- Added texture loading logic for battery icons using getTexture() function
- Prepared foundation for visual battery icon rendering in context menus

## [2025-09-19] - Unreleased (cleanup)
### Added
- Initial cleanup changelog entry created at `logs/DecryptUSBs42_CLEANUP_CHANGELOG_2025-09-19.md` describing files modified and backups archived.
- Local debug wrappers added in `server/GV_ZombieLoot.lua` to centralize logging.

### Changed
- Centralized debug output across client and server modules to use `shared/GVDebug` where available. Files updated: `ClientInit.lua`, `LaptopBatteryWidget.lua`, `DecryptSkillDrive.lua`, `GV_ZombieLoot.lua`.
- Replaced scattered `print()` debug messages with wrapper `debugPrint(...)` delegating to `GVDebug`.

### Removed
- Backups and dead-code files moved to `logs/deleted_backups/` for archive and review (non-destructive).
- Removed client UI file `Contents/mods/DecryptSkillSys/42.0/media/lua/client/UI/LaptopBatteryWidget.lua` (feature retired; caused runtime errors). 

### Added
- **GRID REVEAL ANIMATION**: Added smooth sequential button reveal animation on window open - buttons appear one by one from top-left to bottom-right with CRT-style flash effect
- **VISUAL ENHANCEMENT**: Ultra-fast grid reveal (0.15-0.3s per button) with white flash transition to normal state, creating professional "system boot-up" appearance
- **TEMPLATE SYSTEM COMPLETE**: Created comprehensive template system for dynamic window creation in Project Zomboid mods
- **TEMPLATE_VENTANA_DINAMICA_GUIA_COMPLETA.md**: Detailed architectural guide covering all MiniGameUI patterns, best practices, and implementation strategies for future AI/developer use
- **TEMPLATE_VENTANA_DINAMICA_CODIGO.lua**: Reusable code template with ultra-reliable window creation, adaptive layout, robust error handling, and CRT visual effects
- **EJEMPLO_HACKING_WINDOW.lua**: Practical 2-minute implementation example showing hacking terminal window with XP integration and visual feedback
- **README.md**: Quick-start guide for template usage with 5-step implementation process and common error solutions
- **MODULAR TEMPLATE ARCHITECTURE**: Templates include SimpleTimer system, adaptive grid scaling, global exposure patterns, and comprehensive debugging utilities

### Notes
- All changes were applied on branch `feature/working_state_v1`.
- Next: run QA checks and certification steps described in `docs/QA-CHECKLIST.md`.
