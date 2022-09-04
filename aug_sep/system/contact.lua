local function register_collision(item, other)
    local contact = item:ensure(nw.component.contact)
    contact[other] = true
end

local function unregister_collision(item, other)
    local contact = item:ensure(nw.component.contact)
    contact[other] = false
end

return function(ctx)
    local collision = ctx:listen("collision")
    local moved = ctx:listen("moved")

    while ctx:is_alive() do
        ctx:yield()
    end
end
