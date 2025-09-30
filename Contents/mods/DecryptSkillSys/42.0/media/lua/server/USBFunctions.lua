require("shared/LaptopSystem")
pcall(require, "shared/GVDrive_Config")

local DEBUG = false
if GVDrive_Config and GVDrive_Config.getDebug then
    DEBUG = GVDrive_Config.getDebug()
end
local function debugPrint(...)
    if not DEBUG then return end
    print("[DecryptSkillSys][DEBUG]", ...)
end

function OnOpen_USB(items, result, player)
    local ply = player or getPlayer()
    if not ply then return end

    local inv = ply:getInventory()
    if not inv then return end

    local choices = {
        "GValley.USBOpened",
        "GValley.USBOpened_Damaged",
        "GValley.USBOpened",
        "GValley.USBOpened_Damaged"
    }

    local selectedItem = choices[ZombRand(#choices) + 1]
    inv:AddItem(selectedItem)

    -- Show feedback (client-only helper may not exist on server)
    if HaloTextHelper and HaloTextHelper.addTextWithArrow then
        HaloTextHelper.addTextWithArrow(ply, getText("GVDrive_Msg_USB_Opened_OK"), true, HaloTextHelper.getColorGreen())
    else
        debugPrint("USB opened result granted:", tostring(selectedItem))
    end
end

-- ============ ANTIVIRUS FUNCTIONS ============
function OnUse_AntivirusBasic(items, result, player)
    local ply = player or getPlayer()
    if not ply then return end

    -- Find laptop in inputs
    local laptop = nil
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and (
            item:getType() == "AsusZephLaptopOpened" or
            item:getType() == "Laptop90sOpened" or
            item:getType() == "IBM_LP90Opened"
        ) then
            laptop = item
            break
        end
    end

    if laptop then
        local cleaned = LaptopSystem.cleanMalware(laptop, 25) -- Basic antivirus heals 25 HP
        if cleaned then
            ply:Say(getText("GVDrive_Msg_Antivirus_Success") or "Malware cleaned! Laptop partially restored.")
        else
            ply:Say(getText("GVDrive_Msg_Antivirus_NoMalware") or "No malware detected. Laptop condition improved slightly.")
            LaptopSystem.damageLaptop(laptop, -10) -- Still heals a bit
        end
    end
end

function OnUse_AntivirusAdvanced(items, result, player)
    local ply = player or getPlayer()
    if not ply then return end

    -- Find laptop in inputs
    local laptop = nil
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and (
            item:getType() == "AsusZephLaptopOpened" or
            item:getType() == "Laptop90sOpened" or
            item:getType() == "IBM_LP90Opened"
        ) then
            laptop = item
            break
        end
    end

    if laptop then
        local cleaned = LaptopSystem.cleanMalware(laptop, 50) -- Advanced antivirus heals 50 HP
        if cleaned then
            ply:Say(getText("GVDrive_Msg_Antivirus_Advanced_Success") or "Advanced malware removal complete! Laptop significantly restored.")
        else
            ply:Say(getText("GVDrive_Msg_Antivirus_NoMalware") or "No malware detected. Laptop condition improved.")
            LaptopSystem.damageLaptop(laptop, -25) -- Heals more
        end
    end
end

function OnUse_AntivirusPremium(items, result, player)
    local ply = player or getPlayer()
    if not ply then return end

    -- Find laptop in inputs
    local laptop = nil
    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and (
            item:getType() == "AsusZephLaptopOpened" or
            item:getType() == "Laptop90sOpened" or
            item:getType() == "IBM_LP90Opened"
        ) then
            laptop = item
            break
        end
    end

    if laptop then
        local cleaned = LaptopSystem.cleanMalware(laptop, 75) -- Premium antivirus heals 75 HP
        if cleaned then
            ply:Say(getText("GVDrive_Msg_Antivirus_Premium_Success") or "Premium malware removal complete! Laptop fully restored!")
        else
            ply:Say(getText("GVDrive_Msg_Antivirus_NoMalware") or "No malware detected. Laptop condition greatly improved.")
            LaptopSystem.damageLaptop(laptop, -50) -- Heals a lot
        end
    end
end

local function handleClientCommand(module, command, args)
    if module ~= "GVDrive" then
        return
    end

    if command == "IncrementFailureCount" and args and args.laptop then
        local laptopItem = args.laptop
        if laptopItem and LaptopSystem and LaptopSystem.incrementFailureCount then
            local newCount = LaptopSystem.incrementFailureCount(laptopItem)
            debugPrint("Laptop failure count incremented to: " .. tostring(newCount))
        end
    end
end

if Events and Events.OnClientCommand and Events.OnClientCommand.Add then
    Events.OnClientCommand.Add(handleClientCommand)
end
