local component = {}

function component.event_callback(func)
    return func
end

function component.body(x, y, w, h)
    if w == nil then
        return spatial(-x / 2, -y, x, y)
    else
        return spatial(x, y, w, h)
    end
end

function component.spawn_point() return true end

function component.spawned_minion(minion) return minion end

function component.actor() return true end

function component.switch_state(state) return state or false end

function component.ground_switch() return true end

function component.draw_order(order) return order or 0 end

function component.door_state(open) return open or false end

function component.door_switch(id) return id end

function component.gravity(g) return g or vec2(0, 2000) end

function component.camera() return {} end

return component
