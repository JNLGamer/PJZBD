---
status: partial
phase: 01-foundation
source: [01-VERIFICATION.md]
started: 2026-04-28T00:00:00Z
updated: 2026-04-28T00:00:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Mod loads cleanly in PZ B42
expected: Launch PZ → Main Menu → Mods. "Sanity Traits" appears with no incompatibility warning. Enable, start any new game; console shows `[SanityTraits] Init loaded (v1.0)` and zero red Lua errors mention SanityTraits.
result: [pending]

### 2. OnCreatePlayer ModData init for two professions (CORE-01, CORE-02)
expected: New Unemployed character — `print(getPlayer():getModData().SanityTraits.sanity)` returns `1000`, `.appliedStage` returns `Healthy`, `.profession` returns `base:unemployed`. Console shows `[SanityTraits] OnCreatePlayer: profession=base:unemployed startingSanity=1000`. New Veteran character — same prints return `200`, `Healthy`, `base:veteran`.
result: [pending]

### 3. Zombie kill drives the meter (CORE-03)
expected: With Unemployed character in-world, kill one zombie. Console prints `[SanityTraits] Zombie killed. Sanity: 1000 -> 990`. `print(getPlayer():getModData().SanityTraits.sanity)` returns `990`. After ~110 zombie kills the value clamps at `0` and never goes negative.
result: [pending]

### 4. Survivor kill drives the meter and persists across save/reload (CORE-04, CORE-01 persistence)
expected: Debug-spawn a non-zombie NPC, kill with a fatal weapon hit. Console prints `[SanityTraits] Survivor killed. Sanity: <before> -> <before-30>`. Save → quit to main menu → reload save. `print(getPlayer():getModData().SanityTraits.sanity)` still equals the post-kill value. No Lua errors during save or load.
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
