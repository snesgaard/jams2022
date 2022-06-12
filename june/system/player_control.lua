local spawn_point = require "spawn_point"

local function x_press_keymap(key)
    local dir = {left = -1, right = 1}
    return dir[key]
end

local function is_minion_close_enough(ecs_world)
    local player_pos = ecs_world:ensure(nw.component.position, constants.id.player)
    local minion_pos = ecs_world:ensure(nw.component.position, constants.id.minion)

    return (player_pos - minion_pos):length() < 100
end

local function minion_control(ctx, entity)
    local abort = ctx:listen("keypressed")
        :filter(function(key) return key == "x" end)
        :latest()

    while ctx:is_alive() and not abort:peek() do
        for _, dt in ipairs(ctx.update:pop()) do
            local dx = ctx.x:peek() * dt * 100
            local dy = 0
            collision.move(entity, dx, dy)
        end

        ctx:yield()
    end
end

local function get_closest_spawn_point(ecs_world)
    local w, h = 100, 100
    local entity = ecs_world:entity(constants.id.player)
    local candidates = collision.check(entity, w, h)
    return candidates
    :map(function(id) return ecs_world:entity(id) end)
    :filter(function(entity)
        return spawn_point.is_spawn_point(entity)
    end)
    :head()
end

local function idle_control(ctx)
    local spawn_minion = ctx:listen("keypressed")
        :filter(function(key) return key == "x" end)
        :map(function() return get_closest_spawn_point(ctx.ecs_world) end)
        :filter()
        :latest()

    local entity = ctx.ecs_world:entity(constants.id.player)

    while ctx:is_alive() and not spawn_minion:peek() do
        for _, dt in ipairs(ctx.update:pop()) do
            local dx = ctx.x:peek() * dt * 100
            local dy = 0
            collision.move(entity, dx, dy)
        end

        if ctx.jump_control:pop() then
            entity:map(nw.component.velocity, function(v)
                return vec2(v.x, -200)
            end)
        end

        ctx:yield()
    end

    if spawn_minion:peek() then
        local minion = spawn_point.spawn(spawn_minion:peek())
        if minion then return minion_control(ctx, minion) end
    end
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
