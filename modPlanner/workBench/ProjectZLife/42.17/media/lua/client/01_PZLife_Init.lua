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
-- Starts EMPTY by design. Each subsequent phase that ships a replacement for a
-- BWO `OnTick` consumer registers itself here at file-load via
-- PZLife.AddBWOSuppressionTarget(<name>). The suppressor in
-- 02_PZLife_BWOSuppressor.lua walks the OnTick callback list at OnGameStart and
-- removes any callback whose source path matches a registered name.
--
-- M1 P1 (this phase): ships the mechanism, suppresses NOTHING — BWO continues
--   to run as it did before our mod loaded.
-- M1 P2 (next): would add "BWOPopControl" — but per the revised M1 strategy,
--   BWO's pop control stays alive and we replace it in M3 instead. So no
--   addition this milestone.
-- M2/M3 phases: add their respective BWO source name as each replacement ships.
--
-- Known candidate suppression targets per .planning-ProjectZLife/research/
--   SUMMARY.md Architecture section:
--     BWOScheduler, BWOSquareLoader, BWOPopControl, BWOEffects, BWOEmitter,
--     BWOJetEngine, BWOFakeVehicle, BWORadio, BWOVehicles.
PZLife.BWO_TICK_SOURCES = {}

-- Public helper: register a BWO source name for suppression.
-- Idempotent — safe to call multiple times with the same name.
function PZLife.AddBWOSuppressionTarget(name)
    if type(name) ~= "string" or name == "" then return end
    for _, existing in ipairs(PZLife.BWO_TICK_SOURCES) do
        if existing == name then return end  -- already registered
    end
    PZLife.BWO_TICK_SOURCES[#PZLife.BWO_TICK_SOURCES + 1] = name
end

-- Boot-time announcement: confirms our load order ran before anything else.
print(PZLife.LOG_TAG .. " Init loaded (v" .. PZLife.VERSION .. ")")
