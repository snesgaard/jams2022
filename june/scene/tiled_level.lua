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

    nw.third.sti_parse(tiled_level, load_tile, load_object, ecs_world, bump_world)

    local camera_entity = ecs_world:entity(constants.id.camera)
        :set(component.camera, 50, "box", 50)
        :set(component.target, constants.id.player)
        :set(nw.component.position, -50, -50)

    local spawn_entity = ecs_world:entity()
        :assemble(assemble.spawn_point, -150, -200, bump_world, "skeleton")

    local spawn_entity = ecs_world:entity()
        :assemble(assemble.spawn_point, -350, -200, bump_world, "ghost")
        :set(nw.component.color, 0, 0.5, 1)

    local wall_switch = ecs_world:entity()
        :assemble(assemble.wall_switch, -50, -200, bump_world)

    local ground_switch = ecs_world:entity()
        :assemble(assemble.ground_switch, -100, -135, bump_world)

    local door = ecs_world:entity()
        :assemble(assemble.door, 0, -200, bump_world)
        :set(component.door_switch, ground_switch.id)

    ctx.world:push(camera.system, ecs_world)
    ctx.world:push(require "system.gravity", ecs_world)
    ctx.world:push(require "system.player_control", ecs_world)
    ctx.world:push(require("system.door").system, ecs_world)
    ctx.world:push(require "system.ground_switch", ecs_world)

    while ctx:is_alive() do
        draw:pop():foreach(function()
            gfx.push()

            camera.push_transform(camera_entity)
            for _, layer in ipairs(tiled_level.layers) do
                if layer.visible then layer:draw() end
            end
            render.draw_scene(ecs_world)
            --draw_world(bump_world)
            --render.draw_positions(ecs_world)
            --camera.draw_slack(camera_entity)

            gfx.pop()

        end)

        ctx:yield()
    end
end
