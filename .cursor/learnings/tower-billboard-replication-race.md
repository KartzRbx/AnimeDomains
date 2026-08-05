# Tower billboard lost to replication race

**Tags:** tower, billboard, client, replication

## Symptom

Some towers (typically the side ones) spawn without `TowerBillboard`, while others get it normally. Non-deterministic between matches.

## Root cause

`ResolveTowerEntitys` was a **one-shot pass** fired by the server right after `SpawnMatchTowers`. On the client:

- `updateTowerBillboard` returned early when `HumanoidRootPart` / `Humanoid` were not present yet
- The Model replicates before all of its descendants, so towers still streaming in were silently skipped and never retried
- The pass was also gated on `GameplayServiceClient.EntityState`, which arrives on a separate deferred path (`SendMatchState` waits for `CharacterAdded`)

## Fix

- `bindTowerVisuals` waits for the rig (`WaitForChild` with timeout) inside `task.spawn` before touching the board
- `ResolveTowerEntitys` iterates `TEAM_KEYS` directly instead of depending on `EntityState`
- Each team `Units` folder gets a `ChildAdded` watch (janitor key `{teamKey}_TowerWatch`) so late towers still bind

## Rule

Client visuals bound to server-spawned rigs must wait for the rig and watch `ChildAdded` — never bail out silently on a single pass.
