local lg = love.graphics

local w = lg.getWidth()
local h = lg.getHeight()

local cspeed = 300
local radius = 20
local nballs = 8

local curve, points, balls

function curveToPoints(curve, step)
    step = step or 1

    local dcurve = curve:getDerivative()

    local points = {}
    local arg = 0

    while arg <= 1 do
        local x, y = curve:evaluate(arg)
        table.insert(points, {x = x, y = y})

        local dx, dy = dcurve:evaluate(arg)
        arg = arg + step / math.sqrt(dx ^ 2 + dy ^ 2)
    end

    return points
end

function makeRandomCurve(n)
    local curve = love.math.newBezierCurve()

    for i = 1, n do
        curve:insertControlPoint(math.random(w), math.random(h))
    end

    return curve
end

function init()
    curve = makeRandomCurve(4)
    points = curveToPoints(curve)
    balls = {}
end

function love.load()
    math.randomseed(os.time())

    init()
end

function love.keypressed(key)
    if key == " " then
        init()
    end
end

function love.update(dt)
    local last = balls[#balls]

    if #balls < nballs and (last == nil or last > radius * 2) then
        table.insert(balls, (last or 0) - radius * 2)
    end

    for i, cx in ipairs(balls) do
        balls[i] = cx + cspeed * dt
        if balls[i] > #points and i == nballs then
            init()
            break
        end
    end
end

function love.draw()
    for i, cx in ipairs(balls) do
        local p = points[math.floor(cx + 0.5)]
        if p then
            lg.circle("fill", p.x, p.y, radius, 20)
        end
    end
end