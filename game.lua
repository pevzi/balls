local gamestate = require "hump.gamestate"

local lg = love.graphics
local lm = love.mouse
local lk = love.keyboard

local cspeed = 100
local radius = 20
local nballs = 8

local game = {}

function game:init()
    self.balls = {}
    self.path = nil
end

function game:enter(previous, newpath)
    self.path = newpath
end

function game:keypressed(key)
    if key == " " then
        gamestate.pop()
    end
end

function game:update(dt)
    if lk.isDown("left") then
        cspeed = cspeed - 10
    elseif lk.isDown("right") then
        cspeed = cspeed + 10
    end

    local last = self.balls[#self.balls]

    if #self.balls < nballs and (last == nil or last > radius * 2) then
        table.insert(self.balls, (last or 0) - radius * 2)
    end

    for i, cx in ipairs(self.balls) do
        self.balls[i] = cx + cspeed * dt
        if self.balls[i] > #self.path.points and i == nballs then
            self.balls = {}
            break
        end
    end
end

function game:draw()
    self.path:draw()

    lg.setColor(230, 230, 230)

    for i, cx in ipairs(self.balls) do
        local p = self.path.points[math.floor(cx + 0.5)]
        if p then
            lg.circle("fill", p.x, p.y, radius, 20)
        end
    end
end

return game
