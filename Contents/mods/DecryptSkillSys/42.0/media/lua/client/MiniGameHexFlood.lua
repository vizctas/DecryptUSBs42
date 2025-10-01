-- MiniGameHexFlood.lua - Hexadecimal Flood Minigame
-- Match-3 puzzle with rising hex symbols, inspired by Tetris Attack and Panel de Pon

print("[DecryptSkillSys] Loading MiniGameHexFlood.lua - Hexadecimal Flood system")

function ReloadMiniGameHexFlood() print("[DEBUG] Reloading HexFlood..."); package.loaded["client/MiniGameHexFlood"]=nil; pcall(require,"client/MiniGameHexFlood") end
function TestHexFlood(diff) diff=diff or "Easy"; if _G.MiniGame_HexFlood then return _G.MiniGame_HexFlood(nil,nil,"TestHex",diff,nil,{skill="TestHex"}) end end

-- CONFIG
local W_PCT,H_PCT=28,58
local GRID_W,GRID_H=6,{Easy=8,Moderate=10,Expert=12}
local RISE_SPEEDS={Easy=180,Moderate=120,Expert=80} -- ticks
local TIME_LIMITS={Easy=90,Moderate=75,Expert=60}
local MATCH_SIZES={Easy=3,Moderate=4,Expert=5}
local HEX_SYMBOLS={"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}

local THEME={bg={r=0.05,g=0.1,b=0.05,a=0.9},border={r=0.2,g=1,b=0.2,a=1},cell={r=0.12,g=0.12,b=0.15,a=0.9},
    hex_0={r=0.8,g=0.2,b=0.2,a=1},hex_1={r=0.2,g=0.8,b=0.2,a=1},hex_2={r=0.2,g=0.2,b=0.8,a=1},
    hex_3={r=0.8,g=0.8,b=0.2,a=1},hex_4={r=0.8,g=0.2,b=0.8,a=1},hex_5={r=0.2,g=0.8,b=0.8,a=1},
    text={r=1,g=1,b=1,a=1}}

local SimpleTimer={activeTimers={},nextId=1}
function SimpleTimer:addTimer(dur,cb) local id=self.nextId; self.nextId=id+1; self.activeTimers[id]={callback=cb,duration=dur,elapsed=0}; return id end
function SimpleTimer:removeTimer(id) self.activeTimers[id]=nil end
function SimpleTimer:update() local rm={}; for id,t in pairs(self.activeTimers) do t.elapsed=t.elapsed+1; if t.elapsed>=t.duration then if t.callback then pcall(t.callback) end; rm[id]=true end end; for id in pairs(rm) do self.activeTimers[id]=nil end end
if Events and Events.OnTick then Events.OnTick.Add(function() SimpleTimer:update() end) end

local MiniGameHexFloodWindow=ISPanel:derive("MiniGameHexFloodWindow")

function MiniGameHexFloodWindow:new(x,y,w,h,player,usbType,diff,laptop,usbData)
    local o=ISPanel:new(x,y,w,h); setmetatable(o,self); self.__index=self
    o.player,o.usbType,o.difficulty,o.laptopItem,o.usbData=player,usbType,diff,laptop,usbData
    o.backgroundColor,o.borderColor,o.moveWithMouse=THEME.bg,THEME.border,true
    o.gridH,o.riseSpeed,o.timeLimit=GRID_H[diff] or 8,RISE_SPEEDS[diff] or 180,TIME_LIMITS[diff] or 90
    o.matchSize=MATCH_SIZES[diff] or 3
    o.grid,o.selected,o.timeLeft,o.gameActive,o.resultProcessed,o.score,o.combo={},nil,o.timeLimit,false,false,0,0
    o.riseCounter,o.titleText,o.titleShown,o.titleAcc=0,"HEXADECIMAL FLOOD",0,0
    o:initGrid(); return o
end

function MiniGameHexFloodWindow:initGrid()
    for y=1,self.gridH do self.grid[y]={} for x=1,GRID_W do self.grid[y][x]={symbol=HEX_SYMBOLS[ZombRand(1,9)],marked=false} end end
end

function MiniGameHexFloodWindow:addRow()
    table.remove(self.grid,1); local newRow={}
    for x=1,GRID_W do newRow[x]={symbol=HEX_SYMBOLS[ZombRand(1,#HEX_SYMBOLS+1)],marked=false} end
    table.insert(self.grid,newRow)
end

function MiniGameHexFloodWindow:findMatches()
    for y=1,self.gridH do for x=1,GRID_W do self.grid[y][x].marked=false end end
    local found=false
    -- Horizontal
    for y=1,self.gridH do for x=1,GRID_W-self.matchSize+1 do
        local sym=self.grid[y][x].symbol; local match=true
        for dx=1,self.matchSize-1 do if self.grid[y][x+dx].symbol~=sym then match=false; break end end
        if match then for dx=0,self.matchSize-1 do self.grid[y][x+dx].marked=true end; found=true end
    end end
    -- Vertical
    for x=1,GRID_W do for y=1,self.gridH-self.matchSize+1 do
        local sym=self.grid[y][x].symbol; local match=true
        for dy=1,self.matchSize-1 do if self.grid[y+dy][x].symbol~=sym then match=false; break end end
        if match then for dy=0,self.matchSize-1 do self.grid[y+dy][x].marked=true end; found=true end
    end end
    return found
end

function MiniGameHexFloodWindow:removeMarked()
    local removed=0
    for y=1,self.gridH do for x=1,GRID_W do if self.grid[y][x].marked then self.grid[y][x].symbol=""; removed=removed+1 end end end
    if removed>0 then self.score=self.score+(removed*10*(self.combo+1)); self.combo=self.combo+1; self:playSound("UI_Menu_OS_Select") else self.combo=0 end
    -- Compact grid
    for x=1,GRID_W do local col={}; for y=self.gridH,1,-1 do if self.grid[y][x].symbol~="" then table.insert(col,self.grid[y][x]) end end
        for y=self.gridH,1,-1 do self.grid[y][x]=col[self.gridH-y+1] or {symbol="",marked=false} end
    end
end

function MiniGameHexFloodWindow:createChildren()
    self.closeButton=ISButton:new(self.width-25,5,20,20,"X",self,self.onClose); self.closeButton:initialise(); self:addChild(self.closeButton)
    self.startButton=ISButton:new((self.width-120)/2,self.height-55,120,45,"START",self,self.onStart)
    self.startButton.borderColor,self.startButton.backgroundColor={r=0.2,g=1,b=0.2,a=1},{r=0.05,g=0.15,b=0.05,a=0.9}
    self.startButton.backgroundColorMouseOver={r=0.2,g=1,b=0.2,a=0.9}; self.startButton:initialise(); self:addChild(self.startButton)
    
    self.buttons={}; local cellSize=math.floor((self.width-40)/GRID_W); local gx,gy=20,70
    for y=1,self.gridH do self.buttons[y]={}
        for x=1,GRID_W do local btn=ISButton:new(gx+(x-1)*cellSize,gy+(y-1)*cellSize,cellSize,cellSize,"",self,self.onCellClick)
            btn.gridX,btn.gridY=x,y; btn:initialise(); self:addChild(btn); self.buttons[y][x]=btn
        end
    end
end

function MiniGameHexFloodWindow:onStart()
    self.gameActive,self.timeLeft,self.score,self.combo,self.riseCounter=true,self.timeLimit,0,0,0
    self.startButton:setVisible(false); self:startTimer(); self:startRiser(); self:playSound("UI_Menu_OS_Start")
end

function MiniGameHexFloodWindow:onCellClick(btn)
    if not self.gameActive then return end
    if not self.selected then self.selected={x=btn.gridX,y=btn.gridY}; self:playSound("UI_Menu_OS_Select")
    else local dx,dy=math.abs(btn.gridX-self.selected.x),math.abs(btn.gridY-self.selected.y)
        if dx+dy==1 then -- Adjacent swap
            local c1,c2=self.grid[self.selected.y][self.selected.x],self.grid[btn.gridY][btn.gridX]
            c1.symbol,c2.symbol=c2.symbol,c1.symbol
            if self:findMatches() then self:removeMarked() else c1.symbol,c2.symbol=c2.symbol,c1.symbol end
            self.selected=nil; self:playSound("UI_Menu_OS_Select")
        else self.selected={x=btn.gridX,y=btn.gridY} end
    end
end

function MiniGameHexFloodWindow:cancelTimer(f) if f and self[f] then SimpleTimer:removeTimer(self[f]); self[f]=nil end end
function MiniGameHexFloodWindow:startTimer() self:cancelTimer("timerId"); self.timerId=SimpleTimer:addTimer(60,function() if not self.gameActive then return end; self.timeLeft=self.timeLeft-1; if self.timeLeft<=0 then self:onTimeUp() else self:startTimer() end end) end
function MiniGameHexFloodWindow:startRiser() self:cancelTimer("riserId"); self.riserId=SimpleTimer:addTimer(1,function() if not self.gameActive then return end; self.riseCounter=self.riseCounter+1; if self.riseCounter>=self.riseSpeed then self:addRow(); self.riseCounter=0; if self.grid[1][1].symbol~="" then self:processFinalResult(false) end end; self:startRiser() end) end
function MiniGameHexFloodWindow:onTimeUp() self.gameActive=false; self:playSound("UI_Menu_OS_Exit"); self:processFinalResult(true) end
function MiniGameHexFloodWindow:onClose() if self.gameActive then self:processFinalResult(false) end; self:cancelTimer("timerId"); self:cancelTimer("riserId"); self:setVisible(false); self:removeFromUIManager() end

function MiniGameHexFloodWindow:processFinalResult(success)
    if self.resultProcessed then return end; self.resultProcessed,self.gameActive=true,false; self:cancelTimer("timerId"); self:cancelTimer("riserId")
    if not success and self.laptopItem then if isClient() then sendClientCommand(self.player,"GVDrive","IncrementFailureCount",{laptop=self.laptopItem})
        elseif LaptopSystem and LaptopSystem.incrementFailureCount then LaptopSystem.incrementFailureCount(self.laptopItem) end
    end
    if GVDrive_Utils and GVDrive_Utils.applyMinigameResult then GVDrive_Utils.applyMinigameResult(self.player,self.laptopItem,self.usbType,self.difficulty,success) end
    self:playSound(success and "UI_Menu_OS_Success" or "UI_Menu_OS_Failure"); SimpleTimer:addTimer(120,function() self:onClose() end)
end

function MiniGameHexFloodWindow:playSound(snd) if self.player and snd then if self.player.playSoundLocal then self.player:playSoundLocal(snd) elseif getPlayer() then getPlayer():playSoundLocal(snd) end end end

function MiniGameHexFloodWindow:render()
    ISPanel.render(self)
    if self.gameActive and self.titleShown<#self.titleText then self.titleAcc=self.titleAcc+1; if self.titleAcc>=3 then self.titleAcc=0; self.titleShown=self.titleShown+1 end
    elseif not self.gameActive then self.titleShown=#self.titleText end
    self:drawTextCentre(string.sub(self.titleText,1,self.titleShown),self.width/2,10,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large)
    
    if self.gameActive then
        self:drawText("TIME: "..math.ceil(self.timeLeft).."s",10,35,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)
        self:drawText("SCORE: "..self.score,self.width-120,35,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)
        if self.combo>1 then self:drawTextCentre("COMBO x"..self.combo,self.width/2,55,1,0.8,0.2,1,UIFont.Medium) end
        
        for y=1,self.gridH do for x=1,GRID_W do
            local btn,cell=self.buttons[y][x],self.grid[y][x]
            local bx,by,bw,bh=btn:getX(),btn:getY(),btn:getWidth(),btn:getHeight()
            local clr=THEME["hex_"..math.fmod(tonumber(cell.symbol,16) or 0,6)] or {r=0.5,g=0.5,b=0.5,a=1}
            self:drawRect(bx,by,bw,bh,THEME.cell.a,THEME.cell.r,THEME.cell.g,THEME.cell.b)
            if cell.symbol~="" then self:drawRect(bx+2,by+2,bw-4,bh-4,clr.a,clr.r,clr.g,clr.b); self:drawTextCentre(cell.symbol,bx+bw/2,by+bh/2-8,0,0,0,1,UIFont.Medium) end
            if self.selected and self.selected.x==x and self.selected.y==y then self:drawRectBorder(bx,by,bw,bh,1,1,1,0.2,1) end
        end end
    else if self.resultProcessed then self:drawTextCentre("FINAL SCORE: "..self.score,self.width/2,self.height/2,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large) end
    end
end

function MiniGame_HexFlood(widthPct,heightPct,usbType,difficulty,laptopItem,usbData)
    local player=getPlayer(); if not player then return end; local screenW,screenH=getCore():getScreenWidth(),getCore():getScreenHeight()
    local width,height=math.floor(screenW*(W_PCT/100)),math.floor(screenH*(H_PCT/100)); local x,y=(screenW-width)/2,(screenH-height)/2
    local win=MiniGameHexFloodWindow:new(x,y,width,height,player,usbType,difficulty,laptopItem,usbData)
    win:initialise(); win:addToUIManager(); win:bringToTop(); return win
end
