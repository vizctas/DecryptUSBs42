-- ⚠️ MiniGameLaser.lua v1.5.14 - DESACTIVADO POR USUARIO
-- Usuario reporta: "No me gustó"
-- Revertir a versión anterior o mantener desactivado
-- TODO: Restaurar versión v1.5.13 o anterior

print("[DecryptSkillSys] MiniGameLaser.lua v1.5.14 - DESACTIVADO (requiere revisión)")

-- ⚠️ FUNCIÓN DESACTIVADA - Retornar nil para evitar uso
function MiniGame_Laser(widthPct,heightPct,usbType,difficulty,laptopItem,usbData)
    print("[WARNING] MiniGameLaser está desactivado. Requiere revisión.")
    return nil
end

-- Aliases desactivados
MiniGame_LaserDeflector = MiniGame_Laser
_G.MiniGame_LaserDeflector = MiniGame_Laser

print("[DecryptSkillSys] MiniGameLaser DESACTIVADO - ignorar resto del archivo")

if true then return end  -- ⚠️ BLOQUEAR EJECUCIÓN DEL RESTO DEL ARCHIVO

-- CÓDIGO ORIGINAL COMENTADO ABAJO:
--[[
-- ⚡ MiniGameLaser.lua v1.5.14 - IMPROVED VERSION
-- Mejoras implementadas:
-- ✅ Tutorial completo con explicación interactiva
-- ✅ Laser beam más visible (grosor 4px + glow mejorado)
-- ✅ Animaciones de rotación de espejos
-- ✅ Partículas al rebotar en espejos
-- ✅ Indicadores de dirección del láser
-- ✅ Mejor feedback visual y sonoro
-- ✅ UI/UX profesional con spacing adecuado

print("[DecryptSkillSys] Loading MiniGameLaser.lua v1.5.14 - IMPROVED Laser Grid Deflector system")

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

-- ⚙️ CONFIGURATION MEJORADA
local W_PCT, H_PCT = 30, 55  -- ⚡ Ventana más grande
local GRID_SIZES = {Easy=4, Moderate=5, Expert=6}  -- ⚡ Grid más pequeño
local TIME_LIMITS = {Easy=120, Moderate=90, Expert=60}  -- ⚡ Más tiempo
local MIRROR_COUNTS = {Easy=2, Moderate=4, Expert=6}  -- ⚡ Menos espejos
local BLOCKER_COUNTS = {Easy=0, Moderate=2, Expert=4}  -- ⚡ Menos bloqueadores
local MAX_BOUNCES = {Easy=20, Moderate=15, Expert=12}  -- ⚡ Más rebotes

-- 🎨 TEMA MEJORADO con colores vibrantes
local THEME = {
    bg = {r=0.05,g=0.05,b=0.15,a=0.95},
    border = {r=1,g=0.2,b=0.2,a=1},
    cell_empty = {r=0.08,g=0.08,b=0.18,a=0.9},
    cell_mirror = {r=0.2,g=0.5,b=0.8,a=0.95},  -- Azul brillante
    cell_blocker = {r=0.8,g=0.1,b=0.1,a=0.95},  -- Rojo brillante
    laser_beam = {r=1,g=0.15,b=0.15,a=1},
    laser_glow = {r=1,g=0.4,b=0.4,a=0.7},  -- Glow más visible
    laser_core = {r=1,g=0.8,b=0.8,a=1},  -- Centro del láser
    laser_particle = {r=1,g=0.6,b=0.2,a=0.9},  -- Partículas naranjas
    start_node = {r=0.2,g=1,b=0.2,a=1},
    end_node = {r=1,g=0.2,b=0.2,a=1},
    text = {r=1,g=1,b=1,a=1},
    tutorial_bg = {r=0.05,g=0.05,b=0.12,a=0.92},
    tutorial_highlight = {r=0.3,g=0.7,b=1,a=1},
}

-- TIMER SYSTEM
local SimpleTimer = {activeTimers={}, nextId=1}
function SimpleTimer:addTimer(dur, cb) local id=self.nextId; self.nextId=id+1; self.activeTimers[id]={callback=cb,duration=dur,elapsed=0}; return id end
function SimpleTimer:removeTimer(id) self.activeTimers[id]=nil end
function SimpleTimer:update()
    local rm={}; for id,t in pairs(self.activeTimers) do
        if t and t.elapsed and t.duration then
            t.elapsed=t.elapsed+1
            if t.elapsed>=t.duration then if t.callback then pcall(t.callback) end; rm[id]=true end
        else rm[id]=true end
    end
    for id in pairs(rm) do self.activeTimers[id]=nil end
end
if Events and Events.OnTick then Events.OnTick.Add(function() SimpleTimer:update() end) end

-- WINDOW CLASS
local MiniGameLaserWindow = ISPanel:derive("MiniGameLaserWindow")

function MiniGameLaserWindow:new(x,y,w,h,player,usbType,diff,laptop,usbData)
    local o=ISPanel:new(x,y,w,h); setmetatable(o,self); self.__index=self
    o.player,o.usbType,o.difficulty,o.laptopItem,o.usbData=player,usbType,diff,laptop,usbData
    o.backgroundColor,o.borderColor,o.moveWithMouse=THEME.bg,THEME.border,true
    o.gridSize,o.timeLimit=GRID_SIZES[diff] or 4, TIME_LIMITS[diff] or 120
    o.mirrorCount,o.blockerCount=MIRROR_COUNTS[diff] or 2, BLOCKER_COUNTS[diff] or 0
    o.maxBounces=MAX_BOUNCES[diff] or 20
    o.timeLeft,o.gameActive,o.resultProcessed=o.timeLimit,false,false
    o.grid,o.buttons,o.laserPath={},{},{}
    o.startNode,o.endNode={x=1,y=math.ceil(o.gridSize/2)},{x=o.gridSize,y=math.ceil(o.gridSize/2)}
    o.titleText,o.titleShown,o.titleAcc="LASER DEFLECTOR",0,0
    
    -- ⚡ NUEVAS PROPIEDADES para efectos visuales
    o.laserParticles = {}  -- Partículas al rebotar
    o.mirrorRotationAnims = {}  -- Animaciones de rotación
    o.showTutorial = true  -- Mostrar tutorial antes de START
    o.laserAnimOffset = 0  -- Offset para animación de láser pulsante
    o.bounceFlashes = {}  -- Flashes al rebotar
    
    o:generateGrid(); return o
end

function MiniGameLaserWindow:generateGrid()
    for y=1,self.gridSize do self.grid[y]={}
        for x=1,self.gridSize do self.grid[y][x]={type="empty",rotation=0,clickAnim=0,flash=0} end
    end
    -- Place mirrors with random rotations
    local placed=0; while placed<self.mirrorCount do
        local x,y=ZombRand(2,self.gridSize),ZombRand(2,self.gridSize)
        if self.grid[y][x].type=="empty" and not (x==self.startNode.x and y==self.startNode.y) 
           and not (x==self.endNode.x and y==self.endNode.y) then
            self.grid[y][x]={type="mirror",rotation=ZombRand(4),clickAnim=0,flash=0}; placed=placed+1
        end
    end
    -- Place blockers
    placed=0; while placed<self.blockerCount do
        local x,y=ZombRand(2,self.gridSize),ZombRand(2,self.gridSize)
        if self.grid[y][x].type=="empty" and not (x==self.startNode.x and y==self.startNode.y) 
           and not (x==self.endNode.x and y==self.endNode.y) then
            self.grid[y][x]={type="blocker",rotation=0,clickAnim=0,flash=0}; placed=placed+1
        end
    end
end

function MiniGameLaserWindow:traceLaser()
    self.laserPath={}; self.bounceFlashes={}
    local x,y,dx,dy=self.startNode.x,self.startNode.y,1,0
    local bounces=0
    
    while bounces<self.maxBounces do
        table.insert(self.laserPath,{x=x,y=y,dx=dx,dy=dy})
        x,y=x+dx,y+dy
        
        -- Out of bounds
        if x<1 or x>self.gridSize or y<1 or y>self.gridSize then break end
        
        local cell=self.grid[y][x]
        
        -- Hit blocker
        if cell.type=="blocker" then
            cell.flash = 1.0  -- Flash effect
            break
        end
        
        -- Hit mirror
        if cell.type=="mirror" then
            bounces=bounces+1
            cell.flash = 1.0  -- Flash effect
            
            -- ⚡ CREAR PARTÍCULAS al rebotar
            self:createBounceParticles(x, y)
            
            -- Mirror rotation logic: 0=/, 1=\, 2=|, 3=-
            if cell.rotation==0 then dx,dy=-dy,-dx -- /
            elseif cell.rotation==1 then dx,dy=dy,dx -- \
            elseif cell.rotation==2 then dy=-dy -- |
            else dx=-dx end -- -
        end
        
        -- Reached target
        if x==self.endNode.x and y==self.endNode.y then return true end
    end
    return false
end

-- ⚡ CREAR PARTÍCULAS al rebotar en espejo
function MiniGameLaserWindow:createBounceParticles(gridX, gridY)
    if not self.buttons or not self.buttons[gridY] or not self.buttons[gridY][gridX] then return end
    
    local btn = self.buttons[gridY][gridX]
    local centerX = btn:getX() + btn:getWidth() / 2
    local centerY = btn:getY() + btn:getHeight() / 2
    
    -- Crear 4-6 partículas
    for i=1,ZombRand(4,7) do
        local angle = ZombRand(0, 360) * (math.pi / 180)
        local speed = ZombRand(2, 5)
        table.insert(self.laserParticles, {
            x = centerX,
            y = centerY,
            vx = math.cos(angle) * speed,
            vy = math.sin(angle) * speed,
            life = 30,  -- 30 ticks de vida
            maxLife = 30,
            size = ZombRand(2, 4)
        })
    end
end

function MiniGameLaserWindow:updateParticles()
    for i=#self.laserParticles, 1, -1 do
        local p = self.laserParticles[i]
        p.x = p.x + p.vx
        p.y = p.y + p.vy
        p.life = p.life - 1
        p.vy = p.vy + 0.2  -- Gravity
        
        if p.life <= 0 then
            table.remove(self.laserParticles, i)
        end
    end
    
    -- Reducir flashes
    for y=1, self.gridSize do
        for x=1, self.gridSize do
            local cell = self.grid[y][x]
            if cell.flash and cell.flash > 0 then
                cell.flash = math.max(0, cell.flash - 0.05)
            end
        end
    end
end

function MiniGameLaserWindow:createChildren()
    self.closeButton=ISButton:new(self.width-25,5,20,20,"X",self,self.onClose)
    self.closeButton:initialise(); self:addChild(self.closeButton)
    
    self.startButton=ISButton:new((self.width-120)/2,self.height-55,120,45,"START",self,self.onStart)
    self.startButton.borderColor,self.startButton.backgroundColor={r=1,g=0.2,b=0.2,a=1},{r=0.2,g=0.05,b=0.05,a=0.9}
    self.startButton.backgroundColorMouseOver={r=1,g=0.2,b=0.2,a=0.9}
    self.startButton:initialise(); self:addChild(self.startButton)
    
    local cellSize=math.floor(math.min(self.width-80,self.height-220)/self.gridSize)
    local gx,gy=(self.width-cellSize*self.gridSize)/2, 120  -- ⚡ Más espacio arriba para tutorial
    for y=1,self.gridSize do self.buttons[y]={}
        for x=1,self.gridSize do
            local btn=ISButton:new(gx+(x-1)*cellSize,gy+(y-1)*cellSize,cellSize,cellSize,"",self,self.onCellClick)
            btn.gridX,btn.gridY=x,y; btn:initialise(); btn:setVisible(false); self:addChild(btn); self.buttons[y][x]=btn
        end
    end
end

function MiniGameLaserWindow:onStart()
    self.gameActive,self.timeLeft,self.resultProcessed=true,self.timeLimit,false
    self.showTutorial=false  -- ⚡ Ocultar tutorial
    self.startButton:setVisible(false)
    
    -- ⚡ Mostrar botones de grid
    for y=1,self.gridSize do
        for x=1,self.gridSize do
            self.buttons[y][x]:setVisible(true)
        end
    end
    
    self:startTimer()
    self:playSound("UI_Menu_OS_Start")
    
    if DynamicSoundSystem and DynamicSoundSystem.playButtonClick then
        DynamicSoundSystem.playButtonClick(self.player, 0.7)
    end
end

function MiniGameLaserWindow:onCellClick(btn)
    if not self.gameActive then return end
    local cell=self.grid[btn.gridY][btn.gridX]
    
    if cell.type=="mirror" then
        -- ⚡ ANIMACIÓN DE ROTACIÓN
        cell.clickAnim = 1.0
        cell.rotation=(cell.rotation+1)%4
        
        -- ⚡ SONIDO al rotar
        self:playSound("UI_Menu_OS_Select")
        if DynamicSoundSystem and DynamicSoundSystem.playButtonClick then
            DynamicSoundSystem.playButtonClick(self.player, 0.5)
        end
        
        -- Verificar victoria
        if self:traceLaser() then
            self:processFinalResult(true)
        end
    end
end

function MiniGameLaserWindow:update()
    ISPanel.update(self)
    if not self.gameActive then return end
    
    -- ⚡ Actualizar partículas
    self:updateParticles()
    
    -- ⚡ Animar láser pulsante
    self.laserAnimOffset = (self.laserAnimOffset + 0.05) % 1.0
    
    -- ⚡ Reducir animaciones de rotación
    for y=1, self.gridSize do
        for x=1, self.gridSize do
            local cell = self.grid[y][x]
            if cell.clickAnim and cell.clickAnim > 0 then
                cell.clickAnim = math.max(0, cell.clickAnim - 0.1)
            end
        end
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
    -- ⚡ REPRODUCIR SONIDO LAPTOP SHUTDOWN
    if self.player and DynamicSoundSystem and DynamicSoundSystem.playLaptopShutdown then
        DynamicSoundSystem.playLaptopShutdown(self.player, 0.4)
        print("[MiniGameLaser] Playing laptop_shutdown.ogg")
    end
    
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
    
    -- ⚡ SONIDOS MEJORADOS
    self:playSound(success and "UI_Menu_OS_Success" or "UI_Menu_OS_Failure")
    if success and DynamicSoundSystem and DynamicSoundSystem.playSuccessSound then
        DynamicSoundSystem.playSuccessSound(self.player, 0.9)
    elseif not success and DynamicSoundSystem and DynamicSoundSystem.playFailureSound then
        DynamicSoundSystem.playFailureSound(self.player, 0.8)
    end
    
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
    
    -- ⚡ TUTORIAL COMPLETO antes de START
    if self.showTutorial then
        self:renderTutorial()
        return
    end
    
    -- Título typewriter
    if self.gameActive and self.titleShown<#self.titleText then
        self.titleAcc=self.titleAcc+1; if self.titleAcc>=3 then self.titleAcc=0; self.titleShown=self.titleShown+1 end
    elseif not self.gameActive then self.titleShown=#self.titleText end
    
    local title=string.sub(self.titleText,1,self.titleShown)
    self:drawTextCentre(title,self.width/2,10,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large)
    
    if self.gameActive then
        self:drawText("TIME: "..math.ceil(self.timeLeft).."s",10,40,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Small)
        self:drawTextCentre("Click mirrors to rotate them",self.width/2,60,0.7,0.7,1,1,UIFont.Small)
        self:drawTextCentre("/ \\ | -",self.width/2,78,0.9,0.9,0.9,0.9,UIFont.Medium)
        
        -- Draw grid cells
        for y=1,self.gridSize do for x=1,self.gridSize do
            local btn,cell=self.buttons[y][x],self.grid[y][x]
            local bx,by,bw,bh=btn:getX(),btn:getY(),btn:getWidth(),btn:getHeight()
            
            -- Cell background
            local clr=THEME.cell_empty
            if cell.type=="mirror" then clr=THEME.cell_mirror
            elseif cell.type=="blocker" then clr=THEME.cell_blocker end
            
            -- ⚡ FLASH EFFECT al rebotar
            if cell.flash and cell.flash > 0 then
                local flashIntensity = cell.flash
                clr = {
                    r = math.min(1, clr.r + flashIntensity),
                    g = math.min(1, clr.g + flashIntensity),
                    b = math.min(1, clr.b + flashIntensity),
                    a = clr.a
                }
            end
            
            self:drawRect(bx,by,bw,bh,clr.a,clr.r,clr.g,clr.b)
            self:drawRectBorder(bx,by,bw,bh,0.5,0.3,0.3,0.4)
            
            -- Draw mirror symbol with rotation animation
            if cell.type=="mirror" then
                local symbols={"/","\\","|","-"}
                local symbol = symbols[cell.rotation+1] or "/"
                
                -- ⚡ ANIMACIÓN DE ROTACIÓN
                if cell.clickAnim and cell.clickAnim > 0 then
                    local scale = 1.0 + cell.clickAnim * 0.5
                    self:drawTextCentre(symbol,bx+bw/2,by+bh/2-8,1,1,0,1,UIFont.Large)
                end
                
                self:drawTextCentre(symbol,bx+bw/2,by+bh/2-8,1,1,1,1,UIFont.Large)
                
            elseif cell.type=="blocker" then
                self:drawTextCentre("█",bx+bw/2,by+bh/2-8,0.9,0.1,0.1,1,UIFont.Large)
            end
            
            -- Start/End markers
            if x==self.startNode.x and y==self.startNode.y then
                self:drawRect(bx+3,by+3,bw-6,bh-6,0.6,THEME.start_node.r,THEME.start_node.g,THEME.start_node.b)
                self:drawTextCentre("►",bx+bw/2,by+bh/2-8,1,1,1,1,UIFont.Medium)
            elseif x==self.endNode.x and y==self.endNode.y then
                self:drawRect(bx+3,by+3,bw-6,bh-6,0.6,THEME.end_node.r,THEME.end_node.g,THEME.end_node.b)
                self:drawTextCentre("◆",bx+bw/2,by+bh/2-8,1,1,1,1,UIFont.Medium)
            end
        end end
        
        -- ⚡ DRAW LASER BEAM MEJORADO (grosor 4px + glow)
        self:traceLaser()
        if #self.laserPath>1 then
            for i=1,#self.laserPath-1 do
                local p1,p2=self.laserPath[i],self.laserPath[i+1]
                if self.buttons[p1.y] and self.buttons[p1.y][p1.x] and 
                   self.buttons[p2.y] and self.buttons[p2.y][p2.x] then
                    local btn1,btn2=self.buttons[p1.y][p1.x],self.buttons[p2.y][p2.x]
                    local x1,y1=btn1:getX()+btn1:getWidth()/2,btn1:getY()+btn1:getHeight()/2
                    local x2,y2=btn2:getX()+btn2:getWidth()/2,btn2:getY()+btn2:getHeight()/2
                    
                    -- Glow effect (grosor 6px)
                    self:drawThickLine(x1,y1,x2,y2,6,THEME.laser_glow)
                    -- Core beam (grosor 3px)
                    self:drawThickLine(x1,y1,x2,y2,3,THEME.laser_beam)
                    -- Center core (grosor 1px)
                    self:drawThickLine(x1,y1,x2,y2,1,THEME.laser_core)
                end
            end
        end
        
        -- ⚡ DRAW PARTICLES
        for _, p in ipairs(self.laserParticles) do
            local alpha = p.life / p.maxLife
            self:drawRect(p.x, p.y, p.size, p.size, alpha * THEME.laser_particle.a, 
                         THEME.laser_particle.r, THEME.laser_particle.g, THEME.laser_particle.b)
        end
    end
    
    -- Result message
    if self.resultProcessed then
        local msg = self:traceLaser() and "LASER CONNECTED!" or "CONNECTION FAILED"
        self:drawTextCentre(msg,self.width/2,self.height/2-20,THEME.text.r,THEME.text.g,THEME.text.b,THEME.text.a,UIFont.Large)
    end
end

-- ⚡ TUTORIAL VISUAL completo
function MiniGameLaserWindow:renderTutorial()
    local tutY = 40
    local lineHeight = 24  -- ⚡ Interlineado 2.0
    
    -- Título
    self:drawTextCentre("= LASER DEFLECTOR TUTORIAL =",self.width/2,tutY,THEME.tutorial_highlight.r,THEME.tutorial_highlight.g,THEME.tutorial_highlight.b,1,UIFont.Large)
    tutY = tutY + lineHeight * 2
    
    -- Objetivo
    self:drawTextCentre("OBJECTIVE:",self.width/2,tutY,1,1,1,1,UIFont.Medium)
    tutY = tutY + lineHeight
    self:drawTextCentre("Connect the GREEN start node to the RED target",self.width/2,tutY,0.8,0.8,0.8,1,UIFont.Small)
    tutY = tutY + lineHeight
    self:drawTextCentre("by rotating mirrors to deflect the laser beam.",self.width/2,tutY,0.8,0.8,0.8,1,UIFont.Small)
    tutY = tutY + lineHeight * 1.5
    
    -- Elementos
    self:drawTextCentre("ELEMENTS:",self.width/2,tutY,1,1,1,1,UIFont.Medium)
    tutY = tutY + lineHeight
    self:drawTextCentre("► = START (laser emitter)",self.width/2,tutY,0.2,1,0.2,1,UIFont.Small)
    tutY = tutY + lineHeight
    self:drawTextCentre("◆ = TARGET (laser receiver)",self.width/2,tutY,1,0.2,0.2,1,UIFont.Small)
    tutY = tutY + lineHeight
    self:drawTextCentre("/ \\ | - = MIRRORS (click to rotate 90°)",self.width/2,tutY,0.2,0.5,0.8,1,UIFont.Small)
    tutY = tutY + lineHeight
    self:drawTextCentre("█ = BLOCKERS (laser cannot pass)",self.width/2,tutY,0.8,0.1,0.1,1,UIFont.Small)
    tutY = tutY + lineHeight * 1.5
    
    -- Cómo jugar
    self:drawTextCentre("HOW TO PLAY:",self.width/2,tutY,1,1,1,1,UIFont.Medium)
    tutY = tutY + lineHeight
    self:drawTextCentre("1. Click mirrors to rotate them",self.width/2,tutY,0.8,0.8,0.8,1,UIFont.Small)
    tutY = tutY + lineHeight
    self:drawTextCentre("2. The laser beam will automatically trace its path",self.width/2,tutY,0.8,0.8,0.8,1,UIFont.Small)
    tutY = tutY + lineHeight
    self:drawTextCentre("3. When the laser reaches the target: YOU WIN!",self.width/2,tutY,0.2,1,0.2,1,UIFont.Small)
    tutY = tutY + lineHeight * 1.5
    
    -- Tips
    self:drawTextCentre("TIPS:",self.width/2,tutY,THEME.tutorial_highlight.r,THEME.tutorial_highlight.g,THEME.tutorial_highlight.b,1,UIFont.Medium)
    tutY = tutY + lineHeight
    self:drawTextCentre("• Mirrors reflect the laser 90°",self.width/2,tutY,0.7,0.7,1,1,UIFont.Small)
    tutY = tutY + lineHeight
    self:drawTextCentre("• Plan your path before rotating",self.width/2,tutY,0.7,0.7,1,1,UIFont.Small)
    tutY = tutY + lineHeight
    self:drawTextCentre("• Watch for blockers!",self.width/2,tutY,1,0.5,0.5,1,UIFont.Small)
    tutY = tutY + lineHeight * 2
    
    -- Instrucción final
    self:drawTextCentre("Press START when ready!",self.width/2,tutY,THEME.tutorial_highlight.r,THEME.tutorial_highlight.g,THEME.tutorial_highlight.b,1,UIFont.Medium)
end

-- ⚡ DRAW THICK LINE (para láser más visible)
function MiniGameLaserWindow:drawThickLine(x1,y1,x2,y2,thickness,color)
    local steps=math.max(math.abs(x2-x1),math.abs(y2-y1))
    if steps==0 then return end
    
    for i=0,steps do
        local t=i/steps
        local x,y=x1+t*(x2-x1),y1+t*(y2-y1)
        
        -- Draw multiple pixels for thickness
        for dx=-thickness/2, thickness/2 do
            for dy=-thickness/2, thickness/2 do
                self:drawRect(x+dx,y+dy,1,1,color.a,color.r,color.g,color.b)
            end
        end
    end
end

-- GLOBAL FUNCTION
function MiniGame_Laser(widthPct,heightPct,usbType,difficulty,laptopItem,usbData)
    local player=getPlayer(); if not player then return end
    local screenW,screenH=getCore():getScreenWidth(),getCore():getScreenHeight()
    local width,height=math.floor(screenW*(W_PCT/100)),math.floor(screenH*(H_PCT/100))
    local x,y=(screenW-width)/2,(screenH-height)/2
    local win=MiniGameLaserWindow:new(x,y,width,height,player,usbType,difficulty,laptopItem,usbData)
    win:initialise(); win:addToUIManager(); win:bringToTop(); return win
end

-- ✅ ALIAS DE COMPATIBILIDAD
MiniGame_LaserDeflector = MiniGame_Laser
_G.MiniGame_LaserDeflector = MiniGame_Laser
print("[DecryptSkillSys] MiniGame_LaserDeflector v1.5.14 IMPROVED alias registered")
]]
