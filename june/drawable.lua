local drawables = {}

function drawables.body(entity)
    local body = entity % component.body
    if not body then return end
    local pos = entity:ensure(nw.component.position)
    gfx.setColor(1, 1, 1)
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

return drawables
