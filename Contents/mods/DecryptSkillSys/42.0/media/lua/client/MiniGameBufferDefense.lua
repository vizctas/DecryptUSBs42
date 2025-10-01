-- MiniGameBufferDefense.lua - Buffer Overflow Defender Minigame
-- Simplified tower defense where players place firewalls to stop exploits

print("[DecryptSkillSys] Loading MiniGameBufferDefense.lua - Buffer Overflow Defender system")

function ReloadMiniGameBufferDefense() print("[DEBUG] Reloading BufferDefense..."); package.loaded["client/MiniGameBufferDefense"]=nil; pcall(require,"client/MiniGameBufferDefense") end
function TestBufferDefense(diff) diff=diff or "Easy"; if _G.MiniGame_BufferDefense then return _G.MiniGame_BufferDefense(nil,nil,"TestBuffer",diff,nil,{skill="TestBuffer"}) end end

-- CONFIG
local W_PCT,H_PCT=40,58
local LANE_COUNTS={Easy=3,Moderate=4,Expert=5}
local WAVE_COUNTS={Easy=3,Moderate=5,Expert=7}
local FIREWALL_BUDGETS={Easy=15,Moderate=12,Expert=10}
local SPAWN_RATES={Easy=120,Moderate=80,Expert=50} -- ticks
local EXPLOIT_SPEEDS={Easy=1,Moderate=1.5,Expert=2}

local THEME={bg={r=0.05,g=0.08,b=0.1,a=0.92},border={r=0.8,g=0.3,b=0.1,a=1},
    lane_bg={r=0.08,g=0.1,b=0.12,a=0.8},core={r=1,g=0.2,b=0.2,a=0.9},
    firewall={r=0.2,g=0.8,b=0.3,a=0.9},exploit={r=0.8,g=0.1,b=0.3,a=0.9},
    text={r=1,g=1,b=1,a=1}}

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
    o.laneCount,o.waveCount,o.budget=LANE_COUNTS[diff] or 3,WAVE_COUNTS[diff] or 3,FIREWALL_BUDGETS[diff] or 15
    o.spawnRate,o.exploitSpeed=SPAWN_RATES[diff] or 120,EXPLOIT_SPEEDS[diff] or 1
    o.firewalls,o.exploits,o.currentWave,o.coreHP={},{},1,100
    o.gameActive,o.resultProcessed,o.placementMode,o.spawnCounter=false,false,false,0
    o.gridCols,o.titleText,o.titleShown,o.titleAcc=8,"BUFFER OVERFLOW DEFENDER",0,0
    return o
end

function MiniGameBufferDefenseWindow:createChildren()
    self.closeButton=ISButton:new(self.width-25,5,20,20,"X",self,self.onClose); self.closeButton:initialise(); self:addChild(self.closeButton)
    self.startButton=ISButton:new((self.width-120)/2,self.height-55,120,45,"START",self,self.onStart)
    self.startButton.borderColor,self.startButton.backgroundColor={r=0.8,g=0.3,b=0.1,a=1},{r=0.15,g=0.08,b=0.05,a=0.9}
    self.startButton.backgroundColorMouseOver={r=0.8,g=0.3,b=0.1,a=0.9}; self.startButton:initialise(); self:addChild(self.startButton)
    
    self.placeButton=ISButton:new((self.width-120)/2,self.height-105,120,35,"PLACE FIREWALL",self,self.onPlaceMode)
    self.placeButton.borderColor,self.placeButton.backgroundColor={r=0.2,g=0.8,b=0.3,a=1},{r=0.05,g=0.15,b=0.08,a=0.9}
    self.placeButton.backgroundColorMouseOver={r=0.2,g=0.8,b=0.3,a=0.9}; self.placeButton:initialise(); self.placeButton:setVisible(false); self:addChild(self.placeButton)
    
    self.buttons={}; local laneH=(self.height-200)/self.laneCount; local cellW=(self.width-80)/self.gridCols
    for lane=1,self.laneCount do self.buttons[lane]={}
        for col=1,self.gridCols do
            local btn=ISButton:new(60+(col-1)*cellW,80+(lane-1)*laneH,cellW-2,laneH-2,"",self,self.onCellClick)
            btn.lane,btn.col=lane,col; btn:initialise(); btn:setVisible(false); self:addChild(btn); self.buttons[lane][col]=btn
        end
    end
end

function MiniGameBufferDefenseWindow:onStart()
    self.gameActive,self.currentWave,self.coreHP,self.budget,self.firewalls,self.exploits=true,1,100,FIREWALL_BUDGETS[self.difficulty] or 15,{},{}
    self.startButton:setVisible(false); self.placeButton:setVisible(true)
    for lane=1,self.laneCount do for col=1,self.gridCols do self.buttons[lane][col]:setVisible(true) end end
    self:startSpawner(); self:playSound("UI_Menu_OS_Start")
end

function MiniGameBufferDefenseWindow:onPlaceMode() self.placementMode=not self.placementMode; self:playSound("UI_Menu_OS_Select") end

function MiniGameBufferDefenseWindow:onCellClick(btn)
    if not self.gameActive or not self.placementMode or self.budget<=0 then return end
    local key=btn.lane..","..btn.col
    if not self.firewalls[key] then
        self.firewalls[key]={lane=btn.lane,col=btn.col,hp=3}; self.budget=self.budget-1; self:playSound("UI_Menu_OS_Select")
    end
end

function MiniGameBufferDefenseWindow:startSpawner()
    self:cancelTimer("spawnerId")
    self.spawnerId=SimpleTimer:addTimer(1,function()
        if not self.gameActive then return end; self.spawnCounter=self.spawnCounter+1
        if self.spawnCounter>=self.spawnRate then
            if #self.exploits<self.currentWave*2 then local lane=ZombRand(1,self.laneCount+1); table.insert(self.exploits,{lane=lane,x=self.width-70,hp=1}) end
            self.spawnCounter=0
        end
        self:startSpawner()
    end)
end

function MiniGameBufferDefenseWindow:cancelTimer(f) if f and self[f] then SimpleTimer:removeTimer(self[f]); self[f]=nil end end
function MiniGameBufferDefenseWindow:onClose() if self.gameActive then self:processFinalResult(false) end; self:cancelTimer("spawnerId"); self:setVisible(false); self:removeFromUIManager() end

function MiniGameBufferDefenseWindow:update()
    ISPanel.update(self); if not self.gameActive then return end
    
    -- Move exploits
    local cellW=(self.width-80)/self.gridCols
    for i=#self.exploits,1,-1 do
        local exp=self.exploits[i]; exp.x=exp.x-self.exploitSpeed
        
        -- Check collision with firewalls
        local col=math.floor((exp.x-60)/cellW)+1
        if col>=1 and col<=self.gridCols then
            local key=exp.lane..","..col
            if self.firewalls[key] then
                self.firewalls[key].hp=self.firewalls[key].hp-1; exp.hp=0
                if self.firewalls[key].hp<=0 then self.firewalls[key]=nil end
            end
        end
        
        -- Check if reached core
        if exp.x<40 then self.coreHP=self.coreHP-10; exp.hp=0; self:playSound("UI_Menu_OS_Failure") end
        
        -- Remove dead exploits
        if exp.hp<=0 then table.remove(self.exploits,i) end
    end
    
    -- Check win/lose
    if self.coreHP<=0 then self:processFinalResult(false)
    elseif #self.exploits==0 and self.spawnCounter>self.spawnRate then
        self.currentWave=self.currentWave+1
        if self.currentWave>self.waveCount then self:processFinalResult(true) else self.spawnCounter=0 end
    end
end

function MiniGameBufferDefenseWindow:processFinalResult(success)
    if self.resultProcessed then return end; self.resultProcessed,self.gameActive=true,false; self:cancelTimer("spawnerId")
    if not success and self.laptopItem then if isClient() then sendClientCommand(self.player,"GVDrive","IncrementFailureCount",{laptop=self.laptopItem})
        elseif LaptopSystem and LaptopSystem.incrementFailureCount then LaptopSystem.incrementFailureCount(self.laptopItem) end
    end
    if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then GVDrive_Utils.applyMinigameResult(self.player,self.laptopItem,self.usbType,self.difficulty,success) end
    self:playSound(success and "UI_Menu_OS_Success" or "UI_Menu_OS_Failure"); SimpleTimer:addTimer(120,function() self:onClose() end)
end

function MiniGameBufferDefenseWindow:playSound(snd) if self.player and snd then if self.player.playSoundLocal then self.player:playSoundLocal(snd) elseif getPlayer() then getPlayer():playSoundLocal(snd) end end end

function MiniGameBufferDefenseWindow:render()
    ISPanel.render(self)
    if self.gameActive and self.titleShown<#self.titleText then self.titleAcc=self.titleAcc+1; if self.titleAcc>=3 then self.titleAcc=0; self.titleShown=self.titleShown+1 end
    elseif not self.gameActive then self.titleShown=#self.titleText end
    self:drawTextCentre(string.sub(self.titleText,1,self.titleShown),self.width/2,10,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large)
    
    if self.gameActive then
        self:drawText("WAVE: "..self.currentWave.."/"..self.waveCount,10,35,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)
        self:drawText("BUDGET: "..self.budget,self.width-120,35,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)
        self:drawText("CORE HP: "..self.coreHP.."%",self.width/2-50,35,self.coreHP>50 and THEME.text.r or 1,self.coreHP>50 and THEME.text.g or 0.2,self.coreHP>50 and THEME.text.b or 0.2,THEME.text.a,UIFont.Small)
        
        -- Draw lanes
        local laneH=(self.height-200)/self.laneCount
        for lane=1,self.laneCount do
            local y=80+(lane-1)*laneH
            self:drawRect(60,y,self.width-120,laneH,THEME.lane_bg.a,THEME.lane_bg.r,THEME.lane_bg.g,THEME.lane_bg.b)
        end
        
        -- Draw core
        self:drawRect(10,80,40,self.height-200,THEME.core.a,THEME.core.r,THEME.core.g,THEME.core.b)
        self:drawTextCentre("CORE",30,self.height/2,0,0,0,1,UIFont.Small)
        
        -- Draw firewalls
        local cellW=(self.width-80)/self.gridCols
        for key,fw in pairs(self.firewalls) do
            local x,y=60+(fw.col-1)*cellW,80+(fw.lane-1)*laneH
            self:drawRect(x,y,cellW-2,laneH-2,THEME.firewall.a,THEME.firewall.r,THEME.firewall.g,THEME.firewall.b)
            self:drawTextCentre("FW"..fw.hp,x+cellW/2,y+laneH/2-8,0,0,0,1,UIFont.Small)
        end
        
        -- Draw exploits
        for _,exp in ipairs(self.exploits) do
            local y=80+(exp.lane-1)*laneH+laneH/2
            self:drawRect(exp.x-10,y-10,20,20,THEME.exploit.a,THEME.exploit.r,THEME.exploit.g,THEME.exploit.b)
            self:drawTextCentre("X",exp.x,y-8,1,1,1,1,UIFont.Small)
        end
        
        if self.placementMode then self:drawTextCentre("PLACEMENT MODE ACTIVE",self.width/2,55,0.2,1,0.2,1,UIFont.Medium) end
    else if self.resultProcessed then
        local msg=self.coreHP>0 and "SYSTEM DEFENDED!" or "CORE BREACHED!"
        self:drawTextCentre(msg,self.width/2,self.height/2,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large)
    end end
end

function MiniGame_BufferDefense(widthPct,heightPct,usbType,difficulty,laptopItem,usbData)
    local player=getPlayer(); if not player then return end; local screenW,screenH=getCore():getScreenWidth(),getCore():getScreenHeight()
    local width,height=math.floor(screenW*(W_PCT/100)),math.floor(screenH*(H_PCT/100)); local x,y=(screenW-width)/2,(screenH-height)/2
    local win=MiniGameBufferDefenseWindow:new(x,y,width,height,player,usbType,difficulty,laptopItem,usbData)
    win:initialise(); win:addToUIManager(); win:bringToTop(); return win
end
