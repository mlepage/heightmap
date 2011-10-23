-- Heightmap module
-- Copyright (C) 2011 Marc Lepage

local max, random = math.max, math.random

module(...)

-- Find power of two sufficient for size
local function pot(size)
    local pot = 2
    while true do
        if size <= pot then return pot end
        pot = 2*pot
    end
end

-- Create a table with 0 to n zero values
local function tcreate(n)
    local t = {}
    for i = 0, n do t[i] = 0 end
    return t
end

-- Square step
-- Sets map[x][y] from square of radius d using height function f
local function square(map, x, y, d, f)
    local sum, num = 0, 0
    if 0 <= x-d then
        if   0 <= y-d   then sum, num = sum + map[x-d][y-d], num + 1 end
        if y+d <= map.h then sum, num = sum + map[x-d][y+d], num + 1 end
    end
    if x+d <= map.w then
        if   0 <= y-d   then sum, num = sum + map[x+d][y-d], num + 1 end
        if y+d <= map.h then sum, num = sum + map[x+d][y+d], num + 1 end
    end
    map[x][y] = f(map, x, y, d, sum/num)
end

-- Diamond step
-- Sets map[x][y] from diamond of radius d using height function f
local function diamond(map, x, y, d, f)
    local sum, num = 0, 0
    if   0 <= x-d   then sum, num = sum + map[x-d][y], num + 1 end
    if x+d <= map.w then sum, num = sum + map[x+d][y], num + 1 end
    if   0 <= y-d   then sum, num = sum + map[x][y-d], num + 1 end
    if y+d <= map.h then sum, num = sum + map[x][y+d], num + 1 end
    map[x][y] = f(map, x, y, d, sum/num)
end

-- Diamond square algorithm generates cloud/plasma fractal heightmap
-- http://en.wikipedia.org/wiki/Diamond-square_algorithm
-- Size must be power of two
-- Height function f must look like f(map, x, y, d, h) and return h'
local function diamondsquare(size, f)
    -- create map
    local map = { w = size, h = size }
    for c = 0, size do map[c] = tcreate(size) end
    -- seed four corners
    local d = size
    map[0][0] = f(map, 0, 0, d, 0)
    map[0][d] = f(map, 0, d, d, 0)
    map[d][0] = f(map, d, 0, d, 0)
    map[d][d] = f(map, d, d, d, 0)
    d = d/2
    -- perform square and diamond steps
    while 1 <= d do
        for x = d, map.w-1, 2*d do
            for y = d, map.h-1, 2*d do
                square(map, x, y, d, f)
            end
        end
        for x = d, map.w-1, 2*d do
            for y = 0, map.h, 2*d do
                diamond(map, x, y, d, f)
            end
        end
        for x = 0, map.w, 2*d do
            for y = d, map.h-1, 2*d do
                diamond(map, x, y, d, f)
            end
        end
        d = d/2
    end
    return map
end

-- Default height function
-- d is depth (from size to 1 by powers of two)
-- h is mean height at map[x][y] (from square/diamond of radius d)
-- returns h' which is used to set map[x][y]
function defaultf(map, x, y, d, h)
    return h + (random()-0.5)*d
end

-- Create a heightmap using the specified height function (or default)
-- map[x][y] where x from 0 to map.w and y from 0 to map.h
function create(width, height, f)
    f = f and f or defaultf
    -- make heightmap
    local map = diamondsquare(pot(max(width, height)), f)
    -- clip heightmap to desired size
    for x = 0, map.w do for y = height+1, map.h do map[x][y] = nil end end
    for x = width+1, map.w do map[x] = nil end
    map.w, map.h = width, height
    return map
end
