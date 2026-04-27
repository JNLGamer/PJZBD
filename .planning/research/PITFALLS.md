# Domain Pitfalls: Sanity_traits (Project Zomboid B42)

**Domain:** PZ B42 mod — persistent custom meter, runtime trait mutation, kill events, occupation detection, sandbox config
**Build:** SVN Revision 964 (B42)
**Researched:** 2026-04-27
**Sources:** `reference/` docs, `reference/examples/`, `ProjectZomboid/media/lua/` game source

---

## 1. ModData Pitfalls

### Pitfall 1-A: Using Global ModData for per-character data (wrong storage type)

**What goes wrong:** `ModData.getOrCreate("Sanity_SaveData")` is *global* — one entry for the entire save, not per character. In multiplayer (even if you never intend it) two players would share the same sanity table. Even in singleplayer, if you ever store `playerIndex`-keyed data and the key type is wrong (Lua table vs Java string), the save silently uses defaults after reload.

**Prevention:** Use `player:getModData()` for all per-character state (sanity level, kill counts, current stage, addictions). This table is written automatically with the character save file — no extra work, no transmit call required.

Correct pattern (from `reference/examples/moddata_usage.lua`):
```lua
local function getSanityData(player)
    local md = player:getModData()
    if not md.Sanity then
        md.Sanity = { level = 100, stage = 0, kills = 0 }
    end
    return md.Sanity
end
```

**Warning sign:** You wrote to `ModData.getOrCreate()` and the values reset on every game load.
**Phase affected:** Phase 1 (ModData foundation).

---

### Pitfall 1-B: Reading player ModData before the player object exists

**What goes wrong:** Accessing `getPlayer():getModData()` during `OnGameBoot` or at module load time returns `nil` because the player object does not exist yet. The call silently crashes the Lua environment or reads a stale/nil table.

**Prevention:** Seed and read player ModData only inside event handlers that receive the player as a parameter or fire after the world is live. Safe hooks: `OnCreatePlayer(playerIndex, player)`, `OnGameStart`, `OnInitGlobalModData`. The `OnInitGlobalModData` event receives `isNewGame` which lets you distinguish a fresh save from a reload.

Correct initialization timing (from `reference/moddata.md` and game source `SpawnItems.lua` which hooks both `OnNewGame` and `OnGameStart`):
```lua
local function onInitModData(isNewGame)
    -- Global ModData for SP-only globals (if any)
    local data = ModData.getOrCreate("Sanity_GlobalData")
    if isNewGame then
        data.version = 1
    end
end
Events.OnInitGlobalModData.Add(onInitModData)

local function onCreatePlayer(playerIndex, player)
    local md = player:getModData()
    if not md.Sanity then
        md.Sanity = { level = 100, stage = 0, kills = 0, npckills = 0 }
    end
end
Events.OnCreatePlayer.Add(onCreatePlayer)
```

**Warning sign:** Lua error `attempt to index a nil value (global 'getPlayer')` or `attempt to call method 'getModData' (a nil value)` on startup.
**Phase affected:** Phase 1.

---

### Pitfall 1-C: Key naming collisions with other mods

**What goes wrong:** Using a generic key like `"SanityData"` or `"playerData"` for `player:getModData()` fields will silently collide with any other mod using the same key. The second mod to write wins; the first mod's data is corrupted or overwritten.

**Prevention:** Always namespace your ModData keys with your mod ID. Use a single top-level key:
```lua
md.Sanity_traits = md.Sanity_traits or { level = 100, stage = 0 }
```
Never use bare generic keys like `"kills"`, `"data"`, `"mod"`, `"points"`.

**Warning sign:** Data randomly resets or is wrong when a second mod is active; works fine in isolation.
**Phase affected:** Phase 1.

---

### Pitfall 1-D: `ModData.transmit()` is a no-op concern in singleplayer — but causes confusion

**What goes wrong:** `ModData.transmit("key")` is only meaningful in multiplayer. In singleplayer it does nothing harmful, but including it unconditionally causes confusion and may trigger errors if called at the wrong lifecycle moment.

**Prevention:** For a singleplayer-only mod, do not call `ModData.transmit()`. Per-player `getModData()` auto-saves. If you use Global ModData for any shared state, it also persists automatically.

**Warning sign:** You are calling `ModData.transmit()` and wondering why data is not arriving anywhere.
**Phase affected:** Phase 1.

---

## 2. Trait Runtime Pitfalls

### Pitfall 2-A: Double-application of a trait

**What goes wrong:** Calling `player:getTraits():add("Sanity_Depressed")` without first checking `player:hasTrait(characterTraitDefinition)` will apply the trait twice, doubling any XP penalty or other numeric effect. The trait list is a Java ArrayList — it allows duplicate entries.

**Prevention:** Always guard with a presence check:
```lua
if not player:hasTrait(traitType) then
    player:getTraits():add("Sanity_Depressed")
end
```
The game's own debug UI does this check (confirmed in `ISPlayerStatsChooseTraitUI.lua` line 26: `if not self.chr:hasTrait(characterTraitDefinition:getType()) then`).

**Warning sign:** Negative mood / XP effects are twice as strong as expected after a stage transition.
**Phase affected:** Phase 2 (stage transitions).

---

### Pitfall 2-B: Removing a trait that is not present crashes or silently corrupts

**What goes wrong:** Calling `player:getTraits():remove("Sanity_Sad")` when the trait is not in the list does not throw a visible Lua error but removes the wrong index from a Java ArrayList (Java `remove(Object)` returns false, which Lua receives as `nil`). In practice the list may become corrupted or the call is silently discarded depending on the Java bridge version.

**Prevention:** Guard every removal:
```lua
if player:hasTrait(traitType) then
    player:getTraits():remove("Sanity_Sad")
end
```

**Warning sign:** After removing a stage, UI trait panel shows phantom entries or the wrong trait is gone.
**Phase affected:** Phase 2.

---

### Pitfall 2-C: Trait IDs in B42 are `module:id` strings, not plain strings

**What goes wrong:** In B42 traits are defined as `character_trait_definition base:mymod_sad` with ID `base:mymod_sad`. But some API calls accept the full `module:id` string while others want only the local `id` part. Passing the wrong format causes `hasTrait` to always return false and `add`/`remove` to silently fail.

**Prevention:** Register traits under `module Base {}` and use the full colon-separated ID everywhere. Confirm the format used in `CharacterTrait` constants — the game uses e.g. `CharacterTrait.DESENSITIZED` as an opaque Java object, not a raw string. When calling `player:hasTrait()` from Lua you may need to pass a `CharacterTraitType` object, not a raw string. Cross-check with vanilla usage in `ISPlayerStatsChooseTraitUI.lua` which uses `characterTraitDefinition:getType()` as the argument to `hasTrait`, not a string literal.

**Warning sign:** `player:hasTrait("base:mymod_sad")` always returns false even after you called `add`.

**LOW confidence note:** The exact Java bridge call signature for `hasTrait` with custom trait IDs in B42 was not directly confirmed from game source — needs validation during Phase 2 development with in-game testing.
**Phase affected:** Phase 2.

---

### Pitfall 2-D: `MutuallyExclusiveTraits` in the .txt definition does not enforce runtime add/remove

**What goes wrong:** The `MutuallyExclusiveTraits` field in `character_trait_definition` only enforces exclusion at character creation (the UI greys out conflicting choices). At runtime, calling `player:getTraits():add()` bypasses this check entirely. You can end up with `Sanity_Sad` and `Sanity_Desensitized` simultaneously on the same character.

**Prevention:** When applying a new sanity stage, explicitly remove the previous stage trait:
```lua
local function transitionTo(player, newStage, oldStage)
    if oldStage and player:hasTrait(oldStage) then
        player:getTraits():remove(oldStage)
    end
    if not player:hasTrait(newStage) then
        player:getTraits():add(newStage)
    end
end
```

**Warning sign:** Player has multiple conflicting stage traits active simultaneously; effects stack.
**Phase affected:** Phase 2.

---

### Pitfall 2-E: `IsProfessionTrait = true` traits cannot be added at runtime by the player

**What goes wrong:** Traits with `IsProfessionTrait = true` are hidden from the trait selection UI and intended to be granted by a profession's `GrantedTraits`. They can still be added via `player:getTraits():add()` at runtime, but doing so may confuse the character screen display and makes them invisible in the trait list panel.

**Prevention:** All sanity stage traits should use `IsProfessionTrait = false`. Reserve `IsProfessionTrait = true` only for profession-locked traits. The "hidden/invisible to the player" requirement for sanity traits should be achieved through a separate `IsHidden` or similar display field if available, or simply accepted that they appear in the trait list.

**Warning sign:** Runtime-added trait never appears in the character screen even though `hasTrait` returns true.
**Phase affected:** Phase 2.

---

## 3. Event Timing Pitfalls

### Pitfall 3-A: `OnHitZombie` fires on every hit, not on kill — wrong event for kill detection

**What goes wrong:** The reference `events.md` lists `OnWeaponHitCharacter` and game source confirms `OnHitZombie`. These fire on every weapon contact with a zombie, not when the zombie dies. Using either of these to detect a kill will trigger your sanity effect every time the player swings, not just on death. A single kill could fire 3–15 sanity events.

**Prevention:** Use `OnZombiesDead` which fires when a zombie's health reaches zero. This is the canonical kill event. The reference `events.md` documents it as:
```lua
Events.OnZombiesDead.Add(function(zombie) ... end)
```
Note: the event name is `OnZombiesDead` (plural), not `OnZombieDead`. Getting the name wrong results in silently no-op event registration.

**Warning sign:** Sanity drops multiple times per kill; drops when player misses or hits but zombie survives.
**Phase affected:** Phase 1 (kill hook wiring).

---

### Pitfall 3-B: `OnZombiesDead` does not directly tell you which player killed the zombie

**What goes wrong:** The `OnZombiesDead` event passes the zombie object, not the killer. In singleplayer there is only one player so `getPlayer()` is always the right answer, but if you write a handler that assumes a passed `killer` parameter, it will always be nil.

**Prevention:** In singleplayer, resolve the killer as `getPlayer()` or `getSpecificPlayer(0)` inside the handler. Do not try to read a `killer` field from the zombie object — there is no such field exposed to Lua in the events system as of B42 (LOW confidence: not definitively confirmed from game source, but no evidence of it was found in any game Lua file).

**Warning sign:** `zombie.killer` or `zombie:getAttacker()` returns nil, causing a crash in the handler.
**Phase affected:** Phase 1.

---

### Pitfall 3-C: NPC/survivor kill detection has no dedicated event in vanilla B42

**What goes wrong:** There is no `OnSurvivorDead` or `OnNPCDead` event in the vanilla event list. `OnPlayerDeath` fires only when the local player dies. The `OnWeaponHitCharacter` event fires when a weapon hits any character (human or zombie) but not specifically on death.

**Prevention:** For survivor/NPC kill detection, hook `OnWeaponHitCharacter`, inspect the `target` parameter, and check `target:isDead()` after the hit. Alternatively, poll `getPlayer():getNPCKills()` on a timed event if that Java method exists (LOW confidence — verify during Phase 1 dev). Flag this as needing phase-specific investigation.

**Warning sign:** Killing an NPC survivor does not trigger your sanity handler at all.
**Phase affected:** Phase 1 — needs deeper research before implementation.

---

### Pitfall 3-D: `OnTick` is called every single game tick (30–60 times per second) — never do work there

**What goes wrong:** Putting any non-trivial logic in `OnTick` — even a simple ModData read — will tank performance. A sanity check that runs 30 times per second when the player kills a zombie will cause hitches, especially if it involves string operations (stage comparisons), trait checks (Java bridge calls), or conditional logic.

**Prevention:** Do not use `OnTick` for periodic sanity decay or stage evaluation. Use time-gated events instead:
- `EveryOneMinute` for frequent but not per-frame checks (in-game minutes, not real time)
- `EveryTenMinutes` for slower periodic decay
- `EveryHours` for long-term state checks

Save `OnTick` only for things that genuinely need per-frame attention (e.g. UI rendering). The game itself uses `EveryHours` and `EveryDays` for heavy system updates (confirmed in `forageSystem.lua`).

**Warning sign:** Frame rate noticeably drops with the mod active; CPU profile shows Lua taking 20%+ of frame time.
**Phase affected:** Phase 1 and Phase 3 (timed decay).

---

### Pitfall 3-E: Registering the same event handler multiple times

**What goes wrong:** If a file is `require`d more than once (or reloaded via the debug console), `Events.X.Add(handler)` gets called again and your handler runs twice per event. This doubles sanity penalties per kill.

**Prevention:** Use named module-level functions registered once at file load. Never register inside a function that can be called multiple times. Use `Events.X.Remove(handler)` defensively before re-adding if there is any risk of duplicate registration.

**Warning sign:** Sanity drops by double the expected amount; two notifications fire per kill.
**Phase affected:** All phases.

---

## 4. Occupation Detection Pitfalls

### Pitfall 4-A: Attempting to read profession during `OnGameBoot` — player object does not exist yet

**What goes wrong:** `OnGameBoot` fires before the game world is loaded and before any player object exists. Calling `getPlayer()` returns `nil`. Calling `getPlayer():getDescriptor():getCharacterProfession()` crashes with a nil access error.

**Prevention:** Read the profession in `OnCreatePlayer(playerIndex, player)` or `OnGameStart`. Both fire after the player object is created and fully initialized. The game's own `SpawnItems.lua` reads profession inside its `OnNewGame` and `OnGameStart` handlers, not during `OnGameBoot`.

Safe pattern (derived from `SpawnItems.lua` and `ISCharacterScreen.lua`):
```lua
local function onCreatePlayer(playerIndex, player)
    local descriptor = player:getDescriptor()
    if descriptor and descriptor:getCharacterProfession() then
        local profName = descriptor:getCharacterProfession():getName()
        -- set psyche profile based on profName
    end
end
Events.OnCreatePlayer.Add(onCreatePlayer)
```

**Warning sign:** Lua error `attempt to index a nil value` on game load; error points to profession detection code.
**Phase affected:** Phase 4 (occupation psyche profiles).

---

### Pitfall 4-B: `getCharacterProfession()` can return nil on certain NPC characters

**What goes wrong:** The game code itself guards `getCharacterProfession()` with a nil check before proceeding (confirmed in `SpawnItems.lua` line 188: `if playerObj:getDescriptor():getCharacterProfession() then`). An NPC passed to a shared event might not have a profession set.

**Prevention:** Always nil-check the return value:
```lua
local prof = player:getDescriptor():getCharacterProfession()
if not prof then return end
local profName = prof:getName()
```

**Warning sign:** Profession detection works for the player but crashes when an NPC triggers the same code path.
**Phase affected:** Phase 4.

---

### Pitfall 4-C: Profession name string vs profession object comparison

**What goes wrong:** `getCharacterProfession()` returns a Java `CharacterProfession` object, not a string. Comparing it directly with a string (`if prof == "base:veteran"`) always returns false. The correct check is `descriptor:isCharacterProfession(CharacterProfession.VETERAN)` using the enum constant, or `prof:getName() == "base:veteran"` using the string accessor.

Game source confirms the `isCharacterProfession` pattern (`SpawnItems.lua` line 191, `Vehicles.lua` line 1064).

**Prevention:** Use `descriptor:isCharacterProfession(CharacterProfession.VETERAN)` when checking for specific professions. Build a string-keyed lookup table using `prof:getName()` if you need dynamic dispatch by profession ID.

**Warning sign:** All characters resolve to the "default" psyche profile regardless of their chosen profession.
**Phase affected:** Phase 4.

---

## 5. Sandbox Options Pitfalls

### Pitfall 5-A: `SandboxVars.MyMod_Setting` is nil on saves created before the mod was installed

**What goes wrong:** `SandboxVars` is initialized from the save file's sandbox data. If a player loads an old save that was created before your sandbox options were defined, the keys for your options simply do not exist — they are `nil`, not a default value. Code like `if SandboxVars.Sanity_EnableMod then` will evaluate as `false` (nil is falsy) which may silently disable your mod on pre-existing saves.

**Prevention:** Always read sandbox options with a fallback:
```lua
local enabled = SandboxVars.Sanity_EnableMod
if enabled == nil then enabled = true end  -- default: on
```
Or use `getSandboxOptions():getOptionByName("Sanity_EnableMod")` and call `:getValue()` — this returns the registered default if the key is missing (confirmed pattern in `SPlantGlobalObject.lua` and `forageSystem.lua`).

**Warning sign:** Mod appears to do nothing when loaded on an existing save that predates the mod; fresh game works fine.
**Phase affected:** Phase 5 (sandbox config).

---

### Pitfall 5-B: Reading `SandboxVars` before `OnInitGlobalModData` fires

**What goes wrong:** `SandboxVars.lua` is initialized via `getSandboxOptions():initSandboxVars()` which runs when the Sandbox module loads. However, custom mod sandbox options added to the game's option system may not be available at module-load time. Reading them in a `require`d file's top-level scope (outside any event handler) risks reading a nil table.

**Prevention:** Read sandbox options inside event handlers that fire after world load: `OnInitGlobalModData`, `OnGameStart`, or on first use inside a kill/tick handler. Cache the result in a module-level variable after first read.

**Warning sign:** `SandboxVars.Sanity_X` is nil at startup but non-nil inside an in-game event handler.
**Phase affected:** Phase 5.

---

### Pitfall 5-C: `getSandboxOptions():getOptionByName()` returns nil for unregistered names

**What goes wrong:** If you typo the option name or call it before your options are registered, `getOptionByName` returns nil and calling `:getValue()` on nil crashes.

**Prevention:**
```lua
local opt = getSandboxOptions():getOptionByName("Sanity_SanityDecayRate")
local rate = opt and opt:getValue() or 5  -- safe fallback
```

**Warning sign:** Lua error `attempt to index a nil value` when reading sandbox options.
**Phase affected:** Phase 5.

---

## 6. B42-Specific Breaking Changes

### Pitfall 6-A: Trait and profession definitions moved from Lua to `.txt` script files

**What goes wrong:** The B41 pattern was to define traits entirely in Lua via `TraitFactory.addTrait(...)` registered in `OnGameBoot`. In B42, the canonical approach is `character_trait_definition` in a `.txt` script file under `media/scripts/characters/`. Traits defined only via `TraitFactory` in Lua may still work (the API is not removed) but they will not appear correctly in the B42 character creation screen and will lack proper integration with the new script system.

**Prevention:** Define all sanity stage traits in `.txt` script files as `character_trait_definition base:sanity_sad { ... }`. Only use `TraitFactory` Lua API for runtime manipulation (add/remove), not for initial registration.

**Warning sign:** Traits do not appear in character creation even though they seem registered; trait icons are broken; `CharacterTraitDefinition.getTraits()` does not list your mod's traits.
**Phase affected:** Phase 2 (trait definitions).

---

### Pitfall 6-B: `OnTick` handler signature changed — parameter is `tick` (number), not elapsed time

**What goes wrong:** B41 mod tutorials sometimes show `OnTick` handlers that assume the parameter is a delta-time in seconds. In B42, the parameter is a tick counter (incrementing integer). Using it as elapsed time gives wrong results.

**Prevention:** Do not use `OnTick` for time-based logic. Use `EveryOneMinute`, `EveryTenMinutes`, or `EveryHours` for time-based effects. If you need real-time elapsed tracking, compare `getGameTime():getWorldAgeHours()` snapshots.

**Warning sign:** Timed decay fires at wildly incorrect intervals or not at all.
**Phase affected:** Phase 3 (timed sanity decay).

---

### Pitfall 6-C: `OnZombiesDead` event name (plural) vs B41 pattern

**What goes wrong:** Some older B41 mods and tutorials reference `OnZombieDead` (singular). In the current game event system, the event is `OnZombiesDead` (plural). Registering `Events.OnZombieDead.Add(...)` on a B42 game silently registers against a non-existent event; your handler never fires.

**Prevention:** Use `Events.OnZombiesDead.Add(handler)` exactly as documented in `reference/events.md`.

**Warning sign:** Kill event handler never fires; no Lua error is produced (PZ silently ignores unknown event names).
**Phase affected:** Phase 1.

---

### Pitfall 6-D: `CharacterProfession` enum constants may differ from B41 string IDs

**What goes wrong:** B41 mods often compared profession strings like `"Veteran"` or `"Police Officer"`. In B42, professions are defined as `base:veteran`, `base:policeofficer` etc. in `.txt` files and accessed as Java `CharacterProfession` enum objects. String comparisons against display names will break because `getName()` returns the script ID (e.g. `"base:veteran"`), not the UI display name.

**Prevention:** Use `prof:getName()` and compare against the lowercase script IDs from `occupations.md`: `"base:veteran"`, `"base:policeofficer"`, `"base:doctor"` etc. Or use the `CharacterProfession.VETERAN` constant if available for the professions you care about.

**Warning sign:** Veteran is not detected as a high-psyche profession; all profession checks fall to the default case.
**Phase affected:** Phase 4.

---

## 7. Namespace / Global Pollution Pitfalls

### Pitfall 7-A: Global table name collisions

**What goes wrong:** Declaring a module table as `SanityMod = {}` at the top of a file makes it a global Lua variable. Another mod with the same name silently overwrites it. The second mod to load wins; the first mod's functions are gone.

**Prevention:** Use a unique, specific prefix that includes your mod name. Recommended: `Sanity_traits = Sanity_traits or {}`. The `or {}` guard means if the table already exists (e.g. from another file in the same mod), it is not recreated.

```lua
Sanity_traits = Sanity_traits or {}
Sanity_traits.data = Sanity_traits.data or {}
```

Never use single-word globals: `Sanity`, `Mod`, `Data`, `Manager`.

**Warning sign:** Your mod's functions disappear when another mod is active; functions exist in isolation but are nil in-game.
**Phase affected:** All phases.

---

### Pitfall 7-B: Overwriting vanilla global functions

**What goes wrong:** Defining a function at global scope with a name that matches a vanilla PZ function (e.g. `function getPlayer()`) replaces the vanilla function for all mods loaded after yours. This causes cascading failures across the entire game.

**Prevention:** Never define top-level functions without a namespace prefix. All functions go inside your module table: `function Sanity_traits.applyStage(player, stage) ... end`. If you need to monkey-patch a vanilla function, always call the original:
```lua
local orig_someFunc = someFunc
someFunc = function(...) orig_someFunc(...); Sanity_traits.myAddition(...) end
```

**Warning sign:** Game crashes with errors in unrelated vanilla systems after your mod loads.
**Phase affected:** All phases.

---

### Pitfall 7-C: `require` loading the same file twice from different locations

**What goes wrong:** Lua's `require` uses a module path cache, but PZ's mod loader may load files from both `client/` and `shared/` contexts. If your shared sanity module is `require`d from a client file and also loaded directly, event handlers may register twice (see Pitfall 3-E).

**Prevention:** Put sanity logic that involves player ModData in `shared/` only. Do not split the same logic across `client/` and `shared/` files unless necessary for network separation.

**Phase affected:** All phases.

---

## 8. Performance Traps

### Pitfall 8-A: Java bridge overhead on every tick

**What goes wrong:** Every call through the Lua-Java bridge (e.g. `player:getModData()`, `player:hasTrait(...)`, `player:getDescriptor():getCharacterProfession()`) has non-trivial overhead compared to pure Lua operations. If you put these inside `OnTick`, you are making 30–60 bridge calls per second.

**Prevention:**
- Cache the player object in a module variable after `OnCreatePlayer` fires
- Cache sandbox option values after `OnInitGlobalModData`
- Cache the profession name once at game start — professions do not change during play
- Run the sanity stage evaluation only on `EveryOneMinute` or on kill events, never on `OnTick`

```lua
-- Cache at game start
local _player = nil
local _profName = nil
local _sanityConfig = {}

Events.OnCreatePlayer.Add(function(idx, player)
    _player = player
    local prof = player:getDescriptor():getCharacterProfession()
    _profName = prof and prof:getName() or "base:unemployed"
    _sanityConfig = Sanity_traits.getProfileForProfession(_profName)
end)
```

**Warning sign:** Noticeable lag spike every second; profiler shows Lua bridge calls dominating frame time.
**Phase affected:** All phases.

---

### Pitfall 8-B: String operations inside high-frequency handlers

**What goes wrong:** String concatenation and pattern matching in Lua create garbage. If you do `"Sanity_Depressed_" .. playerName` or call `string.format` inside `OnZombiesDead`, this runs on every kill. On a long play session with hundreds of kills, this generates significant GC pressure.

**Prevention:** Pre-build any lookup strings at initialization time. Use integer stage IDs internally and only convert to string IDs when calling the Java bridge.

**Warning sign:** Progressive performance degradation over a long session; Lua GC pauses become visible.
**Phase affected:** Phase 2 and Phase 3.

---

### Pitfall 8-C: Re-reading ModData on every kill event instead of using a live cache

**What goes wrong:** Calling `player:getModData().Sanity_traits` on every `OnZombiesDead` event is redundant — the ModData table is a live reference, not a copy. But the bridge call to get it still has overhead. More importantly, if you have a bug where you replace the table reference instead of mutating it (e.g. `md.Sanity_traits = newTable`), you lose all accumulated state.

**Prevention:** Always mutate the existing table in-place:
```lua
local sd = player:getModData().Sanity_traits
sd.kills = sd.kills + 1   -- mutate, do not replace
-- NOT: player:getModData().Sanity_traits = { kills = sd.kills + 1 }
```

**Warning sign:** Kill count resets to 0 unexpectedly; sanity state does not persist across a save/load cycle.
**Phase affected:** Phase 1 and Phase 2.

---

## Phase-Specific Warning Summary

| Phase | Topic | Most Likely Pitfall | Mitigation |
|-------|-------|--------------------|-----------| 
| Phase 1 | ModData foundation | Wrong storage type (global vs player) | Use `player:getModData()` always |
| Phase 1 | Kill hook | Wrong event name (`OnZombiesDead` not `OnZombieDead`) | Use exact name from `reference/events.md` |
| Phase 1 | NPC kill detection | No dedicated vanilla event exists | Needs Phase 1 research: test `OnWeaponHitCharacter` + `isDead()` check |
| Phase 2 | Stage trait application | Double-application, wrong trait ID format | Guard every add with `hasTrait` check |
| Phase 2 | Trait definitions | B41-style Lua-only trait registration | Use `.txt` script definitions |
| Phase 3 | Timed decay | Using `OnTick` for period checks | Use `EveryOneMinute` / `EveryTenMinutes` |
| Phase 4 | Occupation detection | Reading profession before player exists | Hook `OnCreatePlayer`, not `OnGameBoot` |
| Phase 4 | Profession comparison | Comparing Java object to string | Use `prof:getName()` with lowercase script IDs |
| Phase 5 | Sandbox options | `nil` on old saves without new options | Always read with fallback defaults |
| All | Namespace | Global table collision | Prefix everything with `Sanity_traits` |
