-- LaptopBatteryWidget.lua — REMOVED
-- This file previously implemented a client-side laptop battery UI widget.
-- The feature has been intentionally removed (kept as an inert stub) per project maintainers' request.
-- Reason: feature will be reworked later; keeping a live implementation caused runtime errors and is unused.

-- No-op stub: do not register events or expose any functions. If other modules still call
-- `showLaptopBatteryWidget` or `createLaptopBatteryWidget`, they should guard the call (check existence)
-- or the call will be a no-op here. This avoids runtime errors while preserving the file for history.

-- Example of safe guard when calling this API elsewhere (recommended):
-- if showLaptopBatteryWidget then showLaptopBatteryWidget(laptop) end

return
