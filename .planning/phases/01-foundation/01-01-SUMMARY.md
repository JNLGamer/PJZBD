---
phase: 01-foundation
plan: 01
subsystem: foundation
tags: [mod-skeleton, namespace, mod-info, b42, scaffolding]
requires: []
provides:
  - "SanityTraits global namespace table"
  - "SanityTraits.VERSION, SANITY_MAX, SANITY_MIN, ZOMBIE_WEIGHT, SURVIVOR_WEIGHT, LOG_TAG constants"
  - "Loadable B42 mod entry (Mods/Sanity_traits/)"
affects:
  - "Mods/Sanity_traits/"
tech-stack:
  added:
    - "PZ B42 mod.info format"
    - "Lua client-side namespace pattern"
  patterns:
    - "Idempotent namespace guard: SanityTraits = SanityTraits or {}"
    - "Numeric filename prefix for load order (1_, 2_, 3_)"
    - "Singleplayer scripts go in client/ (not shared/)"
key-files:
  created:
    - "Mods/Sanity_traits/mod.info"
    - "Mods/Sanity_traits/media/lua/client/1_SanityTraits_Init.lua"
  modified: []
decisions:
  - "Use pzversion=42.0 (NOT 41.78 from example template) per RESEARCH.md Pitfall 4 — Build 964 is B42"
  - "id=Sanity_traits matches folder name exactly (case-sensitive); avoids Linux mod-loader mismatch"
  - "ZOMBIE_WEIGHT=10, SURVIVOR_WEIGHT=30 hardcoded as defaults (Phase 6 will replace with SandboxVars)"
  - "Place script in client/ not shared/ — singleplayer-only mod per CLAUDE.md and RESEARCH.md anti-pattern guidance"
  - "Numeric prefix '1_' enforces alphabetical load order before 2_ and 3_ files in plans 01-02 and 01-03"
metrics:
  duration: "~1 minute"
  completed: 2026-04-27
  tasks: 2
  files: 2
---

# Phase 1 Plan 01: Loadable Mod Skeleton Summary

Established the loadable B42 mod skeleton — `Mods/Sanity_traits/` directory, valid `mod.info`, and the `SanityTraits` namespace bootstrap file with all constants downstream plans (01-02 and 01-03) need to consume.

## What Was Built

### Mod Folder Structure

Created the standard PZ B42 mod layout:

```
Mods/Sanity_traits/
├── mod.info
└── media/
    └── lua/
        └── client/
            └── 1_SanityTraits_Init.lua
```

### `Mods/Sanity_traits/mod.info`

Five-field B42-compliant mod metadata:

```
name=Sanity Traits
id=Sanity_traits
description=Psychological deterioration system. Characters spiral through mental health stages driven by kill events, time, and mood.
modversion=1.0
pzversion=42.0
```

- `id=Sanity_traits` matches the folder name exactly (case-sensitive — required for Linux mod-loader compatibility).
- `pzversion=42.0` overrides the stale `41.78` from the example template per RESEARCH.md Pitfall 4 (Build 964 is B42).
- No `poster=` field — no thumbnail asset exists yet; will be added in a later phase if needed.

### `Mods/Sanity_traits/media/lua/client/1_SanityTraits_Init.lua`

Defines the global namespace and shared constants. The numeric `1_` prefix ensures it loads alphabetically before `2_*` and `3_*` files added in subsequent plans.

Constants exposed (load-bearing — referenced by plans 01-02 and 01-03):

| Name                          | Value     | Purpose                                                              |
| ----------------------------- | --------- | -------------------------------------------------------------------- |
| `SanityTraits.VERSION`        | `"1.0"`   | Mod version string for log output                                    |
| `SanityTraits.SANITY_MAX`     | `1000`    | Sanity meter ceiling (CORE-01 default for healthy civilian)          |
| `SanityTraits.SANITY_MIN`     | `0`       | Floor used for clamping after kill decrements (RESEARCH Pitfall 5)   |
| `SanityTraits.ZOMBIE_WEIGHT`  | `10`      | Sanity lost per zombie kill (CORE-03 default)                        |
| `SanityTraits.SURVIVOR_WEIGHT`| `30`      | Sanity lost per survivor kill — exactly 3x ZOMBIE_WEIGHT per CORE-04 |
| `SanityTraits.LOG_TAG`        | `"[SanityTraits]"` | Console log prefix used by every print() in the mod          |

The file emits `[SanityTraits] Init loaded (v1.0)` on load so manual UAT can confirm the bootstrap fired.

## Tasks Completed

| Task | Name                                                        | Commit    | Files                                                       |
| ---- | ----------------------------------------------------------- | --------- | ----------------------------------------------------------- |
| 1    | Create mod.info with B42-valid metadata                     | b116045   | Mods/Sanity_traits/mod.info                                 |
| 2    | Create SanityTraits namespace and constants                 | 5b9a647   | Mods/Sanity_traits/media/lua/client/1_SanityTraits_Init.lua |

## Verification

All automated `<verify>` blocks from the plan returned `OK`:

- `mod.info` exists with the five required B42 fields, no `pzversion=41.78`, no `poster=`.
- `1_SanityTraits_Init.lua` exists with `SanityTraits = SanityTraits or {}`, all five constants, `LOG_TAG`, and zero `Events.*.Add(` calls.
- File path uses `client/` (singleplayer-only scope).

Manual launch verification (PZ → Mods screen → "Sanity Traits" appears → console shows `[SanityTraits] Init loaded (v1.0)`) is deferred to phase-end UAT per the plan's verification step 5.

## Requirements Satisfied

- **DEF-04** — `mod.info` present with valid `name`, `id`, `description`, `modversion`, `pzversion`.

## Interface Contract for Downstream Plans

Plans 01-02 (ModData) and 01-03 (Kill Events) can now reference these symbols without redefining them:

```lua
SanityTraits.VERSION         -- "1.0"
SanityTraits.SANITY_MAX      -- 1000
SanityTraits.SANITY_MIN      -- 0
SanityTraits.ZOMBIE_WEIGHT   -- 10
SanityTraits.SURVIVOR_WEIGHT -- 30
SanityTraits.LOG_TAG         -- "[SanityTraits]"
```

Subsequent client lua files MUST use the numeric prefix convention (`2_*.lua`, `3_*.lua`) and reside in `media/lua/client/` to load after this bootstrap.

## Deviations from Plan

None — plan executed exactly as written. No auto-fixed bugs, no missing functionality, no blocking issues.

## Authentication Gates

None encountered.

## Known Stubs

None. The two files are complete for their declared scope:
- `mod.info` is final (a `poster=` field can be added later but is not required).
- `1_SanityTraits_Init.lua` intentionally contains only constants and a load print — no functions or event handlers, by plan design (those belong to plans 01-02 and 01-03).

## Self-Check: PASSED

- `Mods/Sanity_traits/mod.info` — FOUND
- `Mods/Sanity_traits/media/lua/client/1_SanityTraits_Init.lua` — FOUND
- Commit `b116045` — FOUND in git log
- Commit `5b9a647` — FOUND in git log
