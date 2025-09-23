# Cleanup changelog — 2025-09-19

Summary
-------
This changelog records the cleanup work performed across the DecryptUSBs42 mod to centralize debug output, remove dead backups from the mod tree, and extract item definitions for verification. Work performed is small, reversible, and logged here for traceability.

Files changed
-------------
- `Contents/mods/DecryptSkillSys/42.0/media/lua/client/ClientInit.lua`
  - Replaced local debug wrapper with centralized `GVDebug` usage. Ensures debug messages only appear when `GVDebug` enables them.

- `Contents/mods/DecryptSkillSys/42.0/media/lua/client/UI/LaptopBatteryWidget.lua`
  - Created a local `debugPrint(...)` wrapper delegating to `GVDebug.debugPrint(...)`.
  - Replaced all `print(...)` occurrences used for non-critical debugging with `debugPrint(...)`.
  - Replaced `print` calls used for error logs with `debugPrint(...)` so logs route through centralized system.

- `Contents/mods/DecryptSkillSys/42.0/media/lua/client/TimedActions/DecryptSkillDrive.lua`
  - Added `debugPrint(...)` wrapper and replaced `print(...)` error lines with `debugPrint(...)`.

- `Contents/mods/DecryptSkillSys/42.0/media/lua/server/GV_ZombieLoot.lua`
  - Added local wrappers `debugPrint(...)` and `testPrint(...)` that forward to `GVDebug` when available.
  - Replaced unscoped calls to `print`/`testPrint` that bypassed `GVDebug` with the wrapped versions (keeps output consistent and toggleable).

Backups moved
-------------
- All `.bak`, `.backup`, and `_backup` files previously found in the mod tree were archived to `logs/deleted_backups/` (performed earlier in the session). Example: `logs/deleted_backups/LaptopFill.lua.backup.txt`.

Item extraction
---------------
- Full item catalog was previously extracted to `logs/DecryptUSBs42/items_catalog.json` (see logs for the exact path). This was used to verify item availability in `GV_ZombieLoot.lua`.

Testing & Verification
----------------------
- Performed code edits in-place and ran repository-wide searches to confirm no remaining unscoped `print(` calls (except in `shared/GVDebug.lua` which intentionally uses `print` to output when enabled).
- Verified `testPrint(...)` calls in `GV_ZombieLoot.lua` and other server files are now resolved by local wrappers to `GVDebug.testPrint(...)`.
- Client UI file `LaptopBatteryWidget.lua` now uses `debugPrint(...)` wrapper; it will emit messages only if `GVDebug` is active.

Notes & Rationale
-----------------
- Centralizing debug output reduces console noise and makes the mod's diagnostic behavior predictable. `GVDebug` controls what's printed and provides two levels (`debugPrint` and `testPrint`).
- Using local wrappers preserves the original code style (many places called `debugPrint`/`testPrint`) while ensuring they use `GVDebug`.

Next steps
----------
- Create a small unit/integration test harness or run a smoke test in-game to confirm no runtime errors occur during init and that SandboxVars reads behave as expected.
- Complete certification steps: code review, PR with Conventional Commit message, update global `CHANGELOG.md`, and request QA tests.

Timestamp
---------
2025-09-19 14:00 — Cleanup edits applied; TODO updated; changelog created.

Author
------
Automated cleanup by assistant (patches applied to working branch `feature/working_state_v1`).
