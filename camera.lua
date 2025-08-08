-- Camera class for Love2D game
-- Handles camera movement and following the player

local Camera = {}
Camera.__index = Camera

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
    
    -- Screen dimensions
    self.screenWidth = love.graphics.getWidth()
    self.screenHeight = love.graphics.getHeight()
    
    return self
end

function Camera:update(player)
    -- Calculate target camera position to center player
    local windowWidth, windowHeight = love.graphics.getDimensions()
    
    -- Calculate scale to maintain aspect ratio
    local scaleX = windowWidth / self.baseWidth
    local scaleY = windowHeight / self.baseHeight
    local scale = math.min(scaleX, scaleY)
    
    -- Calculate camera position to center player
    local targetX = player.x - (windowWidth / scale) / 2
    local targetY = player.y - (windowHeight / scale) / 2
    
    self.x = targetX
    self.y = targetY
    self.scale = scale
end

function Camera:apply()
    love.graphics.push()
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
