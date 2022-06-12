local collision = {}

local function add_entity_to_world(entity)
    local hitbox = entity % component.body
    local bump_world = entity % nw.component.bump_world

    if not hitbox or not bump_world then return end

    local pos = entity:ensure(nw.component.position)

    local world_hb = hitbox:move(pos.x, pos.y)
    print(world_hb)

    if not bump_world:hasItem(entity.id) then
        bump_world:add(entity.id, world_hb:unpack())
    else
        bump_world:update(entity.id, world_hb:unpack())
    end
end

function collision.set_hitbox(entity, ...)
    entity:set(component.body, ...)
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

local function collision_filter(ecs_world, a, b)
    local tag_a = ecs_world:get(nw.component.tag, a)
    local tag_b = ecs_world:get(nw.component.tag, b)

    if not tag_a or not tag_b then return "slide" end
end

local cached_filter = {}

local function get_filter(ecs_world)
    if not cached_filter[ecs_world] then
        cached_filter[ecs_world] = function(a, b)
            return collision_filter(ecs_world, a, b)
        end
    end

    return cached_filter[ecs_world]
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

    local ecs_world = entity:world()

    local ax, ay, col_info = bump_world:move(
        entity.id, tx, ty, get_filter(ecs_world)
    )

    if #col_info > 0 then
        col_info.ecs_world = entity:world()
        emit_event(entity, "collision", col_info)
    end

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

function collision.warp_to(entity, x, y)
    local bump_world = entity % nw.component.bump_world
    local pos = entity:ensure(nw.component.position)

    entity:set(nw.component.position, x, y)

    if not bump_world or not bump_world:hasItem(entity.id) then return end

    local dx, dy = x - pos.x, y - pos.y
    local bx, by = bump_world:getRect(entity.id)
    bump_world:update(entity.id, bx + dx, by + dy)
end

function collision.is_solid(col_info)
    return col_info.type == "slide"
end

local function sanitize_spatial(x, y, w, h)
    if w == nil then
        return -x / 2, -y / 2, x, y
    else
        return x, y, w, h
    end
end

function collision.check(entity, x, y, w, h)
    local pos = entity:ensure(nw.component.position)
    local x, y, w, h = sanitize_spatial(x, y, w, h)
    local bump_world = entity % nw.component.bump_world
    if not bump_world then return list() end
    local items = bump_world:queryRect(x + pos.x, y + pos.y, w, h)
    return list(unpack(items)):filter(function(id) return id ~= entity.id end)
end

return collision
