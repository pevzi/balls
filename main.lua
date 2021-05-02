local gamestate = require "libs.gamestate"

local editor = require "editor"

function love.load()
    love.graphics.setBackgroundColor(0.12, 0.12, 0.12)

    gamestate.registerEvents()
    gamestate.switch(editor)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
