# Item Script Variables

Source: MrBounty/PZ-Mod---Doc

Item definitions live in `media/scripts/items_<modname>.txt`.
See [examples/item_definition.txt](examples/item_definition.txt) for a full template.

## Types

| Type | Usage |
|------|-------|
| `Normal` | Generic carry item |
| `Food` | Edible item |
| `Weapon` | Melee or ranged weapon |
| `Drainable` | Item with a usage charge (torch, lighter) |
| `Clothing` | Wearable gear |
| `Literature` | Book / magazine / newspaper |

---

## General (all types)

| Variable | Effect | Example |
|----------|--------|---------|
| `Type` | Item type (see above) | `Food` |
| `DisplayName` | Name shown to player | `Axe` |
| `Icon` | Sprite name inside `ui.txt` (prefix `Item_` added) | `Axe` |
| `Weight` | Encumbrance weight | `0.5` |
| `Count` | Max quantity of this item in the world | `8` |
| `CanBarricade` | Can be used to barricade like a hammer | `true` |
| `UseWhileEquipped` | Drains while equipped | `true` |
| `UseDelta` | Drain rate per tick | `0.0009` |
| `ReplaceOnUse` | Item that replaces this one after use | `EmptyBotanicle` |
| `CanStoreWater` | Item can hold water | `TRUE` |
| `OtherHandRequire` | Requires this item in off-hand | `Lighter` |

---

## Weapons

| Variable | Effect | Example |
|----------|--------|---------|
| `MinDamage` | Minimum hit damage | `0.7` |
| `MaxDamage` | Maximum hit damage | `1.5` |
| `MinAngle` | Accuracy (closer to 1 = more precise aim needed) | `0.88` |
| `MaxRange` | Melee reach | `1.5` |
| `MaxHitCount` | Max enemies hit per swing | `1` |
| `SwingAnim` | Animation name | `Bat` |
| `WeaponSprite` | Sprite name on character | `axe` |
| `SwingSound` | Sound name | `axe` |
| `SoundRadius` | Radius in world units the sound is heard | `30` |
| `MinimumSwingTime` | Ticks between swings | `15` |
| `DoorDamage` | Damage to doors | `10` |
| `KnockBackOnNoDeath` | Push back if not killed | `true` |
| `TwoHandWeapon` | Requires both hands | `TRUE` |
| `CriticalChance` | % crit chance | `20` |
| `CritDmgMultiplier` | Crit damage multiplier | `3` |
| `BaseSpeed` | Attack speed multiplier | `0.9` |
| `UseEndurance` | Drains endurance | `TRUE` |
| `ConditionMax` | Max condition | `10` |
| `ConditionLowerChanceOneIn` | 1-in-N chance condition drops per use | `60` |
| **Firearms** | | |
| `IsAimedFirearm` | Aimed ranged weapon | `TRUE` |
| `AmmoType` | Ammo item required | `ShotgunShells` |
| `AmmoBox` | Box item that refills | `ShotgunBox` |
| `HitChance` | % base hit chance | `50` |
| `MaxAmmo` | Magazine capacity | `8` |
| `ReloadTime` | Ticks to reload | `25` |
| `AimingTime` | Ticks to aim | `20` |
| `FireMode` | `Single` or `Auto` | `Single` |

---

## Clothing

| Variable | Effect | Example |
|----------|--------|---------|
| `BodyLocation` | Where it's worn | `Bottoms` |
| `SpriteName` | Player sprite | `Shoes1` |
| `Palettes` | Color variants | `Shirt_Blue/Shirt_Red` |
| `Wet` | Can get wet | `TRUE` |
| `WetCooldown` | Ticks to dry | `8000` |
| `ItemWhenDry` | Item replaced with after drying | `Base.DishCloth` |

---

## Food

| Variable | Effect | Example |
|----------|--------|---------|
| `HungerChange` | Hunger delta (negative = fills hunger) | `-30` |
| `ThirstChange` | Thirst delta | `-20` |
| `UnhappyChange` | Unhappiness delta | `-10` |
| `BoredomChange` | Boredom delta | `-20` |
| `StressChange` | Stress delta | `-5` |
| `FatigueChange` | Fatigue delta | `0` |
| `DaysFresh` | Days until rotten | `5` |
| `DaysTotallyRotten` | Days until fully rotten | `7` |
| `Calories` / `Carbohydrates` / `Proteins` / `Lipids` | Nutrition | `498` |
| `Packaged` | Shows nutrition label | `TRUE` |
| `IsCookable` | Can be cooked | `TRUE` |
| `ReplaceOnCooked` | Item after cooking | `Base.SteakCooked` |
| `MinutesToCook` | Cook time | `6` |
| `MinutesToBurn` | Burn time | `60` |
| `Alcoholic` | Makes player drunk | `TRUE` |
| `Poison` | Causes poisoning | `true` |
| `PoisonPower` | Poison strength (100 = lethal) | `80` |
| `CannedFood` | Is a canned food item | `TRUE` |
| `EvolvedRecipe` | Usable in evolved recipes | `Stew:15;Sandwich:10` |
| `DangerousUncooked` | Can make sick if raw | `TRUE` |
| `ReplaceOnUse` | Empty container after use | `TinCanEmpty` |

---

## Literature

| Variable | Effect | Example |
|----------|--------|---------|
| `StressChange` | Stress change on read | `-10` |
| `BoredomChange` | Boredom change on read | `-50` |
| `UnhappyChange` | Unhappiness change | `-20` |
| `TeachedRecipes` | Recipes learned on read | `Make Fishing Rod` |
| `NumberOfPages` | Reading time (pages) | `220` |
| `SkillTrained` | Skill trained | `Trapping` |
| `LvlSkillTrained` | Starting level trained | `1` |
| `NumLevelsTrained` | Number of levels taught | `2` |
| `CanBeWrite` | Notebook — can write in it | `true` |
| `PageToWrite` | Writable pages | `10` |
