local component = {}

function component.event_callback(func)
    return func
end

function component.body(x, y, w, h)
    if w == nil then
        local x = x or 0
        local y = y or 0
        return spatial(-x / 2, -y, x, y)
    else
        return spatial(x, y, w, h)
    end
end

function component.spawn_point(type) return type or "skeleton" end

function component.spawned_minion(minion) return minion end

function component.actor() return true end

function component.switch_state(state) return state or false end

function component.ground_switch() return true end

function component.wall_switch() return true end

function component.draw_order(order) return order or 0 end

function component.door_state(open) return open or false end

function component.door_switch(id) return id end

function component.gravity(g) return g or vec2(0, 2000) end

function component.camera(slack, slack_type, max_move)
    return {
        slack = slack or 0,
        slack_type = slack_type or "box",
        max_move = max_move or 50
    }
end

function component.target(target) return target end

function component.one_way() return true end

function component.ghost() return true end

function component.goal() return true end

return component
