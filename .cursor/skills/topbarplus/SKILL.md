---
name: topbarplus
description: >-
  1ForeverHD TopbarPlus v3 Icon API (new, setImage, setLabel, bindEvent, menus).
  Use when building client topbar UI icons, dropdowns, or captions.
---

# TopbarPlus (1foreverhd @ 3.4.0)

**Require (client):** `ReplicatedStorage.Packages.topbarplus`

```luau
local Icon = require(ReplicatedStorage.Packages.topbarplus)

Icon.new()
	:setName("Shop")
	:setImage(4882429582)
	:setLabel("Shop")
	:setCaption("Open shop")
	:align("Left") -- Left|Center|Right
	:bindEvent("selected", function(icon) end)
	:bindEvent("deselected", function(icon) end)
	:oneClick()
```

States for toggleable setters: `"Selected"` / `"Deselected"` / `"Viewing"` / hovering variants.

Also: `:setDropdown({...})`, `:setMenu({...})`, `:notify()`, `:destroy()`.

## Docs

https://1foreverhd.github.io/TopbarPlus/ · API: https://1foreverhd.github.io/TopbarPlus/api/
