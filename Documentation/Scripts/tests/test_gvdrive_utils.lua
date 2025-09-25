-- Test script to validate GVDrive_Utils global exposure and functionality
-- Run this in PZ console or as a standalone script to verify fixes

print("[TEST] GVDrive_Utils Global Exposure Test")
print("==========================================")

-- Test 1: Check if GVDrive_Utils is available globally
if GVDrive_Utils then
    print("✅ GVDrive_Utils is available globally")
else
    print("❌ GVDrive_Utils is NOT available globally")
    return
end

-- Test 2: Check critical functions exist
local functions_to_check = {
    "getSkillPerk",
    "applyMinigameResult",
    "calculateMinigameXP",
    "calculateMinigameDamage",
    "getSandboxNumber",
    "getSandboxBool"
}

print("\nTesting critical functions:")
for _, func_name in ipairs(functions_to_check) do
    if GVDrive_Utils[func_name] and type(GVDrive_Utils[func_name]) == "function" then
        print("✅ " .. func_name .. " is available")
    else
        print("❌ " .. func_name .. " is NOT available")
    end
end

-- Test 3: Test getSkillPerk with known skills
print("\nTesting getSkillPerk with known skills:")
local test_skills = {"Woodwork", "Electricity", "Farming", "Aiming", "Cooking"}
for _, skill in ipairs(test_skills) do
    local perk = GVDrive_Utils.getSkillPerk(skill)
    if perk then
        print("✅ " .. skill .. " -> " .. tostring(perk))
    else
        print("❌ " .. skill .. " -> nil")
    end
end

-- Test 4: Test XP calculation
print("\nTesting XP calculation:")
local test_xp = GVDrive_Utils.calculateMinigameXP("Woodwork", "Easy")
print("✅ XP calculation result: " .. tostring(test_xp))

print("\n==========================================")
print("[TEST] GVDrive_Utils test completed")