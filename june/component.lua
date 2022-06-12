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

return component
