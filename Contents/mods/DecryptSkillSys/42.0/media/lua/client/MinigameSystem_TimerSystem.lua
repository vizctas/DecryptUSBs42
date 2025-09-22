-- Timer System for Minigame Framework
-- Handles all timing-related functionality for minigames

TimerSystem = {}

-- Active timers storage
TimerSystem.activeTimers = {}
TimerSystem.nextTimerId = 1

-- Initialize the timer system
function TimerSystem.init()
    TimerSystem.activeTimers = {}
    TimerSystem.nextTimerId = 1
    TimerSystem.debugPrint("TimerSystem initialized")
end

-- Create a new timer
function TimerSystem.startTimer(duration, callback, timerType)
    if not duration or duration <= 0 then
        TimerSystem.debugPrint("Invalid duration for timer:", duration)
        return nil
    end

    if not callback or type(callback) ~= "function" then
        TimerSystem.debugPrint("Invalid callback for timer")
        return nil
    end

    local timerId = TimerSystem.nextTimerId
    TimerSystem.nextTimerId = TimerSystem.nextTimerId + 1

    -- Use PZ's getGameTime() if available, fallback to os.time()
    local startTime
    local success, gameTime = pcall(function() return getGameTime() end)
    if success and gameTime and gameTime.getWorldAgeHours then
        startTime = gameTime:getWorldAgeHours() * 3600 -- Convert to seconds
    else
        startTime = os.time()
    end

    local timer = {
        id = timerId,
        duration = duration,
        remaining = duration,
        callback = callback,
        timerType = timerType or "generic",
        startTime = startTime,
        paused = false,
        completed = false
    }

    TimerSystem.activeTimers[timerId] = timer
    TimerSystem.debugPrint("Started timer", timerId, "for", duration, "seconds (type:", timerType, ")")

    return timerId
end

-- Cancel a timer
function TimerSystem.cancelTimer(timerId)
    if not timerId then return false end

    local timer = TimerSystem.activeTimers[timerId]
    if timer then
        timer.completed = true
        TimerSystem.activeTimers[timerId] = nil
        TimerSystem.debugPrint("Cancelled timer", timerId)
        return true
    end

    return false
end

-- Pause a timer
function TimerSystem.pauseTimer(timerId)
    local timer = TimerSystem.activeTimers[timerId]
    if timer and not timer.completed then
        timer.paused = true
        TimerSystem.debugPrint("Paused timer", timerId)
        return true
    end
    return false
end

-- Resume a timer
function TimerSystem.resumeTimer(timerId)
    local timer = TimerSystem.activeTimers[timerId]
    if timer and not timer.completed then
        timer.paused = false
        TimerSystem.debugPrint("Resumed timer", timerId)
        return true
    end
    return false
end

-- Get remaining time for a timer
function TimerSystem.getRemainingTime(timerId)
    local timer = TimerSystem.activeTimers[timerId]
    if timer and not timer.completed then
        return math.max(0, timer.remaining)
    end
    return 0
end

-- Get timer progress (0.0 to 1.0)
function TimerSystem.getTimerProgress(timerId)
    local timer = TimerSystem.activeTimers[timerId]
    if timer and not timer.completed then
        return 1.0 - (timer.remaining / timer.duration)
    end
    return 1.0
end

-- Check if timer is active
function TimerSystem.isTimerActive(timerId)
    local timer = TimerSystem.activeTimers[timerId]
    return timer and not timer.completed
end

-- Update all active timers (called every frame)
function TimerSystem.update(deltaTime)
    -- Use PZ's getGameTime() if available, fallback to os.time()
    local currentTime
    local success, gameTime = pcall(function() return getGameTime() end)
    if success and gameTime and gameTime.getWorldAgeHours then
        currentTime = gameTime:getWorldAgeHours() * 3600 -- Convert to seconds
    else
        currentTime = os.time()
    end

    local completedTimers = {}

    for timerId, timer in pairs(TimerSystem.activeTimers) do
        if not timer.completed and not timer.paused then
            local elapsed = currentTime - timer.startTime
            timer.remaining = timer.duration - elapsed

            if timer.remaining <= 0 then
                timer.completed = true
                table.insert(completedTimers, timerId)

                -- Execute callback
                local success, error = pcall(timer.callback)
                if not success then
                    TimerSystem.debugPrint("Timer callback error for", timerId, ":", error)
                end
            end
        end
    end

    -- Clean up completed timers
    for _, timerId in ipairs(completedTimers) do
        TimerSystem.activeTimers[timerId] = nil
        TimerSystem.debugPrint("Completed and cleaned up timer", timerId)
    end
end

-- Cancel all timers
function TimerSystem.cancelAllTimers()
    local count = 0
    for timerId, _ in pairs(TimerSystem.activeTimers) do
        TimerSystem.activeTimers[timerId] = nil
        count = count + 1
    end
    TimerSystem.debugPrint("Cancelled all", count, "timers")
    return count
end

-- Cancel timers by type
function TimerSystem.cancelTimersByType(timerType)
    local count = 0
    for timerId, timer in pairs(TimerSystem.activeTimers) do
        if timer.timerType == timerType then
            TimerSystem.activeTimers[timerId] = nil
            count = count + 1
        end
    end
    TimerSystem.debugPrint("Cancelled", count, "timers of type", timerType)
    return count
end

-- Get active timer count
function TimerSystem.getActiveTimerCount()
    local count = 0
    for _ in pairs(TimerSystem.activeTimers) do
        count = count + 1
    end
    return count
end

-- Get active timers info (for debugging)
function TimerSystem.getActiveTimersInfo()
    local info = {}
    for timerId, timer in pairs(TimerSystem.activeTimers) do
        table.insert(info, {
            id = timerId,
            type = timer.timerType,
            remaining = timer.remaining,
            duration = timer.duration,
            progress = TimerSystem.getTimerProgress(timerId),
            paused = timer.paused
        })
    end
    return info
end

-- Debug print function
function TimerSystem.debugPrint(...)
    if MinigameConfig and MinigameConfig.DEBUG then
        print("[TimerSystem]", ...)
    end
end

-- Initialize on load
TimerSystem.init()

-- Register update function to be called every frame
Events.OnTick.Add(function()
    TimerSystem.update(0.1) -- Assume ~100ms between ticks
end)

TimerSystem.debugPrint("TimerSystem.lua loaded and registered")