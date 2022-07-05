local drawable = require "drawable"
local door = require "system.door"

local assemble = {}

function assemble.player(entity, x, y, bump_world)
    entity
        :assemble(collision.set_hitbox, 16, 32)
        :assemble(collision.set_bump_world, bump_world)
        :assemble(collision.warp_to, x, y)
        :set(nw.component.tag, "actor")
        :set(component.gravity)
        :set(nw.component.drawable, drawable.body)
        :set(component.actor)
        :set(component.one_way)
end

function assemble.switch(entity, x, y, bump_world)
    entity
        :assemble(collision.warp_to, x, y)
        :assemble(collision.set_hitbox, 50, 20)
        :assemble(collision.set_bump_world, bump_world)
        :set(nw.component.tag, "actor")
        :set(nw.component.drawable, drawable.ground_switch)
        :set(component.ground_switch)
end

function assemble.door(entity, x, y, bump_world)
    return entity
        :assemble(collision.init_entity, x, y, door.init_hitbox, bump_world)
        :set(component.door_state, false)
end

function assemble.spawn_point(entity, x, y, bump_world)
    entity
        :assemble(collision.set_hitbox, 100, 20)
        :assemble(collision.set_bump_world, bump_world)
        :assemble(collision.warp_to, x, y)
        :set(nw.component.tag, "actor")
        :set(component.actor)
        :set(component.spawn_point)
        :set(nw.component.drawable, drawable.body)
end

function assemble.skeleton_minion(entity, x, y, bump_world)
    entity
        :assemble(collision.set_hitbox, 20, 30)
        :assemble(collision.set_bump_world, bump_world)
        :assemble(collision.warp_to, x, y)
        :set(nw.component.tag, "actor")
        :set(component.actor)
        :set(component.gravity)
        :set(nw.component.drawable, drawable.body)
        :set(component.one_way)
end

function assemble.tile(entity, x, y, w, h, properties, bump_world)
    entity
        :assemble(collision.init_entity, x, y, spatial(0, 0, w, h), bump_world)
end

return assemble
