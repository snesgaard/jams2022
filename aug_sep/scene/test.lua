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

return function(ctx)
    local level = load_and_populate_level("art/maps/build/develop.lua")

    ctx:to_cache("level", level)

    local draw = ctx:listen("draw"):collect()

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

    collision(ctx).default_filter = default_collision_filter

    ctx.world:push(require "system.motion")
    ctx.world:push(require "system.player_control")
    ctx.world:push(require "system.collision_resolver")


    while ctx:is_alive() do
        for _, _ in ipairs(draw:pop()) do
            gfx.push()

            camera.push_transform(camera_entity)
            gfx.setColor(1, 1, 1)
            for _, layer in ipairs(level.layers) do
                if layer.visible then layer:draw() end
            end

            render.draw_scene(level.ecs_world)

            gfx.pop()
        end

        ctx:yield()
    end
end
