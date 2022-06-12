local function switch_state_from_cols(ecs_world, cols)
    for _, id in ipairs(cols) do
        if ecs_world:get(component.actor, id) then return true end
    end

    return false
end

local function check_for_collision(ecs_world)
    local switches = ecs_world:get_component_table(component.ground_switch)

    for id, _ in pairs(switches) do
        local cols = collision.check(ecs_world:entity(id))
        local next_switch_state = switch_state_from_cols(ecs_world, cols)
        ecs_world:set(component.switch_state, id, next_switch_state)
    end
end

return function(ctx, ecs_world)
    local update = ctx:listen("update"):collect()

    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            check_for_collision(ecs_world)
        end

        ctx:yield()
    end
end
