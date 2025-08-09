-- tilemap.lua
-- Handmade tilemap renderer for Level1

-- Handmade tilemap renderer for Level1
-- Uses direct map loading without STI dependency

local Tilemap = {}
Tilemap.__index = Tilemap

function Tilemap.new(mapModule)
    local self = setmetatable({}, Tilemap)
    
    -- Load the handmade tilemap data
    local modulePath = mapModule or "maps.Level1.Map1"
    -- Support paths with slashes
    if modulePath:find("/") then
        modulePath = modulePath:gsub("/", ".")
    end
    self.mapData = require(modulePath)
    self.mapModule = modulePath
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
    -- (logs suppressed)
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

-- Helper: check if a layer has an 'overhead' boolean property set to true.
function Tilemap:hasOverheadProperty(layer)
    local props = layer and layer.properties
    if not props then return false end
    -- Case 1: dictionary-style (props.overhead == true)
    if type(props) == "table" and props.overhead == true then
        return true
    end
    -- Case 2: array-style list of property tables from Tiled
    if type(props) == "table" then
        for _, p in ipairs(props) do
            if type(p) == "table" then
                local name = (p.name or ""):lower()
                local val = p.value
                if (name == "overhead" or name == "overlay") and (val == true or val == "true") then
                    return true
                end
            end
        end
    end
    return false
end

function Tilemap:isOverheadLayer(layer)
    if layer and layer.type == "tilelayer" then
        if self:hasOverheadProperty(layer) then
            return true
        end
        local name = (layer.name or ""):lower()
        if name == "overhead" or name == "overlay" or name == "top" or name == "above" then
            return true
        end
    end
    return false
end

function Tilemap:drawBaseLayers()
    if not self.mapData then return end
    for _, layer in ipairs(self.mapData.layers) do
        if layer.type == "tilelayer" and layer.visible and not self:isOverheadLayer(layer) then
            self:drawTileLayer(layer)
        end
    end
end

function Tilemap:drawOverheadLayers()
    if not self.mapData then return end
    for _, layer in ipairs(self.mapData.layers) do
        if layer.type == "tilelayer" and layer.visible and self:isOverheadLayer(layer) then
            self:drawTileLayer(layer)
        end
    end
end

function Tilemap:drawColoredTile(tileId, x, y)
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", x, y, self.tileSize, self.tileSize)
    love.graphics.setColor(1, 1, 1)
end

function Tilemap:draw(camera)
    -- Default draw: base layers only. Use drawOverheadLayers() after drawing entities.
    if not self.mapData then return end
    self:drawBaseLayers()
end

function Tilemap:drawDebugWalls()
    love.graphics.setColor(1, 1, 1, 0.7)
    for _, wall in ipairs(self.walls) do
        love.graphics.rectangle("line", wall.x, wall.y, wall.width, wall.height)
    end
    love.graphics.setColor(1, 1, 1, 1)
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
