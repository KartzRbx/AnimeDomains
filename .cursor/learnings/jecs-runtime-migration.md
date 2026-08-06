# jecs runtime migration (server-authoritative)

**Tags:** jecs, combat, ecs, targeting, movement, health

## What changed

Match units/towers are no longer driven by per-entity Heartbeats in `CardsEntityManager`. Runtime state lives in `Mega.World`:

- Templates: `TemplateTag` via `UnitsMetaData` / `TowerMetaData.EnsureLoaded`
- Instances: `SpawnFromId` + `EntityRegistry` (UID ↔ entity ↔ Model)
- Systems (server Heartbeat): Position → Targeting → Movement → Attack → Health
- View mirror: `AttributeMirror` syncs Ready / AttackEnabled / Attacking / Health → Model attributes + Humanoid

## Authority

- Server World is authoritative for Health, Target, LastAttack, Ready, AttackEnabled
- Client stays presentation-only (Model replication, Debi attack replica, billboards)
- Damage: `CombateStateHandler.ApplyDamageToTarget` subtracts ECS `Health`, then mirrors to Humanoid

## Key paths

- `src/Classes/Tree/Runtime/EntityRegistry.luau`
- `src/Classes/Tree/Systems/Schedule.luau` (started from `Boot/Game/Server.server.luau`)
- `BuildEntityPath` / `BuildTowerAttack` are thin adapters (register controllers / Died hooks)
