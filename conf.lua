-- Configuration file for Love2D game

function love.conf(t)
    t.window.title = "Love2D RPG Adventure"
    t.window.width = 1024
    t.window.height = 768
    t.window.resizable = false
    t.window.vsync = 1
    
    -- For development
    t.console = true
end
