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
        local ISUsbAvaible = inventoryItem:getItemCount("USBOpened") -- doublecheck
        local randomLvl                 = 0
        local loopcter                  = 0
        local randomPerk                = 0
        local diceroll           = 0.00
        local MaxRolls                  = 15
        local probabilityToGain         = MaxRolls*(SandboxVars.GVDrive.Probability_Decrypt_USB/100) -- 90
        local maxExpGain = SandboxVars.GVDrive.Max_Exp_Learn_By_USB
        local minExpGain = SandboxVars.GVDrive.Min_Exp_Learn_By_USB  
        if ISUsbAvaible < 1  
        then  
            --self.character:Say("Need a drive first") 
            return
        end
        diceroll        = 0
        diceroll        = ZombRand(1.0,MaxRolls);
        --self.character:Say(tostring(diceroll).."of"..tostring(MaxRolls));
        if diceroll >= probabilityToGain
        then 
            randomPerk = 0 -- Reinitialize per queue action
            randomLvl = ZombRand(minExpGain,maxExpGain)+1;	-- gain exp
            randomPerk = ZombRand(1,11);
            if randomPerk == 0 then randomPerk = randomPerk+1 end
            local perkTable = {
                [1]  = Perks.Woodwork,
                [2]  = Perks.Electricity,
                [3]  = Perks.Farming,
                [4]  = Perks.Aiming,
                [5]  = Perks.Cooking,
                [6]  = Perks.Sneak,
                [7]  = Perks.Axe,
                [8]  = Perks.Fitness,
                [9]  = Perks.Doctor,
                [10] = Perks.Survivalist,
            }

                if randomPerk == 1 
                then 
                    self.character:getXp():AddXP(perkTable[randomPerk] or Perks.Woodwork, randomLvl)
                    diceroll        = ZombRand(13)+1;
                    if diceroll >= 10
                    then
                        self.character:Say(getText("GVDrive_Msg_Woodwork_Success"))
                    else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                        --self.character:Say("Well there is nothing else to decrypt here.")
                        self.character:Say(getText("GVDrive_Msg_Woodwork_Consume"))
                        inventoryItem:Remove("USBOpened")
                        inventoryItem:AddItem("GValley.USBOpened_Used",1)
                    end
                end

                if randomPerk == 2 
                then 
                    self.character:getXp():AddXP(perkTable[randomPerk] or Perks.Electricity, randomLvl)
                    diceroll        = ZombRand(13)+1;
                    if diceroll >= 10
                    then
                        self.character:Say(getText("GVDrive_Msg_Electricity_Success"))
                    else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                       -- self.character:Say("Well there is nothing else to decrypt here.")
                        self.character:Say(getText("GVDrive_Msg_Electricity_Consume"))
                        inventoryItem:Remove("USBOpened")
                        inventoryItem:AddItem("GValley.USBOpened_Used",1)
                    end
                end

                if randomPerk == 3 
                then 
                    self.character:getXp():AddXP(perkTable[randomPerk] or Perks.Farming, randomLvl)
                    diceroll        = ZombRand(13)+1;
                    if diceroll >= 10
                    then
                        self.character:Say(getText("GVDrive_Msg_Farming_Success"))
                    else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                       -- self.character:Say("Well there is nothing else to decrypt here.")
                        self.character:Say(getText("GVDrive_Msg_Farming_Consume"))
                        inventoryItem:Remove("USBOpened")
                        inventoryItem:AddItem("GValley.USBOpened_Used",1)
                    end
                end
                if randomPerk == 4 
                then 
                    self.character:getXp():AddXP(perkTable[randomPerk] or Perks.Aiming, randomLvl)
                    diceroll        = ZombRand(13)+1;
                    if diceroll >= 10
                    then
                        self.character:Say(getText("GVDrive_Msg_Aiming_Success"))
                    else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                       -- self.character:Say("Well there is nothing else to decrypt here.")
                       self.character:Say(getText("GVDrive_Msg_Aiming_Consume"))
                        inventoryItem:Remove("USBOpened")
                        inventoryItem:AddItem("GValley.USBOpened_Used",1)
                    end
                end
                if randomPerk == 5 
                then 
                    self.character:getXp():AddXP(perkTable[randomPerk] or Perks.Cooking, randomLvl)
                    diceroll        = ZombRand(13)+1;
                    if diceroll >= 10
                    then
                        self.character:Say(getText("GVDrive_Msg_Cooking_Success"))
                    else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                       -- self.character:Say("Well there is nothing else to decrypt here.")
                       self.character:Say(getText("GVDrive_Msg_Cooking_Consume")) 
                        inventoryItem:Remove("USBOpened")
                        inventoryItem:AddItem("GValley.USBOpened_Used",1)
                    end
                end
                if randomPerk == 6 
                then 
                    self.character:getXp():AddXP(perkTable[randomPerk] or Perks.Sneak, randomLvl)
                    diceroll        = ZombRand(13)+1;
                    if diceroll >= 10
                    then
                        self.character:Say(getText("GVDrive_Msg_Sneak_Success"))
                    else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                       -- self.character:Say("Well there is nothing else to decrypt here.")
                       self.character:Say(getText("GVDrive_Msg_Sneak_Consume")) 
                        inventoryItem:Remove("USBOpened")
                        inventoryItem:AddItem("GValley.USBOpened_Used",1)
                    end
                end
                if randomPerk == 7 
                then 
                    self.character:getXp():AddXP(perkTable[randomPerk] or Perks.Axe, randomLvl)
                    diceroll        = ZombRand(13)+1;
                    if diceroll >= 10
                    then
                        self.character:Say(getText("GVDrive_Msg_Axe_Success"))
                    else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                        self.character:Say(getText("GVDrive_Msg_Axe_Consume"))
                        inventoryItem:Remove("USBOpened")
                        inventoryItem:AddItem("GValley.USBOpened_Used",1)
                    end
                end
                if randomPerk == 8 
                then 
                    self.character:getXp():AddXP(perkTable[randomPerk] or Perks.Fitness, randomLvl)
                    diceroll        = ZombRand(13)+1;
                    if diceroll >= 10
                    then
                        self.character:Say(getText("GVDrive_Msg_Fitness_Success"))
                    else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                       -- self.character:Say("Well there is nothing else to decrypt here.")
                       self.character:Say(getText("GVDrive_Msg_Fitness_Consume"))
                        inventoryItem:Remove("USBOpened")
                        inventoryItem:AddItem("GValley.USBOpened_Used",1)
                    end
                end


                if randomPerk == 9 
                then 
                    self.character:getXp():AddXP(perkTable[randomPerk] or Perks.Doctor, randomLvl)
                    diceroll        = ZombRand(13)+1;
                    if diceroll >= 10
                    then
                        self.character:Say(getText("GVDrive_Msg_Doctor_Success"))
                    else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                        self.character:Say(getText("GVDrive_Msg_Doctor_Consume"))
                        inventoryItem:Remove("USBOpened")
                        inventoryItem:AddItem("GValley.USBOpened_Used",1)
                    end
                end

                if randomPerk == 10
                then 
                    self.character:getXp():AddXP(perkTable[randomPerk] or Perks.Survivalist, randomLvl)
                    diceroll        = ZombRand(13)+1;
                    if diceroll >= 10
                    then
                        self.character:Say(getText("GVDrive_Msg_Survivalist_Success"))
                    else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                        self.character:Say(getText("GVDrive_Msg_Survivalist_Consume"))
                        inventoryItem:Remove("USBOpened")
                        inventoryItem:AddItem("GValley.USBOpened_Used",1)
                    end
                end
            else
            self.character:Say(getText("GVDrive_Msg_USB_Corrupted"))
            inventoryItem:Remove("USBOpened")
            inventoryItem:AddItem("GValley.USBOpened_Damaged")
        end
        if self.sound and self.character and self.character:getEmitter() then
            self.character:getEmitter():stopSound(self.sound)
            self.sound = nil
        end
        ISBaseTimedAction.perform(self);
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



