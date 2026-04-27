# Requirements — Sanity_traits

**Project:** Sanity_traits (Project Zomboid B42 singleplayer mod)
**Version:** v1
**Generated:** 2026-04-27

---

## v1 Requirements

### CORE — Sanity Meter

- [x] **CORE-01**: Player has an invisible sanity meter (0–1000) stored in `player:getModData()`, initialized on `OnCreatePlayer` and persisted automatically with the save file
- [x] **CORE-02**: Sanity meter starts at a value determined by the player's occupation archetype (e.g. Veteran starts low/near-desensitized, Unemployed starts at full 1000)
- [x] **CORE-03**: Killing a zombie reduces the sanity meter by a configurable base amount
- [x] **CORE-04**: Killing a survivor or NPC reduces the sanity meter by a heavier configurable amount (default: 3× zombie weight)
- [ ] **CORE-05**: The sanity meter passively decays over time (configurable rate) via `Events.EveryTenMinutes`
- [ ] **CORE-06**: When the player's unhappiness moodle is 0 (content/neutral), the sanity meter slowly recovers over time
- [ ] **CORE-07**: Sandbox settings expose: kill decay weights (zombie/survivor), passive decay rate, stage thresholds, recovery rate — all with fallback defaults for old saves

### STAGE — Deterioration Stages

- [ ] **STAGE-01**: Four deterioration stages are defined: Healthy → Sad → Depressed → Traumatized → Desensitized
- [ ] **STAGE-02**: Stage transitions are evaluated after each kill event and on each `EveryTenMinutes` tick; transitions are idempotent (guard: `appliedStage` in ModData prevents double-application)
- [ ] **STAGE-03**: Entering **Sad** stage applies: `base:insomniac`, `base:cowardly`
- [ ] **STAGE-04**: Entering **Depressed** stage applies: `base:hemophobic`, `base:slowhealer`, `base:weakstomach`, plus one habit-based addiction trait determined by `evaluateAddictions()`
- [ ] **STAGE-05**: Entering **Traumatized** stage applies: `base:out of shape`, `base:needsmoresleep`, `base:disorganized`, `base:pacifist`
- [ ] **STAGE-06**: Entering **Desensitized** stage applies: `base:desensitized` and removes all conflicting emotional-reaction traits (`base:hemophobic`, `base:agoraphobic`, `base:claustrophobic`, `base:cowardly`, and any traits added in prior stages)
- [ ] **STAGE-07**: Depression stage is reversible — if the sanity meter recovers above the Sad threshold, Depressed traits are removed and the player returns to Sad
- [ ] **STAGE-08**: Sad stage is reversible — if the meter fully recovers, Sad traits are removed and the player returns to Healthy
- [ ] **STAGE-09**: Trauma stage is **permanent** — once entered, the meter is clamped and cannot recover past the Traumatized threshold
- [ ] **STAGE-10**: Desensitized stage is permanent — once the meter crosses the final threshold, no recovery is possible

### OCC — Occupation Archetypes

- [ ] **OCC-01**: Each of the 24 vanilla professions has a psyche profile defined in a Lua table: `{ killModifier, startingSanity, threshold_sad, threshold_depressed, threshold_traumatized }`
- [ ] **OCC-02**: Veteran occupation is special-cased: player starts at Desensitized stage immediately on `OnCreatePlayer`; deterioration stage logic is suppressed
- [ ] **OCC-03**: Military/police professions (Police Officer, Security Guard, Firefighter) use 0.7–0.85× kill modifier and slightly higher thresholds
- [ ] **OCC-04**: Medical professions (Doctor, Nurse, Park Ranger) have higher death-tolerance but standard violence sensitivity
- [ ] **OCC-05**: Civilian professions (Unemployed, Carpenter, Chef, etc.) use 1.0× kill modifier and baseline thresholds

### HABIT — Addiction System

- [ ] **HABIT-01**: Consumption of cigarettes, alcohol, and painkillers is counted in ModData (`habits.cigarettes`, `habits.alcohol`, `habits.meds`) by wrapping timed-action completion handlers
- [ ] **HABIT-02**: When a player enters the Depressed stage, `evaluateAddictions()` selects the dominant habit and applies the corresponding addiction trait: `base:smoker` (cigarettes), `sanitymod:alcoholic` (alcohol), `sanitymod:painkiller_dependent` (meds)
- [ ] **HABIT-03**: If no dominant habit is detected at Depression onset, a random addiction trait from the three options is applied
- [ ] **HABIT-04**: Custom addiction traits `sanitymod:alcoholic` and `sanitymod:painkiller_dependent` are defined in the mod's `.txt` script and registered via TraitFactory at `OnGameBoot`
- [ ] **HABIT-05**: Only one addiction trait is applied per character; subsequent entries to Depressed stage do not re-apply if one is already present

### DEF — Trait Definitions

- [ ] **DEF-01**: All vanilla-ID traits used by the mod are applied only by their correct B42 IDs (verified: `base:insomniac`, `base:cowardly`, `base:hemophobic`, `base:slowhealer`, `base:weakstomach`, `base:out of shape`, `base:needsmoresleep`, `base:disorganized`, `base:pacifist`, `base:desensitized`, `base:smoker`)
- [ ] **DEF-02**: Every `add()` call is guarded with `if not player:HasTrait(id)` to prevent double-application
- [ ] **DEF-03**: Every `remove()` call is guarded with `if player:HasTrait(id)` to prevent no-op errors
- [x] **DEF-04**: `mod.info` is present with valid `name`, `id`, `description`, `modversion`, `pzversion` fields

---

## v2 Requirements (deferred)

- UI mood indicator showing current sanity stage — framework needed first
- Multiplayer sync support — singleplayer only in v1
- Expanded occupation-specific trait outcomes — v1 uses shared stage traits with profile modifiers only
- Recovery items (journal, cigarettes as comfort) — needs item interaction design
- Positive trait rewards for Desensitized characters — out of scope for v1

---

## Out of Scope

- **Multiplayer support** — singleplayer only; multiplayer sync is a separate problem requiring server-side scripts
- **Custom UI / mood indicator** — no visual layer in v1; ISPanel framework needed
- **Positive trait gain paths** — mod only applies and removes negative traits
- **Occupation-preset addictions** — addictions are emergent from playstyle habits, not predetermined
- **B41 backwards compatibility** — B42 only; trait script format differs

---

## Traceability

| REQ-ID | Roadmap Phase | Status |
|--------|---------------|--------|
| CORE-01 | Phase 1: Foundation | Complete |
| CORE-02 | Phase 1: Foundation | Complete |
| CORE-03 | Phase 1: Foundation | Complete |
| CORE-04 | Phase 1: Foundation | Complete |
| CORE-05 | Phase 3: Timed Decay and Recovery | Pending |
| CORE-06 | Phase 3: Timed Decay and Recovery | Pending |
| CORE-07 | Phase 6: Sandbox Configuration | Pending |
| STAGE-01 | Phase 2: Stage Transitions | Pending |
| STAGE-02 | Phase 2: Stage Transitions | Pending |
| STAGE-03 | Phase 2: Stage Transitions | Pending |
| STAGE-04 | Phase 2: Stage Transitions | Pending |
| STAGE-05 | Phase 2: Stage Transitions | Pending |
| STAGE-06 | Phase 2: Stage Transitions | Pending |
| STAGE-07 | Phase 2: Stage Transitions | Pending |
| STAGE-08 | Phase 2: Stage Transitions | Pending |
| STAGE-09 | Phase 2: Stage Transitions | Pending |
| STAGE-10 | Phase 2: Stage Transitions | Pending |
| OCC-01 | Phase 4: Occupation Profiles | Pending |
| OCC-02 | Phase 4: Occupation Profiles | Pending |
| OCC-03 | Phase 4: Occupation Profiles | Pending |
| OCC-04 | Phase 4: Occupation Profiles | Pending |
| OCC-05 | Phase 4: Occupation Profiles | Pending |
| HABIT-01 | Phase 5: Habit Tracking and Addictions | Pending |
| HABIT-02 | Phase 5: Habit Tracking and Addictions | Pending |
| HABIT-03 | Phase 5: Habit Tracking and Addictions | Pending |
| HABIT-04 | Phase 5: Habit Tracking and Addictions | Pending |
| HABIT-05 | Phase 5: Habit Tracking and Addictions | Pending |
| DEF-01 | Phase 2: Stage Transitions | Pending |
| DEF-02 | Phase 2: Stage Transitions | Pending |
| DEF-03 | Phase 2: Stage Transitions | Pending |
| DEF-04 | Phase 1: Foundation | Complete |
