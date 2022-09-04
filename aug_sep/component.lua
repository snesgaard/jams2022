local component = {}

function component.actor() return true end

function component.faction(f) return f end

function component.hitbox(x, y, w, h)
    if w == nil then
        return spatial(x / 2, -y, x, y)
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
    if not x then return vec2(0, 100) end

    return vec2(x, y)
end

return component
