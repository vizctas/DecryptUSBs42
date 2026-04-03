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

-- ✅ MULTIPLAYER: Handler mejorado para comandos de cliente
local function handleClientCommand(playerIndex, module, command, args)
    -- Validar parámetros básicos
    if module ~= "GVDrive" then return end
    if not args then return end
    
    -- Obtener jugador
    local player = nil
    if type(playerIndex) == "number" then
        player = getSpecificPlayer(playerIndex)
    end
    
    if not player then
        debugPrint("CRITICAL", "Invalid player in handleClientCommand")
        return
    end
    
    -- ✅ COMANDO: IncrementFailureCount
    if command == "IncrementFailureCount" and args.laptopID then
        -- Buscar laptop por ID en inventario del jugador
        local inventory = player:getInventory()
        if not inventory then return end
        
        local laptop = nil
        for i = 0, inventory:getItems():size() - 1 do
            local item = inventory:getItems():get(i)
            if item and item:getID() == args.laptopID then
                laptop = item
                break
            end
        end
        
        -- Si no está en inventario, buscar en objetos del mundo cercanos
        if not laptop then
            local square = player:getCurrentSquare()
            if square then
                local objects = square:getWorldObjects()
                if objects then
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if obj and instanceof(obj, "IsoWorldInventoryObject") then
                            local item = obj:getItem()
                            if item and item:getID() == args.laptopID then
                                laptop = item
                                break
                            end
                        end
                    end
                end
            end
        end
        
        -- Aplicar incremento si se encontró la laptop
        if laptop and LaptopSystem and LaptopSystem.incrementFailureCount then
            local newCount = LaptopSystem.incrementFailureCount(laptop)
            debugPrint("Laptop failure count incremented to: " .. tostring(newCount))
        else
            debugPrint("CRITICAL", "Laptop not found for ID: " .. tostring(args.laptopID))
        end
    end
    
    -- ✅ COMANDO: ConsumeUSB (nuevo)
    if command == "ConsumeUSB" and args.usbID then
        local inventory = player:getInventory()
        if not inventory then return end
        
        for i = 0, inventory:getItems():size() - 1 do
            local item = inventory:getItems():get(i)
            if item and item:getID() == args.usbID then
                inventory:Remove(item)
                debugPrint("USB consumed: " .. tostring(args.usbID))
                break
            end
        end
    end
    
    -- ✅ COMANDO: ApplyXP (nuevo)
    if command == "ApplyXP" and args.usbType and args.difficulty then
        if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
            -- Buscar laptop si se proporcionó ID
            local laptop = nil
            if args.laptopID then
                local inventory = player:getInventory()
                if inventory then
                    for i = 0, inventory:getItems():size() - 1 do
                        local item = inventory:getItems():get(i)
                        if item and item:getID() == args.laptopID then
                            laptop = item
                            break
                        end
                    end
                end
            end
            
            local isSuccess = args.isSuccess
            if isSuccess == nil then isSuccess = true end
            
            GVDrive_Utils.applyMinigameResult(player, laptop, args.usbType, args.difficulty, isSuccess)
            debugPrint("XP applied for " .. args.usbType .. " (" .. args.difficulty .. ")")
        end
    end
end

if Events and Events.OnClientCommand and Events.OnClientCommand.Add then
    Events.OnClientCommand.Add(handleClientCommand)
    debugPrint("Server command handler registered for GVDrive")
end
