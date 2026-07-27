---
name: vfx-util
description: >-
  lucaschaibub vfx-util emitter helpers (emit, emitAll, toggleAllEmitters,
  copyEmittersTo). Use for ParticleEmitter/Beam bursts and VFX container control.
---

# vfx-util (lucaschaibub @ 1.0.0)

**Require:** `ReplicatedStorage.Packages["vfx-util"]`

```luau
local VfxUtil = require(ReplicatedStorage.Packages["vfx-util"])
VfxUtil.emit(emitter, count?)
VfxUtil.emitAll(container, descendants?)
VfxUtil.toggleAllEmitters(container, enable, includeBeams?, descendants?)
local copies = VfxUtil.copyEmittersTo(container, target, copyAttachments?, copyBeams?)
VfxUtil.destroyVFX(instances)
```

Uses attributes `EmitCount` / `EmitDelay` when present. Beams need valid BasePart targets when copying attachments.

Also see project `Shareds.Utils.VFXUtil` if wrapping this package.
