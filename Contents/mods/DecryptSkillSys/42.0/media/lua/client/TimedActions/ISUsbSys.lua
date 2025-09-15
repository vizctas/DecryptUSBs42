require("TimedActions/ISBaseTimedAction")
require("shared/GVDrive_Utils")

DecryptDrive = ISBaseTimedAction:derive("DecryptDrive")

function DecryptDrive:isValid()
    return self.character and not self.character:isDead()
end  
        
    function DecryptDrive:update()
        if self.item and self.item:getItem() then
            self.item:getItem():setJobDelta(self:getJobDelta())
        end
    end
    function DecryptDrive:start()
        self:setActionAnim("Loot")
        self:setAnimVariable("LootPosition", "Medium")
        if self.character and self.character:getEmitter() then
            self.sound = self.character:getEmitter():playSound("USBSys")
        end
        self:setOverrideHandModels(nil, nil)
       -- self.item:getItem():setJobType(getText("ContextMenu_Grab"));
    end
    function DecryptDrive:stop()
        ISBaseTimedAction.stop(self)
        if self.item and self.item:getItem() then
            self.item:getItem():setJobDelta(0.0)
        end
        if self.sound and self.character and self.character:getEmitter() then
            self.character:getEmitter():stopSound(self.sound)
            self.sound = nil
        end
    end
    function DecryptDrive:perform()
        forceDropHeavyItems(self.character)
        local inventoryItem = self.character:getInventory()
        local ISUsbAvaible = inventoryItem:getItemCount("GValley.USBOpened")
        if ISUsbAvaible < 1 then
            return
        end

        -- Always consume one USB at the start
        inventoryItem:Remove("GValley.USBOpened")

        local MaxRolls = 15
        local probabilityToGain = MaxRolls * (SandboxVars.GVDrive.Probability_Decrypt_USB / 100)
        local diceroll = ZombRand(1.0, MaxRolls)

        if diceroll >= probabilityToGain then
            local randomPerk = GVDrive_Utils.getRandomPerk()
            local perkName = GVDrive_Utils.getPerkName(randomPerk)
            local experienceGain = GVDrive_Utils.calculateScalableExperience(self.character, randomPerk, true)

            self.character:getXp():AddXP(randomPerk, experienceGain)

            local consumeRoll = ZombRand(13) + 1
            if consumeRoll >= 10 then
                self.character:Say(getText("GVDrive_Msg_"..perkName.."_Success") or "Got it! Some "..perkName.." skills. Should keep trying to decrypt...")
                -- USB is preserved, give it back as used
                inventoryItem:AddItem("GValley.USBOpened_Used", 1)
            else
                self.character:Say(getText("GVDrive_Msg_"..perkName.."_Consume") or "Got it! Some "..perkName.." skills. USB is consumed.")
                -- USB is fully consumed, give used version
                inventoryItem:AddItem("GValley.USBOpened_Used", 1)
            end
        else
            self.character:Say(getText("GVDrive_Msg_USB_Corrupted") or "Drive corrupted!")
            -- USB is corrupted, give damaged version
            inventoryItem:AddItem("GValley.USBOpened_Damaged")
        end

        if self.sound and self.character and self.character:getEmitter() then
            self.character:getEmitter():stopSound(self.sound)
            self.sound = nil
        end
        ISBaseTimedAction.perform(self)
    end
    function DecryptDrive:new (character, item, time)
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o.character = character;
        o.item = item;
        o.stopOnWalk = true;
        o.stopOnRun = true;
        -- print("time?")		   
        o.maxTime = time;
        o.loopedAction = true;
        return o
    end


