# Project Z Life — Shelved

**Shelved:** 2026-04-30 after first in-game smoke test
**Last commit:** `6fdcb6f` — *feat(ProjectZLife): M2 P9+P10 — police behavior tier + job income; closes M2*
**Total work:** 11 of 25 phases shipped (44%); 12 client lua files; ~2024 lines; 38 decisions logged (D-01..D-38)

---

## Why halted

In-game smoke test surfaced **5 substrate-API mismatches** between assumed B42.17
internals and reality. The mismatches are individually small (1-line patches
each) but reveal a systemic gap: we built defensive probing on top of *guessed*
B42 API shapes, and the guesses don't match the engine. Continuing to stack M3
phases on this substrate would compound the problem.

The honest call: halt, document, resume after a dedicated B42-internals
investigation session.

---

## What works

These announce themselves cleanly at boot per the console log:

- ✅ Mod registers as **"Project Z Life"** with id=ProjectZLife
- ✅ `require=Bandits2,BanditsWeekOne` chain resolves
- ✅ `incompatible=` declaration *would* block conflicts (untested at install time
  because user manually disabled the 3 absorbed mods instead — `incompatible=`
  syntax may need backslash prefix per Slayer's convention)
- ✅ All 12 modules load + announce: Init, BWOSuppressor, PopControl,
  HomeAssignment, JobAssignment, MapMarkers, ItemPrices, Trespassing, Wanted,
  BustedWasted, PoliceBehavior, JobIncome
- ✅ ItemPrices monkey-patches `ISInventoryPane.renderdetails` (`hooked` log line)
- ✅ Trespassing creates banner ISPanel per player (`banner ensured for player 0`)
- ✅ JobIncome's policeman hook installs (`OnZombieDead hooked`)
- ✅ The architecture (namespaces, decision log, milestone roadmap) is intact

## What doesn't (the 5 substrate mismatches)

| # | File | Symptom | What's actually wrong |
|---|------|---------|------------------------|
| 1 | `02_PZLife_BWOSuppressor.lua` | `WARN: Events.OnTick has no readable callback list` | None of `Events.OnTick.callbacks` / `_callbacks` / `__callbacks` exist on B42.17. The Java-side Events bridge stores callbacks elsewhere. **Investigation needed:** `for k,v in pairs(Events.OnTick) do print(k, type(v)) end` from in-game console. |
| 2 | `34_PZLife_PoliceBehavior.lua` | `WARN: no Police/SWAT programs found in ZombiePrograms (BWO not loaded?)` | BWO IS loaded (confirmed in log: `loading BanditsWeekOne`). But `ZombiePrograms.Police/SWAT/RiotPolice` aren't in the global namespace at our hook time. They might live under `ZombiePrograms.WeekOne.Police` or be lazy-loaded. **Investigation needed:** in-game `for k,v in pairs(ZombiePrograms) do print(k) end`. |
| 3 | `35_PZLife_JobIncome.lua` | `WARN: fireman hook not installed (ZAExtinguish not found at hook time)` | `ZAExtinguish` global doesn't exist where we expect. May be under `ZombieActions.Extinguish` or namespaced differently. |
| 4 | `22_PZLife_MapMarkers.lua` | `WARN: no WorldMap symbols API surface found` | All 3 probes failed: `ISWorldMap.getSymbolsAPI`, `WorldMapVisible.getSymbolsAPI`, `getWorldMap():getSymbolsAPI`. The B42.17 World Map symbol API uses a different access path. **Investigation needed:** trace BWO's own marker-render code for the actual API. |
| 5 | `20_PZLife_HomeAssignment.lua:63` | **CRITICAL CRASH**: `Object tried to call nil in findHomeForPlayer` | `getCurrentSquare():getRoom()` returns nil when player spawns outdoors. Then `def:getX()` is called on a nil `def` (no nil-guard between line 47 building lookup and line 63 def access). Cascades through `JobAssignment.assign` (line 90) too. **Fix:** add `if not def then return fallbackCoord(player) end` after line 47. |

---

## What was learned

- **Defensive coding doesn't substitute for substrate validation.** Probing 3
  candidate API names is faster than reading source, but slower than 30 seconds
  of in-game discovery via `for k,v in pairs(...)`.
- **B42.17 internals differ from B41 docs and from BWO source assumptions.** The
  ZombiePrograms namespace shape, Events callback storage, WorldMap symbol API,
  and ZombieActions registry all behave differently than documented.
- **Compound risk is real.** With 11 phases shipped and 14 to go, each stacking
  on substrate APIs we haven't validated, the cost of "fix later" grows
  super-linearly. Halting at 44% saves more re-work than barreling on would.
- **The Sanity_traits cadence DID work for code authoring** — atomic phases,
  static verification, dev→runtime deploy, decision logging. The breakdown was
  in the *substrate-knowledge layer*, not the methodology.

---

## Resume conditions

Resume Project Z Life when **any** of:

1. **A B42-internals investigation session lands first.** ~1 hour of in-game
   `pairs()` discovery on Events / ZombiePrograms / ZombieActions / WorldMap.
   Output: a `B42_API_NOTES.md` documenting the actual API shapes. Then fix the
   5 mismatches, then resume M3.
2. **A B42 update notes Events / WorldMap stabilization** — saves the discovery
   work; just update probes and resume.
3. **The user wants to come back.** No external time pressure. The workspace,
   commits, planning, and decisions are preserved indefinitely.

---

## Where everything lives

| Artifact | Path |
|---|---|
| Source code | `modPlanner/shelved/ProjectZLife/` (this folder) |
| Planning workspace | `.planning-ProjectZLife/` at PJZBD root (gitignored; full PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md, research/SUMMARY.md, phases/01-foundation/, phases/02-popcontrol/, phases/03-jobs-homes-map/, phases/04-uat/M1-HUMAN-UAT.md, phases/11-m2-uat/M2-HUMAN-UAT.md) |
| Approved plan | `C:/Users/joaqu/.claude/plans/deeply-research-d-steamlibrary-steamapps-twinkly-fern.md` |
| Runtime backup | Was at `C:/Users/joaqu/Zomboid/mods/ProjectZLife/`; folder no longer present (Steam Workshop migration likely cleaned it). Re-deploy via `cp -rv modPlanner/shelved/ProjectZLife/. C:/Users/joaqu/Zomboid/mods/ProjectZLife/` if resuming. |
| Last shipping commit | `6fdcb6f` |
| Subject identifier | `.gsd-subject` at PJZBD root still says `ProjectZLife` — leave or change as user prefers |

---

## Resume checklist

If/when you bring this back:

1. Run a B42-internals probe session in-game (`for k,v in pairs(Events.OnTick) do ...`, same for `ZombiePrograms`, `ZombieActions`, `getWorldMap()`). Write findings to a NOTES.md.
2. Fix the 5 substrate mismatches:
   - Update `02_PZLife_BWOSuppressor.lua` `getCallbackList()` with real field name
   - Update `34_PZLife_PoliceBehavior.lua` with real ZombiePrograms.Police path
   - Update `35_PZLife_JobIncome.lua` with real ZAExtinguish path
   - Update `22_PZLife_MapMarkers.lua` `probeSymbolsAPI()` with real WorldMap API
   - Add nil-guard in `20_PZLife_HomeAssignment.lua` line 47-63 (the `def` deref crash)
3. `git mv modPlanner/shelved/ProjectZLife → modPlanner/workBench/ProjectZLife`
4. Re-deploy to runtime
5. Re-run M1 + M2 smoke tests (the 30 UAT scenarios already authored)
6. Resume autonomous mode at M3 P12 (NPC home assignment) — the next planned phase

The 38 decisions logged in PROJECT.md + per-phase SUMMARY files persist the
*why* behind every architectural choice. A resuming session has all the context
needed without re-deriving anything.
