local function handle_goal(col_info, ctx)
    if col_info.item ~= constants.id.player then return end
    local other = col_info.ecs_world:entity(col_info.other)
    if other:get(component.goal) then
        ctx:emit("goal_reached", true)
    end
end

local function handle_collision(col_info, ctx)
    handle_goal(col_info, ctx)
end

return function(ctx)
    local collisions = ctx:listen("collision"):collect()

    while ctx:is_alive() do
        collisions:pop():foreach(handle_collision, ctx)

        ctx:yield()
    end
end
