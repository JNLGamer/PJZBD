# Feature Landscape: Sanity_traits

**Domain:** Project Zomboid Build 42 psychological deterioration mod
**Researched:** 2026-04-27
**Confidence:** HIGH — all trait IDs confirmed against game source files

---

## 1. Stage Trait Mappings

### How trait application works at runtime (confirmed)

```lua
-- Add
player:getTraits():add("base:out of shape")

-- Remove
player:getTraits():remove("base:out of shape")

-- Check
player:HasTrait("base:out of shape")
```

Source: `reference/traits.md` lines 96-99

---

### Stage 1 — Sad

Mild onset. Character is distressed but functional. Traits should feel like bad luck rather than disability.

| Trait ID | Display Name | Cost | Rationale |
|----------|-------------|------|-----------|
| `base:insomniac` | Insomniac | -6 | Poor sleep from troubled mind; confirmed `CharacterTrait.INSOMNIAC` at `client/OptionScreens/CharacterCreationProfession.lua:889` |
| `base:cowardly` | Cowardly | -2 | First cracks; panic easier. Confirmed `CharacterTrait.COWARDLY` at `shared/TimedActions/ISCraftAction.lua:22` |

Notes:
- `base:insomniac` does NOT conflict with `base:needsmoresleep`/`base:needslesssleep` — those are separate traits. Insomniac is the poor-quality sleep trait; its vanilla ID is confirmed by `CharacterCreationProfession.lua:889` (`CharacterTrait.INSOMNIAC`).
- Do NOT apply `base:restless sleeper` at this stage — this trait does not appear in the B42 vanilla trait list at `reference/vanilla_traits.md`. Likely a B41 term or a community misnomer. The correct B42 equivalent is `base:insomniac`.
- `base:cowardly` has `MutuallyExclusiveTraits = base:brave;base:desensitized`. If Desensitized is later applied, Cowardly must be removed first.
- Recovery should be able to remove this stage cleanly.

**Stage 1 active trait list:** `base:insomniac`, `base:cowardly`

---

### Stage 2 — Depressed

Moderate deterioration. Addictions are triggered here based on tracked consumption habits (see Addiction section below).

Base traits applied at transition from Sad:

| Trait ID | Display Name | Cost | Rationale |
|----------|-------------|------|-----------|
| `base:hemophobic` | Hemophobic | -5 | Panic around blood; confirmed `CharacterTrait.HEMOPHOBIC` at `shared/TimedActions/ISCraftAction.lua:29`. Mutually exclusive with `base:desensitized`. |
| `base:slowhealer` | Slow Healer | -3 | Depression impairs physiological recovery |
| `base:weakstomach` | Weak Stomach | -2 | Nausea, loss of appetite; confirmed ID `base:weakstomach` at `reference/vanilla_traits.md:129` |

Plus: one addiction trait from the tracked-habits system (see Section 3).

Notes:
- `base:hemophobic` adds `CharacterStat.STRESS` over time when exposed to blood — confirmed by `shared/TimedActions/ISCraftAction.lua:29-33`. This compounds well with the depression spiral.
- `base:weakstomach` stacks with `base:heartyappetite` if the character has it, so check for exclusion (`excl. irongut`).

**Stage 2 active trait list:** Stage 1 traits + `base:hemophobic`, `base:slowhealer`, `base:weakstomach`, + one addiction trait

---

### Stage 3 — Traumatized

Severe disability. Character is falling apart physically and cognitively.

| Trait ID | Display Name | Cost | Rationale |
|----------|-------------|------|-----------|
| `base:out of shape` | Out of Shape | -6 | Fitness=-2; confirmed `CharacterTrait.OUT_OF_SHAPE` at `server/XpSystem/XpUpdate.lua:230`. Mutually exclusive with `base:athletic` and `base:fit`. |
| `base:needsmoresleep` | Hearty Sleeper | -4 | Needs more sleep than normal; confirmed `CharacterTrait.NEEDS_MORE_SLEEP` at `client/OptionScreens/CharacterCreationProfession.lua:889`. Mutually exclusive with `base:needslesssleep`. |
| `base:disorganized` | Disorganized | -6 | Confirmed `CharacterTrait.DISORGANIZED` at `client/ISUI/ISCraftingUI.lua:15`. Mutually exclusive with `base:organized`. |
| `base:pacifist` | Pacifist | -5 | Combat XP penalty; confirmed ID `base:pacifist` at `reference/vanilla_traits.md:113`. Character loses will to fight. Mutually exclusive with `base:brave`. |

Notes:
- `base:out of shape` is dynamically added/removed by the vanilla fitness system (`XpUpdate.lua:230,238`). The mod must check whether the character already has it before adding. If they already have `base:unfit`, `base:out of shape` cannot be added (exclusion: `base:athletic/fit`).
- The correct B42 ID spelling is `base:out of shape` (with spaces) — confirmed from `reference/vanilla_traits.md:111`.
- `base:needsmoresleep` is the "Hearty Sleeper" trait — requires more sleep. Different from `base:insomniac` (poor quality). Stack both for severe rest penalty.
- When applying `base:pacifist`, check that `base:brave` is not present (they are mutually exclusive per `reference/vanilla_traits.md:113`). Remove `base:brave` first if needed.

**Stage 3 active trait list:** All Stage 2 traits + `base:out of shape`, `base:needsmoresleep`, `base:disorganized`, `base:pacifist`

---

### Stage 4 — Desensitized

Terminal stage. Character has crossed into numbness. The mind has shut off emotional processing.

Vanilla situation: `base:desensitized` EXISTS as a profession-only trait tied to Veteran (`reference/vanilla_traits.md:145`, `reference/occupations.md:57`). It is `IsProfessionTrait = true`. The mod must use it via `player:getTraits():add("base:desensitized")` at runtime — this works regardless of IsProfessionTrait, which only blocks character-creation selection.

What `base:desensitized` does canonically:
- Removes/prevents panic (no-panic trait)
- Mutually exclusive with `base:hemophobic`, `base:agoraphobic`, `base:claustrophobic`, `base:cowardly` (confirmed `reference/vanilla_traits.md:114-133`)
- The game actively checks `CharacterTrait.DESENSITIZED` before applying stress from looting corpses (`shared/TimedActions/ISCraftAction.lua:20`) and from looting inventory (`client/TimedActions/ISInventoryTransferAction.lua:129`)

Traits to REMOVE when entering Desensitized:
- `base:cowardly` (mutual exclusion)
- `base:hemophobic` (mutual exclusion)
- `base:agoraphobic` (mutual exclusion, if present)
- `base:claustrophobic` (mutual exclusion, if present)
- All prior stage traits that represent emotional pain (insomniac, slowhealer, weakstomach, pacifist) — the Desensitized character no longer feels. This is a design choice, not a game constraint.

Additional custom behavioral changes to apply at Desensitized:
- Addiction trait stays (physical dependency persists)
- `base:disorganized` stays (cognitive damage does not reverse)
- `base:out of shape` stays unless recovery has occurred

Decision: Use the vanilla `base:desensitized` trait. No custom trait needed. However, a custom `sanitymod:desensitized_flag` can be stored in ModData to track that the character reached this stage, since removing the vanilla trait later (on recovery attempts) would be needed.

**Stage 4 active trait list:** `base:desensitized`, `base:disorganized`, `base:out of shape` (if not recovered), addiction trait — all earlier emotional-reaction traits removed.

---

## 2. Occupation Psyche Profiles

All professions from `reference/occupations.md:53-78`. Profiles define starting sanity value (0-100 scale) and thresholds for stage transitions.

| Profession ID | Display Name | Suggested Starting Sanity | Kill Threshold Modifier | Reasoning |
|---------------|-------------|--------------------------|------------------------|-----------|
| `base:veteran` | Veteran | 90 | 2x (hardened) | Granted `base:desensitized` — already trained to kill. Kill events barely register. Also starts in pseudo-Stage 4 equilibrium. Special case: never transitions to Desensitized via the mod because they already have it. |
| `base:policeofficer` | Police Officer | 75 | 1.5x | Law enforcement, some death exposure. High Aiming/Reloading skills suggest combat readiness. |
| `base:fireofficer` | Fire Officer | 70 | 1.25x | Trauma exposure in the line of duty, but non-lethal profession. |
| `base:securityguard` | Security Guard | 65 | 1.0x | Minimal lethal exposure baseline. |
| `base:nurse` | Nurse | 70 | 1.5x | Death-tolerant; exposure to suffering and dying is professional norm. High Doctor skill. |
| `base:doctor` | Doctor | 70 | 1.5x | Medical death exposure is routine. Doctor=6 highest skill in the game. |
| `base:parkranger` | Park Ranger | 65 | 1.0x | Isolation-tolerant, outdoor-hardened. |
| `base:farmer` | Farmer | 55 | 0.75x | Manual labor but no violence exposure. |
| `base:rancher` | Rancher | 60 | 0.9x | Animal butchering desensitizes somewhat. Butchering=3. |
| `base:lumberjack` | Lumberjack | 55 | 0.85x | Physical hardship tolerance but no violence. |
| `base:fitnessinstructor` | Fitness Instructor | 60 | 0.9x | Physical resilience but emotionally civilian. |
| `base:carpenter` | Carpenter | 50 | 0.75x | No violence baseline. |
| `base:constructionworker` | Construction Worker | 50 | 0.75x | Physical toughness but emotional civilian. |
| `base:mechanic` | Mechanic | 50 | 0.75x | No violence or death baseline. |
| `base:electrician` | Electrician | 50 | 0.75x | No violence or death baseline. |
| `base:repairman` | Repairman | 50 | 0.75x | No violence or death baseline. |
| `base:fisherman` | Fisherman | 50 | 0.8x | Tolerates isolation. Some animal butchering. |
| `base:engineer` | Engineer | 50 | 0.75x | Academic/technical, no violence baseline. |
| `base:smither` | Smither | 50 | 0.75x | Physical labor, no violence baseline. |
| `base:chef` | Chef | 50 | 0.8x | Butchering=2; some desensitization to raw meat/blood. |
| `base:burgerflipper` | Burger Flipper | 45 | 0.7x | Civilian service job. |
| `base:tailor` | Tailor | 45 | 0.7x | Civilian craft job. |
| `base:burglar` | Burglar | 55 | 0.9x | Criminal background; some stress tolerance from high-risk lifestyle. |
| `base:unemployed` | Unemployed | 45 | 0.65x | No special resilience. Starts lowest. |

**Implementation note:** Occupation is readable at character creation via `player:getDescriptor():getProfession()` which returns the profession ID string. This must be captured during `OnCreatePlayer` or `OnNewGame` and stored in ModData.

**Veteran special case:** Since Veteran already has `base:desensitized`, the mod should detect this during init and set their stage to Desensitized immediately, suppressing all stage-transition logic. Their sanity meter still exists but they decay more slowly and cannot trigger the panic-related traits since mutual exclusions apply.

---

## 3. Addiction Traits

### Vanilla addiction traits confirmed

Only one dedicated addiction trait exists in vanilla B42:

| ID | Display Name | Cost | Effect | Source |
|----|-------------|------|--------|--------|
| `base:smoker` | Smoker | -3 | Needs cigarettes; mutually exclusive with `base:athletic` | `reference/vanilla_traits.md:123` confirmed `CharacterTrait.SMOKER` at `shared/Items/SpawnItems.lua:236` |

There is NO vanilla `base:alcoholic` trait in B42. The Drunk moodle (`Moodles_Drunk_*` at `shared/Translate/EN/Moodles.json:66-69`) exists as a temporary state, not a trait. Alcohol dependency must be a custom trait if implemented.

### Trackable consumption habits

The mod can detect these via item type or item tags consumed through `ISEatFoodAction`:

| Habit | Detection Method | Vanilla Item Reference | Proposed Custom Trait ID |
|-------|----------------|----------------------|--------------------------|
| Smoking | Item has `ItemTag.SMOKABLE` tag — confirmed `shared/TimedActions/ISEatFoodAction.lua:303`: `item:hasTag(ItemTag.SMOKABLE)`. Also `item:getFullType()=="Base.Cigarettes"` confirmed at `shared/TimedActions/ISEatFoodAction.lua:143` | `Base.Cigarettes`, `Base.CigaretteRolled` | `base:smoker` (vanilla, already exists) |
| Alcohol | Items with `UnhappyChange` reduction and `IntoxicationChange` > 0. The `CharacterStat.INTOXICATION` stat is confirmed at `shared/Foraging/forageSystem.lua:1745`. Drunk moodle confirmed at `Moodles.json:66-69` | Beer, Whiskey, Wine (Base.Beer etc.) | `sanitymod:alcoholic` (custom trait, -4) |
| Painkillers | Items with `DrugType` or relevant tags consumed while injured (Beta Blockers, painkillers). No dedicated vanilla addiction trait exists. | `Base.PillsPainKillers`, `Base.BetaBlockers` | `sanitymod:painkiller_dependent` (custom trait, -3) |

### Addiction detection architecture

Track consumption count in ModData. At entry to Depressed stage, check which substance has the highest count:
- If cigarettes consumed >= threshold → apply `base:smoker`
- If alcohol consumed >= threshold → apply `sanitymod:alcoholic`
- If painkillers consumed >= threshold → apply `sanitymod:painkiller_dependent`
- If nothing over threshold → apply no addiction trait (character has no dominant habit)

Only one addiction trait should be applied per character. If multiple substances qualify, take the one with the highest count.

The `Events.OnZombiesDead` event is not usable for item consumption tracking. Instead, hook `Events.OnContainerUpdate` or override/hook into the `ISEatFoodAction:complete()` path via `Events.OnTick` plus player stat sampling. The simplest B42-compatible approach is an `EveryTenMinutes` check on a ModData counter that is incremented by a wrapper around `ISEatFoodAction`.

---

## 4. Desensitized Trait

### Decision: Use vanilla `base:desensitized` directly

Evidence:
- `base:desensitized` is a real B42 profession-only trait (`reference/vanilla_traits.md:145`)
- It is granted to `base:veteran` via `GrantedTraits` (`reference/occupations.md:57`)
- The game checks `CharacterTrait.DESENSITIZED` in two separate combat/looting contexts (`ISCraftAction.lua:20`, `ISInventoryTransferAction.lua:129`) to skip stress/unhappiness buildup
- It is mutually exclusive with all panic-inducing traits (`hemophobic`, `agoraphobic`, `claustrophobic`, `cowardly`)

### What Desensitized negates (confirmed from source)

| Negated Effect | Source |
|----------------|--------|
| Stress from looting corpses | `shared/TimedActions/ISCraftAction.lua:20` — `if not character:hasTrait(CharacterTrait.DESENSITIZED)` |
| Stress/unhappiness from looting corpse inventory | `client/TimedActions/ISInventoryTransferAction.lua:129` — same guard |
| Panic moodle in general | Vanilla mechanic of Veteran profession |
| `base:hemophobic` (blood panic) | Mutual exclusion `reference/vanilla_traits.md:114` |
| `base:agoraphobic` (outdoor panic) | Mutual exclusion `reference/vanilla_traits.md:115` |
| `base:claustrophobic` (indoor panic) | Mutual exclusion `reference/vanilla_traits.md:116` |
| `base:cowardly` | Mutual exclusion `reference/vanilla_traits.md:133` |

### Custom ModData flag

Even though the trait itself is vanilla, store `sanitymod.stage = "desensitized"` in player ModData. This allows:
- Distinguishing a mod-induced Desensitized from a Veteran's natural one
- Enabling future recovery paths from Desensitized
- Correctly restoring traits if the player somehow recovers (custom logic)

---

## 5. Recovery Sources

### Confirmed game mechanics that reduce `CharacterStat.UNHAPPINESS`

| Action | Effect | Source |
|--------|--------|--------|
| Reading literature (comic books, magazines, fiction) | Caps unhappiness at start-of-read value while reading; `item:getUnhappyChange() < 0` triggers the cap | `shared/TimedActions/ISReadABook.lua:72-75` — `stats:set(CharacterStat.UNHAPPINESS, self.stats.unhappiness)` |
| Washing with soap | `-2 UNHAPPINESS` per body part washed | `shared/TimedActions/ISWashYourself.lua:122-123` |
| Harvesting flowers (farming) | `remove(CharacterStat.UNHAPPINESS, numberOfVeg/2)` | `server/Farming/SFarmingSystem.lua:339` |
| Radio/TV entertainment | `stats:add(CharacterStat.UNHAPPINESS, amount * 5)` with negative amounts from entertainment programming | `shared/RadioCom/ISRadioInteractions.lua:34-40` |
| Crafting (selected items) | Some craft recipes apply negative unhappiness change via `UnhappyChange` item property | `shared/TimedActions/ISCraftAction.lua` via item property |
| Quality food with negative `UnhappyChange` | Food items have `getUnhappyChange()` — confirmed tooltip display `client/ISUI/ISInventoryPaneContextMenu.lua:2075-2078`. Cooked meals significantly reduce unhappiness. | Java item property |
| Sleeping | Indirect: alleviates Tired moodle which compounds with Unhappy moodle's action-time penalty. No direct unhappiness removal confirmed in Lua source, but sleep quality traits affect fatigue recovery. | `shared/TimedActions/ISBaseTimedAction.lua:102` (UNHAPPY slows timed actions) |

### Confirmed game mechanics that reduce `CharacterStat.STRESS`

| Action | Effect | Source |
|--------|--------|--------|
| Harvesting flowers | `remove(CharacterStat.STRESS, numberOfVeg/2)` | `server/Farming/SFarmingSystem.lua:341` |
| Radio/TV entertainment | `doStat("Stress", ...)` with negative values | `shared/RadioCom/ISRadioInteractions.lua:45-76` |
| Time (passive) | `StressDecrease = 0.00003` per tick | `shared/defines.lua:21` |

### Confirmed game mechanics that increase `CharacterStat.UNHAPPINESS`

| Trigger | Effect | Source |
|---------|--------|--------|
| High `UNHAPPY` moodle | All timed action durations `* (1 + moodleLevel/4)` — spirals into more frustration | `shared/TimedActions/ISBaseTimedAction.lua:102` |
| Looting corpse inventory (non-Desensitized) | `add(CharacterStat.UNHAPPINESS, rate/100)` | `client/TimedActions/ISInventoryTransferAction.lua:134` |
| Crafting from corpse inventory (non-Desensitized) | `add(CharacterStat.UNHAPPINESS, rate/100)` | `shared/TimedActions/ISCraftAction.lua:26` |
| Passive baseline increase | `UnhappinessIncrease = 0.0005` per tick | `shared/defines.lua:25` |

### Usable game events for mod sanity hooks

| Event | Use |
|-------|-----|
| `Events.OnZombiesDead` | Increment kill counter; sample mood at kill time to weight sanity damage (killing while Miserable = more damage) |
| `Events.EveryTenMinutes` | Sanity decay tick; check stage transitions; apply/remove traits |
| `Events.OnCreatePlayer` / `Events.OnNewGame` | Initialize ModData with starting sanity from occupation profile |
| `Events.OnInitGlobalModData` | Load/restore ModData across saves |
| `Events.OnGameBoot` | Register custom traits |

Source: `reference/events.md` lines 28-47

---

## 6. Table Stakes vs Differentiators

### Table Stakes — must work for the mod to feel worthwhile

| Feature | Why Non-Negotiable |
|---------|-------------------|
| Four-stage progression (Sad → Depressed → Traumatized → Desensitized) | Core premise of the mod |
| Trait application/removal at each transition | Without this, there is no mechanical consequence to the stages |
| Kill-count-based sanity decay | The central input; without it the mod has no driving force |
| Unhappiness moodle-weighted decay | Ensures the mood system matters; prevents the mod from being purely mechanical |
| Occupation starting sanity (at minimum Veteran = hardened, Unemployed = lowest) | Without this all characters feel identical |
| ModData persistence across saves | Stage must survive save/load or the mod is broken |
| Veteran / `base:desensitized` detection on init | Without this Veteran players get double-desensitized and trait mutation errors |
| Mutual exclusion safety before applying traits | Without explicit checks, `player:getTraits():add()` will silently apply conflicting traits and corrupt character stats |

### Differentiators — polish that makes the mod excellent

| Feature | Value |
|---------|-------|
| Habit-based addiction tracking (not just a random addiction) | Makes the Depressed stage feel earned and personal |
| Occupation-specific decay thresholds (not just starting sanity) | Soldiers really do feel different from civilians over time |
| Recovery path (sanity can improve with sustained positive behavior) | Avoids the one-way death spiral that makes mods feel punishing rather than dramatic |
| Per-occupation trait tendency weights (nurses get `base:slowhealer` last, not first) | Nuanced personality profiles |
| Sandbox settings for decay rate, stage thresholds, recovery enabled/disabled | Respects different play styles |

### Anti-Features — deliberately NOT building in v1

| Anti-Feature | Why to Avoid | Alternative |
|--------------|-------------|-------------|
| UI panel showing sanity meter or stage name | Violates the "no UI in v1" design goal; also breaks immersion | Player infers stage from accumulating negative traits |
| Multiplayer support | `DisabledInMultiplayer` concerns, stat sync complexity, `isServer()`/`isClient()` split | Scope to singleplayer via `DisabledInMultiplayer = true` on custom traits if needed |
| Per-kill-type weighting (zombie vs. human kills weighted differently) | `Events.OnZombiesDead` only fires for zombies; human kills would require combat detection hacks | Defer to v2; use kill count uniformly |
| Custom moodle icons | Requires asset work, not code | Use existing Unhappy moodle as the visible proxy |
| Integration with other mods (Antibodies, Superb Survivors, etc.) | Inter-mod dependencies create fragility | Write defensively with nil checks on any third-party globals |
| Automatic occupation detection changes mid-game | Profession does not change after character creation; detection is one-time | Keep it one-time on `OnNewGame` |
| Custom animations or sounds for breakdowns | Requires animator involvement | v2 scope |

---

## 7. Phase-Specific Implementation Notes

### Trait ID spelling warnings (source-verified)

These IDs have non-obvious formatting that will silently fail if spelled incorrectly:

| Correct ID | Common Misspelling | Source |
|------------|-------------------|--------|
| `base:out of shape` | `base:outofshape`, `base:out_of_shape` | `reference/vanilla_traits.md:111` — exact string with spaces |
| `base:insomniac` | `base:insomiac`, `base:restlesssleeper` | `reference/vanilla_traits.md:110` — "Restless Sleeper" is NOT a B42 trait ID |
| `base:needsmoresleep` | `base:needs_more_sleep`, `base:heartysleeper` | `reference/vanilla_traits.md:118` — no underscores |
| `base:hemophobic` | `base:haemophobic` | `reference/vanilla_traits.md:114` |
| `base:disorganized` | `base:disorganised` | `reference/vanilla_traits.md:108` |
| `base:desensitized` | `base:desensitised` | `reference/vanilla_traits.md:145` |
| `base:pacifist` | `base:pacificist` | `reference/vanilla_traits.md:113` |

### CharacterTrait enum constants (for use with `HasTrait`)

These Lua constants are confirmed in game source and are more reliable than raw strings for `HasTrait()` calls:

| Constant | String equivalent |
|----------|------------------|
| `CharacterTrait.DESENSITIZED` | `"base:desensitized"` — `shared/Items/SpawnItems.lua:221` |
| `CharacterTrait.SMOKER` | `"base:smoker"` — `shared/Items/SpawnItems.lua:236` |
| `CharacterTrait.COWARDLY` | `"base:cowardly"` — `shared/TimedActions/ISCraftAction.lua:22` |
| `CharacterTrait.HEMOPHOBIC` | `"base:hemophobic"` — `shared/TimedActions/ISCraftAction.lua:29` |
| `CharacterTrait.DISORGANIZED` | `"base:disorganized"` — `client/ISUI/ISCraftingUI.lua:15` |
| `CharacterTrait.OUT_OF_SHAPE` | `"base:out of shape"` — `server/XpSystem/XpUpdate.lua:230` |
| `CharacterTrait.INSOMNIAC` | `"base:insomniac"` — `client/OptionScreens/CharacterCreationProfession.lua:889` |
| `CharacterTrait.NEEDS_MORE_SLEEP` | `"base:needsmoresleep"` — `client/OptionScreens/CharacterCreationProfession.lua:889` |
| `CharacterTrait.WEAK` | `"base:weak"` — `server/XpSystem/XpUpdate.lua:209` |
| `CharacterTrait.FEEBLE` | `"base:feeble"` — `server/XpSystem/XpUpdate.lua:210` |

Use the `CharacterTrait.X` constant form with `HasTrait()` where possible — these are Java-backed enums and more stable than raw string comparison.

---

## Sources

All findings are HIGH confidence — sourced from game files, not web searches.

- `reference/vanilla_traits.md` — All vanilla trait IDs, costs, mutual exclusions (B42 authoritative)
- `reference/occupations.md` — All vanilla professions with costs, skills, granted traits
- `reference/traits.md` — Trait creation API, runtime add/remove pattern
- `reference/events.md` — Event system, OnZombiesDead, EveryTenMinutes etc.
- `ProjectZomboid/media/lua/shared/TimedActions/ISCraftAction.lua:20-33` — Desensitized + Cowardly + Hemophobic game checks
- `ProjectZomboid/media/lua/client/TimedActions/ISInventoryTransferAction.lua:129-141` — Desensitized + Cowardly checks for corpse looting
- `ProjectZomboid/media/lua/shared/TimedActions/ISReadABook.lua:72-75,163-165` — Book reading reduces unhappiness/boredom/stress
- `ProjectZomboid/media/lua/shared/TimedActions/ISWashYourself.lua:122-123` — Soap washing reduces unhappiness
- `ProjectZomboid/media/lua/server/Farming/SFarmingSystem.lua:339-341` — Harvesting flowers reduces unhappiness/boredom/stress
- `ProjectZomboid/media/lua/shared/RadioCom/ISRadioInteractions.lua:25-40` — TV/radio reduces boredom and unhappiness
- `ProjectZomboid/media/lua/shared/defines.lua:21-25` — Baseline rates for stress decrease and unhappiness increase
- `ProjectZomboid/media/lua/shared/TimedActions/ISBaseTimedAction.lua:102` — UNHAPPY moodle slows all timed actions
- `ProjectZomboid/media/lua/shared/TimedActions/ISEatFoodAction.lua:143,303` — Cigarette/smokable detection
- `ProjectZomboid/media/lua/shared/Foraging/forageSystem.lua:1745` — CharacterStat.INTOXICATION confirmed
- `ProjectZomboid/media/lua/shared/Translate/EN/Moodles.json:42-45,66-69` — Unhappy (Sad/Weepy/Miserable/Hopeless) and Drunk moodle names confirmed
- `ProjectZomboid/media/lua/server/XpSystem/XpUpdate.lua:209-238` — CharacterTrait.OUT_OF_SHAPE dynamic add/remove confirms the fitness system already manages this trait
- `ProjectZomboid/media/lua/client/OptionScreens/CharacterCreationProfession.lua:889` — CharacterTrait.INSOMNIAC, NEEDS_LESS_SLEEP, NEEDS_MORE_SLEEP enum names confirmed
- `ProjectZomboid/media/lua/client/ISUI/ISCraftingUI.lua:15` — CharacterTrait.DISORGANIZED enum name confirmed
