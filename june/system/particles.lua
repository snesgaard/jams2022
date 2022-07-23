local function handle_update(ctx, dt)
    local ecs_world = ctx:ecs_world()

    local et = ecs_world:get_component_table(nw.component.particles)

    for id, particles in pairs(et) do
        particles:update(dt)
        local one_shot = ecs_world:get(component.one_shot, id)
        if particles:getCount() == 0 and one_shot then
            ecs_world:destroy(id)
        end
    end
end

return function(ctx)
    local update = ctx:listen("update"):collect()

    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do handle_update(ctx, dt) end
        ctx:yield()
    end
end
