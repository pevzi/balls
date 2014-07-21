local u = require "useful"

local Object = require "class"

local lg = love.graphics

local w = lg.getWidth()
local h = lg.getHeight()

local Handle = Object:inherit()

function Handle:init(x, y, p, curve, node, collinear)
    self.x = x
    self.y = y
    self.p = p
    self.curve = curve
    self.node = node
    self.collinear = collinear
end

function Handle:getCollinear(distance)
    local d1 = u.dist(self.node.x, self.node.y, self.x, self.y)
    local d2 = distance or u.dist(self.node.x, self.node.y,
        self.collinear.x, self.collinear.y)
    local k = d2 / d1

    if k < math.huge then
        return self.node.x - (self.x - self.node.x) * k,
               self.node.y - (self.y - self.node.y) * k
    else
        return self.collinear.x, self.collinear.y
    end
end

function Handle:setPosition(x, y, noUpdateCollinear)
    self.x = x
    self.y = y

    if not noUpdateCollinear and self.collinear then
        local collX, collY = self:getCollinear()
        self.collinear:setPosition(collX, collY, true)
    end

    self:updateCurve()
end

function Handle:updateCurve()
    self.curve:setControlPoint(self.p, self.x, self.y)
end

local Node = Object:inherit()

function Node:init(x, y)
    self.x = x
    self.y = y
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
        self.curve2:setControlPoint(-1, self.x, self.y)
    end
end

local Path = Object:inherit()

function Path:init()
    self.head = nil
    self.tail = nil
    self.controlPoints = {} -- maybe try to make this one weak too
    self.colors = setmetatable({}, {__mode = "k"})
    self.points = {}
end

function Path:addNode(x, y)
    local node = Node(x, y)

    if self.tail then
        local curve, p2x, p2y, p3x, p3y

        local distance = u.dist(x, y, self.tail.x, self.tail.y) / 2

        if self.tail.handle2 then
            p2x, p2y = self.tail.handle2:getCollinear(distance)
        else
            p2x, p2y = u.randomHandle(self.tail.x, self.tail.y, distance)
        end

        p3x, p3y = u.randomHandle(x, y, distance)

        curve = love.math.newBezierCurve(self.tail.x, self.tail.y, p2x, p2y,
            p3x, p3y, x, y)

        local c = math.random(0, 255)
        self.colors[curve] = {c, 255 - c, 255 - c}

        self.tail.handle1 = Handle(p2x, p2y, 2, curve, self.tail,
            self.tail.handle2)
        if self.tail.handle2 then
            self.tail.handle2.collinear = self.tail.handle1
        end
        self.tail.curve1 = curve

        node.handle2 = Handle(p3x, p3y, -2, curve, node)
        node.curve2 = curve

        self:addControlPoint(self.tail.handle1)
        self:addControlPoint(node.handle2)
    end

    if self.tail then
        node.prev = self.tail
        self.tail.next = node
    else
        self.head = node
    end

    self.tail = node

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
        local nextNode = node.next

        if node.prev then
            nextNode.curve2 = node.curve2
            nextNode:updateCurve()
            
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
    else
        if node.prev then
            local prevNode = node.prev

            prevNode.curve1 = nil

            self:removeControlPoint(prevNode.handle1)
            prevNode.handle1 = nil
            if prevNode.handle2 then
                prevNode.handle2.collinear = nil
            end

            prevNode:updateCurve()
        end
    end

    if node.prev then
        node.prev.next = node.next
    else
        self.head = self.head.next
    end

    if node.next then
        node.next.prev = node.prev
    else
        self.tail = self.tail.prev
    end
end

function Path:curves()
    local function f(head, node)
        local nextNode

        if node then
            nextNode = node.next
        else
            nextNode = head
        end

        if nextNode and nextNode.curve1 then
            return nextNode, nextNode.curve1
        end
    end

    return f, self.head, nil
end

function Path:addControlPoint(point)
    self.controlPoints[point] = true
end

function Path:removeControlPoint(point)
    self.controlPoints[point] = nil
end

function Path:updatePoints()
    self.points = {}

    for _, curve in self:curves() do
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

            arg = arg + 1 / u.dist(dx, dy)
        end
    end
end

function Path:draw(editing)
    for _, curve in self:curves() do
        lg.setColor(self.colors[curve])
        lg.line(curve:render())
    end

    if editing then
        lg.setColor(255, 255, 255, 60)

        for point in pairs(self.controlPoints) do
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

return Path
