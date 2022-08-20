local render = {}

render.draw_order = {
}

function render.draw_scene(ecs_world, animation)
    local drawables = Dictionary.keys(
        ecs_world:get_component_table(nw.component.drawable)
    )

    local function cmp(a, b)
        local da = ecs_world:ensure(nw.component.draw_order, a)
        local db = ecs_world:ensure(nw.component.draw_order, b)
        if da ~= db then return da < db end
        local pos_a = ecs_world:ensure(nw.component.position, a)
        local pos_b = ecs_world:ensure(nw.component.position, b)

        return pos_a.x < pos_b.x
    end

    table.sort(drawables, cmp)

    for _, id in ipairs(drawables) do
        local draw = ecs_world:get(nw.component.drawable, id)
        gfx.push("all")
        draw(ecs_world:entity(id), animation)
        gfx.pop()
    end
end

function render.draw_positions(ecs_world)
    local pos_table = ecs_world:get_component_table(nw.component.position)
    for entity, pos in pairs(pos_table) do
        gfx.circle("line", pos.x, pos.y, 5)
    end
end

return render
