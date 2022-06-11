local function apply_gravity(ecs_world, id, dt)
    local gravity = ecs_world:get(nw.component.gravity, id)
    if not gravity then return end
    local velocity = ecs_world:ensure(nw.component.velocity, id)
    local position = ecs_world:ensure(nw.component.position, id)

    local next_velocity = velocity + gravity * dt
    local next_position = position + velocity * dt + gravity  * dt * dt * 0.5

    ecs_world:set(nw.component.velocity, id, next_velocity.x, next_velocity.y)
    collision.move_to(ecs_world:entity(id), next_position.x, next_position.y)
end

local function cancel_horz_velocity(v) return vec2(0, v.y) end

local function cancel_vert_velocity(v) return vec2(v.x, 0) end

local function handle_collision(ecs_world, col_info)
    if math.abs(col_info.normal.x) >= 0.9 then
        ecs_world:map(nw.component.velocity, col_info.item, cancel_horz_velocity)
        ecs_world:map(nw.component.velocity, col_info.other, cancel_horz_velocity)
    elseif math.abs(col_info.normal.y) >= 0.9 then
        ecs_world:map(nw.component.velocity, col_info.item, cancel_vert_velocity)
        ecs_world:map(nw.component.velocity, col_info.other, cancel_vert_velocity)
    end
end

return function(ctx, ecs_world)
    local update = ctx:listen("update"):collect()
    local collision = ctx:listen("collision"):collect()

    while ctx:is_alive() do
        update:pop():foreach(function(dt)
            local gravity_table = ecs_world:get_component_table(nw.component.gravity)
            for id, _ in pairs(gravity_table) do
                apply_gravity(ecs_world, id, dt)
            end
        end)

        collision:pop():foreach(function(mul_col_info)
            for _, col_info in ipairs(mul_col_info) do
                handle_collision(ecs_world, col_info)
            end
        end)

        ctx:yield()
    end
end
