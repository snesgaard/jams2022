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
    if state then
        gfx.setColor(0.2, 0.8, 0.4)
    else
        gfx.setColor(0.8, 0.3, 0.2)
    end
    gfx.translate(pos.x, pos.y)
    gfx.rectangle("line", body:unpack())
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

return drawables
