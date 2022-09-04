local function should_activate(item, other)
    local activate_once = item:get(nw.component.activate_once)
    if not activate_once then return true end
    if activate_once[other.id] then return false end
    activate_once[other.id] = true
    return true
end

local function resolve(item, other, col_info)
    if item:get(nw.component.healing) and should_activate(item, other) then
        print("heals")
    end
end

local function resolve_collision(col_info)
    local item_entity = col_info.ecs_world:entity(col_info.item)
    local other_entity = col_info.ecs_world:entity(col_info.other)
    resolve(item_entity, other_entity, col_info)
    resolve(other_entity, item_entity, col_info)
end

return function(ctx)
    local collision = ctx:listen("collision"):collect()

    while ctx:is_alive() do
        for _, colinfo in ipairs(collision:pop()) do
            resolve_collision(colinfo)
        end

        ctx:yield()
    end
end
