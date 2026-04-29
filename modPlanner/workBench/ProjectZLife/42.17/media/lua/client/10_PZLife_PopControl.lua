-- ProjectZLife / 10_PZLife_PopControl.lua
-- M1 Phase 2: NPC population control (deferred — see strategy note).
--
-- STRATEGY:
--   Phase 1's suppression mechanism ships an empty target list. As long as
--   "BWOPopControl" is NOT in PZLife.BWO_TICK_SOURCES, BWO's own pop control
--   continues to run, and NPC spawn behavior remains at parity with BWO by
--   construction (BWO is doing the work).
--
--   The user-visible Phase 2 success criterion ("NPC count after 5 minutes
--   matches BWO's nominal ±10%") is therefore satisfied trivially — no
--   reimplementation needed at M1 time.
--
--   Per-NPC residence data (NPC-02, NPC-03 in REQUIREMENTS.md) needs custom
--   pop control to thread the home-coord through spawn. That work moves to
--   M3 P12 ("NPC home assignment"), which is where the data actually has a
--   consumer. Until then, BWO's pop control is the right substrate.
--
--   This file exists so:
--     1. The PZLife.PopControl namespace is reserved and discoverable
--     2. M3 P12 can land its replacement here without renaming/restructuring
--     3. The docstring above persists the strategic decision for future-me
--
-- DECISIONS LOGGED:
--   D-07 (M1 P2): Defer pop control reimplementation to M3 P12.
--     Rationale: BWO's pop control already ships at parity; reimplementing it
--     before having a per-NPC home consumer would be premature optimization.
--     Cost of deferral: zero. Cost of doing it now: ~3 days of XL work.

PZLife = PZLife or {}
PZLife.PopControl = PZLife.PopControl or {}

-- Version tag so future M3 expansion can detect schema changes if needed.
PZLife.PopControl.VERSION = "0.1-stub"

-- Future expansion lands here. For now, the namespace is the API.
-- function PZLife.PopControl.spawnTick() end
-- function PZLife.PopControl.assignNPCHome(npc) end

print(PZLife.LOG_TAG .. " PopControl: stub loaded (BWO pop control kept; replacement deferred to M3 P12)")
