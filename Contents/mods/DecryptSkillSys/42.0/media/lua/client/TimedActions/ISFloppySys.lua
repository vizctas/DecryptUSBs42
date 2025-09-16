require("TimedActions/ISBaseTimedAction")
require("shared/GVDrive_Utils")
require("shared/LaptopSystem")

DecryptFloppyDisk = ISBaseTimedAction:derive("DecryptFloppyDisk")

function DecryptFloppyDisk:isValid()
    return self.character and not self.character:isDead()
end  
        
function DecryptFloppyDisk:update()
    if self.item and self.item:getItem() then
        self.item:getItem():setJobDelta(self:getJobDelta())
    end
end

function DecryptFloppyDisk:start()
    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "Medium")
    if self.character and self.character:getEmitter() then
        self.sound = self.character:getEmitter():playSound("USBSys")
    end
    self:setOverrideHandModels(nil, nil)
end

function DecryptFloppyDisk:stop()
    ISBaseTimedAction.stop(self)
    if self.item then
        self.item:setJobDelta(0.0)
    end
    if self.sound and self.character and self.character:getEmitter() then
        self.character:getEmitter():stopSound(self.sound)
        self.sound = nil
    end
end

function DecryptFloppyDisk:perform()
    forceDropHeavyItems(self.character)
    local inventoryItem = self.character:getInventory()
    local ISFloppyAvaible = inventoryItem:getItemCount("GValley.FloppyDrive")
    if ISFloppyAvaible < 1 then
        return
    end

    local MaxRolls = 16
    local probabilityToGain = MaxRolls * (SandboxVars.GVDrive.Floppy_Decrypt_Success_Chance / 100)
    local diceroll = ZombRand(1.0, MaxRolls)

    -- Check if drive should be preserved (chance to NOT destroy it)
    local preserveChance = (SandboxVars.GVDrive.Drive_Preserve_Chance or 30) / 100
    local shouldPreserve = ZombRand(100) / 100 < preserveChance
    
    -- Always consume one floppy unless it's preserved
    if not shouldPreserve then
        inventoryItem:Remove("GValley.FloppyDrive")
    end

    if diceroll >= probabilityToGain then
        -- Use GVDrive_Utils directly (ClientInit.lua ensures it's loaded)
        local driveInfo = nil
        if self.item and self.item.getItem and GVDrive_Utils and GVDrive_Utils.getDriveInfo then
            local ok, info = pcall(GVDrive_Utils.getDriveInfo, self.item:getItem())
            if ok then driveInfo = info end
        end

        local perk = nil
        if GVDrive_Utils and GVDrive_Utils.getDrivePerk then
            perk = GVDrive_Utils.getDrivePerk(driveInfo or self.item)
        else
            perk = GVDrive_Utils.getPerkFromDrive(driveInfo)
        end

        local perkName = (GVDrive_Utils and GVDrive_Utils.getPerkName and GVDrive_Utils.getPerkName(perk)) or "Unknown"
        local experienceGain = GVDrive_Utils and GVDrive_Utils.calculateDriveExperience and GVDrive_Utils.calculateDriveExperience(self.character, driveInfo) or 20

        if perk and self.character and self.character.getXp then
            self.character:getXp():AddXP(perk, experienceGain)
        end

        -- Success: normal laptop wear
        LaptopSystem.damageLaptop(self.item, 1)

        local consumeRoll = ZombRand(13) + 1
        if consumeRoll >= 10 then
            self.character:Say(getText("GVDrive_Msg_"..perkName.."_Success") or "Got it! Some "..perkName.." skills. Should keep trying to decrypt...")
            -- Floppy is preserved, give it back as used
            inventoryItem:AddItem("GValley.FloppyDrive_Used", 1)
        else
            self.character:Say(getText("GVDrive_Msg_"..perkName.."_Consume") or "Got it! Some "..perkName.." skills. Floppy is consumed.")
            -- Floppy is fully consumed, give used version
            inventoryItem:AddItem("GValley.FloppyDrive_Used", 1)
        end
    else
        -- Failure: Check for malware
        local malwareChance = (SandboxVars.GVDrive.Malware_Chance or 15) / 100
        local gotMalware = ZombRand(100) / 100 < malwareChance
        
        if gotMalware then
            local isNewInfection = LaptopSystem.applyMalware(self.item)
            if isNewInfection then
                self.character:Say(getText("GVDrive_Msg_Floppy_Malware") or "WARNING: Malware detected! Laptop infected!")
            else
                self.character:Say(getText("GVDrive_Msg_Floppy_Malware_Worse") or "Malware is spreading! Laptop severely damaged!")
            end
        else
            -- Normal failure: just laptop wear
            LaptopSystem.damageLaptop(self.item, 2)
            self.character:Say(getText("GVDrive_Msg_Disk_Corrupted") or "Drive corrupted!")
        end
        self.character:Say(getText("GVDrive_Msg_Disk_Corrupted") or "Disk corrupted!")
        -- Floppy is corrupted, give damaged version
        inventoryItem:AddItem("GValley.FloppyDrive_Damaged")
    end

    if self.sound and self.character and self.character:getEmitter() then
        self.character:getEmitter():stopSound(self.sound)
        self.sound = nil
    end
    
    ISBaseTimedAction.perform(self)
end

function DecryptFloppyDisk:new (character, item, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character;
    o.item = item;
    o.stopOnWalk = true;
    o.stopOnRun = true;
    o.maxTime = time;
    o.loopedAction = false;
    return o
end


