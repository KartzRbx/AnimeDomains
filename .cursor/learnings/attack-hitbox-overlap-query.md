# Attack hitboxes must use overlap queries, not a relocated ZonePlus zone

**Tags:** combat, hitbox, damage, tower, AttackUtils, ZonePlus

## Symptom

- Sabre plays the attack animation but never deals damage (towers *and* units)
- `OnHit` fires with an empty `result.Targets`, so `hasLocked` is always false
- No `ApplyDamageToTarget` call, no billboard health change

## Root cause

Two independent bugs in `Utils/AttackUtils.luau`:

1. **`zone:relocate()` blinds the hitbox.** ZonePlus moves the zone parts into
   `ServerStorage.ZonePlusWorldModel` and sets `zone.worldModel` to that WorldModel.
   `zone:getParts()` then runs `GetPartBoundsInBox` **inside that WorldModel**, which only
   contains the hitbox itself (and it is in the ignore list) — so it always returns `{}`.
   ZonePlus is also throttled (`respectUpdateQueue`, 0.1s) and defaults to
   `Detection.Centre`, both wrong for a hitbox that moves every frame.
2. **Tower anchors never matched the locked target.** `getCombatModelFromPart` returned the
   anchor model (`Towers/LeftTower`), while `lockedTarget` is the *spawned* tower entity in
   `Units`. Even a working hitbox could not match, and the spawned dummy stands ~10 studs
   above ground on top of the anchor, out of reach of any ground melee hitbox.

## Fix

- Query the world directly: `Workspace:GetPartsInPart(hitPart, overlapParams)` with an
  Exclude filter on the hitbox and `RespectCanCollide = false`. Dropped ZonePlus from
  `AttackUtils` (and the `AttackHitBox.Zone` field).
- `getCombatModelFromPart` maps a tower **anchor** part through
  `EntityHelper.GetSpawnedTowerForAnchor(anchor)`, so hitting the building counts as
  hitting the spawned entity that carries the Humanoid.

## Notes

- Keep hitboxes in the `Default` collision group: it is collidable with `Default`,
  `Players`, `Entities` and `EntityBarriers`, so one query sees towers and units.
- Sabre stops ~7.5 studs from the anchor GripEntity (`unitRange` 5 + 2.5 buffer, clamped by
  the anchor clear radius) — the 5x4x5 hitbox overlaps the anchor part, never the dummy on
  top of it.

## Rule

Melee/swing hitboxes are moving volumes: resolve them with `GetPartsInPart` /
`GetPartBoundsInBox` against `Workspace`. ZonePlus is for static zones, and `relocate()`
makes part detection impossible.
