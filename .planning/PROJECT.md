# Sanity_traits

## What This Is

A Project Zomboid Build 42 singleplayer mod that introduces an occupation-flavored psychological
deterioration system. Characters spiral through mental health stages — Sad → Depressed → Traumatized
→ Desensitized — driven by kill events, time, and mood, with each occupation archetype reacting
differently to violence and death.

## Core Value

A character's sanity must visibly decay with realistic occupation-specific flavor, culminating in
permanent trait consequences that feel earned and irreversible.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Track an invisible sanity meter per character, persisted via ModData
- [ ] Kill events (zombie and survivor/NPC) reduce the sanity meter; survivor kills weigh heavier
- [ ] Sanity deteriorates through four stages: Sad → Depressed → Traumatized → Desensitized
- [ ] Each stage applies negative traits: Restless Sleeper (Sad), random habit-based addiction (Depressed), Out of Shape / Sleepyhead / Disorganized (Traumatized), Desensitized (final)
- [ ] Desensitized stage removes all conflicting traits from previous stages
- [ ] Stage progression is driven by combined triggers: kill count, mood state during events, time spent at current stage
- [ ] Each occupation archetype has a distinct psyche profile: different deterioration thresholds, different trait outcome tendencies, and different starting sanity state
- [ ] Recovery from Sad and Depressed stages is possible via existing game happiness mechanics (reading, TV, eating, sleep, idle time)
- [ ] Trauma stage is permanent — no recovery path
- [ ] Addictions in the Depressed stage are habit-based: determined by which consumables the character has used frequently before reaching that stage
- [ ] All deterioration rates, kill weights, and stage thresholds are configurable via sandbox settings

### Out of Scope

- Multiplayer support — singleplayer only for v1; multiplayer sync is a separate problem
- Custom UI / mood indicator — no visual layer in v1; framework needed first
- Positive trait gain — mod only adds and removes negative traits, no new positive paths
- Occupation-preset addictions — addictions are habit-driven, not predetermined by profession

## Context

- **Platform:** Project Zomboid Build 42, singleplayer only
- **Mod output location:** `Mods/Sanity_traits/` following standard PZ mod structure
- **Reference docs:** `reference/` folder contains curated B42-authoritative modding docs and copy-paste Lua/script examples
- **Game source:** `ProjectZomboid/media/lua/` (read-only reference for event hooks, moodle system, etc.)
- **Occupation archetypes:** Each vanilla occupation will receive a psyche profile defining its break thresholds and trait tendencies — e.g. soldiers start partially desensitized with a higher threshold; nurses resist death but are more fragile under violence; civilians break faster
- **Addiction design:** When a character reaches Depressed stage, the game checks which consumables (meds, food, alcohol, etc.) were most used and applies relevant addiction traits from that history. Not preset — emergent from playstyle.
- **Sanity meter:** Custom invisible numeric value (e.g. 0–1000) stored in ModData. Not connected to the vanilla moodle Unhappiness meter directly, but influenced by the same events that affect happiness.

## Constraints

- **Tech stack:** Lua (client-side) + `.txt` script files for trait definitions; B42 script format
- **Compatibility:** Build 42 only — no backwards compatibility with B41 needed
- **Scope:** Singleplayer only; no server-side scripts in v1
- **Data persistence:** ModData only (no external files or JSON saves needed for v1)
- **No search tools:** Researchers must use `reference/` folder and `ProjectZomboid/media/` game files as primary sources; web search unavailable

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Sanity stored as custom invisible meter (not vanilla unhappiness) | Gives full control over thresholds and stage logic without fighting vanilla moodle system | — Pending |
| Addiction triggered by habit history, not occupation preset | More emergent and personal; punishes what you actually relied on | — Pending |
| Trauma is permanent with no recovery | Creates meaningful weight to the final irreversible stage | — Pending |
| Sandbox-configurable thresholds | Lets players tune pacing without touching code | — Pending |
| Occupation archetypes via psyche profile table | Centralized, easy to tune; maps cleanly to existing trait system | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-27 after initialization*
