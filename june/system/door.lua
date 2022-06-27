local door = {}

door.init_hitbox = component.body(10, 50)
door.closed_pos = vec2(door.init_hitbox.x, door.init_hitbox.y)
door.open_pos = vec2(door.init_hitbox.x, door.init_hitbox.y - door.init_hitbox.h)

local function determine_next_state(entity)
    local id = entity % component.door_switch
    if not id then return end
    local switch_state = entity:world():ensure(component.switch_state, id)
    entity:set(component.door_state, switch_state)
end

local function handle_update(ecs_world, tween, dt)
    local doors = ecs_world:get_component_table(component.door_state)

    for id, state in pairs(doors) do
        local entity = ecs_world:entity(id)
        local next_state = determine_next_state(entity)

        local next_pos = state and door.open_pos or door.closed_pos
        local pos = tween:move_to(id, next_pos)
        collision.move_body_to(entity, pos.x, pos.y)
    end
end

function door.system(ctx, ecs_world)
    local update = ctx:listen("update"):collect()
    local tween = imtween.create()

    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            handle_update(ecs_world, tween)
            tween:update(dt)
        end
        ctx:yield()
    end
end

return door
