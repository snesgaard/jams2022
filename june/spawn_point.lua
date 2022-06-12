local spawn_point = {}

function spawn_point.assemble(entity, x, y, bump_world)
    entity
        :assemble(collision.set_hitbox, 100, 20)
        :assemble(collision.set_bump_world, bump_world)
        :assemble(collision.warp_to, x, y)
        :set(nw.component.tag, "actor")
        :set(component.actor)
        :set(component.spawn_point)
end

function spawn_point.assemble_minion(entity, x, y, bump_world)
    entity
        :assemble(collision.set_hitbox, 20, 30)
        :assemble(collision.set_bump_world, bump_world)
        :assemble(collision.warp_to, x, y)
        :set(nw.component.tag, "actor")
        :set(component.actor)
        :set(nw.component.gravity, 0, 200)
end

function spawn_point.is_spawn_point(entity)
    return entity % component.spawn_point
end

function spawn_point.spawn(entity)
    if not spawn_point.is_spawn_point(entity) then return end

    local bump_world = entity % nw.component.bump_world
    local pos = entity:ensure(nw.component.position)

    local prev_minion = entity % component.spawned_minion

    if prev_minion then prev_minion:destroy() end

    local next_minion = entity:world():entity()
        :assemble(spawn_point.assemble_minion, pos.x, pos.y, bump_world)

    entity:set(component.spawned_minion, next_minion)

    return next_minion
end

return spawn_point
