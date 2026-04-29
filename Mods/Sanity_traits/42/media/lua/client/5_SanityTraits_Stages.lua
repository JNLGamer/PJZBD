-- Sanity_traits / 5_SanityTraits_Stages.lua
-- Phase 2 / Plan 02: Public constants/tables for the stage-transition engine + D-36 off-switch helper.
-- Loaded after 1_-4_*.lua (alphabetical/numeric prefix order).
-- Source: .planning/phases/02-stage-transitions/02-RESEARCH.md
--   Patterns 3 (isSystemDisabled), 7 (STAGE_TRAIT_REMOVAL_ON_BROKEN), 8 (LEGACY_APPLIEDSTAGE_COERCION),
--   9 (STAGE_TRAITS public exposure)
-- Verified trait IDs: every ID below is line-by-line confirmed in
--   ProjectZomboid/media/scripts/generated/characters/character_traits.txt (RESEARCH.md table).
--
-- IMPORTANT: `base:out of shape` HAS LITERAL SPACES IN THE ID (line 788 of character_traits.txt).
-- Do NOT rewrite to underscores or hyphens. Copy verbatim.
--
-- Plan 04 ships the evaluator function (SanityTraits.evaluateStageTransitions) into THIS SAME FILE
-- (appended below). Plan 02 lands ONLY the data + isSystemDisabled helper.

-- ── D-32: Hysteresis buffer for upward stage transitions ─────────────────────
-- Sanity must climb threshold + HYSTERESIS_BUFFER to recover (e.g. 800 to exit Shaken).
-- Phase 6 will replace with `SandboxVars.SanityTraits.HysteresisBuffer or 50`.
SanityTraits.HYSTERESIS_BUFFER = 50

-- ── D-38 + STAGE-03/04/05/06: Stage-entry trait sets ─────────────────────────
-- Stage descent into key X applies STAGE_TRAITS[X] in iteration order.
-- Hollow's set DELIBERATELY excludes the addiction trait — D-34: Phase 2 sets
-- `addictionProne = true` on Hollow entry; Phase 5's consumption hook applies
-- the actual addiction trait (base:smoker / sanitymod:alcoholic / sanitymod:painkiller_dependent).
-- Broken's single entry (base:desensitized) is APPLIED VIA the special applyBrokenStage
-- helper in Plan 04 (not the generic descent loop). Listed here for documentation + Phase 6
-- sandbox-tunability.
SanityTraits.STAGE_TRAITS = {
    stable = {},   -- "stable" is the absence of mod-applied traits
    shaken = {
        "base:insomniac",
        "base:cowardly",
    },
    hollow = {
        "base:hemophobic",
        "base:slowhealer",
        "base:weakstomach",
        -- addiction trait deliberately absent — D-34 deferred to Phase 5
    },
    numb = {
        "base:out of shape",     -- LITERAL SPACES IN THE ID (verified line 788)
        "base:needsmoresleep",
        "base:disorganized",
        "base:pacifist",
    },
    broken = {
        "base:desensitized",     -- applied via applyBrokenStage helper in Plan 04
    },
}

-- ── D-33: Blanket-removal list when Broken applies ───────────────────────────
-- Three sources combined:
--   1. Canonical conflict list (vanilla base:desensitized.MutuallyExclusiveTraits at line 247
--      of character_traits.txt): hemophobic, agoraphobic, claustrophobic, cowardly.
--   2. Every prior-stage applied trait (Shaken + Hollow + Numb sets, regardless of origin —
--      mod-applied OR player-picked). DEF-03 guard makes the remove call safe even if absent.
--   3. Phase 5 addiction traits (smoker is vanilla; sanitymod:* not yet defined). DEF-03 guard
--      makes calls safe even when traits are unregistered. Pitfall 5 flagged that
--      HasTrait("sanitymod:alcoholic") on an unregistered trait may emit a Java warning;
--      Plan 04's applyBrokenStage handles the defensive wrapping if Wave 0 smoke test
--      revealed warnings (per 02-01-SUMMARY.md).
SanityTraits.STAGE_TRAIT_REMOVAL_ON_BROKEN = {
    -- 1. Conflict list (D-33 + vanilla MutuallyExclusiveTraits)
    "base:hemophobic",
    "base:agoraphobic",
    "base:claustrophobic",
    "base:cowardly",
    -- 2. Prior-stage applied traits (Shaken/Hollow/Numb sets)
    "base:insomniac",
    "base:slowhealer",
    "base:weakstomach",
    "base:out of shape",     -- LITERAL SPACES — verbatim from STAGE_TRAITS.numb above
    "base:needsmoresleep",
    "base:disorganized",
    "base:pacifist",
    -- 3. Phase 5 addiction traits (defensively included)
    "base:smoker",
    "sanitymod:alcoholic",
    "sanitymod:painkiller_dependent",
}

-- ── D-44 (lazy migration): coerce legacy `appliedStage` strings to thematic keys ──
-- Phase 1 seeded `appliedStage = "Healthy"` (pre-Phase-01.1-rename string).
-- Phase 01.1 renamed stages thematically (stable/shaken/hollow/numb/broken) but did NOT
-- migrate the field. Plan 04's evaluator will lazily coerce on first call after each load.
--
-- Defensive entries for the (highly unlikely) case that some save somehow stored the
-- pre-rename Phase 01.1 STAGE_NAMES (Sad/Depressed/Traumatized/Desensitized) — those
-- never shipped, but defensive mapping costs nothing.
SanityTraits.LEGACY_APPLIEDSTAGE_COERCION = {
    Healthy      = "stable",      -- Phase 1 seed value (the only one that exists in the wild)
    Sad          = "shaken",      -- defensive
    Depressed    = "hollow",      -- defensive
    Traumatized  = "numb",        -- defensive
    Desensitized = "broken",      -- defensive
}

-- ── D-36: Master off-switch helper ───────────────────────────────────────────
-- Returns true iff the sanity system should treat this player as inert.
-- Trips when player has base:desensitized:
--   * Veteran (vanilla profession-grants base:desensitized at character creation,
--     verified character_professions.txt:258)
--   * Player picked Desensitized at character creation (modded char-creation flows)
--   * Modded "hardened survivor" professions
--   * Our own Phase 2 application after Broken (next event tick early-returns)
--
-- Defensive: if `player == nil`, returns true (system inert — safe default).
--
-- Call sites (added by Plans 03, 04, 05):
--   * 2_SanityTraits_ModData.lua / onCreatePlayer (Plan 03)
--   * 3_SanityTraits_KillEvents.lua / onZombieDead, onWeaponHitXp (Plan 05)
--   * 5_SanityTraits_Stages.lua / evaluateStageTransitions (Plan 04 — appended below)
--
-- API form: string-form per 02-01-SUMMARY.md (Wave 0 smoke test confirmed api_form=string).
function SanityTraits.isSystemDisabled(player)
    if not player then return true end
    return player:HasTrait("base:desensitized")
end

print(SanityTraits.LOG_TAG .. " Stages constants loaded (HYSTERESIS_BUFFER="
    .. tostring(SanityTraits.HYSTERESIS_BUFFER) .. ")")
