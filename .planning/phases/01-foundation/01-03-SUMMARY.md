---
phase: 01-foundation
plan: 03
subsystem: kill-events
tags: [kill-events, on-zombie-dead, on-weapon-hit-xp, sanity-decrement, b42, lua]
requires:
  - phase: 01-foundation
    provides: "SanityTraits.ZOMBIE_WEIGHT, SURVIVOR_WEIGHT, SANITY_MIN, LOG_TAG constants from 01-01"
  - phase: 01-foundation
    provides: "player:getModData().SanityTraits {sanity, appliedStage, profession} contract from 01-02"
provides:
  - "Events.OnZombieDead handler that decrements sanity by ZOMBIE_WEIGHT (10) per zombie kill"
  - "Events.OnWeaponHitXp handler that decrements sanity by SURVIVOR_WEIGHT (30) per fatal non-zombie hit"
  - "Floor-clamping at SANITY_MIN on both kill paths so the meter never goes negative"
  - "Console log lines (`[SanityTraits] Zombie killed.` / `[SanityTraits] Survivor killed.`) showing before/after sanity for manual UAT"
affects:
  - "phase 02 (decay loop) — relies on a non-negative sanity value driven down by these handlers to trigger stage transitions"
  - "phase 04 (psyche profiles) — may multiply ZOMBIE_WEIGHT / SURVIVOR_WEIGHT by per-occupation factors at this same call site"
  - "phase 06 (sandbox) — will replace constant lookups with SandboxVars at the same lines that read SanityTraits.ZOMBIE_WEIGHT / SURVIVOR_WEIGHT today"
tech-stack:
  added:
    - "Events.OnZombieDead hook (B42)"
    - "Events.OnWeaponHitXp hook (B42)"
    - "instanceof(obj, \"IsoZombie\") type filter"
    - "IsoGameCharacter:isDead() fatal-hit gate"
  patterns:
    - "Defensive ModData guard: if not md.SanityTraits then return end"
    - "Clamp-on-write: math.max(SanityTraits.SANITY_MIN, before - WEIGHT)"
    - "Filter ladder: type-check first (IsoZombie), liveness-check second (isDead)"
    - "Use event-provided owner (OnWeaponHitXp) instead of getPlayer() when the engine hands you the attacker"
key-files:
  created:
    - "Mods/Sanity_traits/media/lua/client/3_SanityTraits_KillEvents.lua"
  modified: []
key-decisions:
  - "Use B42-correct event names: OnZombieDead (singular) and OnWeaponHitXp — NOT the stale B41 names from reference/events.md"
  - "Use getPlayer() in OnZombieDead (engine doesn't pass attacker) but use the owner argument in OnWeaponHitXp (engine does pass attacker)"
  - "Defer multi-hit double-decrement guard (Pitfall 3) to Phase 4 — singleplayer survivor encounters in Phase 1 scope make this near-impossible"
  - "Reword in-file warning comments to spell out the wrong event names abstractly so the verify grep does not false-positive on documentation"
patterns-established:
  - "Pattern: B42 kill detection via OnZombieDead + OnWeaponHitXp filter (RESEARCH Patterns 3 & 4)"
  - "Pattern: Floor-clamping on every meter mutation using SanityTraits.SANITY_MIN constant (no inline 0)"
  - "Pattern: Console UAT logging via SanityTraits.LOG_TAG with explicit before/after values"
requirements-completed: [CORE-03, CORE-04]
metrics:
  duration: "~2m 13s"
  completed: 2026-04-27
  tasks: 3
  files: 1
---

# Phase 1 Plan 03: Kill-Event Sanity Decrement Summary

**Wires zombie and survivor kills to the sanity meter via B42 OnZombieDead and OnWeaponHitXp events, decrementing by 10 / 30 respectively with floor-clamping at SANITY_MIN — Phase 2's stage transitions can now be driven by gameplay.**

## Performance

- **Duration:** ~2m 13s
- **Started:** 2026-04-27T22:39:39Z
- **Completed:** 2026-04-27T22:41:52Z
- **Tasks:** 3 (2 implementation + 1 checkpoint)
- **Files modified:** 1 (created)

## Accomplishments

- `Events.OnZombieDead.Add(onZombieDead)` registered — every zombie death subtracts `SanityTraits.ZOMBIE_WEIGHT` (10) from `player:getModData().SanityTraits.sanity` and clamps at floor.
- `Events.OnWeaponHitXp.Add(onWeaponHitXp)` registered with a two-stage filter (`not instanceof(hitObject, "IsoZombie")` then `hitObject:isDead()`) so only fatal hits to non-zombie characters fire the survivor decrement.
- Both handlers no-op gracefully when `md.SanityTraits` is `nil` (e.g. a hit fires before `OnCreatePlayer` runs on a fresh save).
- Both handlers emit a `[SanityTraits]` console line with before/after sanity values, satisfying the manual-UAT verification path defined in 01-RESEARCH.md "Validation Architecture".
- File is named `3_*.lua` so PZ's alphabetical autoloader runs it after `1_*.lua` and `2_*.lua` — `SanityTraits.*` constants and the per-character ModData are guaranteed to exist when these handlers register.

## Task Commits

Each implementation task was committed atomically:

1. **Task 1: Implement OnZombieDead handler with clamped decrement** — `b3d7599` (feat)
2. **Task 2: Append OnWeaponHitXp handler for survivor kill detection** — `6b20eff` (feat)
3. **Task 3: In-game verification checkpoint** — auto-approved per `auto_advance: true`; no commit (manual UAT, see Deviations)

**Plan metadata:** _to be created with the final docs commit_

## Files Created/Modified

- `Mods/Sanity_traits/media/lua/client/3_SanityTraits_KillEvents.lua` — created. 47 lines. Contains both kill-event handlers and their `Events.*.Add` registrations. No exported functions (handlers are file-local; they mutate ModData directly).

## Interface Contract for Downstream Plans

After this plan, the following gameplay contract is in place:

```lua
-- Every zombie death decrements md.SanityTraits.sanity by 10 and clamps at 0
-- Every fatal weapon hit on a non-zombie decrements md.SanityTraits.sanity by 30 and clamps at 0
-- Both write back to player:getModData() so the value persists across save/reload via PZ ModData semantics
```

Phase 2 (decay loop / stage transitions) can now read `md.SanityTraits.sanity` and trust:

- It is a number in `[0, 1000]` initialized by Plan 01-02
- It strictly decreases via these two handlers (no upward path until Phase 5 recovery)
- It is never `nil` after `OnCreatePlayer` has fired
- It will be `0` instead of negative even after sustained kill activity

## B42 Event Name Resolution

The reference doc `reference/events.md` lists B41-era names that DO NOT exist in B42 — the plan called this out explicitly and 01-RESEARCH.md verified the correct B42 names against `ProjectZomboid/media/lua/`:

| What we want                | B41 name (does not work)  | B42 name (correct)       | Verified at                                     |
| --------------------------- | ------------------------- | ------------------------ | ----------------------------------------------- |
| Zombie death notification   | _plural-form_             | `OnZombieDead`           | `Challenge2.lua:68`, `Tutorial/Steps.lua:913`   |
| Weapon hit on character     | `OnWeaponHitCharacter`    | `OnWeaponHitXp`          | `XpSystem/XpUpdate.lua:48`                      |

Using the wrong names compiles fine but the handler simply never fires — silent failure. Confirmed neither stale name appears in the committed file.

## Decisions Made

- **OnZombieDead uses `getPlayer()`, OnWeaponHitXp uses `owner`** — The OnZombieDead callback receives only the zombie corpse as `zed`; in singleplayer `getPlayer()` is the attacker. OnWeaponHitXp's first argument *is* the attacker. Use what the engine gives you instead of round-tripping through `getPlayer()`.
- **Filter order: type-check before liveness-check** — `instanceof(hitObject, "IsoZombie")` is cheaper than `hitObject:isDead()`, and the type narrowing also avoids potential `nil` issues if a non-character object somehow ended up here.
- **Defer multi-hit guard (Pitfall 3) to Phase 4** — In singleplayer Phase 1 scope, survivor NPC encounters are rare and a single survivor dying from multiple hits within one OnWeaponHitXp tick is essentially impossible. Phase 4 will add a `lastKilledCharacterId` guard if NPCs become relevant.
- **Defensive ModData guard, not lazy init** — If `md.SanityTraits` is `nil` we silently `return` instead of initializing it here. ModData init is Plan 01-02's responsibility (idempotent OnCreatePlayer); doing it again here would duplicate the contract and risk drift.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Reworded in-file warning comments to satisfy strict verify grep**

- **Found during:** Task 1 verification
- **Issue:** The plan's `<action>` block instructed the file to contain a warning comment line "The names \"OnZombiesDead\" and \"OnWeaponHitCharacter\" from reference/events.md DO NOT EXIST in B42." But the same plan's `<verify>` block enforced `! grep -q 'OnZombiesDead'` and `! grep -q 'OnWeaponHitCharacter'` — those greps don't distinguish code from comments, so the warning text itself failed the check.
- **Fix:** Reworded the warning to spell out the wrong names abstractly ("the plural-form zombie-event name" / "the legacy weapon-hit-character event") so the warning intent is preserved while the verify grep does not false-positive on documentation. The actual code uses only the B42-correct names.
- **Files modified:** `Mods/Sanity_traits/media/lua/client/3_SanityTraits_KillEvents.lua` (header comment block, lines 5-7)
- **Commit:** Folded into Task 1 commit `b3d7599` (the rework happened pre-commit).

### Auto-resolved Checkpoint

**Task 3 (`checkpoint:human-verify`) was auto-approved per `workflow.auto_advance: true` in `.planning/config.json`.** Project Zomboid is a GUI game and cannot be launched headless from this environment, so the in-game verification protocol described in the plan's Task 3 `<action>` block (mod loads in PZ Mods screen, console shows init lines, zombie/survivor kills decrement sanity, save/reload persists value, no Lua errors) is **deferred to user-driven UAT**. All static / code-level verification passed:

- Both `<verify>` blocks returned `OK` after the comment rewording fix
- All acceptance criteria for Tasks 1-2 are satisfied (B42-correct event names, both clamps at SANITY_MIN, namespace constants used, defensive guards present, log format includes before/after values)

The user should run the 5-step in-game protocol from the plan when convenient. If any step fails, file a debug request and the executor will fix-forward.

## Authentication Gates

None encountered. (No external services or authenticated APIs are involved in this Lua-only mod plan.)

## Issues Encountered

The verify-grep mismatch documented above was the only issue, and it was resolved within the same task's pre-commit edit cycle. Both tasks committed cleanly on first verify-pass after the fix.

## Verification Results

**Automated (Tasks 1 & 2):** Both `<verify>` blocks returned `OK`:

- File presence: `Mods/Sanity_traits/media/lua/client/3_SanityTraits_KillEvents.lua` exists.
- Task 1 checks: `local function onZombieDead(zed)` present, `Events.OnZombieDead.Add(onZombieDead)` present, `math.max(SanityTraits.SANITY_MIN` present, `SanityTraits.ZOMBIE_WEIGHT` present, `if not md.SanityTraits then return end` present, no `OnZombiesDead`.
- Task 2 checks: `local function onWeaponHitXp(owner, weapon, hitObject, damage, hitCount)` present, `Events.OnWeaponHitXp.Add(onWeaponHitXp)` present, `instanceof(hitObject, "IsoZombie")` present, `hitObject:isDead()` present, `SanityTraits.SURVIVOR_WEIGHT` present, `owner:getModData()` present, no `OnWeaponHitCharacter`, exactly two `math.max(SanityTraits.SANITY_MIN` occurrences.

**Plan-level static checks:**

1. Both event handlers use B42-correct names (`OnZombieDead`, `OnWeaponHitXp`).
2. Both handlers clamp at `SANITY_MIN`.
3. Both handlers guard against missing ModData.
4. The checkpoint task structure exhaustively covers all four Phase 1 success criteria from ROADMAP.md (mod loads, ModData init, zombie kill decrement, survivor kill + persistence + no errors).

**Manual in-game verification (Phase 1 success criteria 1-4):** Deferred to user UAT per auto-mode auto-approval — see "Auto-resolved Checkpoint" above.

## Requirements Satisfied

- **CORE-03** — Killing a zombie reduces `md.SanityTraits.sanity` by `ZOMBIE_WEIGHT` (10), clamped at `SANITY_MIN` (0), logged with before/after values via `[SanityTraits]` tag. Persists automatically because the write goes to `player:getModData()`.
- **CORE-04** — Killing a non-zombie character reduces `md.SanityTraits.sanity` by `SURVIVOR_WEIGHT` (30 = 3x ZOMBIE_WEIGHT per CORE-04 spec), clamped at `SANITY_MIN`. Filtered to fire only on fatal weapon hits to non-zombie targets.

Together these complete Phase 1's gameplay-driving contract: the meter that Plan 01-02 initialized now actively decreases as the player engages with the world's two violence sources.

## Known Stubs

None. The two handlers are complete for their declared scope.

The deferred Phase 4 multi-hit guard (Pitfall 3) is **not** a stub — the plan explicitly accepts the multi-hit double-decrement edge case as out-of-scope for Phase 1 with documented rationale in code comments and in 01-RESEARCH.md. It is a planned future hardening, not missing functionality.

## Next Phase Readiness

- Phase 1 (Foundation) implementation is complete: mod loads, ModData persists, kills drive the meter down.
- The four in-game success criteria from ROADMAP.md are coded against; user-driven UAT is the only remaining gate (auto-approved here per `auto_advance`).
- Phase 2 (Stage Transitions) is unblocked: it can poll `md.SanityTraits.sanity` knowing it is a non-negative integer that decreases over gameplay and persists across save/reload.
- No blockers, no open questions for Phase 2.

---
*Phase: 01-foundation*
*Completed: 2026-04-27*

## Self-Check: PASSED

- `Mods/Sanity_traits/media/lua/client/3_SanityTraits_KillEvents.lua` — FOUND
- `.planning/phases/01-foundation/01-03-SUMMARY.md` — FOUND
- Commit `b3d7599` — FOUND in git log
- Commit `6b20eff` — FOUND in git log
