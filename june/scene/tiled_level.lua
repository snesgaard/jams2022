return function(ctx)
    local tiled_level = nw.third.sti("art/maps/build/develop.lua")
    local draw = ctx:listen("draw"):collect()

    for _, layer in ipairs(tiled_level.layers) do
        print(dict(layer))
    end

    while ctx:is_alive() do
        draw:pop():foreach(function()
            tiled_level:draw()
        end)
        ctx:yield()
    end
end
