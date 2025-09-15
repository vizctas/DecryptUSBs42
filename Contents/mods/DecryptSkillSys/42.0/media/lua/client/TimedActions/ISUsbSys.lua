require("TimedActions/ISBaseTimedAction")

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
        local ISUsbAvaible = inventoryItem:getItemCount("GValley.USBOpened") -- ensure fully-qualified type
        if ISUsbAvaible < 1 then
            --self.character:Say("Need a drive first")
            return
        end

        local MaxRolls = 15
        local probabilityToGain = MaxRolls * (SandboxVars.GVDrive.Probability_Decrypt_USB / 100)
        local diceroll = ZombRand(1.0, MaxRolls)

        if diceroll >= probabilityToGain then
            local maxExpGain = SandboxVars.GVDrive.Max_Exp_Learn_By_USB
            local minExpGain = SandboxVars.GVDrive.Min_Exp_Learn_By_USB
            local randomLvl = ZombRand(minExpGain, maxExpGain) + 1

            local perkTable = {
                Perks.Woodwork,
                Perks.Electricity,
                Perks.Farming,
                Perks.Aiming,
                Perks.Cooking,
                Perks.Sneak,
                Perks.Axe,
                Perks.Fitness,
                Perks.Doctor,
                Perks.Survivalist,
            }
            local randomPerkIndex = ZombRand(1, #perkTable + 1)
            local randomPerk = perkTable[randomPerkIndex]
            
            local perkNameMap = {
                [Perks.Woodwork] = "Woodwork",
                [Perks.Electricity] = "Electricity",
                [Perks.Farming] = "Farming",
                [Perks.Aiming] = "Aiming",
                [Perks.Cooking] = "Cooking",
                [Perks.Sneak] = "Sneak",
                [Perks.Axe] = "Axe",
                [Perks.Fitness] = "Fitness",
                [Perks.Doctor] = "Doctor",
                [Perks.Survivalist] = "Survivalist",
            }
            local perkName = perkNameMap[randomPerk] or "Woodwork"

            self.character:getXp():AddXP(randomPerk, randomLvl)

            local consumeRoll = ZombRand(13) + 1
            if consumeRoll >= 10 then
                self.character:Say(getText("GVDrive_Msg_"..perkName.."_Success"))
            else
                self.character:Say(getText("GVDrive_Msg_"..perkName.."_Consume"))
                inventoryItem:Remove("GValley.USBOpened")
                inventoryItem:AddItem("GValley.USBOpened_Used", 1)
            end
        else
            self.character:Say(getText("GVDrive_Msg_USB_Corrupted"))
            inventoryItem:Remove("GValley.USBOpened")
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


