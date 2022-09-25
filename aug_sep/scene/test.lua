local function load_tile(map, layer, tile, x, y)
    return map.ecs_world:entity()
        :assemble(
            assemble.tile, x, y, tile.width, tile.height, tile.properties,
            map.bump_world
        )
end

local function load_object(map, layer, object)
    if object.type == "player_spawn" then
        return map.ecs_world:entity(constants.id.player)
            :assemble(assemble.player, object.x, object.y, map.bump_world)
    end
end

local function load_and_populate_level(path)
    local tiled_level = nw.third.sti(path)

    tiled_level.bump_world = nw.third.bump.newWorld()
    tiled_level.ecs_world = nw.ecs.entity.create()

    nw.third.sti_parse(tiled_level, load_tile, load_object)

    return tiled_level
end

local function default_collision_filter(ecs_world, item, other)
    if ecs_world:get(nw.component.ghost, item) or ecs_world:get(nw.component.ghost, other) then return "cross" end
    return "slide"
end

local function camera_wrap(ctx)
    local ecs_world = ctx:from_cache("level")
        :map(function(level) return level.ecs_world end)
        :latest()

    local obs = nw.system.camera.observables(ctx)
    while ctx:is_alive() do
        nw.system.camera.handle_obserables(ctx, obs, ecs_world:peek())
        ctx:yield()
    end
end

local function generic_system_wrap(ctx, system)
    local ecs_world = ctx:from_cache("level")
        :map(function(level) return level.ecs_world end)
        :latest()

    local obs = system.observables(ctx)
    while ctx:is_alive() do
        system.handle_obserables(ctx, obs, ecs_world:peek())
        ctx:yield()
    end
end

local function draw_health(ecs_world, id)
    local health = ecs_world:get(nw.component.health, id) or 0

    gfx.push("all")
    gfx.setColor(1, 0, 0)
    for i = 1, health do
        gfx.circle("fill", 20 * i, 20, 10, 10)
    end
    gfx.pop()
end

return function(ctx)
    local level = load_and_populate_level("art/maps/build/develop.lua")

    ctx:to_cache("level", level)

    local camera_entity = level.ecs_world:entity(constants.id.camera)
        :set(nw.component.camera, 25, "box", 50)
        :set(nw.component.target, constants.id.player)
        :set(nw.component.scale, constants.scale, constants.scale)

    local hitbox_entity = level.ecs_world:entity()
        :assemble(
            collision().assemble.init_entity, 40, -30,
            nw.component.hitbox(40, 40), level.bump_world
        )
        :set(nw.component.drawable, drawable.body)
        :set(nw.component.ghost)
        :set(nw.component.healing)
        :set(nw.component.activate_once)

    local enemy_float = level.ecs_world:entity()
        :assemble(
            collision().assemble.init_entity, 120, -30,
            nw.component.hitbox(20, 10), level.bump_world
        )
        :set(nw.component.drawable, drawable.body)
        :set(nw.component.ghost)

    collision(ctx).default_filter = default_collision_filter

    ctx.world:push(require "system.motion")
    ctx.world:push(require "system.player_control")
    ctx.world:push(require "system.collision_resolver")
    ctx.world:push(generic_system_wrap, nw.system.camera)
    ctx.world:push(generic_system_wrap, require "system.lifetime")
    ctx.world:push(require "system.float_enemy", enemy_float)

    local draw = ctx:listen("draw"):collect()
    local update = ctx:listen("update"):collect()

    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            nw.system.animation(ctx):update(dt, level.ecs_world)
        end

        for _, _ in ipairs(draw:pop()) do
            gfx.push()

            camera.push_transform(camera_entity)
            gfx.setColor(1, 1, 1)
            for _, layer in ipairs(level.layers) do
                if layer.visible then layer:draw() end
            end

            render.draw_scene(level.ecs_world)
            gfx.pop()

            draw_health(level.ecs_world, constants.id.player)
        end

        ctx:yield()
    end
end
