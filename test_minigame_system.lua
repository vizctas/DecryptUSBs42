-- Test script for minigame system validation
print('=== MINIGAME SYSTEM VALIDATION ===')

-- Test GVDrive_Utils functions
print('Testing GVDrive_Utils...')
local utils_ok, utils = pcall(require, 'shared/GVDrive_Utils')
if utils_ok and utils then
    print('✓ GVDrive_Utils loaded successfully')

    -- Test new functions
    local test_functions = {
        'getMinigameWindowSize',
        'getMinigameAutoCloseDelays',
        'getMinigameTimeLimit',
        'getMinigameXPMultiplier',
        'getMinigameBonusItemChance',
        'getMinigameBonusItems'
    }

    for _, func in ipairs(test_functions) do
        if utils[func] then
            print('✓ ' .. func .. ' exists')
        else
            print('✗ ' .. func .. ' missing')
        end
    end
else
    print('✗ GVDrive_Utils failed to load')
end

-- Test MinigameConfig
print('\nTesting MinigameConfig...')
local config_ok, config = pcall(require, 'client/MinigameSystem_Config')
if config_ok and config then
    print('✓ MinigameConfig loaded successfully')
else
    print('✗ MinigameConfig failed to load')
end

-- Test MinigameController
print('\nTesting MinigameController...')
local controller_ok, controller = pcall(require, 'client/MinigameSystem_Controller')
if controller_ok and controller then
    print('✓ MinigameController loaded successfully')
else
    print('✗ MinigameController failed to load')
end

-- Test SequenceBreaker
print('\nTesting SequenceBreaker...')
local sb_ok, sb = pcall(require, 'client/MinigameSystem_SequenceBreaker')
if sb_ok and sb then
    print('✓ SequenceBreaker loaded successfully')
else
    print('✗ SequenceBreaker failed to load')
end

print('\n=== VALIDATION COMPLETE ===')