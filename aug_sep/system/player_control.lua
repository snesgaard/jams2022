return function(ctx)
    local update = ctx:listen("update"):collect()

    local function x_dir()
        local x = 0
        local dir = {left = -1, right = 1}

        for k, v in pairs(dir) do
            if love.keyboard.isDown(k) then x = x + v end
        end
        
        return x
    end

    local player_entity = ctx:from_cache("level")
        :map(function(level)
            return level.ecs_world:entity(constants.id.player)
        end)
        :latest()

    print("player:level", ctx:from_cache("level"):peek())
    print("player:entity", player_entity:peek())

    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            local speed = 200
            collision(ctx):move(player_entity:peek(), speed * x_dir() * dt, 0)
        end

        ctx:yield()
    end
end
