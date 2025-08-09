-- screen.lua
-- Virtual resolution and letterboxing manager for Love2D
-- Renders the game to a fixed-size canvas and scales it to fit any window/device

local Screen = {}
Screen.__index = Screen

function Screen.new()
    local self = setmetatable({}, Screen)
    self.virtualWidth = 192
    self.virtualHeight = 192
    self.pixelPerfect = true
    self.scale = 1
    self.offsetX = 0
    self.offsetY = 0
    self.barColor = {0, 0, 0, 1}
    self.clearColor = {0, 0, 0, 0}
    self.canvas = nil
    return self
end

local instance

local function computeScaleAndOffset(vw, vh, ww, wh, pixelPerfect)
    local sx = ww / vw
    local sy = wh / vh
    local scale = math.min(sx, sy)
    if pixelPerfect and scale >= 1 then
        scale = math.floor(scale)
    end
    -- Guard against 0 scale on tiny windows
    if scale < 0.01 then scale = 0.01 end
    local drawW = vw * scale
    local drawH = vh * scale
    local ox = math.floor((ww - drawW) / 2)
    local oy = math.floor((wh - drawH) / 2)
    return scale, ox, oy
end

local function ensureCanvas(vw, vh)
    if instance.canvas then
        local cw, ch = instance.canvas:getDimensions()
        if cw == vw and ch == vh then
            return
        end
    end
    instance.canvas = love.graphics.newCanvas(vw, vh)
    instance.canvas:setFilter('nearest', 'nearest')
end

function Screen.init(vw, vh, opts)
    instance = Screen.new()
    instance.virtualWidth = vw
    instance.virtualHeight = vh
    if opts then
        if opts.pixelPerfect ~= nil then instance.pixelPerfect = opts.pixelPerfect end
        if opts.barColor then instance.barColor = opts.barColor end
    end
    love.graphics.setDefaultFilter('nearest', 'nearest')
    ensureCanvas(vw, vh)
    local ww, wh = love.graphics.getDimensions()
    instance.scale, instance.offsetX, instance.offsetY = computeScaleAndOffset(vw, vh, ww, wh, instance.pixelPerfect)
end

function Screen.resize(ww, wh)
    if not instance then return end
    instance.scale, instance.offsetX, instance.offsetY = computeScaleAndOffset(instance.virtualWidth, instance.virtualHeight, ww, wh, instance.pixelPerfect)
end

function Screen.setPixelPerfect(enabled)
    if not instance then return end
    instance.pixelPerfect = enabled and true or false
    local ww, wh = love.graphics.getDimensions()
    instance.scale, instance.offsetX, instance.offsetY = computeScaleAndOffset(instance.virtualWidth, instance.virtualHeight, ww, wh, instance.pixelPerfect)
end

function Screen.isPixelPerfect()
    return instance and instance.pixelPerfect or false
end

function Screen.toggleFullscreen()
    local isFull = love.window.getFullscreen()
    love.window.setFullscreen(not isFull)
    local ww, wh = love.graphics.getDimensions()
    Screen.resize(ww, wh)
end

function Screen.getVirtualSize()
    if not instance then return 0, 0 end
    return instance.virtualWidth, instance.virtualHeight
end

function Screen.getScale()
    if not instance then return 1 end
    return instance.scale
end

function Screen.getOffset()
    if not instance then return 0, 0 end
    return instance.offsetX, instance.offsetY
end

function Screen.begin()
    if not instance then return end
    ensureCanvas(instance.virtualWidth, instance.virtualHeight)
    love.graphics.push()
    love.graphics.origin()
    love.graphics.setCanvas(instance.canvas)
    love.graphics.clear(0, 0, 0, 0)
end

function Screen.finish()
    if not instance then return end
    love.graphics.setCanvas()
    love.graphics.pop()
    -- Clear screen for letterbox/pillarbox bars
    love.graphics.clear(instance.barColor[1], instance.barColor[2], instance.barColor[3], instance.barColor[4])
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(instance.canvas, instance.offsetX, instance.offsetY, 0, instance.scale, instance.scale)
end

function Screen.toVirtual(x, y)
    if not instance then return x, y end
    local vx = (x - instance.offsetX) / instance.scale
    local vy = (y - instance.offsetY) / instance.scale
    return vx, vy
end

return Screen
