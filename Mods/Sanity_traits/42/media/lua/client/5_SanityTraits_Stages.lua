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
    -- 3. Phase 5 addiction traits — REMOVED in Plan 05-03 per D-58 (addictions persist past Broken).
    --    Persistence is enforced by removeStageTraits's ADDICTION_TRAIT_IDS skip + this list omission.
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


-- ════════════════════════════════════════════════════════════════════════════
-- Phase 2 / Plan 04: Stage transition evaluator + private helpers
-- ════════════════════════════════════════════════════════════════════════════
-- Public surface added by this plan:
--   SanityTraits.evaluateStageTransitions(player) — called by kill handlers (Plan 05)
--   and future Phase 3 decay tick.
--
-- Private file-local helpers below (applyTrait, removeTrait, removeStageTraits,
-- applyBrokenStage, applyStageDeltas, coerceLegacyAppliedStage). They use the
-- public data tables defined earlier in this file.

-- Stage ordering for cascade traversal (descent walks STAGE_ORDER[prev+1..target];
-- recovery walks reverse: STAGE_ORDER[prev..target+1]).
local STAGE_ORDER = { "stable", "shaken", "hollow", "numb", "broken" }
local STAGE_INDEX = { stable = 1, shaken = 2, hollow = 3, numb = 4, broken = 5 }

-- Maps thematic stageKey -> the legacy STAGE_THRESHOLDS key for this stage's entry threshold.
-- Used in the recovery hysteresis check: exit threshold = STAGE_THRESHOLDS[STAGE_THRESHOLD_KEY[stage]] + HYSTERESIS_BUFFER.
-- "stable" intentionally absent — recovering UP to stable has no entry threshold.
local STAGE_THRESHOLD_KEY = {
    shaken = "sad",          -- 750 + 50 = 800 to exit Shaken → Stable
    hollow = "depressed",    -- 500 + 50 = 550 to exit Hollow → Shaken
    numb   = "traumatized",  -- 250 + 50 = 300 to exit Numb   → Hollow
    broken = "desensitized", -- 50  + 50 = 100 -- intentionally never used (D-32: Broken→Numb impossible because D-36 disables system)
}

-- ── D-44 (lazy migration): coerce legacy `appliedStage` strings ──────────────
-- Phase 1 seeded "Healthy" before Phase 01.1's thematic rename. First evaluator call after
-- each load normalizes the field. If the value is already thematic, returns as-is. Unknown
-- values fall back to computeStage(currentSanity) — recovers from any corruption gracefully.
local function coerceLegacyAppliedStage(rawAppliedStage, currentSanity)
    -- Already a thematic key (defined in STAGE_NAMES from 1_SanityTraits_Init.lua)
    if rawAppliedStage and SanityTraits.STAGE_NAMES[rawAppliedStage] then
        return rawAppliedStage
    end
    -- Legacy string with known mapping?
    local coerced = SanityTraits.LEGACY_APPLIEDSTAGE_COERCION[rawAppliedStage]
    if coerced then return coerced end
    -- Unknown / corrupted: recompute from current sanity. Loses transition history but
    -- produces a self-consistent state.
    return SanityTraits.computeStage(currentSanity)
end

-- ── DEF-02 / DEF-03 idempotent helpers (Pattern 2) ───────────────────────────
-- applyTrait: idempotent add. Skips both the engine-add AND the appliedTraits push if
-- the player ALREADY has the trait — this means a player-picked trait at character
-- creation does NOT get marked as mod-applied, so the lower-stage recovery stack-pop
-- (Pattern 6) won't remove it. (D-33 Broken blanket-removal removes player-picked
-- variants explicitly via STAGE_TRAIT_REMOVAL_ON_BROKEN — that's the only stage that does.)
-- Returns true if a NEW application happened, false if already-present.
local function applyTrait(player, traitId, stageKey)
    if player:HasTrait(traitId) then
        -- Already present — could be (a) we already applied it, (b) player picked at creation,
        -- (c) another mod applied. Don't double-add and don't claim ownership.
        return false
    end
    player:getTraits():add(traitId)
    local md = player:getModData().SanityTraits
    table.insert(md.appliedTraits, {
        traitId        = traitId,
        appliedAtStage = stageKey,
        appliedAtTime  = getTimestampMs(),
    })
    -- D-29 (Phase 01.2 hook): individual trait acquisition counter
    SanityTraits.bumpCounter("traitsAcquired." .. traitId, 1)
    return true
end

-- removeTrait: idempotent remove. ALWAYS prunes appliedTraits entries with matching traitId,
-- even if HasTrait was false (handles case where we never recorded it but the trait exists,
-- or D-33 blanket-remove of a player-picked trait that has no appliedTraits record).
-- Does NOT bump any counter — D-39: stage-trait-removals are silent on counter side.
-- Returns true if engine-remove happened (player had the trait), false otherwise.
local function removeTrait(player, traitId)
    local removed = false
    if player:HasTrait(traitId) then
        player:getTraits():remove(traitId)
        removed = true
    end
    local md = player:getModData().SanityTraits
    if md and md.appliedTraits then
        -- Reverse iteration so table.remove doesn't mess with indexes
        for i = #md.appliedTraits, 1, -1 do
            if md.appliedTraits[i].traitId == traitId then
                table.remove(md.appliedTraits, i)
            end
        end
    end
    return removed
end

-- ── Phase 5 / D-58: addiction trait IDs that PERSIST through stage recovery and Broken transitions ──
-- These IDs survive removeStageTraits's stack-pop (skipped via the gate inside the iteration below)
-- AND survive applyBrokenStage's blanket-remove (the Plan 05-03 amend to STAGE_TRAIT_REMOVAL_ON_BROKEN
-- omits these IDs from the list). Net behavior: addictions are the one record that survives Broken,
-- mechanically implementing the project Core Value "permanent trait consequences that feel earned."
-- Per D-56 AMENDED (Plan 05-01): `base:smoker` is the cigarette-addiction outcome (vanilla, not sanitymod).
local ADDICTION_TRAIT_IDS = {
    ["base:smoker"]                     = true,   -- cigarette addiction (vanilla; per ROADMAP / D-56 AMENDED)
    ["sanitymod:alcoholic"]             = true,   -- defined in character_traits_sanitytraits.txt (Plan 05-02)
    ["sanitymod:painkiller_dependent"]  = true,   -- same
}

-- ── D-39 stack-pop helper: remove only mod-applied traits for the exiting stage ──
-- Iterates appliedTraits, finds entries matching stageKey, calls removeTrait for each.
-- Two-pass (collect IDs then remove) so we don't mutate appliedTraits while iterating.
-- Player-picked traits (which were never pushed to appliedTraits per applyTrait's guard)
-- are NOT removed by this helper — only by D-33 blanket-removal at Broken.
local function removeStageTraits(player, stageKey)
    local md = player:getModData().SanityTraits
    if not md or not md.appliedTraits then return 0 end
    local toRemove = {}
    for _, entry in ipairs(md.appliedTraits) do
        if entry.appliedAtStage == stageKey
           and not ADDICTION_TRAIT_IDS[entry.traitId] then   -- D-58 persistence (Plan 05-03)
            toRemove[#toRemove + 1] = entry.traitId
        end
    end
    local count = 0
    for _, traitId in ipairs(toRemove) do
        if removeTrait(player, traitId) then count = count + 1 end
    end
    return count
end

-- ── D-33 + D-40 Broken application: blanket-removal then desensitized apply ──
-- Three-source removal (per RESEARCH Pattern 7):
--   1. Canonical conflict list (vanilla MutuallyExclusiveTraits)
--   2. Every prior-stage trait the mod applied (or player picked — see D-33)
--   3. Phase 5 addiction traits (defensive — DEF-03 guard makes calls safe even
--      when sanitymod:* IDs are unregistered)
--
-- All three sources are pre-merged into SanityTraits.STAGE_TRAIT_REMOVAL_ON_BROKEN
-- (defined earlier in this file by Plan 02). Iterate that list.
--
-- After removal: apply base:desensitized via applyTrait (which records the entry
-- in appliedTraits with appliedAtStage="broken"). bumpCounter("stageDescents.toBroken").
-- The next event tick will see HasTrait("base:desensitized")=true → isSystemDisabled
-- returns true → kill handlers + evaluator early-return forever (D-40 monument).
--
-- Returns count of traits actually removed by the three-source blanket pass.
--
-- NOTE on Pitfall 5 (defensive pcall): Wave 0 (02-01-SUMMARY.md) confirmed
-- defensive_pcall_needed=false (HasTrait on unregistered IDs returns false cleanly,
-- no Java warning). Direct removeTrait call below is safe.
local function applyBrokenStage(player)
    local md = player:getModData().SanityTraits
    local removed = 0
    for _, traitId in ipairs(SanityTraits.STAGE_TRAIT_REMOVAL_ON_BROKEN) do
        if removeTrait(player, traitId) then removed = removed + 1 end
    end
    -- Clear addictionProne (defensive — Hollow's path may have set it; at Broken
    -- there's no path to addiction since system disables next tick).
    md.addictionProne = false
    -- Apply base:desensitized via the standard helper so:
    --   * appliedTraits entry is recorded with appliedAtStage="broken" (debuff row shows the lone monument icon)
    --   * traitsAcquired.base:desensitized counter bumps once (D-29 hook + D-40 monument)
    applyTrait(player, "base:desensitized", "broken")
    -- D-29 hook: descent counter for this stage (the LAST counter-bump for this character;
    -- isSystemDisabled trips on the next tick → no further bumpCounter calls forever).
    SanityTraits.bumpCounter("stageDescents.toBroken", 1)
    return removed
end

-- ── Cascade walker (Pattern 4 + 5) ───────────────────────────────────────────
-- Walks from prevStage to targetStage. Direction determined by STAGE_INDEX comparison.
--   Descent (target > prev): walk prev+1..target, applying each stage's traits, bumping
--                            descent counter, setting addictionProne at Hollow entry,
--                            calling applyBrokenStage at Broken (special path).
--   Recovery (target < prev): walk prev..target+1 in REVERSE, removing each stage's
--                             mod-applied traits (Pattern 6), clearing addictionProne
--                             at Hollow exit, applying hysteresis check on each step.
--                             Hysteresis failure pins appliedStage at the current
--                             exiting stage (recovery stops short of the computed target).
--
-- Returns (added, removed) counts for the console.txt receipt.
-- May override md.appliedStage if hysteresis blocks recovery (caller checks).
local function applyStageDeltas(player, prevStage, targetStage)
    local prev   = STAGE_INDEX[prevStage]
    local target = STAGE_INDEX[targetStage]
    local md     = player:getModData().SanityTraits
    local sanity = md.sanity
    local added, removed = 0, 0

    if target > prev then
        -- DESCENT: walk prev+1 → target inclusive
        for i = prev + 1, target do
            local stageKey = STAGE_ORDER[i]
            if stageKey == "broken" then
                -- D-40 monument path: blanket-removal + desensitized apply
                removed = removed + applyBrokenStage(player)
                added = added + 1   -- the desensitized apply counts as +1
            else
                -- Generic descent: apply this stage's trait set
                local traits = SanityTraits.STAGE_TRAITS[stageKey] or {}
                for _, traitId in ipairs(traits) do
                    if applyTrait(player, traitId, stageKey) then
                        added = added + 1
                    end
                end
                -- D-34: at Hollow entry, set addictionProne (Phase 5 reads this flag)
                if stageKey == "hollow" then
                    md.addictionProne = true
                end
                -- D-29 (Phase 01.2 hook): descent counter
                local descentKey = SanityTraits.STAGE_DESCENT_KEY[stageKey]
                if descentKey then
                    SanityTraits.bumpCounter("stageDescents." .. descentKey, 1)
                end
            end
        end
    elseif target < prev then
        -- RECOVERY: walk prev → target+1 in REVERSE (removing each stage as we exit it).
        -- Hysteresis (D-32): for each step "exit stage X to recover toward stage X-1",
        -- check that sanity > entryThresholdOf(X) + HYSTERESIS_BUFFER. If not, stop.
        -- Pin appliedStage at the stage we're currently still in.
        for i = prev, target + 1, -1 do
            local exitingStageKey = STAGE_ORDER[i]
            local thresholdKey = STAGE_THRESHOLD_KEY[exitingStageKey]
            -- Phase 4 / Plan 03 (OCC-01): profile-shifted entry threshold per D-50 Edit 2.
            -- HARDENED's -150 shift means Shaken-exit at sanity > 600+50=650 (was 800);
            -- FRAGILE's +75 shift means Shaken-exit at sanity > 825+50=875 (was 800).
            -- HYSTERESIS_BUFFER (+50) at line 332 below stays a flat constant, not threshold-derived.
            local thresholds = SanityTraits.getStageThresholds(player)
            local entryThreshold = thresholdKey and thresholds[thresholdKey]
            if entryThreshold and sanity <= (entryThreshold + SanityTraits.HYSTERESIS_BUFFER) then
                -- HYSTERESIS BLOCK: pin appliedStage at exitingStageKey and stop.
                -- (Pitfall 4: comparison is `<=` for block, equivalent to `> threshold+buffer`
                --  for allow. Sanity exactly equal to threshold+buffer does NOT exit.)
                md.appliedStage = exitingStageKey
                return added, removed
            end
            -- Hysteresis passed — actually exit this stage
            removed = removed + removeStageTraits(player, exitingStageKey)
            -- D-39: at Hollow exit, clear addictionProne (whether or not addiction trait was applied;
            -- if it was, removeStageTraits above already removed it as part of stack-pop)
            if exitingStageKey == "hollow" then
                md.addictionProne = false
            end
            -- D-39: NO bumpCounter on recovery (recoveries counter is Phase 3's territory)
        end
    end
    -- target == prev case is handled by the no-op early-return in the caller (no work here)
    return added, removed
end

-- ── Public evaluator (Hook Contract 1) ───────────────────────────────────────
-- Reconciles md.SanityTraits.appliedStage with the stage implied by md.SanityTraits.sanity.
-- Idempotent: same sanity, same stage → no-op (but normalizes legacy appliedStage strings).
-- D-36 off-switch: early-return if HasTrait("base:desensitized").
--
-- Side effects (per Hook Contract 1 in RESEARCH.md):
--   1. May call player:getTraits():add/remove(traitId)
--   2. Mutates md.SanityTraits.appliedStage (always to a thematic key after first call)
--   3. Mutates md.SanityTraits.appliedTraits (push on apply, filter on remove)
--   4. Mutates md.SanityTraits.addictionProne (set/clear at Hollow boundary; clear at Broken)
--   5. Calls SanityTraits.bumpCounter("stageDescents.<key>") on each descent step
--   6. Calls SanityTraits.bumpCounter("traitsAcquired.<traitId>") on each new apply
--   7. Prints one [SanityTraits] stage transition line per evaluator-call-with-work
--   8. Does NOT mutate md.SanityTraits.sanity (caller owns sanity arithmetic)
--
-- Callers:
--   * Plan 05: 3_SanityTraits_KillEvents.lua / onZombieDead, onWeaponHitXp (after sanity decrement)
--   * Future Phase 3: EveryTenMinutes decay handler (after each drain pass)
function SanityTraits.evaluateStageTransitions(player)
    -- D-36 master invariant. Catches Veteran (vanilla GrantedTraits), char-creation desensitized
    -- pick, modded "hardened" professions, and the Broken-application path (after evaluator
    -- applies base:desensitized, subsequent ticks return immediately).
    if SanityTraits.isSystemDisabled(player) then return end

    local md = player:getModData().SanityTraits
    if not md then return end   -- defensive: shouldn't happen post-OnCreatePlayer

    local currentSanity  = md.sanity
    local prevStageKey   = coerceLegacyAppliedStage(md.appliedStage, currentSanity)
    local targetStageKey = SanityTraits.computeStage(currentSanity)

    if prevStageKey == targetStageKey then
        -- No-op: stage hasn't changed. Normalize legacy "Healthy" → "stable" if needed
        -- (one-time per character; subsequent calls have already-thematic value).
        if md.appliedStage ~= prevStageKey then
            md.appliedStage = prevStageKey
        end
        return
    end

    -- Cascade through intermediate stages (descent or recovery — direction handled inside)
    local added, removed = applyStageDeltas(player, prevStageKey, targetStageKey)

    -- If applyStageDeltas hit a hysteresis block during recovery, it already pinned
    -- md.appliedStage to the still-exiting stage and returned early. Detect that case
    -- by re-reading md.appliedStage: if it's already different from prevStageKey, the
    -- hysteresis-pin happened. Otherwise, set it to the computed target.
    if md.appliedStage == prevStageKey then
        md.appliedStage = targetStageKey
    end
    -- (else: applyStageDeltas already pinned it to the hysteresis-stop stage; respect that)

    print(SanityTraits.LOG_TAG .. " stage transition: " .. tostring(prevStageKey)
        .. " -> " .. tostring(md.appliedStage)
        .. " (sanity=" .. tostring(currentSanity) .. ")"
        .. " traits added=" .. tostring(added)
        .. " removed=" .. tostring(removed))
end

print(SanityTraits.LOG_TAG .. " Stages evaluator loaded")


-- ════════════════════════════════════════════════════════════════════════════
-- Phase 5 / Plan 05-03: Addiction evaluation and application helpers
-- ════════════════════════════════════════════════════════════════════════════
-- Public surface added by this plan:
--   SanityTraits.evaluateAddictions(player) — called from applyStageDeltas at Hollow
--   entry (Task 4) or from consumption event handlers in Plan 05-04.
--
-- Private file-local helper:
--   applyRandomAddiction(player) — determines which addiction trait to apply based
--   on consumption history counters.

-- ── applyRandomAddiction: Private helper for selecting and applying addiction trait
-- Determines which of the three addiction traits to apply based on consumption history.
-- Re-entry guard: if player already has any addiction trait, returns nil immediately.
-- If total consumption counter < ADDICTION_MIN_THRESHOLD, uses ZombRand(3) fallback.
-- Otherwise, weighted random selection based on relative usage counts.
-- Defensive mutex removal (base:athletic, base:obese) before applying base:smoker.
-- Returns the applied trait ID (base:smoker, sanitymod:alcoholic, or sanitymod:painkiller_dependent),
-- or nil if guard skipped.
local function applyRandomAddiction(player)
    local md = player:getModData().SanityTraits
    if not md then return nil end

    -- Re-entry guard: if any addiction trait already present, skip application
    if player:HasTrait("base:smoker")
       or player:HasTrait("sanitymod:alcoholic")
       or player:HasTrait("sanitymod:painkiller_dependent") then
        return nil
    end

    -- Consumption history counters (bumped by Plan 05-04 event handlers)
    local cigarCount    = md.counters.consumptionCigarettes or 0
    local alcoholCount  = md.counters.consumptionAlcohol or 0
    local pillCount     = md.counters.consumptionPills or 0
    local totalCount    = cigarCount + alcoholCount + pillCount

    -- Random selection: weighted by usage counts, or uniform fallback if below threshold
    local choice
    if totalCount < SanityTraits.ADDICTION_MIN_THRESHOLD then
        -- No clear history: random fallback (ZombRand returns 0-2)
        choice = ZombRand(3)
    else
        -- Weighted random: pick based on relative usage
        local r = ZombRand(totalCount)
        if r < cigarCount then
            choice = 0  -- cigarette
        elseif r < cigarCount + alcoholCount then
            choice = 1  -- alcohol
        else
            choice = 2  -- painkiller
        end
    end

    -- Select and apply the trait
    local traitId
    if choice == 0 then
        -- Cigarette addiction: base:smoker (vanilla per ROADMAP / D-56 AMENDED)
        traitId = "base:smoker"
        -- Defensive mutex removal: base:athletic and base:obese are incompatible with base:smoker
        if player:HasTrait("base:athletic") then
            player:getTraits():remove("base:athletic")
        end
        if player:HasTrait("base:obese") then
            player:getTraits():remove("base:obese")
        end
    elseif choice == 1 then
        -- Alcohol addiction (registered in Plan 05-02)
        traitId = "sanitymod:alcoholic"
    else
        -- Painkiller addiction (registered in Plan 05-02)
        traitId = "sanitymod:painkiller_dependent"
    end

    -- Apply via applyTrait helper (records in appliedTraits, bumps traitsAcquired counter)
    applyTrait(player, traitId, "hollow")
    return traitId
end

-- ── Public evaluator: SanityTraits.evaluateAddictions(player) ──────────────────
-- Hook Contract 2 (Phase 5): Evaluates and applies addiction traits when player
-- reaches Hollow stage and addictionProne is set to true.
-- Called from:
--   * applyStageDeltas at Hollow entry (Task 4 insertion)
--   * Consumption event handlers in Plan 05-04 (timed action patches)
--
-- Returns the applied trait ID (base:smoker, sanitymod:alcoholic, sanitymod:painkiller_dependent),
-- or nil if skipped (re-entry guard or addictionProne not set).
--
-- Side effects:
--   * May call player:getTraits():add/remove(traitId) via applyRandomAddiction
--   * Mutates md.appliedTraits (via applyTrait push)
--   * Bumps SanityTraits.bumpCounter("traitsAcquired.<traitId>") via applyTrait
--   * Prints one [SanityTraits] line to console.txt on successful apply
function SanityTraits.evaluateAddictions(player)
    local md = player:getModData().SanityTraits
    if not md or not md.addictionProne then return nil end

    -- Re-entry guard: if any addiction trait already present, skip
    if player:HasTrait("base:smoker")
       or player:HasTrait("sanitymod:alcoholic")
       or player:HasTrait("sanitymod:painkiller_dependent") then
        return nil
    end

    local appliedTraitId = applyRandomAddiction(player)
    if appliedTraitId then
        print(SanityTraits.LOG_TAG .. " addiction applied: " .. tostring(appliedTraitId))
    end
    return appliedTraitId
end

print(SanityTraits.LOG_TAG .. " Addiction helpers loaded")
