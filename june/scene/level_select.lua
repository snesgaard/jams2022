local levels = {
    {name = "develop", path = "develop.lua"},
    {name = "ghost_switch", path = "ghost_switch.lua"},
    {name = "ground_simple", path = "ground_simple.lua"},
    {name = "stack", path = "skeleton_stack.lua"},
    {name = "ghost_skeleton", path = "ghost_skeleton.lua"}
}

local function compute_vertical_offset(valign, font_h, h)
    if valign == "top" then
		return 0
	elseif valign == "bottom" then
		return h - font_h
    else
        return (h - font_h) / 2
	end
end

local function draw_text(text, x, y, w, h, opt, sx, sy)
    local opt = opt or {}
    if opt.font then gfx.setFont(opt.font) end

    local sx = sx or 1
    local sy = sy or sx

    local dy = compute_vertical_offset(
        opt.valign, gfx.getFont():getHeight() * sy, h
    )

    gfx.printf(text, x, y + dy, w / sx, opt.align or "left", 0, sx, sy)
end

local function path_component(path)
    return string.format("art/maps/build/%s", path)
end

local function assemble_box(entity, index, name, path)
    local body = component.body(200, 50):down()

    for i = 1, index - 1 do
        body = body:down():move(0, 20)
    end

    entity
        :set(component.body, body:unpack())
        :set(nw.component.text, name)
        :set(path_component, path)
end

local function init_esc()
    local ecs_world = nw.ecs.entity.create()

    local base_box = component.body(200, 50)

    for index, data in ipairs(levels) do
        ecs_world:entity(index):assemble(assemble_box, index, data.name, data.path)
    end

    return ecs_world
end

local function selected_component(index) return index end

local function handle_draw(ecs_world)
    gfx.push()
    gfx.translate(gfx.getWidth() / 2, 100)
    local selected_index = ecs_world:get(
        selected_component, constants.id.player
    )
    for i = 1, #levels do
        if selected_index == i then
            gfx.setColor(1, 0.3, 0.1)
        else
            gfx.setColor(1, 1, 1)
        end
        local body = ecs_world:get(component.body, i)
        gfx.rectangle("fill", body:unpack())
        gfx.setColor(0, 0, 0)
        local name = ecs_world:get(nw.component.text, i)
        draw_text(
            name, body.x, body.y, body.w, body.h,
            {align = "center", valign="center"}
        )
    end
    gfx.pop()
end

local function handle_mouse_moved(ecs_world, x, y)
    local tx, ty = gfx.getWidth() / 2, 100
    for i = 1, #levels do
        local body = ecs_world:get(component.body, i)
        if body:point_inside(x - tx, y - ty) then
            ecs_world:set(selected_component, constants.id.player, i)
            return
        end
    end
    --ecs_world:set(selected_component, constants.id.player)
end

local function handle_mouse_pressed(ecs_world, x, y)
    handle_mouse_moved(ecs_world, x, y)
    local tx, ty = gfx.getWidth() / 2, 100

    for i = 1, #levels do
        local body = ecs_world:get(component.body, i)
        if body:point_inside(x - tx, y - ty) then
            return ecs_world:get(path_component, i)
        end
    end
end

return function(ctx)
    local draw = ctx:listen("draw"):collect()
    local mousemoved = ctx:listen("mousemoved"):collect()
    local ecs_world = init_esc()

    local level_to_load_from_mouse = ctx:listen("mousepressed")
        :map(function(x, y) return handle_mouse_pressed(ecs_world, x, y) end)
        :filter()

    local level_to_load_from_key = ctx:listen("keypressed")
        :map(tonumber)
        :filter()
        :map(function(index)
            return ecs_world:get(path_component, index)
        end)
        :filter()

    local level_to_load = level_to_load_from_mouse
        :merge(level_to_load_from_key)
        :latest()

    while ctx:is_alive() and not level_to_load:peek() do
        for _, _ in ipairs(draw:pop()) do
            handle_draw(ecs_world)
        end
        for _, data in ipairs(mousemoved:pop()) do
            handle_mouse_moved(ecs_world, unpack(data))
        end
        ctx:yield()
    end

    print(level_to_load:peek())
    ctx.world:push(require "scene.tiled_level", level_to_load:peek())
end
