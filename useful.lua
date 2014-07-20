local function dist2(x1, y1, x2, y2)
    x2 = x2 or 0
    y2 = y2 or 0

    return (x1 - x2) ^ 2 + (y1 - y2) ^ 2
end

local function dist(x1, y1, x2, y2)
    return math.sqrt(dist2(x1, y1, x2, y2))
end

local function randomHandle(ox, oy, r)
    local angle = math.random() * math.pi * 2

    return ox + math.cos(angle) * r,
           oy + math.sin(angle) * r
end

local useful = {
    dist = dist,
    dist2 = dist2,
    randomHandle = randomHandle
}

return useful
