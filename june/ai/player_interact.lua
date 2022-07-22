local player_interact = class()

local function get_objects_in_range(ctx, entity)
    local w, h = 50, 50
    local candidates = collision.check(entity, w, h)
    return candidates:map(function(id) return entity:world():entity(id) end)
end

local function sort_by_distance(a, b, target)
    local pos_target = target:ensure(nw.component.position)
    local pos_a = a:ensure(nw.component.position)
    local pos_b = b:ensure(nw.component.position)

    return (pos_a - pos_target):length() < (pos_b - pos_target):length()
end

local function find_interactables(ecs_world, entity, is_interactable)
    return get_objects_in_range(ctx, entity)
        :filter(is_interactable)
        :sort(function(a, b) return sort_by_distance(a, b, entity) end)
end

local function always_false() return false end

local api = class()

function api.listen(ctx, entity, is_interactable)
    local is_interactable = is_interactable or always_false

    local interact_input = ctx:listen("keypressed")
        :filter(function(key) return key == "x" end)

    local interactables = ctx:listen("moved")
        :filter(function(id) return id == entity.id end)
        :map(function(id)
            return find_interactables(
                ctx:ecs_world(), ctx:ecs_world():entity(id), is_interactable
            )
        end)
        :latest{list()}

    local object_to_interact_with = interact_input
        :map(function() return interactables:peek():head() end)
        :filter()
        :latest()

    return setmetatable(
        {
            interact_input = interact_input,
            interactables = interactables,
            object_to_interact_with = object_to_interact_with,
            ctx = ctx
        },
        api
    )
end

function api:set_interact_highlight()
    self.ctx:ecs_world():set(
        component.target,
        constants.id.interaction,
        self.interactables
            :peek()
            :map(function(e) return e.id end)
            :head()
    )
end

function api:is_empty()
    return self.object_to_interact_with:peek() == nil
end

function api:peek()
    return self.object_to_interact_with:peek()
end

return api
