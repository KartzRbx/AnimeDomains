# Tower combat must target spawned entity, not anchor

**Tags:** combat, tower, damage, billboard, EntityHelper

## Symptom

- Units attack too fast (every frame / ignoring `DelayAttack`)
- Tower billboard health never updates
- `CombateStateHandler:ApplyDamageToTarget` never runs successfully on towers

## Root cause

Match towers exist in two places:

1. **Anchor** — `Game/Gameplay/Teams/{Team}/Towers/LeftTower` (GripEntity, no Humanoid)
2. **Spawned entity** — `Game/Gameplay/Teams/{Team}/Units/{model}` (Humanoid, UID, `TowerSlot`)

Combat used anchor **name** (`LeftTower`) as `TargetUID`. `GetCombatTargetForId` returned the anchor, which has no Humanoid, so damage failed. Because `lastAttackAt` only advanced on successful damage (towers) or successful `Attack()` (units), failed attempts retried every Heartbeat.

## Fix

- `EntityHelper.GetSpawnedTowerForAnchor(anchor)` resolves anchor → spawned model via `TowerSlot`
- `GetCombatTargetForId` returns spawned tower when resolving anchor names
- `IsTowerAlive` checks spawned tower Humanoid
- `syncAttackTargetUid` stores spawned tower UID
- Advance attack cooldown when the attack **starts**, not only when damage applies

## Rule

When applying combat damage or UI bound to Humanoid health on towers, always resolve to the **spawned** model in `Units`, never the `Towers` anchor.
