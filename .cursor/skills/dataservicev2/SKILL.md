---
name: dataservicev2
description: >-
  kartzrbx DataServiceV2 player data API (WaitFor, Get/Set, Paths,
  GetChangedSignal) via AnimeDomains Workers facade. Use when reading/writing
  saves, extending PlayerData, or wiring client data listeners.
---

# DataServiceV2 (kartzrbx @ 2.3.3)

**Prefer:** `ReplicatedStorage.Shareds.Workers.DataServiceV2`  
Raw package: `Packages.dataservicev2`

```luau
const DataServiceV2 = require(...Workers.DataServiceV2)
const Paths = DataServiceV2.Paths

-- server
const data = DataServiceV2.Server:WaitFor(player)
local deck = data:Get(Paths.Game.Deck)
data:Set(Paths.Game.Trophies, 10)

-- client
const clientData = DataServiceV2.Client:WaitForData()
clientData:GetChangedSignal(Paths.Game.Deck):Connect(function(new, old) end)
```

## Rules

- Mutations **server-only**; client is read + signals
- Template: `Constants/Datas/PlayerData.luau`
- Janitor + GetChangedSignal: **do not** pass `"Disconnect"`

## API surface

`Get` / `Set` / `Update*` / array helpers / `GetChangedSignal` / `GetIndexChangedSignal` / transient APIs

## Docs

Package README under `Packages/_Index/kartzrbx_dataservicev2@2.3.3/`
