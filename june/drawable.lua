local drawables = {}

function drawables.push_state(entity)
    local color = entity % nw.component.color
    if color then
        gfx.setColor(color)
    else
        gfx.setColor(1, 1, 1)
    end
end

function drawables.push_transform(entity)
    local pos = entity:get(nw.component.position)
    if pos then gfx.translate(pos.x, pos.y) end
    local scale = entity:get(nw.component.scale)
    if scale then gfx.scale(scale.x, scale.y) end
end

function drawables.body(entity)
    local body = entity % component.body
    if not body then return end
    local pos = entity:ensure(nw.component.position)
    drawables.push_state(entity)
    gfx.translate(pos.x, pos.y)
    gfx.rectangle("fill", body:unpack())
end

function drawables.ground_switch(entity)
    local body = entity % component.body
    if not body then return end
    local state = entity % component.switch_state
    local pos = entity:ensure(nw.component.position)
    local str = state and "ground_switch/on" or "ground_switch/off"
    local image = get_atlas("art/characters"):get_frame(str)
    image:draw("body", pos.x, pos.y)
end

function drawables.wall_switch(entity)
    local state = entity % component.switch_state
    local pos = entity % nw.component.position
    if not pos then return end

    gfx.setColor(1, 1, 1)
    local str = state and "wall_switch/on" or "wall_switch/off"
    local image = get_atlas("art/characters"):get_frame(str)
    image:draw("body", pos.x, pos.y)
end

function drawables.animation(entity, animation)
    local frame = animation:get(entity.id)
    gfx.push()
    drawables.push_transform(entity)
    drawables.push_state(entity)
    if frame then
        frame:draw("body")
    else
        gfx.rectangle("fill", -5, -10, 10, 10)
    end
    gfx.pop()
end

function drawables.spawn_point(entity)
    local type = entity:get(component.spawn_point)
    local frame = get_atlas("art/characters"):get_frame("spawn_point/skeleton")

    gfx.push()
    drawables.push_transform(entity)
    drawables.push_state(entity)
    if type == "ghost" then
        gfx.setColor(0.2, 0.8, 0.4)
    end
    frame:draw("body")
    gfx.pop()
end

function drawables.interaction(entity)
    local target = entity:get(component.target)
    if not target then return end

    local target_entity = entity:world():entity(target)
    local body = target_entity:get(component.body) or component.body()

    gfx.push()
    drawables.push_transform(target_entity)
    drawables.push_state(entity)

    local margin = 5

    gfx.stencil(function()
        gfx.rectangle("fill", body:expand(margin * 2, -margin * 2):unpack())
        gfx.rectangle("fill", body:expand(-margin * 2, margin * 2):unpack())
    end, "replace", 1)
    gfx.setStencilTest("equal", 0)
    gfx.rectangle("line", body:unpack())
    gfx.setStencilTest()
    gfx.pop()
end

return drawables
