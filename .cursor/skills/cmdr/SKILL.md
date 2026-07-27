---
name: cmdr
description: >-
  Evaera/lipetos Cmdr command console (RegisterCommands, BeforeRun hooks,
  command modules). Use when adding admin/debug commands or wiring
  Boot/Cmdr + Handlers/Cmdr.
---

# Cmdr (lipetos @ 1.12.2 / Evaera)

**Require (server only):** `ReplicatedStorage.Packages.cmdr`  
**Boot:** `src/Boot/Cmdr/Cmdr.server.luau`  
**Commands:** `src/Handlers/Cmdr/Commands/`

```luau
Cmdr:RegisterDefaultCommands() -- optional / filtered
Cmdr:RegisterCommandsIn(commandsFolder)
Cmdr.Registry:RegisterHook("BeforeRun", function(context)
	-- return string to block
end)
```

Client UI loads via `CmdrClient` after server registers remotes.

## Command shape

Definition ModuleScript + optional `Server` implementation module. See https://eryn.io/Cmdr/guide/Commands.html

## Docs

https://eryn.io/Cmdr/ · https://github.com/evaera/Cmdr
