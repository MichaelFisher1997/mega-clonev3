-- tilemap.lua
-- Handmade tilemap renderer for Level1

-- Handmade tilemap renderer for Level1
-- Uses direct map loading without STI dependency

local Tilemap = {}
Tilemap.__index = Tilemap

function Tilemap.new(mapData)
    local self = setmetatable({}, Tilemap)
    
    -- Load the handmade tilemap data
    self.mapData = require("maps.Level1.Map1")
    self.tileSize = 16
    self.walls = {}
    self.tilesets = {}
    
    -- Load tileset images
    self:loadTilesets()
    
    -- Parse collision data from map
    self:parseCollisionData()
    
    return self
end

function Tilemap:loadTilesets()
    -- Load tileset images with proper path resolution
    self.tilesets = {}
    
    for _, tileset in ipairs(self.mapData.tilesets) do
        local imagePath = tileset.image
        if imagePath then
            -- Construct full path relative to maps/Level1/
            local fullPath = "maps/Level1/" .. imagePath
            
            -- Try to load the image
            local success, image = pcall(love.graphics.newImage, fullPath)
            if success and image then
                image:setFilter("nearest", "nearest")
                
                -- Store tileset data
                self.tilesets[tileset.firstgid] = {
                    image = image,
                    tilewidth = tileset.tilewidth,
                    tileheight = tileset.tileheight,
                    columns = tileset.columns,
                    firstgid = tileset.firstgid,
                    tilecount = tileset.tilecount,
                    imagewidth = tileset.imagewidth,
                    imageheight = tileset.imageheight
                }
            else
                print("Failed to load tileset image: " .. fullPath)
            end
        end
    end
end

function Tilemap:parseCollisionData()
    -- Parse collision data from Walls object layer
    self.walls = {}
    
    -- Find the Walls layer
    for _, layer in ipairs(self.mapData.layers) do
        if layer.name == "Walls" and layer.type == "objectgroup" then
            for _, obj in ipairs(layer.objects) do
                if obj.shape == "rectangle" then
                    table.insert(self.walls, {
                        x = obj.x,
                        y = obj.y,
                        width = obj.width,
                        height = obj.height
                    })
                end
            end
            break
        end
    end
    
    -- Debug: print found walls
    if #self.walls > 0 then
        print("Found " .. #self.walls .. " collision walls")
        for i, wall in ipairs(self.walls) do
            print("Wall " .. i .. ": x=" .. wall.x .. ", y=" .. wall.y .. ", w=" .. wall.width .. ", h=" .. wall.height)
        end
    end
end

function Tilemap:getTileAt(x, y, layerName)
    -- Get tile ID at specific coordinates
    for _, layer in ipairs(self.mapData.layers) do
        if layer.name == layerName then
            local data = layer.data
            local index = y * layer.width + x + 1
            return data[index] or 0
        end
    end
    return 0
end

function Tilemap:drawTileLayer(layer)
    if not layer.data then return end
    
    local data = layer.data
    local width = layer.width
    local height = layer.height
    
    love.graphics.setColor(1, 1, 1)
    
    -- Draw each tile
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local index = y * width + x + 1
            local tileId = data[index]
            
            if tileId and tileId > 0 then
                local tileX = x * self.tileSize
                local tileY = y * self.tileSize
                
                -- Find which tileset this tile belongs to
                local tileset = self:getTilesetForTile(tileId)
                if tileset and tileset.image then
                    local localId = tileId - tileset.firstgid
                    local tilesPerRow = tileset.columns
                    local tilesetX = (localId % tilesPerRow) * tileset.tilewidth
                    local tilesetY = math.floor(localId / tilesPerRow) * tileset.tileheight
                    
                    -- Create quad for this tile
                    local quad = love.graphics.newQuad(
                        tilesetX, tilesetY,
                        tileset.tilewidth, tileset.tileheight,
                        tileset.imagewidth, tileset.imageheight
                    )
                    
                    love.graphics.draw(tileset.image, quad, tileX, tileY)
                else
                    -- Fallback: draw colored rectangle
                    self:drawColoredTile(tileId, tileX, tileY)
                end
            end
        end
    end
end

function Tilemap:getTilesetForTile(tileId)
    for _, tileset in pairs(self.tilesets) do
        if tileId >= tileset.firstgid and tileId < tileset.firstgid + tileset.tilecount then
            return tileset
        end
    end
    return nil
end

function Tilemap:drawColoredTile(tileId, x, y)
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", x, y, self.tileSize, self.tileSize)
    love.graphics.setColor(1, 1, 1)
end

function Tilemap:draw(camera)
    -- Draw the actual handmade tilemap
    if not self.mapData then return end
    
    -- Draw tiles
    local layers = self.mapData.layers
    for _, layer in ipairs(layers) do
        if layer.type == "tilelayer" and layer.visible then
            self:drawTileLayer(layer)
        end
    end
    
    -- Draw collision boxes in white for debugging
    love.graphics.setColor(1, 1, 1, 0.7)  -- White with slight transparency
    for _, wall in ipairs(self.walls) do
        love.graphics.rectangle("line", wall.x, wall.y, wall.width, wall.height)
    end
    love.graphics.setColor(1, 1, 1, 1)  -- Reset to white
end

function Tilemap:getWalls()
    return self.walls
end

function Tilemap:getDimensions()
    return {
        width = self.mapData.width * self.tileSize,
        height = self.mapData.height * self.tileSize
    }
end

return Tilemap
