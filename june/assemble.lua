local drawable = require "drawable"
local door = require "system.door"

local assemble = {}

function assemble.player(entity, x, y, bump_world)
    entity
        :assemble(collision.set_hitbox, 20, 20)
        :assemble(collision.set_bump_world, bump_world)
        :assemble(collision.warp_to, x, y)
        :set(nw.component.tag, "actor")
        :set(component.gravity)
        :set(nw.component.drawable, drawable.body)
        :set(component.actor)
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
end

function assemble.skeleton_minion(entity, x, y, bump_world)
    entity
        :assemble(collision.set_hitbox, 20, 30)
        :assemble(collision.set_bump_world, bump_world)
        :assemble(collision.warp_to, x, y)
        :set(nw.component.tag, "actor")
        :set(component.actor)
        :set(nw.component.gravity, 0, 200)
end

return assemble
