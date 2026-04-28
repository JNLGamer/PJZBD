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

print(SanityTraits.LOG_TAG .. " Init loaded (v" .. SanityTraits.VERSION .. ")")
