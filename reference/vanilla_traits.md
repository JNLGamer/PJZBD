# Vanilla Traits (Build 42)

Source: `ProjectZomboid/media/scripts/generated/characters/character_traits.txt`

## How Traits Work in B42

Traits are defined in `.txt` script files in B42.  
File location in your mod: `media/scripts/characters/mytraits.txt`

```
module Base
{
    character_trait_definition base:mytrait
    {
        IsProfessionTrait       = false,
        DisabledInMultiplayer   = false,
        CharacterTrait          = base:mytrait,
        Cost                    = 4,
        UIName                  = UI_trait_MyTrait,
        UIDescription           = UI_trait_MyTraitDesc,
        XPBoosts                = Aiming=1;Sneak=1,
        MutuallyExclusiveTraits = base:cowardly;base:pacifist,
        GrantedRecipes          = MakeSomething,
    }
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `IsProfessionTrait` | bool | `true` = hidden from trait list, only via `GrantedTraits` in a profession |
| `DisabledInMultiplayer` | bool | `true` = not usable on MP servers |
| `CharacterTrait` | `module:id` | Must match the definition key |
| `Cost` | int | Positive = player pays; negative = player earns points |
| `UIName` | string | Translation key or literal name |
| `UIDescription` | string | Translation key or literal description |
| `XPBoosts` | `Perk=N;...` | Starting skill boosts (can be negative) |
| `MutuallyExclusiveTraits` | `id;id;...` | Traits that cannot be selected simultaneously |
| `GrantedRecipes` | `Name;Name;...` | Recipes unlocked at character start |
| `GrantedTraits` | `id;id;...` | Sub-traits automatically applied when this trait is selected |

---

## All Vanilla Traits

### Positive Traits (Cost > 0 — player spends points)

| ID | Display Name | Cost | Effect |
|----|-------------|------|--------|
| `base:athletic` | Athletic | 10 | Fitness=4; excl. overweight/unfit/smoker |
| `base:strong` | Strong | 10 | Strength=4; excl. weak/feeble |
| `base:handy` | Handy | 8 | Carving/Maint/Masonry/Woodwork=1; many recipes |
| `base:hunter` | Hunter | 8 | Aiming/Trap/Sneak/SmallBlade/Butchering=1; trap recipes |
| `base:thickskinned` | Thick-Skinned | 8 | Damage resistance; excl. thinskinned |
| `base:wildernessknowledge` | Wilderness Knowledge | 8 | Many craft/plant/flint recipes; multi-skill boosts |
| `base:fasthealer` | Fast Healer | 6 | Heals wounds faster; excl. slowhealer |
| `base:fastlearner` | Fast Learner | 6 | XP multiplier boost; excl. slowlearner/crafty |
| `base:fit` | Fit | 6 | Fitness=2; excl. obese/unfit/out of shape |
| `base:keenhearing` | Keen Hearing | 6 | Larger sound detection radius; excl. deaf/hardofhearing |
| `base:stout` | Stout | 6 | Strength=2; excl. weak/feeble |
| `base:formerscout` | Former Scout | 6 | Doctor/PlantScav/Fishing=1; fishing recipes |
| `base:asthmatic` | Asthmatic | -5 | Reduced endurance regen *(listed negative but costs points as penalty)* |
| `base:gymnast` | Gymnast | 5 | Lightfoot/Nimble=1 |
| `base:target_shooter` | Target Shooter | 5 | Aiming=1 |
| `base:graceful` | Graceful | 4 | Reduced noise while moving; excl. clumsy |
| `base:brave` | Brave | 4 | Panic resistance; excl. cowardly |
| `base:eagleeyed` | Eagle-Eyed | 4 | Wider vision cone; excl. shortsighted |
| `base:inconspicuous` | Inconspicuous | 4 | Less zombie vision attention; excl. conspicuous |
| `base:jogger` | Jogger | 4 | Sprinting=1 |
| `base:organized` | Organized | 4 | Increased container capacity; excl. disorganized |
| `base:resilient` | Resilient | 4 | Reduced illness chance; excl. pronetoillness |
| `base:brawler` | Bar Fighter | 6 | Axe/Blunt=1; barricade recipes |
| `base:outdoorsman` | Outdoorsman | 2 | Less weather penalties |
| `base:dextrous` | Dexterous | 2 | Faster item transfer; excl. allthumbs |
| `base:fastreader` | Fast Reader | 2 | Reads books faster; excl. slowreader/illiterate |
| `base:irongut` | Iron Gut | 2 | Less sickness from food; excl. weakstomach |
| `base:lighteater` | Light Eater | 2 | Slower hunger drain; excl. heartyappetite/obese |
| `base:lowthirst` | Low Thirst | 2 | Slower thirst drain; excl. highthirst |
| `base:needslesssleep` | Wakeful | 3 | Less sleep needed; excl. needsmoresleep |
| `base:nightvision` | Night Owl (selectable) | 3 | Better visibility at night |
| `base:nutritionist` | Nutritionist | 2 | See food nutritional values; excl. nutritionist2 |
| `base:firstaid` | First Aid | 2 | Doctor=1 |
| `base:artisan` | Artisan | 2 | Glassmaking/Pottery=1; glass recipes |
| `base:gardener` | Gardener | 2 | Farming=1; many growing season recipes |
| `base:tinkerer` | Tinkerer | 4 | Maintenance=1 |
| `base:whittler` | Whittler | 2 | Carving=2; many carving/bone recipes |
| `base:mason` | Mason | 2 | Masonry=2; forge/kiln construction |
| `base:fishing` | Fishing | 4 | Fishing=1; fishing recipes |
| `base:hiker` | Hiker | 6 | PlantScav/Trapping=1; trap recipes |
| `base:baseballplayer` | Baseball Player | 4 | Blunt=1; carve bat recipe |
| `base:blacksmith` | Blacksmith | 6 | Blacksmith=2, Maint=1; forge recipes; excl. blacksmith2 |
| `base:cook` | Cook | 3 | Cooking=2, Butchering=1; cooking recipes; excl. cook2 |
| `base:mechanics` | Mechanic (trait) | 3 | Mechanics=1; basic/intermediate mech recipes; excl. mechanics2 |
| `base:tailor` | Tailor (trait) | 4 | Tailoring=1; clothing recipes |
| `base:speeddemon` | Speed Demon | 1 | Drives faster; excl. sundaydriver |
| `base:inventive` | Inventive | 2 | Unlock extra crafting options; excl. inventive_prof |
| `base:crafty` | Crafty | 3 | Craft XP bonus; excl. fastlearner/slowlearner |

### Negative Traits (Cost < 0 — player earns extra points)

| ID | Display Name | Cost | Effect |
|----|-------------|------|--------|
| `base:unfit` | Unfit | -10 | Fitness=-4; excl. athletic/fit |
| `base:illiterate` | Illiterate | -10 | Can't read books; excl. fastreader/slowreader |
| `base:deaf` | Deaf | -12 | No ambient sounds; excl. keenhearing |
| `base:weak` | Weak | -10 | Strength=-5; excl. strong/stout |
| `base:disorganized` | Disorganized | -6 | Reduced carry weight; excl. organized |
| `base:slowlearner` | Slow Learner | -6 | Reduced XP gain; excl. fastlearner |
| `base:insomniac` | Insomniac | -6 | Poor sleep quality |
| `base:out of shape` | Out of Shape | -6 | Fitness=-2; excl. athletic/fit |
| `base:feeble` | Feeble | -6 | Strength=-2; excl. strong/stout |
| `base:pacifist` | Pacifist | -5 | Combat XP penalty |
| `base:hemophobic` | Hemophobic | -5 | Panics around blood; excl. desensitized |
| `base:agoraphobic` | Agoraphobic | -4 | Panics outdoors; excl. brave/desensitized |
| `base:claustrophobic` | Claustrophobic | -4 | Panics indoors; excl. brave/desensitized |
| `base:pronetoillness` | Prone to Illness | -4 | Gets sick more easily; excl. resilient |
| `base:needsmoresleep` | Hearty Sleeper | -4 | Needs more sleep; excl. wakeful |
| `base:heartyappetite` | Hearty Appetite | -4 | Faster hunger drain; excl. lighteater |
| `base:hardofhearing` | Hard of Hearing | -4 | Reduced hearing radius; excl. deaf/keenhearing |
| `base:conspicuous` | Conspicuous | -4 | More zombie vision attention; excl. inconspicuous |
| `base:slowhealer` | Slow Healer | -3 | Heals wounds slower; excl. fasthealer |
| `base:smoker` | Smoker | -3 | Needs cigarettes; excl. athletic |
| `base:allthumbs` | All Thumbs | -2 | Slower item transfer; excl. dextrous |
| `base:clumsy` | Clumsy | -2 | More noise while moving; excl. graceful |
| `base:highthirst` | High Thirst | -2 | Faster thirst drain; excl. lowthirst |
| `base:shortsighted` | Short-Sighted | -2 | Narrower vision cone; excl. eagleeyed |
| `base:slowreader` | Slow Reader | -2 | Reads books slower; excl. fastreader |
| `base:weakstomach` | Weak Stomach | -2 | More sickness from food; excl. irongut |
| `base:weightgain` | Prone to Weight Gain | -2 | Starts with `base:overweight`; excl. weightloss |
| `base:weightloss` | Prone to Weight Loss | -2 | Starts with `base:underweight`; excl. weightgain |
| `base:sundaydriver` | Sunday Driver | -1 | Drives slower; excl. speeddemon |
| `base:cowardly` | Cowardly | -2 | Panics easily; excl. brave/desensitized |

### Profession-Only Traits (IsProfessionTrait = true, cost = 0)

Not selectable — granted automatically by a profession via `GrantedTraits`.

| ID | Linked Profession | Effect note |
|----|------------------|-------------|
| `base:axeman` | Lumberjack | Axe use bonus |
| `base:blacksmith2` | Smither | Free blacksmith unlock |
| `base:burglar` | Burglar | Burglar unlock |
| `base:cook2` | Chef / Burger Flipper | Free cook unlock |
| `base:desensitized` | Veteran | No panic |
| `base:herbalist_prof` | Park Ranger | Free herbalist unlock |
| `base:inventive_prof` | Repairman | Free inventive unlock |
| `base:marksman` | — (reserved) | Aiming bonus |
| `base:mechanics2` | Mechanic | Free mechanic unlock |
| `base:nightowl` | Nurse / Security Guard | Better night vision |
| `base:nutritionist2` | Fitness Instructor | Free nutritionist |
| `base:obese` | — (body type) | Fitness=-2 |
| `base:overweight` | — (body type) | Fitness=-1 |
| `base:underweight` | — (body type) | Fitness=-1 |
| `base:very underweight` | — (body type) | Fitness=-2 |
| `base:emaciated` | — (body type) | Fitness penalty |
