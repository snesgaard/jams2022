local camera = require "system.camera"
local render = require "render"
local bumpdebug = require "bumpdebug"

local function load_tile(map, layer, tile, x, y, ecs_world, bump_world)
    return ecs_world:entity()
        :assemble(
            assemble.tile, x, y, tile.width, tile.height, tile.properties,
            bump_world
        )
end

local function load_object(map, layer, object, ecs_world, bump_world)
    if object.type == "player_spawn" then
        return ecs_world:entity(constants.id.player)
            :assemble(assemble.player, object.x, object.y, bump_world)
    end
end

return function(ctx)
    local tiled_level = nw.third.sti("art/maps/build/develop.lua")
    local draw = ctx:listen("draw"):collect()
    local ecs_world = nw.ecs.entity.create()
    local bump_world = nw.third.bump.newWorld()

    ecs_world:entity(constants.id.global)
        :set(nw.component.bump_world, bump_world)
        :set(component.event_callback, function(...) ctx:emit(...) end)

    for _, layer in ipairs(tiled_level.layers) do
        print(dict(layer))
    end

    local camera_entity = ecs_world:entity()
        :set(component.camera)
        :set(nw.component.position, -50, -50)

    ctx.world:push(camera.system, ecs_world)
    --ecs_world:entity(constants.id.player)
    --    :assemble(assemble.player, 50, 50, bump_world)

    nw.third.sti_parse(tiled_level, load_tile, load_object, ecs_world, bump_world)

    ctx.world:push(require "system.gravity", ecs_world)
    ctx.world:push(require "system.player_control", ecs_world)

    while ctx:is_alive() do
        draw:pop():foreach(function()
            gfx.push()

            camera.push_transform(camera_entity)
            for _, layer in ipairs(tiled_level.layers) do layer:draw() end
            render.draw_scene(ecs_world)
            draw_world(bump_world)
            render.draw_positions(ecs_world)

            gfx.pop()

        end)

        ctx:yield()
    end
end
