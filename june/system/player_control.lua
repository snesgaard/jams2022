local function x_press_keymap(key)
    local dir = {left = -1, right = 1}
    return dir[key]
end

local function is_minion_close_enough(ecs_world)
    local player_pos = ecs_world:ensure(nw.component.position, constants.id.player)
    local minion_pos = ecs_world:ensure(nw.component.position, constants.id.minion)

    return (player_pos - minion_pos):length() < 100
end

local function minion_control(ctx)
    local abort = ctx:listen("keypressed")
        :filter(function(key) return key == "x" end)
        :latest()

    local entity = ctx.ecs_world:entity(constants.id.minion)

    while ctx:is_alive() and not abort:peek() do
        for _, dt in ipairs(ctx.update:pop()) do
            local dx = ctx.x:peek() * dt * 100
            local dy = 0
            collision.move(entity, dx, dy)
        end

        ctx:yield()
    end
end

local function idle_control(ctx)
    local swap_to_minion = ctx:listen("keypressed")
        :filter(function(key) return key == "x" end)
        :filter(function() return is_minion_close_enough(ctx.ecs_world) end)
        :latest()

    local entity = ctx.ecs_world:entity(constants.id.player)

    while ctx:is_alive() and not swap_to_minion:peek() do
        for _, dt in ipairs(ctx.update:pop()) do
            local dx = ctx.x:peek() * dt * 100
            local dy = 0
            collision.move(entity, dx, dy)
        end

        if ctx.jump_control:pop() then
            print("go")
            entity:map(nw.component.velocity, function(v)
                print(v.x, v.y)
                return vec2(v.x, -200)
            end)
        end

        ctx:yield()
    end

    if swap_to_minion:peek() then return minion_control(ctx) end
end

return function(ctx, ecs_world)
    local x_press = ctx:listen("keypressed")
        :map(x_press_keymap)

    local x_release = ctx:listen("keyreleased")
        :map(function(key)
            local v = x_press_keymap(key)
            if v then return -v end
        end)

    ctx.x = x_press:merge(x_release)
        :filter()
        :reduce(function(agg, v) return agg + v end, 0)

    ctx.update = ctx:listen("update"):collect()
    ctx.jump_control = require("ai.player_jump").create(ctx, constants.id.player)


    ctx.ecs_world = ecs_world

    while ctx:is_alive() do idle_control(ctx) end
end
