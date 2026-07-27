---
name: ezvisualz
description: >-
  arxkdev EzVisualz UI gradient/shine effects (Effect.new presets). Use for Gui
  polish (gradients, strokes, dropshadows) — not world VFX.
---

# EzVisualz (arxkdev @ 1.2.0)

**Require:** `ReplicatedStorage.Packages.ezvisualz`

```luau
local Effect = require(ReplicatedStorage.Packages.ezvisualz)
local fx = Effect.new(guiObject, presetName, speed?, size?)
fx:Pause()
fx:Resume()
fx:Destroy()
Effect.SetCustomFolders(presetsFolder?, templatesFolder?)
```

Submodules: `.Gradient`, `.Stroke`, `.Dropshadow`, `.Templates`.  
Preset name must exist under package Presets/Templates.
