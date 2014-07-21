local gamestate = require "hump.gamestate"
local u = require "useful"

local game = require "game"
local Path = require "path"

local lg = love.graphics
local lm = love.mouse
local lk = love.keyboard

local path, drag

local editor = {}

function editor:init()
    path = Path()
end

function editor:mousepressed(x, y, button)
    for point in pairs(path.controlPoints) do
        if u.dist2(x, y, point.x, point.y) < 400 then
            if button == "l" then
                drag = point
                return
            elseif button == "r" and not point.node then
                --                   ^^^^ shit ^^^^
                -- must have some distinctive thing for nodes and handles
                path:removeNode(point)
                drag = nil
                return
            end
        end
    end

    if button == "l" then
        drag = path:addNode(x, y)
    end
end

function editor:mousereleased(x, y, button)
    drag = nil
end

function editor:keypressed(key)
    if key == "return" then
        path = Path()
    elseif key == " " then
        drag = nil
        path:updatePoints()
        gamestate.push(game, path)
    end
end

function editor:update(dt)
    if drag then
        drag:setPosition(lm.getX(), lm.getY(), lk.isDown("lshift"))
    end
end

function editor:draw()
    path:draw(true)
end

return editor
