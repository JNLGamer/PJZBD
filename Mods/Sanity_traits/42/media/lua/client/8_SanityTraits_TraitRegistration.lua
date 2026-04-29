-- Sanity_traits / 8_SanityTraits_TraitRegistration.lua
-- Phase 5 / Plan 02: Defensive Lua TraitFactory fallback for the 2 sanitymod addiction traits.
--
-- Loaded LAST among client lua files (numeric prefix "8_" sorts after 1_-7_*) so that
-- when Events.OnGameBoot fires, the .txt parser has had its chance to register the
-- traits declaratively (Mods/Sanity_traits/42/media/scripts/character_traits_sanitytraits.txt).
--
-- Why both paths in parallel? Per RESEARCH Open Q #2: B42's .txt parser auto-loads
-- mod scripts on game start (verified pattern), but the documentation does not give
-- a HIGH-confidence guarantee for mod-side .txt files (vs vanilla scripts/generated/).
-- This handler runs IDEMPOTENTLY: it queries TraitFactory.getTrait(id) first; if the
-- trait is already registered (by the .txt parser, which is the canonical B42 path),
-- the addTrait call is skipped. If the .txt parser missed the trait for any reason
-- (mod-script case-sensitivity, parse error, B42 build regression), this handler
-- registers them defensively so Plan 05-03's evaluateAddictions doesn't silently
-- fail at applyTrait.
--
-- Per autonomous-mode authorization (no F11 user smoke tests): both registration
-- paths are populated; whichever the engine honors wins, the other becomes a no-op.
--
-- Cigarette addiction = vanilla base:smoker (per ROADMAP / D-56 AMENDED, Plan 05-01).
-- Vanilla base:smoker is engine-shipped — NEVER attempt to TraitFactory.addTrait it.

-- Trait registration data: id, display name, description.
-- Display strings are passed directly to addTrait so the legacy Lua API works even
-- if the translation .txt files are not read by the engine (third defensive layer).
-- These display strings MUST match the values in Trait_EN.txt / UI_EN.txt.
local SANITYMOD_TRAITS = {
    {
        id          = "sanitymod:alcoholic",
        name        = "Alcoholic",
        cost        = 0,
        description = "When everything fell apart, the bottle helped you stand. It still does. You can't put it down.",
    },
    {
        id          = "sanitymod:painkiller_dependent",
        name        = "Painkiller-Dependent",
        cost        = 0,
        description = "Pain — physical, emotional, or both — became something to medicate. The pills are part of you now.",
    },
}

local function registerSanitymodTraits()
    if not TraitFactory then
        print(SanityTraits.LOG_TAG .. " TraitRegistration: TraitFactory unavailable; skipping defensive registration")
        return
    end
    local registered = 0
    local skipped = 0
    for _, t in ipairs(SANITYMOD_TRAITS) do
        local existing = nil
        if TraitFactory.getTrait then
            existing = TraitFactory.getTrait(t.id)
        end
        if existing then
            -- .txt parser already registered (canonical path) — defensive layer is no-op.
            skipped = skipped + 1
        else
            -- TraitFactory.addTrait(id, name, cost, description, isProfession, removeInMP)
            -- isProfession=true hides from char-creation picker (mod-applied at runtime only).
            -- removeInMP=false: mod is SP-only but the field default keeps the contract honest.
            TraitFactory.addTrait(t.id, t.name, t.cost, t.description, true, false)
            registered = registered + 1
            print(SanityTraits.LOG_TAG .. " TraitRegistration: defensive Lua registration of "
                .. t.id .. " (.txt parser missed it)")
        end
    end
    print(SanityTraits.LOG_TAG .. " TraitRegistration: "
        .. tostring(registered) .. " registered defensively, "
        .. tostring(skipped) .. " already present from .txt parser")
end

Events.OnGameBoot.Add(registerSanitymodTraits)

print(SanityTraits.LOG_TAG .. " TraitRegistration loader: OnGameBoot handler installed (defensive fallback)")
