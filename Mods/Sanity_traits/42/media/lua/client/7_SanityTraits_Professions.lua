-- Sanity_traits / 7_SanityTraits_Professions.lua
-- Phase 4 / Plan 02: Profession-keyed psyche profile dispatch table + lookup helpers.
-- Loaded LAST among client/ scripts (numeric prefix 7; phases 1-3 took 1-6).
-- Source: .planning/phases/04-occupation-profiles/04-CONTEXT.md D-48..D-54 (post-04-01 amendment)
-- Source: .planning/phases/04-occupation-profiles/04-RESEARCH.md Pattern 1 + Pattern 2
--
-- Public surface:
--   SanityTraits.PROFESSION_PROFILES        — table[profName] -> { startingSanity, thresholdShift, decayMultiplier, killWeightMultiplier, bucket }
--   SanityTraits.getProfessionProfile(s)    — string-form lookup (used at OnCreatePlayer)
--   SanityTraits.getProfessionProfileForPlayer(p) — player-form lookup (Pitfall 2 nil-safe)
--   SanityTraits.getStageThresholds(p)      — fresh shifted table per call (D-50 Edit 2 consumer)
--   SanityTraits.getEffectiveDecayRate(p,k) — floor-of-1 when base>0 (D-50 Edit 3 consumer)
--
-- D-48 5-field profile shape (amended 2026-04-29 per ROADMAP Success Criterion #2):
--   killWeightMultiplier was added to satisfy ROADMAP "Police Officer 0.7-0.85x kill modifier"
--   after RESEARCH proved decayMultiplier can't affect kill events. Per-bucket defaults set
--   killWeightMultiplier == decayMultiplier so the unified-knob intent is preserved.
--
-- D-37 invariant: this file introduces ZERO new sanity-clamps. The single rate-floor
-- (math.max with operand=1) in getEffectiveDecayRate is a RATE-floor (operand: decay rate),
-- NOT a sanity-clamp (operand: sanity). Sanity clamps remain confined to SANITY_MIN/MAX in
-- 3_*.lua and 6_*.lua only.
--
-- D-53: helpers re-read the profile every call (no ModData caching) so mid-run profession
-- changes via mods take effect at next tick. Lookup is O(1) hash-table read.

SanityTraits.PROFESSION_PROFILES = {
    -- ── HARDENED bucket (5) — CONTEXT D-49 ──
    -- D-54: Veteran's entry is documentation-only at runtime (D-36 off-switch fires first via
    -- vanilla GrantedTraits = base:desensitized). Recorded for the niche case where another
    -- mod strips the desensitized grant before spawn — that Veteran still plays as HARDENED
    -- instead of falling through to AVERAGE.
    ["base:veteran"]            = { startingSanity = 1000, thresholdShift = -150, decayMultiplier = 0.7,  killWeightMultiplier = 0.7,  bucket = "hardened" },
    ["base:policeofficer"]      = { startingSanity = 1000, thresholdShift = -150, decayMultiplier = 0.7,  killWeightMultiplier = 0.7,  bucket = "hardened" },
    ["base:securityguard"]      = { startingSanity = 1000, thresholdShift = -150, decayMultiplier = 0.7,  killWeightMultiplier = 0.7,  bucket = "hardened" },
    ["base:fireofficer"]        = { startingSanity = 1000, thresholdShift = -150, decayMultiplier = 0.7,  killWeightMultiplier = 0.7,  bucket = "hardened" },
    ["base:parkranger"]         = { startingSanity = 1000, thresholdShift = -150, decayMultiplier = 0.7,  killWeightMultiplier = 0.7,  bucket = "hardened" },

    -- ── SCHOLAR bucket (2) — CONTEXT D-49 ──
    ["base:doctor"]             = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 0.95, killWeightMultiplier = 0.95, bucket = "scholar" },
    ["base:nurse"]              = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 0.95, killWeightMultiplier = 0.95, bucket = "scholar" },

    -- ── ENTERTAINER bucket (2) — CONTEXT D-49 ──
    ["base:burglar"]            = { startingSanity = 1000, thresholdShift =  -50, decayMultiplier = 0.85, killWeightMultiplier = 0.85, bucket = "entertainer" },
    ["base:fitnessinstructor"]  = { startingSanity = 1000, thresholdShift =  -50, decayMultiplier = 0.85, killWeightMultiplier = 0.85, bucket = "entertainer" },

    -- ── FRAGILE bucket (3) — CONTEXT D-49 ──
    ["base:chef"]               = { startingSanity =  950, thresholdShift =   75, decayMultiplier = 1.3,  killWeightMultiplier = 1.3,  bucket = "fragile" },
    ["base:burgerflipper"]      = { startingSanity =  950, thresholdShift =   75, decayMultiplier = 1.3,  killWeightMultiplier = 1.3,  bucket = "fragile" },
    ["base:tailor"]             = { startingSanity =  950, thresholdShift =   75, decayMultiplier = 1.3,  killWeightMultiplier = 1.3,  bucket = "fragile" },

    -- ── AVERAGE bucket (13) — CONTEXT D-49 baseline ──
    ["base:unemployed"]         = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },
    ["base:smither"]            = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },
    ["base:engineer"]           = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },
    ["base:mechanics"]          = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },
    ["base:metalworker"]        = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },
    ["base:carpenter"]          = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },
    ["base:constructionworker"] = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },
    ["base:electrician"]        = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },
    ["base:fisherman"]          = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },
    ["base:repairman"]          = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },
    ["base:farmer"]             = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },
    ["base:lumberjack"]         = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },
    ["base:rancher"]            = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },

    -- ── Default fallback for modded / unrecognized professions (D-52) ──
    -- Mirrors AVERAGE bucket values so modded characters get baseline behavior, never a stall.
    _default                    = { startingSanity = 1000, thresholdShift =    0, decayMultiplier = 1.0,  killWeightMultiplier = 1.0,  bucket = "average" },
}
-- Total: 25 vanilla + _default. Bucket-count: 5+2+2+3+13 = 25 ✓

-- D-52: module-local set; first call per session per unknown profName logs once.
-- Lives at file scope so subsequent profession lookups in the same session see the same
-- dedupe table. Cleared only by mod reload / game restart.
local _warnedProfessions = {}

-- ── String-form lookup ───────────────────────────────────────────────────────
-- Used at OnCreatePlayer where `profName` is already a local (player object's descriptor
-- chain has already been resolved by 04-03 Edit 1). Returns _default + warns ONCE per
-- unknown profession id per session (D-52). Never returns nil.
function SanityTraits.getProfessionProfile(profName)
    local profile = SanityTraits.PROFESSION_PROFILES[profName]
    if profile then return profile end
    if profName and not _warnedProfessions[profName] then
        print(SanityTraits.LOG_TAG .. " profile fallback: unknown profession " .. tostring(profName))
        _warnedProfessions[profName] = true
    end
    return SanityTraits.PROFESSION_PROFILES._default
end

-- ── Player-form lookup ───────────────────────────────────────────────────────
-- Used by getStageThresholds + getEffectiveDecayRate + 04-03 Edit 4 kill handlers.
-- Defensive nil-guard chain mirrors Phase 1 Pitfall 2 (getCharacterProfession() can be nil
-- very early in OnCreatePlayer). Pattern copied from 2_SanityTraits_ModData.lua:56-61.
-- Always returns a profile table (never nil) so callers can safely index .thresholdShift etc.
function SanityTraits.getProfessionProfileForPlayer(player)
    if not player then return SanityTraits.PROFESSION_PROFILES._default end
    local desc = player:getDescriptor()
    if not desc then return SanityTraits.PROFESSION_PROFILES._default end
    local prof = desc:getCharacterProfession()
    if not prof then return SanityTraits.PROFESSION_PROFILES._default end
    local profName = prof:getName()
    return SanityTraits.getProfessionProfile(profName)
end

-- ── D-50 Edit 2 consumer: profile-shifted stage thresholds ───────────────────
-- Returns a FRESH table per call (allocation cost is one 4-key Lua table at the 10-minute
-- event cadence — negligible). The BASE table SanityTraits.STAGE_THRESHOLDS is NEVER mutated.
-- A FRAGILE character (thresholdShift=+75) gets entry thresholds 825/575/325/125 instead of
-- the global 750/500/250/50; HARDENED (-150) gets 600/350/100/-100.
function SanityTraits.getStageThresholds(player)
    local profile = SanityTraits.getProfessionProfileForPlayer(player)
    local shift = profile.thresholdShift or 0
    local base = SanityTraits.STAGE_THRESHOLDS
    return {
        sad          = base.sad          + shift,
        depressed    = base.depressed    + shift,
        traumatized  = base.traumatized  + shift,
        desensitized = base.desensitized + shift,
    }
end

-- ── D-50 Edit 3 consumer: profile-multiplied per-tick decay rate ─────────────
-- D-37 strict-no-clamping: the rate-floor below (math.max with floor-of-1 operand) is a
-- RATE-floor (operand: decay rate), NOT a sanity-clamp (operand: sanity). A new rate-floor
-- is permitted per CONTEXT amendment; new sanity-clamps remain forbidden. The only sanity
-- clamps remain SANITY_MIN/MAX in 3_*.lua + 6_*.lua.
--
-- Pitfall 5 / Discretion §Floor-of-1: floor-of-1 ONLY when source rate > 0. Preserves the
-- "broken" stage short-circuit (DECAY_RATE_BY_STAGE has no `broken` key → table read yields
-- nil → `or 0` yields 0 → early return 0). Without the `if base <= 0` guard, the rate-floor
-- would force broken to drain at 1/tick, contradicting D-36 isSystemDisabled semantics.
function SanityTraits.getEffectiveDecayRate(player, stageKey)
    local base = SanityTraits.DECAY_RATE_BY_STAGE[stageKey] or 0
    if base <= 0 then return 0 end  -- preserves "broken" stage short-circuit (table absence -> 0)
    local profile = SanityTraits.getProfessionProfileForPlayer(player)
    local profMul = profile.decayMultiplier or 1.0
    -- Phase 6 / CORE-07: sandbox override multiplier composes with profession multiplier.
    local sandboxMul = SanityTraits.SANDBOX_DECAY_MULT or 1.0
    return math.max(1, math.floor(base * profMul * sandboxMul + 0.5))
end

print(SanityTraits.LOG_TAG .. " 7_SanityTraits_Professions loaded: 26 profile rows (25 vanilla + _default)")
