# Janitor reference (AnimeDomains)

## MethodName defaults when omitted

| typeof | default |
|---|---|
| RBXScriptConnection | `"Disconnect"` |
| function / thread | `true` |
| else | `"Destroy"` |

## Nested janitors

If outer holds inner with `"destroy"`, remove the index when inner dies or the outer entry leaks.

## Player teardown

Destroy player-scoped janitors on `Players.PlayerRemoving`, not inside that character’s `AncestryChanged`.
