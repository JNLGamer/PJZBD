-- ProfessionFramework trait example (3rd-party framework by FWolfe)
-- Requires the ProfessionFramework mod as a dependency in mod.info:
--   require=ProfessionFramework
--
-- Place at: media/lua/shared/MyMod_PF_Traits.lua
--
-- Source reference: github.com/FWolfe/ProfessionFramework

-- Traits registered here are picked up automatically by ProfessionFramework
-- on OnGameBoot / OnGameStart.

ProfessionFramework.addTrait("MyMod_Survivalist", {
    name        = "UI_trait_MyMod_Survivalist",       -- translation string, or literal
    description = "UI_traitdesc_MyMod_Survivalist",
    cost        = -4,                                  -- negative = gives player points
    xp          = {
        [Perks.Foraging]  = 1,
        [Perks.Trapping]  = 1,
    },
    exclude     = {"MyMod_CitySlicker"},               -- mutually exclusive traits
})

ProfessionFramework.addTrait("MyMod_CitySlicker", {
    name        = "UI_trait_MyMod_CitySlicker",
    description = "UI_traitdesc_MyMod_CitySlicker",
    cost        = 4,                                   -- positive = costs points (flaw)
    exclude     = {"MyMod_Survivalist"},
    -- OnNewGame callback fires when a new character is created with this trait
    OnNewGame   = function(player)
        -- e.g., give a starting item
        player:getInventory():AddItem("Base.Smartphone")
    end,
})

-- Profession-specific trait (only available when a matching profession is chosen)
ProfessionFramework.addTrait("MyMod_FieldMedic", {
    name        = "UI_trait_MyMod_FieldMedic",
    description = "UI_traitdesc_MyMod_FieldMedic",
    cost        = 0,                                  -- free, gated by profession
    profession  = true,                               -- profession-only trait
    xp          = { [Perks.Doctor] = 2 },
    recipes     = { "Make Splint", "Suture Wound" },
})
