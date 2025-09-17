Context menu test (Lua)
=======================

Prerequisites
- Lua 5.3+ installed and available as `lua` in your shell.

Run
- From the repository root:

  lua Scripts/tests/context_menu_test.lua

What it does
- Mocks Project Zomboid APIs and loads:
  - `Contents/mods/DecryptSkillSys/42.0/media/lua/client/TimedActions/LaptopFill.lua`
- Builds a fake world object with a valid laptop item and health=42.
- Invokes `LaptopOnFillWorldObjectContextMenu` and inspects options added.
- Asserts that a single life entry like "Laptop Condition: 42%" is present and has an icon.

Notes
- This is a pure-Lua smoke test; it does not render UI.
- Adjust the translation by editing the EN/ES override files if needed.

