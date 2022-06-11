local collision = {}

local function add_entity_to_world(entity)
    local hitbox = entity % nw.component.hitbox
    local bump_world = entity % nw.component.bump_world

    if not hitbox or not bump_world then return end

    local pos = entity:ensure(nw.component.position)

    local world_hb = hitbox:move(pos.x, pos.y)

    if not bump_world:hasItem(entity.id) then
        bump_world:add(entity.id, world_hb:unpack())
    else
        bump_world:update(entity.id, world_hb:unpack())
    end
end

function collision.set_hitbox(entity, ...)
    entity:set(nw.component.hitbox, ...)
    add_entity_to_world(entity)
end

function collision.set_bump_world(entity, bump_world)
    local prev_world = entity % nw.component.bump_world
    entity:set(nw.component.bump_world, bump_world)

    if prev_world ~= nil and prev_world ~= bump_world then
        prev_world:remove(entity)
    end

    add_entity_to_world(entity)
end

function collision.move(entity, dx, dy)
    local bump_world = entity % nw.component.bump_world
    local pos = entity:ensure(nw.component.position)

    if not bump_world or not bump_world:hasItem(entity.id) then
        entity:set(nw.component.position, pos + vec2(dx, dy))
        return dx, dy, dict()
    end

    local x, y = bump_world:getRect(entity.id)
    local tx, ty = x + dx, y + dy
    local ax, ay, col_info = bump_world:move(entity.id, tx, ty)

    if #col_info > 0 then emit_event(entity, "collision", col_info) end

    local real_dx, real_dy = ax - x, ay - y

    entity:set(nw.component.position, pos + vec2(real_dx, real_dy))

    return real_dx, real_dy, col_info
end

function collision.move_to(entity, x, y)
    local pos = entity:ensure(nw.component.position)
    local dx, dy = x - pos.x, y - pos.y
    local real_dx, real_dy, col_info = collision.move(entity, dx, dy)
    return pos.x + real_dx, pos.y + real_dy, col_info
end


return collision
