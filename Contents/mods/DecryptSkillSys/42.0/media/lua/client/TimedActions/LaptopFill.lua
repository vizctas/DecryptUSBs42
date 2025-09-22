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

-- Main context menu function
function LaptopOnFillWorldObjectContextMenu(player, context, worldobjects, test)
    if not player or not context or not worldobjects then return end
    
    local playerObj = getSpecificPlayer(player)
    if not playerObj then return end
    
    -- Simplified laptop detection
    debugPrint("Context menu checking " .. #worldobjects .. " objects")

    -- Check each world object for laptops
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
            debugPrint("Found laptop: " .. itemType)
            
            -- Add laptop health status at top with improved visual representation
            -- Get and display real laptop health
            local laptopHealth = 100 -- Default fallback
            if LaptopSystem and LaptopSystem.getLaptopHealth then
                laptopHealth = LaptopSystem.getLaptopHealth(item)
            end
            
            -- Create visual health bar (10 characters) - using simple characters
            local barLength = 10
            local filledBars = math.floor((laptopHealth / 100) * barLength)
            local emptyBars = barLength - filledBars
            local healthBar = string.rep("|", filledBars) .. string.rep(".", emptyBars)
            
            -- Color based on health percentage
            local healthColor = ""
            local healthStatus = ""
            
            if laptopHealth >= 80 then
                healthColor = " <RGB:0,1,0> " -- Green
                healthStatus = "Excellent"
            elseif laptopHealth >= 60 then
                healthColor = " <RGB:1,1,0> " -- Yellow  
                healthStatus = "Good"
            elseif laptopHealth >= 40 then
                healthColor = " <RGB:1,0.5,0> " -- Orange
                healthStatus = "Fair"
            elseif laptopHealth >= 20 then
                healthColor = " <RGB:1,0,0> " -- Red
                healthStatus = "Poor"
            else
                healthColor = " <RGB:0.5,0,0> " -- Dark Red
                healthStatus = "Critical"
            end
            
            -- Display format: Health: [████████░░] 75% (Good) - SIN formato RGB en opciones del menú
            local healthDisplay = "Health: [" .. healthBar .. "] " .. laptopHealth .. "% (" .. healthStatus .. ")"
            
            context:addOptionOnTop(healthDisplay, playerObj, function() 
                local messages = {
                    "The laptop hums softly, displaying its current condition.",
                    "You examine the laptop's status indicators carefully.",
                    "The screen flickers slightly as you check the system diagnostics.",
                    "You run a quick hardware diagnostic on the laptop.",
                    "The laptop responds to your touch, showing its current state."
                }
                
                if laptopHealth <= 0 then
                    playerObj:Say("This laptop is completely dead. It's nothing more than expensive paperweight now.")
                elseif laptopHealth < 20 then
                    playerObj:Say("This laptop is barely hanging on. One wrong move and it'll be toast.")
                elseif laptopHealth < 40 then
                    playerObj:Say("This laptop has seen better days. Some TLC with antivirus might help.")
                elseif laptopHealth < 60 then
                    playerObj:Say("This laptop is holding up okay, but could use some maintenance.")
                elseif laptopHealth < 80 then
                    playerObj:Say("This laptop is in good shape and should serve you well.")
                else
                    local randomMsg = messages[ZombRand(#messages) + 1]
                    playerObj:Say(randomMsg)
                end
            end)
            
            -- Check for USB drives and organize by type
            local inv = playerObj:getInventory()
            if inv then
                -- Collect and organize USB drives by skill type
                local usbBySkill = {}
                local totalUSBCount = 0
                local items = inv:getItems()
                
                for i = 0, items:size() - 1 do
                    local invItem = items:get(i)
                    if invItem and invItem.getFullType then
                        local fullType = invItem:getFullType()
                        if string.find(fullType, "SkillDrive_") then
                            totalUSBCount = totalUSBCount + 1
                            
                            -- Extract skill name from item type (e.g. "SkillDrive_Carpinteria_Facil")
                            local skillName = "Unknown"
                            local itemName = invItem:getDisplayName() or fullType
                            
                            -- Try to extract skill from display name or type
                            if string.find(itemName, "Carpinteria") or string.find(fullType, "Carpinteria") then
                                skillName = "Carpentry"
                            elseif string.find(itemName, "Electricidad") or string.find(fullType, "Electricidad") then
                                skillName = "Electrical"
                            elseif string.find(itemName, "Mecanica") or string.find(fullType, "Mecanica") then
                                skillName = "Mechanics"
                            elseif string.find(itemName, "Medicina") or string.find(fullType, "Medicina") then
                                skillName = "FirstAid"
                            elseif string.find(itemName, "Cocina") or string.find(fullType, "Cocina") then
                                skillName = "Cooking"
                            elseif string.find(itemName, "Metalurgia") or string.find(fullType, "Metalurgia") then
                                skillName = "MetalWelding"
                            elseif string.find(itemName, "Sastre") or string.find(fullType, "Sastre") then
                                skillName = "Tailoring"
                            elseif string.find(itemName, "Punteria") or string.find(fullType, "Punteria") then
                                skillName = "Aiming"
                            elseif string.find(itemName, "Farmacia") or string.find(fullType, "Farmacia") then
                                skillName = "Pharmacy"
                            else
                                -- Try to extract from the type pattern
                                local extracted = string.match(fullType, "SkillDrive_([^_]+)")
                                if extracted then
                                    skillName = extracted
                                end
                            end
                            
                            if not usbBySkill[skillName] then
                                usbBySkill[skillName] = {}
                            end
                            table.insert(usbBySkill[skillName], invItem)
                        end
                    end
                end
                
                if totalUSBCount > 0 then
                    -- Check if modern menu system is available and working
                    local modernMenuActive = false
                    local modernMenuError = nil

                    -- Try to check if modern menu is loaded
                    if type(_G) == 'table' and _G.DecryptDrivesContextMenu_MODERN then
                        modernMenuActive = true
                        debugPrint("LaptopFill: Modern menu detected via global flag")
                    else
                        local ok, mod = pcall(function() return require "client/DecryptDrivesContextMenu" end)
                        if ok and type(mod) == 'table' and mod.MODERN_MENU_ACTIVE then
                            modernMenuActive = true
                            debugPrint("LaptopFill: Modern menu detected via require")
                        elseif not ok then
                            modernMenuError = mod
                            debugPrint("LaptopFill: Modern menu require failed: " .. tostring(mod))
                        else
                            debugPrint("LaptopFill: Modern menu module loaded but MODERN_MENU_ACTIVE is " .. tostring(mod and mod.MODERN_MENU_ACTIVE or "nil"))
                        end
                    end

                    debugPrint("LaptopFill: modernMenuActive = " .. tostring(modernMenuActive))
                    debugPrint("LaptopFill: context._DecryptDrives_ModernMenu = " .. tostring(context and context._DecryptDrives_ModernMenu or "nil"))

                    -- If modern menu is active, try to call it directly instead of relying on event order
                    if modernMenuActive then
                        debugPrint("LaptopFill: Attempting to call modern menu directly")
                        local ok, result = pcall(function()
                            local modernMenu = require "DecryptDrivesContextMenu"
                            if modernMenu and modernMenu.addContextMenuOption then
                                modernMenu.addContextMenuOption(playerObj, context, worldobjects, test)
                                debugPrint("LaptopFill: Modern menu called successfully")
                                return true
                            end
                            return false
                        end)
                        
                        if ok and result then
                            debugPrint("LaptopFill: Modern menu executed successfully - skipping legacy menu")
                            return
                        else
                            debugPrint("LaptopFill: Modern menu call failed: " .. tostring(result) .. " - falling back to legacy")
                        end
                    end

                    -- Fallback to legacy menu if modern menu failed
                    debugPrint("LaptopFill: Using legacy menu implementation")
                    -- Check if laptop can be used for decryption
                    if laptopHealth <= 0 then
                        local brokenOption = context:addOption("Drives Available (" .. totalUSBCount .. ") - LAPTOP BROKEN", playerObj, function()
                            playerObj:Say("This laptop is completely broken and cannot decrypt anything. Use antivirus to repair it.")
                        end)
                        brokenOption.notAvailable = true
                    elseif laptopHealth < 10 then
                        local riskOption = context:addOption("Drives Available (" .. totalUSBCount .. ") - HIGH RISK", playerObj, function() end)
                        local riskSubMenu = ISContextMenu:getNew(context)
                        context:addSubMenu(riskOption, riskSubMenu)
                        
                        -- Add warning at top of submenu
                        local warningOpt = riskSubMenu:addOption("WARNING: CRITICAL LAPTOP - HIGH RISK", playerObj, function()
                            playerObj:Say("Warning: This laptop is in critical condition. Decryption may fail or damage the laptop further.")
                        end)
                        warningOpt.notAvailable = true
                        riskSubMenu:addOption("---------", playerObj, function() end).notAvailable = true
                        
                        -- Add skill-based options
                        for skillName, driveList in pairs(usbBySkill) do
                            riskSubMenu:addOption("USB " .. skillName .. " (" .. #driveList .. ")", playerObj, function()
                                playerObj:Say("WARNING: High risk decryption of " .. skillName .. " drives...")
                                queueDecryptActions(playerObj, worldObject, driveList)
                            end)
                        end
                    else
                        -- Normal operation - create submenu
                        local drivesOption = context:addOption("Drives Available (" .. totalUSBCount .. ")", playerObj, function() end)
                        local subMenu = ISContextMenu:getNew(context)
                        context:addSubMenu(drivesOption, subMenu)
                        
                        -- Add "Decrypt All" option at top
                        if totalUSBCount > 1 then
                            local allDrives = {}
                            for _, driveList in pairs(usbBySkill) do
                                for _, drive in ipairs(driveList) do
                                    table.insert(allDrives, drive)
                                end
                            end
                            subMenu:addOption("= Decrypt All (" .. totalUSBCount .. ")", playerObj, function()
                                queueDecryptActions(playerObj, worldObject, allDrives)
                            end)
                            subMenu:addOption("---------", playerObj, function() end).notAvailable = true
                        end
                        
                        -- Add skill-based options
                        for skillName, driveList in pairs(usbBySkill) do
                            subMenu:addOption("USB " .. skillName .. " (" .. #driveList .. ")", playerObj, function()
                                queueDecryptActions(playerObj, worldObject, driveList)
                            end)
                        end
                    end
                else
                    local noUSBOption = context:addOption("No USB drives found", playerObj, function() end)
                    noUSBOption.notAvailable = true
                end
                
                -- Check for antivirus (both old and new item names)
                local antivirusCount = inv:getItemCount("GValley.AntivirusDisk_Basic") + 
                                       inv:getItemCount("GValley.AntivirusDisk_Advanced") + 
                                       inv:getItemCount("GValley.AntivirusDisk_Premium") +
                                       inv:getItemCount("GValley.Antivirus_Norton") +
                                       inv:getItemCount("GValley.Antivirus_Kaspersky") +
                                       inv:getItemCount("GValley.Antivirus_McAfee") +
                                       inv:getItemCount("GValley.Antivirus_MalwareBytes")
                
                if antivirusCount > 0 then
                    -- Create antivirus submenu
                    local antivirusOption = context:addOption("Use Antivirus (" .. antivirusCount .. ")", playerObj, function() end)
                    local antivirusSubMenu = ISContextMenu:getNew(context)
                    context:addSubMenu(antivirusOption, antivirusSubMenu)
                    
                    -- Check each antivirus type and add to submenu
                    local antivirusTypes = {
                        {id = "GValley.Antivirus_MalwareBytes", name = "MalwareBytes", heal = 12},
                        {id = "GValley.Antivirus_McAfee", name = "McAfee", heal = 10},
                        {id = "GValley.Antivirus_Kaspersky", name = "Kaspersky", heal = 8},
                        {id = "GValley.Antivirus_Norton", name = "Norton", heal = 5},
                        {id = "GValley.AntivirusDisk_Premium", name = "Premium", heal = 75},
                        {id = "GValley.AntivirusDisk_Advanced", name = "Advanced", heal = 50},
                        {id = "GValley.AntivirusDisk_Basic", name = "Basic", heal = 25}
                    }
                    
                    for _, avType in ipairs(antivirusTypes) do
                        local count = inv:getItemCount(avType.id)
                        if count > 0 then
                            antivirusSubMenu:addOption(avType.name .. " (" .. count .. ") - Heal +" .. avType.heal .. "%", playerObj, function()
                                -- Find and use this specific antivirus type
                                local antivirusItem = nil
                                
                                -- Try multiple methods to find the item
                                local items = inv:getItems()
                                for i = 0, items:size() - 1 do
                                    local checkItem = items:get(i)
                                    if checkItem and checkItem:getFullType() == avType.id then
                                        antivirusItem = checkItem
                                        break
                                    end
                                end
                                
                                -- Fallback: try getItemsFromType
                                if not antivirusItem then
                                    local itemList = inv:getItemsFromType(avType.id)
                                    if itemList and itemList:size() > 0 then
                                        antivirusItem = itemList:get(0)
                                    end
                                end
                                
                                if antivirusItem then
                                    -- Use the antivirus on the world object laptop
                                    local laptopItem = worldObject:getItem()
                                    if laptopItem and LaptopSystem then
                                        -- Get current health before treatment
                                        local beforeHealth = LaptopSystem.getLaptopHealth(laptopItem)
                                        
                                        -- Remove the antivirus item
                                        inv:DoRemoveItem(antivirusItem)
                                        
                                        -- Apply antivirus cleaning directly to world object
                                        local cleaned = false
                                        if LaptopSystem.cleanMalware then
                                            cleaned = LaptopSystem.cleanMalware(laptopItem, avType.heal)
                                        end
                                        local afterHealth = LaptopSystem.getLaptopHealth(laptopItem)
                                        local healthGain = afterHealth - beforeHealth
                                        
                                        if cleaned then
                                            playerObj:Say("Antivirus " .. avType.name .. " successfully cleaned malware! Health: " .. beforeHealth .. "% -> " .. afterHealth .. "% (+" .. healthGain .. "%)")
                                        else
                                            playerObj:Say("No malware detected. " .. avType.name .. " improved laptop condition: " .. beforeHealth .. "% -> " .. afterHealth .. "% (+" .. healthGain .. "%)")
                                            if LaptopSystem.damageLaptop then
                                                LaptopSystem.damageLaptop(laptopItem, -math.floor(avType.heal / 2))
                                            end
                                            -- Update after the additional healing
                                            local finalHealth = LaptopSystem.getLaptopHealth(laptopItem)
                                            if finalHealth ~= afterHealth then
                                                playerObj:Say("Additional maintenance applied. Final health: " .. finalHealth .. "%")
                                            end
                                        end
                                    else
                                        playerObj:Say("Cannot access laptop for cleaning.")
                                    end
                                else
                                    playerObj:Say("No " .. avType.name .. " antivirus found in inventory.")
                                end
                            end)
                        end
                    end
                end
                
                -- Check for elite drives and create submenu
                local eliteCount = 0
                local eliteTypes = {{"Strength", "Force"}, {"Endurance", "Resistance"}, {"Capacity", "Weight"}, {"Speed", "Movement"}, {"Luck", "Fortune"}}
                local availableElites = {}
                
                for _, eData in ipairs(eliteTypes) do
                    local eType = eData[1]
                    local displayName = eData[2]
                    local fullTypeName = "GValley.EliteDrive_" .. eType
                    
                    -- Use multiple methods to count elite drives
                    local count = 0
                    
                    -- Method 1: getItemCount
                    count = inv:getItemCount(fullTypeName)
                    
                    -- Method 2: Manual count if getItemCount fails
                    if count == 0 then
                        local items = inv:getItems()
                        for i = 0, items:size() - 1 do
                            local checkItem = items:get(i)
                            if checkItem and checkItem:getFullType() == fullTypeName then
                                count = count + 1
                            end
                        end
                    end
                    
                    if count >= 2 then
                        eliteCount = eliteCount + 1
                        table.insert(availableElites, {type = eType, name = displayName, count = count, fullType = fullTypeName})
                    end
                end
                
                if eliteCount > 0 then
                    -- Create elite drives submenu
                    local eliteOption = context:addOption("Use Elite Enhancement (" .. eliteCount .. " types)", playerObj, function() end)
                    local eliteSubMenu = ISContextMenu:getNew(context)
                    context:addSubMenu(eliteOption, eliteSubMenu)
                    
                    -- Add info header
                    local infoOpt = eliteSubMenu:addOption("Elite Enhancements Available:", playerObj, function() end)
                    infoOpt.notAvailable = true
                    eliteSubMenu:addOption("---------", playerObj, function() end).notAvailable = true
                    
                    -- Add each available elite type
                    for _, elite in ipairs(availableElites) do
                        eliteSubMenu:addOption("Elite " .. elite.name .. " (" .. elite.count .. "/2)", playerObj, function()
                            -- Find elite drives in inventory
                            local eliteItems = {}
                            local items = inv:getItems()
                            for i = 0, items:size() - 1 do
                                local checkItem = items:get(i)
                                if checkItem and checkItem:getFullType() == elite.fullType then
                                    table.insert(eliteItems, checkItem)
                                    if #eliteItems >= 2 then break end -- Only need 2
                                end
                            end
                            
                            if #eliteItems >= 2 then
                                -- Remove 2 elite drives from inventory
                                inv:DoRemoveItem(eliteItems[1])
                                inv:DoRemoveItem(eliteItems[2])
                                
                                -- Apply elite enhancement
                                if EliteDriveSystem and EliteDriveSystem.useEliteDrive then
                                    local success = EliteDriveSystem.useEliteDrive(playerObj, elite.type)
                                    if success then
                                        playerObj:Say("Elite " .. elite.name .. " enhancement successfully applied! You feel more powerful...")
                                    else
                                        playerObj:Say("Elite " .. elite.name .. " enhancement failed. You may have already used this enhancement.")
                                        -- Return items if failed
                                        inv:AddItem(elite.fullType)
                                        inv:AddItem(elite.fullType)
                                    end
                                else
                                    playerObj:Say("Elite enhancement system not available.")
                                    -- Return items if system not available
                                    inv:AddItem(elite.fullType)
                                    inv:AddItem(elite.fullType)
                                end
                            else
                                playerObj:Say("Not enough Elite " .. elite.name .. " drives found. Need 2, have " .. #eliteItems)
                            end
                        end)
                    end
                    
                    eliteSubMenu:addOption("---------", playerObj, function() end).notAvailable = true
                    eliteSubMenu:addOption("Note: Elite drives work independently", playerObj, function()
                        playerObj:Say("Elite drives can be used directly from inventory without requiring a laptop.")
                    end).notAvailable = true
                end
            end
            
                debugPrint("Simple menu added successfully")
                break -- Only add menu once per laptop found
            end
        end
        end
    end
end

-- Register the context menu event
debugPrint("==> Registering context menu event...")
Events.OnFillWorldObjectContextMenu.Add(LaptopOnFillWorldObjectContextMenu)
debugPrint("==> Context menu event registered successfully")

debugPrint("LaptopFill.lua loaded successfully")
