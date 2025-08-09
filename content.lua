-- content.lua
-- Helpers to enumerate available characters and levels dynamically

local Content = {}

local function isDir(path)
    local info = love.filesystem.getInfo(path)
    return info and info.type == 'directory'
end

local function isFile(path)
    local info = love.filesystem.getInfo(path)
    return info and info.type == 'file'
end

-- List character directories under images/player
function Content.listCharacters()
    local base = 'images/player'
    local items = {}
    if not isDir(base) then return items end
    for _, name in ipairs(love.filesystem.getDirectoryItems(base)) do
        local p = base .. '/' .. name
        if isDir(p) then table.insert(items, name) end
    end
    table.sort(items, function(a, b)
        local na = a:match('%d+')
        local nb = b:match('%d+')
        if na and nb then
            na, nb = tonumber(na), tonumber(nb)
            if na ~= nb then return na < nb end
            return a:lower() < b:lower()
        end
        -- fallback lexicographic
        return a:lower() < b:lower()
    end)
    return items
end

-- Find first PNG inside a character folder (for loading)
function Content.findCharacterSprite(character)
    local base = 'images/player/' .. character
    if not isDir(base) then return nil end
    -- Prefer naming convention: <folder>_frame16x20.png
    local preferred = base .. '/' .. character .. '_frame16x20.png'
    if isFile(preferred) then return preferred end
    -- Otherwise pick first .png
    for _, name in ipairs(love.filesystem.getDirectoryItems(base)) do
        if name:lower():match('%.png$') then
            local p = base .. '/' .. name
            if isFile(p) then return p end
        end
    end
    return nil
end

-- Recursively list map modules matching maps/**/Map*.lua
local function scanMaps(dir, out)
    out = out or {}
    for _, name in ipairs(love.filesystem.getDirectoryItems(dir)) do
        local p = dir .. '/' .. name
        local info = love.filesystem.getInfo(p)
        if info then
            if info.type == 'directory' then
                scanMaps(p, out)
            elseif info.type == 'file' and name:match('^Map.+%.lua$') then
                local mod = p:gsub('%.lua$', ''):gsub('/', '.')
                table.insert(out, mod)
            end
        end
    end
    return out
end

function Content.listLevels()
    if not isDir('maps') then return {} end
    local modules = scanMaps('maps', {})
    table.sort(modules)
    return modules
end

-- Turn maps.Level1.Map1 into Level1/Map1 (for display)
function Content.levelLabel(modulePath)
    local label = modulePath
    label = label:gsub('^maps%.', '')
    label = label:gsub('%.', '/')
    return label
end

return Content
