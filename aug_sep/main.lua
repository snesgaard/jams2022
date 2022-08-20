nw = require "nodeworks"
assemble = require "assemble"
collision = nw.system.collision
camera = nw.system.camera
drawable = require "drawable"
constants = require "constants"
render = require "render"

decorate(nw.component, require "component", true)

Frame.slice_to_pos = Spatial.centerbottom

function love.load()
    world = nw.ecs.world()

    world:push(require "scene.test")
end

function love.update(dt)
    world:emit("update", dt):spin()
end

function love.keypressed(key)
    if key == "escape" then love.event.quit() end

    world:emit("keypressed", key)
end

function love.keyreleased(key)
    world:emit("keyreleased", key)
end

function love.draw()
    world:emit("draw"):emit("debugdraw"):spin()
end

function love.wheelmoved(x, y)
    world:emit("wheelmoved", x, y)
end

function love.mousemoved(x, y, dx, dy)
    world:emit("mousemoved", x, y, dx, dy)
end

function love.mousepressed(x, y, button, isTouch)
    world:emit("mousepressed", x, y, button, isTouch)
end
