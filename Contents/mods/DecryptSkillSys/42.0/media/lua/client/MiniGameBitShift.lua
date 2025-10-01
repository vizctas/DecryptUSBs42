-- MiniGameBitShift.lua - Bit Shifter Puzzle Minigame
-- Binary logic puzzle inspired by Lights Out where clicks affect neighbors

print("[DecryptSkillSys] Loading MiniGameBitShift.lua - Bit Shifter system")

function ReloadMiniGameBitShift() print("[DEBUG] Reloading BitShift..."); package.loaded["client/MiniGameBitShift"]=nil; pcall(require,"client/MiniGameBitShift") end
function TestBitShift(diff) diff=diff or "Easy"; if _G.MiniGame_BitShift then return _G.MiniGame_BitShift(nil,nil,"TestBit",diff,nil,{skill="TestBit"}) end end

-- CONFIG
local W_PCT,H_PCT=30,52
local GRID_SIZES={Easy=4,Moderate=5,Expert=6}
local MOVE_LIMITS={Easy=20,Moderate=15,Expert=10}
local TIME_LIMITS={Easy=90,Moderate=75,Expert=60}
local OPERATIONS={Easy="XOR",Moderate="XOR",Expert="XOR"} -- XOR flips neighbors
local AFFECT_PATTERNS={Easy="cross",Moderate="cross",Expert="cross_center"} -- cross: ↑↓←→, cross_center: ↑↓←→+self

local THEME={bg={r=0.08,g=0.08,b=0.12,a=0.92},border={r=0.2,g=0.8,b=1,a=1},
    bit_0={r=0.1,g=0.1,b=0.15,a=0.95},bit_1={r=0.2,g=0.8,b=1,a=0.95},
    text={r=1,g=1,b=1,a=1},grid_line={r=0.3,g=0.3,b=0.4,a=0.5}}

local SimpleTimer={activeTimers={},nextId=1}
function SimpleTimer:addTimer(dur,cb) local id=self.nextId; self.nextId=id+1; self.activeTimers[id]={callback=cb,duration=dur,elapsed=0}; return id end
function SimpleTimer:removeTimer(id) self.activeTimers[id]=nil end
function SimpleTimer:update() local rm={}; for id,t in pairs(self.activeTimers) do t.elapsed=t.elapsed+1; if t.elapsed>=t.duration then if t.callback then pcall(t.callback) end; rm[id]=true end end; for id in pairs(rm) do self.activeTimers[id]=nil end end
if Events and Events.OnTick then Events.OnTick.Add(function() SimpleTimer:update() end) end

local MiniGameBitShiftWindow=ISPanel:derive("MiniGameBitShiftWindow")

function MiniGameBitShiftWindow:new(x,y,w,h,player,usbType,diff,laptop,usbData)
    local o=ISPanel:new(x,y,w,h); setmetatable(o,self); self.__index=self
    o.player,o.usbType,o.difficulty,o.laptopItem,o.usbData=player,usbType,diff,laptop,usbData
    o.backgroundColor,o.borderColor,o.moveWithMouse=THEME.bg,THEME.border,true
    o.gridSize,o.moveLimit,o.timeLimit=GRID_SIZES[diff] or 4,MOVE_LIMITS[diff] or 20,TIME_LIMITS[diff] or 90
    o.operation,o.pattern=OPERATIONS[diff] or "XOR",AFFECT_PATTERNS[diff] or "cross"
    o.grid,o.solution,o.movesLeft,o.timeLeft,o.gameActive,o.resultProcessed={},{},o.moveLimit,o.timeLimit,false,false
    o.titleText,o.titleShown,o.titleAcc="BIT SHIFTER",0,0
    o:generatePuzzle(); return o
end

function MiniGameBitShiftWindow:generatePuzzle()
    -- Start with all 1s (target state)
    for y=1,self.gridSize do self.grid[y]={} self.solution[y]={}
        for x=1,self.gridSize do self.grid[y][x]=1; self.solution[y][x]=1 end
    end
    -- Work backwards: apply random clicks to scramble
    local scrambles=self.moveLimit-5
    for i=1,scrambles do
        local x,y=ZombRand(1,self.gridSize+1),ZombRand(1,self.gridSize+1)
        self:applyClick(x,y,self.grid)
    end
end

function MiniGameBitShiftWindow:applyClick(x,y,grid)
    local dirs={{0,-1},{0,1},{-1,0},{1,0}} -- up,down,left,right
    if self.pattern=="cross_center" then
        grid[y][x]=1-grid[y][x] -- toggle self
    end
    for _,d in ipairs(dirs) do
        local nx,ny=x+d[1],y+d[2]
        if nx>=1 and nx<=self.gridSize and ny>=1 and ny<=self.gridSize then
            grid[ny][nx]=1-grid[ny][nx] -- XOR toggle
        end
    end
end

function MiniGameBitShiftWindow:checkWin()
    for y=1,self.gridSize do for x=1,self.gridSize do
        if self.grid[y][x]~=self.solution[y][x] then return false end
    end end
    return true
end

function MiniGameBitShiftWindow:createChildren()
    self.closeButton=ISButton:new(self.width-25,5,20,20,"X",self,self.onClose); self.closeButton:initialise(); self:addChild(self.closeButton)
    self.startButton=ISButton:new((self.width-120)/2,self.height-55,120,45,"START",self,self.onStart)
    self.startButton.borderColor,self.startButton.backgroundColor={r=0.2,g=0.8,b=1,a=1},{r=0.05,g=0.1,b=0.2,a=0.9}
    self.startButton.backgroundColorMouseOver={r=0.2,g=0.8,b=1,a=0.9}; self.startButton:initialise(); self:addChild(self.startButton)
    
    self.buttons={}; local cellSize=math.floor(math.min(self.width-60,self.height-180)/self.gridSize); local gx,gy=(self.width-cellSize*self.gridSize)/2,80
    for y=1,self.gridSize do self.buttons[y]={}
        for x=1,self.gridSize do local btn=ISButton:new(gx+(x-1)*cellSize,gy+(y-1)*cellSize,cellSize,cellSize,"",self,self.onCellClick)
            btn.gridX,btn.gridY=x,y; btn:initialise(); self:addChild(btn); self.buttons[y][x]=btn
        end
    end
end

function MiniGameBitShiftWindow:onStart()
    self.gameActive,self.timeLeft,self.movesLeft=true,self.timeLimit,self.moveLimit
    self.startButton:setVisible(false); self:startTimer(); self:playSound("UI_Menu_OS_Start")
end

function MiniGameBitShiftWindow:onCellClick(btn)
    if not self.gameActive or self.movesLeft<=0 then return end
    self:applyClick(btn.gridX,btn.gridY,self.grid); self.movesLeft=self.movesLeft-1
    if self:checkWin() then self:processFinalResult(true)
    elseif self.movesLeft<=0 then self:processFinalResult(false) end
    self:playSound("UI_Menu_OS_Select")
end

function MiniGameBitShiftWindow:cancelTimer(f) if f and self[f] then SimpleTimer:removeTimer(self[f]); self[f]=nil end end
function MiniGameBitShiftWindow:startTimer() self:cancelTimer("timerId"); self.timerId=SimpleTimer:addTimer(60,function() if not self.gameActive then return end; self.timeLeft=self.timeLeft-1; if self.timeLeft<=0 then self:onTimeUp() else self:startTimer() end end) end
function MiniGameBitShiftWindow:onTimeUp() self.gameActive=false; self:playSound("UI_Menu_OS_Exit"); self:processFinalResult(false) end
function MiniGameBitShiftWindow:onClose() if self.gameActive then self:processFinalResult(false) end; self:cancelTimer("timerId"); self:setVisible(false); self:removeFromUIManager() end

function MiniGameBitShiftWindow:processFinalResult(success)
    if self.resultProcessed then return end; self.resultProcessed,self.gameActive=true,false; self:cancelTimer("timerId")
    if not success and self.laptopItem then if isClient() then sendClientCommand(self.player,"GVDrive","IncrementFailureCount",{laptop=self.laptopItem})
        elseif LaptopSystem and LaptopSystem.incrementFailureCount then LaptopSystem.incrementFailureCount(self.laptopItem) end
    end
    if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then GVDrive_Utils.applyMinigameResult(self.player,self.laptopItem,self.usbType,self.difficulty,success) end
    self:playSound(success and "UI_Menu_OS_Success" or "UI_Menu_OS_Failure"); SimpleTimer:addTimer(120,function() self:onClose() end)
end

function MiniGameBitShiftWindow:playSound(snd) if self.player and snd then if self.player.playSoundLocal then self.player:playSoundLocal(snd) elseif getPlayer() then getPlayer():playSoundLocal(snd) end end end

function MiniGameBitShiftWindow:render()
    ISPanel.render(self)
    if self.gameActive and self.titleShown<#self.titleText then self.titleAcc=self.titleAcc+1; if self.titleAcc>=3 then self.titleAcc=0; self.titleShown=self.titleShown+1 end
    elseif not self.gameActive then self.titleShown=#self.titleText end
    self:drawTextCentre(string.sub(self.titleText,1,self.titleShown),self.width/2,10,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large)
    
    if self.gameActive then
        self:drawText("TIME: "..math.ceil(self.timeLeft).."s",10,35,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)
        self:drawText("MOVES: "..self.movesLeft,self.width-120,35,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)
        self:drawTextCentre("TARGET: ALL ONES",self.width/2,55,0.8,0.8,0.8,1,UIFont.Small)
        
        for y=1,self.gridSize do for x=1,self.gridSize do
            local btn,bit=self.buttons[y][x],self.grid[y][x]
            local bx,by,bw,bh=btn:getX(),btn:getY(),btn:getWidth(),btn:getHeight()
            local clr=bit==1 and THEME.bit_1 or THEME.bit_0
            self:drawRect(bx,by,bw,bh,clr.a,clr.r,clr.g,clr.b)
            self:drawRectBorder(bx,by,bw,bh,THEME.grid_line.a,THEME.grid_line.r,THEME.grid_line.g,THEME.grid_line.b)
            self:drawTextCentre(tostring(bit),bx+bw/2,by+bh/2-10,0,0,0,1,UIFont.Large)
        end end
    else if self.resultProcessed then
        local msg=self:checkWin() and "PATTERN SOLVED!" or "PATTERN FAILED"
        self:drawTextCentre(msg,self.width/2,self.height/2,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large)
    end end
end

function MiniGame_BitShift(widthPct,heightPct,usbType,difficulty,laptopItem,usbData)
    local player=getPlayer(); if not player then return end; local screenW,screenH=getCore():getScreenWidth(),getCore():getScreenHeight()
    local width,height=math.floor(screenW*(W_PCT/100)),math.floor(screenH*(H_PCT/100)); local x,y=(screenW-width)/2,(screenH-height)/2
    local win=MiniGameBitShiftWindow:new(x,y,width,height,player,usbType,difficulty,laptopItem,usbData)
    win:initialise(); win:addToUIManager(); win:bringToTop(); return win
end
