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
        print("[DecryptSkillSys] USB opened result granted: " .. tostring(selectedItem))
    end
end
