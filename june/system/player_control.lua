local function x_press_keymap(key)
    local dir = {left = -1, right = 1}
    return dir[key]
end

return function(ctx, ecs_world)
    local x_press = ctx:listen("keypressed")
        :map(x_press_keymap)

    local x_release = ctx:listen("keyreleased")
        :map(function(key)
            local v = x_press_keymap(key)
            if v then return -v end
        end)

    local x = x_press:merge(x_release)
        :filter()
        :reduce(function(agg, v) return agg + v end, 0)

    local update = ctx:listen("update"):collect()

    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            local dx = x:peek() * dt * 100
            local dy = 0
            collision.move(ecs_world:entity(constants.id.player), dx, dy)
        end

        ctx:yield()
    end
end
