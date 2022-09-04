return function(ctx)
    local ecs_world = ctx:from_cache("level")
        :map(function(level) return level.ecs_world end)
        :latest()

    local update = ctx:listen("update"):collect()
    local collision = ctx:listen("collision"):collect()

    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            nw.system.motion(ctx):update(dt, ecs_world:peek())
        end

        for _, colinfo in ipairs(collision:pop()) do
            nw.system.motion(ctx):on_collision(colinfo)
        end

        ctx:yield()
    end
end
