function class()
    local c = {}
    c.__index = c
    return c
end

nw = require "nodeworks"
constants = require "constants"
collision = require "collision"
component = require "component"
assemble = require "assemble"

function nw.ecs.entity.on_entity_destroyed(id, values)
    local bump_world = values[nw.component.bump_world]
    if not bump_world then return end
    if bump_world:hasItem(id) then bump_world:remove(id) end
end

function emit_event(entity, ...)
    local cb = entity:world():entity(constants.id.global) % component.event_callback
    if not cb then return end
    cb(...)
end

function love.load()
    world = nw.ecs.world()
    world:push(require "scene.manual")
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
    world:emit("draw"):spin()
end
