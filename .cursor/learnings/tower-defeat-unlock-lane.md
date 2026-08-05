# Tower defeat unlocks attacker lane

**Tags:** tower, zone, unlock, death

## Behavior

When a spawned Left/Right tower dies:

1. Entity model despawns (`DespawnEntity`)
2. Anchor + entity get `Destroyed = true`
3. Attacker team gains that lane via `PlacementZoneUtils.UnlockEnemyLane`

Main tower does not unlock a lane.

## Rule

Never leave a tower anchor targetable after its spawned entity dies — `IsTowerAlive` must return false when spawned is missing or `Destroyed` is set. Reset `Destroyed` in `ResetUnlocks` on new match.
