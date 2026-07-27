---
name: janitor
description: >-
  1ForeverHD Janitor cleanup API as used in AnimeDomains (:add, :Remove,
  :destroy, indexed cleanup). Use when managing connections, tweens, threads,
  or fixing janitor remove/disconnect bugs.
---

# Janitor (1foreverhd @ 1.18.15)

**Require:** `ReplicatedStorage.Packages.janitor`

## API (this build)

```luau
const Janitor = require(ReplicatedStorage.Packages.janitor)
const j = Janitor.new()

j:add(conn)                          -- RBXScriptConnection → Disconnect
j:add(instance, "Destroy")
j:add(tween, "Cancel")
j:add(fn, true)                      -- call function / cancel thread
j:add(obj, methodName, index)        -- indexed

j:Remove(index)                      -- clean + unregister (PascalCase!)
j:removeNoClean(index)               -- unregister only
j:cleanup()
j:destroy()                          -- cleanup + invalidate
j:linkToInstance(instance)
```

## Project pitfall — `:remove` vs `:Remove`

In this package version, `Janitor.remove` was assigned **before** `Remove` existed → **`:remove` is nil**. Use **`:Remove`**. Prefer lowercase `:add` / `:destroy` which work.

## DataService signals

```luau
-- WRONG
j:add(data:GetChangedSignal(path):Connect(fn), "Disconnect")
-- RIGHT (Connection is a table with Destroy)
j:add(data:GetChangedSignal(path):Connect(fn))
```

## Related

- Docs: https://github.com/howmanysmall/Janitor · RoStrap Janitor
- `AGENT.md` Janitor section
- Deeper notes: [reference.md](reference.md)
