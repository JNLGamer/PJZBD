# IsoPlayer / IsoGameCharacter API Reference

> **Source:** Inferred from Lua usage across `ProjectZomboid/media/lua/` (B42 game files).
> `IsoPlayer` and `IsoGameCharacter` are Java classes exposed to Lua — there is no single Lua
> definition file. Every method listed here was found called in the game source. Confidence levels
> reflect call frequency: HIGH = found in many files/many times, MED = found 2–5 times, LOW = single
> source occurrence.
>
> **Aliases used in game code:** `player`, `_player`, `playerObj`, `self.player`, `self.character`,
> `self.char`. All resolve to the same IsoPlayer/IsoGameCharacter object.

---

## Quick Reference Table

| Method | Returns | Category | Confidence |
|---|---|---|---|
| `player:getX()` | float | Position | HIGH |
| `player:getY()` | float | Position | HIGH |
| `player:getZ()` | float | Position | HIGH |
| `player:setX(v)` | void | Position | MED |
| `player:setY(v)` | void | Position | MED |
| `player:setZ(v)` | void | Position | MED |
| `player:setLastZ(v)` | void | Position | MED |
| `player:getDir()` | IsoDirections | Position | MED |
| `player:setDir(dir)` | void | Position | MED |
| `player:getSquare()` | IsoGridSquare | Position | HIGH |
| `player:getCurrentSquare()` | IsoGridSquare | Position | HIGH |
| `player:getForwardDirection()` | Vector2 | Position | MED |
| `player:getAimVector(vec)` | Vector2 | Position | MED |
| `player:faceLocationF(x, y)` | void | Position | MED |
| `player:isAiming()` | boolean | Position/State | HIGH |
| `player:IsRunning()` | boolean | Position/State | MED |
| `player:isSprinting()` | boolean | Position/State | MED |
| `player:isSeatedInVehicle()` | boolean | Position/State | MED |
| `player:isClimbing()` | boolean | Position/State | LOW |
| `player:isClimbingRope()` | boolean | Position/State | LOW |
| `player:isPlayerMoving()` | boolean | Position/State | LOW |
| `player:getInventory()` | ItemContainer | Inventory | HIGH |
| `player:getPrimaryHandItem()` | InventoryItem | Inventory | HIGH |
| `player:getSecondaryHandItem()` | InventoryItem | Inventory | HIGH |
| `player:setPrimaryHandItem(item)` | void | Inventory | HIGH |
| `player:setSecondaryHandItem(item)` | void | Inventory | HIGH |
| `player:isPrimaryHandItem(item)` | boolean | Inventory | MED |
| `player:isSecondaryHandItem(item)` | boolean | Inventory | MED |
| `player:isItemInBothHands(item)` | boolean | Inventory | LOW |
| `player:getWornItems()` | WornItems | Inventory | HIGH |
| `player:setWornItem(loc, item)` | void | Inventory | LOW |
| `player:setAttachedItem(slot, item)` | void | Inventory | LOW |
| `player:removeFromHands(item)` | void | Inventory | MED |
| `player:isEquipped(item)` | boolean | Inventory | MED |
| `player:isEquippedClothing(item)` | boolean | Inventory | LOW |
| `player:getInventoryWeight()` | float | Inventory | MED |
| `player:getMaxWeight()` | float | Inventory | MED |
| `player:resetEquippedHandsModels()` | void | Inventory | LOW |
| `player:getStats()` | Stats | Stats | HIGH |
| `player:getNutrition()` | Nutrition | Stats | HIGH |
| `player:getBodyDamage()` | BodyDamage | Health | HIGH |
| `player:getFitness()` | Fitness | Stats/Skills | HIGH |
| `player:getXp()` | XP | Skills/XP | HIGH |
| `player:getPerkLevel(Perks.X)` | int | Skills/XP | HIGH |
| `player:LevelPerk(Perks.X)` | void | Skills/XP | HIGH |
| `player:setPerkLevelDebug(perk, lvl)` | void | Skills/XP | LOW |
| `player:getMoodles()` | MoodleJava | Moodles | HIGH |
| `player:getTraits()` | ArrayList | Traits | HIGH |
| `player:HasTrait(id)` | boolean | Traits | HIGH |
| `player:getCharacterTraits()` | CharacterTraits | Traits | MED |
| `player:getModData()` | table | ModData | HIGH |
| `player:getDescriptor()` | CharacterDescriptor | Identity | HIGH |
| `player:getUsername()` | string | Identity | HIGH |
| `player:getDisplayName()` | string | Identity | MED |
| `player:getOnlineID()` | int | Identity | HIGH |
| `player:getPlayerNum()` | int | Identity | HIGH |
| `player:getRole()` | Role | Identity/Admin | HIGH |
| `player:isFemale()` | boolean | Identity | HIGH |
| `player:setFemale(bool)` | void | Identity | LOW |
| `player:getHumanVisual()` | HumanVisual | Visual | HIGH |
| `player:getVisual()` | Visual | Visual | HIGH |
| `player:isDead()` | boolean | Health | HIGH |
| `player:setHealth(v)` | void | Health | LOW |
| `player:isLocalPlayer()` | boolean | Multiplayer | MED |
| `player:isLocal()` | boolean | Multiplayer | MED |
| `player:getVehicle()` | BaseVehicle | Vehicle | HIGH |
| `player:isSeatedInVehicle()` | boolean | Vehicle | MED |
| `player:playSound(name)` | int | Audio | HIGH |
| `player:getEmitter()` | EmmiterUpdater | Audio | HIGH |
| `player:getJoypadBind()` | int | Input | MED |
| `player:getModData()` | table | ModData | HIGH |
| `player:getVariable(key)` | any | Variables | MED |
| `player:getVariableBoolean(key)` | boolean | Variables | MED |
| `player:setVariable(key, val)` | void | Variables | HIGH |
| `player:setHaloNote(text)` | void | UI/Debug | HIGH |
| `player:reportEvent(name)` | void | Events | MED |
| `player:learnRecipe(name)` | boolean | Recipes | HIGH |
| `player:isRecipeKnown(recipe, bool)` | boolean | Recipes | HIGH |
| `player:isRecipeActuallyKnown(name)` | boolean | Recipes | MED |
| `player:isKnowAllRecipes()` | boolean | Cheats | MED |
| `player:setKnowAllRecipes(bool)` | void | Cheats | MED |

---

## Identity / Descriptor

```lua
-- Username (multiplayer)
local name = player:getUsername()              -- string; ISUsersList.lua
local name = player:getDisplayName()           -- string; ISHealthPanel.lua

-- Numeric IDs
local num  = player:getPlayerNum()             -- int (0-3 for splitscreen); ISBodyPartPanel.lua
local id   = player:getOnlineID()              -- int (multiplayer only); ISHealthPanel.lua

-- Descriptor (character creation data)
local desc = player:getDescriptor()            -- CharacterDescriptor object
desc:getForename()                             -- string
desc:getSurname()                              -- string
desc:isFemale()                                -- boolean
desc:setFemale(bool)                           -- Tutorial1.lua
desc:setForename("Jane")                       -- Tutorial1.lua
desc:setSurname("Doe")                         -- Tutorial1.lua
desc:getCharacterProfession()                  -- returns profession object; LastStandSetup.lua
desc:isCharacterProfession(professionString)   -- boolean; Vehicles.lua
desc:getHumanVisual()                          -- HumanVisual; LastStandSetup.lua

-- Gender shortcut (on player directly)
local female = player:isFemale()               -- boolean; ISClothingInsPanel.lua
player:setFemale(false)                        -- FenrisScenario.lua

-- Role (admin/server)
local role = player:getRole()                  -- Role object
role:hasCapability(Capability.X)               -- boolean; ISAdminPowerUI.lua
role:hasAdminPower()                           -- boolean
role:getPosition()                             -- int (rank level)
```

**Confidence:** HIGH for `getDescriptor`, `getUsername`, `getPlayerNum`, `getOnlineID`. MED for `getDisplayName`.

---

## Position / Movement

```lua
local x = player:getX()                        -- float; used everywhere
local y = player:getY()
local z = player:getZ()

player:setX(x)                                  -- MED; ProfessionVehicles.lua (commented)
player:setY(y)
player:setZ(z)                                  -- ISFastTeleportMove.lua
player:setLastZ(z)                              -- ISFastTeleportMove.lua

local sq  = player:getSquare()                  -- IsoGridSquare; ISBuildWindow.lua
local sq  = player:getCurrentSquare()           -- IsoGridSquare (same in most contexts); luautils.lua

local dir = player:getDir()                     -- IsoDirections; ISButtonPrompt.lua
player:setDir(IsoDirections.W)                  -- ISSpawnVehicleUI.lua

local fwd = player:getForwardDirection()        -- Vector2; FishingRod.lua
local vec = player:getAimVector(outVec)         -- Vector2 (writes into outVec); FishingUtils.lua

player:faceLocationF(x, y)                      -- Face character toward world coords; FishingUtils.lua

-- State checks
player:isAiming()                               -- boolean; XpUpdate.lua
player:IsRunning()                              -- boolean (capital I); XpUpdate.lua
player:isSprinting()                            -- boolean; XpUpdate.lua
player:isSittingOnFurniture()                   -- boolean; ISFitnessUI.lua
player:isClimbing()                             -- boolean; ISFitnessUI.lua
player:isClimbingRope()                         -- boolean; CFarming_Interact.lua
player:isPlayerMoving()                         -- boolean; ISWidgetTitleHeader.lua
player:isSeatedInVehicle()                      -- boolean; ISWorldObjectContextMenu.lua
player:isAsleep()                               -- boolean; ISRadioInteractions.lua
player:isAttacking()                            -- boolean; OnBreak.lua
```

---

## Inventory

```lua
local inv = player:getInventory()               -- ItemContainer; everywhere
-- Common ItemContainer methods on the returned object:
--   inv:AddItem("Base.Axe")
--   inv:Remove(item)
--   inv:getItemWithID(id)
--   inv:contains(item, bool)
--   inv:hasRoomFor(player, weight)
--   inv:getFirstTypeEvalRecurse("Base.PropaneTank", predicate)
--   inv:getItemsFromType("Base.Axe", bool)
--   inv:containsTagEvalRecurse(ItemTag.SCISSORS, predicate)

-- Equipped hand items
local primary   = player:getPrimaryHandItem()   -- InventoryItem or nil; everywhere
local secondary = player:getSecondaryHandItem() -- InventoryItem or nil; OnBreak.lua
player:setPrimaryHandItem(item)                 -- OnBreak.lua / FishingRod.lua
player:setSecondaryHandItem(item)               -- OnBreak.lua / FishingRod.lua
player:isPrimaryHandItem(item)                  -- boolean; ClientCommands.lua
player:isSecondaryHandItem(item)                -- boolean; ClientCommands.lua
player:isItemInBothHands(item)                  -- boolean; ISFitnessUI.lua
player:removeFromHands(item)                    -- removes item from either hand; ClientCommands.lua

-- Clothing / worn items
local worn = player:getWornItems()              -- WornItems list; ISFitnessUI.lua
-- worn:size(), worn:get(i):getItem(), worn:getItem(ItemBodyLocation.EYES)

player:setWornItem(bodyLocation, item)          -- FenrisScenario.lua
player:setAttachedItem("Holster Shoulder", wpn) -- FenrisScenario.lua
player:isEquipped(item)                         -- boolean; ISInventoryPane.lua
player:isEquippedClothing(item)                 -- boolean; ISTradingUI.lua
player:resetEquippedHandsModels()               -- void; FishingRod.lua

-- Weight
local w    = player:getInventoryWeight()        -- float; XpUpdate.lua
local maxW = player:getMaxWeight()              -- float; XpUpdate.lua
```

---

## Stats

```lua
local stats = player:getStats()                 -- Stats object; ISRadioInteractions.lua
-- Stats methods:
--   stats:get(CharacterStat.FATIGUE)           -- ISSleepDialog.lua
--   stats:get(CharacterStat.ENDURANCE)         -- XpUpdate.lua
--   stats:get(CharacterStat.BOREDOM)
--   stats:get(CharacterStat.UNHAPPINESS)
--   stats:add(CharacterStat.BOREDOM, amount)
--   stats:getEnduranceWarning()                -- float threshold

-- Nutrition
local nutr = player:getNutrition()              -- Nutrition; ISCharacterScreen.lua
-- nutr:getWeight()       -> float
-- nutr:setWeight(val)
-- nutr:isIncWeight()     -> boolean
-- nutr:isIncWeightLot()  -> boolean
-- nutr:isDecWeight()     -> boolean
-- nutr:getCalories()     -> float (uncommon usage)

-- Temperature
player:setTemperature(val)                      -- float; season.lua
-- Note: getTemperature not found called directly on player in scanned files

-- Fitness subsystem
local fit = player:getFitness()                 -- Fitness; ISFitnessUI.lua
-- fit:init()
-- fit:getRegularity(exeType)   -> float
-- fit:removeStiffnessValue(bodyPartString)
```

---

## Skills / XP

```lua
-- Get current perk level (0-10)
local lvl = player:getPerkLevel(Perks.Axe)     -- int; used in many files

-- Level a perk up by one level (instant, no XP cost)
player:LevelPerk(Perks.Fitness)                 -- Challenge1.lua, ISSkillProgressBar.lua

-- Debug override of perk level
player:setPerkLevelDebug(Perks.Fitness, 5)      -- ISStatsAndBody.lua

-- XP object
local xp = player:getXp()                      -- XP; ISRadioInteractions.lua
-- xp:AddXP(Perks.X, amount, false, false, false, false)
-- xp:getXP(Perks.X)             -> float (cumulative XP)
-- xp:setXPToLevel(Perks.X, lvl) -> sets XP to exactly the amount needed for lvl
-- xp:getMultiplier(Perks.X)     -> float
-- xp:getPerkBoost(Perks.X)      -> float (occupation/trait boost)
```

---

## Traits

```lua
-- Runtime check (recommended for sanity-traits mod)
if player:HasTrait("Brave") then ... end        -- reference/traits.md, LastStandSetup.lua

-- Get ArrayList of all current traits
local traits = player:getTraits()               -- ArrayList<String>; reference/traits.md
traits:add("MyMod_Depressed")
traits:remove("MyMod_Sad")

-- Full CharacterTraits object (used for serialisation/display)
local ct = player:getCharacterTraits()          -- CharacterTraits; LastStandSetup.lua
local known = ct:getKnownTraits()               -- ArrayList
-- known:size(), known:get(i):getName()
```

**Note on vanilla game files:** The game's own Lua never calls `HasTrait` in the scanned client/server/shared files — trait checks in vanilla code use `getCharacterTraits()`. The `HasTrait` shortcut is confirmed in `reference/traits.md` and is the standard mod usage pattern.

---

## Moodles / Mood

```lua
local moodles = player:getMoodles()             -- MoodleJava; ISRadioInteractions.lua
-- moodles:getMoodleLevel(MoodleType.ENDURANCE)  -> int (0-4)
-- moodles:getMoodleLevel(MoodleType.HEAVY_LOAD)
-- moodles:getMoodleLevel(MoodleType.PAIN)
-- moodles:getMoodleLevel(MoodleType.FOOD_EATEN)
-- Common MoodleTypes: ENDURANCE, HEAVY_LOAD, PAIN, FOOD_EATEN,
--   HUNGER, THIRST, BOREDOM, UNHAPPY, TIRED, ANGRY, PANICKED,
--   SICK, BLEEDING, INFECTED
```

---

## ModData

```lua
-- Per-character persistent table (survives save/load)
local data = player:getModData()                -- table (Lua metatable-wrapped Java map)
data.SanityTraits = data.SanityTraits or {}     -- LastStandSetup.lua, FishingRod.lua

-- Usage pattern (write)
player:getModData()["myKey"] = someValue

-- Usage pattern (read)
local val = player:getModData()["myKey"] or defaultValue
```

---

## Health / Body

```lua
local bd = player:getBodyDamage()               -- BodyDamage; ISBodyPartPanel.lua
-- bd:getBodyParts()              -> ArrayList of BodyPart
-- bd:getThermoregulator()        -> Thermoregulator object

player:isDead()                                 -- boolean; used everywhere
player:setHealth(1.0)                           -- float 0.0–1.0; DebugDemoTime.lua

-- Visual damage / blood (mostly debug or tutorial)
player:addBlood(bodyPartType, front, back, bool)   -- ISHealthPanel.lua
player:addHole(bodyPartType)                        -- ISHealthPanel.lua
player:addBasicPatch(bodyPartType)                  -- ISHealthPanel.lua
player:addDirt(bodyPartType, nil, bool)             -- ISHealthPanel.lua
player:resetModelNextFrame()                        -- ISHealthPanel.lua

-- Infection (no direct call found in scanned files — use getBodyDamage():isInfected())
```

---

## Visual / Appearance

```lua
-- HumanVisual — the saved/created visual data
local hv = player:getHumanVisual()             -- ISCharacterScreen.lua
-- hv:getHairModel()              -> string
-- hv:getBeardModel()             -> string
-- hv:getLastStandString()        -> serialized string; LastStandSetup.lua
-- hv:loadLastStandString(str)    -> restore from string; LastStandSetup.lua
-- hv:copyFrom(otherHumanVisual)

-- Visual — the live in-world visual state
local vis = player:getVisual()                  -- ISCharacterScreen.lua
-- vis:setBlood(bodyPartType, 0)
-- vis:setDirt(bodyPartType, 0)
-- vis:setHairModel("Bob")                      -- Tutorial/Steps.lua
-- vis:setHairColor(immutableColor)
-- vis:setBeardModel("Full")
-- vis:setSkinTextureIndex(int)
-- vis:getNonAttachedHair()        -> string or nil
-- vis:setNonAttachedHair(name)

player:setFemale(bool)                          -- FenrisScenario.lua
player:setWornItem(bodyLocation, item)          -- FenrisScenario.lua
```

---

## Audio

```lua
-- Direct sound playback on the character's position
player:playSound("SoundName")                   -- returns sound handle int; FishingRod.lua, Fishing Bobber.lua
-- Examples: "BreakFishingLine", "LureHitWater"

-- Emitter — for looping/managed sounds
local emitter = player:getEmitter()             -- EmmiterUpdater; ISReloadWeaponAction.lua
-- emitter:playSound("SoundName")   -> int handle
-- emitter:isPlaying(handle)        -> boolean
-- emitter:stopSound(handle)
-- emitter:stopOrTriggerSound(handle)
```

---

## Actions / Queue

```lua
player:hasTimedActions()                        -- boolean; CFarming_Interact.lua

-- No direct stopAllActionQueue call found in scanned files.
-- Use ISTimedActionQueue.clear(player) from Lua to clear the queue.

-- Variable-based action state
player:setVariable("ExerciseStarted", false)    -- string key, any value; ISFitnessUI.lua
player:getVariable("FishingFinished")           -- FishingManager.lua
player:getVariableBoolean("sitonground")        -- boolean; ISFitnessUI.lua
player:getVariableBoolean("isLoading")          -- ISReloadWeaponAction.lua

-- Fishing-specific (animation state machine)
player:setFishingStage("Cast")                  -- string; FishingStates.lua
player:setIsAiming(bool)                        -- FishingStates.lua
player:setIsFarming(bool)                       -- CFarming_Interact.lua
```

---

## Recipes / Knowledge

```lua
-- Learn a recipe by name
local ok = player:learnRecipe("Generator")       -- boolean; XpUpdate.lua, ISRadioInteractions.lua

-- Check recipe knowledge
player:isRecipeKnown(craftRecipe, bool)           -- ISRecipeScrollingListBox.lua
player:isRecipeActuallyKnown(recipeName)          -- CFarming_Interact.lua

-- Known media (radio broadcasts)
player:isKnownMediaLine(guid)                    -- boolean; ISRadioInteractions.lua
player:addKnownMediaLine(guid)                   -- ISRadioInteractions.lua

-- Known poison
player:isKnownPoison(item)                       -- boolean; ISInventoryPane.lua

-- Known map
player:hasReadMap(item)                          -- boolean; ISInventoryPane.lua
```

---

## Profession Detection

```lua
-- Full chain to get profession ID string
local prof = player:getDescriptor():getCharacterProfession()
-- prof:getName()    -> string (e.g. "police", "doctor")
-- prof is returned as a CharacterProfessionDefinition key — compare with strings
-- from CharacterProfessionDefinition.getCharacterProfessionDefinition(key)

-- Shortcut check (Vehicles.lua)
chr:getDescriptor():isCharacterProfession("police")   -- boolean
```

---

## Multiplayer / Social

```lua
-- Local player checks
player:isLocalPlayer()                           -- boolean; ServerCommands.lua
player:isLocal()                                 -- boolean; FishingHandler.lua

-- Online identity
player:getUsername()                             -- string; used across MP files
player:getOnlineID()                             -- int; sent in server commands
player:getRole()                                 -- Role object (see Identity section)

-- Faction / PvP flags
player:isShowTag()                               -- boolean; ISFactionUI.lua
player:setShowTag(bool)
player:isFactionPvp()                            -- boolean; ISFactionUI.lua
player:setFactionPvp(bool)

-- Zone visibility
player:setSeeNonPvpZone(bool)                    -- ISAddNonPvpZoneUI.lua
player:isSeeNonPvpZone()                         -- boolean
player:setSeeDesignationZone(bool)               -- ISDesignationZonePanel.lua
player:addSelectedZoneForHighlight(zoneId)       -- ISDesignationZonePanel.lua
```

---

## Vehicle

```lua
local v = player:getVehicle()                    -- BaseVehicle or nil; XpUpdate.lua
-- Check: if player:getVehicle() then ... end
player:isSeatedInVehicle()                       -- boolean; ISWorldObjectContextMenu.lua
```

---

## Sleep

```lua
player:setAsleep(bool)                           -- ISSleepDialog.lua
player:setAsleepTime(float)                      -- ISSleepDialog.lua
player:setForceWakeUpTime(hours)                 -- ISSleepDialog.lua
player:isAsleep()                                -- boolean; ISRadioInteractions.lua
```

---

## Cheat / Admin Flags

These are only meaningful in admin/debug contexts. Listed for completeness.

```lua
player:isGodMod()          / player:setGodMod(bool)
player:isInvisible()       / player:setInvisible(bool)
player:isNoClip()          / player:setNoClip(bool)
player:isGhostMode()       / player:setGhostMode(bool)
player:isInvincible()      / player:setInvincible(bool)
player:isUnlimitedAmmo()   / player:setUnlimitedAmmo(bool)
player:isUnlimitedCarry()  / player:setUnlimitedCarry(bool)
player:isUnlimitedEndurance() / player:setUnlimitedEndurance(bool)
player:isBuildCheat()      / player:setBuildCheat(bool)
player:isFishingCheat()    / player:setFishingCheat(bool)
player:isFarmingCheat()    / player:setFarmingCheat(bool)     (note: no is* found, set* confirmed)
player:isMovablesCheat()   / player:setMovablesCheat(bool)
player:isZombiesDontAttack() / player:setZombiesDontAttack(bool)
player:isTimedActionInstantCheat() / player:setTimedActionInstantCheat(bool)
player:isAnimalExtraValuesCheat() / player:setAnimalExtraValuesCheat(bool)
player:setHealthCheat(bool)
player:setMechanicsCheat(bool)
player:setFastMoveCheat(bool)
player:setCanSeeAll(bool)
player:setCanHearAll(bool)
player:setCanUseBrushTool(bool)
player:setCanUseLootZed(bool)
player:setCanUseLootLog(bool)
player:setAnimalCheat(bool)
player:setKnowAllRecipes(bool)  / player:isKnowAllRecipes()
```

---

## UI / Debug Helpers

```lua
player:setHaloNote("text")                       -- shows floating text above character; ISRadioInteractions.lua
player:reportEvent("EventAttachItem")            -- fires a named event; OnBreak.lua
player:playDropItemSound(item)                   -- OnBreak.lua
player:getLastHitCharacter()                     -- IsoGameCharacter or nil; OnBreak.lua
player:hasAwkwardHands()                         -- boolean; ISCraftRecipeInfoBox.lua
```

---

## IsoZombie — Specific Methods

Zombies share the `IsoGameCharacter` base but have additional zombie-specific methods. All calls below were found in `Tutorial/Steps.lua` or `DebugContextMenu.lua`.

```lua
zombie:isDead()                                  -- boolean; Tutorial/Steps.lua (commented debug)
zombie:getHealth()                               -- float; Tutorial/Steps.lua (commented debug)
zombie:isFemale()                                -- boolean; Steps.lua
zombie:removeFromWorld()                         -- void; Steps.lua, DebugContextMenu.lua
zombie:removeFromSquare()                        -- void; Steps.lua
zombie:dressInRandomOutfit()                     -- void; Steps.lua
zombie:dressInNamedOutfit("TutorialDad")         -- void; Steps.lua
zombie:DoZombieInventory()                       -- void; Steps.lua
zombie:getVisual()                               -- Visual; Steps.lua
zombie:addBlood(bodyPart, front, back, bool)     -- Steps.lua
zombie:addHole(bodyPart)                         -- Steps.lua
zombie:addVisualDamage(texture)                  -- DamageModelDefinitions.lua
zombie:getX() / zombie:getY()                    -- float; Steps.lua
zombie:setX(v) / zombie:setY(v)
zombie:setDir(IsoDirections.E)                   -- Steps.lua
zombie:getCurrentSquare()                        -- IsoGridSquare; Steps.lua
zombie:getCurrentState()                         -- state object; Steps.lua
zombie:getHitReaction()                          -- string; Steps.lua
zombie:resetModelNextFrame()                     -- Steps.lua
zombie:setAttachedItem("Knife in Back", item)    -- Steps.lua
zombie:setUseless(bool)                          -- Steps.lua
zombie:setNoDamage(bool)                         -- Steps.lua
zombie:setReanimateTimer(int)                    -- Steps.lua (ticks before reanimate)
zombie:setAlwaysKnockedDown(bool)                -- Steps.lua
zombie:setImmortalTutorialZombie(bool)           -- Steps.lua
zombie:setForceEatingAnimation(bool)             -- Steps.lua
zombie:setOnlyJawStab(bool)                      -- Steps.lua
zombie:setDressInRandomOutfit(bool)              -- Steps.lua
zombie:setCanWalk(bool)    / zombie:isCanWalk()  -- DebugContextMenu.lua
zombie:setFakeDead(bool)   / zombie:isFakeDead() -- DebugContextMenu.lua
zombie:setUseless(bool)    / zombie:isUseless()  -- DebugContextMenu.lua
zombie:knockDown(hitFromBehind)                  -- DebugContextMenu.lua
zombie:SetOnFire()                               -- DebugContextMenu.lua (capital S)
zombie:setCanCrawlUnderVehicle(bool)             -- DebugContextMenu.lua
zombie:removeAttachedItem(item)                  -- ISAttachedItemsUI.lua
zombie:getAttachedItems()                        -- ArrayList; ISAttachedItemsUI.lua
```

---

## Common Chained Patterns

These multi-step call chains appear frequently across the codebase:

```lua
-- Profession check (forageSystem.lua:1867 pattern)
local profName = player:getDescriptor():getCharacterProfession():getName()

-- XP award (standard pattern, shared/server side)
player:getXp():AddXP(Perks.Carpentry, 3, false, false, false, false)

-- Stats get/set
player:getStats():get(CharacterStat.FATIGUE)
player:getStats():add(CharacterStat.BOREDOM, -10)

-- Moodle level check
player:getMoodles():getMoodleLevel(MoodleType.PAIN)   -- returns 0-4

-- ModData read/write
player:getModData().SanityTraits = player:getModData().SanityTraits or {}

-- Inventory item search
player:getInventory():getFirstTagEvalRecurse(ItemTag.SCREWDRIVER, predicateNotBroken)

-- Worn item access
local eyewear = player:getWornItems():getItem(ItemBodyLocation.EYES)

-- Character screen descriptor chain
player:getDescriptor():getForename() .. " " .. player:getDescriptor():getSurname()
```
