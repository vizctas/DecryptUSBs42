-- Central config for DecryptSkillSys (small, safe)
GVDrive_Config = GVDrive_Config or {}

-- Default: true for debugging loot issues
GVDrive_Config.DEBUG = true

function GVDrive_Config.getDebug()
    return GVDrive_Config.DEBUG
end

return GVDrive_Config
