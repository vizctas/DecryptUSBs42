require("TimedActions/ISBaseTimedAction")
require("shared/GVDrive_Utils")
require("shared/LaptopSystem")

pcall(require, "shared/GVDrive_Config")
-- Defensive GVDebug require: some load orders may not have it available yet
local ok_dbg, dbg_mod = pcall(require, "shared/GVDebug")
local GVDebug = nil
if ok_dbg and type(dbg_mod) == "table" then
    GVDebug = dbg_mod
else
    GVDebug = { debugPrint = function(...) end }
end

local function debugPrint(...)
    if GVDebug and GVDebug.debugPrint then
        GVDebug.debugPrint(...)
    end
end

local function ensureGVDriveUtils()
    if GVDrive_Utils and type(GVDrive_Utils) == "table" then
        return GVDrive_Utils
    end

    local ok, module = pcall(require, "shared/GVDrive_Utils")
    if ok and type(module) == "table" then
        GVDrive_Utils = module
        return GVDrive_Utils
    end

    if GVDrive_Utils and type(GVDrive_Utils) == "table" then
        return GVDrive_Utils
    end

    debugPrint("[DecryptSkillDrive] ERROR: GVDrive_Utils unavailable: " .. tostring(module))
    return nil
end

local function fallbackDriveInfo(item)
    if not item then return nil end
    local fullType = tostring(item:getFullType() or item:getType() or "")
    if fullType == "" then return nil end

    local short = fullType:match("([^%.]+)$") or fullType
    if short:find("SkillDrive_") or short:find("SkillFloppy_") then
        local parts = {}
        for part in short:gmatch("([^_]+)") do
            parts[#parts+1] = part
        end
        if #parts >= 3 then
            return {
                skill = parts[2],
                skillName = parts[2],
                rarity = parts[3],
                difficulty = parts[3],
                isUSB = short:find("SkillDrive_") ~= nil,
            }
        end
    end

    if short == "USBOpened" or short == "USBOpened_Damaged" or short == "USBOpened_Used" then
        return { skill = "LegacyUSB", skillName = "LegacyUSB", rarity = "Normal", difficulty = "Normal", isUSB = true }
    end
    -- Treat legacy floppy items as USB equivalents to avoid creating floppy items (v42 USB-only)
    if short == "FloppyDrive" or short == "FloppyDrive_Damaged" or short == "FloppyDrive_Used" then
        return { skill = "LegacyFloppy", skillName = "LegacyFloppy", rarity = "Normal", difficulty = "Normal", isUSB = true }
    end
    return nil
end

local function resolvePerk(perkValue, skillName, utils)
    if perkValue then
        if type(perkValue) ~= "string" then
            return perkValue
        end
        if utils and utils.getPerkFromName then
            local perk = utils.getPerkFromName(perkValue)
            if perk then return perk end
        end
        if Perks and Perks.FromString then
            local ok, perk = pcall(Perks.FromString, perkValue)
            if ok and perk then return perk end
        end
    end

    if skillName and utils and utils.getPerkFromName then
        local perk = utils.getPerkFromName(skillName)
        if perk then return perk end
    end

    if skillName and Perks and Perks.FromString then
        local ok, perk = pcall(Perks.FromString, skillName)
        if ok and perk then return perk end
    end

    return nil
end

-- Function to get translated message with fallback
local function getTranslatedMessage(key, fallback)
    if not key then return fallback or "Unknown message" end
    
    local translated = getText(key)
    if translated and translated ~= key then
        return translated
    end
    
    return fallback or "Unknown message"
end

DecryptSkillDrive = ISBaseTimedAction:derive("DecryptSkillDrive")

local globalEnv = _G or (type(getfenv) == "function" and getfenv(0)) or nil
if globalEnv then
    globalEnv.DecryptSkillDrive = DecryptSkillDrive
end

function DecryptSkillDrive:isValid()
    local hasCharacter = self.character ~= nil and (not self.character:isDead())
    local hasDrive = self.drive ~= nil
    local hasLaptop = self.laptop ~= nil
    
    -- Check laptop health
    local laptopUsable = false
    if hasLaptop and self.laptop.getItem then
        local laptopItem = self.laptop:getItem()
        if laptopItem and LaptopSystem and LaptopSystem.getLaptopHealth then
            local health = LaptopSystem.getLaptopHealth(laptopItem)
            laptopUsable = health and health > 0
        else
            laptopUsable = true -- fallback if no health system
        end
    end
    
    local valid = hasCharacter and hasDrive and hasLaptop and laptopUsable
    debugPrint("isValid called - character:", tostring(self.character), "drive:", tostring(self.drive), "laptopUs:", tostring(laptopUsable), "result:", tostring(valid))
    return valid
end  
        
function DecryptSkillDrive:update()
    if self.laptop and self.laptop.getItem then
        local laptopItem = self.laptop:getItem()
        if laptopItem then
            laptopItem:setJobDelta(self:getJobDelta())
            
            -- Check if laptop is still usable during the action
            if LaptopSystem and LaptopSystem.getLaptopHealth then
                local health = LaptopSystem.getLaptopHealth(laptopItem)
                if health and health <= 0 then
                    debugPrint("Laptop reached 0% health, cancelling action")
                    -- Stop the action and show message
                    if self.character then
                        local brokenText = getTranslatedMessage("GVDrive_Error_Laptop_Broken", "This laptop is completely broken and unusable.")
                        self.character:Say(brokenText)
                    end
                    self:forceStop()
                    return
                end
            end
        end
    end
end

function DecryptSkillDrive:start()
    debugPrint("start() called")
    self:setActionAnim("Loot")
    self:setAnimVariable("LootPosition", "Medium")
    if self.character and self.character:getEmitter() then
        self.sound = self.character:getEmitter():playSound("USBSys")
    end
    self:setOverrideHandModels(nil, nil)
end

function DecryptSkillDrive:stop()
    ISBaseTimedAction.stop(self)
    if self.laptop and self.laptop.getItem then
        local laptopItem = self.laptop:getItem()
        if laptopItem then
            laptopItem:setJobDelta(0.0)
        end
    end
    if self.sound and self.character and self.character:getEmitter() then
        self.character:getEmitter():stopSound(self.sound)
        self.sound = nil
    end
end

function DecryptSkillDrive:perform()
    debugPrint("perform() called")
    forceDropHeavyItems(self.character)

    if not self.character or not self.character.getInventory then
        debugPrint("[DecryptSkillDrive] ERROR: character or inventory missing")
        ISBaseTimedAction.perform(self)
        return
    end

    local inventory = self.character:getInventory()
    if not inventory then
        debugPrint("[DecryptSkillDrive] ERROR: inventory not available")
        ISBaseTimedAction.perform(self)
        return
    end

    local laptopItem = nil
    if self.laptop and self.laptop.getItem then
        laptopItem = self.laptop:getItem()
    end

    if not laptopItem then
        debugPrint("[DecryptSkillDrive] ERROR: Cannot get laptop item from world object")
        if self.sound and self.character and self.character:getEmitter() then
            self.character:getEmitter():stopSound(self.sound)
            self.sound = nil
        end
        ISBaseTimedAction.perform(self)
        return
    end

    local utils = ensureGVDriveUtils()
    local driveInfo = nil
    if utils and utils.getDriveInfo then
        local ok, info = pcall(utils.getDriveInfo, self.drive)
        if ok then driveInfo = info end
    end

    if not driveInfo then
        driveInfo = fallbackDriveInfo(self.drive)
    end

    if not driveInfo then
        debugPrint("[DecryptSkillDrive] ERROR: Could not determine drive info")
        if self.sound and self.character and self.character:getEmitter() then
            self.character:getEmitter():stopSound(self.sound)
            self.sound = nil
        end
        ISBaseTimedAction.perform(self)
        return
    end

    local skillName = driveInfo.skillName or (type(driveInfo.skill) == "string" and driveInfo.skill) or "Unknown"
    local driveFullType = nil
    if self.drive then
        if self.drive.getFullType then
            driveFullType = self.drive:getFullType()
        end
        if not driveFullType and self.drive.getType then
            driveFullType = self.drive:getType()
        end
    end

    if driveFullType and inventory.getItemCount then
        local driveCount = inventory:getItemCount(driveFullType)
        if driveCount < 1 then
            if self.sound and self.character and self.character:getEmitter() then
                self.character:getEmitter():stopSound(self.sound)
                self.sound = nil
            end
            ISBaseTimedAction.perform(self)
            return
        end
    end

    local successChance = 50
    if utils and utils.getSuccessChance then
        local ok, chance = pcall(utils.getSuccessChance, driveInfo)
        if ok and type(chance) == "number" then
            successChance = math.max(0, math.min(100, chance))
        end
    end
    -- Ensure successChance is a number
    successChance = tonumber(successChance) or 50

    local MaxRolls = 100
    local probabilityToGain = math.max(0, math.min(100, successChance))
    local diceroll = ZombRand(1, MaxRolls)

    local preserveChancePercent = 30
    if GVDrive_Utils and GVDrive_Utils.getSandboxNumber then
        preserveChancePercent = GVDrive_Utils.getSandboxNumber('Drive_Preserve_Chance', 30)
    end
    -- Ensure preserveChancePercent is a number
    preserveChancePercent = tonumber(preserveChancePercent) or 30
    local preserveChance = math.max(0, math.min(100, preserveChancePercent)) / 100
    local shouldPreserve = ZombRand(100) / 100 < preserveChance

    local function removeDriveFromInventory()
        if not inventory then return false end
        local removed = false
        if self.drive and inventory.contains and inventory:contains(self.drive) then
            inventory:Remove(self.drive)
            removed = true
        elseif driveFullType then
            if inventory.RemoveOneOf then
                local removedItem = inventory:RemoveOneOf(driveFullType)
                removed = removedItem ~= nil
            elseif inventory.Remove then
                inventory:Remove(driveFullType)
                removed = true
            end
        end
        if not removed then
            debugPrint("WARNING: failed to remove drive from inventory")
        end
        return removed
    end

    local xpGainDefault = 50
    if utils and utils.calculateDriveExperience then
        local ok, xpGain = pcall(utils.calculateDriveExperience, self.character, driveInfo)
        if ok and type(xpGain) == "number" then
            xpGainDefault = xpGain
        end
    end

    local laptopDamageSuccess = driveInfo.isUSB and 2 or 1
    local laptopDamageFailure = driveInfo.isUSB and 2 or 1
    if utils and utils.getLaptopDamage then
        local okSuccess, dmgSuccess = pcall(utils.getLaptopDamage, driveInfo, true)
        if okSuccess and type(dmgSuccess) == "number" then
            laptopDamageSuccess = dmgSuccess
        end
        local okFail, dmgFail = pcall(utils.getLaptopDamage, driveInfo, false)
        if okFail and type(dmgFail) == "number" then
            laptopDamageFailure = dmgFail
        end
    end

    local perk = resolvePerk(driveInfo.skill, skillName, utils)

    if diceroll <= probabilityToGain then
        local preservedDrive = shouldPreserve
        if not preservedDrive then
            removeDriveFromInventory()
        else
            debugPrint("Drive preserved after success")
        end

        if perk and self.character and self.character.getXp then
            local xp = self.character:getXp()
            if xp and xp.AddXP then
                xp:AddXP(perk, xpGainDefault)
            end
        end

        -- Only damage laptop if drive is preserved (not consumed)
        -- When USB is consumed successfully, laptop should not take damage
        if preservedDrive and LaptopSystem and LaptopSystem.damageLaptop then
            LaptopSystem.damageLaptop(laptopItem, laptopDamageSuccess)
        end

        if preservedDrive then
            -- Use generic preserved message since specific ones may not exist
            local preservedText = getTranslatedMessage("GVDrive_Msg_Drive_Preserved", "Drive survived the decryption. " .. skillName .. " data remains available.")
            self.character:Say(preservedText)
        else
            local consumeRoll = ZombRand(13) + 1
            if consumeRoll >= 10 then
                -- Success message - use existing translations or fallback
                local successKey = "GVDrive_Msg_" .. skillName .. "_Success"
                local successText = getTranslatedMessage(successKey, "Got it! Some " .. skillName .. " skills. Should keep trying to decrypt...")
                self.character:Say(successText)
                if inventory and inventory.AddItem then
                        -- Always add USB used variant (floppy types mapped to USB for v42)
                        inventory:AddItem("GValley.USBOpened_Used", 1)
                end
            else
                -- Consume message - use existing translations or fallback
                local consumeKey = "GVDrive_Msg_" .. skillName .. "_Consume"
                local consumeText = getTranslatedMessage(consumeKey, "Got it! Some " .. skillName .. " skills. Drive is consumed.")
                self.character:Say(consumeText)
                if inventory and inventory.AddItem then
                        -- Always add USB used variant (floppy types mapped to USB for v42)
                        inventory:AddItem("GValley.USBOpened_Used", 1)
                end
            end
        end
    else
        removeDriveFromInventory()

        local malwareChancePercent = 15
        if GVDrive_Utils and GVDrive_Utils.getMalwareChance then
            local ok, malChance = pcall(GVDrive_Utils.getMalwareChance, GVDrive_Utils, driveInfo)
            if ok and type(malChance) == 'number' then
                malwareChancePercent = malChance
            end
        else
            if GVDrive_Utils and GVDrive_Utils.getSandboxNumber then
                malwareChancePercent = GVDrive_Utils.getSandboxNumber('Malware_Chance', 15)
            end
        end
        if utils and utils.getMalwareChance then
            local ok, malChance = pcall(utils.getMalwareChance, driveInfo)
            if ok and type(malChance) == "number" then
                malwareChancePercent = malChance
            end
        end
        local malwareChance = math.max(0, math.min(100, malwareChancePercent)) / 100

        local gotMalware = ZombRand(100) / 100 < malwareChance

        if gotMalware and LaptopSystem and LaptopSystem.applyMalware then
            local isNewInfection = LaptopSystem.applyMalware(laptopItem)
            if isNewInfection then
                -- New malware infection - use generic message
                local malwareText = getTranslatedMessage("GVDrive_Msg_USB_Malware", "WARNING: Malware detected! Laptop infected!")
                self.character:Say(malwareText)
            else
                -- Existing malware getting worse - use generic message
                local malwareWorseText = getTranslatedMessage("GVDrive_Msg_USB_Malware_Worse", "Malware is spreading! Laptop severely damaged!")
                self.character:Say(malwareWorseText)
            end
        else
            if LaptopSystem and LaptopSystem.damageLaptop then
                LaptopSystem.damageLaptop(laptopItem, laptopDamageFailure)
            end
            local corruptedText = getTranslatedMessage("GVDrive_Msg_Drive_Corrupted", "Drive corrupted!")
            self.character:Say(corruptedText)
        end

        if inventory and inventory.AddItem then
            -- Always add USB damaged variant (floppy types mapped to USB for v42)
            inventory:AddItem("GValley.USBOpened_Damaged")
        end
    end

    if self.sound and self.character and self.character:getEmitter() then
        self.character:getEmitter():stopSound(self.sound)
        self.sound = nil
    end
    ISBaseTimedAction.perform(self)
end

function DecryptSkillDrive:new(character, laptop, drive, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.laptop = laptop
    o.drive = drive
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = time or 500
    o.loopedAction = false
    debugPrint("Constructor called - character:", tostring(character), "laptop:", tostring(laptop), "drive:", tostring(drive))
    return o
end

return DecryptSkillDrive
