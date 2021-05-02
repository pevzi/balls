local u = require "useful"

local Object = require "libs.class"
local chain = require "chain"

local lg = love.graphics

local w = lg.getWidth()
local h = lg.getHeight()

local function randomHandle(ox, oy, r)
    local angle = love.math.random() * math.pi * 2

    return ox + math.cos(angle) * r,
           oy + math.sin(angle) * r
end

local Handle = Object:inherit()

function Handle:init(x, y, p, curve, node, collinear)
    self.x = x
    self.y = y
    self.p = p
    self.curve = curve
    self.node = node
    self.collinear = collinear
end

function Handle:getCollinearPosition(distance)
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

function Handle:setPosition(x, y, updateCollinear)
    self.x = x
    self.y = y

    if updateCollinear and self.collinear then
        self.collinear:setPosition(self:getCollinearPosition())
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
                                 self.handle1.y + dy)
    end

    if self.handle2 then
        self.handle2:setPosition(self.handle2.x + dx,
                                 self.handle2.y + dy)
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
    self.nodes = chain.Chain()
    self.controlPoints = {} -- maybe try to make this one weak too
    self.colors = setmetatable({}, {__mode = "k"})
    self.points = {}
    self.length = 0
end

function Path:addNode(x, y)
    local node = Node(x, y)

    local tail = self.nodes.tail

    if tail then
        local curve, p2x, p2y, p3x, p3y

        local distance = u.dist(x, y, tail.x, tail.y) / 2

        if tail.handle2 then
            p2x, p2y = tail.handle2:getCollinearPosition(distance)
        else
            p2x, p2y = randomHandle(tail.x, tail.y, distance)
        end

        p3x, p3y = randomHandle(x, y, distance)

        curve = love.math.newBezierCurve(tail.x, tail.y, p2x, p2y,
            p3x, p3y, x, y)

        local c = love.math.random()
        self.colors[curve] = {c, 1 - c, 1 - c}

        tail.handle1 = Handle(p2x, p2y, 2, curve, tail, tail.handle2)
        if tail.handle2 then
            tail.handle2.collinear = tail.handle1
        end
        tail.curve1 = curve

        node.handle2 = Handle(p3x, p3y, -2, curve, node)
        node.curve2 = curve

        self:addControlPoint(tail.handle1)
        self:addControlPoint(node.handle2)
    end

    self.nodes:insert(node, tail)

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

    local links = self.nodes.links[node]
    local nextNode = links.next
    local prevNode = links.prev

    if nextNode then
        if prevNode then
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
        if prevNode then
            prevNode.curve1 = nil

            self:removeControlPoint(prevNode.handle1)
            prevNode.handle1 = nil
            if prevNode.handle2 then
                prevNode.handle2.collinear = nil
            end

            prevNode:updateCurve()
        end
    end

    self.nodes:remove(node)
end

function Path:addControlPoint(point)
    self.controlPoints[point] = true
end

function Path:removeControlPoint(point)
    self.controlPoints[point] = nil
end

function Path:updatePoints()
    self.points = {}
    self.length = 0

    for node in self.nodes:iter() do
        local curve = node.curve1

        if curve == nil then
            break
        end

        local dcurve = curve:getDerivative()

        local arg = 0
        while arg < 1 do
            local x, y = curve:evaluate(arg)

            local dx, dy
            if dcurve:getDegree() > 0 then
                dx, dy = dcurve:evaluate(arg)
            else
                dx, dy = dcurve:getControlPoint(1)
            end

            table.insert(self.points, {x = x, y = y, dx = dx, dy = dy})

            arg = arg + 1 / u.dist(dx, dy)

            self.length = self.length + 1
        end
    end
end

function Path:getAt(px)
    return self.points[math.floor(px + 0.5)]
end

function Path:draw(editing)
    for node in self.nodes:iter() do
        local curve = node.curve1

        if curve == nil then
            break
        end

        lg.setColor(self.colors[curve])
        lg.line(curve:render())
    end

    if editing then
        lg.setColor(1, 1, 1, 0.2)

        for point in pairs(self.controlPoints) do
            if point:is(Handle) then
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

return {
    Handle = Handle,
    Node = Node,
    Path = Path
}
