-- MiniGameBufferDefense.lua v1.5.14 - Buffer Overflow Defender Minigame
-- MEJORAS v1.5.14:
-- ✅ Dificultad aumentada: +75% velocidad, +70% enemigos, -20% presupuesto
-- ✅ Sistema de combos: 5 kills = +2 budget, 10 kills = +5 budget
-- ✅ Explosiones con partículas al destruir enemigos
-- ✅ 3 Power-ups estratégicos (Slowdown, Fortress, Nuke)
-- ✅ HP visual de firewalls (■■■■■)

print("[DecryptSkillSys] Loading MiniGameBufferDefense.lua v1.5.14 - Enhanced Tower Defense")

function ReloadMiniGameBufferDefense() print("[DEBUG] Reloading BufferDefense v1.5.14..."); package.loaded["client/MiniGameBufferDefense"]=nil; pcall(require,"client/MiniGameBufferDefense") end
function TestBufferDefense(diff) diff=diff or "Easy"; if _G.MiniGame_BufferDefense then return _G.MiniGame_BufferDefense(nil,nil,"TestBuffer",diff,nil,{skill="TestBuffer"}) end end

-- ============================================================
-- ⚙️ CONFIGURACIÓN v1.5.14 - DIFICULTAD AUMENTADA
-- ============================================================
local W_PCT,H_PCT=32,50

-- 🎮 OLEADAS
local WAVE_COUNTS={Easy=1,Moderate=1,Expert=1}

-- 🏃 VELOCIDAD DE ENEMIGOS v1.5.14: +75% MÁS RÁPIDO
local EXPLOIT_SPEEDS={Easy=3.5,Moderate=5.0,Expert=7.0}

-- ⏱️ SPAWN RATE v1.5.14: -33% TIEMPO (más rápido)
local SPAWN_RATES={Easy=30,Moderate=20,Expert=15}

-- 👾 ENEMIGOS POR OLEADA v1.5.14: +70% MÁS ENEMIGOS
local EXPLOITS_PER_WAVE={Easy=10,Moderate=14,Expert=18}

-- 🛡️ CONFIGURACIÓN ESTRATÉGICA v1.5.14: -20% PRESUPUESTO
local LANE_COUNTS={Easy=3,Moderate=4,Expert=5}
local FIREWALL_BUDGETS={Easy=25,Moderate=20,Expert=15}
local FIREWALL_COST=1
local FIREWALL_HP=5
local CORE_HP=100
local DAMAGE_PER_EXPLOIT=20

-- 💥 v1.5.14: POWER-UPS
local POWERUP_COSTS={slowdown=5,fortress=8,nuke=15}
local POWERUP_DURATIONS={slowdown=600,fortress=300}  -- 10s y 5s

local THEME={
    bg={r=0.05,g=0.08,b=0.1,a=0.92},
    border={r=0.8,g=0.3,b=0.1,a=1},
    lane_bg={r=0.08,g=0.1,b=0.12,a=0.8},
    core={r=1,g=0.2,b=0.2,a=0.9},
    firewall={r=0.2,g=0.8,b=0.3,a=0.9},
    exploit={r=0.8,g=0.1,b=0.3,a=0.9},
    text={r=1,g=1,b=1,a=1},
    -- v1.5.14: Colores de partículas
    particle_explosion={r=1,g=0.3,b=0.1,a=0.9},
    particle_fortress={r=0.3,g=0.6,b=1,a=0.9},
    combo_text={r=1,g=1,b=0.2,a=1}
}

local SimpleTimer={activeTimers={},nextId=1}
function SimpleTimer:addTimer(dur,cb) local id=self.nextId; self.nextId=id+1; self.activeTimers[id]={callback=cb,duration=dur,elapsed=0}; return id end
function SimpleTimer:removeTimer(id) self.activeTimers[id]=nil end
function SimpleTimer:update() local rm={}; for id,t in pairs(self.activeTimers) do t.elapsed=t.elapsed+1; if t.elapsed>=t.duration then if t.callback then pcall(t.callback) end; rm[id]=true end end; for id in pairs(rm) do self.activeTimers[id]=nil end end
if Events and Events.OnTick then Events.OnTick.Add(function() SimpleTimer:update() end) end

local MiniGameBufferDefenseWindow=ISPanel:derive("MiniGameBufferDefenseWindow")

function MiniGameBufferDefenseWindow:new(x,y,w,h,player,usbType,diff,laptop,usbData)
    local o=ISPanel:new(x,y,w,h); setmetatable(o,self); self.__index=self
    o.player,o.usbType,o.difficulty,o.laptopItem,o.usbData=player,usbType,diff,laptop,usbData
    o.backgroundColor,o.borderColor,o.moveWithMouse=THEME.bg,THEME.border,true
    o.laneCount,o.waveCount,o.budget=LANE_COUNTS[diff] or 3,WAVE_COUNTS[diff] or 1,FIREWALL_BUDGETS[diff] or 25
    o.spawnRate,o.exploitSpeed=SPAWN_RATES[diff] or 30,EXPLOIT_SPEEDS[diff] or 3.5
    o.firewalls,o.exploits,o.currentWave,o.coreHP={},{},1,100
    o.gameActive,o.resultProcessed,o.placementMode,o.spawnCounter=false,false,false,0
    o.gridCols,o.titleText,o.titleShown,o.titleAcc=8,"BUFFER OVERFLOW DEFENDER",0,0
    -- v1.5.14: Sistema de combos y partículas
    o.comboCount=0
    o.particles={}
    o.comboMessages={5,10,15,20}
    o.killCount=0
    -- v1.5.14: Power-ups activos
    o.slowdownActive=false
    o.fortressActive=false
    o.slowdownTimer=0
    o.fortressTimer=0
    return o
end

-- v1.5.14: Crear partículas de explosión
function MiniGameBufferDefenseWindow:createExplosionParticles(x,y)
    for i=1,ZombRand(6,10) do
        local angle=ZombRand(0,360)*(math.pi/180)
        local speed=ZombRand(3,7)
        table.insert(self.particles,{
            x=x,y=y,
            vx=math.cos(angle)*speed,
            vy=math.sin(angle)*speed,
            life=20,maxLife=20,
            size=ZombRand(3,6),
            color={r=1,g=0.3+ZombRand(0,30)/100,b=0.1,a=0.9}
        })
    end
end

-- v1.5.14: Actualizar partículas
function MiniGameBufferDefenseWindow:updateParticles()
    for i=#self.particles,1,-1 do
        local p=self.particles[i]
        p.x=p.x+p.vx
        p.y=p.y+p.vy
        p.vy=p.vy+0.2  -- Gravedad
        p.life=p.life-1
        if p.life<=0 then table.remove(self.particles,i) end
    end
end

function MiniGameBufferDefenseWindow:createChildren()
    self.closeButton=ISButton:new(self.width-25,5,20,20,"X",self,self.onClose)
    self.closeButton:initialise(); self:addChild(self.closeButton)
    
    self.startButton=ISButton:new((self.width-120)/2,self.height-55,120,45,"START",self,self.onStart)
    self.startButton.borderColor={r=0.8,g=0.3,b=0.1,a=1}
    self.startButton.backgroundColor={r=0.15,g=0.08,b=0.05,a=0.9}
    self.startButton.backgroundColorMouseOver={r=0.8,g=0.3,b=0.1,a=0.9}
    self.startButton:initialise(); self:addChild(self.startButton)
    
    self.placeButton=ISButton:new((self.width-120)/2,self.height-105,120,35,"PLACE [-1]",self,self.onPlaceMode)
    self.placeButton.borderColor={r=0.2,g=0.8,b=0.3,a=1}
    self.placeButton.backgroundColor={r=0.05,g=0.15,b=0.08,a=0.9}
    self.placeButton.backgroundColorMouseOver={r=0.2,g=0.8,b=0.3,a=0.9}
    self.placeButton:initialise(); self.placeButton:setVisible(false); self:addChild(self.placeButton)
    
    -- v1.5.14: Power-up buttons
    self.slowdownButton=ISButton:new(20,self.height-150,80,25,"SLOW [-5]",self,self.onSlowdown)
    self.slowdownButton.borderColor={r=0.3,g=0.6,b=1,a=1}
    self.slowdownButton.backgroundColor={r=0.05,g=0.1,b=0.2,a=0.9}
    self.slowdownButton.backgroundColorMouseOver={r=0.3,g=0.6,b=1,a=0.9}
    self.slowdownButton:initialise(); self.slowdownButton:setVisible(false); self:addChild(self.slowdownButton)
    
    self.fortressButton=ISButton:new(110,self.height-150,80,25,"FORT [-8]",self,self.onFortress)
    self.fortressButton.borderColor={r=0.3,g=0.6,b=1,a=1}
    self.fortressButton.backgroundColor={r=0.05,g=0.1,b=0.2,a=0.9}
    self.fortressButton.backgroundColorMouseOver={r=0.3,g=0.6,b=1,a=0.9}
    self.fortressButton:initialise(); self.fortressButton:setVisible(false); self:addChild(self.fortressButton)
    
    self.nukeButton=ISButton:new(200,self.height-150,80,25,"NUKE [-15]",self,self.onNuke)
    self.nukeButton.borderColor={r=1,g=0.2,b=0.2,a=1}
    self.nukeButton.backgroundColor={r=0.2,g=0.05,b=0.05,a=0.9}
    self.nukeButton.backgroundColorMouseOver={r=1,g=0.2,b=0.2,a=0.9}
    self.nukeButton:initialise(); self.nukeButton:setVisible(false); self:addChild(self.nukeButton)
    
    self.buttons={}; local laneH=(self.height-220)/self.laneCount; local cellW=(self.width-80)/self.gridCols
    for lane=1,self.laneCount do self.buttons[lane]={}
        for col=1,self.gridCols do
            local btn=ISButton:new(60+(col-1)*cellW,80+(lane-1)*laneH,cellW-2,laneH-2,"",self,self.onCellClick)
            btn.lane,btn.col=lane,col; btn:initialise(); btn:setVisible(false); self:addChild(btn); self.buttons[lane][col]=btn
        end
    end
end

-- v1.5.14: Power-up: Slowdown (50% velocidad por 10s)
function MiniGameBufferDefenseWindow:onSlowdown()
    if self.budget<POWERUP_COSTS.slowdown or self.slowdownActive then return end
    self.budget=self.budget-POWERUP_COSTS.slowdown
    self.slowdownActive=true
    self.slowdownTimer=POWERUP_DURATIONS.slowdown
    self:playSound("UI_Menu_OS_Success")
    if self.player then self.player:Say("SLOWDOWN ACTIVATED! (-50% speed)") end
end

-- v1.5.14: Power-up: Fortress (firewalls x2 HP por 5s)
function MiniGameBufferDefenseWindow:onFortress()
    if self.budget<POWERUP_COSTS.fortress or self.fortressActive then return end
    self.budget=self.budget-POWERUP_COSTS.fortress
    self.fortressActive=true
    self.fortressTimer=POWERUP_DURATIONS.fortress
    -- Duplicar HP de todos los firewalls existentes
    for _,fw in pairs(self.firewalls) do
        fw.hp=fw.hp*2
    end
    self:playSound("UI_Menu_OS_Success")
    if self.player then self.player:Say("FORTRESS MODE! (x2 Firewall HP)") end
end

-- v1.5.14: Power-up: Nuke (elimina todos los enemigos en pantalla)
function MiniGameBufferDefenseWindow:onNuke()
    if self.budget<POWERUP_COSTS.nuke then return end
    self.budget=self.budget-POWERUP_COSTS.nuke
    local count=#self.exploits
    -- Crear explosiones para todos los enemigos
    for _,exp in ipairs(self.exploits) do
        local laneH=(self.height-220)/self.laneCount
        local y=80+(exp.lane-1)*laneH+laneH/2
        self:createExplosionParticles(exp.x,y)
    end
    self.exploits={}
    self.killCount=self.killCount+count
    self:playSound("UI_Menu_OS_Failure")
    if self.player then self.player:Say("NUCLEAR OPTION! " .. count .. " exploits eliminated!") end
end

function MiniGameBufferDefenseWindow:onStart()
    self.gameActive,self.currentWave,self.coreHP,self.budget=true,1,CORE_HP,FIREWALL_BUDGETS[self.difficulty] or 25
    self.firewalls,self.exploits,self.comboCount,self.killCount={},{},0,0
    self.spawnedThisWave,self.nextSpawnLane=0,1
    self.startButton:setVisible(false)
    self.placeButton:setVisible(true)
    self.slowdownButton:setVisible(true)
    self.fortressButton:setVisible(true)
    self.nukeButton:setVisible(true)
    for lane=1,self.laneCount do for col=1,self.gridCols do self.buttons[lane][col]:setVisible(true) end end
    self:startSpawner(); self:playSound("UI_Menu_OS_Start")
    if self.player then self.player:Say("Defend the core! " .. EXPLOITS_PER_WAVE[self.difficulty] .. " incoming!") end
end

function MiniGameBufferDefenseWindow:onPlaceMode() self.placementMode=not self.placementMode; self:playSound("UI_Menu_OS_Select") end

function MiniGameBufferDefenseWindow:onCellClick(btn)
    if not self.gameActive or not self.placementMode or self.budget<FIREWALL_COST then return end
    local key=btn.lane..","..btn.col
    if not self.firewalls[key] then
        self.firewalls[key]={lane=btn.lane,col=btn.col,hp=FIREWALL_HP}
        self.budget=self.budget-FIREWALL_COST
        self:playSound("UI_Menu_OS_Select")
    end
end

function MiniGameBufferDefenseWindow:startSpawner()
    self:cancelTimer("spawnerId")
    self.spawnerId=SimpleTimer:addTimer(1,function()
        if not self.gameActive then return end
        self.spawnCounter=self.spawnCounter+1
        
        if self.spawnCounter>=self.spawnRate then
            local maxEnemies=EXPLOITS_PER_WAVE[self.difficulty] or 10
            if self.spawnedThisWave<maxEnemies then
                self.nextSpawnLane=(self.nextSpawnLane%self.laneCount)+1
                table.insert(self.exploits,{lane=self.nextSpawnLane,x=self.width-70,hp=1,flash=10})
                self.spawnedThisWave=self.spawnedThisWave+1
                self:playSound("UI_Menu_OS_Error")
            end
            self.spawnCounter=0
        end
        self:startSpawner()
    end)
end

function MiniGameBufferDefenseWindow:cancelTimer(f) if f and self[f] then SimpleTimer:removeTimer(self[f]); self[f]=nil end end

function MiniGameBufferDefenseWindow:onClose()
    if self.gameActive then self:processFinalResult(false) end
    self:cancelTimer("spawnerId"); self:setVisible(false); self:removeFromUIManager()
end

function MiniGameBufferDefenseWindow:update()
    ISPanel.update(self); if not self.gameActive then return end
    
    -- v1.5.14: Actualizar power-ups
    if self.slowdownActive then
        self.slowdownTimer=self.slowdownTimer-1
        if self.slowdownTimer<=0 then
            self.slowdownActive=false
            if self.player then self.player:Say("Slowdown expired!") end
        end
    end
    
    if self.fortressActive then
        self.fortressTimer=self.fortressTimer-1
        if self.fortressTimer<=0 then
            self.fortressActive=false
            if self.player then self.player:Say("Fortress mode expired!") end
        end
    end
    
    -- v1.5.14: Actualizar partículas
    self:updateParticles()
    
    -- Mover enemigos con velocidad ajustada
    local cellW=(self.width-80)/self.gridCols
    local speed=self.exploitSpeed
    if self.slowdownActive then speed=speed*0.5 end  -- v1.5.14: Slowdown effect
    
    for i=#self.exploits,1,-1 do
        local exp=self.exploits[i]; exp.x=exp.x-speed
        if exp.flash then exp.flash=exp.flash-1 end
        
        -- Colisión con firewalls
        local col=math.floor((exp.x-60)/cellW)+1
        if col>=1 and col<=self.gridCols then
            local key=exp.lane..","..col
            if self.firewalls[key] then
                self.firewalls[key].hp=self.firewalls[key].hp-1
                exp.hp=0
                self.firewalls[key].flash=8
                self:playSound("UI_Menu_OS_Select")
                
                -- v1.5.14: Explosión al destruir enemigo
                local laneH=(self.height-220)/self.laneCount
                local y=80+(exp.lane-1)*laneH+laneH/2
                self:createExplosionParticles(exp.x,y)
                
                -- v1.5.14: Sistema de combos
                self.comboCount=self.comboCount+1
                self.killCount=self.killCount+1
                
                for _,milestone in ipairs(self.comboMessages) do
                    if self.comboCount==milestone then
                        local bonus=milestone==5 and 2 or milestone==10 and 5 or milestone==15 and 8 or 10
                        self.budget=self.budget+bonus
                        self:playSound("UI_Menu_OS_Success")
                        if self.player then self.player:Say(milestone .. " STREAK! +" .. bonus .. " BUDGET") end
                        break
                    end
                end
                
                if self.firewalls[key].hp<=0 then
                    self.firewalls[key]=nil
                    self:playSound("UI_Menu_OS_Error")
                end
            end
        end
        
        -- Llegó al core
        if exp.x<40 then
            self.coreHP=self.coreHP-DAMAGE_PER_EXPLOIT
            exp.hp=0
            -- v1.5.14: Reset combo al recibir daño
            self.comboCount=0
            self:playSound("UI_Menu_OS_Failure")
            if self.player then self.player:Say("COMBO RESET! Core HP: " .. self.coreHP) end
        end
        
        if exp.hp<=0 then table.remove(self.exploits,i) end
    end
    
    -- Decay de flash en firewalls
    for _,fw in pairs(self.firewalls) do
        if fw.flash then fw.flash=fw.flash-1 end
    end
    
    -- Check win/lose
    local maxEnemies=EXPLOITS_PER_WAVE[self.difficulty] or 10
    if self.coreHP<=0 then
        self:processFinalResult(false)
    elseif self.spawnedThisWave>=maxEnemies and #self.exploits==0 then
        self.currentWave=self.currentWave+1
        if self.currentWave>self.waveCount then
            self:processFinalResult(true)
        else
            self.spawnedThisWave,self.spawnCounter=0,0
            self:playSound("UI_Menu_OS_Success")
        end
    end
end

function MiniGameBufferDefenseWindow:processFinalResult(success)
    if self.resultProcessed then return end
    self.resultProcessed,self.gameActive=true,false
    self:cancelTimer("spawnerId")
    
    if not success and self.laptopItem then
        if isClient() then sendClientCommand(self.player,"GVDrive","IncrementFailureCount",{laptop=self.laptopItem})
        elseif LaptopSystem and LaptopSystem.incrementFailureCount then LaptopSystem.incrementFailureCount(self.laptopItem) end
    end
    
    if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
        GVDrive_Utils.applyMinigameResult(self.player,self.laptopItem,self.usbType,self.difficulty,success)
    end
    
    self:playSound(success and "UI_Menu_OS_Success" or "UI_Menu_OS_Failure")
    if self.player then
        if success then
            self.player:Say("Victory! " .. self.killCount .. " exploits blocked!")
        else
            self.player:Say("Defeat! Core breached!")
        end
    end
    
    SimpleTimer:addTimer(120,function() self:onClose() end)
end

function MiniGameBufferDefenseWindow:playSound(snd)
    if self.player and snd then
        if self.player.playSoundLocal then self.player:playSoundLocal(snd)
        elseif getPlayer() then getPlayer():playSoundLocal(snd) end
    end
end

function MiniGameBufferDefenseWindow:render()
    ISPanel.render(self)
    
    if self.gameActive and self.titleShown<#self.titleText then
        self.titleAcc=self.titleAcc+1
        if self.titleAcc>=3 then self.titleAcc=0; self.titleShown=self.titleShown+1 end
    elseif not self.gameActive then self.titleShown=#self.titleText end
    
    self:drawTextCentre(string.sub(self.titleText,1,self.titleShown),self.width/2,10,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large)
    
    if self.gameActive then
        -- Stats
        self:drawText("WAVE: "..self.currentWave.."/"..self.waveCount,10,35,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)
        self:drawText("BUDGET: "..self.budget,self.width-120,35,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)
        
        -- v1.5.14: HP con barra visual
        local hpPercent=self.coreHP/100
        local hpColor=hpPercent>0.5 and THEME.text or {r=1,g=0.2,b=0.2,a=1}
        self:drawText("CORE HP:",10,55,hpColor.r,hpColor.g,hpColor.b,hpColor.a,UIFont.Small)
        local blocks=math.ceil(hpPercent*10)
        local hpBar=""
        for i=1,10 do hpBar=hpBar..(i<=blocks and "■" or "□") end
        self:drawText(hpBar,80,55,hpColor.r,hpColor.g,hpColor.b,hpColor.a,UIFont.Small)
        
        -- v1.5.14: Combo counter
        if self.comboCount>0 then
            self:drawText("COMBO: "..self.comboCount,self.width/2-50,55,THEME.combo_text.r,THEME.combo_text.g,THEME.combo_text.b,THEME.combo_text.a,UIFont.Medium)
        end
        
        -- Draw lanes
        local laneH=(self.height-220)/self.laneCount
        for lane=1,self.laneCount do
            local y=80+(lane-1)*laneH
            self:drawRect(60,y,self.width-120,laneH,THEME.lane_bg.a,THEME.lane_bg.r,THEME.lane_bg.g,THEME.lane_bg.b)
        end
        
        -- Draw core
        self:drawRect(10,80,40,laneH*self.laneCount,THEME.core.a,THEME.core.r,THEME.core.g,THEME.core.b)
        self:drawTextCentre("CORE",30,80+laneH*self.laneCount/2-8,0,0,0,1,UIFont.Small)
        
        -- Draw firewalls con HP visual
        local cellW=(self.width-80)/self.gridCols
        for key,fw in pairs(self.firewalls) do
            local x,y=60+(fw.col-1)*cellW,80+(fw.lane-1)*laneH
            local flashIntensity=fw.flash and (fw.flash/8) or 0
            local r=THEME.firewall.r+flashIntensity*0.5
            self:drawRect(x,y,cellW-2,laneH-2,THEME.firewall.a,r,THEME.firewall.g,THEME.firewall.b)
            -- v1.5.14: HP visual
            local hpBlocks=""
            for i=1,FIREWALL_HP do hpBlocks=hpBlocks..(i<=fw.hp and "■" or "□") end
            self:drawTextCentre(hpBlocks,x+cellW/2,y+laneH/2-8,0,0,0,1,UIFont.Small)
        end
        
        -- Draw exploits
        for _,exp in ipairs(self.exploits) do
            local y=80+(exp.lane-1)*laneH+laneH/2
            local flashIntensity=exp.flash and (exp.flash/10) or 0
            self:drawRect(exp.x-10,y-10,20,20,THEME.exploit.a,THEME.exploit.r+flashIntensity*0.2,THEME.exploit.g,THEME.exploit.b)
            self:drawTextCentre("X",exp.x,y-8,1,1,1,1,UIFont.Small)
        end
        
        -- v1.5.14: Draw particles
        for _,p in ipairs(self.particles) do
            local alpha=p.life/p.maxLife
            self:drawRect(p.x,p.y,p.size,p.size,alpha,p.color.r,p.color.g,p.color.b)
        end
        
        -- v1.5.14: Power-up indicators
        if self.slowdownActive then
            local timeLeft=math.ceil(self.slowdownTimer/60)
            self:drawText("SLOWDOWN: "..timeLeft.."s",self.width-150,self.height-150,0.3,0.6,1,1,UIFont.Small)
        end
        if self.fortressActive then
            local timeLeft=math.ceil(self.fortressTimer/60)
            self:drawText("FORTRESS: "..timeLeft.."s",self.width-150,self.height-130,0.3,0.6,1,1,UIFont.Small)
        end
        
        if self.placementMode then
            self:drawTextCentre("PLACEMENT MODE ACTIVE",self.width/2,70,0.2,1,0.2,1,UIFont.Medium)
        end
    else
        if self.resultProcessed then
            local msg=self.coreHP>0 and "SYSTEM DEFENDED!" or "CORE BREACHED!"
            self:drawTextCentre(msg,self.width/2,self.height/2-20,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large)
            self:drawTextCentre("Kills: "..self.killCount,self.width/2,self.height/2+10,THEME.combo_text.r,THEME.combo_text.g,THEME.combo_text.b,THEME.combo_text.a,UIFont.Medium)
        end
    end
end

function MiniGame_BufferDefense(widthPct,heightPct,usbType,difficulty,laptopItem,usbData)
    local player=getPlayer(); if not player then return end
    local screenW,screenH=getCore():getScreenWidth(),getCore():getScreenHeight()
    local width,height=math.floor(screenW*(W_PCT/100)),math.floor(screenH*(H_PCT/100))
    local x,y=(screenW-width)/2,(screenH-height)/2
    local win=MiniGameBufferDefenseWindow:new(x,y,width,height,player,usbType,difficulty,laptopItem,usbData)
    win:initialise(); win:addToUIManager(); win:bringToTop(); return win
end

print("[DecryptSkillSys] MiniGame_BufferDefense v1.5.14 loaded - Enhanced difficulty + combos + power-ups")
