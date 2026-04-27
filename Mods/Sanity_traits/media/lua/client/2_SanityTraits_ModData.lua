-- Sanity_traits / 2_SanityTraits_ModData.lua
-- Phase 1 / Plan 02: Per-character sanity meter init via OnCreatePlayer.
-- Loaded after 1_SanityTraits_Init.lua (alphabetical/numeric prefix order).
-- Source: .planning/phases/01-foundation/01-RESEARCH.md Patterns 2 & 5

-- Profession archetype starting sanity (Phase 1 seed; Phase 4 will replace with full 24-profession psyche profile table)
-- Source: 01-RESEARCH.md Pattern 5; profession ids verified in reference/occupations.md
SanityTraits.STARTING_SANITY_BY_PROFESSION = {
    ["base:veteran"]       = 200,   -- starts near-desensitized (CORE-02 / OCC-02 seed; Phase 4 will mark stage)
    ["base:policeofficer"] = 850,   -- military/police archetype (OCC-03)
    ["base:securityguard"] = 850,   -- military/police archetype (OCC-03)
    ["base:fireofficer"]   = 850,   -- military/police archetype (OCC-03)
    ["base:doctor"]        = 900,   -- medical archetype (OCC-04)
    ["base:nurse"]         = 900,   -- medical archetype (OCC-04)
    ["base:parkranger"]    = 900,   -- medical-adjacent archetype (OCC-04)
}

-- Returns starting sanity for a profession; falls back to SANITY_MAX (1000) for unknown/civilian/modded professions (OCC-05)
function SanityTraits.getStartingSanity(profName)
    if profName == nil then return SanityTraits.SANITY_MAX end
    return SanityTraits.STARTING_SANITY_BY_PROFESSION[profName] or SanityTraits.SANITY_MAX
end
