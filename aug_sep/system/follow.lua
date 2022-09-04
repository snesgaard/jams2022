local function handle_moved(entity, dx, dy)
    local followers = entity:get(component.followers)
    for _, follower in ipairs(followers) do
        collision(ctx):move(follower, dx, dy, function(ecs_world, item, other)
            if other == entity.id then return false end
            return collision().default_collision_filter(ecs_world, item, other)
        end)
    end
end

local assemble = {}

function assemble.follow(follower, leader)
    if follower:get(component.leader) == leader then return end

    follower:assemble(assemble.unfollow)

    leader:map(component.followers, function(followers)
        return followers:insert(follower)
    end)
    follower:set(component.leader, leader)
end

function assemble.unfollow(follower)
    if not follower:has(component.leader) then return end

    local leader = follower:get(component.leader)
    leader:map(component.followers, function(followers)
        return followers:filter(function(f) return f ~= follower end)
    end)
    follower:remove(component.leader)
end

return function(ctx)
    local entity_moved = ctx:listen("moved")
        :filter(function(entity)
            return entity:has(component.followers)
        end)
        :collect()

    while ctx:is_alive() do
        for _, event in ipairs(entity_moved:pop()) do
            handle_moved(unpack(event))
        end
        ctx:yield()
    end
end
