local nw = require "nodeworks"

local function create_global()
    return {
        ecs_world = nw.ecs.entity.create(),
        animation = im_animation.create(),
        bump_world = nw.third.bump.newWorld()
    }
end

function nw.ecs.World:global()
    if not self.__global then self.__global = create_global() end

    return self.__global
end

function nw.ecs.World:clear_global()
    self.__global = nil
    return self
end

function nw.ecs.World:ecs_world()
    return self:global().ecs_world
end

function nw.ecs.World:animation()
    return self:global().animation
end

function nw.ecs.World:bump_world()
    return self:global().bump_world
end

local func_to_forward = {
    "global", "bump_world", "ecs_world", "animation", "clear_global"
}

for _, name in ipairs(func_to_forward) do
    nw.ecs.World.Context[name] = function(self, ...)
        local f = self.world[name]
        return f(world, ...)
    end
end
