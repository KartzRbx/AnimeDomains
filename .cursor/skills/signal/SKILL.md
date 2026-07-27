---
name: signal
description: >-
  Sleitnick Signal Luau API (new, Fire, Connect, Once, Wait, Destroy). Use when
  adding custom events, cutscene Completed callbacks, or Janitor+Signal wiring.
---

# Signal (sleitnick @ 2.0.3)

**Require:** `ReplicatedStorage.Packages.signal`

```luau
const Signal = require(ReplicatedStorage.Packages.signal)
const s = Signal.new()

const conn = s:Connect(function(...) end)
s:Once(function(...) end)
s:Fire(...)
s:FireDeferred(...)
local a, b = s:Wait()
s:DisconnectAll()
s:Destroy()
conn:Disconnect()
```

Also: `Signal.Wrap(rbxScriptSignal)`, `Signal.Is(obj)`.

## Project use

- Cutscene / cards: `Completed = Signal.new()` then `:Fire()` / `:Connect`
- Janitor: `j:add(signalConn)` — **omit** `"Disconnect"` (use Destroy path)

## Docs

https://sleitnick.github.io/RbxUtil/api/Signal/
