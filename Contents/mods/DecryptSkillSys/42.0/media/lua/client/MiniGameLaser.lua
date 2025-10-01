-- MiniGameLaser.lua - Laser Grid Deflector Minigame
-- Spatial puzzle with mirror rotation and laser raytracing
-- Inspired by BioShock hacking and laser puzzle games

print("[DecryptSkillSys] Loading MiniGameLaser.lua - Laser Grid Deflector system")

-- DEBUG FUNCTIONS
function ReloadMiniGameLaser()
    print("[DEBUG] Reloading MiniGameLaser..."); package.loaded["client/MiniGameLaser"] = nil
    local ok, res = pcall(require, "client/MiniGameLaser")
    print(ok and "[DEBUG] MiniGameLaser reloaded!" or "[DEBUG] Failed: " .. tostring(res))
end
function TestLaserDeflector(diff)
    diff = diff or "Easy"; print("[DEBUG] Testing MiniGameLaser: " .. diff)
    if _G.MiniGame_Laser then return _G.MiniGame_Laser(nil, nil, "TestLaser", diff, nil, {skill="TestLaser", difficulty_english=diff}) end
end

-- CONFIGURATION
local W_PCT, H_PCT = 35, 55
local GRID_SIZES = {Easy=5, Moderate=6, Expert=7}
local TIME_LIMITS = {Easy=90, Moderate=75, Expert=60}
local MIRROR_COUNTS = {Easy=3, Moderate=5, Expert=7}
local BLOCKER_COUNTS = {Easy=1, Moderate=3, Expert=5}
local MAX_BOUNCES = {Easy=15, Moderate=12, Expert=10}

local THEME = {
    bg = {r=0.05,g=0.05,b=0.15,a=0.9},
    border = {r=1,g=0.2,b=0.2,a=1}, -- Red laser
    cell_empty = {r=0.1,g=0.1,b=0.2,a=0.8},
    cell_mirror = {r=0.3,g=0.3,b=0.5,a=0.9},
    cell_blocker = {r=0.5,g=0.1,b=0.1,a=0.9},
    laser_beam = {r=1,g=0.1,b=0.1,a=1},
    laser_glow = {r=1,g=0.3,b=0.3,a=0.3},
    start_node = {r=0.1,g=1,b=0.1,a=1},
    end_node = {r=1,g=0.2,b=0.2,a=1},
    text = {r=1,g=1,b=1,a=1},
}

-- TIMER SYSTEM
local SimpleTimer = {activeTimers={}, nextId=1}
function SimpleTimer:addTimer(dur, cb) local id=self.nextId; self.nextId=id+1; self.activeTimers[id]={callback=cb,duration=dur,elapsed=0}; return id end
function SimpleTimer:removeTimer(id) self.activeTimers[id]=nil end
function SimpleTimer:update()
    local rm={}; for id,t in pairs(self.activeTimers) do t.elapsed=t.elapsed+1
    if t.elapsed>=t.duration then if t.callback then pcall(t.callback) end; rm[id]=true end end
    for id in pairs(rm) do self.activeTimers[id]=nil end
end
if Events and Events.OnTick then Events.OnTick.Add(function() SimpleTimer:update() end) end

-- WINDOW
local MiniGameLaserWindow = ISPanel:derive("MiniGameLaserWindow")

function MiniGameLaserWindow:new(x,y,w,h,player,usbType,diff,laptop,usbData)
    local o=ISPanel:new(x,y,w,h); setmetatable(o,self); self.__index=self
    o.player,o.usbType,o.difficulty,o.laptopItem,o.usbData=player,usbType,diff,laptop,usbData
    o.backgroundColor,o.borderColor,o.moveWithMouse=THEME.bg,THEME.border,true
    o.gridSize,o.timeLimit=GRID_SIZES[diff] or 5, TIME_LIMITS[diff] or 90
    o.mirrorCount,o.blockerCount=MIRROR_COUNTS[diff] or 3, BLOCKER_COUNTS[diff] or 1
    o.maxBounces=MAX_BOUNCES[diff] or 15
    o.timeLeft,o.gameActive,o.resultProcessed=o.timeLimit,false,false
    o.grid,o.buttons,o.laserPath={},{},{}
    o.startNode,o.endNode={x=1,y=math.ceil(o.gridSize/2)},{x=o.gridSize,y=math.ceil(o.gridSize/2)}
    o.titleText,o.titleShown,o.titleAcc="LASER DEFLECTOR",0,0
    o:generateGrid(); return o
end

function MiniGameLaserWindow:generateGrid()
    for y=1,self.gridSize do self.grid[y]={}
        for x=1,self.gridSize do self.grid[y][x]={type="empty",rotation=0,clickAnim=0} end
    end
    -- Place mirrors
    local placed=0; while placed<self.mirrorCount do
        local x,y=ZombRand(2,self.gridSize),ZombRand(2,self.gridSize)
        if self.grid[y][x].type=="empty" then
            self.grid[y][x]={type="mirror",rotation=ZombRand(4),clickAnim=0}; placed=placed+1
        end
    end
    -- Place blockers
    placed=0; while placed<self.blockerCount do
        local x,y=ZombRand(2,self.gridSize),ZombRand(2,self.gridSize)
        if self.grid[y][x].type=="empty" then
            self.grid[y][x]={type="blocker",rotation=0,clickAnim=0}; placed=placed+1
        end
    end
end

function MiniGameLaserWindow:traceLaser()
    self.laserPath={}
    local x,y,dx,dy=self.startNode.x,self.startNode.y,1,0
    local bounces=0
    while bounces<self.maxBounces do
        table.insert(self.laserPath,{x=x,y=y})
        x,y=x+dx,y+dy
        if x<1 or x>self.gridSize or y<1 or y>self.gridSize then break end
        local cell=self.grid[y][x]
        if cell.type=="blocker" then break end
        if cell.type=="mirror" then
            bounces=bounces+1
            -- Mirror rotation: 0=/, 1=\, 2=|, 3=-
            if cell.rotation==0 then dx,dy=-dy,-dx -- /
            elseif cell.rotation==1 then dx,dy=dy,dx -- \
            elseif cell.rotation==2 then dy=-dy -- |
            else dx=-dx end -- -
        end
        if x==self.endNode.x and y==self.endNode.y then return true end
    end
    return false
end

function MiniGameLaserWindow:createChildren()
    self.closeButton=ISButton:new(self.width-25,5,20,20,"X",self,self.onClose)
    self.closeButton:initialise(); self:addChild(self.closeButton)
    
    self.startButton=ISButton:new((self.width-120)/2,self.height-55,120,45,"START",self,self.onStart)
    self.startButton.borderColor,self.startButton.backgroundColor={r=1,g=0.2,b=0.2,a=1},{r=0.2,g=0.05,b=0.05,a=0.9}
    self.startButton.backgroundColorMouseOver={r=1,g=0.2,b=0.2,a=0.9}
    self.startButton:initialise(); self:addChild(self.startButton)
    
    local cellSize=math.floor(math.min(self.width-60,self.height-160)/self.gridSize)
    local gx,gy=(self.width-cellSize*self.gridSize)/2, 70
    for y=1,self.gridSize do self.buttons[y]={}
        for x=1,self.gridSize do
            local btn=ISButton:new(gx+(x-1)*cellSize,gy+(y-1)*cellSize,cellSize,cellSize,"",self,self.onCellClick)
            btn.gridX,btn.gridY=x,y; btn:initialise(); self:addChild(btn); self.buttons[y][x]=btn
        end
    end
end

function MiniGameLaserWindow:onStart()
    self.gameActive,self.timeLeft,self.resultProcessed=true,self.timeLimit,false
    self.startButton:setVisible(false); self:startTimer(); self:playSound("UI_Menu_OS_Start")
end

function MiniGameLaserWindow:onCellClick(btn)
    if not self.gameActive then return end
    local cell=self.grid[btn.gridY][btn.gridX]
    if cell.type=="mirror" then cell.rotation=(cell.rotation+1)%4; cell.clickAnim=1.0
        if self:traceLaser() then self:processFinalResult(true) end
        self:playSound("UI_Menu_OS_Select")
    end
end

function MiniGameLaserWindow:cancelTimer(field)
    if field and self[field] then SimpleTimer:removeTimer(self[field]); self[field]=nil end
end

function MiniGameLaserWindow:startTimer()
    self:cancelTimer("timerId")
    self.timerId=SimpleTimer:addTimer(60,function()
        if not self.gameActive then return end
        self.timeLeft=self.timeLeft-1
        if self.timeLeft<=0 then self:onTimeUp() else self:startTimer() end
    end)
end

function MiniGameLaserWindow:onTimeUp()
    self.gameActive=false; self:playSound("UI_Menu_OS_Exit"); self:processFinalResult(false)
end

function MiniGameLaserWindow:onClose()
    if self.gameActive then self:processFinalResult(false) end
    self:cancelTimer("timerId"); self:setVisible(false); self:removeFromUIManager()
end

function MiniGameLaserWindow:processFinalResult(success)
    if self.resultProcessed then return end
    self.resultProcessed,self.gameActive=true,false; self:cancelTimer("timerId")
    if not success and self.laptopItem then
        if isClient() then sendClientCommand(self.player,"GVDrive","IncrementFailureCount",{laptop=self.laptopItem})
        elseif LaptopSystem and LaptopSystem.incrementFailureCount then LaptopSystem.incrementFailureCount(self.laptopItem) end
    end
    if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then
        GVDrive_Utils.applyMinigameResult(self.player,self.laptopItem,self.usbType,self.difficulty,success)
    end
    self:playSound(success and "UI_Menu_OS_Success" or "UI_Menu_OS_Failure")
    SimpleTimer:addTimer(120,function() self:onClose() end)
end

function MiniGameLaserWindow:playSound(snd)
    if self.player and snd then
        if self.player.playSoundLocal then self.player:playSoundLocal(snd)
        elseif getPlayer() and getPlayer().playSoundLocal then getPlayer():playSoundLocal(snd)
        else local sm=getSoundManager(); if sm and sm.playUISound then pcall(function() sm:playUISound(snd) end) end end
    end
end

function MiniGameLaserWindow:render()
    ISPanel.render(self)
    if self.gameActive and self.titleShown<#self.titleText then
        self.titleAcc=self.titleAcc+1; if self.titleAcc>=3 then self.titleAcc=0; self.titleShown=self.titleShown+1 end
    elseif not self.gameActive then self.titleShown=#self.titleText end
    
    local title=string.sub(self.titleText,1,self.titleShown)
    self:drawTextCentre(title,self.width/2,10,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large)
    
    if self.gameActive then
        self:drawText("TIME: "..math.ceil(self.timeLeft).."s",10,35,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)
        
        -- Draw grid cells
        for y=1,self.gridSize do for x=1,self.gridSize do
            local btn,cell=self.buttons[y][x],self.grid[y][x]
            if cell.clickAnim>0 then cell.clickAnim=math.max(0,cell.clickAnim-0.1) end
            local bx,by,bw,bh=btn:getX(),btn:getY(),btn:getWidth(),btn:getHeight()
            
            -- Cell background
            local clr=THEME.cell_empty
            if cell.type=="mirror" then clr=THEME.cell_mirror
            elseif cell.type=="blocker" then clr=THEME.cell_blocker end
            self:drawRect(bx,by,bw,bh,clr.a,clr.r,clr.g,clr.b)
            
            -- Draw mirror symbol
            if cell.type=="mirror" then
                local symbols={"/","\\","|","-"}
                self:drawTextCentre(symbols[cell.rotation+1] or "/",bx+bw/2,by+bh/2-8,1,1,1,1,UIFont.Large)
            elseif cell.type=="blocker" then
                self:drawTextCentre("█",bx+bw/2,by+bh/2-8,0.8,0.1,0.1,1,UIFont.Large)
            end
            
            -- Start/End markers
            if x==self.startNode.x and y==self.startNode.y then
                self:drawRect(bx+2,by+2,bw-4,bh-4,0.5,THEME.start_node.r,THEME.start_node.g,THEME.start_node.b)
            elseif x==self.endNode.x and y==self.endNode.y then
                self:drawRect(bx+2,by+2,bw-4,bh-4,0.5,THEME.end_node.r,THEME.end_node.g,THEME.end_node.b)
            end
        end end
        
        -- Draw laser beam
        self:traceLaser()
        if #self.laserPath>1 then
            for i=1,#self.laserPath-1 do
                local p1,p2=self.laserPath[i],self.laserPath[i+1]
                local btn1,btn2=self.buttons[p1.y][p1.x],self.buttons[p2.y][p2.x]
                local x1,y1=btn1:getX()+btn1:getWidth()/2,btn1:getY()+btn1:getHeight()/2
                local x2,y2=btn2:getX()+btn2:getWidth()/2,btn2:getY()+btn2:getHeight()/2
                -- Glow effect
                self:drawLine(x1,y1,x2,y2,THEME.laser_glow.a,THEME.laser_glow.r,THEME.laser_glow.g,THEME.laser_glow.b)
                -- Core beam
                self:drawLine(x1,y1,x2,y2,THEME.laser_beam.a,THEME.laser_beam.r,THEME.laser_beam.g,THEME.laser_beam.b)
            end
        end
    end
end

function drawLine(self,x1,y1,x2,y2,a,r,g,b)
    local steps=math.max(math.abs(x2-x1),math.abs(y2-y1))
    if steps==0 then return end
    for i=0,steps do
        local t=i/steps; local x,y=x1+t*(x2-x1),y1+t*(y2-y1)
        self:drawRect(x,y,2,2,a,r,g,b)
    end
end
MiniGameLaserWindow.drawLine=drawLine

-- GLOBAL FUNCTION
function MiniGame_Laser(widthPct,heightPct,usbType,difficulty,laptopItem,usbData)
    local player=getPlayer(); if not player then return end
    local screenW,screenH=getCore():getScreenWidth(),getCore():getScreenHeight()
    local width,height=math.floor(screenW*(W_PCT/100)),math.floor(screenH*(H_PCT/100))
    local x,y=(screenW-width)/2,(screenH-height)/2
    local win=MiniGameLaserWindow:new(x,y,width,height,player,usbType,difficulty,laptopItem,usbData)
    win:initialise(); win:addToUIManager(); win:bringToTop(); return win
end
