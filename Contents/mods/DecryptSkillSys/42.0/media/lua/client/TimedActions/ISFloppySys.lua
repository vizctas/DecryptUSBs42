require("TimedActions/ISBaseTimedAction")

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
    if self.character:getEmitter() then
        self.character:getEmitter():playSound("USBSys")
    end
    self:setOverrideHandModels(nil, nil)
end

function DecryptFloppyDisk:stop()
    ISBaseTimedAction.stop(self)
    if self.item and self.item:getItem() then
        self.item:getItem():setJobDelta(0.0)
    end
    if self.character:getEmitter() then
        self.character:getEmitter():stopSoundByName("USBSys")
    end
end
    function DecryptFloppyDisk:perform()
        forceDropHeavyItems(self.character)
        local inventoryItem = self.character:getInventory()
        local ISUsbAvaible = inventoryItem:getItemCount("GValley.FloppyDrive") -- ensure fully-qualified type
        local diceroll           = 0
        local randomLvl                 = 0
        local loopcter                  = 0
        local randomPerk                = 0
        local MaxRolls                  = 16
        local probabilityToKppUsing     = 5
        local probabilityToGain         = MaxRolls*(SandboxVars.GVDrive.Probability_Decrypt_Diskette/100) -- 90
        local maxExpGain = SandboxVars.GVDrive.Max_Exp_Learn_By_Diskette
        local minExpGain = SandboxVars.GVDrive.Min_Exp_Learn_By_Diskette

        if ISUsbAvaible < 1  
        then  
            --self.character:Say("Need a floppy first") 
            return
        end
        diceroll        = 0
        diceroll         = ZombRand(1.0,MaxRolls);
        --self.character:Say(tostring(diceroll).."of"..tostring(MaxRolls));
        if diceroll     >= probabilityToGain -- 6.4 debe ser mayor al aleatorio de 1.0 a 15
        then 
            randomPerk = 0 -- Reinitialize per queue action
            randomLvl = ZombRand(minExpGain,maxExpGain)+1;	-- gain exp
            randomPerk = ZombRand(1,11);

            if randomPerk == 0 then randomPerk = randomPerk+1 end       
            if randomPerk == 1 
            then 
                self.character:getXp():AddXP(Perks.Woodwork, randomLvl)
                diceroll        = ZombRand(13)+1;
                if diceroll >= 10
                then
                    self.character:Say(getText("GVDrive_Msg_Woodwork_Success"))
                else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                    --self.character:Say("Well there is nothing else to decrypt here.")
                    self.character:Say(getText("GVDrive_Msg_Woodwork_Consume"))
                    inventoryItem:Remove("GValley.FloppyDrive")
                    inventoryItem:AddItem("GValley.FloppyDrive_Used",1)
                end
            end

            if randomPerk == 2 
            then 
                self.character:getXp():AddXP(Perks.Electricity, randomLvl)
                diceroll        = ZombRand(13)+1;
                if diceroll >= 10
                then
                    self.character:Say(getText("GVDrive_Msg_Electricity_Success"))
                else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                   -- self.character:Say("Well there is nothing else to decrypt here.")
                    self.character:Say(getText("GVDrive_Msg_Electricity_Consume"))
                       
                    inventoryItem:Remove("GValley.FloppyDrive")
                    inventoryItem:AddItem("GValley.FloppyDrive_Used",1)
                end
            end

            if randomPerk == 3 
            then 
                self.character:getXp():AddXP(Perks.Farming, randomLvl)
                diceroll        = ZombRand(13)+1;
                if diceroll >= 10
                then
                    self.character:Say(getText("GVDrive_Msg_Farming_Success"))
                else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                   -- self.character:Say("Well there is nothing else to decrypt here.")
                    self.character:Say(getText("GVDrive_Msg_Farming_Consume"))
                    inventoryItem:Remove("GValley.FloppyDrive")
                    inventoryItem:AddItem("GValley.FloppyDrive_Used",1)
                end
            end
            if randomPerk == 4 
            then 
                self.character:getXp():AddXP(Perks.Aiming, randomLvl)
                diceroll        = ZombRand(13)+1;
                if diceroll >= 10
                then
                    self.character:Say(getText("GVDrive_Msg_Aiming_Success"))
                else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                   -- self.character:Say("Well there is nothing else to decrypt here.")
                   self.character:Say(getText("GVDrive_Msg_Aiming_Consume")) 
                    inventoryItem:Remove("GValley.FloppyDrive")
                    inventoryItem:AddItem("GValley.FloppyDrive_Used",1)
                end
            end
            if randomPerk == 5 
            then 
                self.character:getXp():AddXP(Perks.Cooking, randomLvl)
                diceroll        = ZombRand(13)+1;
                if diceroll >= 10
                then
                    self.character:Say("Got it! Some Cooking skills. So the government hid the food inside bunkers before the apocalypse ...! Should keep decrypting this drive ")
                else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                   -- self.character:Say("Well there is nothing else to decrypt here.")
                   self.character:Say("Got it! Some Cooking skills. What are these recipes?  I may find more info to decrypt more from another drive") 
                    inventoryItem:Remove("GValley.FloppyDrive")
                    inventoryItem:AddItem("GValley.FloppyDrive_Used",1)
                end
            end
            if randomPerk == 6 
            then 
                self.character:getXp():AddXP(Perks.Sneak, randomLvl)
                diceroll        = ZombRand(13)+1;
                if diceroll >= 10
                then
                    self.character:Say("Got it! Undercover agent's training files...That's how they sneak.... Hmm there might more information.")
                else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                   -- self.character:Say("Well there is nothing else to decrypt here.")
                   self.character:Say("Got it! Undercover agent's training files...That's how they sneak.  I may find more info to decrypt more from another drive") 
                    inventoryItem:Remove("GValley.FloppyDrive")
                    inventoryItem:AddItem("GValley.FloppyDrive_Used",1)
                end
            end


            if randomPerk == 7 
            then 
                self.character:getXp():AddXP(Perks.Axe, randomLvl)
                diceroll        = ZombRand(13)+1;
                if diceroll >= 10
                then
                    self.character:Say(getText("GVDrive_Msg_Axe_Success"))
                else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                    self.character:Say(getText("GVDrive_Msg_Axe_Consume"))
                    inventoryItem:Remove("GValley.FloppyDrive")
                    inventoryItem:AddItem("GValley.FloppyDrive_Used",1)
                end
            end



            if randomPerk == 8 
            then 
                self.character:getXp():AddXP(Perks.Fitness, randomLvl)
                diceroll        = ZombRand(13)+1;
                if diceroll >= 10
                then
                    self.character:Say(getText("GVDrive_Msg_Fitness_Success"))
                else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                   -- self.character:Say("Well there is nothing else to decrypt here.")
                   self.character:Say(getText("GVDrive_Msg_Fitness_Consume"))
                    inventoryItem:Remove("GValley.FloppyDrive")
                    inventoryItem:AddItem("GValley.FloppyDrive_Used",1)
                end
            end


            if randomPerk == 9 
            then 
                self.character:getXp():AddXP(Perks.Doctor, randomLvl)
                diceroll        = ZombRand(13)+1;
                if diceroll >= 10
                then
                    self.character:Say(getText("GVDrive_Msg_Doctor_Success"))
                else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                    self.character:Say(getText("GVDrive_Msg_Doctor_Consume"))
                    inventoryItem:Remove("GValley.FloppyDrive")
                    inventoryItem:AddItem("GValley.FloppyDrive_Used",1)
                end
            end

            if randomPerk == 10
            then 
                self.character:getXp():AddXP(Perks.Survivalist, randomLvl)
                diceroll        = ZombRand(13)+1;
                if diceroll >= 10
                then
                    self.character:Say(getText("GVDrive_Msg_Survivalist_Success"))
                else -- deployed. This will be change to a number of uses. I dont know how to store variables per each character.
                    self.character:Say(getText("GVDrive_Msg_Survivalist_Consume"))
                    inventoryItem:Remove("GValley.FloppyDrive")
                    inventoryItem:AddItem("GValley.FloppyDrive_Used",1)
                end
            end
            else
            self.character:Say(getText("GVDrive_Msg_Disk_Corrupted"))
            inventoryItem:Remove("GValley.FloppyDrive")
            inventoryItem:AddItem("GValley.FloppyDrive_Damaged")
        end
        ISBaseTimedAction.perform(self);
    end

    function DecryptFloppyDisk:new (character, item, time)
        local o = {}
        setmetatable(o, self)
        self.__index = self
        o.character = character;
        o.item = item;
        o.stopOnWalk = true;
        o.stopOnRun = true;
        -- print("time?")		   
        o.maxTime = time;
        o.loopedAction = false;
        return o
    end


