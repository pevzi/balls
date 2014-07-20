local newPath = require "path"
local u = require "useful"

local lg = love.graphics
local lm = love.mouse
local lk = love.keyboard

local w = lg.getWidth()
local h = lg.getHeight()

local cspeed = 100
local radius = 20
local nballs = 8

local path, balls, drag, moving

local function init()
    path = newPath()

    path:updatePoints()

    balls = {}
    drag = nil
    moving = false
end

function love.load()
    math.randomseed(os.time())

    lg.setBackgroundColor(30, 30, 30)

    init()
end

function love.mousepressed(x, y, button)
    if moving then
        return
    end

    for point in pairs(path.controlPoints) do
        if u.dist2(x, y, point.x, point.y) < 400 then
            if button == "l" then
                drag = point
                return
            elseif button == "r" and not point.node then
                --                   ^^^^ shit ^^^^
                -- must have some distinctive thing for nodes and handles
                path:removeNode(point)
                path:updatePoints()
                drag = nil
                return
            end
        end
    end

    if button == "l" then
        drag = path:addNode(x, y)
    end
end

function love.mousereleased(x, y, button)
    drag = nil
end

function love.keypressed(key)
    if key == "return" then
        init()
    elseif key == " " then
        moving = not moving
        drag = nil
    elseif key == "escape" then
        love.event.quit()
    end
end

function love.update(dt)
    if lk.isDown("left") then
        cspeed = cspeed - 10
    elseif lk.isDown("right") then
        cspeed = cspeed + 10
    end

    if drag then
        drag:setPosition(lm.getX(), lm.getY(), lk.isDown("lshift"))
        path:updatePoints()
    end

    if moving then
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
end

function love.draw()
    path:draw(not moving)

    lg.setColor(230, 230, 230)

    for i, cx in ipairs(balls) do
        local p = path.points[math.floor(cx + 0.5)]
        if p then
            lg.circle("fill", p.x, p.y, radius, 20)
        end
    end
end
