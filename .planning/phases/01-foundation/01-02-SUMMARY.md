---
phase: 01-foundation
plan: 02
subsystem: persistence
tags: [moddata, oncreateplayer, profession, lua, b42, sanity-meter]
requires:
  - phase: 01-foundation
    provides: "SanityTraits namespace with SANITY_MAX, SANITY_MIN, LOG_TAG constants from 01-01"
provides:
  - "SanityTraits.STARTING_SANITY_BY_PROFESSION lookup table (7 Phase-1 archetypes)"
  - "SanityTraits.getStartingSanity(profName) function with nil-safe fallback"
  - "OnCreatePlayer handler that initializes player:getModData().SanityTraits"
  - "Per-character ModData contract: { sanity, appliedStage, profession }"
affects:
  - "01-03 (kill events) — reads/writes player:getModData().SanityTraits.sanity"
  - "phase 02 (decay loop) — mutates appliedStage on this same ModData object"
  - "phase 04 (psyche profiles) — extends STARTING_SANITY_BY_PROFESSION to all 24 vanilla professions"
tech-stack:
  added:
    - "Events.OnCreatePlayer hook (B42)"
    - "player:getDescriptor():getCharacterProfession():getName() (profession id resolution)"
  patterns:
    - "Idempotent ModData init: if md.SanityTraits ~= nil then return"
    - "Defensive descriptor guard: if desc and desc:getCharacterProfession() then ..."
    - "Lookup-or-default: STARTING_SANITY_BY_PROFESSION[profName] or SanityTraits.SANITY_MAX"
key-files:
  created:
    - "Mods/Sanity_traits/media/lua/client/2_SanityTraits_ModData.lua"
  modified: []
key-decisions:
  - "Use Events.OnCreatePlayer (not OnNewGame) so the same code path serves new and loaded characters"
  - "Idempotent guard via if md.SanityTraits ~= nil — load-save protection without separate OnLoad hook"
  - "Fallback to SANITY_MAX (1000) for unknown/modded professions — civilian baseline per OCC-05"
  - "Profession ID cached at creation in md.SanityTraits.profession — Phase 4 will read this without re-querying descriptor"
  - "appliedStage starts at literal 'Healthy' string — Phase 2 will mutate to Sad/Depressed/Traumatized/Desensitized"
patterns-established:
  - "Pattern: Per-character init via OnCreatePlayer with idempotent guard (RESEARCH Pattern 2)"
  - "Pattern: Profession-keyed lookup tables in the SanityTraits namespace (extensible for Phase 4)"
  - "Pattern: All ModData mutations log via SanityTraits.LOG_TAG for greppable console output"
requirements-completed: [CORE-01, CORE-02]
duration: 1m 42s
completed: 2026-04-27
---

# Phase 1 Plan 02: Sanity Meter ModData Initialization Summary

**Per-character sanity meter bootstraps on OnCreatePlayer with profession-keyed starting values (veteran=200, police/security/fire=850, doctor/nurse/parkranger=900, civilians=1000) and idempotent reload guard.**

## Performance

- **Duration:** 1m 42s
- **Started:** 2026-04-27T22:34:33Z
- **Completed:** 2026-04-27T22:36:15Z
- **Tasks:** 2
- **Files modified:** 1 (created)

## Accomplishments

- `SanityTraits.getStartingSanity(profName)` callable from any client/ file with safe fallback to `SANITY_MAX` for nil/unknown professions.
- `Events.OnCreatePlayer` registers a handler that writes the canonical per-character ModData shape: `{ sanity, appliedStage = "Healthy", profession }`.
- Idempotent on save reload — existing `md.SanityTraits` is never overwritten, so manually-edited or already-decayed sanity values survive a save/load cycle.
- Profession id is cached on first creation so Phase 4 can read it without re-querying the descriptor (which can be nil during certain frames).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add SanityTraits.getStartingSanity profession lookup** — `314570f` (feat)
2. **Task 2: Register OnCreatePlayer handler that initializes player ModData** — `47f2360` (feat)

**Plan metadata:** _to be created with the final docs commit_

## Files Created/Modified

- `Mods/Sanity_traits/media/lua/client/2_SanityTraits_ModData.lua` — created. Contains `STARTING_SANITY_BY_PROFESSION` table, `getStartingSanity` function, `onCreatePlayer` local handler, and `Events.OnCreatePlayer.Add(onCreatePlayer)` registration. Total 54 lines.

## Interface Contract for Downstream Plans

After this plan, the following contract is in place:

```lua
-- Per-character sanity ModData (auto-persisted with save):
player:getModData().SanityTraits = {
    sanity       = <number 0..1000>,  -- Plan 01-03 will decrement on kills
    appliedStage = "Healthy",          -- Phase 2 will mutate to Sad/Depressed/Traumatized/Desensitized
    profession   = "<base:xxx>",       -- Phase 4 will read for psyche profile lookup
}

-- Helper, safe to call with any profName including nil:
SanityTraits.getStartingSanity(profName)  -- returns 200..1000

-- Lookup table, extensible by Phase 4:
SanityTraits.STARTING_SANITY_BY_PROFESSION  -- 7 entries in Phase 1; all 24 in Phase 4
```

Plan 01-03 (kill events) reads `md.SanityTraits.sanity` and decrements it; the field is guaranteed to exist after `OnCreatePlayer` fires.

## Profession Starting Values (Phase 1 Seed)

| Profession ID         | Start Sanity | Archetype           | Requirement |
| --------------------- | ------------ | ------------------- | ----------- |
| `base:veteran`        | 200          | near-Desensitized   | OCC-02      |
| `base:policeofficer`  | 850          | military/police     | OCC-03      |
| `base:securityguard`  | 850          | military/police     | OCC-03      |
| `base:fireofficer`    | 850          | military/police     | OCC-03      |
| `base:doctor`         | 900          | medical             | OCC-04      |
| `base:nurse`          | 900          | medical             | OCC-04      |
| `base:parkranger`     | 900          | medical-adjacent    | OCC-04      |
| _all others_          | 1000         | civilian baseline   | OCC-05      |

Phase 4 will replace this seed table with the full 24-profession psyche profile.

## Decisions Made

- **OnCreatePlayer over OnNewGame** — OnCreatePlayer fires for both new characters and loaded saves; combined with the `if md.SanityTraits ~= nil then return` guard this gives single-handler init that also re-arms on every load (e.g., after a Phase-4 column rename, the constants would refresh on load).
- **Cache profession id in ModData** — `md.SanityTraits.profession = profName` so Phase 4 can lookup the psyche profile without calling `getDescriptor():getCharacterProfession()` repeatedly (avoids Pitfall 2 nil races mid-frame).
- **No clamping in this handler** — clamping is Plan 01-03's responsibility (kill-event decrement). Initial values are already in `[200, 1000]` by table design; clamping during init would be wasted work.
- **Defensive `profName or "unknown"` for the cached field** — keeps the type stable (always a string) even if descriptor was nil at creation, simplifying Phase 4's lookup.

## Deviations from Plan

None — plan executed exactly as written. No auto-fixed bugs, no missing functionality, no blocking issues. Both verify blocks returned `OK` on first run.

## Authentication Gates

None encountered. (No external services or authenticated APIs are involved in this Lua-only mod plan.)

## Issues Encountered

None.

## Verification Results

**Automated (Tasks 1 & 2):** Both `<verify>` blocks returned `OK` — file presence, all 7 profession entries with correct values, `getStartingSanity` defined with `or SanityTraits.SANITY_MAX` fallback, `onCreatePlayer` handler registered with `Events.OnCreatePlayer.Add`, idempotent guard `if md.SanityTraits ~= nil then` present, Pitfall 2 descriptor guard `desc and desc:getCharacterProfession()` present, no `Events.OnNewGame` (correct event chosen), `LOG_TAG` used for console output.

**Plan-level verification 1-3:**

1. File contains all four required pieces: `STARTING_SANITY_BY_PROFESSION` table, `getStartingSanity` function, `onCreatePlayer` handler, `Events.OnCreatePlayer.Add` registration — confirmed.
2. Profession lookup logic — all 7 entries grep-confirmed with exact values 200/850/850/850/900/900/900.
3. Idempotent guard present at line 30 of the file.

**Verification 4 (in-game manual launch):** Deferred to phase-end UAT per the plan. The game cannot be launched headless from this environment; the user will run the manual check (`print(getPlayer():getModData().SanityTraits.sanity)` for an Unemployed and a Veteran character) at the end of phase 1.

## Requirements Satisfied

- **CORE-01** — `player:getModData().SanityTraits` is initialized on character creation with `sanity` field; auto-persisted via PZ ModData semantics (`reference/moddata.md`).
- **CORE-02** — Starting sanity differs by profession per the 7-entry archetype table; Phase 4 will extend to all 24 vanilla professions.

## Known Stubs

The `STARTING_SANITY_BY_PROFESSION` table is intentionally a 7-entry seed for Phase 1 — it covers the four archetypes called out in RESEARCH.md Pattern 5 (civilian default, veteran, military/police, medical). The full 24-profession psyche profile is owned by Phase 4 (per RESEARCH.md and the plan frontmatter). This is documented in code comments on lines 6 and 9 of the file. Not a defect; intentional scope boundary between phases.

## Next Phase Readiness

- Plan 01-03 (kill events) is unblocked: the `SanityTraits` namespace now provides a guaranteed `md.SanityTraits.sanity` field on every character that has played at least one frame.
- The ModData contract `{ sanity, appliedStage, profession }` is finalized; downstream plans can rely on field names.
- No blockers, no open questions.

---
*Phase: 01-foundation*
*Completed: 2026-04-27*

## Self-Check: PASSED

- `Mods/Sanity_traits/media/lua/client/2_SanityTraits_ModData.lua` — FOUND
- `.planning/phases/01-foundation/01-02-SUMMARY.md` — FOUND
- Commit `314570f` — FOUND in git log
- Commit `47f2360` — FOUND in git log
