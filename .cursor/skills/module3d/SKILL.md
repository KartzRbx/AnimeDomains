---
name: module3d
description: >-
  kumarion Module3D ViewportFrame helper (new, Attach3D, SetCFrame, Update). Use
  for 3D model previews inside Gui (card previews, shop viewers).
---

# Module3D (kumarion @ 0.0.2)

**Require:** `ReplicatedStorage.Packages.module3d`

```luau
local Module3D = require(ReplicatedStorage.Packages.module3d)
local view = Module3D.new(modelOrPart)
-- or Module3D:Attach3D(guiFrame, modelOrPart)
view:SetCFrame(cf)
view:SetDepthMultiplier(1)
view:Update()
view:Destroy() -- prefer over deprecated :End
```

Extends ViewportFrame via metamethods (`.Parent`, `.Visible`, …). Moves object far away for isolation — expect that side effect.
