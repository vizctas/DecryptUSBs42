require "TimedActions/ISBaseTimedAction"

UseEliteDrive = ISBaseTimedAction:derive("UseEliteDrive")

function UseEliteDrive:new(character, worldObj, driveType, time)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.character = character
    o.worldObj = worldObj
    o.driveType = driveType
    o.stopOnWalk = true
    o.stopOnRun = true
    o.maxTime = time or 500 -- default 5s (500 ticks)
    return o
end

function UseEliteDrive:start()
    -- Mirror DecryptSkillDrive: set action anim and play USB sound
    pcall(function() self:setActionAnim('Loot') end)
    pcall(function() self:setAnimVariable('LootPosition', 'Medium') end)
    if self.character and self.character.getEmitter then
        pcall(function()
            if self.character:getEmitter() then
                self.sound = self.character:getEmitter():playSound('USBSys')
            end
        end)
    end
end

function UseEliteDrive:stop()
    ISBaseTimedAction.stop(self)
    if self.sound and self.character and self.character.getEmitter then
        pcall(function()
            if self.character:getEmitter() then
                self.character:getEmitter():stopSound(self.sound)
            end
        end)
        self.sound = nil
    end
end

function UseEliteDrive:update()
    -- Face the laptop/world object if possible
    if self.worldObj and self.worldObj.getX and self.character and self.character.faceThisObject then
        pcall(function() self.character:faceThisObject(self.worldObj) end)
    end
end

function UseEliteDrive:perform()
    -- Attempt to send a client command to server to apply the elite drive
    local playerIndex = (self.character and self.character.getPlayerNum and self.character:getPlayerNum()) or 0
    local payload = { driveType = self.driveType, playerIndex = playerIndex }
    local sent = false
    if sendClientCommand then
        pcall(function() sendClientCommand('DecryptSkillSys', 'UseEliteDrive', payload) end)
        sent = true
    elseif sendServerCommand then
        pcall(function() sendServerCommand('DecryptSkillSys', 'UseEliteDrive', payload) end)
        sent = true
    end

    if not sent then
        -- Singleplayer / fallback: try to apply directly server-side APIs
        if EliteDriveSystem and EliteDriveSystem.useEliteDrive then
            pcall(function()
                local ok = EliteDriveSystem.useEliteDrive(self.character, self.driveType)
                if ok and self.character.getInventory then
                    local inv = self.character:getInventory()
                    local fullname = 'GValley.EliteDrive_' .. self.driveType
                    local cnt = inv:getItemCount(fullname)
                    if cnt and cnt >= 2 then
                        inv:RemoveOneOf(fullname)
                        inv:RemoveOneOf(fullname)
                    elseif cnt and cnt == 1 then
                        inv:RemoveOneOf(fullname)
                    end
                end
            end)
        end
    end

    if self.sound and self.character and self.character.getEmitter then
        pcall(function()
            if self.character:getEmitter() then
                self.character:getEmitter():stopSound(self.sound)
            end
        end)
        self.sound = nil
    end
    ISBaseTimedAction.perform(self)
end

pcall(require, "shared/GVDrive_Config")
local function debugPrint(...)
    if type(GVDrive_Config) == 'table' and GVDrive_Config.getDebug and GVDrive_Config.getDebug() then
        print("[DecryptSkillSys][DEBUG]", ...)
    end
end

debugPrint('UseEliteDrive timed action loaded')
