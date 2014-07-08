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

    if not noUpdateCollinear and self.collinear then
        local collX, collY = getCollinear(x, y, self.node.x, self.node.y,
            self.collinear.x, self.collinear.y)
        self.collinear:setPosition(collX, collY, true)
    end

    self:updateCurve()
end

function Handle:updateCurve()
    self.curve:setControlPoint(self.p, self.x, self.y)
end

local Node = {}
Node.__index = Node

local function newNode(x, y)
    local self = setmetatable({}, Node)

    self.x = x
    self.y = y

    return self
end

function Node:setPosition(x, y)
    local dx, dy = x - self.x, y - self.y -- shit

    self.x = x
    self.y = y

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

    self:updateCurve()
end

function Node:updateCurve() -- or curves?
    if self.curve1 then
        self.curve1:setControlPoint(1, self.x, self.y)
    end

    if self.curve2 then
        self.curve2:setControlPoint(4, self.x, self.y)
    end
end

local Path = {}
Path.__index = Path

function newPath()
    local self = setmetatable({}, Path)

    self.tail = nil
    self.curves = {}
    self.colors = {}
    self.points = {}

    return self
end

function Path:addNode(x, y)
    local node = newNode(x, y)

    if self.tail then
        local curve, p2x, p2y, p3x, p3y

        if self.tail.handle2 then
            p2x, p2y = getCollinear(self.tail.handle2.x, self.tail.handle2.y,
                self.tail.x, self.tail.y)
        else
            p2x, p2y = math.random(w), math.random(h)
        end

        p3x, p3y = math.random(w), math.random(h)

        curve = love.math.newBezierCurve(self.tail.x, self.tail.y, p2x, p2y,
            p3x, p3y, x, y)

        self.tail.handle1 = newHandle(p2x, p2y, 2, curve, self.tail,
            self.tail.handle2)
        if self.tail.handle2 then
            self.tail.handle2.collinear = self.tail.handle1
        end
        self.tail.curve1 = curve

        node.handle2 = newHandle(p3x, p3y, 3, curve, node)
        node.curve2 = curve

        self:addCurve(curve)

        self:addControlPoint(self.tail.handle1)
        self:addControlPoint(node.handle2)
    end

    self:addControlPoint(node)

    return node
end

function Path:removeNode(node)
    if node.handle1 then
        self:removeControlPoint(node.handle1)
    end

    if node.handle2 then
        self:removeControlPoint(node.handle2)
    end

    self:removeControlPoint(node)

    if node.next then
        self:removeCurve(node.curve1)

        local nextNode = node.next.next

        if node.prev then
            nextNode.curve2 = node.curve2
            nextNode.handle2.curve = node.curve2
            nextNode.handle2:updateCurve()
        else
            nextNode.curve2 = nil
            self:removeControlPoint(nextNode.handle2)
            nextNode.handle2 = nil
            if nextNode.handle1 then
                nextNode.handle1.collinear = nil
            end
        end

        nextNode:updateCurve()
    else
        if node.prev then
            local prevNode = node.prev.prev

            self:removeCurve(prevNode.curve1)
            self:removeControlPoint(prevNode.handle1)
            prevNode.curve1 = nil
            prevNode.handle1 = nil
            if prevNode.handle2 then
                prevNode.handle2.collinear = nil
            end

            prevNode:updateCurve()
        end
    end
end

function Path:addControlPoint(point)
    if self.tail then
        point.prev = self.tail
        self.tail.next = point
    end

    self.tail = point
end

function Path:removeControlPoint(point)
    if point.prev then
        point.prev.next = point.next
    end

    if point.next then
        point.next.prev = point.prev
    end

    if point == self.tail then -- redundant?
        self.tail = self.tail.prev
    end
end

function Path:controlPoints()
    local function f(tail, point)
        if point then
            return point.prev
        else
            return tail
        end
    end

    return f, self.tail, nil
end

function Path:addCurve(curve)
    local c = math.random(0, 255)
    local color = {c, 255 - c, 255 - c}

    table.insert(self.curves, curve)
    table.insert(self.colors, color)
end

function Path:removeCurve(curve)
    -- shit

    for i, c in ipairs(self.curves) do
        if c == curve then
            table.remove(self.curves, i)
            table.remove(self.colors, i)
            return
        end
    end
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

        for point in self:controlPoints() do
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
