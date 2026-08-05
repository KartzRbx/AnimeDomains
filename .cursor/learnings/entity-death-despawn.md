# Entity death — despawn model and billboard

**Tags:** combat, death, billboard, despawn

## Expected behavior

When a unit or spawned tower dies (`Humanoid.Died`), remove the character from the world and clean up its billboard/listeners.

## Implementation

- Server: `CardsEntityManager.DespawnEntity(uid, model)` — stops path/attack janitors, clears cache, destroys model
- Bind `Humanoid.Died` in `BuildEntityPath` (units) and `BuildTowerAttack` (towers)
- Set `BreakJointsOnDeath = false` on spawn to avoid ragdoll before destroy
- Client: `_RemoveUnitBillboard` on `Died` / `Destroying` clears janitor keys and billboard instance

## Rule

Do not leave dead entities in `_Entitys` or `Units` — always route death through `DespawnEntity`.
