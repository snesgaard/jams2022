local drawable = require "drawable"
local door = require "system.door"
local render = require "render"

local assemble = {}

function assemble.player(entity, x, y, bump_world)
    entity
        :assemble(collision.set_hitbox, 16, 32)
        :assemble(collision.set_bump_world, bump_world)
        :assemble(collision.warp_to, x, y)
        :set(nw.component.tag, "actor")
        :set(component.gravity)
        :set(nw.component.drawable, drawable.animation)
        :set(component.actor)
        :set(component.one_way)
end

function assemble.ground_switch(entity, x, y, bump_world)
    entity
        :assemble(collision.warp_to, x, y)
        :assemble(collision.set_hitbox, 20, 20)
        :assemble(collision.set_bump_world, bump_world)
        :set(nw.component.tag, "actor")
        :set(nw.component.drawable, drawable.ground_switch)
        :set(component.ground_switch)
        :set(component.actor)
        :set(component.draw_order, render.draw_order.prop_foreground)
end

function assemble.wall_switch(entity, x, y, bump_world)
    entity
        :assemble(collision.init_entity, x, y, component.body(16, 16), bump_world)
        :set(nw.component.drawable, drawable.wall_switch)
        :set(component.wall_switch)
        :set(component.ghost)
        :set(component.switch_state, false)
        :set(component.draw_order, render.draw_order.prop_foreground)
end

function assemble.door(entity, x, y, bump_world)
    return entity
        :assemble(collision.init_entity, x, y, door.init_hitbox, bump_world)
        :set(component.door_state, false)
        :set(nw.component.drawable, drawable.body)
end

function assemble.spawn_point(entity, x, y, bump_world, minion_type)
    entity
        :assemble(collision.set_hitbox, 32, 32)
        :assemble(collision.set_bump_world, bump_world)
        :assemble(collision.warp_to, x, y)
        :set(nw.component.tag, "actor")
        :set(component.actor)
        :set(component.spawn_point, minion_type)
        :set(nw.component.drawable, drawable.spawn_point)
        :set(component.draw_order, render.draw_order.prop_background)
end

function assemble.skeleton_minion(entity, x, y, bump_world)
    entity
        :assemble(collision.set_hitbox, 20, 30)
        :assemble(collision.set_bump_world, bump_world)
        :assemble(collision.warp_to, x, y)
        :set(nw.component.tag, "actor")
        :set(component.actor)
        :set(component.gravity)
        :set(nw.component.drawable, drawable.animation)
        :set(component.one_way)
end

function assemble.ghost_minion(entity, x, y, bump_world)
    entity
        :assemble(collision.init_entity, x, y, component.body(20, 30), bump_world)
        :set(component.actor)
        :set(nw.component.drawable, drawable.animation)
        :set(component.ghost)
        :set(nw.component.color, 1, 1, 1)
end

function assemble.tile(entity, x, y, w, h, properties, bump_world)
    entity
        :assemble(collision.init_entity, x, y, spatial(0, 0, w, h), bump_world)
end

function assemble.goal(entity, x, y, bump_world)
    entity
        :set(component.ghost)
        :set(component.goal)
        :assemble(collision.init_entity, x, y, component.body(20, 30), bump_world)
        :set(nw.component.drawable, drawable.body)
        :set(nw.component.color, 0.2, 0.8, 0.6, 0.5)
        :set(nw.component.drawable, drawable.goal)
end

function assemble.interaction(entity)
    entity
        :set(nw.component.drawable, drawable.interaction)
        :set(component.draw_order, render.draw_order.ui_foreground)
end

local dirt_image = gfx.prerender(4, 3, function(w, h)
    gfx.setColor(1, 1, 1)
    gfx.ellipse("fill", w / 2, h / 2, w / 2, h / 2)
end)

function assemble.skeleton_dirt_spawn(entity, x, y)
    entity
        :set(
            nw.component.particles,
            {
                buffer = 20,
                image = dirt_image,
                emit = 20,
                lifetime = 0.5,
                dir = -math.pi * 0.5,
                spread = math.pi * 0.25,
                speed = {100, 300},
                damp = 0,
                acceleration = {0, 1000},
                relative_rotation = true,
                color = {
                    gfx.hex2color("953f5c"),
                    gfx.hex2color("953f5c"),
                    gfx.hex2color("953f5c00"),
                }
            }
        )
        :set(nw.component.position, x, y)
        :set(nw.component.drawable, drawable.particles)
        :set(component.draw_order, render.draw_order.ui_foreground)
        :set(component.one_shot)
end

return assemble
