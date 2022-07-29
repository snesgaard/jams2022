local collision = require "collision"

local spawn_point = {}

function spawn_point.despawn(entity)
    prev_minion
        :assemble(collision.set_bump_world)
        :remove(component.gravity)

end

function spawn_point.is_spawn_point(entity)
    return entity % component.spawn_point
end

function spawn_point.assemble_from_key(key)
    if key == "skeleton" then
        return assemble.skeleton_minion
    elseif key == "ghost" then
        return assemble.ghost_minion
    else
        errorf("Unknown minion key %s", key)
    end
end

function spawn_point.spawn(entity)
    local minion_type = spawn_point.is_spawn_point(entity)
    if not minion_type then return end

    local minion_assemble = spawn_point.assemble_from_key(minion_type)

    local bump_world = entity % nw.component.bump_world
    local pos = entity:ensure(nw.component.position)

    local prev_minion = entity % component.spawned_minion

    if prev_minion then
    end

    local next_minion = entity:world():entity()
        :assemble(minion_assemble, pos.x, pos.y, bump_world)

    entity:set(component.spawned_minion, next_minion)

    return next_minion
end

return spawn_point
