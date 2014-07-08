local lg = love.graphics

local w = lg.getWidth()
local h = lg.getHeight()

local function getCollinear(x, y, ox, oy, px, py, dir)
    dir = dir or -1

    local k = px and math.sqrt(
        ((px - ox) ^ 2 + (py - oy) ^ 2)
        / ((x - ox) ^ 2 + (y - oy) ^ 2)
        ) or 1

    if k < math.huge then
        return (ox + dir * (x - ox) * k), (oy + dir * (y - oy) * k)
    else
        return px, py
    end
end

local Handle = {}
Handle.__index = Handle

local function newHandle(x, y, p, curve, node, collinear)
    local self = setmetatable({}, Handle)

    self.x = x
    self.y = y
    self.p = p
    self.curve = curve
    self.node = node
    self.collinear = collinear

    return self
end

function Handle:setPosition(x, y, noUpdateCollinear)
    self.x = x
    self.y = y

    self.curve:setControlPoint(self.p, x, y)

    if not noUpdateCollinear and self.collinear then
        local collX, collY = getCollinear(x, y, self.node.x, self.node.y,
            self.collinear.x, self.collinear.y)
        self.collinear:setPosition(collX, collY, true)
    end
end

local Node = {}
Node.__index = Node

local function newNode(x, y, curve1, curve2, handle1, handle2)
    local self = setmetatable({}, Node)

    self.x = x
    self.y = y
    self.curve1 = curve1
    self.curve2 = curve2
    self.handle1 = handle1
    self.handle2 = handle2

    return self
end

function Node:setPosition(x, y)
    local dx, dy = x - self.x, y - self.y

    if self.curve1 then
        self.curve1:setControlPoint(1, x, y)
    end

    if self.curve2 then
        self.curve2:setControlPoint(4, x, y)
    end

    if self.handle1 then
        self.handle1:setPosition(self.handle1.x + dx,
                                 self.handle1.y + dy,
                                 true)
    end

    if self.handle2 then
        self.handle2:setPosition(self.handle2.x + dx,
                                 self.handle2.y + dy,
                                 true)
    end

    self.x = x
    self.y = y
end

local Path = {}
Path.__index = Path

function newPath()
    local self = setmetatable({}, Path)

    self.controlPoints = {}
    self.curves = {}
    self.colors = {}
    self.points = {}

    return self
end

function Path:addNode(x, y)
    local node = newNode(x, y)

    local last = self.controlPoints[#self.controlPoints]

    if last then
        local curve, p2x, p2y, p3x, p3y

        if last.handle2 then
            p2x, p2y = getCollinear(last.handle2.x, last.handle2.y,
                last.x, last.y)
        else
            p2x, p2y = math.random(w), math.random(h)
        end

        p3x, p3y = math.random(w), math.random(h)

        curve = love.math.newBezierCurve(last.x, last.y, p2x, p2y,
            p3x, p3y, x, y)

        last.handle1 = newHandle(p2x, p2y, 2, curve, last, last.handle2)
        if last.handle2 then
            last.handle2.collinear = last.handle1
        end
        last.curve1 = curve

        node.handle2 = newHandle(p3x, p3y, 3, curve, node)
        node.curve2 = curve

        self:addCurve(curve)

        table.insert(self.controlPoints, last.handle1)
        table.insert(self.controlPoints, node.handle2)
    end

    table.insert(self.controlPoints, node)

    return node
end

function Path:addCurve(curve)
    local c = math.random(0, 255)
    local color = {c, 255 - c, 255 - c}

    table.insert(self.curves, curve)
    table.insert(self.colors, color)
end

function Path:updatePoints()
    self.points = {}

    for _, curve in ipairs(self.curves) do
        local dcurve = curve:getDerivative()

        local arg = 0
        while arg < 1 do
            local x, y = curve:evaluate(arg)
            table.insert(self.points, {x = x, y = y})

            local dx, dy
            if dcurve:getDegree() > 0 then
                dx, dy = dcurve:evaluate(arg)
            else
                dx, dy = dcurve:getControlPoint(1)
            end

            arg = arg + 1 / math.sqrt(dx ^ 2 + dy ^ 2)
        end
    end
end

function Path:draw(editing)
    for c, curve in ipairs(self.curves) do
        lg.setColor(self.colors[c])
        lg.line(curve:render())
    end

    if editing then
        lg.setColor(255, 255, 255, 60)

        for p, point in ipairs(self.controlPoints) do
            if point.node then
                lg.line(point.x, point.y, point.node.x, point.node.y)
                lg.circle("line", point.x, point.y, 5, 16)
            else
                if point.curve1 then
                    lg.circle("fill", point.x, point.y, 10, 16)
                else
                    lg.circle("line", point.x, point.y, 5, 16)
                end
            end
        end
    end
end
