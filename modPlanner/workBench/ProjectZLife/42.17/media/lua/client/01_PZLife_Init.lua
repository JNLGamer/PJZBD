-- ProjectZLife / 01_PZLife_Init.lua
-- M1 Phase 1 / Plan 01: Namespace bootstrap and shared constants.
-- Loaded first (numeric prefix "01_") so subsequent client/ files can reference PZLife.*
-- Mirrors the Sanity_traits Phase 1 bootstrap pattern.

PZLife = PZLife or {}

-- Version
PZLife.VERSION = "0.1.0"

-- Log tag used by all PZLife print() calls so console grep/filter is consistent
PZLife.LOG_TAG = "[PZLife]"

-- ── BWO suppression target list ──────────────────────────────────────────────
-- These are the 9 BWO files that register `Events.OnTick` callbacks per the
-- M1 RESEARCH (.planning-ProjectZLife/research/SUMMARY.md). The suppressor in
-- 02_PZLife_BWOSuppressor.lua walks the OnTick callback list at OnGameStart and
-- removes any callback whose source path matches one of these.
PZLife.BWO_TICK_SOURCES = {
    "BWOScheduler",
    "BWOSquareLoader",
    "BWOPopControl",
    "BWOEffects",
    "BWOEmitter",
    "BWOJetEngine",
    "BWOFakeVehicle",
    "BWORadio",
    "BWOVehicles",
}

-- Boot-time announcement: confirms our load order ran before anything else.
print(PZLife.LOG_TAG .. " Init loaded (v" .. PZLife.VERSION .. ")")
