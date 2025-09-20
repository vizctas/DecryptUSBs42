-- Basic server init logging for DecryptSkillSys
-- SIMPLIFIED VERSION - uses new native PZ approach

local DEBUG = true
pcall(require, "shared/GVDrive_Config")
if GVDrive_Config and GVDrive_Config.getDebug then
    DEBUG = GVDrive_Config.getDebug()
end

local ok_debug, GVDebug = pcall(require, "shared/GVDebug")
if not ok_debug or not GVDebug then
    GVDebug = { debugPrint = function(...) end, testPrint = function(...) end }
end

-- SIMPLIFIED INIT: Just load the simplified loader
local function initMod()
    GVDebug.debugPrint("🚀 Starting simplified mod initialization...")
    -- The simplified loader (GVLoaderSimple) was removed to avoid recursive/erroneous requires.
    -- Core systems will be loaded via explicit requires further down; this avoids noisy pcall failures.
    GVDebug.debugPrint("ℹ️ GVLoaderSimple not present; using direct loading of core systems")
    
    GVDebug.debugPrint("🎯 Initialization complete - using native PZ systems")
end

-- Register simplified init
if Events and Events.OnServerStarted then
    Events.OnServerStarted.Add(initMod)
elseif Events and Events.OnGameBoot then  
    Events.OnGameBoot.Add(initMod)
else
    -- Fallback: run immediately
    initMod()
end

do
GVDebug.debugPrint("Simplified Init.lua loaded")

-- Helper to wait for sandbox vars with a tight but finite retry loop
local function waitForSandboxVars()
    local maxAttempts = 10
    local attempt = 0
    local delaySeconds = 1

    while attempt < maxAttempts do
        local ok, gv = pcall(function() return SandboxVars and SandboxVars.GVDrive or nil end)
        if not ok then
            if GVDebug and GVDebug.debugPrint then
                GVDebug.debugPrint(string.format("SandboxVars not available yet (attempt %d/%d)", attempt+1, maxAttempts))
            end
            attempt = attempt + 1
            if attempt < maxAttempts then
                coroutine.yield(delaySeconds * 1000) -- Wait before retrying
            end
        else
            return gv
        end
    end

    if GVDebug and GVDebug.debugPrint then
        GVDebug.debugPrint("[WARNING] Failed to load SandboxVars after "..maxAttempts.." attempts")
    end
    return nil
end

local function onStarted()
    if GVDebug and GVDebug.debugPrint then
        GVDebug.debugPrint("Server start detected; initializing sandbox settings...")
    end

    -- Create coroutine to handle retries
    local co = coroutine.create(function()
        local gv = waitForSandboxVars()
        if gv and GVDebug and GVDebug.debugPrint then
            GVDebug.debugPrint("Successfully loaded sandbox settings")
        else
            if GVDebug and GVDebug.debugPrint then
                GVDebug.debugPrint("[WARNING] Using fallback sandbox settings")
            end
            -- Initialize minimal fallback settings with correct values
            SandboxVars = SandboxVars or {}
            SandboxVars.GVDrive = {
                USB_ZombieDrop_Chance = 0.4,
                Laptop_ZombieDrop_Chance = 0.125,
                EliteDrive_ZombieDrop_Chance = 0.05,
                Antivirus_ZombieDrop_Chance = 0.167,
                EnableWorldLoot = true,
                USB_Decrypt_Success_Chance = 33,
                Drive_Preserve_Chance = 30,
                Malware_Chance = 15
            }
            gv = SandboxVars.GVDrive
        end

        -- Log sandbox settings (use helpers when available)
        local keys = {
            {k = "USB_ZombieDrop_Chance", fn = function() return GVDrive_Utils and GVDrive_Utils.getSandboxPercent and GVDrive_Utils.getSandboxPercent("USB_ZombieDrop_Chance", 0.4) or (gv and gv.USB_ZombieDrop_Chance) or 0.4 end},
            {k = "Laptop_ZombieDrop_Chance", fn = function() return GVDrive_Utils and GVDrive_Utils.getSandboxPercent and GVDrive_Utils.getSandboxPercent("Laptop_ZombieDrop_Chance", 0.125) or (gv and gv.Laptop_ZombieDrop_Chance) or 0.125 end},
            {k = "USB_Decrypt_Success_Chance", fn = function() return GVDrive_Utils and GVDrive_Utils.getSandboxNumber and GVDrive_Utils.getSandboxNumber("USB_Decrypt_Success_Chance", 33) or (gv and gv.USB_Decrypt_Success_Chance) or 33 end},
            {k = "USB_Min_Experience", fn = function() return GVDrive_Utils and GVDrive_Utils.getSandboxNumber and GVDrive_Utils.getSandboxNumber("USB_Min_Experience", 35) or (gv and gv.USB_Min_Experience) or 35 end},
            {k = "USB_Max_Experience", fn = function() return GVDrive_Utils and GVDrive_Utils.getSandboxNumber and GVDrive_Utils.getSandboxNumber("USB_Max_Experience", 245) or (gv and gv.USB_Max_Experience) or 245 end},
        }

        for _, entry in ipairs(keys) do
            local ok, value = pcall(entry.fn)
            if GVDebug and GVDebug.debugPrint then
                GVDebug.debugPrint(string.format("%s%s=%s", "GVDrive.", entry.k, tostring(ok and value or "<error>")))
            end
        end
    end)

    -- Start the coroutine
    local ok, err = coroutine.resume(co)
    if not ok and GVDebug and GVDebug.debugPrint then
        GVDebug.debugPrint("[ERROR] in sandbox initialization:", tostring(err))
    end
end

-- Auto-clamp known sandbox vars to safe ranges to avoid engine rejection
local function clampSandboxVars()
    if not SandboxVars then return end
    SandboxVars = SandboxVars or {}
    SandboxVars.GVDrive = SandboxVars.GVDrive or {}
    local gv = SandboxVars.GVDrive

    local clamps = {
        {k = "USB_WorldLoot_Chance", min = 0.0, max = 5.0, def = 1.0},
        {k = "Laptop_WorldLoot_Chance", min = 0.0, max = 5.0, def = 1.0},
        {k = "EliteDrive_WorldLoot_Chance", min = 0.0, max = 5.0, def = 0.1},
        {k = "SkillUSB_WorldLoot_Chance", min = 0.0, max = 5.0, def = 0.2},
        {k = "USB_ZombieDrop_Chance", min = 0.0, max = 5.0, def = 0.4},
        {k = "Laptop_ZombieDrop_Chance", min = 0.0, max = 5.0, def = 0.125},
        {k = "EliteDrive_ZombieDrop_Chance", min = 0.0, max = 5.0, def = 0.05},
        {k = "Antivirus_ZombieDrop_Chance", min = 0.0, max = 5.0, def = 0.167},
        {k = "Antivirus_Norton_Drop_Rate", min = 0.0, max = 5.0, def = 0.4},
        {k = "Antivirus_Kaspersky_Drop_Rate", min = 0.0, max = 5.0, def = 0.3},
        {k = "Antivirus_McAfee_Drop_Rate", min = 0.0, max = 5.0, def = 0.2},
        {k = "Antivirus_MalwareBytes_Drop_Rate", min = 0.0, max = 5.0, def = 0.05},
    }

    for _, entry in ipairs(clamps) do
        local key = entry.k
        local v = gv[key]
        if v ~= nil then
            local n = tonumber(v) or entry.def
            if n < entry.min or n > entry.max then
                if GVDebug and GVDebug.debugPrint then
                    GVDebug.debugPrint(string.format("[WARN] Clamping sandbox var %s: %s -> %s (allowed %s..%s)", key, tostring(v), tostring(entry.def), tostring(entry.min), tostring(entry.max)))
                end
                gv[key] = entry.def
            end
        else
            -- ensure default exists
            gv[key] = entry.def
        end
    end
end

-- Run clamp early on script load to ensure subsequent modules see corrected values
pcall(clampSandboxVars)

-- Register on multiple events defensively (varies by build/server)
if Events and Events.OnServerStarted and Events.OnServerStarted.Add then
    Events.OnServerStarted.Add(onStarted)
end
if Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(onStarted)
end
if Events and Events.OnInitWorld and Events.OnInitWorld.Add then
    Events.OnInitWorld.Add(function()
        if GVDebug and GVDebug.debugPrint then
            GVDebug.debugPrint("OnInitWorld fired")
        end
        pcall(function() if logGVDriveSandbox then logGVDriveSandbox("GVDrive.") end end)
    end)
end

-- Load distribution systems
pcall(require, "shared/GVDrive_Utils")
pcall(require, "server/items/GV_Itemsdistro")
pcall(require, "server/GV_ZombieLoot")

if GVDebug and GVDebug.debugPrint then
    GVDebug.debugPrint("Init.lua loaded (server)")
end

-- Debug: server-only test handler to confirm OnZombieDead fires
do
    local canRegister = false
    pcall(function()
        canRegister = isServer() or not isClient()
    end)
    if canRegister then
        if Events and Events.OnZombieDead and Events.OnZombieDead.Add then
            Events.OnZombieDead.Add(function(zombie)
                if GVDebug and GVDebug.debugPrint then
                    GVDebug.debugPrint("[TEST] OnZombieDead fired for", tostring(zombie))
                end
            end)
        end
    end
end
