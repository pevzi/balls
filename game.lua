local gamestate = require "hump.gamestate"
local u = require "useful"
local Object = require "class"

local chain = require "chain"

local lg = love.graphics
local lm = love.mouse
local lk = love.keyboard

local palettes = {
    -- palettes are from http://www.colourlovers.com
    {{120,75,121}, {78,205,196}, {232,255,107}, {232,126,40}, {196,77,88}}, -- monday cheer [3101907]
    -- {{66,66,84}, {100,144,138}, {232,202,164}, {204,42,65}}, -- you are beautiful [379413]
    {{101,86,67}, {128,188,163}, {246,247,189}, {230,172,39}, {191,77,40}}, -- headache [953498]
    -- {{247,120,37}, {211,206,61}, {241,239,165}, {96,185,154}}, -- mystery machine [940086]
}
local pusherColor = {230, 230, 230}

local nballs = 10
local maxSpeed = 400
local minSpeed = 10
local acc = 400
local radius = 20
local distance = radius * 2

local Ball = Object:inherit()

function Ball:init(cx, color, ownSpeed)
    self.cx = cx
    self.color = color
    self.ownSpeed = ownSpeed or 0
    self.curSpeed = self.ownSpeed
    self.detached = false
end

function Ball:update(dt)
    -- curSpeed changes towards ownSpeed
    if self.curSpeed ~= self.ownSpeed then
        local dist = self.ownSpeed - self.curSpeed
        local d = acc * dt
        if math.abs(dist) > d then
            self.curSpeed = self.curSpeed + u.sign(dist) * d
        else
            self.curSpeed = self.ownSpeed
        end
    end

    self.cx = self.cx + self.curSpeed * dt
end

function Ball:draw()
    if self.point then
        lg.setColor(self.color)
        lg.circle("fill", self.point.x, self.point.y, radius, 20)
    end
end

local Pusher = Ball:inherit()

function Pusher:init(cx, ownSpeed)
    self.super.init(self, cx, pusherColor, ownSpeed)
    self.detached = true
end

function Pusher:draw()
    if self.point then
        lg.setColor(self.color)
        lg.circle("line", self.point.x, self.point.y, radius, 20)
    end
end

local game = {}

function game:init()
    self.palette = u.choice(palettes)
    self.balls = chain.Chain()
    self:spawnBalls(nballs)
    self.path = nil
end

function game:enter(previous, newpath)
    self.path = newpath
end

function game:spawnBalls(n)
    local from = self.balls.tail and math.min(self.balls.tail.cx, 0) or 0

    for i = 1, n do
        local ball = Ball(from - distance * i, u.choice(self.palette))
        self.balls:insert(ball, self.balls.tail)
    end

    local pusher = Pusher(from - distance * (n + 1), maxSpeed)
    self.balls:insert(pusher, self.balls.tail)
end

function game:removeBall(ball)
    self:removeBalls(ball, ball)
end

function game:removeBalls(from, to)
    local prevBall = self.balls.links[from].prev

    if prevBall then
        if not prevBall.detached then
            prevBall.detached = true
            prevBall.curSpeed = from.curSpeed
        end
    end

    self.balls:removeRange(from, to)
end

function game:keypressed(key)
    if key == " " then
        gamestate.pop()
    elseif key == "return" then
        self:spawnBalls(nballs)
    end
end

function game:mousepressed(x, y, button)
    if button == "l" then
        for ball in self.balls:iter() do
            if ball.point and u.dist(x, y,
                              ball.point.x, ball.point.y) < radius then
                self:removeBall(ball)
                break
            end
        end
    end
end

function game:update(dt)
    local nextBall = nil
    local nextDetached = nil
    local nextPusher = nil

    local toRemove = {}

    for ball in self.balls:reverseIter() do
        if ball.detached then
            ball:update(dt)

            if ball:is(Pusher) then
                if nextBall and ball.cx < nextBall.cx + distance then
                    table.insert(toRemove, {from = ball, to = ball})
                else
                    nextPusher = ball
                end

            elseif nextBall then
                if ball.color == nextBall.color or nextBall:is(Pusher) then
                    ball.ownSpeed = -maxSpeed
                else
                    ball.ownSpeed = 0
                end

                if ball.cx < nextBall.cx + distance then
                    ball.cx = nextBall.cx + distance

                    -- this works wrong when they're
                    -- moving in the same direction
                    nextDetached.curSpeed = nextDetached.curSpeed
                                          + ball.curSpeed

                    ball.detached = false
                    ball.ownSpeed = 0
                    ball.curSpeed = 0
                end
            end

            nextDetached = ball
        else
            ball.cx = nextBall.cx + distance

            if nextPusher then
                nextPusher.ownSpeed = (1 - ball.cx / self.path.length)
                                    * maxSpeed + minSpeed
            end
        end

        nextBall = ball

        ball.point = self.path:getAt(ball.cx)
    end

    for i, v in ipairs(toRemove) do
        self:removeBalls(v.from, v.to)
    end
end

function game:draw()
    self.path:draw()

    for ball in self.balls:iter() do
        ball:draw()
    end
end

return game
