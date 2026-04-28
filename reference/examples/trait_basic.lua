-- Vanilla TraitFactory trait registration example
-- Place at: media/lua/client/MyMod_Traits.lua
--
-- Icon: place an 18x18 PNG at media/ui/Traits/trait_MyMod_IronGut.png
--       and media/ui/Traits/trait_MyMod_WeakStomach.png

local function initTraits()

    -- Positive trait (costs points — player pays for it)
    local ironGut = TraitFactory.addTrait(
        "MyMod_IronGut",            -- internal code (unique across all mods)
        "Iron Gut",                 -- display name
        -4,                         -- negative = gives player points to spend
        "Your stomach can handle almost anything. Less chance of sickness from food.",
        false,                      -- isProfession: false = available to all
        false                       -- serverOnly: false = works in SP too
    )
    ironGut:setExclusive("MyMod_WeakStomach")  -- these two can't coexist

    -- Negative trait (gives the player extra points to spend)
    local weakStomach = TraitFactory.addTrait(
        "MyMod_WeakStomach",
        "Weak Stomach",
        4,                          -- positive = costs the player points (it's a flaw)
        "You get sick easily from bad food or unclean water.",
        false,
        false
    )
    weakStomach:setExclusive("MyMod_IronGut")

    -- Trait with skill XP boost
    local brawler = TraitFactory.addTrait(
        "MyMod_Brawler",
        "Brawler",
        -4,
        "Years of street fighting left you with strong arms and good instincts.",
        false,
        false
    )
    brawler:addXPBoost(Perks.SmallBlunt, 1)
    brawler:addXPBoost(Perks.Strength, 1)
    brawler:setExclusive("Pacifist")  -- exclude vanilla Pacifist

    -- Trait that unlocks recipes
    local herbalist = TraitFactory.addTrait(
        "MyMod_WildHarvester",
        "Wild Harvester",
        -4,
        "You know which plants are edible and how to prepare them.",
        false,
        false
    )
    herbalist:getFreeRecipes():add("Make Herbal Poultice")
    herbalist:getFreeRecipes():add("Brew Herbal Tea")

end

Events.OnGameBoot.Add(initTraits)
