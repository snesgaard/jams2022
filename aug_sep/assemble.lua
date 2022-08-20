local assemble = {}

function assemble.player(entity, x, y, bump_world)
    entity
        :assemble(
            collision().assemble.init_entity,
            x, y, nw.component.hitbox(20, 40), bump_world
        )
        :set(nw.component.drawable, drawable.body)
end

return assemble
