local wrap = {}

function wrap.clamp(time, t1, t2)
    return math.clamp(time, t1, t2)
end

function wrap.periodic(time, t1, t2)
    if t2 <= t1 then errorf("t2 must be larger (t1=%f, t2=%f)", t1, t2) end

    -- Sawtooth wave equation
    local t = time - t1
    local p = t2 - t1
    local t_div_p = t / p
    local s = t_div_p - math.floor(t_div_p)
    return t1  + s * p
end

function wrap.bounce(time, t1, t2)
    if t2 <= t1 then errorf("t2 must be larger (t1=%f, t2=%f)", t1, t2) end

    -- Triangle wave equation
    local t = time - t1
    local d = (t2 - t1)
    local p = d
    -- Triangle wave value in range of [0, 1]
    local s = 2 * math.abs((t / p - math.floor(t / p + 0.5)))
    return t1 + s * d
end

local function piecewise(x, condition, func)
    local size = math.min(#condition, #func)

    for s = 1, size do
        if condition[s] then
            local f = func[s]
            return f(x)
        end
    end

    return
end

local function lerp(x, x1, y1, x2, y2, ease_func)
    ease_func = ease_func or nw.ease.linear
    local t = x - x1
    local b = y1
    local c = y2 - y1
    local d = x2 - x1
    return ease_func(t, b, c, d)
end

local function condition_from_segments(segments, wrapped_time)
    local condition = {}

    for i, s in ipairs(segments) do
        local lower_bound = i == 1 and -math.huge or s.t1
        local upper_bound = i == #segments and math.huge or s.t2
        condition[i] = lower_bound <= wrapped_time and wrapped_time < upper_bound
    end

    return condition
end

local patrol = {}

function patrol.update(dt, entity)
    local path = entity:get(nw.component.patrol)
    if not path then return end
    local state = entity:ensure(nw.component.patrol_state)
    local next_time = state.time + dt
    state.time = next_time
    local wrapped_time = wrap.bounce(next_time, 0, path.cycle_time)
end

function patrol.next_position(entity)
    local state = entity:ensure(nw.component.patrol_state)
    local path = entity:get(nw.component.patrol)

    if not path then return end

    local wrapped_time = wrap.bounce(state.time, 0, path.cycle_time)
    local conditions = condition_from_segments(path.segments, wrapped_time)

    local func = path.segments:map(function(s)
        return function(t)
            return lerp(t, s.t1, s.p1, s.t2, s.p2)
        end
    end)

    return piecewise(wrapped_time, conditions, func)
end

function patrol.return_to_patrol()

end

return patrol
