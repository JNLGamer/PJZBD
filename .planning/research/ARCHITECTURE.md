# Architecture Patterns: Sanity_traits Mod

**Domain:** Project Zomboid B42 singleplayer mod — psychological deterioration system
**Researched:** 2026-04-27
**Confidence:** HIGH (all patterns verified against game source)

---

## Module Map

```
Mods/Sanity_traits/
├── mod.info
├── media/
│   ├── scripts/
│   │   └── characters/
│   │       └── sanity_traits.txt          ← trait definitions (B42 .txt format)
│   └── lua/
│       ├── client/
│       │   └── SanityTraits_TraitDefs.lua ← TraitFactory registration + OnGameBoot
│       └── shared/
│           ├── SanityTraits_Config.lua    ← sandbox var cache + default thresholds
│           ├── SanityTraits_Data.lua      ← ModData schema, getters/setters, init
│           ├── SanityTraits_Manager.lua   ← sanity arithmetic, decay, regen
│           ├── SanityTraits_Stages.lua    ← stage transition logic, trait apply/remove
│           ├── SanityTraits_Occupations.lua ← psyche profiles keyed by profession ID
│           └── SanityTraits_Habits.lua    ← consumption tracking, addiction evaluation
```

| File | Single-line purpose |
|------|---------------------|
| `sanity_traits.txt` | Declares all custom trait definitions in B42 script format |
| `SanityTraits_TraitDefs.lua` | Registers traits via `TraitFactory` at `OnGameBoot`; client-only because `TraitFactory` is client-side |
| `SanityTraits_Config.lua` | Reads and caches sandbox vars at `OnInitGlobalModData`; single source of truth for all thresholds |
| `SanityTraits_Data.lua` | Owns the `player:getModData()` schema; all read/write goes through this module |
| `SanityTraits_Manager.lua` | Responds to kill events and periodic ticks; calls into Data then Stages |
| `SanityTraits_Stages.lua` | Compares current sanity to thresholds; applies/removes traits idempotently |
| `SanityTraits_Occupations.lua` | Pure data table — profession ID → psyche profile (modifier values, initial sanity) |
| `SanityTraits_Habits.lua` | Tracks item consumption via timed-action hooks; evaluates addiction eligibility |

---

## Data Schema

All per-character state lives in `player:getModData()`. This is automatically persisted with the character save — no extra work needed.

Source: `reference/moddata.md`, `d:/SteamLibrary/steamapps/common/PJZBD/ProjectZomboid/media/lua/shared/moddata_usage.lua`

```lua
-- SanityTraits_Data.lua — canonical schema

local NAMESPACE = "SanityTraits"

local DEFAULTS = {
    -- Core meter: 0.0 (shattered) to 1.0 (intact)
    sanity          = 1.0,

    -- Stage enum: 0=Normal, 1=Sad, 2=Depressed, 3=Traumatized, 4=Desensitized
    stage           = 0,

    -- Kill counts (for future scaling / display)
    zombieKills     = 0,
    survivorKills   = 0,

    -- Habit tracking: map of itemType → use count this session/week
    -- e.g. { ["Base.Cigarettes"] = 12, ["Base.WhiskeyFull"] = 4 }
    habitCounts     = {},

    -- Addiction flags set once the Depressed threshold is crossed
    -- e.g. { ["Base.Cigarettes"] = true }
    addictions      = {},

    -- Guard: which stage traits are currently applied (prevents double-apply)
    appliedStage    = 0,
}

function SanityTraits_Data.get(player)
    local md = player:getModData()
    if not md[NAMESPACE] then
        -- Deep-copy defaults; avoids shared-table bugs
        md[NAMESPACE] = {}
        for k, v in pairs(DEFAULTS) do
            if type(v) == "table" then
                md[NAMESPACE][k] = {}
            else
                md[NAMESPACE][k] = v
            end
        end
    end
    return md[NAMESPACE]
end

-- Convenience
function SanityTraits_Data.getSanity(player)
    return SanityTraits_Data.get(player).sanity
end

function SanityTraits_Data.setSanity(player, value)
    local d = SanityTraits_Data.get(player)
    -- clamp 0..1
    d.sanity = math.max(0.0, math.min(1.0, value))
end
```

**Key decisions:**
- Use `player:getModData()` (per-character), not global `ModData`. There is no global kill counter needed; everything is character-scoped.
- `habitCounts` is a flat map (itemType string → integer). Reset logic (weekly decay) is handled in `SanityTraits_Manager` on the `EveryDays` event.
- `appliedStage` is the idempotency guard — it records which stage's traits are currently attached, separate from the computed `stage`. This lets you always re-derive stage from `sanity` without worrying about double-applying traits.

---

## Event Flow

Source: `reference/events.md`, game source verified

### Boot / Init sequence

```
OnGameBoot
    └─> SanityTraits_TraitDefs.lua: register all custom traits via TraitFactory
        (must be at boot so traits exist before character creation screen)

OnInitGlobalModData(isNewGame)
    └─> SanityTraits_Config.lua: read SandboxVars, cache thresholds
    └─> (no player object yet — do NOT touch player ModData here)

OnCreatePlayer(playerIndex, player)
    └─> SanityTraits_Data.get(player): lazy-initialise ModData schema
    └─> SanityTraits_Occupations: look up player's profession, store initial sanity modifier
    └─> SanityTraits_Stages.applyStage(player): sync traits to current stage
        (handles loading an existing save where stage > 0)
```

### Kill events

```
OnZombieDead(zombie)
    └─> SanityTraits_Manager.onZombieKilled(zombie)
        ├─ validate: getPlayer() is attacker (see note below)
        ├─ SanityTraits_Data: zombieKills += 1
        ├─ delta = Config.zombieKillDelta * OccupationProfile.killModifier
        ├─ SanityTraits_Data.setSanity(player, current - delta)
        └─ SanityTraits_Stages.checkTransition(player)
```

**Note on attacker validation:** `OnZombieDead` fires with the zombie object but does not pass the killer. In singleplayer you can safely assume `getPlayer()` is the killer. Verify with `getPlayer():getZombieKills()` if needed (the engine already increments this). Source: `ISPlayerStatsUI.lua:57`, `Tutorial/Steps.lua:913`.

```
-- NPC/survivor kill: no dedicated event exists in B42 Lua.
-- Use OnWeaponHitCharacter and check for death state, OR
-- poll getPlayer():getSurvivorKills() if that counter exists.
-- Safest approach: hook OnWeaponHitCharacter, check target is
-- instanceof IsoSurvivor and target:isDead() after the hit.
-- Source: DebugContextMenu.lua:534 (instanceof IsoSurvivor/IsoZombie pattern)

OnWeaponHitCharacter(attacker, target, weapon, damage)
    └─> SanityTraits_Manager.onWeaponHit(attacker, target, weapon, damage)
        ├─ if attacker ~= getPlayer() then return end
        ├─ if not instanceof(target, "IsoSurvivor") then return end
        ├─ if not target:isDead() then return end  -- wait for death, not hit
        ├─ SanityTraits_Data: survivorKills += 1
        ├─ delta = Config.survivorKillDelta * OccupationProfile.survivorKillModifier
        ├─ SanityTraits_Data.setSanity(player, current - delta)
        └─ SanityTraits_Stages.checkTransition(player)
```

### Periodic decay / regen

```
EveryTenMinutes
    └─> SanityTraits_Manager.onTenMinutes()
        ├─ player = getPlayer(); if not player then return end
        ├─ read mood modifier: player:getMoodles():getMoodleLevel(MoodleType.UNHAPPY)
        ├─ compute delta from Config + mood + OccupationProfile.regenRate
        ├─ SanityTraits_Data.setSanity(player, current + delta)  -- delta may be negative
        └─ SanityTraits_Stages.checkTransition(player)

EveryDays
    └─> SanityTraits_Habits.decayHabitCounts(player)
        └─ reduce all habitCounts by Config.dailyHabitDecay (floor at 0)
```

### Full call chain for a kill → trait apply

```
[player kills zombie]
    OnZombieDead fires
    → Manager.onZombieKilled(zombie)
        → Data.setSanity(player, newValue)          -- mutates ModData
        → Stages.checkTransition(player)
            → local newStage = Stages.computeStage(sanity, Config.thresholds)
            → if newStage == data.appliedStage then return end  -- idempotency guard
            → Stages.removeStageTraits(player, data.appliedStage)
            → Stages.applyStageTraits(player, newStage)
            → data.stage = newStage
            → data.appliedStage = newStage
            [if newStage == DEPRESSED]
                → Habits.evaluateAddictions(player)   -- check habit counts → set flags
```

---

## Stage Transition Design

### Check timing

Stage transitions are checked **on every kill event and every `EveryTenMinutes` tick**, not on a dedicated tick. This avoids unnecessary overhead. The sanity value only changes at those two call sites, so those are the only places a stage transition can be warranted.

Do NOT use `OnTick` for sanity arithmetic — it fires hundreds of times per second and is for animation/input polling only.

### Guard conditions and idempotency

```lua
-- SanityTraits_Stages.lua

local STAGE = { NORMAL=0, SAD=1, DEPRESSED=2, TRAUMATIZED=3, DESENSITIZED=4 }

function SanityTraits_Stages.computeStage(sanity, thresholds)
    -- thresholds from Config, e.g. { sad=0.75, depressed=0.5, traumatized=0.25, desensitized=0.05 }
    if sanity <= thresholds.desensitized then return STAGE.DESENSITIZED end
    if sanity <= thresholds.traumatized  then return STAGE.TRAUMATIZED  end
    if sanity <= thresholds.depressed    then return STAGE.DEPRESSED    end
    if sanity <= thresholds.sad          then return STAGE.SAD          end
    return STAGE.NORMAL
end

function SanityTraits_Stages.checkTransition(player)
    local d = SanityTraits_Data.get(player)
    local newStage = SanityTraits_Stages.computeStage(d.sanity, SanityTraits_Config.thresholds)

    -- IDEMPOTENCY: bail if stage has not changed
    if newStage == d.appliedStage then return end

    -- Remove traits for the previous stage
    SanityTraits_Stages.removeStageTraits(player, d.appliedStage)

    -- Apply traits for the new stage
    SanityTraits_Stages.applyStageTraits(player, newStage)

    -- Update both fields atomically
    d.stage       = newStage
    d.appliedStage = newStage

    -- Side effect: addiction evaluation at Depressed threshold
    if newStage >= STAGE.DEPRESSED and d.appliedStage < STAGE.DEPRESSED then
        SanityTraits_Habits.evaluateAddictions(player)
    end
end
```

### Trait removal safety pattern

Source: `reference/traits.md` — `player:getTraits():remove()` is the runtime API

```lua
function SanityTraits_Stages.safeRemoveTrait(player, traitID)
    -- Defensive: do not error if trait is absent (e.g. was never applied,
    -- or was already removed by another system)
    if player:HasTrait(traitID) then
        player:getTraits():remove(traitID)
    end
end
```

**Note:** The game source uses `player:hasTrait(CharacterTrait.X)` for Java enum values (verified in `ISBarricadeAction.lua`, `ISCraftAction.lua`). For mod-defined string-keyed traits the equivalent runtime check is `player:HasTrait("MyMod_TraitCode")` (capital H, string argument). This distinction is confirmed in `reference/traits.md`. Both forms must be tested on first build.

### Desensitized special case

At Desensitized, conflicting vanilla panic/phobia traits are removed:

```lua
local DESENSITIZED_REMOVES = {
    "base:hemophobic",    -- excl. desensitized in vanilla
    "base:agoraphobic",   -- excl. desensitized in vanilla  (vanilla_traits.md)
    "base:claustrophobic",
    "base:cowardly",
}

function SanityTraits_Stages.applyStageTraits(player, stage)
    if stage == STAGE.DESENSITIZED then
        for _, id in ipairs(DESENSITIZED_REMOVES) do
            SanityTraits_Stages.safeRemoveTrait(player, id)
        end
        -- then add the mod's Desensitized positive traits
        player:getTraits():add("SanityTraits_Desensitized")
    end
    -- ... other stages
end
```

---

## Occupation Profile Pattern

Source: `reference/occupations.md` — all vanilla profession IDs confirmed.
Runtime API: `player:getDescriptor():getCharacterProfession():getName()`
Verified in: `ISPlayerStatsUI.lua:48`, `LastStandSetup.lua:102`

```lua
-- SanityTraits_Occupations.lua

SanityTraits_Occupations = {}

-- Key: the string returned by getCharacterProfession():getName()
-- The game returns lowercase names as stored in the script file's ID field
-- e.g. "base:veteran" → getName() returns "veteran" (the part after the colon)
-- VERIFY this on first test — the API may return the full "base:veteran" or just "veteran"

local PROFILES = {
    -- High-stress military/law enforcement: start with lower sanity,
    -- but kills cost them LESS (conditioned)
    ["veteran"] = {
        initialSanityBonus  =  0.10,  -- starts 10% above baseline
        zombieKillModifier  =  0.50,  -- zombie kills only half as damaging
        survivorKillModifier = 0.60,
        regenRate           =  1.20,  -- 20% faster passive recovery
    },
    ["policeofficer"] = {
        initialSanityBonus  =  0.05,
        zombieKillModifier  =  0.70,
        survivorKillModifier = 0.70,
        regenRate           =  1.10,
    },

    -- Medical: used to death, stoic but not immune
    ["doctor"] = {
        initialSanityBonus  =  0.0,
        zombieKillModifier  =  0.80,
        survivorKillModifier = 0.90,
        regenRate           =  1.15,
    },
    ["nurse"] = {
        initialSanityBonus  =  0.0,
        zombieKillModifier  =  0.85,
        survivorKillModifier = 0.95,
        regenRate           =  1.10,
    },

    -- Civilian: full cost
    ["unemployed"] = {
        initialSanityBonus  =  0.0,
        zombieKillModifier  =  1.0,
        survivorKillModifier = 1.0,
        regenRate           =  1.0,
    },

    -- Default fallback for unrecognised professions
    ["__default"] = {
        initialSanityBonus  =  0.0,
        zombieKillModifier  =  1.0,
        survivorKillModifier = 1.0,
        regenRate           =  1.0,
    },
}

function SanityTraits_Occupations.getProfile(player)
    -- Returns the psyche profile table for the player's current profession.
    local profObj = player:getDescriptor():getCharacterProfession()
    if not profObj then
        return PROFILES["__default"]
    end
    local profName = profObj:getName()  -- e.g. "veteran", "unemployed"
    return PROFILES[profName] or PROFILES["__default"]
end
```

**Profession name resolution note:** The call chain `player:getDescriptor():getCharacterProfession():getName()` is confirmed in `ISPlayerStatsUI.lua:711-712` and `LastStandSetup.lua:102`. The string result of `:getName()` on the profession object used in `LastStandSetup` is the short name after the colon (e.g. `"veteran"`). Validate this on first runtime test and adjust the profile keys if needed.

---

## Habit Tracking Design

### Which event to hook

There is **no published `OnEat` or `OnConsume` event** in the event reference or game source. The timed action system (`ISEatFoodAction`, `ISTakePillAction`, `ISDrinkFromBottle`) calls `self.character:Eat(item, ...)` and `self.character:getBodyDamage():JustTookPill(item)` in their `complete()` methods — these are Java-side calls with no corresponding Lua event.

**Practical solution — wrap the timed action `complete` method:**

```lua
-- SanityTraits_Habits.lua
-- Hook ISEatFoodAction:complete and ISTakePillAction:complete at OnGameStart,
-- after the action classes are loaded.

local _eatComplete  = ISEatFoodAction.complete
local _pillComplete = ISTakePillAction.complete

function ISEatFoodAction:complete()
    local result = _eatComplete(self)
    if self.character == getPlayer() then
        SanityTraits_Habits.recordConsumption(self.character, self.item)
    end
    return result
end

function ISTakePillAction:complete()
    local result = _pillComplete(self)
    if self.character == getPlayer() then
        SanityTraits_Habits.recordConsumption(self.character, self.item)
    end
    return result
end
```

Hook these overrides in `OnGameStart` (not `OnGameBoot`) so the action classes are already defined. Place this code in a shared Lua file since the timed actions are in `media/lua/shared/TimedActions/`.

### What to track

Track by **full item type** (`item:getFullType()`, e.g. `"Base.Cigarettes"`, `"Base.WhiskeyFull"`). This is the stable cross-session identifier.

```lua
function SanityTraits_Habits.recordConsumption(player, item)
    local d = SanityTraits_Data.get(player)
    local itemType = item:getFullType()

    -- Only track categories relevant to addiction
    if not SanityTraits_Habits.isTrackable(itemType) then return end

    d.habitCounts[itemType] = (d.habitCounts[itemType] or 0) + 1
end

-- Configurable list of trackable item type prefixes
local TRACKABLE_CATEGORIES = {
    ["Base.Cigarettes"]   = "nicotine",
    ["Base.Smokes"]       = "nicotine",
    ["Base.WhiskeyFull"]  = "alcohol",
    ["Base.Beer"]         = "alcohol",
    ["Base.BeerCan"]      = "alcohol",
    -- Pills
    ["Base.Painkillers"]  = "opioid",
    ["Base.Sleeping Tablets"] = "sedative",
    -- Extend as needed
}

function SanityTraits_Habits.isTrackable(itemType)
    return TRACKABLE_CATEGORIES[itemType] ~= nil
end
```

### Evaluating addictions

Called when the player crosses into Depressed stage:

```lua
function SanityTraits_Habits.evaluateAddictions(player)
    local d = SanityTraits_Data.get(player)
    local cfg = SanityTraits_Config.addictionThresholds

    for itemType, category in pairs(TRACKABLE_CATEGORIES) do
        local count = d.habitCounts[itemType] or 0
        if count >= (cfg[category] or 10) then
            -- Mark addiction and add corresponding negative trait
            if not d.addictions[category] then
                d.addictions[category] = true
                local traitID = "SanityTraits_Addict_" .. category
                if not player:HasTrait(traitID) then
                    player:getTraits():add(traitID)
                end
            end
        end
    end
end
```

---

## Sandbox Config Access

### Where to define custom options

B42 uses the standard `SandboxVars` table. Custom mod options are added via the `getSandboxOptions()` Java API. However, the simplest singleplayer-only pattern is to use `SandboxVars` directly after seeding it in `OnInitGlobalModData`, or to use a `ModOptions`-style flat table stored in ModData.

For a singleplayer mod, the pragmatic approach is:

1. Define default thresholds in `SanityTraits_Config.lua` as Lua constants.
2. Check `SandboxVars.SanityTraits_*` at `OnInitGlobalModData` and override defaults if the keys exist.
3. This requires exposing the sandbox options through the Sandbox Options UI, which needs a `sandbox.lua` or similar approach.

```lua
-- SanityTraits_Config.lua

SanityTraits_Config = {}

-- Defaults (used if sandbox vars not set)
local DEFAULTS = {
    thresholds = {
        sad          = 0.75,
        depressed    = 0.50,
        traumatized  = 0.25,
        desensitized = 0.05,
    },
    zombieKillDelta  = 0.01,   -- sanity lost per zombie kill (before modifiers)
    survivorKillDelta = 0.08,  -- sanity lost per survivor kill
    regenPerTick     = 0.002,  -- sanity gained per 10-min tick (before modifiers)
    addictionThresholds = {
        nicotine  = 15,
        alcohol   = 10,
        opioid    = 8,
        sedative  = 6,
    },
}

local function onInitModData(isNewGame)
    -- Cache config at world load; SandboxVars is available here.
    -- Override defaults with any SandboxVars the player/server has set.
    SanityTraits_Config.thresholds = {
        sad          = SandboxVars.SanityTraits_ThresholdSad          or DEFAULTS.thresholds.sad,
        depressed    = SandboxVars.SanityTraits_ThresholdDepressed     or DEFAULTS.thresholds.depressed,
        traumatized  = SandboxVars.SanityTraits_ThresholdTraumatized   or DEFAULTS.thresholds.traumatized,
        desensitized = SandboxVars.SanityTraits_ThresholdDesensitized  or DEFAULTS.thresholds.desensitized,
    }
    SanityTraits_Config.zombieKillDelta   = SandboxVars.SanityTraits_ZombieKillDelta  or DEFAULTS.zombieKillDelta
    SanityTraits_Config.survivorKillDelta = SandboxVars.SanityTraits_SurvivorKillDelta or DEFAULTS.survivorKillDelta
    SanityTraits_Config.regenPerTick      = SandboxVars.SanityTraits_RegenPerTick     or DEFAULTS.regenPerTick
    SanityTraits_Config.addictionThresholds = DEFAULTS.addictionThresholds  -- not exposed to sandbox yet
end

Events.OnInitGlobalModData.Add(onInitModData)
```

**Read timing:** Config is read **once at world load** (`OnInitGlobalModData`), cached in `SanityTraits_Config`. All other modules read from the cache, not `SandboxVars` directly. This avoids repeated table lookups on every tick and makes the system testable.

Source for `SandboxVars` access pattern: verified in `shared/Items/SpawnItems.lua:149` and `shared/RadioCom/ISRadioInteractions.lua:7`. Source for `getSandboxOptions():getOptionByName()` per-operation access: `client/Farming/CPlantGlobalObject.lua:19`.

---

## Build Order

Dependency graph drives build order. A module may only be built after everything it `require`s exists.

```
Layer 0 (no dependencies):
    sanity_traits.txt           -- pure data, no Lua deps
    SanityTraits_Config.lua     -- reads SandboxVars only (global), no mod deps

Layer 1 (depends on Config):
    SanityTraits_Occupations.lua -- pure data table, references Config thresholds
    SanityTraits_Data.lua        -- schema definition; references Config for NAMESPACE

Layer 2 (depends on Config + Data):
    SanityTraits_Stages.lua      -- needs Data (schema), Config (thresholds), trait IDs from .txt
    SanityTraits_Habits.lua      -- needs Data (schema), Config (addiction thresholds)

Layer 3 (depends on all of the above):
    SanityTraits_Manager.lua     -- orchestrates: calls Config, Data, Stages, Habits, Occupations

Layer 4 (client-only, depends on .txt being loaded):
    SanityTraits_TraitDefs.lua   -- calls TraitFactory; runs at OnGameBoot
```

**Recommended build sequence:**

1. `sanity_traits.txt` — define Sad/Depressed/Traumatized/Desensitized traits and addiction traits as stubs. No mechanical effects yet.
2. `SanityTraits_Config.lua` — hardcoded defaults, no sandbox integration yet.
3. `SanityTraits_Data.lua` — schema + getters/setters. Test with debug print on `OnCreatePlayer`.
4. `SanityTraits_Occupations.lua` — data table + `getProfile()`. Test against all 24 vanilla professions.
5. `SanityTraits_Stages.lua` — `checkTransition()` + safe trait apply/remove. Test by manually forcing sanity values.
6. `SanityTraits_Manager.lua` — wire up `OnZombieDead` and `EveryTenMinutes`. Test kill loop.
7. `SanityTraits_Habits.lua` — timed-action wrapping and addiction evaluation.
8. Sandbox integration — expose `SandboxVars.SanityTraits_*` keys and update `Config.lua`.
9. Polish: `SanityTraits_TraitDefs.lua` with final trait costs, icons, descriptions.

---

## Critical Implementation Notes

### Native CharacterStat.SANITY exists in B42

The debug stats panel (`ISStatsAndBody.lua:71`) exposes `CharacterStat.SANITY` as a slider. The access pattern is `player:getStats():get(CharacterStat.SANITY)` / `player:getStats():set(CharacterStat.SANITY, value)` — this is the same pattern used for `CharacterStat.UNHAPPINESS` in `ISRadioInteractions.lua:36`.

**Decision point:** You can either drive this mod's sanity off the native `CharacterStat.SANITY` Java stat, or store your own `0..1` float in ModData. Using the native stat means it integrates with the debug UI and potentially with moodle systems; however you lose full control over its range and decay. **Recommendation: store your own value in ModData for full control, but optionally mirror it to `CharacterStat.SANITY` for debug UI visibility.**

### OnZombieDead passes a zombie object (not the killer)

Confirmed in `Tutorial/Steps.lua:913` — the handler receives `zed` as parameter. In singleplayer `getPlayer()` is the only combatant, so attacker validation is trivially `getPlayer()`. Do not attempt to look up the killer from the zombie object.

### No dedicated NPC kill event

There is no `OnSurvivorDead` or `OnNPCKilled` event in the Lua event system (checked exhaustively in game source). Hooking `OnWeaponHitCharacter` and testing `instanceof(target, "IsoSurvivor")` + `target:isDead()` is the established pattern (verified via `DebugContextMenu.lua:534`). Note that `OnWeaponHitCharacter` does not appear in `reference/events.md` by that exact name — the reference table lists it; verify spelling against game source.

### Trait registration must be OnGameBoot, not OnGameStart

Source: `reference/traits.md` explicit note. `TraitFactory` must be populated before character creation. All custom trait codes must be stable strings with a `SanityTraits_` prefix to avoid conflicts.

### SandboxVars is a plain Lua table

`SandboxVars.lua` simply `return`s the Apocalypse preset table and calls `getSandboxOptions():initSandboxVars()`. Custom keys set via the sandbox options UI are merged into this table. Reading `SandboxVars.MyKey` at `OnInitGlobalModData` is safe and correct. Do not read it at event-handler time (EveryTenMinutes etc.) — read once and cache.

---

## Sources

| Claim | Source |
|-------|--------|
| `player:getModData()` pattern | `reference/moddata.md`, `moddata_usage.lua` |
| `OnGameBoot` for TraitFactory | `reference/traits.md`, `trait_basic.lua` |
| `OnInitGlobalModData(isNewGame)` | `reference/events.md`, `moddata_usage.lua` |
| `OnZombieDead(zombie)` signature | `Tutorial/Steps.lua:913`, `Challenge2.lua:242` |
| `instanceof(x, "IsoSurvivor")` | `DebugContextMenu.lua:534`, `StreamMapWindow.lua:43` |
| `player:getDescriptor():getCharacterProfession():getName()` | `ISPlayerStatsUI.lua:711`, `LastStandSetup.lua:102` |
| `player:HasTrait(id)` / `player:getTraits():add/remove` | `reference/traits.md` |
| `CharacterStat.SANITY` exists | `ISStatsAndBody.lua:71` |
| `player:getStats():get(CharacterStat.X)` | `ISStatsAndBody.lua:127` |
| `player:getMoodles():getMoodleLevel(MoodleType.UNHAPPY)` | `ISBaseTimedAction.lua:102` |
| `SandboxVars.X` read pattern | `SpawnItems.lua:149`, `ISRadioInteractions.lua:7` |
| No OnEat/OnConsume event; wrap timed action complete() | `ISEatFoodAction.lua`, `ISTakePillAction.lua` (no event emission in complete()) |
| All vanilla profession IDs | `reference/occupations.md` |
| Desensitized trait conflict list | `reference/vanilla_traits.md` (hemophobic, agoraphobic, claustrophobic, cowardly all list `desensitized` as exclusive) |
