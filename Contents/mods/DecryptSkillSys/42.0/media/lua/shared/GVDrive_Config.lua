-- Central config for DecryptSkillSys (small, safe)
GVDrive_Config = GVDrive_Config or {}

-- Default: false for production
GVDrive_Config.DEBUG = false

function GVDrive_Config.getDebug()
    return GVDrive_Config.DEBUG
end

return GVDrive_Config
