# PJZBD

A personal modding archive for Project Zomboid Build 42, used as a sandbox
for AI-assisted development and in-game testing.

The repository pairs Workshop-ready mod source with a curated reference set
and an AI tooling layer (Claude Code + the GSD planning workflow). Mods are
designed, drafted, and iterated on inside this workspace, then deployed into
Project Zomboid for live testing.

---

## What this repo is

- An archive of Project Zomboid mods I'm building and maintaining over time.
- A controlled environment for AI-assisted modding: research, planning,
  implementation, and verification all run against a curated set of B42
  authoritative sources, not open-web search.
- A test harness: every mod is built incrementally, deployed into a real
  Zomboid install, and validated in-game before the next slice is added.

It is **not** a release distribution channel — published Workshop versions
live on the Steam Workshop. This repo is the workshop bench.

---

## Repository Layout

```
PJZBD/
├── Mods/             Deploy output — finished, Workshop-ready mod copies
├── modPlanner/       Active development workspace (gitignored)
│   ├── <ModName>/    One folder per mod under active iteration
│   ├── reference/    Curated B42 modding reference (traits, items, events…)
│   └── ProjectZomboid/  Local read-only game install used as ground truth
├── README.md
└── .gitignore
```

Each mod under `Mods/` follows the standard Project Zomboid layout:

```
Mods/<ModName>/
├── mod.info                       Workshop metadata
├── 42/
│   └── media/
│       ├── lua/{client,server,shared}/   Lua source
│       └── scripts/                       Item / recipe / sandbox .txt
└── poster.png                     Optional Workshop thumbnail
```

---

## AI-Assisted Workflow

This repo is set up to be driven by Claude Code with the GSD (Get Stuff Done)
planning workflow. The loop, per slice of work:

1. **Research** — pull authoritative B42 patterns from `modPlanner/reference/`
   and vanilla source in `modPlanner/ProjectZomboid/media/lua/`. No web
   search; the wiki is unreliable / blocked, vanilla source is ground truth.
2. **Plan** — break the slice into small, verifiable tasks with explicit
   success criteria.
3. **Execute** — implement against the dev copy in `modPlanner/<ModName>/`.
4. **Test** — copy the dev copy into `Mods/<ModName>/`, then deploy to
   `C:\Users\joaqu\Zomboid\mods\<ModName>\` and load the game.
5. **Verify** — UAT against the slice's success criteria; only then does
   the slice count as shipped.

Planning artifacts (`.planning/`, `.claude/`, `.agents/`) are gitignored —
they're scaffolding for the AI loop, not part of the mod source.

### Why this structure

- **Two copies of each mod (dev + deploy).** Edits happen in `modPlanner/`;
  `Mods/` only updates after a slice passes verification. Keeps in-progress
  work from corrupting tested builds.
- **Curated reference, not the open web.** The B42 modding surface is poorly
  documented and littered with B41-era misinformation. Research is anchored
  to local files that have already been pre-verified against vanilla source.
- **Vanilla-source-first verification.** Any API claim must be backed by a
  call site in the actual game's Lua, not by AI prior knowledge.

---

## Current Mods

### Sanity_traits

Singleplayer Build 42 mod adding an occupation-flavored psychological
deterioration system. Characters carry a hidden sanity meter (0–1000) that
decays with kills and time and progresses through five stages — Stable,
Shaken, Hollow, Numb, Broken — each with thematic flavor and permanent
trait consequences. Starting profession affects starting sanity (Veterans
start near Numb; civilians start Stable).

A custom "Psyche" tab in the character info window surfaces the meter,
current stage, a 50-entry event log, and active sanity-applied debuff
traits.

**Compatibility:** B42 only. **Scope:** Singleplayer.
**Persistence:** Per-character ModData.

#### Roadmap

| Stage | Scope | Status |
|------|------|--------|
| 1 | Sanity meter, kill-driven decay, profession-based starting values | Complete |
| 2 | "Psyche" tab UI — bar, stage label, event log, debuff row | Complete |
| 3 | Stage transition logic — automatic trait application at thresholds | Planned |
| 4 | Passive decay + contentment-gated recovery (Unhappy moodle) | Planned |
| 5 | Per-occupation psyche profiles — decay rates, starts, flavor text | Planned |
| 6 | Habit and addiction layer (alcohol / coping) | Planned |
| 7 | Sandbox menu — all weights and thresholds in-game | Planned |

---

## Planned Future Mods

Exploratory, not on a release schedule:

- Occupation rebalance pack centered on realistic civilian professions.
- Negative-trait expansion with deeper behavioral consequences.
- Quality-of-life systems surfacing hidden character state in existing UI.

---

## Conventions

- Lua hooks use `Events.<EventName>.Add(function(...) end)`.
- All globals are namespaced (e.g. `SanityTraits.*`) to avoid conflicts.
- Items: `Mods/<ModName>/42/media/scripts/items_<modname>.txt`.
  Recipes: `recipes_<modname>.txt`.
- `mod.info` requires `name`, `id`, `description`, `modversion`, B42
  workshop tag.
- Client load order is alphanumeric; numeric prefixes (`1_`, `2_`…)
  enforce dependency order.

---

## License

To be decided per-mod. Source under `Mods/` is original work unless a
per-mod `LICENSE` or `mod.info` field says otherwise. Reference material
under `modPlanner/reference/` is local-only and not redistributed.
