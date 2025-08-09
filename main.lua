-- Love2D 2D Game with Player Movement and Tilemap Collision
-- Author: Cascade AI

local Player = require("player")
local Camera = require("camera")
local Tilemap = require("tilemap")
local Screen = require("screen")
local Menu = require("menu")
local Content = require("content")

-- Game state
local game = {
    map = nil,
    player = nil,
    camera = nil,
    walls = {},
    debug = false,
    tileSize = 16,
    mapWidth = 100,
    mapHeight = 100,
    state = "menu", -- menu | playing | options
    menu = nil
    , selectedCharacter = nil
    , selectedLevel = nil
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
        minheight = 192,
        highdpi = true
    })
    
    -- Initialize virtual resolution/letterboxing
    Screen.init(game.baseWidth, game.baseHeight, { pixelPerfect = true, barColor = {0,0,0,1} })
    
    -- Defer creating tilemap until Start Game (based on selected level)
    game.tilemap = nil
    
    -- Initialize default selections from available content
    local chars = Content.listCharacters()
    game.selectedCharacter = chars[1] or "character_1"
    local levels = Content.listLevels()
    game.selectedLevel = levels[1] or "maps.Level1.Map1"
    
    -- Player and tilemap will be created when starting the game
    game.player = nil
    
    -- Create camera
    game.camera = Camera.new()
    
    -- Set up debug mode toggle
    game.debug = false
    
    -- Create menu and set initial state
    game.state = "menu"
    game.menu = Menu.new({
        -- Defaults to display in menu
        initialCharacter = game.selectedCharacter,
        initialLevel = game.selectedLevel,
        
        startGame = function()
            -- Create chosen level and player, then enter gameplay
            local playerStartX = 8 * game.tileSize
            local playerStartY = 10 * game.tileSize
            
            -- Load selected level
            game.tilemap = Tilemap.new(game.selectedLevel)
            
            -- Create player with selected character
            game.player = Player.new(playerStartX, playerStartY, { character = game.selectedCharacter })
            
            -- Ensure camera exists and focuses player
            if not game.camera then
                game.camera = Camera.new()
            end
            game.camera:update(game.player)
            
            game.state = "playing"
        end,
        toggleFullscreen = function()
            Screen.toggleFullscreen()
        end,
        togglePixelPerfect = function()
            Screen.setPixelPerfect(not Screen.isPixelPerfect())
        end,
        setCharacter = function(name)
            game.selectedCharacter = name
        end,
        setLevel = function(modulePath)
            game.selectedLevel = modulePath
        end,
        quit = function()
            love.event.quit()
        end
    })
end

function love.update(dt)
    if game.state == "menu" then
        if game.menu and game.menu.update then game.menu:update(dt) end
        return
    end
    
    -- Playing state updates
    game.player:update(dt, game.tilemap:getWalls())
    game.camera:update(game.player)
end

function love.resize(w, h)
    Screen.resize(w, h)
    if game.state == "playing" then
        game.camera:update(game.player)
    end
end

function love.draw()
    Screen.begin()
    if game.state == "menu" then
        if game.menu and game.menu.draw then game.menu:draw() end
    else
        -- Apply camera for world rendering
        game.camera:apply()
        drawMap()
        game.player:draw()
        if game.tilemap then game.tilemap:drawOverheadLayers() end
        if game.debug then drawDebug() end
        game.camera:reset()
        drawUI()
    end
    Screen.finish()
end

function drawMap()
    -- Draw the actual handmade tilemap
    if game.tilemap then
        game.tilemap:draw()
    end
end

function drawDebug()
    -- Draw collision rectangles (from tilemap)
    if game.tilemap then
        game.tilemap:drawDebugWalls()
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
    love.graphics.print("Esc: Menu", 10, 90)
    
    if game.debug then
        love.graphics.print("Debug Mode: ON", 10, 110)
        local wallCount = game.tilemap and #game.tilemap:getWalls() or 0
        love.graphics.print("Walls: " .. wallCount, 10, 130)
    end
end

function love.keypressed(key)
    if game.state == "menu" then
        if game.menu and game.menu.keypressed then game.menu:keypressed(key) end
        return
    end
    
    if key == "escape" then
        game.state = "menu"
        return
    end
    if key == "f" then
        Screen.toggleFullscreen()
        return
    end
    if key == "f1" then
        game.debug = not game.debug
        return
    end
end

function love.mousepressed(x, y, button)
    if game.state == "menu" and game.menu and game.menu.mousepressed then
        local vx, vy = Screen.toVirtual(x, y)
        game.menu:mousepressed(vx, vy, button)
    end
end

function love.mousemoved(x, y, dx, dy, istouch)
    if game.state == "menu" and game.menu and game.menu.mousemove then
        local vx, vy = Screen.toVirtual(x, y)
        game.menu:mousemove(vx, vy)
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    if game.state == "menu" and game.menu and game.menu.mousepressed then
        local ww, wh = love.graphics.getDimensions()
        local px, py = x * ww, y * wh
        local vx, vy = Screen.toVirtual(px, py)
        game.menu:mousepressed(vx, vy, 1)
    end
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if game.state == "menu" and game.menu and game.menu.mousemove then
        local ww, wh = love.graphics.getDimensions()
        local px, py = x * ww, y * wh
        local vx, vy = Screen.toVirtual(px, py)
        game.menu:mousemove(vx, vy)
    end
end
