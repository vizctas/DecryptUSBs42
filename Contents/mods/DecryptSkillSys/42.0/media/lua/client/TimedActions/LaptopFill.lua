-- Import required modules
require "TimedActions/ISBaseTimedAction"
require "client/TimedActions/ISUsbSys"
require "client/TimedActions/ISFloppySys"

-- Import for context menus and submenus
pcall(require, "ISUI/ISContextMenu")

local DecryptSkillDrive = require "client/TimedActions/DecryptSkillDrive"
require "shared/LaptopSystem"
require "shared/GVDrive_Utils"
require "shared/EliteDriveSystem"

pcall(require, "shared/GVDrive_Config")
local function debugPrint(...)
    if type(GVDrive_Config) == 'table' and GVDrive_Config.getDebug and GVDrive_Config.getDebug() then
        print("[DecryptSkillSys][DEBUG]", ...)
    end
end

debugPrint("LaptopFill.lua starting to load...")

-- Function to get random fun messages for USB decryption by skill type
local function getRandomUSBMessage(skillName, rarity)
    local messages = {
        -- Combat Skills
        Axe = {
            "The primal fury of the axe awakens within you!",
            "You feel the weight of Viking rage in your swings!",
            "The USB channels the spirit of ancient warriors!",
            "Your axe thirsts for battle with newfound hunger!",
            "Berserker techniques flood your warrior's soul!",
            "The art of the perfect cleave becomes instinct!",
            "You've unlocked the savage wisdom of axe masters!",
            "The USB forges your spirit in digital fire!",
            "Your axe arm grows strong with ancient knowledge!",
            "The ghosts of legendary lumberjacks guide your blade!"
        },
        LongBlade = {
            "The way of the sword flows through your consciousness!",
            "Samurai techniques download into your muscle memory!",
            "You feel the steel singing with deadly precision!",
            "Ancient swordmasters whisper their secrets to you!",
            "The blade becomes an extension of your soul!",
            "Katana wisdom cuts through your ignorance!",
            "You've mastered the art of the perfect strike!",
            "The USB sharpens your mind like a whetstone!",
            "Legendary blade techniques are now yours!",
            "The spirit of the sword awakens within you!"
        },
        ShortBlade = {
            "Quick, deadly strikes become second nature!",
            "The art of close combat flows through you!",
            "Knife-fighting mastery floods your reflexes!",
            "You learn to dance with danger and sharp steel!",
            "Silent takedowns become your specialty!",
            "The USB teaches you the language of blades!",
            "Precision cuts through the fog of ignorance!",
            "Your hands remember a thousand swift strikes!",
            "The way of the dagger illuminates your path!",
            "Short blades whisper deadly secrets to you!"
        },
        LongBlunt = {
            "Heavy impacts resonate through your understanding!",
            "The crushing power of blunt force awakens!",
            "You feel the weight of destruction in your hands!",
            "Sledgehammer techniques thunder through your mind!",
            "The art of overwhelming force becomes clear!",
            "Your strikes gain the power of earthquakes!",
            "The USB crushes doubt with pure knowledge!",
            "Blunt trauma expertise flows through you!",
            "You've learned to break more than just bones!",
            "The spirit of destruction guides your swings!"
        },
        ShortBlunt = {
            "Quick crushing blows become your trademark!",
            "The art of compact destruction fills your mind!",
            "Baseball bat mastery courses through your veins!",
            "You learn to make every swing count!",
            "Close-quarters combat wisdom downloads instantly!",
            "The USB teaches you efficient violence!",
            "Your reflexes sharpen to deadly precision!",
            "Compact weapons reveal their hidden potential!",
            "You've mastered the art of swift brutality!",
            "Quick strikes echo with newfound power!"
        },
        Spear = {
            "The ancient art of the spear pierces your consciousness!",
            "You feel the reach of warriors across millennia!",
            "Phalanx formations dance in your mind!",
            "The USB extends your combat range infinitely!",
            "Thrust and parry become as natural as breathing!",
            "You've learned to keep death at spear's length!",
            "The spirit of ancient hunters guides your aim!",
            "Spearmanship mastery flows through your being!",
            "You feel the power of distance and precision!",
            "The USB teaches you to strike from afar!"
        },
        Maintenance = {
            "The secrets of preservation flood your mind!",
            "You understand the art of keeping things alive!",
            "Repair techniques download into your consciousness!",
            "The USB restores your knowledge of restoration!",
            "Maintenance mastery courses through your circuits!",
            "You've learned to breathe life back into the broken!",
            "The art of perpetual motion becomes clear!",
            "Your hands remember how to heal machines!",
            "Entropy bows before your newfound wisdom!",
            "The USB teaches you to fight decay itself!"
        },
        Aiming = {
            "Your crosshairs align with deadly precision!",
            "The USB downloads years of sniper training instantly!",
            "You feel your hand steady with newfound accuracy!",
            "Bullseye! The secrets of perfect aim are yours!",
            "Your targeting instincts sharpen to a razor's edge!",
            "The art of the perfect shot becomes second nature!",
            "Marksmanship mastery floods your muscle memory!",
            "You've acquired the eye of a legendary sharpshooter!",
            "The USB calibrates your brain for pinpoint accuracy!",
            "Silent death becomes your new specialty!"
        },
        Reloading = {
            "Lightning-fast reloads become muscle memory!",
            "Your fingers dance with magazine mastery!",
            "The USB teaches you the rhythm of combat!",
            "Ammunition flows through your hands like water!",
            "You've mastered the art of seamless warfare!",
            "Reload speeds that defy human limitations!",
            "The spirit of continuous fire flows through you!",
            "Your hands remember every gun ever made!",
            "The USB eliminates the gap between shots!",
            "Magazines become extensions of your will!"
        },
        
        -- Crafting Skills
        Woodwork = {
            "You crack open the carpenter's secrets hidden in this USB drive!",
            "The wisdom of master woodworkers flows into your mind...",
            "Ancient building techniques reveal themselves to you!",
            "You discover the lost art of precision woodworking!",
            "The USB contains blueprints that would make any carpenter jealous!",
            "Your mind absorbs decades of craftsmanship experience!",
            "The digital ghost of a master builder guides your hands!",
            "You unlock the mysteries of wood grain and joint perfection!",
            "A carpenter's lifetime of knowledge downloads into your brain!",
            "The USB whispers the secrets of flawless construction!"
        },
        Cooking = {
            "Culinary magic bubbles up from the depths of this USB!",
            "The flavors of a thousand recipes dance on your tongue!",
            "You taste the knowledge of master chefs across the ages!",
            "The USB seasoned your mind with gourmet wisdom!",
            "Kitchen secrets that would make Gordon Ramsay weep!",
            "You've unlocked the cookbook of the gods!",
            "Delicious techniques simmer in your consciousness!",
            "The USB serves up a feast of culinary knowledge!",
            "You're now cooking with the fire of true expertise!",
            "The digital ghost of Julia Child guides your hands!"
        },
        Farming = {
            "The earth's ancient secrets sprout in your mind!",
            "You feel connected to the soil and seasons like never before!",
            "Agricultural wisdom takes root in your consciousness!",
            "The USB plants seeds of knowledge that will grow forever!",
            "You harvest a bounty of farming techniques!",
            "The green thumb digitally transfers to your hands!",
            "Mother Nature's cookbook downloads into your brain!",
            "You cultivate an understanding that spans generations!",
            "The USB fertilizes your mind with growing expertise!",
            "Ancient farming spirits whisper their secrets to you!"
        },
        Doctor = {
            "Medical knowledge flows through you like healing energy!",
            "The Hippocratic Oath echoes in your digital consciousness!",
            "You've absorbed the wisdom of battlefield medics!",
            "The USB diagnoses your brain with pure expertise!",
            "Healing hands are born from digital knowledge!",
            "The secrets of life and death dance in your mind!",
            "You feel the pulse of medical mastery in your veins!",
            "The USB performs surgery on your ignorance!",
            "Ancient healing arts merge with modern medicine!",
            "The digital ghosts of great doctors guide your hands!"
        },
        Electricity = {
            "Electrical circuits dance before your eyes as knowledge surges through you!",
            "You feel the power of electricity coursing through your understanding!",
            "The mysteries of voltage and current become crystal clear!",
            "Lightning-fast insights spark in your mind!",
            "You've tapped into the grid of electrical wisdom!",
            "Shocking revelations about wiring fill your consciousness!",
            "The USB electrifies your brain with technical knowledge!",
            "Amperes of experience flow through your neural pathways!",
            "You're now wired for electrical excellence!",
            "The digital spirits of Tesla himself guide your learning!"
        },
        MetalWelding = {
            "Molten metal mastery flows through your consciousness!",
            "The art of joining steel becomes second nature!",
            "You feel the heat of a thousand forges in your mind!",
            "Welding techniques fuse with your understanding!",
            "The USB melts away your metallurgical ignorance!",
            "Sparks of genius ignite in your neural pathways!",
            "You've unlocked the secrets of molecular bonding!",
            "The spirit of master blacksmiths guides your torch!",
            "Metal bends to your newly awakened will!",
            "The USB forges you into a welding warrior!"
        },
        Mechanics = {
            "Engine knowledge roars to life in your mind!",
            "Mechanical mastery flows through your consciousness!",
            "You hear the heartbeat of every machine!",
            "The USB tunes your brain to perfect pitch!",
            "Automotive wisdom accelerates through your thoughts!",
            "You've become one with the spirit of the machine!",
            "Gears and pistons dance in digital harmony!",
            "The secrets of mechanical motion are revealed!",
            "Your hands remember every engine ever built!",
            "The USB shifts your understanding into overdrive!"
        },
        Tailoring = {
            "The art of perfect stitching flows through your fingers!",
            "Fabric secrets weave themselves into your mind!",
            "You feel the texture of a thousand textiles!",
            "The USB threads knowledge through your consciousness!",
            "Sewing mastery patterns itself in your brain!",
            "You've unlocked the couture codes of the masters!",
            "The needle becomes an extension of your soul!",
            "Fashion wisdom drapes itself around your thoughts!",
            "You can now tailor reality to your specifications!",
            "The digital spirits of great designers inspire you!"
        },
        
        -- Survivalist Skills
        Fishing = {
            "The ancient art of angling flows through your mind!",
            "You feel the pulse of every fish in the water!",
            "The USB hooks you up with aquatic wisdom!",
            "Fishing secrets surface from the digital depths!",
            "You've learned to think like the fish you seek!",
            "The art of patience becomes your greatest weapon!",
            "Water whispers its fishy secrets to you!",
            "You cast your line into the sea of knowledge!",
            "The USB reels in decades of fishing experience!",
            "You've become one with the rhythm of the tides!"
        },
        Trapping = {
            "The hunter's instincts awaken within your soul!",
            "You learn to think like both predator and prey!",
            "Trapping wisdom snares your consciousness!",
            "The USB sets the perfect knowledge trap for you!",
            "You've mastered the art of invisible capture!",
            "The forest reveals its hidden hunting secrets!",
            "Survival cunning flows through your neural pathways!",
            "You become the apex trapper of the digital age!",
            "The USB teaches you to catch what cannot be seen!",
            "Ancient hunting spirits guide your clever hands!"
        },
        PlantScavenging = {
            "Botanical wisdom blooms in your consciousness!",
            "You learn to read the green language of nature!",
            "The USB cultivates your foraging instincts!",
            "Edible secrets reveal themselves in every leaf!",
            "You've unlocked nature's hidden pantry!",
            "The forest becomes your personal grocery store!",
            "Plant knowledge photosynthesizes in your mind!",
            "You can now hear the whispers of edible flora!",
            "The USB roots you in ancient gathering wisdom!",
            "Every plant becomes a potential ally or resource!"
        },
        Survivalist = {
            "The wild calls to you with newfound understanding!",
            "Survival instincts sharpen to a primal edge!",
            "You taste the knowledge of those who endured!",
            "The USB teaches you to thrive where others perish!",
            "Wilderness wisdom flows through your survival circuits!",
            "You've unlocked the secrets of ultimate adaptation!",
            "The art of staying alive becomes second nature!",
            "Your survival skills evolve beyond human limits!",
            "The USB transforms you into the apex survivor!",
            "The spirits of legendary survivors whisper their secrets!"
        },
        
        -- Fitness Skills
        Fitness = {
            "Your muscles scream with the joy of newfound strength!",
            "The USB pumps iron directly into your neural pathways!",
            "You feel the burn of a thousand workouts instantly!",
            "Athletic excellence surges through every fiber!",
            "The secrets of peak physical performance are yours!",
            "Your body remembers exercises you've never done!",
            "The USB downloads decades of training experience!",
            "You feel like you could benchpress a car!",
            "Physical mastery floods your muscle memory!",
            "The digital spirits of Olympic champions inspire you!"
        },
        Strength = {
            "Raw power courses through your digital veins!",
            "You feel the might of titans in your muscles!",
            "The USB upgrades your physical strength protocols!",
            "Hercules himself would be proud of your gains!",
            "Your strength multiplies beyond mortal limits!",
            "The art of applied force becomes instinctual!",
            "You've unlocked the genetic codes of power!",
            "The USB overclocks your muscular potential!",
            "Strength beyond measure flows through you!",
            "You feel capable of moving mountains!"
        },
        Sprinting = {
            "Lightning speed electrifies your leg muscles!",
            "You feel the wind spirit enter your stride!",
            "The USB downloads the DNA of cheetahs!",
            "Your feet barely touch the ground anymore!",
            "Speed beyond human limits becomes your reality!",
            "The art of velocity flows through your being!",
            "You've become the embodiment of pure motion!",
            "The USB accelerates your life force!",
            "You could outrun your own shadow now!",
            "The speed force acknowledges you as kin!"
        },
        Lightfoot = {
            "You learn to move like smoke on the wind!",
            "The art of silent motion becomes second nature!",
            "Your footsteps vanish into digital ether!",
            "The USB teaches you to dance with gravity!",
            "You've mastered the technique of weightless walking!",
            "Sound itself forgets you exist when you move!",
            "The spirits of cat burglars guide your steps!",
            "You become one with the silence between sounds!",
            "The USB makes you lighter than thought itself!",
            "You could walk on water and leave no ripples!"
        },
        Nimble = {
            "Agility beyond imagination flows through you!",
            "You feel like liquid mercury in motion!",
            "The USB upgrades your flexibility protocols!",
            "Your body remembers every acrobatic move ever performed!",
            "You've become poetry in motion, grace personified!",
            "The art of fluid movement becomes your signature!",
            "You could dodge raindrops if you wanted to!",
            "The USB downloads the essence of wind itself!",
            "Flexibility and grace merge in perfect harmony!",
            "You move like a river finding its way to the sea!"
        },
        Sneak = {
            "You melt into the shadows with newfound grace...",
            "The art of invisibility becomes your second skin!",
            "Silent footsteps echo the wisdom of master thieves!",
            "You've learned to move like smoke in the wind!",
            "The USB teaches you to dance with darkness!",
            "Stealth techniques flow through you like liquid shadow!",
            "You become one with the night and silence!",
            "The secrets of legendary assassins are now yours!",
            "Your presence becomes as light as a whisper!",
            "The USB transforms you into a ghost among the living!"
        }
    }
    
    local skillMessages = messages[skillName] or {
        "You absorb mysterious knowledge from the digital depths!",
        "The USB reveals its secrets to your eager mind!",
        "Unknown wisdom floods your consciousness!",
        "You feel smarter already!",
        "The data transforms you in ways you can't explain!",
        "Digital enlightenment courses through your neural pathways!",
        "You've tapped into something extraordinary!",
        "The USB downloads directly into your soul!",
        "Knowledge beyond comprehension fills your being!",
        "You feel the power of learning itself!"
    }
    
    local selectedMessage = skillMessages[ZombRand(#skillMessages) + 1]
    
    -- Add rarity flavor
    if rarity == "Dificil" then
        selectedMessage = "★★★ " .. selectedMessage .. " This was ELITE knowledge!"
    elseif rarity == "Moderado" then
        selectedMessage = "★★ " .. selectedMessage
    else
        selectedMessage = "★ " .. selectedMessage
    end
    
    return selectedMessage
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

local function ensureDecryptSkillDrive()
    if DecryptSkillDrive and type(DecryptSkillDrive.new) == "function" then
        return DecryptSkillDrive
    end

    local moduleNames = {
        "client/TimedActions/DecryptSkillDrive",
        "TimedActions/DecryptSkillDrive"
    }

    for _, name in ipairs(moduleNames) do
        local ok, module = pcall(require, name)
        if ok and module and type(module.new) == "function" then
            DecryptSkillDrive = module
            return DecryptSkillDrive
        end
    end

    if _G.DecryptSkillDrive and type(_G.DecryptSkillDrive.new) == "function" then
        DecryptSkillDrive = _G.DecryptSkillDrive
        return DecryptSkillDrive
    end

    return nil
end

local function getDriveInfoSafe(item)
    if not item then return nil end
    if GVDrive_Utils and GVDrive_Utils.getDriveInfo then
        local ok, info = pcall(GVDrive_Utils.getDriveInfo, item)
        if ok and info then return info end
    end
    return nil
end

local rarityFallback = {
    Facil = { en = "Easy", es = "Facil" },
    Moderado = { en = "Moderate", es = "Moderado" },
    Dificil = { en = "Hard", es = "Dificil" }
}

local function buildDriveDisplayName(isUSB, skillName, rarity)
    if not skillName then skillName = "Unknown" end
    if not rarity then rarity = "Unknown" end

    local baseKey = isUSB and "DisplayName_SkillDrive_" or "DisplayName_SkillFloppy_"
    local translationKey = baseKey .. skillName .. "_" .. rarity
    local label = getText and getText(translationKey) or translationKey
    if label == translationKey then
        local rarityLabel = rarityFallback[rarity]
        if rarityLabel then
            local language = "EN"
            if getCore and getCore() and getCore().getOptionLanguage then
                local ok, lang = pcall(function() return getCore():getOptionLanguage() end)
                if ok and lang then language = lang end
            end
            if language == "ES" then
                rarity = rarityLabel.es
            else
                rarity = rarityLabel.en
            end
        end
        label = string.format("%s (%s)", skillName, rarity)
    end
    return label
end

local function queueDecryptActions(player, worldObj, drives)
    if not drives or #drives == 0 then return end

    -- Validate laptop health before queuing actions
    local laptopItem = worldObj
    if laptopItem and laptopItem.getItem then
        local ok, inner = pcall(function() return laptopItem:getItem() end)
        if ok and inner then laptopItem = inner end
    end

    if LaptopSystem and laptopItem then
        local health = LaptopSystem.getLaptopHealth(laptopItem)
        if health <= 0 then
            player:Say(getTranslatedMessage("GVDrive_Msg_Laptop_Broken", "This laptop doesn't work... I should find a way to repair it."))
            return
        end
    end

    local class = ensureDecryptSkillDrive()
    if not class then
        player:Say(getTranslatedMessage("GVDrive_Msg_Decrypt_Action_Failed", "Cannot start decrypt action right now."))
        return
    end

    for _, drive in ipairs(drives) do
        ISTimedActionQueue.add(class:new(player, worldObj, drive, 500))
    end
end

local function groupDrivesByInfo(driveList, isUSB)
    local groups = {}

    for _, drive in ipairs(driveList) do
        local info = getDriveInfoSafe(drive)
        local skill = (info and info.skillName) or "Unknown"
        local rarity = (info and info.rarity) or "Unknown"
        local key = skill .. "|" .. rarity

        if not groups[key] then
            groups[key] = {
                drives = {},
                skill = skill,
                rarity = rarity,
                isUSB = isUSB
            }
        end

        table.insert(groups[key].drives, drive)
    end

    local ordered = {}
    for key, data in pairs(groups) do
        data.sortKey = key
        table.insert(ordered, data)
    end
    table.sort(ordered, function(a, b) return a.sortKey < b.sortKey end)

    return ordered
end

-- Lists of allowed laptops
LaptopList = {
    "GValley.AsusZephLaptopOpened",
    "GValley.AsusZephLaptopClosed",
    "GValley.Laptop90sOpened",
    "GValley.Laptop90sClosed",
    "GValley.IBM_LP90Opened",
    "GValley.PBIBM_LP90Closed",
}

LaptopUSBAllowed = {
    "GValley.AsusZephLaptopOpened",
    "GValley.AsusZephLaptopClosed",
}

LaptopFloppyAllowed = {
    "GValley.Laptop90sOpened",
    "GValley.Laptop90sClosed",
    "GValley.IBM_LP90Opened",
    "GValley.PBIBM_LP90Closed",
}

-- ============================================================================
-- LAPTOP FILL - SIMPLIFIED BACKUP SYSTEM
-- ============================================================================
-- This file now serves as a backup system in case the modern DecryptDrivesContextMenu fails
-- All main functionality has been moved to DecryptDrivesContextMenu.lua

-- Main context menu function - SIMPLIFIED BACKUP
function LaptopOnFillWorldObjectContextMenu(player, context, worldobjects, test)
    if not player or not context or not worldobjects then return end

    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end

    debugPrint("LaptopFill: Backup system activated - modern menu may have failed")

    -- Simplified laptop detection
    for _, worldObject in ipairs(worldobjects) do
        if not worldObject or not worldObject.getItem then
            -- Skip this object and continue with next
        else
            local item = worldObject:getItem()
            if not item or not item.getFullType then
                -- Skip this object and continue with next
            else
                local itemType = item:getFullType()

                -- Enhanced laptop detection for all laptop types
                if string.find(itemType, "Laptop") or string.find(itemType, "AsusZeph") or string.find(itemType, "IBM_LP90") or string.find(itemType, "PBIBM_LP90") then
                    debugPrint("LaptopFill: Backup system found laptop: " .. itemType)

                    -- Get laptop health
                    local laptopItem = worldObject:getItem()
                    local laptopHealth = 0
                    if laptopItem and LaptopSystem then
                        laptopHealth = LaptopSystem.getLaptopHealth(laptopItem)
                    end

                    -- Check if laptop can be used for decryption
                    if laptopHealth <= 0 then
                        local brokenOption = context:addOption("Drives Available - LAPTOP BROKEN", playerObj, function()
                            playerObj:Say("This laptop is completely broken and cannot decrypt anything. Use antivirus to repair it.")
                        end)
                        brokenOption.notAvailable = true
                    else
                        -- Check if modern menu system is already active
                        local modernMenuActive = context._DecryptDrives_ModernMenu or false

                        if not modernMenuActive then
                            -- Simple USB check
                            local inv = playerObj:getInventory()
                            local totalUSBCount = 0

                            if inv then
                                local items = inv:getItems()
                                for i = 0, items:size() - 1 do
                                    local invItem = items:get(i)
                                    if invItem and invItem.getFullType and string.find(invItem:getFullType(), "SkillDrive_") then
                                        totalUSBCount = totalUSBCount + 1
                                    end
                                end
                            end

                            if totalUSBCount > 0 then
                                local drivesOption = context:addOption("Drives Available (BACKUP: " .. totalUSBCount .. ")", playerObj, function()
                                    playerObj:Say("Backup system: Please use the modern menu system for full functionality.")
                                end)
                                drivesOption.notAvailable = true
                            else
                                local noUSBOption = context:addOption("No USB drives found (BACKUP)", playerObj, function() end)
                                noUSBOption.notAvailable = true
                            end

                            debugPrint("LaptopFill: Backup menu options added (modern menu not detected)")
                        else
                            debugPrint("LaptopFill: Modern menu detected, skipping backup options")
                        end
                    end

                    debugPrint("LaptopFill: Menu processing completed")
                    break -- Only add menu once per laptop found
                end
            end
        end
    end
end

-- Register the backup context menu event
debugPrint("LaptopFill: Registering backup context menu event...")
Events.OnFillWorldObjectContextMenu.Add(LaptopOnFillWorldObjectContextMenu)
debugPrint("LaptopFill: Backup context menu event registered successfully")

debugPrint("LaptopFill: Backup system loaded - modern menu should take precedence")
