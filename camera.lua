-- Handles camera movement and following the player

local Camera = {}
Camera.__index = Camera

local Screen = require("screen")

function Camera.new()
    local self = setmetatable({}, Camera)
    
    -- Camera position
    self.x = 0
    self.y = 0
    self.scale = 1.0
    self.smoothing = 0.1
    
    -- Retro grid settings
    self.baseWidth = 12 * 16
    self.baseHeight = 12 * 16
    self.tileSize = 16
    
    -- Camera settings
    self.followSpeed = 5
    self.deadZone = 50  -- Distance from center before camera moves
    
    -- Screen dimensions (virtual via Screen)
    self.screenWidth = 0
    self.screenHeight = 0
    
    return self
end

function Camera:update(player)
    -- Calculate target camera position to center player in virtual space
    local vw, vh = Screen.getVirtualSize()
    self.screenWidth, self.screenHeight = vw, vh
    local targetX = player.x - (vw / 2)
    local targetY = player.y - (vh / 2)
    self.x = targetX
    self.y = targetY
    -- Scaling is handled by Screen; keep camera scale at 1 unless implementing zoom
    self.scale = 1
end

function Camera:apply()
    love.graphics.push()
    -- No additional camera scaling; Screen handles window scaling
    love.graphics.scale(self.scale, self.scale)
    love.graphics.translate(-math.floor(self.x), -math.floor(self.y))
end

function Camera:reset()
    love.graphics.pop()
end

function Camera:getWorldCoordinates(screenX, screenY)
    return screenX + self.x, screenY + self.y
end

function Camera:getScreenCoordinates(worldX, worldY)
    return worldX - self.x, worldY - self.y
end

return Camera
