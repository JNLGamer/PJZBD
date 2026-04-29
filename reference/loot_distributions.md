# Loot Distributions (Procedural Distributions)

Source: PZwiki — B42.7.0. Game file: `ProjectZomboid/media/lua/server/Items/ProceduralDistributions.lua`

## How It Works

When a container loads (or respawns loot), `OnFillContainer` fires. The game rolls each item entry a set number of times. Chance values are **neither weights nor percentages** — they are compared against existing vanilla values to calibrate your entries.

## Distribution Structure

```lua
ProceduralDistributions.list = {
    distributionName = {
        rolls = 3,          -- how many times items are rolled
        items = {
            "ItemName", 10, -- item ID, chance value (paired)
            "OtherItem", 5,
        },
        junk = {            -- ignores zombie density; x1.4 chance multiplier
            rolls = 1,
            items = {
                "ItemName", 3,
            }
        }
    },
}
```

Items with a module other than `Base` must include it: `"MyMod.MyItem"`.

## Distribution Tags

| Tag | Effect |
|-----|--------|
| `rolls` | Number of roll attempts per item in this list |
| `ignoreZombieDensity` | Ignores zombie density impact on spawn chance |
| `isShop = true` | Disables stash chance, item wear, bag fill, and weapon condition reduction |
| `stashChance` | Chance for the container to be a stash |
| `canBurn` | Food can be burnt (25%) or cooked |
| `isWorn` | Items spawn with reduced condition, dirty/bloody/holes on clothing |
| `isTrash` | Harsher version of `isWorn`; clothing 95% dirty, 75% holes |
| `isRotten` | Non-rotten food becomes rotten (75%) or gets increased age |
| `maxMap` (integer) | Limits same item to a max count (behavior not fully confirmed) |

## Adding Items to Existing Distributions

### Simple (one-off)
```lua
-- runs in media/lua/server/
table.insert(ProceduralDistributions.list["DistributionListName"].items, "YourItem")
table.insert(ProceduralDistributions.list["DistributionListName"].items, 0.5)
```

### Recommended Pattern (multiple distributions, bulk insert)
```lua
local myDistributions = {
    GigamartPots = {
        items = {
            "GlassWine", 6,
            "Fork", 10,
            "Mugl", 10,
        },
        junk = {
            "HandTorch", 8,
        },
    },
    LibraryMilitaryHistory = {
        items = {
            "Book_Music", 20,
            "Doodle", 0.001,
        },
    },
}

-- cache for performance
local ProceduralDistributions_list = ProceduralDistributions.list
local table_insert = table.insert

local function insertInDistribution(distrib)
    for k, v in pairs(distrib) do
        local dest = ProceduralDistributions_list[k]
        local items = v.items
        if items then
            local dest_items = dest.items
            for i = 1, #items do
                table_insert(dest_items, items[i])
            end
        end
        local junk = v.junk
        if junk then
            local dest_junk = dest.junk
            for i = 1, #junk do
                table_insert(dest_junk, junk[i])
            end
        end
    end
end

insertInDistribution(myDistributions)
```

This file lives in `media/lua/server/` (not client or shared).

## Related Loot Table Files

```
media/lua/server/Items/
├── ProceduralDistributions.lua     ← main loot table
├── Distribution_BinJunk.lua        ← clutter tables
├── Distribution_ClosetJunk.lua
├── Distribution_CounterJunk.lua
├── Distribution_DeskJunk.lua
├── Distribution_ShelfJunk.lua
├── Distribution_SideTableJunk.lua
└── Distribution_BagsAndContainers.lua  ← backpack loot

media/lua/server/Vehicles/
├── VehicleDistribution_GloveBoxJunk.lua
├── VehicleDistribution_SeatJunk.lua
└── VehicleDistribution_TrunkJunk.lua
```

## Hooking OnFillContainer

To intercept loot spawning and modify it dynamically (e.g., replace a dummy item):

```lua
Events.OnFillContainer.Add(function(roomType, containerType, container)
    -- container is an ItemContainer
    -- roomType e.g. "kitchen", "bedroom"
    -- containerType e.g. "Fridge", "DeskDrawer"
end)
```

## Warnings

- Adding many items to a single distribution **inflates total loot count** in that container — this is a known systemic issue.
- Do not reduce spawn chance as a band-aid; instead use dummy items + `OnFillContainer` replacement, or variant items.
- Use **PZTools** (external tool) to explore vanilla distribution lists and calibrate your chance values against existing items.
