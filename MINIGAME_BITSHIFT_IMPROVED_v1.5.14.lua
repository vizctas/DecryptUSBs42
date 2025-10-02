-- MiniGameBitShift.lua v1.5.14 - Bit Shifter Puzzle Minigame
-- MEJORAS v1.5.14:
-- ✅ Tema moderno neon blue
-- ✅ Flip animations (10 ticks)
-- ✅ Partículas al cambiar bits (3-6 por cambio)
-- ✅ Progress bar visual
-- ✅ Tutorial integrado
-- ✅ Hover preview con outline amarillo

print("[DecryptSkillSys] Loading MiniGameBitShift.lua v1.5.14 - Enhanced Bit Shifter")

function ReloadMiniGameBitShift() print("[DEBUG] Reloading BitShift v1.5.14..."); package.loaded["client/MiniGameBitShift"]=nil; pcall(require,"client/MiniGameBitShift") end
function TestBitShift(diff) diff=diff or "Easy"; if _G.MiniGame_BitShift then return _G.MiniGame_BitShift(nil,nil,"TestBit",diff,nil,{skill="TestBit"}) end end

-- CONFIG
local W_PCT,H_PCT=28,50
local GRID_SIZES={Easy=4,Moderate=5,Expert=6}
local MOVE_LIMITS={Easy=20,Moderate=15,Expert=10}
local TIME_LIMITS={Easy=90,Moderate=75,Expert=60}
local OPERATIONS={Easy="XOR",Moderate="XOR",Expert="XOR"}
local AFFECT_PATTERNS={Easy="cross",Moderate="cross",Expert="cross_center"}

-- v1.5.14: TEMA MODERNO NEON BLUE
local THEME={
    bg={r=0.05,g=0.08,b=0.15,a=0.92},  -- Azul oscuro
    border={r=0.3,g=0.7,b=1,a=1},  -- Azul brillante
    bit_0={r=0.15,g=0.15,b=0.25,a=0.95},  -- Oscuro
    bit_1={r=0.3,g=0.8,b=1,a=0.95},  -- Azul neón
    grid_line={r=0.4,g=0.4,b=0.6,a=0.7},
    text={r=1,g=1,b=1,a=1},
    text_highlight={r=0.3,g=0.8,b=1,a=1},
    particle_on={r=0.3,g=0.8,b=1,a=0.9},
    particle_off={r=0.5,g=0.5,b=0.5,a=0.7},
    hover_outline={r=1,g=1,b=0.2,a=0.8},
    progress_bar={r=0.3,g=0.8,b=1,a=0.9},
    progress_bg={r=0.15,g=0.15,b=0.25,a=0.8}
}

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
    -- v1.5.14: Partículas y animaciones
    o.particles={}
    o.showTutorial=true
    o:generatePuzzle()
    return o
end

function MiniGameBitShiftWindow:generatePuzzle()
    for y=1,self.gridSize do self.grid[y]={} self.solution[y]={}
        for x=1,self.gridSize do self.grid[y][x]=1; self.solution[y][x]=1 end
    end
    local scrambles=self.moveLimit-5
    for i=1,scrambles do
        local x,y=ZombRand(1,self.gridSize+1),ZombRand(1,self.gridSize+1)
        self:applyClick(x,y,self.grid,true)  -- true = skip particles
    end
end

function MiniGameBitShiftWindow:applyClick(x,y,grid,skipParticles)
    local dirs={{0,-1},{0,1},{-1,0},{1,0}}
    if self.pattern=="cross_center" then
        grid[y][x]=1-grid[y][x]
    end
    for _,d in ipairs(dirs) do
        local nx,ny=x+d[1],y+d[2]
        if nx>=1 and nx<=self.gridSize and ny>=1 and ny<=self.gridSize then
            local oldValue=grid[ny][nx]
            grid[ny][nx]=1-grid[ny][nx]
            -- v1.5.14: Crear partículas al cambiar bit
            if not skipParticles and self.buttons and self.buttons[ny] and self.buttons[ny][nx] then
                local btn=self.buttons[ny][nx]
                self:createBitParticles(btn:getX()+btn:getWidth()/2,btn:getY()+btn:getHeight()/2,grid[ny][nx])
                -- v1.5.14: Flip animation
                btn.flipAnim=10
            end
        end
    end
end

-- v1.5.14: Crear partículas al cambiar bits
function MiniGameBitShiftWindow:createBitParticles(x,y,bitValue)
    local color=bitValue==1 and THEME.particle_on or THEME.particle_off
    for i=1,ZombRand(3,6) do
        local angle=ZombRand(0,360)*(math.pi/180)
        table.insert(self.particles,{
            x=x,y=y,
            vx=math.cos(angle)*2,
            vy=math.sin(angle)*2-3,  -- Float up
            life=20,maxLife=20,
            size=2,
            color={r=color.r,g=color.g,b=color.b,a=color.a}
        })
    end
end

-- v1.5.14: Actualizar partículas
function MiniGameBitShiftWindow:updateParticles()
    for i=#self.particles,1,-1 do
        local p=self.particles[i]
        p.x,p.y=p.x+p.vx,p.y+p.vy
        p.vy=p.vy+0.2  -- Gravedad
        p.life=p.life-1
        if p.life<=0 then table.remove(self.particles,i) end
    end
end

function MiniGameBitShiftWindow:checkWin()
    for y=1,self.gridSize do for x=1,self.gridSize do
        if self.grid[y][x]~=self.solution[y][x] then return false end
    end end
    return true
end

function MiniGameBitShiftWindow:createChildren()
    self.closeButton=ISButton:new(self.width-25,5,20,20,"X",self,self.onClose)
    self.closeButton:initialise(); self:addChild(self.closeButton)
    
    self.startButton=ISButton:new((self.width-120)/2,self.height-55,120,45,"START",self,self.onStart)
    self.startButton.borderColor={r=0.3,g=0.7,b=1,a=1}
    self.startButton.backgroundColor={r=0.05,g=0.1,b=0.2,a=0.9}
    self.startButton.backgroundColorMouseOver={r=0.3,g=0.7,b=1,a=0.9}
    self.startButton:initialise(); self:addChild(self.startButton)
    
    self.buttons={}
    local cellSize=math.floor(math.min(self.width-60,self.height-200)/self.gridSize)
    local gx,gy=(self.width-cellSize*self.gridSize)/2,100
    
    for y=1,self.gridSize do self.buttons[y]={}
        for x=1,self.gridSize do
            local btn=ISButton:new(gx+(x-1)*cellSize,gy+(y-1)*cellSize,cellSize,cellSize,"",self,self.onCellClick)
            btn.gridX,btn.gridY=x,y
            btn.flipAnim=0  -- v1.5.14: Animation state
            btn:initialise(); self:addChild(btn)
            self.buttons[y][x]=btn
        end
    end
end

function MiniGameBitShiftWindow:onStart()
    self.gameActive,self.timeLeft,self.movesLeft=true,self.timeLimit,self.moveLimit
    self.showTutorial=false
    self.startButton:setVisible(false)
    self:startTimer()
    self:playSound("UI_Menu_OS_Start")
end

function MiniGameBitShiftWindow:onCellClick(btn)
    if not self.gameActive or self.movesLeft<=0 then return end
    self:applyClick(btn.gridX,btn.gridY,self.grid)
    self.movesLeft=self.movesLeft-1
    
    if self:checkWin() then
        self:processFinalResult(true)
    elseif self.movesLeft<=0 then
        self:processFinalResult(false)
    end
    
    self:playSound("UI_Menu_OS_Select")
end

function MiniGameBitShiftWindow:cancelTimer(f) if f and self[f] then SimpleTimer:removeTimer(self[f]); self[f]=nil end end
function MiniGameBitShiftWindow:startTimer() self:cancelTimer("timerId"); self.timerId=SimpleTimer:addTimer(60,function() if not self.gameActive then return end; self.timeLeft=self.timeLeft-1; if self.timeLeft<=0 then self:onTimeUp() else self:startTimer() end end) end
function MiniGameBitShiftWindow:onTimeUp() self.gameActive=false; self:playSound("UI_Menu_OS_Exit"); self:processFinalResult(false) end
function MiniGameBitShiftWindow:onClose() if self.gameActive then self:processFinalResult(false) end; self:cancelTimer("timerId"); self:setVisible(false); self:removeFromUIManager() end

function MiniGameBitShiftWindow:processFinalResult(success)
    if self.resultProcessed then return end
    self.resultProcessed,self.gameActive=true,false
    self:cancelTimer("timerId")
    
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

function MiniGameBitShiftWindow:playSound(snd)
    if self.player and snd then
        if self.player.playSoundLocal then self.player:playSoundLocal(snd)
        elseif getPlayer() then getPlayer():playSoundLocal(snd) end
    end
end

function MiniGameBitShiftWindow:update()
    ISPanel.update(self)
    if not self.gameActive then return end
    
    -- v1.5.14: Update particles
    self:updateParticles()
    
    -- v1.5.14: Update flip animations
    for y=1,self.gridSize do
        for x=1,self.gridSize do
            local btn=self.buttons[y][x]
            if btn.flipAnim and btn.flipAnim>0 then
                btn.flipAnim=btn.flipAnim-1
            end
        end
    end
end

function MiniGameBitShiftWindow:render()
    ISPanel.render(self)
    
    if self.gameActive and self.titleShown<#self.titleText then
        self.titleAcc=self.titleAcc+1
        if self.titleAcc>=3 then self.titleAcc=0; self.titleShown=self.titleShown+1 end
    elseif not self.gameActive then
        self.titleShown=#self.titleText
    end
    
    self:drawTextCentre(string.sub(self.titleText,1,self.titleShown),self.width/2,10,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large)
    
    -- v1.5.14: Tutorial
    if self.showTutorial and not self.gameActive then
        local tutY=50
        self:drawTextCentre("= HOW TO PLAY =",self.width/2,tutY,THEME.text_highlight.r,THEME.text_highlight.g,THEME.text_highlight.b,1,UIFont.Medium)
        tutY=tutY+30
        
        self:drawText("OBJECTIVE: Turn all bits to 1 (all blue)",15,tutY,0.9,0.9,0.9,1,UIFont.Small)
        tutY=tutY+24
        
        self:drawText("Click a bit to toggle it AND neighbors:",15,tutY,0.8,0.8,0.8,1,UIFont.Small)
        tutY=tutY+24
        
        -- Diagram
        self:drawTextCentre("↑",self.width/2,tutY,THEME.text_highlight.r,THEME.text_highlight.g,THEME.text_highlight.b,1,UIFont.Medium)
        tutY=tutY+20
        self:drawTextCentre("← X →",self.width/2,tutY,THEME.text_highlight.r,THEME.text_highlight.g,THEME.text_highlight.b,1,UIFont.Medium)
        tutY=tutY+20
        self:drawTextCentre("↓",self.width/2,tutY,THEME.text_highlight.r,THEME.text_highlight.g,THEME.text_highlight.b,1,UIFont.Medium)
        tutY=tutY+30
        
        self:drawTextCentre("0 = OFF (dark) | 1 = ON (blue)",self.width/2,tutY,0.7,0.7,0.9,1,UIFont.Small)
    end
    
    if self.gameActive then
        self:drawText("TIME: "..math.ceil(self.timeLeft).."s",10,35,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)
        self:drawText("MOVES: "..self.movesLeft,self.width-120,35,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)
        
        -- v1.5.14: Progress bar
        local correctCount=0
        for y=1,self.gridSize do for x=1,self.gridSize do
            if self.grid[y][x]==1 then correctCount=correctCount+1 end
        end end
        local totalBits=self.gridSize*self.gridSize
        local progressRatio=correctCount/totalBits
        
        local progressText=correctCount.." / "..totalBits.." bits"
        local progressColor=correctCount==totalBits and {r=0.2,g=1,b=0.2} or THEME.text_highlight
        self:drawTextCentre(progressText,self.width/2,55,progressColor.r,progressColor.g,progressColor.b,1,UIFont.Small)
        
        -- Progress bar visual
        local barWidth=self.width-40
        local barHeight=10
        local barX=20
        local barY=70
        self:drawRect(barX,barY,barWidth,barHeight,THEME.progress_bg.a,THEME.progress_bg.r,THEME.progress_bg.g,THEME.progress_bg.b)
        self:drawRect(barX,barY,barWidth*progressRatio,barHeight,THEME.progress_bar.a,THEME.progress_bar.r,THEME.progress_bar.g,THEME.progress_bar.b)
        
        -- Grid rendering
        for y=1,self.gridSize do for x=1,self.gridSize do
            local btn,bit=self.buttons[y][x],self.grid[y][x]
            local bx,by,bw,bh=btn:getX(),btn:getY(),btn:getWidth(),btn:getHeight()
            
            -- v1.5.14: Flip animation (scale effect)
            local scale=1.0
            if btn.flipAnim>0 then
                scale=1.0+(btn.flipAnim/10)*0.3  -- Scale up during flip
            end
            
            local scaledW=bw*scale
            local scaledH=bh*scale
            local offsetX=(bw-scaledW)/2
            local offsetY=(bh-scaledH)/2
            
            local clr=bit==1 and THEME.bit_1 or THEME.bit_0
            self:drawRect(bx+offsetX,by+offsetY,scaledW,scaledH,clr.a,clr.r,clr.g,clr.b)
            self:drawRectBorder(bx,by,bw,bh,THEME.grid_line.a,THEME.grid_line.r,THEME.grid_line.g,THEME.grid_line.b)
            
            -- v1.5.14: Hover effect (simple check if mouse over button area)
            local mouseX,mouseY=getMouseX(),getMouseY()
            if mouseX>=bx and mouseX<=bx+bw and mouseY>=by and mouseY<=by+bh then
                self:drawRectBorder(bx-1,by-1,bw+2,bh+2,THEME.hover_outline.a,THEME.hover_outline.r,THEME.hover_outline.g,THEME.hover_outline.b)
            end
            
            self:drawTextCentre(tostring(bit),bx+bw/2,by+bh/2-10,0,0,0,1,UIFont.Large)
        end end
        
        -- v1.5.14: Render particles
        for _,p in ipairs(self.particles) do
            local alpha=p.life/p.maxLife
            self:drawRect(p.x,p.y,p.size,p.size,alpha*p.color.a,p.color.r,p.color.g,p.color.b)
        end
    else
        if self.resultProcessed then
            local msg=self:checkWin() and "PATTERN SOLVED!" or "PATTERN FAILED"
            local color=self:checkWin() and {r=0.2,g=1,b=0.2} or {r=1,g=0.2,b=0.2}
            self:drawTextCentre(msg,self.width/2,self.height/2,color.r,color.g,color.b,1,UIFont.Large)
        end
    end
end

function MiniGame_BitShift(widthPct,heightPct,usbType,difficulty,laptopItem,usbData)
    local player=getPlayer(); if not player then return end
    local screenW,screenH=getCore():getScreenWidth(),getCore():getScreenHeight()
    local width,height=math.floor(screenW*(W_PCT/100)),math.floor(screenH*(H_PCT/100))
    local x,y=(screenW-width)/2,(screenH-height)/2
    local win=MiniGameBitShiftWindow:new(x,y,width,height,player,usbType,difficulty,laptopItem,usbData)
    win:initialise(); win:addToUIManager(); win:bringToTop(); return win
end

print("[DecryptSkillSys] MiniGame_BitShift v1.5.14 loaded - Neon blue theme + animations + particles")
