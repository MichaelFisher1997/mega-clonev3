-- bomb.lua
-- Simple Bomberman-style bomb with ticking animation and cross explosion

local Bomb = {}
Bomb.__index = Bomb

local function loadAssets()
    local bombPath = 'images/bombs/Bomb.png'
    local expPath = 'images/bombs/Explosion.png'
    local bombImg, expImg
    if love.filesystem.getInfo(bombPath) then
        bombImg = love.graphics.newImage(bombPath)
        bombImg:setFilter('nearest', 'nearest')
    end
    if love.filesystem.getInfo(expPath) then
        expImg = love.graphics.newImage(expPath)
        expImg:setFilter('nearest', 'nearest')
    end
    return bombImg, expImg
end

function Bomb.new(x, y, opts)
    local self = setmetatable({}, Bomb)
    opts = opts or {}
    self.x, self.y = x, y -- tile-centered world coords (center of the tile)
    self.tileSize = opts.tileSize or 16
    self.range = opts.range or 2
    self.fuse = opts.fuse or 1.5
    self.explosionTime = 0.30
    self.time = 0
    self.state = 'ticking' -- ticking | exploding | done
    self.bombImg, self.explosionImg = loadAssets()
    self.scalePulse = 0
    self.explosionTiles = nil -- list of {cx, cy}
    self.getWalls = opts.getWalls -- function to get walls at explosion time
    return self
end

local function rectsIntersect(a, b)
    return not (a.x + a.w <= b.x or b.x + b.w <= a.x or a.y + a.h <= b.y or b.y + b.h <= a.y)
end

function Bomb:computeExplosion()
    self.explosionTiles = {}
    local T = self.tileSize
    -- self.x,self.y are at tile center; convert to tile index
    local gx = math.floor(self.x / T)
    local gy = math.floor(self.y / T)

    -- helper to check if a tile is blocked by any wall
    local walls = self.getWalls and self.getWalls() or {}
    local function blockedAt(tx, ty)
        local r = { x = tx * T, y = ty * T, w = T, h = T }
        for _, w in ipairs(walls) do
            local wr = { x = w.x, y = w.y, w = w.width, h = w.height }
            if rectsIntersect(r, wr) then return true end
        end
        return false
    end

    -- center always included (visual)
    table.insert(self.explosionTiles, { gx, gy })

    -- rays in 4 directions
    local dirs = { {1,0}, {-1,0}, {0,1}, {0,-1} }
    for _, d in ipairs(dirs) do
        local dx, dy = d[1], d[2]
        for step = 1, self.range do
            local tx, ty = gx + dx*step, gy + dy*step
            if blockedAt(tx, ty) then
                break
            end
            table.insert(self.explosionTiles, { tx, ty })
        end
    end
end

function Bomb:update(dt)
    if self.state == 'done' then return end
    self.time = self.time + dt
    if self.state == 'ticking' then
        -- flicker pulse (0..1) used for noticeable brightness, speeds up as fuse runs out
        local p = math.min(self.time / math.max(self.fuse, 0.0001), 1)
        self.scalePulse = 0.5 + 0.5 * math.sin(self.time * (8 + 16 * p))
        if self.time >= self.fuse then
            self.state = 'exploding'
            self.time = 0
            self:computeExplosion()
        end
    elseif self.state == 'exploding' then
        if self.time >= self.explosionTime then
            self.state = 'done'
        end
    end
end

function Bomb:isDone()
    return self.state == 'done'
end

function Bomb:isExploding()
    return self.state == 'exploding'
end

function Bomb:getExplosionTiles()
    return self.explosionTiles or {}
end

function Bomb:draw()
    local T = self.tileSize
    if self.state == 'ticking' then
        if self.bombImg then
            local img = self.bombImg
            local iw, ih = img:getWidth(), img:getHeight()
            local ox = math.floor(iw/2)
            local oy = math.floor(ih)
            -- Base scale so bomb occupies exactly 1 tile
            local baseSx = T / iw
            local baseSy = T / ih
            local sx = baseSx
            local sy = baseSy
            -- draw with bottom anchored to tile floor
            local drawX = math.floor(self.x)
            local drawY = math.floor(self.y + T/2)
            -- high-contrast flicker: toggle brightness sharply for noticeability
            local on = (self.scalePulse or 0) > 0.5
            local tint = on and 1.0 or 0.55
            love.graphics.setColor(tint, tint, tint, 1)
            love.graphics.draw(img, drawX, drawY, 0, sx, sy, ox, oy)
            love.graphics.setColor(1,1,1,1)
        else
            love.graphics.setColor(0,0,0)
            love.graphics.circle('fill', math.floor(self.x), math.floor(self.y + T/2), 4 + 2*(self.scalePulse or 0))
            love.graphics.setColor(1,1,1)
            love.graphics.circle('line', math.floor(self.x), math.floor(self.y + T/2), 4 + 2*(self.scalePulse or 0))
        end
    elseif self.state == 'exploding' then
        if self.explosionImg then
            local img = self.explosionImg
            local iw, ih = img:getWidth(), img:getHeight()
            local sx = T / iw
            local sy = T / ih
            love.graphics.setColor(1,1,1,1)
            for _, t in ipairs(self.explosionTiles or {}) do
                local x0 = math.floor(t[1] * T)
                local y0 = math.floor(t[2] * T)
                love.graphics.draw(img, x0, y0, 0, sx, sy)
            end
        else
            -- fallback: simple cross of tiles
            love.graphics.setColor(1.0, 0.8, 0.2, 0.9)
            for _, t in ipairs(self.explosionTiles or {}) do
                local x0 = math.floor(t[1] * T)
                local y0 = math.floor(t[2] * T)
                love.graphics.rectangle('fill', x0, y0, T, T)
            end
            love.graphics.setColor(1,1,1,1)
        end
    end
end

return Bomb
