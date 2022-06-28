local camera = {}

function camera.push_transform(entity)
    local pos = entity % nw.component.position or vec2()
    local scale = entity % nw.component.scale or vec2(1, 1)
    local w, h = gfx.getWidth(), gfx.getHeight()

    gfx.translate(w / 2, h / 2)
    gfx.scale(scale.x, scale.y)
    gfx.translate(-pos.x, -pos.y)
end

function camera.sti_args(entity)
    local pos = entity % nw.component.position or vec2()

    return -pos.x, -pos.y
end

local function handle_wheelmoved(ecs_world, m)
    local et = ecs_world:get_component_table(component.camera)
    local scale = m.y > 0 and 1.1 or 0.9

    for id, _ in pairs(et) do
        local entity = ecs_world:entity(id)
        local s = entity:ensure(nw.component.scale, 1, 1)
        s.x = s.x * scale
        s.y = s.y * scale
    end
end

local function handle_mousemoved(ecs_world, x,  y, dx, dy)
    if not love.mouse.isDown(1) then return end

    local et = ecs_world:get_component_table(component.camera)

    for id, _ in pairs(et) do
        local entity = ecs_world:entity(id)
        local pos = entity:ensure(nw.component.position)
        local scale = entity:ensure(nw.component.scale, 1, 1)

        pos.x = pos.x - dx / scale.x
        pos.y = pos.y - dy / scale.y
    end
end

function camera.system(ctx, ecs_world)
    local wheelmoved = ctx:listen("wheelmoved")
        :map(vec2)
        :collect()

    local mousemoved = ctx:listen("mousemoved")
        :collect()

    while ctx:is_alive() do
        wheelmoved
            :pop()
            :foreach(function(m)
                handle_wheelmoved(ecs_world, m)
            end)

        mousemoved
            :pop()
            :foreach(function(args)
                handle_mousemoved(ecs_world, unpack(args))
            end)

        ctx:yield()
    end
end

return camera
