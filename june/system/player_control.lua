local spawn_point = require "spawn_point"
local jump_control = require("ai.player_jump")

local atlas = get_atlas("art/characters")

local anime = {
    necromancer = {
        idle = atlas:get_animation("necro-silhouette"),
        run = atlas:get_animation("necromancer_run/run"),
    },
    skeleton = {
        idle = atlas:get_animation("skeleton/idle"),
        run = atlas:get_animation("skeleton/run"),
    },
    ghost = {
        idle = atlas:get_animation("ghost/idle")
    }
}

local function dir_from_input(ctx, entity)
    if ctx.x:peek() > 0 then
        entity:set(nw.component.scale, 1, 1)
    elseif ctx.x:peek() < 0 then
        entity:set(nw.component.scale, -1, 1)
    end
end

local function animation_from_input_and_motion(ctx, entity, animations)
    if math.abs(ctx.x:peek()) > 0 then
        ctx:animation():play(entity.id, animations.run)
    else
        ctx:animation():play(entity.id, animations.idle)
    end

    dir_from_input(ctx, entity)
end

local function get_objects_in_range(ctx, entity)
    local w, h = 100, 100
    local candidates = collision.check(entity, w, h)
    return candidates:map(function(id) return entity:world():entity(id) end)
end

local function interact(object)
    if object % component.wall_switch then
        object:map(component.switch_state, function(s)
            return not s
        end)
        return true
    end
end

local function x_press_keymap(key)
    local dir = {left = -1, right = 1}
    return dir[key]
end

local function y_press_keymap(key)
    local dir = {up = -1, down = 1}
    return dir[key]
end

local function is_minion_close_enough(ecs_world)
    local player_pos = ecs_world:ensure(nw.component.position, constants.id.player)
    local minion_pos = ecs_world:ensure(nw.component.position, constants.id.minion)

    return (player_pos - minion_pos):length() < 100
end

local function skeleton_minion_control(ctx, entity)
    local abort = ctx:listen("keypressed")
        :filter(function(key) return key == "x" end)
        :latest()

    local jump_control = jump_control.create(ctx, entity.id)

    ctx:animation():play(entity.id, anime.skeleton.idle)

    while ctx:is_alive() and not abort:peek() do
        for _, dt in ipairs(ctx.update:pop()) do
            local dx = ctx.x:peek() * dt * 200
            local dy = 0
            collision.move(entity, dx, dy)

            animation_from_input_and_motion(ctx, entity, anime.skeleton)
        end


        if jump_control:pop() then
            local g = entity:ensure(component.gravity)
            local vy = ctx.jump_control.speed_from_height(g.y, 85)
            entity:map(nw.component.velocity, function(v)
                return vec2(v.x, -vy)
            end)
        end

        ctx:yield()
    end
end

local function ghost_minion_control(ctx, entity)
    local abort = ctx:listen("keypressed")
        :filter(function(key) return key == "x" end)
        :latest()

    ctx:animation():play(entity.id, anime.ghost.idle)

    local interact_cmd = ctx:listen("keypressed")
        :filter(function(key) return key == "c" end)
        :map(function() return get_objects_in_range(ctx, entity) end)
        :filter()
        :latest()

    while ctx:is_alive() and not abort:peek() do
        for _, dt in ipairs(ctx.update:pop()) do
            local dx = ctx.x:peek() * dt * 100
            local dy = ctx.y:peek() * dt * 100
            collision.move(entity, dx, dy)
            dir_from_input(ctx, entity)
        end

        for _, obj in ipairs(interact_cmd:pop() or {}) do
            if interact(obj) then break end
        end

        ctx:yield()
    end
end

local function minion_control(ctx, entity)
    ctx:ecs_world():set(component.target, constants.id.camera, entity.id)

    if entity:get(component.ghost) then
        return ghost_minion_control(ctx, entity)
    else
        return skeleton_minion_control(ctx, entity)
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
    ctx:ecs_world():set(component.target, constants.id.camera, constants.id.player)
    local entity = ctx:ecs_world():entity(constants.id.player)

    local spawn_minion = ctx:listen("keypressed")
        :filter(function(key) return key == "x" end)
        :map(function() return get_closest_spawn_point(ctx:ecs_world()) end)
        :filter()
        :latest()

    local interact_cmd = ctx:listen("keypressed")
        :filter(function(key) return key == "c" end)
        :map(function() return get_objects_in_range(ctx, entity) end)
        :filter()
        :latest()

    ctx:animation():play(
        constants.id.player,
        anime.necromancer.idle
    )

    while ctx:is_alive() and not spawn_minion:peek() do
        for _, dt in ipairs(ctx.update:pop()) do
            local dx = ctx.x:peek() * dt * 150
            local dy = 0
            collision.move(entity, dx, dy)
            animation_from_input_and_motion(ctx, entity, anime.necromancer)
        end

        for _, obj in ipairs(interact_cmd:pop() or {}) do
            if interact(obj) then break end
        end

        if ctx.jump_control:pop() then
            local g = entity:ensure(component.gravity)
            local vy = ctx.jump_control.speed_from_height(g.y, 55)
            entity:map(nw.component.velocity, function(v)
                return vec2(v.x, -vy)
            end)
        end

        ctx:yield()
    end

    if spawn_minion:peek() then
        local minion = spawn_point.spawn(spawn_minion:peek())
        if minion then
            return minion_control(ctx, minion)
        end
    end
end

return function(ctx, ecs_world, animation)
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

    local y_press = ctx:listen("keypressed")
        :map(y_press_keymap)

    local y_release = ctx:listen("keyreleased")
        :map(y_press_keymap)
        :filter()
        :map(function(v) return -v end)

    ctx.y = y_press:merge(y_release)
        :filter()
        :reduce(function(agg, v) return agg + v end, 0)

    ctx.update = ctx:listen("update"):collect()
    ctx.jump_control = jump_control.create(ctx, constants.id.player)

    while ctx:is_alive() do idle_control(ctx) end
end
