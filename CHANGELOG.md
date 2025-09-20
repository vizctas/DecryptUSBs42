Keep a Changelog
=================

All notable changes to this project will be documented in this file.

The format is based on https://keepachangelog.com/en/1.0.0/

## [Unreleased]
- None yet. Work in progress: changelog consolidation and QA checklist creation.

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
