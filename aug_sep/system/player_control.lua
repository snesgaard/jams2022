local Jump = require "system.player_jump"

local animations = {
    idle = get_atlas("art/characters"):get_animation("alchemist_chibi")
}

local jump_height = 64

local function get_transform(entity)
    local p = entity:get(nw.component.position) or vec2()
    local m = entity:get(nw.component.mirror)

    return love.math.newTransform(p.x, p.y, 0, m and -1 or 1, 1)
end

local function transform_velocity(entity, v)
    local m = entity:get(nw.component.mirror)
    if m then
        return vec2(-v.x, v.y)
    else
        return v
    end
end

local function throw_projectile(entity, bump_world)
    local transform = get_transform(entity)
    local x, y = transform:transformPoint(20, -20)

    entity:world():entity()
        :assemble(
            assemble.alchemy_projectile, x, y,
            transform_velocity(entity, vec2(200, -300)), "red",
            bump_world
        )
end

local rules = {}

return function(ctx)
    local update = ctx:listen("update"):collect()
    local throw = ctx:listen("keypressed")
        :filter(function(k) return k == "a" end)
        :collect()

    local function x_dir()
        local x = 0
        local dir = {left = -1, right = 1}

        for k, v in pairs(dir) do
            if love.keyboard.isDown(k) then x = x + v end
        end

        return x
    end

    local player_entity = ctx:from_cache("level")
        :map(function(level)
            return level.ecs_world:entity(constants.id.player)
        end)
        :latest()

    local bump_world = ctx:from_cache("level")
        :map(function(level) return level.bump_world end)
        :latest()

    nw.system.animation(ctx):play(player_entity:peek(), animations.idle)

    local jump = Jump.create(ctx, player_entity)

    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            local speed = 200
            if x_dir() < 0 then
                player_entity:peek():set(nw.component.mirror, true)
            elseif x_dir() > 0 then
                player_entity:peek():set(nw.component.mirror, false)
            end
            collision(ctx):move(player_entity:peek(), speed * x_dir() * dt, 0)
        end

        if jump:pop() then
            player_entity:peek():map(nw.component.velocity, function(v)
                local g = player_entity:peek():ensure(nw.component.gravity)
                local vy = Jump.speed_from_height(g.y, jump_height)
                return vec2(v.x, -vy)
            end)
        end

        for _, _ in ipairs(throw:pop()) do
            throw_projectile(player_entity:peek(), bump_world:peek())
        end

        ctx:yield()
    end
end
