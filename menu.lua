-- menu.lua
-- A simple but stylish animated menu with keyboard, mouse, and touch support

local Screen = require("screen")
local Content = require("content")

-- Utility
local function clamp(v, a, b)
    if v < a then return a elseif v > b then return b else return v end
end

local Menu = {}
Menu.__index = Menu

function Menu.new(callbacks)
    local self = setmetatable({}, Menu)
    self.callbacks = callbacks or {}
    self.state = "main" -- main | options | character | level
    self.selectedCharacter = self.callbacks.initialCharacter or nil
    self.selectedLevel = self.callbacks.initialLevel or nil
    self.items = {
        { id = "start",   label = "Start Game", action = function() if self.callbacks.startGame then self.callbacks.startGame() end end },
        { id = "character", getLabel = function(s)
            return "Character: " .. (s.selectedCharacter or "-")
        end, action = function()
            self:enterCharacter()
        end },
        { id = "level", getLabel = function(s)
            local lbl = s.selectedLevel and Content.levelLabel(s.selectedLevel) or "-"
            return "Level: " .. lbl
        end, action = function()
            self.state = "level"; self.selected = 1; self:refreshLevels()
        end },
        { id = "options", label = "Options",    action = function() self.state = "options"; self.selected = 1; self:refreshOptions() end },
        { id = "quit",    label = "Quit",       action = function() if self.callbacks.quit then self.callbacks.quit() end end },
    }
    self.optionsItems = {}
    self.characterItems = {}
    self.levelItems = {}
    self.selected = 1
    self.hovered = nil
    self.time = 0

    -- Character carousel state
    self.charNames = Content.listCharacters()
    self.charIndex = 1
    if self.selectedCharacter and #self.charNames > 0 then
        for i, n in ipairs(self.charNames) do if n == self.selectedCharacter then self.charIndex = i break end end
    end
    self.charTransition = 0   -- -1 slide from right, +1 slide from left, 0 idle
    self.charProg = 1         -- 0..1 animation progress
    self.charSpacing = 64
    self.charScale = 3
    self.charWalkTimer = 0
    self.charWalkFrame = 1    -- 1 or 3 (standing is 2)
    self.charAnimSpeed = 0.35
    self.charCache = {}
    self.leftHover = false
    self.rightHover = false

    -- Fonts
    self.titleFont = love.graphics.newFont(20)
    self.itemFont  = love.graphics.newFont(12)
    self.hintFont  = love.graphics.newFont(8)

    -- Background starfield
    self.stars = {}
    local vw, vh = Screen.getVirtualSize()
    for i = 1, 80 do
        table.insert(self.stars, {
            x = love.math.random() * vw,
            y = love.math.random() * vh,
            spd = 10 + love.math.random() * 40,
            size = love.math.random(1, 2)
        })
    end

-- Enter character carousel submenu
function Menu:enterCharacter()
    self.charNames = Content.listCharacters()
    if #self.charNames == 0 then
        self.charIndex = 1
    else
        -- Sync index to current selectedCharacter if possible
        local idx = 1
        if self.selectedCharacter then
            for i, n in ipairs(self.charNames) do if n == self.selectedCharacter then idx = i break end end
        end
        self.charIndex = idx
    end
    self.charTransition = 0
    self.charProg = 1
    self.leftHover = false
    self.rightHover = false
    self.state = "character"
    self.selected = 1
end

function Menu:loadCharAsset(name)
    if not name then return nil end
    if self.charCache[name] then return self.charCache[name] end
    local path = Content.findCharacterSprite(name)
    if not path then return nil end
    local img = love.graphics.newImage(path)
    img:setFilter("nearest", "nearest")
    local frameW, frameH = 16, 20
    local quadsDown = {}
    for col = 0, 2 do
        quadsDown[col+1] = love.graphics.newQuad(col*frameW, 0, frameW, frameH, img:getWidth(), img:getHeight())
    end
    local asset = { image = img, frameW = frameW, frameH = frameH, quadsDown = quadsDown }
    self.charCache[name] = asset
    return asset
end

function Menu:prevCharacter()
    if #self.charNames == 0 then return end
    self.charIndex = ((self.charIndex - 2) % #self.charNames) + 1
    -- New selection should slide in from the left
    self.charTransition = -1
    self.charProg = 0
end

function Menu:nextCharacter()
    if #self.charNames == 0 then return end
    self.charIndex = (self.charIndex % #self.charNames) + 1
    -- New selection should slide in from the right
    self.charTransition = 1
    self.charProg = 0
end

    return self
end

function Menu:refreshOptions()
    local pixel = Screen.isPixelPerfect()
    self.optionsItems = {
        { id = "pp",   label = "Pixel Perfect: " .. (pixel and "On" or "Off"), action = function()
            if self.callbacks.togglePixelPerfect then self.callbacks.togglePixelPerfect() end
            self:refreshOptions()
        end },
        { id = "fs",   label = "Fullscreen", action = function()
            if self.callbacks.toggleFullscreen then self.callbacks.toggleFullscreen() end
            self:refreshOptions()
        end },
        { id = "back", label = "Back", action = function()
            self.state = "main"; self.selected = 2
        end },
    }
end

function Menu:refreshCharacters()
    local list = {}
    local chars = Content.listCharacters()
    if #chars == 0 then
        table.insert(list, { id = "none", label = "No characters found", action = function() end })
    else
        for _, name in ipairs(chars) do
            table.insert(list, {
                id = "char:"..name,
                label = name .. (self.selectedCharacter == name and "  (selected)" or ""),
                action = function()
                    self.selectedCharacter = name
                    if self.callbacks.setCharacter then self.callbacks.setCharacter(name) end
                    self.state = "main"; self.selected = 2
                end
            })
        end
    end
    table.insert(list, { id = "back", label = "Back", action = function() self.state = "main"; self.selected = 2 end })
    self.characterItems = list
end

function Menu:refreshLevels()
    local list = {}
    local mods = Content.listLevels()
    if #mods == 0 then
        table.insert(list, { id = "none", label = "No levels found", action = function() end })
    else
        for _, mod in ipairs(mods) do
            local label = Content.levelLabel(mod)
            local suffix = (self.selectedLevel == mod) and "  (selected)" or ""
            table.insert(list, {
                id = "lvl:"..mod,
                label = label .. suffix,
                action = function()
                    self.selectedLevel = mod
                    if self.callbacks.setLevel then self.callbacks.setLevel(mod) end
                    self.state = "main"; self.selected = 3
                end
            })
        end
    end
    table.insert(list, { id = "back", label = "Back", action = function() self.state = "main"; self.selected = 3 end })
    self.levelItems = list
end

function Menu:update(dt)
    self.time = self.time + dt
    -- Animate stars
    local vw, vh = Screen.getVirtualSize()
    for _, s in ipairs(self.stars) do
        s.y = s.y + s.spd * dt
        if s.y > vh then
            s.y = -2
            s.x = love.math.random() * vw
        end
    end
    -- Character carousel animation
    if self.state == "character" then
        -- Walk animation: toggle between frames 1 and 3
        self.charWalkTimer = self.charWalkTimer + dt
        if self.charWalkTimer >= self.charAnimSpeed then
            self.charWalkTimer = 0
            self.charWalkFrame = (self.charWalkFrame == 1) and 3 or 1
        end
        if self.charTransition ~= 0 and self.charProg < 1 then
            self.charProg = clamp(self.charProg + dt * 6, 0, 1)
            if self.charProg >= 1 then
                self.charTransition = 0
            end
        end
    end
end

function Menu:currentList()
    if self.state == "options" then
        if #self.optionsItems == 0 then self:refreshOptions() end
        return self.optionsItems
    elseif self.state == "character" then
        if #self.characterItems == 0 then self:refreshCharacters() end
        return self.characterItems
    elseif self.state == "level" then
        if #self.levelItems == 0 then self:refreshLevels() end
        return self.levelItems
    end
    return self.items
end

function Menu:drawBackground()
    local vw, vh = Screen.getVirtualSize()
    love.graphics.clear(0.05, 0.07, 0.12, 1)
    love.graphics.setColor(1, 1, 1, 0.2)
    for _, s in ipairs(self.stars) do
        love.graphics.rectangle("fill", math.floor(s.x), math.floor(s.y), s.size, s.size)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setColor(0, 0, 0, 0.08)
    for y = 0, vh, 2 do
        love.graphics.rectangle("fill", 0, y, vw, 1)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Menu:draw()
    self:drawBackground()

    local vw, vh = Screen.getVirtualSize()
    love.graphics.setFont(self.titleFont)
    local title = "Mega Bomberman"
    local tw = self.titleFont:getWidth(title)
    local wobble = math.sin(self.time * 2) * 2
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(title, math.floor((vw - tw) / 2), 28 + wobble)

    if self.state == "character" then
        self:drawCharacterSelect()
        love.graphics.setFont(self.hintFont)
        local hint = "Left/Right: Browse  •  Enter: Select  •  Esc: Back  •  Tap arrows"
        local hw = self.hintFont:getWidth(hint)
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.print(hint, math.floor((vw - hw) / 2), vh - 20)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    local list = self:currentList()
    love.graphics.setFont(self.itemFont)
    local startY = 80
    local spacing = 18

    for i, item in ipairs(list) do
        local label = (item.getLabel and item.getLabel(self)) or item.label
        local iw = self.itemFont:getWidth(label)
        local ih = self.itemFont:getHeight()
        local x = math.floor((vw - iw) / 2)
        local y = startY + (i - 1) * spacing
        local isSel = (i == self.selected)
        local isHover = (self.hovered == i)
        local color = isSel and {0.95, 0.85, 0.3, 1} or isHover and {0.8, 0.8, 0.9, 1} or {1, 1, 1, 0.9}
        love.graphics.setColor(color)
        love.graphics.print(label, x, y)
        if isSel then
            love.graphics.setColor(0.95, 0.85, 0.3, 1)
            love.graphics.print(">", x - 14, y)
            love.graphics.print("<", x + iw + 4, y)
            love.graphics.setColor(1, 1, 1, 1)
        end
        if isHover and not isSel then
            love.graphics.setColor(1, 1, 1, 0.5)
            love.graphics.rectangle("fill", x, y + ih - 2, iw, 1)
        end
    end

    love.graphics.setFont(self.hintFont)
    local hint
    if self.state == "main" then
        hint = "Enter: Select  •  Up/Down: Navigate  •  Mouse/Touch: Tap"
    else
        hint = "Enter: Select  •  Esc: Back"
    end
    local hw = self.hintFont:getWidth(hint)
    love.graphics.setColor(1, 1, 1, 0.6)
    love.graphics.print(hint, math.floor((vw - hw) / 2), vh - 20)
    love.graphics.setColor(1, 1, 1, 1)
end

function Menu:drawCharacterSelect()
    local vw, vh = Screen.getVirtualSize()
    local cx = math.floor(vw / 2)
    local floorY = 124 -- floor line for feet anchoring
    local spacing = self.charSpacing
    local slideOffset = (self.charTransition ~= 0) and (self.charTransition * (1 - self.charProg) * spacing) or 0

    -- Arrows
    local ax = 24
    local ay = floorY - 12
    love.graphics.setFont(self.itemFont)
    love.graphics.setColor(self.leftHover and {0.95,0.85,0.3,1} or {1,1,1,0.8})
    love.graphics.print("<", ax, ay)
    self.leftRect = {x = ax, y = ay, w = self.itemFont:getWidth("<"), h = self.itemFont:getHeight()}
    love.graphics.setColor(self.rightHover and {0.95,0.85,0.3,1} or {1,1,1,0.8})
    local rx = vw - ax - self.itemFont:getWidth(">")
    love.graphics.print(">", rx, ay)
    self.rightRect = {x = rx, y = ay, w = self.itemFont:getWidth(">"), h = self.itemFont:getHeight()}

    -- Draw nearby entries (center +/- 2)
    if #self.charNames == 0 then
        love.graphics.setColor(1,1,1,0.7)
        love.graphics.printf("No characters found", 0, floorY - 10, vw, "center")
        love.graphics.setColor(1,1,1,1)
        return
    end

    for di = -2, 2 do
        local i = ((self.charIndex - 1 + di) % #self.charNames) + 1
        local name = self.charNames[i]
        local asset = self:loadCharAsset(name)
        if asset then
            local isCenter = (di == 0)
            local scale = self.charScale * (isCenter and 1.0 or 0.85)
            local x = cx + di * spacing + slideOffset
            local y = floorY
            -- Choose frame: center animates between 1 and 3, sides use standing (2)
            local frameIndex = isCenter and self.charWalkFrame or 2
            local quad = asset.quadsDown[frameIndex]
            -- Anchor feet on floor
            local drawX = math.floor(x - (asset.frameW * scale) / 2)
            local drawY = math.floor(y - asset.frameH * scale)
            love.graphics.setColor(1,1,1, isCenter and 1 or 0.9)
            love.graphics.draw(asset.image, quad, drawX, drawY, 0, scale, scale)
            -- Label under center
            if isCenter then
                love.graphics.setFont(self.itemFont)
                local label = name
                local lw = self.itemFont:getWidth(label)
                love.graphics.setColor(1,1,1,0.9)
                love.graphics.print(label, math.floor(x - lw/2), y + 6)
            end
        end
    end
    love.graphics.setColor(1,1,1,1)
end

function Menu:keypressed(key)
    if self.state == "character" then
        if key == "left" or key == "a" then
            self:prevCharacter()
        elseif key == "right" or key == "d" then
            self:nextCharacter()
        elseif key == "return" or key == "space" or key == "kpenter" then
            -- Confirm selection
            local name = self.charNames[self.charIndex]
            if name then
                self.selectedCharacter = name
                if self.callbacks.setCharacter then self.callbacks.setCharacter(name) end
            end
            self.state = "main"; self.selected = 2
        elseif key == "escape" then
            self.state = "main"; self.selected = 2
        end
        return
    end
    local list = self:currentList()
    if key == "up" or key == "w" then
        self.selected = ((self.selected - 2) % #list) + 1
    elseif key == "down" or key == "s" then
        self.selected = (self.selected % #list) + 1
    elseif key == "return" or key == "space" or key == "kpenter" then
        self:activate(self.selected)
    elseif key == "escape" then
        if self.state == "options" then
            self.state = "main"; self.selected = 2
        elseif self.state == "character" then
            self.state = "main"; self.selected = 2
        elseif self.state == "level" then
            self.state = "main"; self.selected = 3
        end
    end
end

function Menu:activate(index)
    local list = self:currentList()
    local item = list[index]
    if item and item.action then item.action() end
end

function Menu:mousepressed(x, y, button)
    if button ~= 1 then return end
    if self.state == "character" then
        -- Check arrows
        if self.leftRect and x >= self.leftRect.x and x <= self.leftRect.x + self.leftRect.w and y >= self.leftRect.y and y <= self.leftRect.y + self.leftRect.h then
            self:prevCharacter(); return
        end
        if self.rightRect and x >= self.rightRect.x and x <= self.rightRect.x + self.rightRect.w and y >= self.rightRect.y and y <= self.rightRect.y + self.rightRect.h then
            self:nextCharacter(); return
        end
        -- Click near center to select
        local vw, vh = Screen.getVirtualSize()
        local cx = math.floor(vw / 2)
        local floorY = 124
        local scale = self.charScale
        local w = 16 * scale
        local h = 20 * scale
        local x0 = cx - w/2
        local y0 = floorY - h
        if x >= x0 and x <= x0 + w and y >= y0 and y <= y0 + h then
            local name = self.charNames[self.charIndex]
            if name then
                self.selectedCharacter = name
                if self.callbacks.setCharacter then self.callbacks.setCharacter(name) end
            end
            self.state = "main"; self.selected = 2
        end
        return
    end
    local list = self:currentList()
    local vw, vh = Screen.getVirtualSize()
    love.graphics.setFont(self.itemFont)
    local startY = 80
    local spacing = 18
    for i, item in ipairs(list) do
        local label = (item.getLabel and item.getLabel(self)) or item.label
        local iw = self.itemFont:getWidth(label)
        local ih = self.itemFont:getHeight()
        local x0 = math.floor((vw - iw) / 2)
        local y0 = startY + (i - 1) * spacing
        if x >= x0 and x <= x0 + iw and y >= y0 and y <= y0 + ih then
            self.selected = i
            self:activate(i)
            return
        end
    end
end

function Menu:mousemove(x, y)
    if self.state == "character" then
        self.leftHover = false
        self.rightHover = false
        if self.leftRect and x >= self.leftRect.x and x <= self.leftRect.x + self.leftRect.w and y >= self.leftRect.y and y <= self.leftRect.y + self.leftRect.h then
            self.leftHover = true
        elseif self.rightRect and x >= self.rightRect.x and x <= self.rightRect.x + self.rightRect.w and y >= self.rightRect.y and y <= self.rightRect.y + self.rightRect.h then
            self.rightHover = true
        end
        return
    end
    local list = self:currentList()
    local vw, vh = Screen.getVirtualSize()
    love.graphics.setFont(self.itemFont)
    local startY = 80
    local spacing = 18
    self.hovered = nil
    for i, item in ipairs(list) do
        local label = (item.getLabel and item.getLabel(self)) or item.label
        local iw = self.itemFont:getWidth(label)
        local ih = self.itemFont:getHeight()
        local x0 = math.floor((vw - iw) / 2)
        local y0 = startY + (i - 1) * spacing
        if x >= x0 and x <= x0 + iw and y >= y0 and y <= y0 + ih then
            self.hovered = i
            break
        end
    end
end

return Menu
