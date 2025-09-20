-- Simple test script to validate GVDrive_Utils.getSkillPerk mapping
pcall(require, "shared/GVDrive_Utils")
local utils = GVDrive_Utils
if not utils then
    print("GVDrive_Utils not available - aborting test")
    return
end

local skills = {"Woodwork", "Electricity", "Farming", "Aiming", "Cooking", "Sneak", "Axe", "Fitness", "Doctor", "Survivalist", "Mechanics", "Tailoring", "Maintenance", "SmallBlade", "LongBlade", "SmallBlunt", "LongBlunt", "Spear", "Trapping", "Fishing", "Sprinting", "Strength", "Nimble", "Lightfoot"}

local results = {}
for _, skill in ipairs(skills) do
    local ok, perk = pcall(utils.getSkillPerk, skill)
    if ok and perk then
        results[skill] = tostring(perk)
        print(string.format("SKILL: %s -> Perk resolved: %s", skill, tostring(perk)))
    else
        results[skill] = nil
        print(string.format("SKILL: %s -> Perk NOT resolved (nil)", skill))
    end
end

-- Summarize
local resolved = 0
local total = 0
for k, v in pairs(results) do
    total = total + 1
    if v then resolved = resolved + 1 end
end
print(string.format("Resolved %d/%d skills", resolved, total))

return results
