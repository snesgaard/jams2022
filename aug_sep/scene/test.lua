return function(ctx)
    local ecs_world = nw.ecs.entity.create()
    local bump_world = nw.third.bump.newWorld()

    ecs_world:entity(constants.id)
        :assemble(assemble.player, 100, 100, bump_world)

    local draw = ctx:listen("draw"):collect()

    while ctx:is_alive() do
        for _, _ in ipairs(draw:pop()) do
            render.draw_scene(ecs_world)
        end

        ctx:yield()
    end
end
