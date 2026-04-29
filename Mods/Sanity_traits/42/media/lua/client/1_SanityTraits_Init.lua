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

-- ── Phase 01.2 constants (counter-tree fade window + geometry + Phase 2 hook map) ──

-- D-28: recency-fade window in milliseconds (real-time wall-clock).
-- 10 real-time seconds — counter rows lerp from WHITE to MID_GREY over this window.
SanityTraits.FADE_WINDOW_MS = 10 * 1000

-- Counter tree geometry (UI-SPEC §Spacing Scale; consumed by SanityPanel:renderCounterTree).
SanityTraits.COUNTER_ROW_H  = 14   -- row height: UIFont.Small ~12px + 2px pad
SanityTraits.COUNTER_INDENT = 14   -- per-depth indent for subcategory rows
SanityTraits.COUNTER_TREE_X = 10   -- counter tree left margin (matches readout/stage label X)
SanityTraits.COUNTER_TREE_Y = 82   -- counter tree top edge (bumped from 62 to make room for sub-tab strip at y=54)

-- D-29 Hook Contract 2: maps STAGE_NAMES key -> counters.stageDescents key.
-- Used by Phase 2 stage-transition handler to address the right counter slot:
--   SanityTraits.bumpCounter("stageDescents." .. SanityTraits.STAGE_DESCENT_KEY[newStageKey])
-- "stable" intentionally absent — recovering UP to stable doesn't count as a descent.
SanityTraits.STAGE_DESCENT_KEY = {
    shaken = "toShaken",
    hollow = "toHollow",
    numb   = "toNumb",
    broken = "toBroken",
}

-- ── Phase 3 constants (timed decay + recovery + bonus events) ─────────────────
-- D-44: per-stage decay rate; D-45: per-stage recovery rate.
-- Both tables key on the SAME thematic stage names as STAGE_NAMES / computeStage output
-- ("stable"|"shaken"|"hollow"|"numb"|"broken"). Lookups use `tbl[computeStage(sanity)] or 0`
-- so a "broken" key (handler short-circuits via isSystemDisabled before this point in
-- practice) yields 0 and the caller no-ops. Phase 6 will replace literals with
-- SandboxVars.SanityTraits.DecayRate<Stage> / RecoveryRate<Stage> / GoodEventBonus / GoodEventDailyCap.

SanityTraits.DECAY_RATE_BY_STAGE = {
    stable = 1,
    shaken = 2,
    hollow = 3,
    numb   = 4,
    -- broken: handler short-circuits via isSystemDisabled; "or 0" defends in caller
}

SanityTraits.RECOVERY_RATE_BY_STAGE = {
    stable = 1,
    shaken = 2,
    hollow = 2,
    numb   = 2,
    -- broken: handler short-circuits; "or 0" defends in caller
}

-- D-45: bonus events (sleep / eat / read / entertainment-reserved). Per-event sanity gain
-- and per-in-game-day cumulative cap. Cap is enforced inline in applyBonusEvent (Plan 03-03)
-- and reset on Events.EveryDays (Plan 03-02).
SanityTraits.GOOD_EVENT_BONUS     = 5
SanityTraits.GOOD_EVENT_DAILY_CAP = 30

-- ── Phase 5 constants (habit tracking + addictions) ──────────────────────────
-- D-57: minimum total consumption events to qualify for habit-based addiction selection.
-- Below this floor, evaluateAddictions falls through to applyRandomAddiction (HABIT-03).
-- Phase 6 will replace with `SandboxVars.SanityTraits.AddictionMinThreshold or 5`.
SanityTraits.ADDICTION_MIN_THRESHOLD = 5

-- ── Phase 6: Sandbox overrides (CORE-07) ─────────────────────────────────────
-- On OnGameStart, swap hardcoded defaults with SandboxVars.SanityTraits.* values
-- when present. Old saves that predate sandbox config fall through to defaults
-- because SandboxVars.SanityTraits is nil or its fields are nil — `or default`
-- preserves prior behavior. Decay/recovery sandbox values are MULTIPLIERS applied
-- to the per-stage rate tables (not stage-specific values), keeping the sandbox
-- screen compact while still letting players tune pacing.
SanityTraits.SANDBOX_DECAY_MULT    = 1.0
SanityTraits.SANDBOX_RECOVERY_MULT = 1.0

function SanityTraits.applySandboxOverrides()
    local sv = SandboxVars and SandboxVars.SanityTraits
    if not sv then
        print(SanityTraits.LOG_TAG .. " sandbox: SandboxVars.SanityTraits not present, using defaults")
        return
    end

    SanityTraits.ZOMBIE_WEIGHT          = sv.ZombieWeight          or SanityTraits.ZOMBIE_WEIGHT
    SanityTraits.SURVIVOR_WEIGHT        = sv.SurvivorWeight        or SanityTraits.SURVIVOR_WEIGHT
    SanityTraits.SANDBOX_DECAY_MULT     = sv.DecayMultiplier       or 1.0
    SanityTraits.SANDBOX_RECOVERY_MULT  = sv.RecoveryMultiplier    or 1.0

    if sv.SadThreshold          then SanityTraits.STAGE_THRESHOLDS.sad          = sv.SadThreshold end
    if sv.DepressedThreshold    then SanityTraits.STAGE_THRESHOLDS.depressed    = sv.DepressedThreshold end
    if sv.TraumatizedThreshold  then SanityTraits.STAGE_THRESHOLDS.traumatized  = sv.TraumatizedThreshold end

    print(SanityTraits.LOG_TAG .. " sandbox applied: ZW=" .. tostring(SanityTraits.ZOMBIE_WEIGHT)
        .. " SW=" .. tostring(SanityTraits.SURVIVOR_WEIGHT)
        .. " decayMult=" .. tostring(SanityTraits.SANDBOX_DECAY_MULT)
        .. " recoveryMult=" .. tostring(SanityTraits.SANDBOX_RECOVERY_MULT)
        .. " thresholds=[" .. tostring(SanityTraits.STAGE_THRESHOLDS.sad)
        .. "/" .. tostring(SanityTraits.STAGE_THRESHOLDS.depressed)
        .. "/" .. tostring(SanityTraits.STAGE_THRESHOLDS.traumatized) .. "]")
end

Events.OnGameStart.Add(SanityTraits.applySandboxOverrides)

print(SanityTraits.LOG_TAG .. " Init loaded (v" .. SanityTraits.VERSION .. ")")
