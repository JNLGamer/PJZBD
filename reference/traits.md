# Creating Custom Traits

Source: pzwiki.net, MrBounty/PZ-Mod---Doc, game files (B42 authoritative)

## Build 42: Script Files (Recommended)

In Build 42, the primary way to define traits is via `.txt` script files — the same
format the game itself uses. See [examples/trait_definition.txt](examples/trait_definition.txt)
for a complete template with all 4 patterns.

File location: `media/scripts/characters/mytraits.txt`

```
module Base
{
    character_trait_definition base:mytrait
    {
        IsProfessionTrait       = false,
        DisabledInMultiplayer   = false,
        CharacterTrait          = base:mytrait,
        Cost                    = 4,
        UIName                  = UI_trait_MyTrait,
        UIDescription           = UI_trait_MyTraitDesc,
        XPBoosts                = Aiming=1;Sneak=1,
        MutuallyExclusiveTraits = base:cowardly,
        GrantedRecipes          = MakeSomething,
    }
}
```

For all vanilla trait IDs, costs, and exclusions see [vanilla_traits.md](vanilla_traits.md).

---

## Legacy Lua API: TraitFactory (pre-B42 style)

The Lua `TraitFactory` API still works and is useful for runtime trait manipulation.
For defining traits via code (e.g. when using FWolfe's ProfessionFramework), see
[examples/trait_basic.lua](examples/trait_basic.lua).

### Where the Code Goes

`media/lua/client/MyMod_Traits.lua`  
Traits are registered on the client side at game boot.

## Core API: TraitFactory

```lua
TraitFactory.addTrait(code, name, cost, description, isProfession, serverOnly)
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `code` | string | Internal unique ID (e.g. `"MyMod_NightOwl"`) |
| `name` | string | Display name shown in UI |
| `cost` | number | Point cost — positive = costs points, negative = gives points |
| `description` | string | Tooltip text |
| `isProfession` | boolean | `true` = only available via a profession |
| `serverOnly` | boolean | `true` = disabled in singleplayer |

Returns a `TraitFactory.Trait` object you can chain methods on.

## Chaining Methods

```lua
local trait = TraitFactory.addTrait("MyMod_Brawler", "Brawler", -4, "Hits harder.", false, false)

-- Skill XP boosts (perk, level)
trait:addXPBoost(Perks.Strength, 1)
trait:addXPBoost(Perks.Fitness, 1)

-- Unlock recipes
trait:getFreeRecipes():add("Make Wooden Spear")

-- Mutual exclusivity (by code string)
trait:setExclusive("Weak")
trait:setExclusive("Feeble")
```

## Trait Icon

Place an 18×18 PNG at:
```
media/ui/Traits/trait_MyMod_Brawler.png
```
Naming pattern: `trait_<code>.png` (lowercase code).

## Checking / Modifying Traits at Runtime

```lua
-- Check if a player has a trait
if player:HasTrait("MyMod_Brawler") then
    -- ...
end

-- Add/remove trait at runtime
player:getTraits():add("MyMod_Brawler")
player:getTraits():remove("MyMod_Brawler")
```

## Common Perks Reference

```lua
Perks.Strength       Perks.Fitness        Perks.Sprinting
Perks.Lightfoot      Perks.Nimble         Perks.Sneak
Perks.Axe            Perks.LongBlade      Perks.SmallBlade
Perks.SmallBlunt     Perks.Spear          Perks.Maintenance
Perks.Carpentry      Perks.Cooking        Perks.Farming
Perks.Electrical     Perks.Metalworking   Perks.Mechanics
Perks.Aiming         Perks.Reloading      Perks.Doctor
Perks.Fishing        Perks.Trapping       Perks.Foraging
```

## Full Minimal Example

```lua
local function initTraits()
    local t = TraitFactory.addTrait(
        "MyMod_IronGut",
        "Iron Gut",
        -4,
        "Your stomach can handle almost anything.",
        false,
        false
    )
    t:setExclusive("IronGut") -- exclude vanilla equivalent if any
end

Events.OnGameBoot.Add(initTraits)
```

## Notes

- Register traits in `OnGameBoot`, not `OnGameStart` — the factory must be populated before character creation.
- Icons are optional; the game will use a blank placeholder if missing.
- `cost` of 0 is valid (free trait, usually profession-locked).
