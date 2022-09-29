local component = {}

function component.actor() return true end

function component.faction(f) return f end

function component.hitbox(x, y, w, h)
    if w == nil then
        return spatial(-x / 2, -y, x, y)
    elseif type(x) == "table" then
        return x
    else
        return spatial(x, y, w, h)
    end
end

function component.draw_order(i) return i or 0 end

function component.ghost() return true end

function component.healing() return true end

function component.activate_once() return {} end

function component.gravity(x, y)
    if not x then return vec2(0, 1000) end

    return vec2(x, y)
end

function component.lifetime(duration)
    if not duration then error("you must specify duration") end

    return {
        time = duration,
        duration = duration
    }
end

function component.patrol(path, cycle_time)
    local points = List.map(path, function(p) return vec2(p.x, p.y) end)
    local lines = List.zip(points:sub(1, #points - 1), points:sub(2, #points))
    local lengths = lines:map(function(l)
        local p1, p2 = unpack(l)
        return (p1 - p2):length()
    end)
    local total_length = lengths:reduce(function(a, b) return a + b end, 0)

    local t = 0
    local line_times = list()
    for _, l in ipairs(lengths) do
        local t1 = t
        local t2 = t + cycle_time * l / total_length
        table.insert(line_times, dict{t1, t2})
        t = t2
    end

    return {
        segments = lines:zip(line_times):map(function(l)
            local line, time = unpack(l)
            local p1, p2 = unpack(line)
            local t1, t2 = unpack(time)
            return {type="line", p1=p1, p2=p2, t1=t1, t2=t2}
        end),
        cycle_time = cycle_time
    }
end

function component.patrol_state(time)
    return {time = time or 0}
end

function component.die_on_effect() return true end

function component.die_on_impact() return true end

function component.faction(n)
    if n == nil then return "neutral" end
    return n
end

function component.health(hp)
    return hp or 0
end

function component.damage(dmg) return dmg or 0 end

function component.element(element) return element end

function component.proximity(margin, filter)
    return {margin=margin or 0, filter=filter}
end

function component.reagent(type) return type end

function component.reagent_inventory(l)
    return l or list("mushroom", "sulfur", "flower")
end

function component.paused(v)
    return v
end

return component
