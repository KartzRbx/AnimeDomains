---
name: stickybillboard
description: >-
  kartzrbx StickyBillboard keeps BillboardGui on-screen (new, BindToUpdate,
  OffScreenSize). Use for world labels that clamp to screen edges.
---

# StickyBillboard (kartzrbx @ 1.2.0)

**Require:** `ReplicatedStorage.Packages.stickybillboard` (client)

```luau
local StickyBillboard = require(ReplicatedStorage.Packages.stickybillboard)
local sticky = StickyBillboard.new(billboardGui, adornee, {
	MaxDistance = 100,
	OffScreenSize = UDim2.fromOffset(40, 40), -- required if scale-sized
})
sticky:BindToUpdate(function() end)
print(sticky.OnScreen, sticky:WorldPosition())
sticky:Destroy()
```

`adornee`: `Vector3 | BasePart | Model`. Clamps off-screen to edges.
