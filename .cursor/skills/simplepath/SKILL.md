---
name: simplepath
description: >-
  SimplePath pathfinding wrapper (Path.new, Run, Reached, Error). Use when
  moving humanoid/non-humanoid agents along PathfindingService routes.
---

# SimplePath (tabby0x @ 2.2.6)

**Require:** `ReplicatedStorage.Packages.simplepath`

```luau
local Path = require(ReplicatedStorage.Packages.simplepath)
local path = Path.new(agentModel) -- needs PrimaryPart
path.Visualize = true

path.Reached:Connect(function(agent, finalWaypoint) end)
path.Error:Connect(function(errorType) end)
path.Blocked:Connect(function() end)

local ok = path:Run(goalVector3OrPart)
path:Stop()
path:Destroy()
```

Prefer **repetitive** `:Run` while chasing moving targets (module design).

## Docs

https://grayzcale.github.io/simplepath/ · API: https://grayzcale.github.io/simplepath/api-reference/
