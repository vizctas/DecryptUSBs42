Keep a Changelog
=================

All notable changes to this project will be documented in this file.

The format is based on https://keepachangelog.com/en/1.0.0/

## [Unreleased]
### Fixed
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

### Changed
- Changed main menu text from "Decrypt Drives" to "Insert Drive..." for better user experience

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

### Notes
- All changes were applied on branch `feature/working_state_v1`.
- Next: run QA checks and certification steps described in `docs/QA-CHECKLIST.md`.
