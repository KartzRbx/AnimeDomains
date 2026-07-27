---
name: author-hand-programming
description: >-
  Captures how the AnimeDomains owner programs by hand (voice, const, WIP stubs,
  section markers). Use whenever editing their Luau modules, completing stubs,
  or fixing small bugs in files they authored. Prefer matching their style over
  agent reorganization.
---

# Author hand programming

The owner codes **à mão**. Their file voice is intentional even when imperfectly organized.

## Core rules

1. Change **only** what they asked.
2. Match the open file: `const`/`local`, names, markers, stubs, spacing.
3. Never rewrite/reorganize for agent taste.
4. Never swap `const` ↔ `local` (or helper declaration style) unprompted.
5. Leave WIP alone unless the task is to finish that piece.

## What their code often looks like

- Heavy `const` for services, requires, tags, animations
- `const function` helpers when they write new ones
- Section banners (`-- << BIND >>`, `SERVER_CALLS`, etc.)
- Incomplete stubs mid-session (`function Foo()` empty / WIP)
- Practical naming over perfect taxonomy (`FalingTrack`, `GetClockModel`)
- Janitor with tagged indexes when they need remove later

## When adding code in their file

- Mirror nearby patterns first (their style beats a generic AGENT example).
- Keep framework rules that matter: `--!strict`, no side effects in `require`, server truth for data — without restyling the module.

## Related

- Always-on rule: `.cursor/rules/respect-author-hand-style.mdc`
- Skill: `respect-author-hand-style`
- Full policy: `AGENT.md` → **Author style — hand-written code**
