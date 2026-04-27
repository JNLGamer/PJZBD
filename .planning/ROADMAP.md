# Roadmap: Sanity_traits

## Overview

The mod is built in seven phases. Phase 1 lays the scaffolding: the sanity meter stored in ModData, the kill-event hooks, and the mod.info file that makes the mod loadable. Phase 2 builds on that foundation with the full stage transition engine — all four deterioration stages, their traits, and the idempotency guards that prevent double-application. Phase 3 adds the time dimension: passive decay and happiness-driven recovery running on the game clock. Phase 4 wires in all 24 occupation psyche profiles so every profession starts and breaks differently. Phase 5 introduces the habit-tracking and addiction system that makes the Depressed stage feel personal. Phase 6 exposes every tunable threshold to sandbox settings. Phase 7 audits the whole system end-to-end and verifies it loads cleanly.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - Mod scaffolding, sanity meter init, kill-event hooks, mod.info
- [ ] **Phase 2: Stage Transitions** - Four-stage deterioration engine with trait apply/remove and idempotency guards
- [ ] **Phase 3: Timed Decay and Recovery** - Passive sanity decay and happiness-driven recovery on the game clock
- [ ] **Phase 4: Occupation Profiles** - Psyche profiles for all 24 professions including Veteran special case
- [ ] **Phase 5: Habit Tracking and Addictions** - Consumption counting, evaluateAddictions(), and custom addiction traits
- [ ] **Phase 6: Sandbox Configuration** - All thresholds and weights exposed as configurable sandbox settings
- [ ] **Phase 7: Polish and Integration** - End-to-end audit, trait ID validation, load-order verification

## Phase Details

### Phase 1: Foundation
**Goal**: The mod loads cleanly, creates and persists the sanity meter, and records every kill
**Depends on**: Nothing (first phase)
**Requirements**: CORE-01, CORE-02, CORE-03, CORE-04, DEF-04
**Success Criteria** (what must be TRUE):
  1. The mod appears in the mod list and loads without Lua errors on a new game
  2. A new character has a `modData.sanity` value set to the correct starting number (e.g. 1000 for Unemployed)
  3. Killing a zombie reduces `modData.sanity` by the configured zombie weight; console logging confirms the event fired
  4. Killing a survivor reduces `modData.sanity` by the heavier survivor weight; the value is persisted after save/reload
**Plans**: 3 plans
  - [x] 01-01-PLAN.md — Mod skeleton, mod.info, namespace bootstrap (DEF-04)
  - [x] 01-02-PLAN.md — OnCreatePlayer ModData init with profession-aware starting sanity (CORE-01, CORE-02)
  - [x] 01-03-PLAN.md — Kill event handlers (OnZombieDead, OnWeaponHitXp) with sanity decrement + checkpoint (CORE-03, CORE-04)

### Phase 2: Stage Transitions
**Goal**: Characters progress through all four deterioration stages with correct traits applied and removed, with no double-application
**Depends on**: Phase 1
**Requirements**: STAGE-01, STAGE-02, STAGE-03, STAGE-04, STAGE-05, STAGE-06, STAGE-07, STAGE-08, STAGE-09, STAGE-10, DEF-01, DEF-02, DEF-03
**Success Criteria** (what must be TRUE):
  1. A character whose sanity crosses the Sad threshold gains `base:insomniac` and `base:cowardly`; crossing it twice does not duplicate the traits
  2. A character at Depressed stage has the Depressed trait set applied; recovering above the Sad threshold removes them and the character returns to Sad
  3. A character at Traumatized stage cannot recover — the meter is clamped and Traumatized traits persist
  4. A character at Desensitized stage has all prior emotional-reaction traits removed and `base:desensitized` applied; the `appliedStage` guard in ModData prevents re-entry
**Plans**: TBD

### Phase 3: Timed Decay and Recovery
**Goal**: Sanity decays passively over time and recovers when the character is content, making time itself a factor in psychological deterioration
**Depends on**: Phase 2
**Requirements**: CORE-05, CORE-06
**Success Criteria** (what must be TRUE):
  1. Sanity decreases by the configured passive rate on each `EveryTenMinutes` tick even without any kills
  2. When the character's unhappiness moodle reads 0 (content), sanity increases by the recovery rate each tick; when unhappy, no recovery occurs
**Plans**: TBD

### Phase 4: Occupation Profiles
**Goal**: Every vanilla profession has a defined psyche profile that changes its starting sanity and break thresholds; the Veteran starts Desensitized from character creation
**Depends on**: Phase 1
**Requirements**: OCC-01, OCC-02, OCC-03, OCC-04, OCC-05
**Success Criteria** (what must be TRUE):
  1. A Veteran character starts the game with `base:desensitized` applied and stage progression logic suppressed; no further stage checks fire for this character
  2. A Police Officer character uses a 0.7–0.85× kill modifier; the same kill event reduces sanity less than it would for an Unemployed character
  3. All 24 professions are present in the psyche profile table; an unknown/modded profession falls back to the civilian baseline without error
**Plans**: TBD

### Phase 5: Habit Tracking and Addictions
**Goal**: Consumption of cigarettes, alcohol, and painkillers is tracked throughout the playthrough; at Depressed onset, the dominant habit determines which addiction trait is applied
**Depends on**: Phase 2
**Requirements**: HABIT-01, HABIT-02, HABIT-03, HABIT-04, HABIT-05
**Success Criteria** (what must be TRUE):
  1. Each cigarette, alcoholic drink, and painkiller consumed increments the corresponding counter in `modData.habits`; the counters persist across save/reload
  2. When a character enters Depressed stage, `evaluateAddictions()` applies the trait matching the highest counter (`base:smoker`, `sanitymod:alcoholic`, or `sanitymod:painkiller_dependent`)
  3. If no dominant habit exists, one of the three addiction traits is applied at random; entering Depressed a second time does not apply a second trait
  4. The custom traits `sanitymod:alcoholic` and `sanitymod:painkiller_dependent` are defined in the mod's script files and appear correctly in the trait list on the character screen
**Plans**: TBD

### Phase 6: Sandbox Configuration
**Goal**: All deterioration rates, kill weights, and stage thresholds are tunable in the sandbox settings screen without touching code; old saves that predate the settings fall back to defaults
**Depends on**: Phase 1
**Requirements**: CORE-07
**Success Criteria** (what must be TRUE):
  1. The sandbox settings screen contains sliders/fields for zombie kill weight, survivor kill weight, passive decay rate, recovery rate, and each of the three stage thresholds
  2. Changing a sandbox value before starting a game changes the actual in-game behavior (e.g. doubling the zombie weight causes sanity to drop twice as fast per kill)
  3. Loading a save created before sandbox settings existed uses the hardcoded defaults without error
**Plans**: TBD

### Phase 7: Polish and Integration
**Goal**: The complete system runs end-to-end without Lua errors, all vanilla trait IDs are verified correct for B42, and the mod is ready to ship
**Depends on**: Phase 6
**Requirements**: (integration audit — all prior requirements validated together)
**Success Criteria** (what must be TRUE):
  1. A full playthrough from new game through all four stages completes without a single Lua error in the console
  2. All vanilla trait IDs used by the mod (`base:insomniac`, `base:cowardly`, `base:hemophobic`, `base:slowhealer`, `base:weakstomach`, `base:out of shape`, `base:needsmoresleep`, `base:disorganized`, `base:pacifist`, `base:desensitized`, `base:smoker`) are confirmed present in B42 game files
  3. The mod loads correctly when placed in `Mods/Sanity_traits/` and selected from the mod list on a clean install
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7

Note: Phases 3 and 4 both depend on Phase 1/2 respectively and can be planned in parallel, but execute sequentially per phase number.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/3 | Planned | - |
| 2. Stage Transitions | 0/TBD | Not started | - |
| 3. Timed Decay and Recovery | 0/TBD | Not started | - |
| 4. Occupation Profiles | 0/TBD | Not started | - |
| 5. Habit Tracking and Addictions | 0/TBD | Not started | - |
| 6. Sandbox Configuration | 0/TBD | Not started | - |
| 7. Polish and Integration | 0/TBD | Not started | - |
