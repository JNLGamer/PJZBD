# Occupations (Build 42)

Source: `ProjectZomboid/media/scripts/generated/characters/character_professions.txt`

## How Professions Work in B42

In Build 42, professions are defined in `.txt` script files, **not** in Lua.  
File location in your mod: `media/scripts/characters/myprofessions.txt`

```
module Base
{
    character_profession_definition base:myprofession
    {
        CharacterProfession = base:myprofession,
        Cost = -4,
        UIName = UI_prof_MyProfession,
        UIDescription = UI_profdesc_myprofession,
        IconPathName = profession_myprofession,
        GrantedTraits = base:sometrait,
        XPBoosts = Aiming=2;Woodwork=1,
        GrantedRecipes = MakeSomething;MakeOther,
    }
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `CharacterProfession` | `module:id` | Must match the definition key |
| `Cost` | int | Point cost — **negative = gives player points**, positive = costs points |
| `UIName` | string | Translation key OR literal display name |
| `UIDescription` | string | Translation key OR literal description |
| `IconPathName` | string | Image name in `media/textures/` (no extension) |
| `GrantedTraits` | `id;id;...` | Profession-only traits granted for free |
| `XPBoosts` | `Perk=N;Perk=N` | Starting skill XP boosts |
| `GrantedRecipes` | `Name;Name;...` | Recipes unlocked at character creation |

### Point Cost Convention

| Cost | Meaning |
|------|---------|
| Positive (e.g. `8`) | Player **gains** free points — Unemployed has `8` |
| `0` | Neutral — same starting points as baseline |
| Negative (e.g. `-4`) | Player **spends** points to pick this profession |

---

## All Vanilla Professions

| ID | Display Name | Cost | Key Skills | Granted Traits |
|----|-------------|------|-----------|----------------|
| `base:unemployed` | Unemployed | +8 | — | — |
| `base:burglar` | Burglar | -6 | Nimble=2, Sneak=2, Lightfoot=2 | `base:burglar` |
| `base:veteran` | Veteran | -8 | Aiming=2, Reloading=2 | `base:desensitized` |
| `base:fitnessinstructor` | Fitness Instructor | -6 | Fitness=3, Sprinting=2, Strength=1 | `base:nutritionist2` |
| `base:smither` | Smither | -6 | Blacksmith=4, Maintenance=1, SmallBlunt=1 | `base:blacksmith2` |
| `base:engineer` | Engineer | -4 | Electricity=1, Woodwork=1, Masonry=1 | — |
| `base:mechanics` | Mechanic | -4 | Mechanics=4, MetalWelding=1 | `base:mechanics2` |
| `base:metalworker` | Metal Worker | -4 | MetalWelding=4 | — |
| `base:parkranger` | Park Ranger | -4 | Trapping=1, Doctor=1, Tracking=1, PlantScav=1, FlintKnapping=1 | `base:herbalist_prof` |
| `base:policeofficer` | Police Officer | -4 | Aiming=4, Reloading=1, Nimble=1 | — |
| `base:carpenter` | Carpenter | -2 | Woodwork=4, Carving=1, SmallBlunt=1, Masonry=1, Maintenance=1 | — |
| `base:chef` | Chef | -2 | Cooking=4, Maintenance=1, SmallBlade=1, Butchering=2 | `base:cook2` |
| `base:constructionworker` | Construction Worker | -2 | SmallBlunt=2, Blunt=1, Masonry=2, Woodwork=1, Maintenance=1 | — |
| `base:electrician` | Electrician | -2 | Electricity=5 | — |
| `base:fisherman` | Fisherman | -2 | Fishing=3, PlantScavenging=1, Butchering=1 | — |
| `base:repairman` | Repairman | -2 | Woodwork=1, Maintenance=2, SmallBlunt=1, Masonry=1 | `base:inventive_prof` |
| `base:securityguard` | Security Guard | -2 | Sprinting=2, Lightfoot=1, SmallBlunt=1 | `base:nightowl` |
| `base:doctor` | Doctor | 0 | Doctor=6, SmallBlade=1 | — |
| `base:farmer` | Farmer | 0 | Farming=4, Husbandry=1, Strength=1 | — |
| `base:fireofficer` | Fire Officer | 0 | Sprinting=1, Strength=1, Fitness=1, Axe=1 | — |
| `base:lumberjack` | Lumberjack | 0 | Axe=2, Strength=1, Maintenance=1 | `base:axeman` |
| `base:nurse` | Nurse | 0 | Doctor=3, Lightfoot=1, Fitness=1 | `base:nightowl` |
| `base:rancher` | Rancher | 0 | Farming=1, Husbandry=4, Butchering=3 | — |
| `base:burgerflipper` | Burger Flipper | +2 | Cooking=2, Maintenance=1, SmallBlade=1 | `base:cook2` |
| `base:tailor` | Tailor | +2 | Tailoring=4 | — |

---

## Skill (XP Boost) Names

```
Aiming         Reloading      Axe            Blunt          LongBlade
SmallBlade     SmallBlunt     Spear          Nimble         Sneak
Lightfoot      Sprinting      Strength       Fitness        Woodwork
Carpentry      Masonry        Carving        MetalWelding   Blacksmith
Mechanics      Electricity    Farming        Husbandry      Butchering
Fishing        Trapping       PlantScavenging  FlintKnapping  Tracking
Cooking        Doctor         Tailoring      Maintenance
```

---

## Profession-Locked Traits (IsProfessionTrait = true)

These traits are only obtainable through a profession's `GrantedTraits` — not selectable in the trait list by the player. They show at cost `0`.

Common pattern: trait `base:cook` (selectable, costs 3 pts) has a matching `base:cook2` (profession-only, free) that is mutually exclusive with it. This prevents double-dipping.

| Trait ID | Tied to Profession |
|----------|--------------------|
| `base:cook2` | Chef, Burger Flipper |
| `base:mechanics2` | Mechanic |
| `base:blacksmith2` | Smither |
| `base:nutritionist2` | Fitness Instructor |
| `base:herbalist_prof` | Park Ranger |
| `base:inventive_prof` | Repairman |
| `base:nightowl` | Nurse, Security Guard |
| `base:axeman` | Lumberjack |
| `base:burglar` | Burglar |
| `base:desensitized` | Veteran |
