local patrol = require "system.patrol"

local states = {}

function states.setup(ctx, entity)
    local p = entity:get(nw.component.position)

    local path = {p, p - vec2(0, 100)}
    local cycle_time = 2

    entity:set(nw.component.patrol, path, cycle_time)

    return states.idle(ctx, entity)
end

function states.idle(ctx, entity)
    local update = ctx:listen("update"):collect()

    local timer_before_shoot = nw.component.timer.create(love.math.random(0.75, 1))

    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            if timer_before_shoot:update(dt) then
                return states.shoot(ctx, entity)
            end
            patrol.update(dt, entity)
            local p = patrol.next_position(entity)
            collision(ctx):move_to(entity, p.x, p.y)
        end
        ctx:yield()
    end
end

function states.shoot(ctx, entity)
    local pause_timer = nw.component.timer.create(0.5)
    local update = ctx:listen("update"):collect()

    local p = entity:ensure(nw.component.position)
    local player_p = entity:world():get(nw.component.position, constants.id.player)

    if not player_p then return states.idle(ctx, entity) end

    local dir = (player_p - p):normalize()

    local bullet = entity:world():entity()
        :set(nw.component.color, 1, 0, 0)
        :assemble(nw.system.collision(ctx).assemble.init_entity,
            p.x, p.y, nw.component.hitbox(4, 4),
            entity:get(nw.component.bump_world)
        )
        :set(nw.component.drawable, drawable.body)
        :set(nw.component.lifetime, 3)
        :set(nw.component.velocity, dir.x * 100, dir.y * 100)
        :set(nw.component.ghost)
        :set(nw.component.die_on_effect)
        :set(nw.component.collision_filter, function(ecs_world, item, other)
            if other == entity.id then return end
            return nw.system.collision(ctx).default_filter(ecs_world, item, other)
        end)
        :set(nw.component.damage, 1)

    while ctx:is_alive() and not pause_timer:done() do
        for _, dt in ipairs(update:pop()) do pause_timer:update(dt) end
        ctx:yield()
    end

    return states.idle(ctx, entity)
end

return states.setup
