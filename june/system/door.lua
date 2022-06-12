local door = {}

door.init_hitbox = component.body(10, 50)
door.closed_pos = vec2(door.init_hitbox.x, door.init_hitbox.y)
door.open_pos = vec2(door.init_hitbox.x, door.init_hitbox.y - door.init_hitbox.h)

local function handle_update(ecs_world, dt)
    local doors = ecs_world:get_component_table(component.door_state)

    for id, state in pairs(doors) do
        local next_pos = state and door.open_pos or door.closed_pos
        collision.move_body_to(ecs_world:entity(id), next_pos.x, next_pos.y)
    end
end

function door.system(ctx, ecs_world)
    local update = ctx:listen("update"):collect()

    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            handle_update(ecs_world)
        end
        ctx:yield()
    end
end

function door.assemble(entity, x, y, bump_world)
    return entity
        :assemble(
            collision.init_entity, x, y, door.init_hitbox, bump_world
        )
        :set(component.door_state, true)
end

return door
