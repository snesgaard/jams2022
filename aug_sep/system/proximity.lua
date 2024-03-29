local function filter_others_on_id(id, self_id, filter, ecs_world)
    if id == self_id then return false end
    if filter then return filter(ecs_world, id) end
    return true
end

local function compute_distance(id, entity)
    local other_pos = entity:world():get(nw.component.position, id) or vec2()
    local pos = entity:get(nw.component.position) or vec2()
    return (pos - other_pos):length()
end

local function handle_moved(entity)
    local bump_world = entity:get(nw.component.bump_world)
    local prox = entity:get(nw.component.proximity)

    if not bump_world or not prox then return end
    local x, y, w, h = bump_world:getRect(entity.id)
    local area = spatial(x, y, w, h):expand(prox.margin, prox.margin)
    local others = bump_world:queryRect(area.x, area.y, area.w, area.h)
    local filter = prox.filter

    local filter_others = List.filter(others,
        filter_others_on_id, entity.id, filter, entity:world()
    )
    prox.others = filter_others
end

local function sq_distance(id, entity)
    local other_pos = entity:world():get(nw.component.position, id) or vec2()
    local pos = entity:get(nw.component.position) or vec2()
    local dx = other_pos.x - pos.x
    local dy = other_pos.y - pos.y
    return dx * dx + dy * dy
end

local proximity = {}

function proximity.square_distance(ecs_world, a, b)
    local other_pos = ecs_world:get(nw.component.position, a) or vec2()
    local pos = ecs_world:get(nw.component.position, b) or vec2()
    local dx = other_pos.x - pos.x
    local dy = other_pos.y - pos.y
    return dx * dx + dy * dy
end

function proximity.draw(entity)
    local prox = entity:get(nw.component.proximity)
    local bump_world = entity:get(nw.component.bump_world)

    if not bump_world or not prox then return end
    local others = prox.others or list()

    gfx.push("all")
    gfx.setColor(1, 1, 1)
    for _, id in ipairs(others) do
        if bump_world:hasItem(id) then
            gfx.rectangle("line", bump_world:getRect(id))
        end
    end
    gfx.pop()
end

function proximity.system(ctx)
    local ecs_world = ctx:from_cache("level")
        :map(function(level) return level.ecs_world end)
        :latest()

    local moved = ctx:listen("moved")
        :filter(function(entity) return entity:get(nw.component.proximity) end)
        :collect(true)

    while ctx:is_alive() do
        for _, entity in ipairs(moved:pop()) do
            handle_moved(unpack(entity))
        end

        ctx:yield()
    end
end

return proximity
