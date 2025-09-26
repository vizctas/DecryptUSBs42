-- MiniGameRewardHelper.lua
-- Centraliza la aplicación de recompensas y penalizaciones para minijuegos USB

local MiniGameRewardHelper = {}

local function validateInputs(player, laptopItem, usbType, difficulty)
    if not player then
        print("[MiniGameRewardHelper] player is nil")
        return false
    end
    if not usbType or usbType == "" then
        print("[MiniGameRewardHelper] usbType is invalid: " .. tostring(usbType))
        return false
    end
    if not difficulty or difficulty == "" then
        print("[MiniGameRewardHelper] difficulty is invalid: " .. tostring(difficulty))
        return false
    end
    if not laptopItem then
        print("[MiniGameRewardHelper] laptopItem is nil - damage application may be skipped")
    end
    return true
end

local function applyResult(player, laptopItem, usbType, difficulty, isSuccess)
    if not validateInputs(player, laptopItem, usbType, difficulty) then
        return false, "invalid_inputs"
    end

    if not GVDrive_Utils or not GVDrive_Utils.applyMinigameResult then
        print("[MiniGameRewardHelper] GVDrive_Utils.applyMinigameResult not available")
        return false, "missing_utils"
    end

    local ok = GVDrive_Utils.applyMinigameResult(player, laptopItem, usbType, difficulty, isSuccess)
    if not ok then
        print("[MiniGameRewardHelper] applyMinigameResult returned false (success=" .. tostring(isSuccess) .. ")")
        return false, "apply_failed"
    end

    if isSuccess then
        print("[MiniGameRewardHelper] XP granted successfully for usbType=" .. tostring(usbType) .. ", difficulty=" .. tostring(difficulty))
    else
        print("[MiniGameRewardHelper] Damage applied successfully for usbType=" .. tostring(usbType) .. ", difficulty=" .. tostring(difficulty))
    end

    return true
end

function MiniGameRewardHelper.applySuccess(player, laptopItem, usbType, difficulty)
    return applyResult(player, laptopItem, usbType, difficulty, true)
end

function MiniGameRewardHelper.applyFailure(player, laptopItem, usbType, difficulty)
    return applyResult(player, laptopItem, usbType, difficulty, false)
end

return MiniGameRewardHelper
