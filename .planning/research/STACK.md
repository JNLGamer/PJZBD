# STACK.md — Sanity_traits Technical Stack

**Source:** `reference/` docs + `ProjectZomboid/media/lua/` game source (B42 authoritative)
**Confidence:** HIGH — all APIs verified against actual game Lua files

---

## 1. Trait Definition

### B42 Script Format (Recommended for static definitions)

File: `Mods/Sanity_traits/media/scripts/characters/sanity_traits.txt`

```
module Base
{
    character_trait_definition sanitymod:insomniac_stage1
    {
        IsProfessionTrait   = false,
        CharacterTrait      = sanitymod:insomniac_stage1,
        Cost                = 4,
        UIName              = UI_trait_SanityMod_Insomniac,
        UIDescription       = UI_trait_SanityMod_InsomniacDesc,
    }
}
```

See full template: `reference/examples/trait_definition.txt`

### TraitFactory (Legacy Lua — still valid for dynamic/programmatic registration)

```lua
local t = TraitFactory.addTrait("MyMod_TraitCode", "Display Name", -4, "Description.", false, false)
t:addXPBoost(Perks.Fitness, 1)
t:setExclusive("OtherTraitCode")
```

Source: `reference/traits.md`, `reference/examples/trait_basic.lua`

**Recommendation:** Use `.txt` script format for all custom traits in this mod. Register in `OnGameBoot`.

---

## 2. Trait Runtime API

```lua
-- Check
if player:HasTrait("base:insomniac") then ... end

-- Add
player:getTraits():add("sanitymod:fatigued")

-- Remove (guard first — remove on absent trait is silent but wasteful)
if player:HasTrait("sanitymod:fatigued") then
    player:getTraits():remove("sanitymod:fatigued")
end
```

**B42 typed form** (used internally by game):
```lua
local ct = CharacterTrait.get(ResourceLocation.of("base:insomniac"))
player:hasTrait(ct)  -- lowercase h, typed argument
```

`player:HasTrait("traitID")` (uppercase H, string) is the safe mod-friendly form.

Source: `reference/traits.md:89-98`, `ProjectZomboid/media/lua/shared/Foraging/forageSystem.lua:1880`

---

## 3. ModData — Sanity Meter Persistence

### Per-character ModData (recommended for sanity meter)

Automatically saved with the player file — no extra transmit needed in singleplayer.

```lua
local function getSanityData(player)
    local md = player:getModData()
    if not md.SanityTraits then
        md.SanityTraits = {
            meter    = 800,       -- 0–1000; lower = worse mental state
            stage    = "healthy", -- healthy | sad | depressed | traumatized | desensitized
            kills    = { zombie = 0, survivor = 0 },
            habits   = { meds = 0, alcohol = 0, cigarettes = 0 },
            tick_last = 0,
        }
    end
    return md.SanityTraits
end
```

Initialize in `Events.OnCreatePlayer` or `Events.OnInitGlobalModData`.

Source: `reference/moddata.md:69-76`

### Global ModData (alternative — if cross-character data needed)

```lua
local data = ModData.getOrCreate("SanityTraits_Global")
data.someGlobal = true
-- singleplayer: no transmit needed
```

Source: `reference/moddata.md:6-44`

---

## 4. Kill Events

### Zombie kills

```lua
Events.OnZombieDead.Add(function()
    -- no parameters — call getPlayer() to get local player
    local player = getPlayer()
    -- update kill count via getSanityData(player)
end)
```

Source: `ProjectZomboid/media/lua/client/LastStand/Challenge2.lua:68,242`
Note: Reference docs list `OnZombiesDead` (plural) — game source uses `OnZombieDead` (singular). Use singular.

### Survivor / NPC kills

```lua
Events.OnWeaponHitCharacter.Add(function(attacker, target, weapon, damage)
    -- fires on every hit; check if target died on this hit
    if attacker == getPlayer() and target and target:isDead() then
        if not target:isZombie() then
            -- survivor kill — weigh heavier
        end
    end
end)
```

Source: `reference/events.md:57`
Caution: `isDead()` may not be true immediately; test behavior. `OnPlayerDeath` also fires for NPC deaths:

```lua
Events.OnPlayerDeath.Add(function(_character)
    -- fires for local player AND NPC characters dying
    -- check if attacker was the player for attribution
end)
```

Source: `ProjectZomboid/media/lua/shared/Logs/ISPerkLog.lua:90,114`

---

## 5. Mood / Time Events

There is **no dedicated happiness-change event** in B42. Mood recovery must be polled.

```lua
-- Poll every 10 in-game minutes (recommended — low overhead)
Events.EveryTenMinutes.Add(function()
    local player = getPlayer()
    if not player then return end
    -- read moodle level
    local moodles = player:getMoodles()
    local unhappyLevel = moodles:getMoodleLevel(MoodleType.Unhappy)
    -- unhappyLevel: 0=none, 1=low, 2=medium, 3=high, 4=severe
    -- use this to drive sanity meter recovery when unhappyLevel is 0
end)

-- For time-based passive decay
Events.EveryOneMinute.Add(function()
    local player = getPlayer()
    if not player then return end
    -- apply passive sanity decay tick
end)
```

Source: `reference/events.md:45-47`

---

## 6. Sandbox Options

### Reading custom sandbox vars at runtime

```lua
-- Pattern 1: SandboxVars module namespace (preferred)
local decayRate = SandboxVars.SanityTraits and SandboxVars.SanityTraits.DecayRate or 50

-- Pattern 2: getSandboxOptions() API
local val = getSandboxOptions():getOptionByName("SanityTraitsDecayRate"):getValue()
```

Source: `ProjectZomboid/media/lua/client/ISUI/Maps/ISMiniMap.lua:687`,
        `ProjectZomboid/media/lua/shared/TimedActions/ISReadABook.lua:483`

### Defining custom sandbox options (B42)

Custom sandbox options are defined in a `.txt` file:
`Mods/Sanity_traits/media/scripts/sandbox_options.txt`

```
option SanityTraits.DecayRate
{
    type        = double,
    min         = 0.1,
    max         = 5.0,
    default     = 1.0,
    page        = SanityTraits,
    translation = Sandbox_SanityTraits_DecayRate,
}
```

Read at runtime via `SandboxVars.SanityTraits.DecayRate` after game start.
Always use `or default_value` fallback for old saves.

**Confidence:** MEDIUM — sandbox option .txt format verified by pattern in vanilla game but no mod example found in reference/. Verify against a working B42 mod before shipping.

---

## 7. Profession Detection

```lua
-- Get profession ID string at runtime
local profID = player:getDescriptor():getCharacterProfession():getName()
-- returns e.g. "base:police", "base:doctor", "base:veteran"

-- Safe read (character descriptor can be nil during creation)
local function getProfessionID(player)
    local desc = player:getDescriptor()
    if not desc then return "base:unemployed" end
    local prof = desc:getCharacterProfession()
    if not prof then return "base:unemployed" end
    return prof:getName()
end
```

Source: `ProjectZomboid/media/lua/shared/Foraging/forageSystem.lua:1867`

---

## 8. Perks Constants (XP Boost reference)

```lua
Perks.Strength      Perks.Fitness       Perks.Sprinting
Perks.Lightfoot     Perks.Nimble        Perks.Sneak
Perks.Axe           Perks.LongBlade     Perks.SmallBlade
Perks.SmallBlunt    Perks.Spear         Perks.Maintenance
Perks.Carpentry     Perks.Cooking       Perks.Farming
Perks.Electrical    Perks.Metalworking  Perks.Mechanics
Perks.Aiming        Perks.Reloading     Perks.Doctor
Perks.Fishing       Perks.Trapping      Perks.Foraging
```

Source: `reference/traits.md:101-112`

---

## Summary Table

| Need | API | Source | Confidence |
|------|-----|--------|------------|
| Define custom trait | `.txt` `character_trait_definition` | `reference/traits.md` | HIGH |
| Add trait at runtime | `player:getTraits():add("id")` | `reference/traits.md:96` | HIGH |
| Remove trait at runtime | `player:getTraits():remove("id")` | `reference/traits.md:97` | HIGH |
| Check trait | `player:HasTrait("id")` | `reference/traits.md:95` | HIGH |
| Persist sanity meter | `player:getModData().SanityTraits` | `reference/moddata.md:69` | HIGH |
| Zombie kill event | `Events.OnZombieDead` (no params) | Game source `Challenge2.lua` | HIGH |
| NPC kill detection | `Events.OnWeaponHitCharacter` + isDead check | `reference/events.md` | MEDIUM |
| Mood polling | `Events.EveryTenMinutes` + `getMoodles()` | `reference/events.md` | HIGH |
| Sandbox read | `SandboxVars.SanityTraits.Key or default` | Game source `ISMiniMap.lua` | HIGH |
| Sandbox define | `media/scripts/sandbox_options.txt` | Pattern inferred | MEDIUM |
| Profession ID | `player:getDescriptor():getCharacterProfession():getName()` | `forageSystem.lua:1867` | HIGH |
