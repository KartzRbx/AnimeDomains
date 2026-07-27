---
name: display
description: >-
  nightcycle Display JSON-ish pretty printer for debug logging. Use when dumping
  nested tables/values to Output during development.
---

# Display (nightcycle @ 0.2.8)

**Require:** `ReplicatedStorage.Packages.display`

Debug pretty-printer (not UI). Builder under `Display.JSON`:

```luau
local Display = require(ReplicatedStorage.Packages.display)
local d = Display.JSON.new()
	:setIndentWith("  ")
	:setSortKeys(true)
	:build()
d:display(someTable)
```

Depends on bundled `option` package.
