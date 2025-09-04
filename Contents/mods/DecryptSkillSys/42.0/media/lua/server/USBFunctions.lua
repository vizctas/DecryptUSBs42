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

    -- Show feedback
    HaloTextHelper.addTextWithArrow(ply, getText("GVDrive_Msg_USB_Opened_OK"), true, HaloTextHelper.getColorGreen())
end
