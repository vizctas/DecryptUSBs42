-- Central debug utility for DecryptSkillSys
local M = {}

-- Flag to enable verbose debug output. Keep false for cleaned release.
M.ENABLED = false

function M.debugPrint(...)
    if not M.ENABLED then return end
    if print then print("[DecryptSkillSys][DEBUG]", ...) end
end

function M.testPrint(...)
    if not M.ENABLED then return end
    if print then print("[DecryptSkillSys][TEST]", ...) end
end

return M
