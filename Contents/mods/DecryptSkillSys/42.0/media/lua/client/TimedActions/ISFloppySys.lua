require("TimedActions/ISBaseTimedAction")
require("shared/GVDrive_Utils")

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
    if self.item and self.item:getItem() then
        self.item:getItem():setJobDelta(0.0)
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

    -- Always consume one floppy at the start
    inventoryItem:Remove("GValley.FloppyDrive")

    local MaxRolls = 16
    local probabilityToGain = MaxRolls * (SandboxVars.GVDrive.Probability_Decrypt_Diskette / 100)
    local diceroll = ZombRand(1.0, MaxRolls)

    if diceroll >= probabilityToGain then
        local randomPerk = GVDrive_Utils.getRandomPerk()
        local perkName = GVDrive_Utils.getPerkName(randomPerk)
        local experienceGain = GVDrive_Utils.calculateScalableExperience(self.character, randomPerk, false)

        self.character:getXp():AddXP(randomPerk, experienceGain)

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
    function DecryptFloppyDisk:perform()
        forceDropHeavyItems(self.character)
        local inventoryItem = self.character:getInventory()
        local ISFloppyAvaible = inventoryItem:getItemCount("GValley.FloppyDrive") -- ensure fully-qualified type
        if ISFloppyAvaible < 1 then
            --self.character:Say("Need a floppy first")
            return
        end

        local MaxRolls = 16
        local probabilityToGain = MaxRolls * (SandboxVars.GVDrive.Probability_Decrypt_Diskette / 100)
        local diceroll = ZombRand(1.0, MaxRolls)

        if diceroll >= probabilityToGain then
            local maxExpGain = SandboxVars.GVDrive.Max_Exp_Learn_By_Diskette
            local minExpGain = SandboxVars.GVDrive.Min_Exp_Learn_By_Diskette
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
                inventoryItem:Remove("GValley.FloppyDrive")
                inventoryItem:AddItem("GValley.FloppyDrive_Used", 1)
            end
        else
            self.character:Say(getText("GVDrive_Msg_Disk_Corrupted"))
            inventoryItem:Remove("GValley.FloppyDrive")
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


