local camera = require "system.camera"
local render = require "render"
local bumpdebug = require "bumpdebug"

local function load_tile(map, layer, tile, x, y, ctx)
    return ctx:ecs_world():entity()
        :assemble(
            assemble.tile, x, y, tile.width, tile.height, tile.properties,
            ctx:bump_world()
        )
end

local function load_object(map, layer, object, ctx)
    if object.type == "player_spawn" then
        return ctx:ecs_world():entity(constants.id.player)
            :assemble(assemble.player, object.x, object.y, ctx:bump_world())
    elseif object.type == "spawn_point" then
        return ctx:ecs_world():entity(object.id)
            :assemble(
                assemble.spawn_point, object.x, object.y, ctx:bump_world(),
                object.properties.minion_type or "skeleton"
            )
    elseif object.type == "goal" then
        return ctx:ecs_world():entity(object.id)
            :assemble(assemble.goal, object.x, object.y, ctx:bump_world())
    elseif object.type == "wall_switch" then
        return ctx:ecs_world():entity(object.id)
            :assemble(assemble.wall_switch, object.x, object.y, ctx:bump_world())
    elseif object.type == "ground_switch" then
        return ctx:ecs_world():entity(object.id)
            :assemble(assemble.ground_switch, object.x, object.y, ctx:bump_world())
    elseif object.type == "door" then
        local switch_id = object.properties.switch and object.properties.switch.id or nil
        return ctx:ecs_world():entity(object.id)
            :assemble(assemble.door, object.x, object.y, ctx:bump_world())
            :set(component.door_switch, switch_id)
    end
end

local function draw_controls(ecs_world)
    local shape = spatial(10, 10, 175, 100)
    gfx.setColor(constants.theme.grey)
    gfx.rectangle("fill", shape:expand(16, 16):unpack())
    gfx.setColor(constants.theme.purple)
    gfx.rectangle("fill", shape:expand(6, 6):unpack())
    gfx.setColor(constants.theme.light)
    painter.text(
        "__Controls__\n<- -> :: Move\nspace :: jump\nx :: interact\nz :: leave monion",
        shape.x, shape.y, shape.w, shape.h,
        {align="left", valign="top", font=constants.font.normal}
    )
end


local function system(ctx, level_path)
    ctx:clear_global()
    local tiled_level = nw.third.sti(level_path or "art/maps/build/ground_simple.lua")
    local ecs_world = ctx:ecs_world()
    local bump_world = ctx:bump_world()

    ecs_world:entity(constants.id.global)
        :set(nw.component.bump_world, bump_world)
        :set(component.event_callback, function(...) ctx:emit(...) end)

    for _, layer in ipairs(tiled_level.layers) do
        print(dict(layer))
    end

    nw.third.sti_parse(
        tiled_level, load_tile, load_object, ctx
    )

    local camera_entity = ecs_world:entity(constants.id.camera)
        :set(component.camera, 25, "box", 50)
        :set(component.target, constants.id.player)
        :set(nw.component.position, -200, -200)
        :set(nw.component.scale, constants.scale, constants.scale)


    local draw = ctx:listen("draw"):collect()
    local update = ctx:listen("update"):collect()
    local goal_reached = ctx:listen("goal_reached"):latest()

    local interaction_entity = ecs_world:entity(constants.id.interaction)
        :assemble(assemble.interaction)
        :set(component.target, constants.id.player)

    ctx.world:push(require "system.collision_response")
    ctx.world:push(require "system.gravity", ecs_world)
    local player_control = ctx.world:push(require "system.player_control", ecs_world)
    ctx.world:push(require("system.door").system, ecs_world)
    ctx.world:push(require "system.ground_switch", ecs_world)
    ctx.world:push(require "system.particles")
    ctx.world:push(camera.system, ecs_world)

    local function draw_and_animate()
        draw:peek():foreach(function()
            gfx.push()

            camera.push_transform(camera_entity)
            gfx.setColor(1, 1, 1)
            for _, layer in ipairs(tiled_level.layers) do
                if layer.visible then layer:draw() end
            end
            render.draw_scene(ctx:ecs_world(), ctx:animation())
            --draw_world(bump_world)
            --render.draw_positions(ecs_world)
            --camera.draw_slack(camera_entity)
            gfx.pop()

            draw_controls(ecs_world)
        end)

        for _, dt in ipairs(update:pop()) do
            ctx:animation():update(dt)
        end
    end

    while ctx:is_alive() and not goal_reached:peek() do
        draw_and_animate()
        ctx:yield()
    end

    player_control:kill()

    local confirm = ctx:listen("keypressed")
        :filter(function(key) return key == "space" end)
        :latest()

    while ctx:is_alive() and not confirm:peek() do
        draw_and_animate()
        for _, _ in ipairs(draw:peek()) do
            gfx.setColor(1, 1, 1)
            gfx.rectangle("fill", 0, 0, 100, 100)
        end
        ctx:yield()
    end

    ctx:kill_all_but_this()
    ctx:yield()
    ctx.world:push(require "scene.level_select")
end

return system
