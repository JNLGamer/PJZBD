-- ProfessionFramework profession example (3rd-party framework by FWolfe)
-- Requires the ProfessionFramework mod as a dependency in mod.info:
--   require=ProfessionFramework
--
-- Place at: media/lua/shared/MyMod_PF_Professions.lua
--
-- Source reference: github.com/FWolfe/ProfessionFramework

ProfessionFramework.addProfession("MyMod_Ranger", {
    name    = "UI_prof_MyMod_Ranger",       -- translation string, or literal display name
    icon    = "prof_ranger",                -- looks for media/ui/prof_ranger.png
    cost    = -4,                           -- negative = starts with more points than baseline

    -- Skill XP bonuses granted at character creation
    xp = {
        [Perks.Aiming]    = 1,
        [Perks.Foraging]  = 2,
        [Perks.Trapping]  = 1,
        [Perks.Fitness]   = 1,
    },

    -- Free traits automatically applied when this profession is selected
    traits = {
        "Outdoorsman",          -- vanilla trait code
        "MyMod_Survivalist",    -- custom trait from MyMod_PF_Traits.lua
    },

    -- Recipes unlocked at start
    recipes = {
        "Make Animal Trap",
        "Make Fishing Rod",
    },

    -- Starting inventory (added on new game)
    -- Each entry: { type = "Base.ItemID", count = N }
    items = {
        { type = "Base.HuntingKnife",   count = 1 },
        { type = "Base.WaterBottle",    count = 1 },
        { type = "Base.Matches",        count = 1 },
    },

    -- Optional callback when a new game starts with this profession
    OnNewGame = function(player)
        -- extra setup, e.g. set a custom ModData flag
        player:getModData().MyMod_isRanger = true
    end,
})
