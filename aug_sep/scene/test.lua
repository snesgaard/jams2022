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

return function(ctx)
    local level = load_and_populate_level("art/maps/build/develop.lua")

    local draw = ctx:listen("draw"):collect()

    local camera_entity = level.ecs_world:entity(constants.id.camera)
        :set(nw.component.camera, 25, "box", 50)
        :set(nw.component.target, constants.id.player)
        :set(nw.component.scale, constants.scale, constants.scale)

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
