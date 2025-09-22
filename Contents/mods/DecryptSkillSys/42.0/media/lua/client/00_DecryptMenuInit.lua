-- Ensure the modern hierarchical context menu is loaded early
pcall(require, "client/DecryptDrivesContextMenu")
-- Expose a global to confirm load
_G.DecryptDrivesContextMenu_MODERN = _G.DecryptDrivesContextMenu_MODERN or true
