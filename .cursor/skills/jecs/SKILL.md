---
name: jecs
description: >-
  ukendio jecs ECS API (World, entity, component, query, pairs) as used via
  Mega/Tree MetaData in AnimeDomains. Use when adding components, systems,
  units/towers, or querying entities.
---

# jecs (ukendio @ 0.11.0)

**Require:** `ReplicatedStorage.Packages.jecs`  
**Project world:** `Shareds.Classes.Mega` → `World` / `Jecs`

## Core

```luau
local world = jecs.World.new(true) -- or jecs.world()
local Position = world:component() :: jecs.Id<Vector3>
local e = world:entity()
world:set(e, Position, Vector3.zero)
local v = world:get(e, Position)
world:has(e, Position)
world:remove(e, Position)
world:delete(e)

for id, pos in world:query(Position) do
end
```

## Relationships

`jecs.pair(rel, target)` · `ChildOf` · `Wildcard` · `:parent` / `:children` / `:target`

## Project rules

- No entity spawn in `require` — export `{ Config, create }` / MetaData factories
- Units: `Classes/Tree` MetaData + `Datas/Units/*.luau`
- Debugger: skill `jabby`

## Docs

https://ukendio-jecs.mintlify.app/ · https://github.com/Ukendio/jecs
