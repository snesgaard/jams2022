local lifetime = {}

function lifetime.observables(ctx)
    return {
        update = ctx:listen("update"):collect()
    }
end

local function handle_update(dt, ecs_world)
    local entities = ecs_world:get_component_table(nw.component.lifetime)

    for id, lifetime in pairs(entities) do
        if lifetime.time < dt then
            ecs_world:destroy(id)
        else
            lifetime.time = lifetime.time - dt
        end
    end
end

function lifetime.handle_obserables(ctx, obs, ecs_world, ...)
    if not ecs_world then return end

    obs.update:pop():foreach(handle_update, ecs_world)
end

return lifetime
