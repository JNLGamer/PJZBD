# PJZBD — Project Zomboid Mod Workspace

## Layout

```
PJZBD/
├── Mods/           ← final mod output goes here (one subfolder per mod)
├── reference/      ← modding docs and working examples (traits, items, UI, events…)
│   └── examples/   ← copy-paste ready .lua and .txt files
├── ProjectZomboid/ ← game installation (read-only reference, not tracked in git)
│   └── media/
│       ├── lua/
│       │   ├── client/   ← client-side game lua (reference)
│       │   ├── server/   ← server-side game lua (reference)
│       │   └── shared/   ← shared game lua (reference)
│       └── scripts/      ← item/recipe definitions (reference)
└── CLAUDE.md
```

## Mod Structure

Each finished mod lives in `Mods/<ModName>/` following the standard PZ layout:

```
Mods/<ModName>/
├── mod.info          ← mod metadata (id, name, description, poster)
├── media/
│   ├── lua/
│   │   ├── client/   ← client-only scripts
│   │   ├── server/   ← server-only scripts
│   │   └── shared/   ← shared scripts (items, recipes, events)
│   └── scripts/      ← item and recipe .txt definitions
└── poster.png        ← optional workshop thumbnail
```

## !! RULE: ProjectZomboid/ is READ-ONLY !!

**NEVER create, edit, or delete any file inside `ProjectZomboid/`.** It is the vanilla game installation and exists purely as a reference. All mod work goes in `Mods/`. Read files in `ProjectZomboid/` freely, but never write to them.

## Key Conventions

- Lua is the primary modding language for PZ (Build 42+).
- Use `Events.<EventName>.Add(function(...) end)` to hook into game events.
- Prefix all global functions and tables with a unique namespace to avoid conflicts.
- Item definitions go in `media/scripts/items_<modname>.txt`.
- Recipe definitions go in `media/scripts/recipes_<modname>.txt`.
- `mod.info` required fields: `name`, `id`, `description`, `modversion`, `pzversion`.

## Reference

- Modding docs & examples: `reference/` (traits, items, events, timed actions, UI, moddata)
- Game lua source: `ProjectZomboid/media/lua/`
- Game scripts: `ProjectZomboid/media/scripts/`
- PZ Build: check `ProjectZomboid/SVNRevision.txt`

## For GSD Agents: Research Priority Order

When researching how to implement anything PZ-related, consult sources in this order:

1. **`reference/`** — curated, B42-authoritative docs compiled from game files and modding guides. Check here first.
   - `reference/README.md` — index of all topics and examples
   - `reference/examples/` — copy-paste ready `.lua` and `.txt` files
   - `reference/vanilla_traits.md` — all vanilla trait IDs, costs, exclusions
   - `reference/occupations.md` — all vanilla profession definitions
2. **`ProjectZomboid/media/`** — the actual game source (scripts + Lua). More authoritative than any wiki. Read freely, never write.
3. **Web search** — last resort only, and prefer official sources. pzwiki.net returns 403 frequently; fall back to game files instead.

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Sanity_traits**

A Project Zomboid Build 42 singleplayer mod that introduces an occupation-flavored psychological
deterioration system. Characters spiral through mental health stages — Sad → Depressed → Traumatized
→ Desensitized — driven by kill events, time, and mood, with each occupation archetype reacting
differently to violence and death.

**Core Value:** A character's sanity must visibly decay with realistic occupation-specific flavor, culminating in
permanent trait consequences that feel earned and irreversible.

### Constraints

- **Tech stack:** Lua (client-side) + `.txt` script files for trait definitions; B42 script format
- **Compatibility:** Build 42 only — no backwards compatibility with B41 needed
- **Scope:** Singleplayer only; no server-side scripts in v1
- **Data persistence:** ModData only (no external files or JSON saves needed for v1)
- **No search tools:** Researchers must use `reference/` folder and `ProjectZomboid/media/` game files as primary sources; web search unavailable
<!-- GSD:project-end -->

<!-- GSD:stack-start source:research/STACK.md -->
## Technology Stack

## 1. Trait Definition
### B42 Script Format (Recommended for static definitions)
### TraitFactory (Legacy Lua — still valid for dynamic/programmatic registration)
## 2. Trait Runtime API
## 3. ModData — Sanity Meter Persistence
### Per-character ModData (recommended for sanity meter)
### Global ModData (alternative — if cross-character data needed)
## 4. Kill Events
### Zombie kills
### Survivor / NPC kills
## 5. Mood / Time Events
## 6. Sandbox Options
### Reading custom sandbox vars at runtime
### Defining custom sandbox options (B42)
## 7. Profession Detection
## 8. Perks Constants (XP Boost reference)
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
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd:quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd:debug` for investigation and bug fixing
- `/gsd:execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd:profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
