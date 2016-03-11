local gamestate = require "hump.gamestate"
local u = require "useful"

local game = require "game"
local path = require "path"

local lg = love.graphics
local lm = love.mouse
local lk = love.keyboard

local editor = {}

function editor:init()
    self.path = path.Path()
    self.drag = nil
end

function editor:mousepressed(x, y, button)
    for point in pairs(self.path.controlPoints) do
        if u.dist2(x, y, point.x, point.y) < 400 then
            if button == 1 then
                self.drag = point
                return
            elseif button == 2 and point:is(path.Node) then
                self.path:removeNode(point)
                self.drag = nil
                return
            end
        end
    end

    if button == 1 then
        self.drag = self.path:addNode(x, y)
    end
end

function editor:mousereleased(x, y, button)
    self.drag = nil
end

function editor:keypressed(key)
    if key == "return" then
        self.path = path.Path()
    elseif key == "space" then
        self.drag = nil
        self.path:updatePoints()
        gamestate.push(game, self.path)
    end
end

function editor:update(dt)
    if self.drag then
        self.drag:setPosition(lm.getX(), lm.getY(), lk.isDown("lshift"))
    end
end

function editor:draw()
    self.path:draw(true)
end

return editor
