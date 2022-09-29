local lifetime = {}

function lifetime.observables(ctx)
    return {
        update = ctx:listen("update"):collect()
    }
end

function lifetime.handle_update(dt, ecs_world)
    local entities = ecs_world:get_component_table(nw.component.lifetime)

    for id, lifetime in pairs(entities) do
        if lifetime.time < dt then
            ecs_world:destroy(id)
        else
            lifetime.time = lifetime.time - dt
        end
    end
end

function lifetime.handle_observables(ctx, obs, ecs_world, ...)
    if not ecs_world then return end

    obs.update:peek():foreach(lifetime.handle_update, ecs_world)

    return lifetime.handle_observables(obs, ...)
end

return lifetime
