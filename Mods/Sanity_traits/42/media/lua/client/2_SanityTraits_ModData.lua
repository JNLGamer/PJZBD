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

-- OnCreatePlayer handler — initializes / upgrades per-character SanityTraits ModData.
-- Fires for BOTH new characters and loaded saves.
--   * New character: seeds full Phase 01.2 ModData shape (sanity, appliedStage, profession,
--                    appliedTraits, counters). The deprecated `log` field is NOT seeded.
--   * Loaded save:   idempotently adds missing `appliedTraits` (Phase 1 -> 01.1 migration)
--                    and `counters` (Phase 01.1 -> 01.2 migration). Old `log` field on
--                    Phase 01.1 saves is left in place (zero functional impact per CONTEXT
--                    D-27 + RESEARCH Discretion #4).
--   * Both:          re-zero `touchedAt` and `seenAt` under all counter cells (Pitfall 4
--                    mitigation — getTimestampMs is wall-clock-since-launch, not save-stable).
-- Source: 01-RESEARCH.md Pattern 2; 01.2-RESEARCH.md Pattern 6 + Pitfall 4
local function onCreatePlayer(playerIndex, player)
    if not player then return end
    local md = player:getModData()

    if md.SanityTraits == nil then
        -- New character path. Pitfall 2 guard: getCharacterProfession() can be nil very early.
        local profName = nil
        local desc = player:getDescriptor()
        if desc and desc:getCharacterProfession() then
            profName = desc:getCharacterProfession():getName()
        end

        local startSanity = SanityTraits.getStartingSanity(profName)

        md.SanityTraits = {
            sanity        = startSanity,
            appliedStage  = "Healthy",
            profession    = profName or "unknown",
            appliedTraits = {},   -- D-17: list of traits this mod has applied (populated by Phase 2)
            counters      = {     -- Phase 01.2 D-29: aggregated counter tree
                zombiesKilled    = { count = 0 },
                survivorsKilled  = { count = 0 },
                stageDescents    = {
                    toShaken  = { count = 0 },
                    toHollow  = { count = 0 },
                    toNumb    = { count = 0 },
                    toBroken  = { count = 0 },
                },
                traitsAcquired   = {},   -- dynamic keys; auto-vivified by SanityTraits.bumpCounter
                recoveries       = { count = 0 },   -- Phase 3+ populates
            },
        }

        print(SanityTraits.LOG_TAG .. " OnCreatePlayer: profession=" .. tostring(profName)
            .. " startingSanity=" .. tostring(startSanity))
    else
        -- Loaded save. Idempotently upgrade missing fields (Phase 1 -> 01.1 migration).
        -- Do NOT touch sanity, appliedStage, or profession — those persist as-is.
        local upgraded = false
        if md.SanityTraits.log == nil then
            md.SanityTraits.log = {}
            upgraded = true
        end
        if md.SanityTraits.appliedTraits == nil then
            md.SanityTraits.appliedTraits = {}
            upgraded = true
        end
        if upgraded then
            print(SanityTraits.LOG_TAG .. " OnCreatePlayer: upgraded existing save with log/appliedTraits fields")
        end
    end
end

Events.OnCreatePlayer.Add(onCreatePlayer)
