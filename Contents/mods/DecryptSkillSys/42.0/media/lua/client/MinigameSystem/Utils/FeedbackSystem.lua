-- Feedback System for Minigame Framework
-- Handles visual effects, sound effects, and user feedback

FeedbackSystem = {}

-- Initialize the feedback system
function FeedbackSystem.init()
    FeedbackSystem.debugPrint("FeedbackSystem initialized")
end

-- Play sound effect
function FeedbackSystem.playSound(soundType)
    if not FeedbackSystem.isSoundEnabled() then return end

    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    local soundName = MinigameConfig.SOUNDS[soundType]

    if soundName then
        -- Try to play sound using PZ sound system
        local player = getPlayer()
        if player then
            -- Use PZ sound system if available
            if player:getEmitter() then
                player:getEmitter():playSound(soundName)
                FeedbackSystem.debugPrint("Played sound:", soundName)
            else
                FeedbackSystem.debugPrint("No emitter available for sound:", soundName)
            end
        end
    else
        FeedbackSystem.debugPrint("Unknown sound type:", soundType)
    end
end

-- Show success feedback
function FeedbackSystem.showSuccess(message, duration)
    duration = duration or 3

    FeedbackSystem.playSound("SUCCESS")

    if FeedbackSystem.isVisualEffectsEnabled() then
        -- Create success particles/effects
        FeedbackSystem.createSuccessParticles()
    end

    -- Show message to player
    if message then
        getPlayer():Say(message)
    end

    FeedbackSystem.debugPrint("Showed success feedback:", message)
end

-- Show failure feedback
function FeedbackSystem.showFailure(message, duration)
    duration = duration or 2

    FeedbackSystem.playSound("FAILURE")

    if FeedbackSystem.isVisualEffectsEnabled() then
        -- Create failure effects (screen shake, etc.)
        FeedbackSystem.createFailureEffects()
    end

    -- Show message to player
    if message then
        getPlayer():Say(message)
    end

    FeedbackSystem.debugPrint("Showed failure feedback:", message)
end

-- Show timeout feedback
function FeedbackSystem.showTimeout(message, duration)
    duration = duration or 2

    FeedbackSystem.playSound("TIMEOUT")

    if FeedbackSystem.isVisualEffectsEnabled() then
        -- Create timeout effects
        FeedbackSystem.createTimeoutEffects()
    end

    -- Show message to player
    if message then
        getPlayer():Say(message or "Time's up!")
    end

    FeedbackSystem.debugPrint("Showed timeout feedback:", message)
end

-- Create success particles effect
function FeedbackSystem.createSuccessParticles()
    -- This would create particle effects in PZ
    -- For now, just log it
    FeedbackSystem.debugPrint("Creating success particles")
end

-- Create failure effects (screen shake, etc.)
function FeedbackSystem.createFailureEffects()
    -- This would create screen shake and failure effects in PZ
    -- For now, just log it
    FeedbackSystem.debugPrint("Creating failure effects")
end

-- Create timeout effects
function FeedbackSystem.createTimeoutEffects()
    -- This would create timeout warning effects in PZ
    -- For now, just log it
    FeedbackSystem.debugPrint("Creating timeout effects")
end

-- Highlight UI element with glow effect
function FeedbackSystem.highlightElement(element, color, duration)
    if not FeedbackSystem.isVisualEffectsEnabled() then return end

    duration = duration or 0.5

    -- This would apply glow effect to UI element in PZ
    FeedbackSystem.debugPrint("Highlighting element with color:", color, "for", duration, "seconds")
end

-- Shake UI element
function FeedbackSystem.shakeElement(element, intensity, duration)
    if not FeedbackSystem.isVisualEffectsEnabled() then return end

    intensity = intensity or 5
    duration = duration or 0.3

    -- This would apply shake effect to UI element in PZ
    FeedbackSystem.debugPrint("Shaking element with intensity:", intensity, "for", duration, "seconds")
end

-- Button press feedback
function FeedbackSystem.buttonPressFeedback(buttonElement, isCorrect)
    if isCorrect then
        FeedbackSystem.highlightElement(buttonElement, {0, 1, 0, 1}, 0.3) -- Green glow
        FeedbackSystem.playSound("MATCH_FOUND")
    else
        FeedbackSystem.shakeElement(buttonElement, 3, 0.2)
        FeedbackSystem.playSound("MATCH_WRONG")
    end
end

-- Sequence button feedback
function FeedbackSystem.sequenceButtonFeedback(buttonType, isShowing)
    if isShowing then
        -- When showing the sequence
        local soundMap = {
            red = "BUTTON_RED",
            blue = "BUTTON_BLUE",
            green = "BUTTON_GREEN",
            yellow = "BUTTON_YELLOW"
        }
        FeedbackSystem.playSound(soundMap[buttonType] or "BUTTON_RED")
    else
        -- When player presses button
        FeedbackSystem.playSound("CARD_FLIP")
    end
end

-- Card flip feedback for memory game
function FeedbackSystem.cardFlipFeedback(cardElement, symbol)
    FeedbackSystem.playSound("CARD_FLIP")

    if FeedbackSystem.isVisualEffectsEnabled() then
        -- Highlight the card briefly
        FeedbackSystem.highlightElement(cardElement, {1, 1, 1, 0.5}, 0.2)
    end

    FeedbackSystem.debugPrint("Card flipped showing:", symbol)
end

-- Match found feedback
function FeedbackSystem.matchFoundFeedback(card1, card2, symbol)
    FeedbackSystem.playSound("MATCH_FOUND")

    if FeedbackSystem.isVisualEffectsEnabled() then
        -- Highlight both cards with success color
        FeedbackSystem.highlightElement(card1, {0, 1, 0, 1}, 0.5)
        FeedbackSystem.highlightElement(card2, {0, 1, 0, 1}, 0.5)
    end

    FeedbackSystem.debugPrint("Match found for symbol:", symbol)
end

-- Match wrong feedback
function FeedbackSystem.matchWrongFeedback(card1, card2)
    FeedbackSystem.playSound("MATCH_WRONG")

    if FeedbackSystem.isVisualEffectsEnabled() then
        -- Shake both cards
        FeedbackSystem.shakeElement(card1, 3, 0.3)
        FeedbackSystem.shakeElement(card2, 3, 0.3)
    end

    FeedbackSystem.debugPrint("Wrong match")
end

-- Check if sound is enabled
function FeedbackSystem.isSoundEnabled()
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    return MinigameConfig.isSoundEnabled()
end

-- Check if visual effects are enabled
function FeedbackSystem.isVisualEffectsEnabled()
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    return MinigameConfig.isVisualEffectsEnabled()
end

-- Debug print function
function FeedbackSystem.debugPrint(...)
    local MinigameConfig = require "MinigameSystem.Config.MinigameConfig"
    if MinigameConfig.DEBUG then
        print("[FeedbackSystem]", ...)
    end
end

-- Initialize on load
FeedbackSystem.init()

FeedbackSystem.debugPrint("FeedbackSystem.lua loaded successfully")

return FeedbackSystem