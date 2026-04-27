# Phase 1: Foundation - Research

**Researched:** 2026-04-28
**Domain:** Project Zomboid Build 42 mod scaffolding — mod.info, ModData, kill events, profession detection
**Confidence:** HIGH

---

## Summary

Phase 1 establishes every piece of infrastructure the remaining six phases depend on: a loadable
mod skeleton, a per-character sanity meter stored in ModData, and hooks for the two kill categories
(zombie and survivor). All five requirements are achievable with well-understood B42 APIs, verified
directly against `ProjectZomboid/media/lua/` game source.

The single most important discovery is a **discrepancy between `reference/events.md` and the actual
game source**. The reference doc lists `OnZombiesDead` and `OnWeaponHitCharacter` as event names —
neither exists in the B42 codebase. The correct events are `OnZombieDead` (singular, confirmed in
`Challenge2.lua` and `Tutorial/Steps.lua`) and `OnWeaponHitXp` (confirmed in `XpUpdate.lua`) for
hit-and-check survivor detection. Plans MUST use the verified names.

Survivor kill detection has no dedicated "on death" event. The correct pattern is to hook
`OnWeaponHitXp` (which provides `owner, weapon, hitObject, damage, hitCount`), check if
`hitObject` is not an `IsoZombie` via `instanceof(hitObject, "IsoZombie")`, and check if
`hitObject:isDead()` is true at that moment to confirm the kill actually happened.

**Primary recommendation:** Use `OnCreatePlayer` to initialize ModData, `OnZombieDead` for zombie
kills, and `OnWeaponHitXp` + `instanceof` + `:isDead()` for survivor kills. Everything in
`media/lua/client/` since this mod is singleplayer only.

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CORE-01 | Invisible sanity meter (0–1000) in `player:getModData()`, initialized on `OnCreatePlayer` | `OnCreatePlayer` event confirmed with `(playerIndex, player)` params; per-player ModData pattern verified from `moddata_usage.lua` and game source |
| CORE-02 | Starting sanity value determined by occupation archetype | Profession ID read via `player:getDescriptor():getCharacterProfession():getName()` — confirmed in `forageSystem.lua:1867` and `LastStandSetup.lua:102`; all 25 vanilla profession IDs documented in `reference/occupations.md` |
| CORE-03 | Killing a zombie reduces sanity by configurable base amount | `OnZombieDead` event confirmed in game source (Challenge2.lua:68, Steps.lua:840); fires with no params in singleplayer — use `getPlayer()` to get the player |
| CORE-04 | Killing a survivor reduces sanity by heavier configurable amount | No `OnNPCDead` event exists; pattern: `OnWeaponHitXp(owner, weapon, hitObject, damage, hitCount)` + `not instanceof(hitObject, "IsoZombie")` + `hitObject:isDead()` |
| DEF-04 | `mod.info` present with valid `name`, `id`, `description`, `modversion`, `pzversion` fields | mod.info format fully documented; example available in `reference/examples/mod.info` |
</phase_requirements>

---

## Standard Stack

### Core

| Library / API | Version | Purpose | Why Standard |
|---------------|---------|---------|--------------|
| Lua (client-side) | PZ B42 embedded | All mod logic | Only language supported for client mods |
| `player:getModData()` | B42 | Per-character persistence | Auto-saved with character file, no extra work |
| `Events.OnCreatePlayer` | B42 | Initialization hook | Fires when player object is created, both new and loaded games |
| `Events.OnZombieDead` | B42 | Zombie kill detection | Confirmed in game source; fires once per zombie death |
| `Events.OnWeaponHitXp` | B42 | Survivor kill detection | Only reliable event providing attacker + target; confirmed in `XpUpdate.lua` |

### Supporting

| Library / API | Version | Purpose | When to Use |
|---------------|---------|---------|-------------|
| `getPlayer()` | B42 | Get singleplayer character | Shorthand; valid in all client callbacks |
| `getSpecificPlayer(i)` | B42 | Get player by index | Use in `OnCreatePlayer` handler since index is provided |
| `instanceof(obj, "ClassName")` | B42 | Type checking | Required to distinguish IsoZombie vs other characters |
| `player:getDescriptor():getCharacterProfession():getName()` | B42 | Read profession string ID | Returns e.g. `"base:unemployed"` — verified in forageSystem.lua |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `OnWeaponHitXp` for survivor kills | `OnHitZombie` | `OnHitZombie` only fires on zombie hits — useless for NPCs |
| Per-player `getModData()` | Global `ModData.getOrCreate()` | Global ModData is per-save, not per-character; wrong for sanity |
| `OnCreatePlayer` init | `OnNewGame` init | `OnNewGame` only fires for new saves; `OnCreatePlayer` fires both new and loaded |

**Installation:** No installation — pure Lua mod, no dependencies.

---

## Architecture Patterns

### Recommended Project Structure

```
Mods/Sanity_traits/
├── mod.info
└── media/
    └── lua/
        └── client/
            ├── 1_SanityTraits_Init.lua      -- namespace + constants
            ├── 2_SanityTraits_ModData.lua   -- ModData init and accessors
            └── 3_SanityTraits_KillEvents.lua -- OnZombieDead + OnWeaponHitXp hooks
```

Files are loaded alphabetically within a folder; numeric prefixes enforce load order.
Everything goes in `client/` for singleplayer-only scope. No `server/` or `shared/` scripts needed in Phase 1.

### Pattern 1: Namespace Table

**What:** Wrap all globals in a single table to avoid polluting the global environment.
**When to use:** Always — every Lua file in the mod.

```lua
-- Source: reference/mod_structure.md
SanityTraits = SanityTraits or {}
SanityTraits.VERSION = "1.0"

-- Default weights (Phase 6 will replace with SandboxVars)
SanityTraits.ZOMBIE_WEIGHT  = 10
SanityTraits.SURVIVOR_WEIGHT = 30
SanityTraits.SANITY_MAX     = 1000
```

### Pattern 2: ModData Initialization on OnCreatePlayer

**What:** Initialize the sanity meter when the player object is created.
**When to use:** CORE-01 — fires for both new characters and loaded saves.

```lua
-- Source: reference/moddata.md + game source ISPerkLog.lua:112
local function onCreatePlayer(playerIndex, player)
    local md = player:getModData()
    if md.SanityTraits == nil then
        -- Only seed defaults if not already present (handles save/reload)
        local profName = player:getDescriptor():getCharacterProfession():getName()
        local startSanity = SanityTraits.getStartingSanity(profName)
        md.SanityTraits = {
            sanity = startSanity,
            appliedStage = "Healthy",
        }
    end
end

Events.OnCreatePlayer.Add(onCreatePlayer)
```

### Pattern 3: Zombie Kill Hook

**What:** Decrement sanity when `OnZombieDead` fires.
**When to use:** CORE-03 — the only confirmed zombie death event in B42.

```lua
-- Source: game source Challenge2.lua:242-257, Tutorial/Steps.lua:913
local function onZombieDead(zed)
    -- In singleplayer, zed is passed but attacker is not -- use getPlayer()
    local player = getPlayer()
    if not player then return end
    local md = player:getModData()
    if not md.SanityTraits then return end
    md.SanityTraits.sanity = md.SanityTraits.sanity - SanityTraits.ZOMBIE_WEIGHT
    print("[SanityTraits] Zombie killed. Sanity: " .. tostring(md.SanityTraits.sanity))
end

Events.OnZombieDead.Add(onZombieDead)
```

**Critical note:** `OnZombieDead` passes `zed` (the zombie object) as a parameter — confirmed in
`Tutorial/Steps.lua:913` (`function FightStep:OnMomDead(zed)`). However the attacker is not
provided. In singleplayer `getPlayer()` is always the attacker.

### Pattern 4: Survivor Kill Hook

**What:** Decrement sanity by heavier weight when player kills a non-zombie character.
**When to use:** CORE-04 — no dedicated survivor-death event exists; this is the best available approach.

```lua
-- Source: game source XpUpdate.lua:48 (OnWeaponHitXp signature)
-- Source: game source OnBreak.lua:62 (instanceof IsoZombie pattern)
local function onWeaponHitXp(owner, weapon, hitObject, damage, hitCount)
    if not owner or not hitObject then return end
    -- Filter: not a zombie, and just died from this hit
    if not instanceof(hitObject, "IsoZombie") and hitObject:isDead() then
        local md = owner:getModData()
        if not md.SanityTraits then return end
        -- Guard against double-counting (hitCount can be > 1)
        -- Use a "lastKilledId" guard if needed in later phases
        md.SanityTraits.sanity = md.SanityTraits.sanity - SanityTraits.SURVIVOR_WEIGHT
        print("[SanityTraits] Survivor killed. Sanity: " .. tostring(md.SanityTraits.sanity))
    end
end

Events.OnWeaponHitXp.Add(onWeaponHitXp)
```

### Pattern 5: Profession Lookup

**What:** Read the player's profession string ID to determine starting sanity.
**When to use:** CORE-02 — called during OnCreatePlayer.

```lua
-- Source: game source forageSystem.lua:1867, LastStandSetup.lua:102
function SanityTraits.getStartingSanity(profName)
    -- Phase 4 will populate a full table; Phase 1 uses simple defaults
    local profiles = {
        ["base:veteran"]     = 200,   -- starts near-desensitized
        ["base:policeofficer"] = 850,
        ["base:securityguard"] = 850,
        ["base:fireofficer"]   = 850,
        ["base:doctor"]        = 900,
        ["base:nurse"]         = 900,
        ["base:parkranger"]    = 900,
    }
    return profiles[profName] or SanityTraits.SANITY_MAX  -- civilian baseline = 1000
end
```

### Anti-Patterns to Avoid

- **Using `OnZombiesDead` or `OnWeaponHitCharacter`:** These event names do NOT exist in B42. The reference doc has wrong names. Use `OnZombieDead` and `OnWeaponHitXp`.
- **Initializing ModData in `OnNewGame` only:** `OnNewGame` does not fire on save/reload. `OnCreatePlayer` fires in both cases; the `if md.SanityTraits == nil then` guard handles the new-game case.
- **Global ModData instead of player ModData:** `ModData.getOrCreate()` is per-save, not per-character. `player:getModData()` is correct for sanity.
- **Assuming `OnZombieDead` provides the attacker:** The event only passes the zombie. In singleplayer `getPlayer()` is safe; for future multiplayer support use `getNumActivePlayers()` loop.
- **Placing singleplayer-only scripts in `shared/`:** Scripts in `shared/` execute on both client and server. Since this mod is singleplayer-only, `client/` is the correct location and avoids accidental server execution.
- **Omitting numeric filename prefix:** PZ loads Lua files alphabetically. Without prefixes, `KillEvents.lua` may load before `Init.lua`, causing nil namespace errors.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Per-character save/load | Custom file I/O | `player:getModData()` | Auto-persists with save; JSON file I/O is fragile and adds save-path management |
| Type discrimination (zombie vs NPC) | String parsing or HP checks | `instanceof(obj, "IsoZombie")` | Built-in Java reflection; reliable, zero-cost |
| Profession identity | String parsing character name/bio | `player:getDescriptor():getCharacterProfession():getName()` | Returns the canonical `module:id` string directly |
| Event system | Polling or tick-based checks | `Events.OnZombieDead.Add(...)` | Native engine callback; no polling overhead |

**Key insight:** The PZ engine already owns persistence, type identity, and event dispatch. Building custom solutions for any of these would duplicate engine features and introduce subtle bugs around save/load timing.

---

## Runtime State Inventory

Step 2.5 SKIPPED — Phase 1 is greenfield. No existing runtime state to migrate.

---

## Environment Availability Audit

Step 2.6 SKIPPED — Phase 1 is pure Lua file creation with no external tools, CLIs, databases, or services. The only requirement is a working PZ B42 installation, which is confirmed at `ProjectZomboid/SVNRevision.txt` (Build 964).

---

## Common Pitfalls

### Pitfall 1: Wrong Event Names from reference/events.md

**What goes wrong:** The planner (or executor) uses `OnZombiesDead` or `OnWeaponHitCharacter` from
`reference/events.md`, registers handlers that never fire, and sanity never changes.
**Why it happens:** `reference/events.md` documents B41-era event names; both were renamed or removed in B42.
**How to avoid:** Use only names verified against `ProjectZomboid/media/lua/`: `OnZombieDead` and `OnWeaponHitXp`.
**Warning signs:** Console shows no `[SanityTraits]` log output after killing a zombie.

### Pitfall 2: OnCreatePlayer Fires with Nil Descriptor on Loading Screen

**What goes wrong:** `player:getDescriptor():getCharacterProfession()` returns nil if called too
early in the character creation flow (e.g. before the player has selected a profession).
**Why it happens:** `OnCreatePlayer` can fire during the character creation screen before the descriptor is fully populated.
**How to avoid:** Guard with `if player:getDescriptor() and player:getDescriptor():getCharacterProfession() then`
before calling `:getName()`.
**Warning signs:** Lua error `attempt to index a nil value (field 'getCharacterProfession')`.

### Pitfall 3: Double-Decrement on Multi-Hit with OnWeaponHitXp

**What goes wrong:** Hitting multiple targets simultaneously (AoE weapons, cars) may call
`OnWeaponHitXp` once per target. If two survivors die from one swing, sanity drops twice.
**Why it happens:** The event fires for each character hit, including multiple NPCs.
**How to avoid:** In Phase 1, scope is singleplayer where survivor NPC encounters are rare and
multi-hit survivor kills are near-impossible. Add a `lastKilledCharacterId` ModData guard in Phase
4 if it becomes an issue.
**Warning signs:** Sanity drops by `2 × SURVIVOR_WEIGHT` in a single animation frame.

### Pitfall 4: mod.info pzversion Field Outdated

**What goes wrong:** The example in `reference/examples/mod.info` shows `pzversion=41.78`. Using
this in a B42 mod does not break functionality but shows as "untested" in the mod list and may
confuse users.
**Why it happens:** The example template pre-dates B42.
**How to avoid:** Set `pzversion=42.0` (or `42.x` matching the current SVN build, which is 964).
**Warning signs:** Mod list shows compatibility warning for the current PZ version.

### Pitfall 5: Sanity Meter Underflows Below 0

**What goes wrong:** Rapid killing can push `sanity` below 0, breaking threshold comparisons in
Phase 2.
**Why it happens:** No floor is applied in Phase 1.
**How to avoid:** Always clamp after decrement: `md.SanityTraits.sanity = math.max(0, md.SanityTraits.sanity - weight)`.
**Warning signs:** Stage transition checks in Phase 2 behave unexpectedly for players with very negative sanity.

---

## Code Examples

Verified patterns from official sources:

### mod.info (B42)

```
name=Sanity Traits
id=Sanity_traits
description=Psychological deterioration system. Characters spiral through mental health stages driven by kill events, time, and mood.
modversion=1.0
pzversion=42.0
```

Source: `reference/mod_structure.md`, `reference/examples/mod.info`

### Per-Character ModData Init

```lua
-- Source: reference/moddata.md:69 + game source ISPerkLog.lua:112
local function onCreatePlayer(playerIndex, player)
    local md = player:getModData()
    if md.SanityTraits == nil then
        md.SanityTraits = { sanity = 1000, appliedStage = "Healthy" }
    end
end
Events.OnCreatePlayer.Add(onCreatePlayer)
```

### Zombie Kill Decrement

```lua
-- Source: game source Challenge2.lua:68, Tutorial/Steps.lua:913
local function onZombieDead(zed)
    local player = getPlayer()
    if not player then return end
    local md = player:getModData()
    if md.SanityTraits then
        md.SanityTraits.sanity = math.max(0, md.SanityTraits.sanity - SanityTraits.ZOMBIE_WEIGHT)
    end
end
Events.OnZombieDead.Add(onZombieDead)
```

### Survivor Kill Detection

```lua
-- Source: game source XpUpdate.lua:48, OnBreak.lua:62
local function onWeaponHitXp(owner, weapon, hitObject, damage, hitCount)
    if not owner or not hitObject then return end
    if not instanceof(hitObject, "IsoZombie") and hitObject:isDead() then
        local md = owner:getModData()
        if md.SanityTraits then
            md.SanityTraits.sanity = math.max(0, md.SanityTraits.sanity - SanityTraits.SURVIVOR_WEIGHT)
        end
    end
end
Events.OnWeaponHitXp.Add(onWeaponHitXp)
```

### Profession ID Retrieval

```lua
-- Source: game source forageSystem.lua:1867, LastStandSetup.lua:102
local desc = player:getDescriptor()
if desc and desc:getCharacterProfession() then
    local profName = desc:getCharacterProfession():getName()
    -- profName == "base:unemployed", "base:veteran", etc.
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `TraitFactory.addTrait()` for all traits | `.txt` script `character_trait_definition` | Build 42 | Txt is now primary; TraitFactory still works for dynamic/runtime registration |
| `OnZombiesDead` (B41) | `OnZombieDead` (B42) | Build 42 | Event renamed; old name does not fire |
| `OnWeaponHitCharacter` (referenced in old docs) | Does not exist in B42 | B42 | Use `OnWeaponHitXp` or `OnHitZombie` depending on target type |

**Deprecated/outdated:**
- `OnZombiesDead`: Not present in B42 game source. Confirmed absent.
- `OnWeaponHitCharacter`: Not present in B42 game source. Confirmed absent.
- `reference/events.md` event names: Partially stale. Use game source as the authoritative reference.

---

## Open Questions

1. **Does `OnZombieDead` pass the zed as a parameter consistently?**
   - What we know: `Tutorial/Steps.lua:913` shows `function FightStep:OnMomDead(zed)` — parameter exists. `Challenge2.onZombieDead` (line 242) ignores parameters.
   - What's unclear: Whether the parameter is always populated or is nil in some kill scenarios (e.g., vehicle kill, fire kill).
   - Recommendation: Accept `zed` parameter but do not rely on it; use `getPlayer()` for the attacker.

2. **Is `OnWeaponHitXp` the correct event for survivor kills, or does a dedicated NPC-death event exist?**
   - What we know: Exhaustive search of all `.lua` events in `ProjectZomboid/media/lua/` found no `OnNPCDead`, `OnCharacterDead`, or `OnSurvivorDead` event. `OnWeaponHitXp` is the best available hook.
   - What's unclear: Whether ranged kills (gun shots that kill an NPC at distance) also fire `OnWeaponHitXp`. Ranged XP is handled in `XpUpdate.lua:78-84` within the same handler, suggesting it does fire.
   - Recommendation: Use `OnWeaponHitXp` and accept the edge-case risk. Flag for verification during Phase 1 testing.

3. **Does `hitObject:isDead()` return true at the moment `OnWeaponHitXp` fires for a kill shot?**
   - What we know: The event fires after the hit is processed; `isDead()` is a Java method on `IsoGameCharacter`.
   - What's unclear: The exact order of damage application vs event dispatch within the engine tick.
   - Recommendation: Test in-game immediately during Phase 1 implementation and log results.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None — no Lua unit test framework for PZ mods; all validation is in-game |
| Config file | none |
| Quick run command | Launch PZ with mod enabled, open console (F11), observe `[SanityTraits]` log output |
| Full suite command | Complete all 4 success criteria from the phase definition manually |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DEF-04 | mod.info present and valid; mod appears in mod list | manual | Launch PZ → Mods screen → confirm "Sanity Traits" appears | ❌ Wave 0 |
| CORE-01 | New character has `modData.SanityTraits.sanity` set | manual | New game → debug menu (`F11`) → `print(getPlayer():getModData().SanityTraits.sanity)` | ❌ Wave 0 |
| CORE-02 | Unemployed starts at 1000; Veteran starts at 200 | manual | Start game with each profession → console print sanity | ❌ Wave 0 |
| CORE-03 | Killing zombie decrements sanity; console log confirms | manual | Kill one zombie → observe `[SanityTraits] Zombie killed. Sanity: 990` in console | ❌ Wave 0 |
| CORE-04 | Killing survivor decrements sanity by 3×; persists after save/reload | manual | Kill NPC → note sanity → save → reload → console print sanity | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Manually launch PZ and confirm no Lua errors in console
- **Per wave merge:** Run all 4 success criteria from phase definition
- **Phase gate:** All 5 success criteria green before marking Phase 1 complete

### Wave 0 Gaps

- [ ] Mod skeleton does not exist yet — `Mods/Sanity_traits/mod.info` must be created in Wave 0
- [ ] No Lua files exist — all client scripts created in Wave 0
- [ ] No automated test infrastructure available for PZ Lua; all tests are manual in-game verification

*(No automated test framework exists for PZ Lua mods. All validation is manual in-game.)*

---

## Project Constraints (from CLAUDE.md)

- **Read-only:** `ProjectZomboid/` directory — never create, edit, or delete files there
- **Mod output location:** `Mods/Sanity_traits/` — all mod files go here
- **Primary language:** Lua (client-side) + `.txt` script files for definitions; B42 script format
- **Compatibility:** Build 42 only — no B41 backwards compatibility
- **Scope:** Singleplayer only — no server-side scripts in v1
- **Data persistence:** ModData only — no external files or JSON saves for v1
- **Research priority:** `reference/` first, then `ProjectZomboid/media/`, then web (last resort)
- **GSD enforcement:** All file-changing work must go through a GSD command

---

## Sources

### Primary (HIGH confidence)

- `ProjectZomboid/media/lua/client/LastStand/Challenge2.lua:68` — `OnZombieDead` event name and registration pattern confirmed
- `ProjectZomboid/media/lua/client/Tutorial/Steps.lua:913` — `OnZombieDead` parameter (`zed`) confirmed
- `ProjectZomboid/media/lua/server/XpSystem/XpUpdate.lua:48` — `OnWeaponHitXp(owner, weapon, hitObject, damage, hitCount)` signature confirmed
- `ProjectZomboid/media/lua/shared/Items/OnBreak.lua:62` — `instanceof(target, "IsoZombie")` pattern confirmed
- `ProjectZomboid/media/lua/shared/Foraging/forageSystem.lua:1867` — `getDescriptor():getCharacterProfession():getName()` confirmed
- `ProjectZomboid/media/lua/client/LastStand/LastStandSetup.lua:102` — same profession API pattern confirmed
- `ProjectZomboid/media/lua/client/ISUI/PlayerData/ISPlayerData.lua:203` — `OnCreatePlayer` registration pattern confirmed
- `ProjectZomboid/SVNRevision.txt` — Build 964 (B42) confirmed
- `reference/mod_structure.md` — mod.info format and load order
- `reference/moddata.md` — per-player ModData API
- `reference/occupations.md` — all 25 vanilla profession IDs
- `reference/vanilla_traits.md` — all vanilla trait IDs

### Secondary (MEDIUM confidence)

- `reference/events.md` — general event pattern (PARTIALLY STALE: `OnZombiesDead` and `OnWeaponHitCharacter` names are wrong for B42; game source is authoritative)

### Tertiary (LOW confidence)

- None identified

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all APIs verified against B42 game source
- Architecture: HIGH — patterns match existing game code in Challenge2.lua, ISPerkLog.lua, forageSystem.lua
- Pitfalls: HIGH — event name discrepancy confirmed by exhaustive grep of game source; double-decrement is a logical edge case

**Research date:** 2026-04-28
**Valid until:** 2026-07-28 (stable — PZ B42 APIs change slowly between minor builds)
