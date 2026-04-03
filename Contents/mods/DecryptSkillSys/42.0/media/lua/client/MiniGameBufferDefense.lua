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
local W_PCT,H_PCT=30,48
local GRID_PADDING={top=120,left=70,right=70,bottom=140}

-- 🎮 OLEADAS Y DIFICULTAD ESCALADA
local WAVE_COUNTS={Easy=2,Moderate=3,Expert=3}

-- 🏃 VELOCIDAD BASE DE ENEMIGOS (se incrementa cada oleada)
local EXPLOIT_SPEEDS={Easy=5.5,Moderate=6.9,Expert=8.8}

-- ⏱️ SPAWN RATE (ticks entre spawns)
local SPAWN_RATES={Easy=24,Moderate=18,Expert=12}

-- 👾 ENEMIGOS POR OLEADA
local EXPLOITS_PER_WAVE={Easy=14,Moderate=20,Expert=28}

-- 💣 SALUD BASE + ELITES
local EXPLOIT_HPS={Easy=1,Moderate=2,Expert=3}
local ELITE_INTERVAL={Easy=6,Moderate=5,Expert=4}
local ELITE_HP_BONUS=2
local ELITE_SPEED_BONUS=1.5

-- 🛡️ CONFIGURACIÓN ESTRATÉGICA
local LANE_COUNTS={Easy=4,Moderate=5,Expert=6}
local FIREWALL_BUDGETS={Easy=18,Moderate=14,Expert=12}
local FIREWALL_COST=2
local FIREWALL_HP=4
local CORE_HP=90
local DAMAGE_PER_EXPLOIT=25

-- 💥 POWER-UPS
local POWERUP_COSTS={slowdown=6,fortress=9,nuke=16}
local POWERUP_DURATIONS={slowdown=540,fortress=300}  -- 9s y 5s

local THEME={
    bg={r=0.05,g=0.2,b=0.05,a=0.92},
    border={r=0.2,g=1,b=0.2,a=1},
    lane_bg={r=0.06,g=0.15,b=0.08,a=0.78},
    core={r=0.1,g=0.35,b=0.15,a=0.95},
    firewall={r=0.3,g=0.85,b=0.4,a=0.95},
    exploit={r=0.8,g=0.25,b=0.35,a=0.95},
    exploit_elite={r=0.2,g=0.6,b=1,a=0.95},
    text={r=0.75,g=1,b=0.75,a=1},
    particle_explosion={r=0.3,g=1,b=0.4,a=0.9},
    particle_fortress={r=0.2,g=0.9,b=0.9,a=0.9},
    combo_text={r=0.4,g=1,b=0.6,a=1},
    scanline={r=0.2,g=1,b=0.2,a=0.04}
}

local STATUS_MESSAGES={
    "BUFFER LINK ESTABLISHED",
    "SCANNING INTRUSION LANES",
    "FIREWALLS ARMED",
    "TRIANGULATING EXPLOITS",
    "CORE INTEGRITY UNDER WATCH"
}

local STATUS_CYCLE_DELAY=180
local SCANLINE_SPACING=4
local BORDER_THICKNESS=2

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
    o.laneCount=LANE_COUNTS[diff] or LANE_COUNTS.Moderate
    o.waveCount=WAVE_COUNTS[diff] or 2
    o.baseSpawnRate=SPAWN_RATES[diff] or SPAWN_RATES.Moderate
    o.baseSpeed=EXPLOIT_SPEEDS[diff] or EXPLOIT_SPEEDS.Moderate
    o.baseEnemyHP=EXPLOIT_HPS[diff] or EXPLOIT_HPS.Moderate
    o.eliteInterval=ELITE_INTERVAL[diff] or ELITE_INTERVAL.Moderate
    o.spawnRate=o.baseSpawnRate
    o.exploitSpeed=o.baseSpeed
    o.baseEnemyCount=EXPLOITS_PER_WAVE[diff] or EXPLOITS_PER_WAVE.Moderate
    o.maxEnemiesThisWave=o.baseEnemyCount
    o.firewalls={}
    o.exploits={}
    o.currentWave=1
    o.coreHP=CORE_HP
    o.budget=FIREWALL_BUDGETS[diff] or FIREWALL_BUDGETS.Moderate
    o.gameActive=false
    o.resultProcessed=false
    o.placementMode=false
    o.spawnCounter=0
    o.spawnedThisWave=0
    o.spawnedTotal=0
    o.spawnedSinceElite=0
    o.gridCols=8
    o.nextSpawnLane=1
    o.titleText="BUFFER OVERFLOW DEFENDER"
    o.titleShown=0
    o.titleAcc=0
    o.comboCount=0
    o.killCount=0
    o.comboMessages={5,10,15,20}
    o.particles={}
    o.slowdownActive=false
    o.fortressActive=false
    o.slowdownTimer=0
    o.fortressTimer=0
    o.statusIndex=1
    o.statusTimer=0
    o.statusPulse=0
    o.scanlineOffset=0
    o.statusCycleEnabled=false
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

function MiniGameBufferDefenseWindow:getGridMetrics()
    local gridWidth=self.width-GRID_PADDING.left-GRID_PADDING.right
    local gridHeight=self.height-GRID_PADDING.top-GRID_PADDING.bottom
    local cellW=gridWidth/self.gridCols
    local laneH=gridHeight/self.laneCount
    return GRID_PADDING.left,GRID_PADDING.top,gridWidth,gridHeight,cellW,laneH
end

function MiniGameBufferDefenseWindow:registerKill(isElite)
    self.comboCount=self.comboCount+1
    self.killCount=self.killCount+1
    if isElite then
        self.budget=self.budget+3
        self:playSound("UI_Menu_OS_Success")
    end
    for _,milestone in ipairs(self.comboMessages) do
        if self.comboCount==milestone then
            local bonus=milestone==5 and 3 or milestone==10 and 6 or milestone==15 and 9 or 12
            self.budget=self.budget+bonus
            self:playSound("UI_Menu_OS_Success")
            if self.player then
                self.player:Say(milestone .. " streak! +" .. bonus .. " budget")
            end
            break
        end
    end
end

function MiniGameBufferDefenseWindow:spawnEnemy()
    if self.spawnedThisWave>=self.maxEnemiesThisWave then return end
    local originX,originY,gridWidth,_,cellW,laneH=self:getGridMetrics()
    local lane=self.nextSpawnLane or 1
    self.nextSpawnLane=(lane%self.laneCount)+1

    local baseHp=self.baseEnemyHP + (self.currentWave-1)
    local enemy={
        lane=lane,
        x=originX+gridWidth+24,
        y=originY+(lane-0.5)*laneH,
        hp=baseHp,
        maxHp=baseHp,
        speed=self.exploitSpeed,
        elite=false,
        flash=10
    }

    self.spawnedSinceElite=(self.spawnedSinceElite or 0)+1
    if self.spawnedSinceElite>=self.eliteInterval then
        enemy.elite=true
        enemy.hp=enemy.hp+ELITE_HP_BONUS
        enemy.maxHp=enemy.hp
        enemy.speed=enemy.speed*ELITE_SPEED_BONUS
        self.spawnedSinceElite=0
    end

    table.insert(self.exploits,enemy)
    self.spawnedThisWave=self.spawnedThisWave+1
    self.spawnedTotal=self.spawnedTotal+1

    if enemy.elite then
        self:playSound("UI_Menu_OS_Start")
        if self.player then self.player:Say("Elite exploit detected!") end
    else
        self:playSound("UI_Menu_OS_Error")
    end
end

function MiniGameBufferDefenseWindow:advanceWave()
    if not self.gameActive then return end
    if self.currentWave>=self.waveCount then
        self:processFinalResult(true)
        return
    end
    self.currentWave=self.currentWave+1
    self.spawnRate=math.max(6,math.floor(self.baseSpawnRate-2*(self.currentWave-1)))
    self.exploitSpeed=self.baseSpeed+(self.currentWave-1)*0.9
    self.baseEnemyHP=self.baseEnemyHP+1
    self.maxEnemiesThisWave=math.floor(self.baseEnemyCount*(1+0.3*(self.currentWave-1)))
    self.spawnedThisWave=0
    self.spawnCounter=0
    self.spawnedSinceElite=0
    self.nextSpawnLane=1
    self.statusTimer=0
    if self.player then self.player:Say("Wave " .. self.currentWave .. " inbound!") end
    self:playSound("UI_Menu_OS_Success")
end

function MiniGameBufferDefenseWindow:updateStatusCycle()
    self.scanlineOffset=(self.scanlineOffset+1)%SCANLINE_SPACING
    if not self.statusCycleEnabled then return end
    self.statusTimer=self.statusTimer+1
    self.statusPulse=self.statusPulse+1
    if self.statusTimer>=STATUS_CYCLE_DELAY then
        self.statusTimer=0
        self.statusIndex=(self.statusIndex % #STATUS_MESSAGES)+1
    end
end

function MiniGameBufferDefenseWindow:drawFirewallHP(fw,x,y,cellW,laneH)
    local maxHp=fw.maxHp or FIREWALL_HP
    local ratio=maxHp>0 and math.max(fw.hp,0)/maxHp or 0
    local barWidth=cellW-12
    local barHeight=6
    local startX=x+6
    local startY=y+laneH-12
    self:drawRect(startX,startY,barWidth,barHeight,0.25,0,0.35,0)
    self:drawRect(startX,startY,barWidth*ratio,barHeight,0.9,0.3,1,0.3)
end

function MiniGameBufferDefenseWindow:drawStatusPanel()
    local message
    if self.gameActive then
        message=STATUS_MESSAGES[self.statusIndex]
    elseif self.resultProcessed then
        message=self.coreHP>0 and "SYSTEM DEFENDED" or "CORE BREACHED"
    else
        message="INITIALIZE BUFFER DEFENSE"
    end
    local pulse=0.6+0.4*math.abs(math.sin((self.statusPulse or 0)/12))
    self:drawTextCentre(message,self.width/2,32,THEME.text.r,THEME.text.g,THEME.text.b,pulse,UIFont.Small)
end

function MiniGameBufferDefenseWindow:drawCRTOverlay()
    for y=self.scanlineOffset,self.height,SCANLINE_SPACING do
        self:drawRect(0,y,self.width,1,THEME.scanline.a,THEME.scanline.r,THEME.scanline.g,THEME.scanline.b)
    end
    self:drawRectBorder(0,0,self.width,self.height,THEME.border.a,THEME.border.r,THEME.border.g,THEME.border.b)
    self:drawRectBorder(BORDER_THICKNESS,BORDER_THICKNESS,self.width-2*BORDER_THICKNESS,self.height-2*BORDER_THICKNESS,THEME.border.a*0.7,THEME.border.r,THEME.border.g,THEME.border.b)
end

function MiniGameBufferDefenseWindow:createChildren()
    self.closeButton=ISButton:new(self.width-25,5,20,20,"X",self,self.onClose)
    self.closeButton:initialise(); self:addChild(self.closeButton)

    local startWidth,startHeight=150,44
    local controlY=self.height-60
    self.startButton=ISButton:new((self.width-startWidth)/2,controlY,startWidth,startHeight,"START",self,self.onStart)
    self.startButton.borderColor={r=0.25,g=0.9,b=0.25,a=1}
    self.startButton.backgroundColor={r=0.08,g=0.2,b=0.08,a=0.95}
    self.startButton.backgroundColorMouseOver={r=0.25,g=1,b=0.4,a=1}
    self.startButton:initialise(); self:addChild(self.startButton)

    local placeWidth=160
    self.placeButton=ISButton:new(GRID_PADDING.left,controlY,placeWidth,32,"PLACE FIREWALL [-"..FIREWALL_COST.."]",self,self.onPlaceMode)
    self.placeButton.borderColor={r=0.25,g=0.9,b=0.25,a=1}
    self.placeButton.backgroundColor={r=0.05,g=0.16,b=0.08,a=0.9}
    self.placeButton.backgroundColorMouseOver={r=0.2,g=0.9,b=0.2,a=1}
    self.placeButton:initialise(); self.placeButton:setVisible(false); self:addChild(self.placeButton)

    local powerY=controlY-42
    self.slowdownButton=ISButton:new(GRID_PADDING.left,powerY,110,28,"SLOW [-"..POWERUP_COSTS.slowdown.."]",self,self.onSlowdown)
    self.slowdownButton.borderColor={r=0.2,g=0.8,b=1,a=1}
    self.slowdownButton.backgroundColor={r=0.05,g=0.12,b=0.2,a=0.9}
    self.slowdownButton.backgroundColorMouseOver={r=0.2,g=0.9,b=1,a=1}
    self.slowdownButton:initialise(); self.slowdownButton:setVisible(false); self:addChild(self.slowdownButton)

    self.fortressButton=ISButton:new(GRID_PADDING.left+120,powerY,110,28,"FORT [-"..POWERUP_COSTS.fortress.."]",self,self.onFortress)
    self.fortressButton.borderColor={r=0.2,g=0.8,b=1,a=1}
    self.fortressButton.backgroundColor={r=0.05,g=0.12,b=0.2,a=0.9}
    self.fortressButton.backgroundColorMouseOver={r=0.2,g=0.9,b=1,a=1}
    self.fortressButton:initialise(); self.fortressButton:setVisible(false); self:addChild(self.fortressButton)

    self.nukeButton=ISButton:new(GRID_PADDING.left+240,powerY,110,28,"NUKE [-"..POWERUP_COSTS.nuke.."]",self,self.onNuke)
    self.nukeButton.borderColor={r=1,g=0.3,b=0.3,a=1}
    self.nukeButton.backgroundColor={r=0.2,g=0.05,b=0.05,a=0.9}
    self.nukeButton.backgroundColorMouseOver={r=1,g=0.4,b=0.4,a=1}
    self.nukeButton:initialise(); self.nukeButton:setVisible(false); self:addChild(self.nukeButton)

    self.buttons={}
    local originX,originY,_,_,cellW,laneH=self:getGridMetrics()
    for lane=1,self.laneCount do
        self.buttons[lane]={}
        for col=1,self.gridCols do
            local btn=ISButton:new(originX+(col-1)*cellW,originY+(lane-1)*laneH,cellW-4,laneH-4,"",self,self.onCellClick)
            btn.lane,btn.col=lane,col
            btn.borderColor={r=0.25,g=1,b=0.25,a=0.6}
            btn.backgroundColor={r=0,g=0,b=0,a=0.2}
            btn.backgroundColorMouseOver={r=0.25,g=1,b=0.25,a=0.35}
            btn:initialise()
            btn:setVisible(false)
            self:addChild(btn)
            self.buttons[lane][col]=btn
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
    for _,fw in pairs(self.firewalls) do
        fw.originalMaxHp=fw.originalMaxHp or fw.maxHp or FIREWALL_HP
        fw.maxHp=(fw.originalMaxHp or FIREWALL_HP)*2
        fw.hp=math.min((fw.hp or FIREWALL_HP)*2,fw.maxHp)
        fw.fortressBoost=true
    end
    self:playSound("UI_Menu_OS_Success")
    if self.player then self.player:Say("FORTRESS MODE! (x2 Firewall HP)") end
end

-- v1.5.14: Power-up: Nuke (elimina todos los enemigos en pantalla)
function MiniGameBufferDefenseWindow:onNuke()
    if self.budget<POWERUP_COSTS.nuke then return end
    self.budget=self.budget-POWERUP_COSTS.nuke
    local count=#self.exploits
    for _,exp in ipairs(self.exploits) do
        self:createExplosionParticles(exp.x,exp.y or exp.lane)
        self:registerKill(exp.elite)
    end
    self.exploits={}
    self:playSound("UI_Menu_OS_Failure")
    if self.player then self.player:Say("NUCLEAR OPTION! " .. count .. " exploits eliminated!") end
end

function MiniGameBufferDefenseWindow:onStart()
    self.gameActive=true
    self.resultProcessed=false
    self.statusCycleEnabled=true
    self.statusIndex=1
    self.statusTimer=0
    self.statusPulse=0
    self.currentWave=1
    self.coreHP=CORE_HP
    self.budget=FIREWALL_BUDGETS[self.difficulty] or FIREWALL_BUDGETS.Moderate
    self.firewalls={}
    self.exploits={}
    self.comboCount=0
    self.killCount=0
    self.spawnedThisWave=0
    self.spawnedTotal=0
    self.spawnedSinceElite=0
    self.spawnCounter=0
    self.nextSpawnLane=1
    self.maxEnemiesThisWave=self.baseEnemyCount
    self.baseEnemyHP=EXPLOIT_HPS[self.difficulty] or self.baseEnemyHP
    self.spawnRate=self.baseSpawnRate
    self.exploitSpeed=self.baseSpeed
    self.slowdownActive=false
    self.fortressActive=false
    self.slowdownTimer=0
    self.fortressTimer=0
    self.startButton:setVisible(false)
    self.placeButton:setVisible(true)
    self.slowdownButton:setVisible(true)
    self.fortressButton:setVisible(true)
    self.nukeButton:setVisible(true)
    for lane=1,self.laneCount do
        for col=1,self.gridCols do
            local btn=self.buttons[lane][col]
            btn:setVisible(true)
        end
    end
    self:startSpawner()
    self:playSound("UI_Menu_OS_Start")
    if self.player then
        self.player:Say("Defend the core! " .. self.maxEnemiesThisWave .. " exploits inbound")
    end
end

function MiniGameBufferDefenseWindow:onPlaceMode()
    self.placementMode=not self.placementMode
    local label=self.placementMode and "PLACEMENT MODE [ON]" or "PLACE FIREWALL [-"..FIREWALL_COST.."]"
    self.placeButton:setTitle(label)
    self:playSound("UI_Menu_OS_Select")
end

function MiniGameBufferDefenseWindow:onCellClick(btn)
    if not self.gameActive or not self.placementMode or self.budget<FIREWALL_COST then return end
    local key=btn.lane..","..btn.col
    if not self.firewalls[key] then
        local fw={lane=btn.lane,col=btn.col,hp=FIREWALL_HP,maxHp=FIREWALL_HP}
        if self.fortressActive then
            fw.originalMaxHp=FIREWALL_HP
            fw.maxHp=FIREWALL_HP*2
            fw.hp=fw.maxHp
            fw.fortressBoost=true
        end
        self.firewalls[key]=fw
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
            self:spawnEnemy()
            self.spawnCounter=0
        end
        self:startSpawner()
    end)
end

function MiniGameBufferDefenseWindow:cancelTimer(f) if f and self[f] then SimpleTimer:removeTimer(self[f]); self[f]=nil end end

function MiniGameBufferDefenseWindow:onClose()
    if self.gameActive then self:processFinalResult(false) end
    self:cancelTimer("spawnerId")
    self.statusCycleEnabled=false
    self.startButton:setVisible(true)
    self.placeButton:setVisible(false)
    self.slowdownButton:setVisible(false)
    self.fortressButton:setVisible(false)
    self.nukeButton:setVisible(false)
    for lane=1,self.laneCount do
        for col=1,self.gridCols do
            self.buttons[lane][col]:setVisible(false)
        end
    end
    self:setVisible(false)
    self:removeFromUIManager()
end

function MiniGameBufferDefenseWindow:update()
    ISPanel.update(self)
    self:updateStatusCycle()
    if not self.gameActive then return end

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
            for _,fw in pairs(self.firewalls) do
                if fw.fortressBoost then
                    fw.maxHp=fw.originalMaxHp or FIREWALL_HP
                    fw.hp=math.min(fw.hp,fw.maxHp)
                    fw.fortressBoost=false
                end
            end
            if self.player then self.player:Say("Fortress mode expired!") end
        end
    end

    self:updateParticles()

    local originX,originY,_,_,cellW,laneH=self:getGridMetrics()
    local speed=self.exploitSpeed
    if self.slowdownActive then speed=speed*0.55 end

    for i=#self.exploits,1,-1 do
        local exp=self.exploits[i]
        exp.x=exp.x-speed
        if exp.flash and exp.flash>0 then exp.flash=exp.flash-1 end

        local removed=false
        local relX=exp.x-originX
        local col=math.floor(relX/cellW)+1
        if col>=1 and col<=self.gridCols then
            local key=exp.lane..","..col
            local fw=self.firewalls[key]
            if fw then
                fw.hp=(fw.hp or FIREWALL_HP)-1
                fw.flash=8
                exp.hp=(exp.hp or 1)-1
                exp.flash=12
                self:playSound("UI_Menu_OS_Select")
                if exp.hp<=0 then
                    self:createExplosionParticles(exp.x,exp.y)
                    self:registerKill(exp.elite)
                    removed=true
                end
                if fw.hp<=0 then
                    self.firewalls[key]=nil
                    self:playSound("UI_Menu_OS_Error")
                end
            end
        end

        if not removed and exp.x<=originX-12 then
            self.coreHP=self.coreHP-DAMAGE_PER_EXPLOIT
            self.comboCount=0
            self:playSound("UI_Menu_OS_Failure")
            if self.player then
                self.player:Say("Core integrity " .. math.max(self.coreHP,0) .. "%")
            end
            removed=true
        end

        if not removed and exp.hp and exp.hp<=0 then
            self:createExplosionParticles(exp.x,exp.y)
            self:registerKill(exp.elite)
            removed=true
        end

        if removed then
            table.remove(self.exploits,i)
        end
    end

    for _,fw in pairs(self.firewalls) do
        if fw.flash and fw.flash>0 then fw.flash=fw.flash-1 end
    end

    if self.coreHP<=0 then
        self:processFinalResult(false)
        return
    end

    if self.spawnedThisWave>=self.maxEnemiesThisWave and #self.exploits==0 then
        self:advanceWave()
    end
end

function MiniGameBufferDefenseWindow:processFinalResult(success)
    if self.resultProcessed then return end
    self.resultProcessed=true
    self.gameActive=false
    self:cancelTimer("spawnerId")
    self.statusCycleEnabled=false
    
    if not success and self.laptopItem then
        if isClient() then
            -- ✅ MULTIPLAYER: Enviar solo ID del item
            local laptopID = self.laptopItem:getID()
            if laptopID then
                sendClientCommand(self.player, "GVDrive", "IncrementFailureCount", { 
                    laptopID = laptopID,
                    playerIndex = self.player:getPlayerNum()
                })
            end
        elseif LaptopSystem and LaptopSystem.incrementFailureCount then 
            LaptopSystem.incrementFailureCount(self.laptopItem)
        end
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
    elseif not self.gameActive then
        self.titleShown=#self.titleText
    end

    self:drawCRTOverlay()
    self:drawTextCentre(string.sub(self.titleText,1,self.titleShown),self.width/2,12,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large)
    self:drawStatusPanel()

    local originX,originY,gridWidth,gridHeight,cellW,laneH=self:getGridMetrics()

    self:drawRect(originX-46,originY,40,laneH*self.laneCount,THEME.core.a,THEME.core.r,THEME.core.g,THEME.core.b)
    self:drawTextCentre("CORE",originX-26,originY+laneH*self.laneCount/2-8,0.1,0.9,0.1,1,UIFont.Small)

    for lane=1,self.laneCount do
        local y=originY+(lane-1)*laneH
        self:drawRect(originX,y,gridWidth,laneH,THEME.lane_bg.a,THEME.lane_bg.r,THEME.lane_bg.g,THEME.lane_bg.b)
    end

    self:drawText(string.format("WAVE %d/%d",self.currentWave,self.waveCount),GRID_PADDING.left,64,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)
    self:drawText("BUDGET: "..self.budget,self.width-GRID_PADDING.right-110,64,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)

    local hpPercent=math.max(self.coreHP,0)/CORE_HP
    local hpBarWidth=gridWidth
    local hpY=originY-28
    self:drawRect(originX,hpY,hpBarWidth,6,0.35,0,0.3,0)
    self:drawRect(originX,hpY,hpBarWidth*hpPercent,6,0.9,0.3,1,0.3)
    self:drawText(string.format("CORE INTEGRITY: %d%%",math.floor(hpPercent*100)),originX,hpY-14,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)

    if self.comboCount>0 then
        self:drawText("COMBO "..self.comboCount,originX+gridWidth-120,hpY-14,THEME.combo_text.r,THEME.combo_text.g,THEME.combo_text.b,THEME.combo_text.a,UIFont.Small)
    end

    for key,fw in pairs(self.firewalls) do
        local x=originX+(fw.col-1)*cellW
        local y=originY+(fw.lane-1)*laneH
        local flash=fw.flash and fw.flash/12 or 0
        local r=THEME.firewall.r+flash*0.3
        self:drawRect(x+2,y+2,cellW-8,laneH-8,THEME.firewall.a,r,THEME.firewall.g,THEME.firewall.b)
        self:drawFirewallHP(fw,x,y,cellW,laneH)
    end

    for _,exp in ipairs(self.exploits) do
        local flash=exp.flash and exp.flash/12 or 0
        local color=exp.elite and THEME.exploit_elite or THEME.exploit
        self:drawRect(exp.x-12,exp.y-12,24,24,color.a,color.r+flash,color.g,color.b)
        if exp.elite then
            self:drawTextCentre("E",exp.x,exp.y-6,0,0.1,0.1,1,UIFont.Small)
        else
            self:drawTextCentre("X",exp.x,exp.y-6,0,0,0,1,UIFont.Small)
        end
    end

    for _,p in ipairs(self.particles) do
        local alpha=p.life/p.maxLife
        self:drawRect(p.x,p.y,p.size,p.size,alpha,p.color.r,p.color.g,p.color.b)
    end

    if self.slowdownActive then
        local timeLeft=math.ceil(self.slowdownTimer/60)
        self:drawText("SLOWDOWN "..timeLeft.."s",self.width-GRID_PADDING.right-140,self.height-GRID_PADDING.bottom+10,0.2,0.9,1,1,UIFont.Small)
    end
    if self.fortressActive then
        local timeLeft=math.ceil(self.fortressTimer/60)
        self:drawText("FORTRESS "..timeLeft.."s",self.width-GRID_PADDING.right-140,self.height-GRID_PADDING.bottom+26,0.2,0.9,1,1,UIFont.Small)
    end

    if self.placementMode then
        self:drawTextCentre("PLACEMENT MODE ACTIVE",self.width/2,originY-44,0.25,1,0.25,1,UIFont.Medium)
    end

    if self.resultProcessed then
        local msg=self.coreHP>0 and "SYSTEM DEFENDED" or "CORE BREACHED"
        self:drawTextCentre(msg,self.width/2,self.height/2-24,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large)
        self:drawTextCentre("Neutralized: "..self.killCount,self.width/2,self.height/2+6,THEME.combo_text.r,THEME.combo_text.g,THEME.combo_text.b,THEME.combo_text.a,UIFont.Small)
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
