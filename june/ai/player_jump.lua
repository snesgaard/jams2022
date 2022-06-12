local jump_control = class()

local function input_filter(key) return key == "space" end

local function collision_filter(all_col_info, id, ecs_world)
    for _, col_info in ipairs(all_col_info) do
        local is_sold = collision.is_solid(col_info)
        local is_id = col_info.item == id
        local is_normal = col_info.normal.y < -0.9
        if is_sold and is_id and is_normal then return true end
    end
end

jump_control.BUFFER_TIME = 0.2

function jump_control.create(ctx, id)
    local on_ground_timer = nw.component.timer.create(jump_control.BUFFER_TIME, 0)
    local input_timer = nw.component.timer.create(jump_control.BUFFER_TIME, 0)

    local this = {
        timer = {
            on_ground = on_ground_timer,
            input = input_timer
        },
        input = ctx:listen("keypressed")
            :filter(function(key) return key == "space" end)
            :foreach(function()
                input_timer:reset()
            end),
        collision = ctx:listen("collision")
            :filter(function(all_col_info, ecs_world)
                return collision_filter(all_col_info, id, ecs_world)
            end)
            :foreach(function()
                on_ground_timer:reset()
            end),
        update = ctx:listen("update")
            :foreach(function(dt)
                on_ground_timer:update(dt)
                input_timer:update(dt)
            end)
    }

    return setmetatable(this, jump_control)
end

function jump_control:can_jump()
    return not self.timer.on_ground:done() and not self.timer.input:done()
end

function jump_control:clear()
    self.timer.on_ground:finish()
    self.timer.input:finish()
end

function jump_control:pop()
    local v = self:can_jump()
    if v then self:clear() end
    return v
end

return jump_control
