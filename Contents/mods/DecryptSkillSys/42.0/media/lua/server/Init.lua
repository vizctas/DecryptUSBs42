-- Basic server init logging for DecryptSkillSys

local function logGVDriveSandbox(prefix)
    local ok, gv = pcall(function() return SandboxVars and SandboxVars.GVDrive or nil end)
    if not ok then
        print("[DecryptSkillSys] SandboxVars not available yet")
        return
    end
    if not gv then
        print("[DecryptSkillSys] GVDrive sandbox group is nil")
        return
    end

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
        local v = gv[k]
        print(string.format("[DecryptSkillSys] %s%s=%s", prefix or "GVDrive.", k, tostring(v)))
    end
end

local function onStarted()
    print("[DecryptSkillSys] Server start detected; logging sandbox settings...")
    logGVDriveSandbox("GVDrive.")
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

