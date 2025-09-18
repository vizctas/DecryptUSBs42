-- Basic server init logging for DecryptSkillSys

local function logGVDriveSandbox(prefix)
    local maxAttempts = 10
    local attempt = 0
    local delaySeconds = 1
    
    while attempt < maxAttempts do
        local ok, gv = pcall(function() return SandboxVars and SandboxVars.GVDrive or nil end)
        if not ok then
            print(string.format("[DecryptSkillSys] SandboxVars not available yet (attempt %d/%d)", attempt+1, maxAttempts))
            attempt = attempt + 1
            if attempt < maxAttempts then
                coroutine.yield(delaySeconds * 1000) -- Wait before retrying
            end
        else
            if not gv then
                print("[DecryptSkillSys] GVDrive sandbox group is nil after "..attempt.." attempts")
            end
            return gv
        end
    end
    
    print("[DecryptSkillSys] WARNING: Failed to load SandboxVars after "..maxAttempts.." attempts")
    return nil
end

local function onStarted()
    print("[DecryptSkillSys] Server start detected; initializing sandbox settings...")
    
    -- Create coroutine to handle retries
    local co = coroutine.create(function()
        local gv = logGVDriveSandbox("GVDrive.")
        if gv then
            print("[DecryptSkillSys] Successfully loaded sandbox settings")
        else
            print("[DecryptSkillSys] WARNING: Using fallback sandbox settings")
            -- Initialize minimal fallback settings
            SandboxVars = SandboxVars or {}
            SandboxVars.GVDrive = {
                USB_ZombieDrop_Chance = 1.5,
                Laptop_ZombieDrop_Chance = 0.3,
                EliteDrive_ZombieDrop_Chance = 0.08,
                EnableWorldLoot = true
            }
        end
        
        -- Log sandbox settings
        local keys = {
            "USB_ZombieDrop_Chance",
            "Floppy_ZombieDrop_Chance",
            "USB_Decrypt_Success_Chance",
            "Floppy_Decrypt_Success_Chance",
            "USB_Min_Experience",
            "USB_Max_Experience",
            "Floppy_Min_Experience",
            "Floppy_Max_Experience",
        }

        for _, k in ipairs(keys) do
            local v = gv and gv[k] or SandboxVars.GVDrive[k]
            print(string.format("[DecryptSkillSys] %s%s=%s", prefix or "GVDrive.", k, tostring(v)))
        end
    end)
    
    -- Start the coroutine
    local ok, err = coroutine.resume(co)
    if not ok then
        print("[DecryptSkillSys] ERROR in sandbox initialization: "..tostring(err))
    end
end

-- Register on multiple events defensively (varies by build/server)
if Events and Events.OnServerStarted and Events.OnServerStarted.Add then
    Events.OnServerStarted.Add(onStarted)
end
if Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(onStarted)
end
if Events and Events.OnInitWorld and Events.OnInitWorld.Add then
    Events.OnInitWorld.Add(function()
        print("[DecryptSkillSys] OnInitWorld fired")
        logGVDriveSandbox("GVDrive.")
    end)
end

print("[DecryptSkillSys] Init.lua loaded (server)")
