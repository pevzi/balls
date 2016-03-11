local sqrt = math.sqrt
local floor = math.floor
local random = love.math.random

local function dist2(x1, y1, x2, y2)
    x2 = x2 or 0
    y2 = y2 or 0

    return (x1 - x2) ^ 2 + (y1 - y2) ^ 2
end

local function dist(x1, y1, x2, y2)
    return sqrt(dist2(x1, y1, x2, y2))
end

local function choice(t)
    return t[random(#t)]
end

local function sign(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    else
        return 0
    end
end

local useful = {
    dist = dist,
    dist2 = dist2,
    choice = choice,
    sign = sign,
}

return useful
