# PJZBD

A development workspace and personal archive for Project Zomboid Build 42 mods.

This repository holds mod source code in a Steam-Workshop-ready layout, plus a
curated set of modding references compiled from the game's own scripts and Lua
sources. It is maintained as an active workspace, not a one-shot release.

---

## Repository Layout

```
PJZBD/
├── Mods/             Mod source code (one folder per mod, Workshop-ready)
├── reference/        Modding reference material (event hooks, item formats, examples)
├── README.md         This file
└── .gitignore
```

Each entry under `Mods/` follows the standard Project Zomboid mod layout:

```
Mods/<ModName>/
├── mod.info                       Workshop metadata (id, name, description, version)
├── 42/
│   ├── media/
│   │   ├── lua/
│   │   │   ├── client/            Client-only scripts
│   │   │   ├── server/            Server-only scripts
│   │   │   └── shared/            Shared scripts (items, recipes, events)
│   │   └── scripts/               Item and recipe text definitions
│   └── ...
└── poster.png                     Optional Workshop thumbnail
```

---

## Current Mods

### Sanity_traits

A singleplayer-only mod that introduces an occupation-flavored psychological
deterioration system to Project Zomboid Build 42.

Characters carry an invisible sanity meter (0 to 1000) that drops with kill
events and time, and progresses through five stages — Stable, Shaken, Hollow,
Numb, Broken — each with thematic flavor and eventual permanent trait
consequences. Different starting professions begin the game with different
sanity values: Veterans start near the Numb stage; civilians start fully
stable.

A custom "Psyche" tab in the character info window surfaces the meter, the
current stage, a 50-entry event log, and a row of active sanity-applied
debuff traits.

**Compatibility:** Build 42 only. No B41 backwards compatibility.
**Scope:** Singleplayer. No server-side scripts in v1.
**Persistence:** Per-character ModData; no external files or saves.

---

## Roadmap

Sanity_traits is being built incrementally, with each iteration shipping a
working slice of the system before adding the next layer.

| Stage | Scope | Status |
|------|------|--------|
| 1 | Sanity meter, kill-driven decay, profession-based starting values | Complete |
| 2 | Visible "Psyche" tab in the character info window with bar, stage label, event log, debuff row | Complete |
| 3 | Stage transition logic — automatic application of sanity-stage traits when crossing thresholds | Planned |
| 4 | Passive decay over time and recovery while content (gated on the Unhappy moodle) | Planned |
| 5 | Full per-occupation psyche profile — decay multipliers, starting state, flavor text per profession | Planned |
| 6 | Habit and addiction layer — alcohol and coping mechanics tied to the sanity system | Planned |
| 7 | Sandbox menu integration — all weights, thresholds, and rates exposed as in-game options | Planned |

---

## Planned Future Mods

The workspace is intended to host more than one mod over time. Ideas under
consideration:

- An occupation rebalance pack focused on realistic civilian professions and
  their starting kits.
- A trait expansion pack focused on negative traits with deeper behavioral
  consequences (extending ideas first explored in Sanity_traits).
- Quality-of-life systems that surface previously-hidden character state in
  the existing UI, in the same spirit as the Psyche tab.

These are exploratory and not committed to a release schedule.

---

## Conventions

- Lua client-side scripts use `Events.<EventName>.Add(function(...) end)` for
  game-event registration.
- All globals are namespaced (for example, `SanityTraits.*`) to avoid conflicts
  with vanilla and other mods.
- Item definitions live in `Mods/<ModName>/42/media/scripts/items_<modname>.txt`;
  recipes in `recipes_<modname>.txt`.
- `mod.info` requires `name`, `id`, `description`, `modversion`, and a Build 42
  workshop tag.
- File load order inside a mod's `client/` folder is alphanumeric — numeric
  prefixes (`1_`, `2_`, etc.) are used to enforce dependency order.

---

## Reference Material

The `reference/` folder is a working set of compiled notes drawn from
`ProjectZomboid/media/lua/` and the modding wiki. It includes:

- An index of all vanilla traits with point costs and exclusion rules.
- An index of all vanilla professions with starting traits and skill bonuses.
- Event-hook documentation with confirmed B42 signatures.
- Copy-paste-ready Lua examples for common patterns.

The vanilla game install referenced under `ProjectZomboid/` is not tracked in
this repository — it is read-only reference material on the local machine only.

---

## License

To be decided per-mod. Mod source under `Mods/` is the author's original work
unless otherwise noted in a per-mod `LICENSE` or `mod.info` field.
