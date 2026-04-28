-- Sanity_traits / 1_SanityTraits_Init.lua
-- Phase 1 / Plan 01: Namespace bootstrap and shared constants.
-- Loaded first (numeric prefix "1_") so subsequent client/ files can reference SanityTraits.*
-- Source patterns: reference/mod_structure.md, .planning/phases/01-foundation/01-RESEARCH.md (Pattern 1)

SanityTraits = SanityTraits or {}

-- Version
SanityTraits.VERSION = "1.0"

-- Sanity meter bounds (CORE-01)
SanityTraits.SANITY_MAX = 1000
SanityTraits.SANITY_MIN = 0

-- Kill decay weights (CORE-03, CORE-04)
-- Phase 6 will replace these with SandboxVars; defaults must remain functional in the absence of sandbox config.
SanityTraits.ZOMBIE_WEIGHT   = 10
SanityTraits.SURVIVOR_WEIGHT = 30  -- 3x zombie weight per CORE-04 default

-- Log tag used by all SanityTraits print() calls so console grep/filter is consistent
SanityTraits.LOG_TAG = "[SanityTraits]"

-- ── Stage thresholds (D-08) ──────────────────────────────────────────────────
-- LOCKED in Phase 01.1; consumed by Phase 2 transition logic and 01.1 panel rendering.
-- Boundary semantics: a value EQUAL to a threshold belongs to the LOWER stage (uses `<=`).
SanityTraits.STAGE_THRESHOLDS = {
    sad          = 750,  -- <=750 enters Shaken
    depressed    = 500,  -- <=500 enters Hollow
    traumatized  = 250,  -- <=250 enters Numb
    desensitized = 50,   -- <=50  enters Broken
}

-- ── Player-facing thematic stage names (D-09) ────────────────────────────────
-- Trait IDs (base:cowardly etc.) are unchanged; this is UI strings only.
SanityTraits.STAGE_NAMES = {
    stable  = "Stable",   -- sanity > 750
    shaken  = "Shaken",   -- sanity <= 750
    hollow  = "Hollow",   -- sanity <= 500
    numb    = "Numb",     -- sanity <= 250
    broken  = "Broken",   -- sanity <= 50
}

-- ── computeStage(sanity) -> stage key (D-10) ─────────────────────────────────
-- Returns one of: "stable", "shaken", "hollow", "numb", "broken".
-- Phase 2 reuses this same helper for transition logic; Plan 03 panel reads it for the stage label.
-- Order matters: lowest threshold first so a value of 50 returns "broken", not "numb".
function SanityTraits.computeStage(sanity)
    if sanity <= SanityTraits.STAGE_THRESHOLDS.desensitized then return "broken" end
    if sanity <= SanityTraits.STAGE_THRESHOLDS.traumatized  then return "numb"   end
    if sanity <= SanityTraits.STAGE_THRESHOLDS.depressed    then return "hollow" end
    if sanity <= SanityTraits.STAGE_THRESHOLDS.sad          then return "shaken" end
    return "stable"
end

-- ── UI sizing constants (consumed by Plan 02 logger and Plan 03 panel) ───────
SanityTraits.LOG_MAX_ENTRIES   = 50  -- D-12: FIFO eviction at 51st entry
SanityTraits.DEBUFF_SLOT_COUNT = 6   -- D-16: reserved slot count in debuff row

print(SanityTraits.LOG_TAG .. " Init loaded (v" .. SanityTraits.VERSION .. ")")
