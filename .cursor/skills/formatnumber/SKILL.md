---
name: formatnumber
description: >-
  kumarion FormatNumber / project NumberFormater for UI number display. Use when
  formatting coins, damage, energy, or compact counts.
---

# FormatNumber (kumarion @ 0.0.1)

**Prefer project facade:** `ReplicatedStorage.Shareds.Utils.NumberFormater`  
Raw: `Packages.formatnumber` → `{ Main, Simple, ... }`

```luau
-- Simple
FormatNumber.Simple.Format(value, skeleton?)

-- Main (immutable builder)
NumberFormatter.with():Notation(...):Precision(...):Format(n)
```

Do not reimplement formatting inline — use existing Utils/Modules.
