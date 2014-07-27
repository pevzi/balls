local gamestate = require "hump.gamestate"

local editor = require "editor"

function love.load()
    love.graphics.setBackgroundColor(30, 30, 30)

    gamestate.registerEvents()
    gamestate.switch(editor)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
