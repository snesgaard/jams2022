local bumpdebug = require "bumpdebug"
local spawn_point = require "spawn_point"
local render = require "render"
local drawable = require "drawable"
local door = require "system.door"

return function(ctx)
    local bump_world = nw.third.bump.newWorld()
    local ecs_world = nw.ecs.entity.create()

    ecs_world:entity(constants.id.global)
        :set(nw.component.bump_world, bump_world)
        :set(component.event_callback, function(...) ctx:emit(...) end)

    ecs_world:entity(constants.id.player)
        :assemble(collision.set_hitbox, 20, 20)
        :assemble(collision.set_bump_world, bump_world)
        :assemble(collision.warp_to, 200, 300)
        :set(nw.component.tag, "actor")
        :set(nw.component.gravity, 0, 100)
        :set(nw.component.drawable, drawable.body)
        :set(component.actor)

    ctx.spawn = ecs_world:entity("spawn")
        :assemble(spawn_point.assemble, 100, 300, bump_world)

    ctx.switch = ecs_world:entity("switch")
        :assemble(collision.warp_to, 300, 300)
        :assemble(collision.set_hitbox, 50, 20)
        :assemble(collision.set_bump_world, bump_world)
        :set(nw.component.tag, "actor")
        :set(nw.component.drawable, drawable.ground_switch)
        :set(component.ground_switch)

    bump_world:add("platform", 0, 300, 1000, 200)

    ctx.door = ecs_world:entity("door")
        :assemble(door.assemble, 400, 300, bump_world)

    ctx.world:push(require "system.gravity", ecs_world)
    ctx.world:push(require "system.player_control", ecs_world)
    ctx.world:push(require "system.ground_switch", ecs_world)
    ctx.world:push(require("system.door").system, ecs_world)

    local draw = ctx:listen("draw"):collect()

    while ctx:is_alive() do
        draw:pop():foreach(function()
            render.draw_scene(ecs_world)
            draw_world(bump_world)
            render.draw_positions(ecs_world)
        end)

        ctx:yield()
    end
end
