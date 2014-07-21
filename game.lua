local gamestate = require "hump.gamestate"

local lg = love.graphics
local lm = love.mouse
local lk = love.keyboard

local cspeed = 100
local radius = 20
local nballs = 8

local path, balls

local game = {}

function game:init()
    balls = {}
end

function game:enter(previous, newpath)
    path = newpath
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

    local last = balls[#balls]

    if #balls < nballs and (last == nil or last > radius * 2) then
        table.insert(balls, (last or 0) - radius * 2)
    end

    for i, cx in ipairs(balls) do
        balls[i] = cx + cspeed * dt
        if balls[i] > #path.points and i == nballs then
            balls = {}
            break
        end
    end
end

function game:draw()
    path:draw()

    lg.setColor(230, 230, 230)

    for i, cx in ipairs(balls) do
        local p = path.points[math.floor(cx + 0.5)]
        if p then
            lg.circle("fill", p.x, p.y, radius, 20)
        end
    end
end

return game
