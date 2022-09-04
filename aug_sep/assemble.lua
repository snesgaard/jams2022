local assemble = {}

function assemble.player(entity, x, y, bump_world)
    entity
        :assemble(
            collision().assemble.init_entity,
            x, y, nw.component.hitbox(20, 40), bump_world
        )
        :set(nw.component.drawable, drawable.body)
        :set(nw.component.gravity)
        :set(nw.component.health, 3)
end

function assemble.tile(entity, x, y, w, h, properties, bump_world)
    entity
        :assemble(
            collision().assemble.init_entity, x, y, spatial(0, 0, w, h),
            bump_world
        )
end

return assemble
