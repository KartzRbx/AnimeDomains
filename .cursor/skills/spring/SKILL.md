---
name: spring
description: >-
  nightcycle Spring scalar damper (new, Set, Get, Step). Use for smooth number
  interpolation (UI bars, camera folt, values) stepped each frame.
---

# Spring (nightcycle @ 1.0.0)

**Require:** `ReplicatedStorage.Packages.spring`

```luau
local Spring = require(ReplicatedStorage.Packages.spring)
local s = Spring.new(dampingRatio, frequency, initialPosition)
s:Set(goal)
-- Heartbeat:
local x = s:Step(dt) -- or s:Get() after Step
```

Fields: `.Damping`, `.Frequency`, `.Goal`, `.Position`, `.Velocity`.

Scalar only — for Vector3 spring multiple instances or custom.
