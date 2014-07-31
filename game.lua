local gamestate = require "hump.gamestate"
local u = require "useful"
local Object = require "class"

local chain = require "chain"

local lg = love.graphics
local lm = love.mouse
local lk = love.keyboard

local colors = {{200, 60, 60}, {60, 200, 60}, {60, 60, 200}}
local pusherColor = {230, 230, 230}

local nballs = 50
local pushSpeed = 100
local maxSpeed = 400
local acc = 400
local radius = 20
local distance = radius * 2

-- temporary
local moving = true
local pusher

local Ball = Object:inherit()

function Ball:init(cx, color, ownSpeed)
    self.cx = cx
    self.color = color
    self.ownSpeed = ownSpeed or 0
    self.curSpeed = self.ownSpeed
    self.detached = false
end

function Ball:update(dt)
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
    self.balls = chain.Chain()
    self:spawnBalls(nballs)
    self.path = nil
end

function game:enter(previous, newpath)
    self.path = newpath
end

function game:spawnBalls(n)
    for i = 1, n do
        local ball = Ball(-distance * i, u.choice(colors))
        self.balls:insert(ball, self.balls.tail)
    end

    pusher = Pusher(-distance * (n + 1), pushSpeed)

    self.balls:insert(pusher, self.balls.tail)
end

function game:keypressed(key)
    if key == " " then
        gamestate.pop()
    elseif key == "p" then
        moving = not moving
        pusher.ownSpeed = moving and pushSpeed or 0
    end
end

function game:mousepressed(x, y, button)
    if button == "l" then
        for ball in self.balls:iter() do
            if ball.point and u.dist(x, y,
                              ball.point.x, ball.point.y) < radius then
                local prevBall = self.balls.links[ball].prev
                
                if prevBall then
                    if not prevBall.detached then
                        prevBall.detached = true
                        prevBall.curSpeed = ball.curSpeed
                    end
                end
                
                self.balls:remove(ball)
                
                break
            end
        end
    end
end

function game:update(dt)
    local nextBall = nil
    local nextDetached = nil

    for ball in self.balls:reverseIter() do
        if ball.detached then
            ball:update(dt)

            if not ball:is(Pusher) and nextBall then
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
        end

        nextBall = ball

        ball.point = self.path:getAt(ball.cx)
    end
end

function game:draw()
    self.path:draw()

    for ball in self.balls:iter() do
        ball:draw()
    end
end

return game
