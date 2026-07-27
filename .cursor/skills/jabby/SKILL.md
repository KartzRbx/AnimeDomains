---
name: jabby
description: >-
  alicesaidhi Jabby jecs debugger UI (register world applet, obtain_client). Use
  for ECS debugging/dev tools only — gate with set_check_function.
---

# Jabby (alicesaidhi @ 0.6.1)

**Require:** `ReplicatedStorage.Packages.jabby`  
jecs world/scheduler debugger (dev).

```luau
local jabby = require(ReplicatedStorage.Packages.jabby)
jabby.set_check_function(function(player)
	return true -- gate access
end)
jabby.register({
	name = "World",
	applet = jabby.applets.world,
	configuration = { world = World },
})
-- client
local client = jabby.obtain_client()
```

Early/experimental — do not ship ungated to production players.

## Docs

https://alicesaidhi.github.io/jabby/
