local function transform_to_move_pair(col_info)
    local item = col_info.item
    local other = col_info.other

    if item:has(component.moving_platform) and other:has(component.actor) then
        return {
            platform = item,
            actor = other,
            col_info = col_info
        }
    end

    if item:has(component.actor) and other:has(component.moving_platform) then
        return {
            platform = other,
            actor = item,
            col_info = col_info
        }
    end
end

local function active_following(platform_actor)
    platform.actor:assemble(system.follow.assemble.follow, platform.platform)
end

local function is_following_platform(entity)
    local leader = entity:get(component.leader)
    if not leader then return end
    return leader:has(component.moving_platform)
end

return function(ctx)
    local collision = ctx:listen("collision")
        :filter(function(col_info) return col_info.type == "slide" end)
        :map(transform_to_move_pair)
        :filter()
        :collect()

    while ctx:is_alive() do
        ctx:yield()
    end
end
