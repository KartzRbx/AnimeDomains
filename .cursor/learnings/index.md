# Learnings index

| Slug | Tags | Summary |
|---|---|---|
| [tower-spawned-entity-combat-target](./tower-spawned-entity-combat-target.md) | combat, tower, damage, billboard | Combat must target spawned tower in Units, not Towers anchor |
| [entity-death-despawn](./entity-death-despawn.md) | combat, death, billboard, despawn | Humanoid.Died → DespawnEntity removes model + billboard cleanup |
| [tower-defeat-unlock-lane](./tower-defeat-unlock-lane.md) | tower, zone, unlock, death | Defeated Left/Right tower unlocks attacker lane + marks anchor Destroyed |
| [tower-billboard-replication-race](./tower-billboard-replication-race.md) | tower, billboard, client, replication | Wait for rig + watch ChildAdded; one-shot bind skipped towers |
| [attack-hitbox-overlap-query](./attack-hitbox-overlap-query.md) | combat, hitbox, damage, tower, ZonePlus | Relocated ZonePlus zone detects nothing; use GetPartsInPart + map anchor → spawned tower |
| [jecs-runtime-migration](./jecs-runtime-migration.md) | jecs, combat, ecs, health | Server World + systems own combat runtime; Models/Humanoids are the view |

API completa dos módulos Tree/jecs: [jecs-tree-runtime.md](../docs/jecs-tree-runtime.md)

