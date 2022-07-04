local function apply_gravity(ecs_world, id, dt)
    local gravity = ecs_world:get(component.gravity, id)
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

local function sign(x)
    if x < 0 then
        return -1
    elseif 0 < x then
        return 1
    else
        return 0
    end
end

local function cancel_on_y_axis(v, y_axis)
    local s_v = sign(v.y)
    local s_a = sign(y_axis)

    if s_v == -s_a then return vec2(v.x, 0) end

    return v
end

local function cancel_on_x_axis(v, x_axis)
    local s_v = sign(v.x)
    local s_a = sign(x_axis)

    if s_v == -s_a then return vec2(0, v.y) end

    return v
end

local function cancel_on_axis(v, x_axis, y_axis)
    local v = cancel_on_x_axis(v, x_axis)
    local v = cancel_on_y_axis(v, y_axis)
    return v
end

local function handle_collision(ecs_world, col_info)
    if col_info.type ~= "touch" and col_info.type ~= "slide" then return end

    ecs_world:map(
        nw.component.velocity, col_info.item,
        cancel_on_axis, col_info.normal.x, col_info.normal.y
    )
    ecs_world:map(
        nw.component.velocity, col_info.other,
        cancel_on_axis, -col_info.normal.x, -col_info.normal.y
    )
end

return function(ctx, ecs_world)
    local update = ctx:listen("update"):collect()
    local collision = ctx:listen("collision"):collect()

    while ctx:is_alive() do
        update:pop():foreach(function(dt)
            local gravity_table = ecs_world:get_component_table(component.gravity)
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
