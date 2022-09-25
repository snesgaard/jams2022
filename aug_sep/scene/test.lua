local Connect = require "rules.connect"
local Proximity = require "system.proximity"

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
    if ecs_world:get(nw.component.ghost, item) or ecs_world:get(nw.component.ghost, other) then
        return "cross"
    end
    return "slide"
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

local rules = {}

function rules.die(state, id)
    state:destroy(id)

    local info = {id = id}

    return Connect.epoch(state, info)
end

function rules.spawn(state, parent_id)
    local pos = state:get(nw.component.position, parent_id) or vec2()
    local bump_world = state:get(nw.component.bump_world, parent_id)

    state:entity()
        :assemble(assemble.alchemy_cloud, pos.x, pos.y, "foobar", bump_world)

    return Connect.epoch(state)
end

function rules.collision(state, colinfo)
    local actions = list()

    if state:get(nw.component.die_on_impact, colinfo.item) then
        if state:get(nw.component.element, colinfo.item) then
            table.insert(actions, {"spawn", colinfo.item})
        end

        table.insert(actions, {"die", colinfo.item})
    end

    return Connect.epoch(state), actions
end

return function(ctx)
    local level = load_and_populate_level("art/maps/build/develop.lua")

    ctx:to_cache("level", level)

    local camera_entity = level.ecs_world:entity(constants.id.camera)
        :set(nw.component.camera, 25, "box", 50)
        :set(nw.component.target, constants.id.player)
        :set(nw.component.scale, constants.scale, constants.scale)

    collision(ctx).default_filter = default_collision_filter

    ctx.world:push(require "system.motion")
    ctx.world:push(require "system.player_control")
    ctx.world:push(require "system.collision_resolver")
    ctx.world:push(generic_system_wrap, nw.system.camera)
    ctx.world:push(generic_system_wrap, require "system.lifetime")
    ctx.world:push(Proximity.system)

    local draw = ctx:listen("draw"):collect()
    local update = ctx:listen("update"):collect()

    local connect = Connect.create(ctx, rules, list("collision"))
    
    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            nw.system.animation(ctx):update(dt, level.ecs_world)
            connect:spin()
        end

        for _, _ in ipairs(draw:pop()) do
            gfx.push()

            camera.push_transform(camera_entity)
            gfx.setColor(1, 1, 1)
            for _, layer in ipairs(level.layers) do
                if layer.visible then layer:draw() end
            end

            render.draw_scene(level.ecs_world)
            Proximity.draw(level.ecs_world:entity(constants.id.player))
            gfx.pop()

            draw_health(level.ecs_world, constants.id.player)
        end

        ctx:yield()
    end
end
