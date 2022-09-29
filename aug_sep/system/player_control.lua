local Jump = require "system.player_jump"
local proximity = require "system.proximity"

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

local function is_reagent(ecs_world, id)
    return ecs_world:get(nw.component.reagent, id)
end

local function handle_pickup(entity, ecs_world)
    local prox = entity:ensure(nw.component.proximity)
    local others = prox.others or list()
    local ecs_world = ecs_world or entity:world()

    local candidate = others
        :filter(function(id) return is_reagent(ecs_world, id) end)
        :sort(function(a, b)
            local da = proximity.square_distance(ecs_world, entity.id, a)
            local db = proximity.square_distance(ecs_world, entity.id, b)
            return da < db
        end)
        :head()

    if not candidate then return end

    local reagent_type = ecs_world:get(nw.component.reagent, candidate)
    ecs_world:destroy(candidate)

    entity:map(nw.component.reagent_inventory, function(current)
        return current + list(reagent_type)
    end)
end

local rules = {}

local function idle(ctx)
    local update = ctx:listen("update"):collect()

    local throw = ctx:listen("keypressed")
        :filter(function(k) return k == "a" end)
        :collect()

    local pickup = ctx:listen("keypressed")
        :filter(function(k) return k == "p" end)
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
        :map(function(entity)
            return entity:set(nw.component.proximity, 10, is_reagent)
        end)
        :latest()

    function ctx:paused()
        return player_entity:peek():get(nw.component.paused)
    end

    local ecs_world = ctx:from_cache("level")
        :map(function(level) return level.ecs_world end)
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

        for _, _ in ipairs(pickup:pop()) do
            handle_pickup(player_entity:peek())
        end

        ctx:yield()
    end
end

return function(ctx)
    while ctx:is_alive() do
        idle(ctx)
        ctx:yield()
    end
end
