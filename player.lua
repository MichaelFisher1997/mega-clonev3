-- Player class for Love2D game
-- Handles player movement, animation, and collision

local Player = {}
Player.__index = Player

-- Player constants
local PLAYER_SPEED = 150
local PLAYER_WIDTH = 16
local PLAYER_HEIGHT = 20
local TILE_SIZE = 16
local MOVE_SPEED = 8  -- pixels per frame for smooth tile-to-tile movement

function Player.new(x, y)
    local self = setmetatable({}, Player)
    
    -- Initialize player state
    self.x = x
    self.y = y
    self.width = 16  -- Collision width for tile grid
    self.height = 16  -- Collision height for tile grid
    self.direction = "down"
    self.isMoving = false
    self.sprite = nil
    self.quads = nil
    self.animationTimer = 0
    self.currentFrame = 1
    self.isAnimating = false
    
    -- Grid movement system
    self.targetX = x
    self.targetY = y
    self.isMoving = false
    self.tileX = math.floor(x / TILE_SIZE)
    self.tileY = math.floor(y / TILE_SIZE)
    self.moveSpeed = 8  -- pixels per frame for smooth movement
    self.moveProgress = 0
    self.totalMoveTime = 16 / self.moveSpeed  -- time to move one tile
    self.startX = x
    self.startY = y
    
    -- Load player sprites
    self:loadSprites()
    
    -- Movement state
    self.direction = "down"
    self.isMoving = false
    
    return self
end

function Player:loadSprites()
    -- Load the 16x16 player sprite sheet
    local spritePath = "images/player/character_1/character_1_frame16x20.png"
    
    -- Load the sprite sheet
    self.sprite = nil
    if love.filesystem.getInfo(spritePath) then
        self.sprite = love.graphics.newImage(spritePath)
        
        -- Sprite sheet dimensions (16x20 frames)
        self.spriteWidth = 48   -- 3 frames * 16px
        self.spriteHeight = 80  -- 4 rows * 20px
        self.frameWidth = 16
        self.frameHeight = 20
        
        -- Update player collision dimensions to fit 16x16 tile grid
        self.width = 16  -- Collision width for tile grid
        self.height = 16  -- Collision height for tile grid
        
        -- Create quads for each frame
        self.quads = {}
        for row = 0, 3 do  -- 4 directions
            self.quads[row] = {}
            for col = 0, 2 do  -- 3 frames per direction
                local quad = love.graphics.newQuad(
                    col * self.frameWidth, 
                    row * self.frameHeight, 
                    self.frameWidth, 
                    self.frameHeight,
                    self.sprite:getWidth(),
                    self.sprite:getHeight()
                )
                table.insert(self.quads[row], quad)
            end
        end
    else
        -- Fallback dimensions
        self.width = 16
        self.height = 16
    end
    
    -- Animation system
    -- Row mapping: 0=down, 1=left, 2=right, 3=up
    self.animationFrames = {
        down = {0, 1, 2},    -- Row 0: face down
        left = {0, 1, 2},  -- Row 1: face left  
        right = {0, 1, 2}, -- Row 2: face right
        up = {0, 1, 2}     -- Row 3: face up
    }
    
    self.animationSpeed = 0.15  -- seconds per frame
    self.animationTimer = 0
    self.currentFrame = 1
    self.isAnimating = false
end

function Player:update(dt, walls)
    -- Handle grid-based movement with smooth animation
    if not self.isMoving then
        -- Check for new movement input
        local newTileX, newTileY = self.tileX, self.tileY
        local newDirection = self.direction
        
        if love.keyboard.isDown("w", "up") then
            newTileY = self.tileY - 1
            newDirection = "up"
        elseif love.keyboard.isDown("s", "down") then
            newTileY = self.tileY + 1
            newDirection = "down"
        elseif love.keyboard.isDown("a", "left") then
            newTileX = self.tileX - 1
            newDirection = "left"
        elseif love.keyboard.isDown("d", "right") then
            newTileX = self.tileX + 1
            newDirection = "right"
        end
        
        -- Check if we can move to the new tile position
        if newTileX ~= self.tileX or newTileY ~= self.tileY then
            local targetX = newTileX * TILE_SIZE
            local targetY = newTileY * TILE_SIZE
            
            if self:canMoveTo(targetX, targetY, walls) then
                -- Start movement to new tile
                self.isMoving = true
                self.direction = newDirection
                self.tileX = newTileX
                self.tileY = newTileY
                self.startX = self.x
                self.startY = self.y
                self.targetX = targetX
                self.targetY = targetY
                self.moveProgress = 0
                
                -- Update animation
                self.isAnimating = true
                self.currentFrame = 2  -- Walking frame
            end
        end
    else
        -- Continue movement animation
        self.moveProgress = self.moveProgress + dt * self.moveSpeed
        
        if self.moveProgress >= 1 then
            -- Movement complete
            self.x = self.targetX
            self.y = self.targetY
            self.isMoving = false
            self.moveProgress = 0
            self.isAnimating = false
            self.currentFrame = 1  -- Standing frame
        else
            -- Interpolate position during movement
            self.x = self.startX + (self.targetX - self.startX) * self.moveProgress
            self.y = self.startY + (self.targetY - self.startY) * self.moveProgress
            
            -- Update walking animation
            self.animationTimer = self.animationTimer + dt
            if self.animationTimer >= self.animationSpeed then
                self.animationTimer = 0
                -- Toggle between walking frames
                self.currentFrame = self.currentFrame == 2 and 3 or 2
            end
        end
    end
    
    -- Update sprite animation
    if self.sprite and self.quads then
        local directionMap = {
            down = 0,
            left = 1,
            right = 2,
            up = 3
        }
        
        local row = directionMap[self.direction]
        if row then
            local quadIndex = row * 3 + self.currentFrame
            if self.quads[quadIndex] then
                self.currentQuad = self.quads[quadIndex]
            end
        end
    end
end

function Player:canMoveTo(newX, newY, walls)
    -- Calculate player collision box
    local left = newX - self.width / 2
    local right = newX + self.width / 2
    local top = newY - self.height / 2
    local bottom = newY + self.height / 2
    
    -- Check against each wall
    for _, wall in ipairs(walls) do
        if self:rectanglesIntersect(left, top, self.width, self.height,
                                  wall.x, wall.y, wall.width, wall.height) then
            return false
        end
    end
    
    return true
end

function Player:rectanglesIntersect(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

function Player:draw()
    if self.sprite and self.quads then
        -- Map direction to row
        local directionMap = {
            down = 0,
            left = 1,
            right = 2,
            up = 3
        }
        
        local row = directionMap[self.direction]
        if not row then return end
        
        -- Get the correct quad for current frame
        local quad = self.quads[row][self.currentFrame]
        if not quad then return end
        
        -- Calculate draw position (center sprite)
        local drawX = self.x - self.width/2
        local drawY = self.y - self.height/2
        
        -- Draw the sprite
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.sprite, quad, drawX, drawY)
        
    else
        -- Fallback to colored rectangle if no sprite
        love.graphics.setColor(0.2, 0.6, 1.0)  -- Blue color
        
        -- Draw player rectangle
        love.graphics.rectangle("fill", 
            self.x - self.width/2, 
            self.y - self.height/2, 
            self.width, 
            self.height)
        
        -- Draw direction indicator
        love.graphics.setColor(1, 1, 1)
        local dirX, dirY = 0, 0
        
        if self.direction == "up" then dirY = -8
        elseif self.direction == "down" then dirY = 8
        elseif self.direction == "left" then dirX = -8
        elseif self.direction == "right" then dirX = 8
        end
        
        love.graphics.line(self.x, self.y, self.x + dirX, self.y + dirY)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

return Player
