---
name: debi-networker
description: >-
  AnimeDomains typed Networker (Debi IDL → generated Client/Server). Use when
  adding remotes, editing .debi files, wiring Fire/SetCallback/On, or debugging
  Game/Secondary/Validations channels.
---

# Debi Networker

Gameplay remotes are **typed Debi channels**, not ad-hoc RemoteEvents.

## Files

- IDL: `src/Networker/<Channel>/*.debi` (`game.debi`, `secondary.debi`, `validations.debi`)
- Generated: sibling `Client.luau` / `Server.luau` — **do not hand-edit**
- Entry: `NetClient` / `NetServer` → `.Game` / `.Secondary` / `.Validations`

```luau
-- client
const Debi = require(ReplicatedStorage.Shareds.Networker.NetClient).Game
Debi.PutCardInPlace.Fire(payload)
Debi.SyncCardHand.SetCallback(function(state) end)

-- server
const Debi = require(ReplicatedStorage.Shareds.Networker.NetServer).Game
Debi.PutCardInPlace.SetCallback(function(player, payload) end)
Debi.SyncCardHand.Fire(player, state)
```

## Event shape (.debi)

```text
event Name = {
  from: Client | Server,
  type: Reliable | Unreliable,
  call: SingleAsync | ManyAsync,
  data: (...),
}
```

| call | Client listen | Server listen |
|---|---|---|
| SingleAsync | `SetCallback` | `SetCallback` |
| ManyAsync | `On` | (server→client multi) |

Server→client helpers: `Fire` / `FireAll` / `FireExcept`.

## Workflow

1. Edit `.debi`
2. Regenerate: `node tools/debi/cli.js --all` (or project script)
3. Use generated API in Services

## Pitfalls

- Persistence ≠ Debi — use DataServiceV2 for saves
- Packets flush on Heartbeat
- Wrong peer assert if you require Client on server (or vice versa)

## Related

- `anime-domains-organization`
- Docs: project Networker tools under `tools/debi/`
