local bumpdebug = require "bumpdebug"

return function(ctx)
    local bump_world = nw.third.bump.newWorld()
    local ecs_world = nw.ecs.entity()

    ecs_world:entity(constants.id.global)
        :set(nw.component.bump_world, bump_world)
        :set(component.event_callback, function(...) ctx:emit(...) end)

    ecs_world:entity(constants.id.player)
        :assemble(collision.set_hitbox, 20, 20)
        :assemble(collision.set_bump_world, bump_world)
        :assemble(collision.warp_to, 200, 200)
        :set(nw.component.tag, "actor")
        :set(nw.component.gravity, 0, 100)

    ecs_world:entity(constants.id.minion)
        :assemble(collision.set_hitbox,10, 20)
        :assemble(collision.set_bump_world, bump_world)
        :assemble(collision.warp_to, 400, 270)
        :set(nw.component.tag, "actor")

    bump_world:add("platform", 0, 300, 1000, 200)

    ctx.world:push(require "system.gravity", ecs_world)
    ctx.world:push(require "system.player_control", ecs_world)

    local draw = ctx:listen("draw"):collect()

    while ctx:is_alive() do
        draw:pop():foreach(function()
            draw_world(bump_world)
        end)

        ctx:yield()
    end
end
