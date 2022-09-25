local assemble = {}

function assemble.player(entity, x, y, bump_world)
    entity
        :assemble(
            collision().assemble.init_entity,
            x, y, nw.component.hitbox(20, 40), bump_world
        )
        :set(nw.component.drawable, drawable.animation)
        :set(nw.component.gravity)
        :set(nw.component.health, 3)
        :set(nw.component.proximity, 10)
        --:set(nw.component.color, 0.2, 0.8, 0.5)
end

function assemble.tile(entity, x, y, w, h, properties, bump_world)
    entity
        :assemble(
            collision().assemble.init_entity, x, y, spatial(0, 0, w, h),
            bump_world
        )
end

function assemble.alchemy_projectile(entity, x, y, velocity, element, bump_world)
    entity
        :assemble(
            collision().assemble.init_entity,
            x, y, nw.component.hitbox(6, 6), bump_world
        )
        :set(nw.component.drawable, drawable.body)
        :set(nw.component.gravity)
        :set(nw.component.velocity, velocity.x, velocity.y)
        :set(nw.component.die_on_impact)
        :set(nw.component.ghost)
        :set(nw.component.element, "foobar")
end

function assemble.alchemy_cloud(entity, x, y, element, bump_world)
    entity
        :assemble(
            collision().assemble.init_entity,
            x, y, nw.component.hitbox(40, 40), bump_world
        )
        :set(nw.component.drawable, drawable.body)
        :set(nw.component.lifetime, 10.0)
        :set(nw.component.color, 1, 0, 1)
        :set(nw.component.ghost)
end

return assemble
