local Jump = require "system.player_jump"

local animations = {
    idle = get_atlas("art/characters"):get_animation("alchemist_chibi")
}

local jump_height = 64

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

    nw.system.animation(ctx):play(player_entity:peek(), animations.idle)

    print("player:level", ctx:from_cache("level"):peek())
    print("player:entity", player_entity:peek())

    local jump = Jump.create(ctx, player_entity)

    while ctx:is_alive() do
        for _, dt in ipairs(update:pop()) do
            local speed = 200
            collision(ctx):move(player_entity:peek(), speed * x_dir() * dt, 0)
        end

        if jump:pop() then
            player_entity:peek():map(nw.component.velocity, function(v)
                local g = player_entity:peek():ensure(nw.component.gravity)
                local vy = Jump.speed_from_height(g.y, jump_height)
                return vec2(v.x, -vy)
            end)
        end

        ctx:yield()
    end
end
