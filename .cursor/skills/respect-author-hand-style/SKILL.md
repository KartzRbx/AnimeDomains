---
name: respect-author-hand-style
description: >-
  Respect the repository owner's hand-written coding style. Use when editing
  Luau/modules the user authored, fixing small bugs in their files, completing
  stubs they started, or whenever tempted to reorganize/rewrite for cleaner
  agent taste. Prefer matching their const/local, naming, and WIP shape.
---

# Respect author hand style

The owner programs **à mão** (by hand). Their way of writing is intentional even when it is not 100% organized by agent standards.

## When this applies

- Editing any file they clearly authored or are actively writing
- Small fixes, completions, or follow-ups inside their modules
- Any urge to restructure, rename, or "normalize" style without being asked

## Instructions

1. Read the surrounding file and **match its voice** (bindings, spacing, markers, stub shape).
2. Implement **only the requested change**.
3. Do **not** convert their `const` to `local` or the reverse unless they ask.
4. Do **not** rewrite helpers, collapse sections, or reorganize the module for taste.
5. Leave incomplete/WIP functions alone unless the task is to finish that specific piece.
6. New architecture still follows `AGENT.md` (Services, Networker, `--!strict`, no side effects in `require`) — but **style of existing hand code is not redesigned**.

## Examples

```text
User: fix the remove method on lines 47-53
✅ Patch those lines; keep their const bindings and structure
❌ Rewrite the whole cutscene module more "cleanly"
```

```text
User: complete ClockTimeEffect
✅ Fill that function in their style
❌ Also refactor SpawnEntityInPosition and rename locals
```

## Priority

Author hand style in the open file **wins** over the agent's preferred organization.
