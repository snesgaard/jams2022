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
    elseif object.type == "reagent" then
        return map.ecs_world:entity(object.id)
            :assemble(
                assemble.reagent, object.x, object.y, map.bump_world,
                object.properties.reagent
            )
    end
end

local function load_and_populate_level(path)
    local tiled_level = nw.third.sti(path)

    tiled_level.bump_world = nw.third.bump.newWorld()
    tiled_level.ecs_world = nw.ecs.entity.create()

    function tiled_level.ecs_world:get_component_table(component, get_all)
        local tab = nw.ecs.entity.get_component_table(self, component)
        if get_all then return tab end
        return Dictionary.filter(tab, function(id, _)
            return not self:get(nw.component.paused, id)
        end)
    end

    nw.third.sti_parse(tiled_level, load_tile, load_object)

    return tiled_level
end

local function default_collision_filter(ecs_world, item, other)
    if ecs_world:get(nw.component.ghost, item) or ecs_world:get(nw.component.ghost, other) then
        return "cross"
    end
    return "slide"
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

local function draw_reagent_inventory(ecs_world, id)
    local inventory = ecs_world:ensure(nw.component.reagent_inventory, id)

    local reagent_color = {
        sulfur = color(0.8, 0.8, 0.2),
        mushroom = color(0.2, 0.3, 0.8),
        flower = color(0.8, 0.3, 0.2)
    }

    gfx.push("all")
    for index, reagent in ipairs(inventory) do
        gfx.setColor(reagent_color[reagent])
        gfx.circle("fill", 20 * index, 40, 10, 10)
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

    ctx.world:push(require "system.player_control")
    ctx.world:push(require "system.collision_resolver")
    ctx.world:push(Proximity.system)

    local draw = ctx:listen("draw"):collect()
    local update = ctx:listen("update"):collect()
    local collision = ctx:listen("collision"):collect()

    local connect = Connect.create(ctx, rules, list("collision"))

    local systems = list(
        nw.system.camera,
        require "system.lifetime",
        nw.system.motion(ctx),
        nw.system.animation(ctx)
    )

    local systems_with_obs = systems
        :map(function(system) return system.observables(ctx) end)

    while ctx:is_alive() do
        -- TODO: This is the way to go. Pausing can be implemented easily be
        -- simply filtering which ecs worlds are given to each system.
        for i = 1, systems:size() do
            local sys = systems[i]
            local obs = systems_with_obs[i]
            sys.handle_observables(ctx, obs, level.ecs_world)
        end

        connect:spin()
        
        for _, _ in ipairs(draw:pop()) do
            gfx.push()

            nw.system.camera.push_transform(camera_entity)

            gfx.setColor(1, 1, 1)
            for _, layer in ipairs(level.layers) do
                if layer.visible then layer:draw() end
            end

            render.draw_scene(level.ecs_world)
            Proximity.draw(level.ecs_world:entity(constants.id.player))
            gfx.pop()

            draw_health(level.ecs_world, constants.id.player)
            draw_reagent_inventory(level.ecs_world, constants.id.player)
        end

        ctx:yield()
    end
end
