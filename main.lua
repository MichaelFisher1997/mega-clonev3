-- Love2D 2D Game with Player Movement and Tilemap Collision
-- Author: Cascade AI

local Player = require("player")
local Camera = require("camera")
local Tilemap = require("tilemap")

-- Game state
local game = {
    map = nil,
    player = nil,
    camera = nil,
    walls = {},
    debug = false,
    tileSize = 16,
    mapWidth = 100,
    mapHeight = 100
}

function love.load()
    -- Set up dynamic resolution system
    love.window.setTitle("Love2D Retro Adventure")
    
    -- Base game resolution (12x12 tiles at 16x16 pixels each)
    game.baseWidth = 12 * 16
    game.baseHeight = 12 * 16
    game.tileSize = 16
    game.tilesX = 12
    game.tilesY = 12
    
    -- Set initial window size
    love.window.setMode(game.baseWidth, game.baseHeight, {
        resizable = true,
        minwidth = 192,
        minheight = 192
    })
    
    -- Set up scaling
    game.scaleX = 1
    game.scaleY = 1
    
    -- Create handmade tilemap
    game.tilemap = Tilemap.new()
    
    -- Initialize player at tile 8,10
    local playerStartX = 8 * game.tileSize
    local playerStartY = 10 * game.tileSize
    
    -- Create player
    game.player = Player.new(playerStartX, playerStartY)
    
    -- Create camera
    game.camera = Camera.new()
    
    -- Set up debug mode toggle
    game.debug = false
end

function love.update(dt)
    -- Update player
    game.player:update(dt, game.tilemap:getWalls())
    
    -- Update camera to follow player
    game.camera:update(game.player)
    
    -- Handle debug toggle
    if love.keyboard.isDown("f1") then
        game.debug = not game.debug
    end
    
    -- Handle fullscreen toggle
    if love.keyboard.isDown("f") and not game.fullscreenPressed then
        game.fullscreenPressed = true
        local fullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not fullscreen)
    elseif not love.keyboard.isDown("f") then
        game.fullscreenPressed = false
    end
end

function love.resize(w, h)
    -- Camera will automatically handle new dimensions
    game.camera:update(game.player)
end

function love.draw()
    -- Apply camera transform
    game.camera:apply()
    
    -- Draw the map background
    drawMap()
    
    -- Draw player
    game.player:draw()
    
    -- Draw debug info if enabled
    if game.debug then
        drawDebug()
    end
    
    -- Reset camera transform
    game.camera:reset()
    
    -- Draw UI elements (not affected by camera)
    drawUI()
end

function drawMap()
    -- Draw the actual handmade tilemap
    if game.tilemap then
        game.tilemap:draw()
    end
end

function drawDebug()
    -- Draw collision rectangles
    love.graphics.setColor(1, 0, 0, 0.5)
    for _, wall in ipairs(game.walls) do
        love.graphics.rectangle("line", wall.x, wall.y, wall.width, wall.height)
    end
    
    -- Draw player collision box
    love.graphics.setColor(0, 1, 0, 0.5)
    love.graphics.rectangle("line", 
        game.player.x - game.player.width/2, 
        game.player.y - game.player.height/2, 
        game.player.width, 
        game.player.height)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function drawUI()
    -- Draw UI elements (not affected by camera)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Controls:", 10, 10)
    love.graphics.print("WASD/Arrows: Move", 10, 30)
    love.graphics.print("F1: Toggle Debug", 10, 50)
    love.graphics.print("F: Toggle Fullscreen", 10, 70)
    love.graphics.print("Resize: Stretch window", 10, 90)
    
    if game.debug then
        love.graphics.print("Debug Mode: ON", 10, 110)
        love.graphics.print("Walls: " .. #game.walls, 10, 130)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
