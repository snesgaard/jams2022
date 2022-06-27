local spawn_point = {}

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
        :assemble(assemble.skeleton_minion, pos.x, pos.y, bump_world)

    entity:set(component.spawned_minion, next_minion)

    return next_minion
end

return spawn_point
