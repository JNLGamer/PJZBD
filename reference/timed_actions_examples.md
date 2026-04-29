# Vanilla Timed Actions Reference

**Source:** `ProjectZomboid/media/lua/shared/TimedActions/`
**Build:** 42 (verified from game source)

---

## ISBaseTimedAction Lifecycle

Every timed action goes through the same Java-driven lifecycle. Understanding the order of calls is the most important thing before writing your own action.

```
Queue.add(MyAction:new(...))
         │
         ▼
  isValidStart()  ← called once before the action begins; false = skip entirely
         │
         ▼
  waitToStart()   ← called every frame while waiting; returns true = "still turning/facing"
         │
         ▼
    start()       ← one-shot setup: set animation, sounds, jobType label
         │
         ▼
    update()      ← called every frame while running; drive progress bar, loop sounds
         │
    [time expires or forceComplete()]
         │
         ▼
   perform()      ← cleanup: stop sounds, setDrawDirty, then call ISBaseTimedAction.perform(self)
         │
         ▼
   complete()     ← do the actual effect: consume item, grant XP, apply stats
         │
         ▼
  [next action in queue starts]

         OR

    [interrupt / walk away]
         │
         ▼
     stop()       ← cleanup: stop sounds, reset jobDelta, call ISBaseTimedAction.stop(self)
```

**Critical rules extracted from source:**

- `perform()` advances the queue. You MUST call `ISBaseTimedAction.perform(self)` at the end — without it the next queued action never starts.
- `stop()` resets the queue. You MUST call `ISBaseTimedAction.stop(self)` — it calls `resetQueue()`.
- Item consumption and stat changes go in `complete()`, NOT in `perform()`. `perform()` is only for cleanup and queue advancement.
- `maxTime` is set in `new()`, optionally via `getDuration()`. It is auto-adjusted by `adjustMaxTime()` which adds time for unhappiness, drunk moodles, and hand wounds.
- `maxTime = -1` means the action is animation-driven: Java runs it until `forceComplete()` is called, typically from `animEvent()`.
- `stopOnWalk`, `stopOnRun`, `stopOnAim` are set in `new()` and default to `true` in the base. Override them to allow actions while moving.

---

## ISBaseTimedAction — Base Class

**Source:** `ISBaseTimedAction.lua`

### Key base fields set in `new(character)`

| Field | Default | Meaning |
|-------|---------|---------|
| `self.character` | arg | The IsoPlayer/IsoGameCharacter |
| `self.stopOnWalk` | `true` | Interrupt if player walks |
| `self.stopOnRun` | `true` | Interrupt if player runs |
| `self.stopOnAim` | `true` | Interrupt if player aims |
| `self.caloriesModifier` | `1` | Multiplier for calorie burn rate |
| `self.maxTime` | `-1` | Duration in ticks; -1 = anim-driven |
| `self.ignoreHandsWounds` | unset | Set to `true` to skip wound penalty in `adjustMaxTime()` |

### `adjustMaxTime(maxTime)` — automatic duration modifiers

```lua
-- ISBaseTimedAction.lua:99-123
-- Applied automatically in create() before the action starts.
maxTime = maxTime * (1 + (moodleLevel(UNHAPPY) / 4))   -- up to +25% per moodle level
maxTime = maxTime * (1 + (moodleLevel(DRUNK)   / 4))   -- drunk slows everything
-- hand wound pain: each arm/hand part contributes; maxPain/300 is the multiplier
maxTime = maxTime * (1 + (maxPain / 300))
-- body temperature / other stat modifier
maxTime = maxTime * self.character:getTimedActionTimeModifier()
```

**Pattern:** Never apply these yourself — let `adjustMaxTime` handle them. Use `ignoreHandsWounds = true` for actions where hand injuries shouldn't matter (equipping, eating).

---

## Item Consumption

### ISEatFoodAction — Eating Food

**Source:** `ISEatFoodAction.lua`

**Pattern:** Consume a food item partially or fully, with animation and looping sound.

#### Constructor

```lua
function ISEatFoodAction:new(character, item, percentage)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.container = item:getContainer() or character:getInventory()
    o.percentage = percentage          -- fraction of food to consume (0.0-1.0)
    o.stopOnWalk = false               -- eating while walking is allowed
    o.stopOnAim  = false               -- eating while aiming is allowed
    o.ignoreHandsWounds = true
    o.maxTime = ISEatFoodAction.getDuration(o)
    o.eatSound  = item:getCustomEatSound() or "Eating"
    o.eatAudio  = 0                    -- sound handle; 0 = not playing
    return o
end
```

| Param | Type | Meaning |
|-------|------|---------|
| `character` | IsoGameCharacter | The eater |
| `item` | InventoryItem | The food |
| `percentage` | float (0-1) | How much of the remaining food to eat this action |

#### `isValidStart()`

```lua
-- Don't start eating if the character is already stuffed (moodle level 3)
return self.character:getMoodles():getMoodleLevel(MoodleType.FOOD_EATEN) < 3
```

#### `isValid()` — called every frame during the action

```lua
-- Multiplayer: check by ID (item reference can go stale across network)
if isClient() and self.item then
    if self.character:getInventory():containsID(self.item:getID()) then
        return true
    else
        self:forceComplete()  -- item was taken away; skip to perform()
        return false
    end
else
    return self.character:getInventory():contains(self.item)
end
```

**Pattern:** Always check inventory in `isValid()`. In multiplayer, use `containsID()` because item object identity can differ between client and server.

#### `start()` — set animation

```lua
-- Sets the eating or drinking anim based on item metadata
if item:getCustomMenuOption() == getText("ContextMenu_Drink") then
    self:setActionAnim(CharacterActionAnims.Drink)
else
    self:setActionAnim(CharacterActionAnims.Eat)
end
-- Determines utensil/bowl/can animation variant
self:setAnimVariable("FoodType", self.item:getEatType())
self:setOverrideHandModels(secondItem, self.item)  -- show item in hand
self.character:reportEvent("EventEating")
```

**Key animations:** `CharacterActionAnims.Eat`, `CharacterActionAnims.Drink`

#### `update()` — drive progress bar + loop sound

```lua
self.item:setJobDelta(self:getJobDelta())  -- drives the item's progress bar in UI
if self.eatAudio ~= 0 and not self.character:getEmitter():isPlaying(self.eatAudio) then
    self.eatAudio = self.character:getEmitter():playSound(self.eatSound)
end
```

**Pattern:** Call `item:setJobDelta(self:getJobDelta())` in `update()` to show the progress bar on the item in the inventory panel.

#### `stop()` — interrupt cleanup

```lua
-- Always stop sounds in stop()
if self.eatAudio ~= 0 and self.character:getEmitter():isPlaying(self.eatAudio) then
    self.character:stopOrTriggerSound(self.eatAudio)
end
self.item:setJobDelta(0.0)    -- reset item progress bar
ISBaseTimedAction.stop(self)  -- REQUIRED
```

#### `perform()` — completion cleanup (NOT where food is consumed)

```lua
-- Sounds stop here too
self.container:setDrawDirty(true)  -- redraw inventory container UI
self.item:setJobDelta(0.0)
ISBaseTimedAction.perform(self)    -- REQUIRED — advances queue
```

#### `complete()` — actual effect

```lua
-- The actual eating happens here, NOT in perform()
self.character:Eat(self.item, self.percentage, self.useUtensil)
return true
```

**Why `complete()` not `perform()`:** If the action is interrupted, `stop()` fires instead of `perform()`, so the item is never consumed. Putting consumption in `complete()` guarantees it only happens on successful completion.

#### `getDuration()` — dynamic timing

```lua
-- Duration scales with how much hunger the food satisfies
local maxTime = math.abs(self.item:getBaseHunger() * 150 * self.percentage) * 8
-- Minimum ~232 ticks for 1 eating loop, up to 696 for 3 loops
-- Override with item:getEatTime() if set
```

---

### ISTakePillAction — Taking Medicine / Pills

**Source:** `ISTakePillAction.lua`

**Pattern:** Identical structure to ISEatFoodAction but for pills/medicine. Simpler because pills don't have a percentage eaten.

#### Constructor

```lua
function ISTakePillAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.stopOnWalk = false
    o.stopOnAim  = false
    o.maxTime    = o:getDuration()   -- 165 ticks default, or item:getEatTime()
    o.isEating   = true
    return o
end
```

#### Key differences from ISEatFoodAction

```lua
-- start(): puts item in secondary hand only (not primary)
self:setOverrideHandModels(nil, self.item)

-- update(): animation is set PER-FRAME based on item type
-- (unusual pattern — most actions set anim once in start())
if self.item:getEatType() then
    self:setAnimVariable("FoodType", self.item:getEatType())
    self:setActionAnim(CharacterActionAnims.Eat)
else
    self:setActionAnim(CharacterActionAnims.TakePills)
end

-- complete(): applies pill body effects via BodyDamage API
self.character:getBodyDamage():JustTookPill(self.item)
```

**Key animation:** `CharacterActionAnims.TakePills` (default), `CharacterActionAnims.Eat` (if food-type pill)

---

### ISDrinkFromBottle — Drinking Fluid

**Source:** `ISDrinkFromBottle.lua`

**Pattern:** Partial consumption from a fluid container. Demonstrates how to apply effects per-tick during the action rather than all at once.

#### Constructor

```lua
function ISDrinkFromBottle:new(character, item, uses)
    local o = ISBaseTimedAction.new(self, character)
    o.uses = uses           -- number of "sips" to take
    o.eatSound = item:getFluidContainer():getCustomDrinkSound()
    o.ignoreHandsWounds = true
    o.maxTime = o:getDuration()  -- uses < 4 → 120; else uses * 30
    return o
end
```

#### Notable: `stop()` partially applies the effect

```lua
function ISDrinkFromBottle:stop()
    -- Partial drink is applied on interrupt, proportional to progress
    if self.character:getInventory():contains(self.item) then
        self:drink(self.item, self:getJobDelta())
    end
    ISBaseTimedAction.stop(self)
end
```

**Why:** Drinking is designed to apply partial benefit if interrupted (you took a sip). Eating food does NOT do this by default — interrupted eating loses the food's effect entirely. Choose which behavior fits your mod.

#### `complete()` applies full effect

```lua
function ISDrinkFromBottle:complete()
    self:drink(self.item, 1)   -- 1 = 100% of the requested uses
    return true
end
```

#### Fluid depletion inside `drink()`

```lua
-- Reduce thirst stat per sip
self.character:getStats():remove(CharacterStat.THIRST, 0.1)
-- Deplete the fluid container
local amount = self.item:getFluidContainer():getAmount() - 0.12
self.item:getFluidContainer():adjustAmount(math.max(amount, 0))
```

**Key animation:** `CharacterActionAnims.Drink`

---

## Medical

### ISApplyBandage — Bandage / Remove Bandage

**Source:** `ISApplyBandage.lua`

**Pattern:** Action that can target SELF or ANOTHER player. Demonstrates `waitToStart()` for facing, multiplayer lock-out for body parts, and skill-scaled duration.

#### Constructor

```lua
function ISApplyBandage:new(character, otherPlayer, item, bodyPart, doIt)
    local o = ISBaseTimedAction.new(self, character)
    o.otherPlayer = otherPlayer  -- may equal character for self-treatment
    o.item        = item         -- bandage item (nil = removing a bandage)
    o.bodyPart    = bodyPart     -- BodyPart object
    o.doIt        = doIt         -- true = apply, false = remove
    o.doctorLevel = character:getPerkLevel(Perks.Doctor)
    -- stop while walking only for lower-body parts (legs need you to stand still)
    o.stopOnWalk  = bodyPart:getIndex() > BodyPartType.ToIndex(BodyPartType.Groin)
    o.maxTime = o:getDuration()  -- 120 - (doctorLevel * 4)
    return o
end
```

#### `waitToStart()` — face the patient first

```lua
function ISApplyBandage:waitToStart()
    if self.character == self.otherPlayer or self.character:isSeatedInVehicle() then
        return false  -- no wait needed for self-treatment
    end
    self.character:faceThisObject(self.otherPlayer)
    return self.character:shouldBeTurning()  -- returns true until fully turned
end
```

**Pattern:** Use `faceThisObject()` + `shouldBeTurning()` in `waitToStart()` for any action targeting a world object or another character. Also used in `update()` to keep facing during the action.

#### `isValid()` — multiplayer body part lock

```lua
function ISApplyBandage:isValid()
    -- Abort if either party moved too far
    if ISHealthPanel.DidPatientMove(...) then return false end
    -- In multiplayer, another player could already be bandaging this part
    if self.item then
        return isClient() and self.itemWasPresent
                          or self.character:getInventory():contains(self.item)
    else
        return isClient() and self.wasBandaged
                          or self.bodyPart:bandaged()
    end
end
```

#### `complete()` — item consumed here, XP granted

```lua
-- Remove bandage from inventory
self.character:getInventory():Remove(self.item)
-- Apply bandage state to body part
self.otherPlayer:getBodyDamage():SetBandaged(
    self.bodyPart:getIndex(), true, bandageLife, self.item:isAlcoholic(),
    self.item:getModule() .. "." .. self.item:getType()
)
-- Grant XP
addXp(self.character, Perks.Doctor, 5)
```

**Key animation:** `CharacterActionAnims.Bandage` (self), `"Loot"` (treating another player)
**Anim variable:** `"BandageType"` — value from `ISHealthPanel.getBandageType(bodyPart)`

---

## Equipment

### ISEquipWeaponAction — Equip Primary / Secondary / Two-Handed

**Source:** `ISEquipWeaponAction.lua`

**Pattern:** Equip an item to primary hand, secondary hand, or both. Handles hotbar detach animation. Demonstrates `animEvent()` callback.

#### Constructor

```lua
function ISEquipWeaponAction:new(character, item, maxTimeInit, primary, twoHands, alwaysTurnOn)
    local o = ISBaseTimedAction.new(self, character)
    o.item       = item
    o.primary    = primary    -- true = primary hand, false = secondary
    o.twoHands   = twoHands   -- true = equip to both hands simultaneously
    o.stopOnWalk = false
    o.stopOnAim  = false
    o.ignoreHandsWounds = true
    o.maxTime = maxTimeInit   -- pass 0 for instant equip
    -- fromHotbar: if the item is attached to the hotbar, use detach animation
    o.fromHotbar = o.hotbar and o.hotbar:isItemAttached(item)
    return o
end
```

| Param | Type | Meaning |
|-------|------|---------|
| `maxTimeInit` | int | Duration; 0 = instant |
| `primary` | bool | true = primary hand |
| `twoHands` | bool | true = both hands (overrides primary) |

#### `start()` — animation branch

```lua
if self.fromHotbar then
    self:setActionAnim("DetachItem")  -- plays detach-from-back/belt anim
else
    self:setActionAnim("EquipItem")
end
```

#### `animEvent()` — animation-driven equip timing

```lua
function ISEquipWeaponAction:animEvent(event, parameter)
    if event == 'detachConnect' then
        -- Mid-animation: item visually leaves the hotbar slot
        hotbar.chr:removeAttachedItem(self.item)
        self:setOverrideHandModels(self.item, self.twoHands and self.item or nil)
        self:overrideWeaponType()  -- fix anim blending
        if self.maxTime == -1 then
            self:forceComplete()
        end
    end
end
```

**Pattern:** For `maxTime = -1` (anim-driven), call `self:forceComplete()` inside `animEvent()` when the animation signal arrives.

#### `complete()` — the actual hand assignment

```lua
if self.primary then
    self.character:setPrimaryHandItem(nil)
    self.character:setPrimaryHandItem(self.item)
else
    self.character:setSecondaryHandItem(nil)
    self.character:setSecondaryHandItem(self.item)
end
-- Two-handed: assign to both
self.character:setPrimaryHandItem(self.item)
self.character:setSecondaryHandItem(self.item)
```

**Why nil first:** Calling `setPrimaryHandItem(nil)` before setting the new item ensures the previous item's equipped state is cleanly cleared.

#### `stop()` — restore weapon type

```lua
self:restoreWeaponType()  -- undo overrideWeaponType() if called in animEvent
self.item:setJobDelta(0.0)
ISBaseTimedAction.stop(self)
```

---

### ISUnequipAction — Unequip Hand Item or Clothing

**Source:** `ISUnequipAction.lua`

**Pattern:** Remove item from hand or worn clothing slot. Mirror of ISEquipWeaponAction.

#### Constructor

```lua
function ISUnequipAction:new(character, item, maxTimeInit)
    local o = ISBaseTimedAction.new(self, character)
    o.item = item
    o.stopOnWalk = ISWearClothing.isStopOnWalk(item)  -- clothing-dependent
    o.fromHotbar = o.hotbar and o.hotbar:isItemAttached(item)
    o.maxTime = maxTimeInit
    return o
end
```

#### `complete()` — clear the hand slots

```lua
self.character:removeWornItem(self.item)
if self.item == self.character:getPrimaryHandItem() then
    self.character:setPrimaryHandItem(nil)
end
if self.item == self.character:getSecondaryHandItem() then
    self.character:setSecondaryHandItem(nil)
end
sendEquip(self.character)             -- sync to server
triggerEvent("OnClothingUpdated", self.character)
```

---

### ISWearClothing — Wear Clothing Item

**Source:** `ISWearClothing.lua`

**Pattern:** Equip an item to a body location (clothing slot). Demonstrates animation variable table for body location.

#### `WearClothingAnimations` table

```lua
-- Maps ItemBodyLocation → animation variant string used by "WearClothing" AnimSet
WearClothingAnimations[ItemBodyLocation.JACKET]  = "Jacket"
WearClothingAnimations[ItemBodyLocation.PANTS]   = "Legs"
WearClothingAnimations[ItemBodyLocation.HAT]     = "Face"
WearClothingAnimations[ItemBodyLocation.SHOES]   = "Feet"
-- etc.
```

#### `start()`

```lua
self:setActionAnim("WearClothing")
self:setAnimVariable("WearClothingLocation", WearClothingAnimations[location] or "")
self.character:reportEvent("EventWearClothing")
```

**Pattern:** When an action has multiple animation variants, define a lookup table keyed on item metadata and call `setAnimVariable()` with the result.

---

## Environmental Actions

### ISChopTreeAction — Chop Tree

**Source:** `ISChopTreeAction.lua`

**Pattern:** Repeating environmental action where each animation cycle does damage. Demonstrates `maxTime = -1` (animation-driven), `animEvent()` for per-swing effects, and endurance drain.

#### Constructor

```lua
function ISChopTreeAction:new(character, tree)
    local o = ISBaseTimedAction.new(self, character)
    o.tree = tree             -- IsoTree object
    o.maxTime = -1            -- animation-driven; never times out
    o.caloriesModifier = 8    -- burns 8x normal calories (hard labor)
    o.forceProgressBar = true -- show progress bar even with maxTime=-1
    return o
end
```

#### `isValid()` — checks tool AND environment each frame

```lua
return self.tree ~= nil and
       self.tree:getObjectIndex() >= 0 and                          -- tree still exists
       self.character:isEnduranceSufficientForAction() and          -- has stamina
       self.character:getPrimaryHandItem() ~= nil and
       self.character:getPrimaryHandItem():hasTag(ItemTag.CHOP_TREE) and  -- axe in hand
       not self.character:getPrimaryHandItem():isBroken()
```

**Pattern:** `isValid()` runs every frame. For environmental actions, check that the target still exists (object index >= 0) in addition to tool validity.

#### `waitToStart()` — face the tree

```lua
self.character:faceThisObject(self.tree)
return self.character:shouldBeTurning()
```

#### `update()` — maintain facing + set metabolics

```lua
self.axe:setJobDelta(self:getJobDelta())
self.character:faceThisObject(self.tree)        -- re-face on each tick
self.character:setMetabolicTarget(Metabolics.ForestryAxe)  -- calorie burn rate
```

#### `animEvent()` — actual tree damage per swing

```lua
function ISChopTreeAction:animEvent(event, parameter)
    if event == 'ChopTree' and self.axe then
        -- Damage is applied per animation event, not per frame
        self.tree:WeaponHit(self.character, self.axe)
        self.character:addCombatMuscleStrain(self.axe, 1, modifier)
        self:useEndurance()
        -- Tree fell?
        if self.tree:getObjectIndex() == -1 then
            self:forceComplete()  -- done; tree is gone
        end
    end
end
```

**Key animation:** `CharacterActionAnims.Chop_tree`

#### `start()` grabs the axe from hand

```lua
function ISChopTreeAction:start()
    self.axe = self.character:getPrimaryHandItem()  -- cache at start
    self:setActionAnim(CharacterActionAnims.Chop_tree)
    self:setOverrideHandModels(self.axe, nil)
end
```

**Why cache in `start()`, not `new()`:** The player could swap weapons between queuing the action and starting it. Always re-read hand items in `start()`.

---

## Inventory Transfer

### ISDropWorldItemAction — Drop Item to World

**Source:** `ISDropWorldItemAction.lua`

**Pattern:** Take an item from inventory and place it as a world object on a specific map square.

#### Constructor

```lua
function ISDropWorldItemAction:new(character, item, sq, xoffset, yoffset, zoffset, rotation, isMultiple)
    local o = ISBaseTimedAction.new(self, character)
    o.item    = item
    o.sq      = sq          -- IsoGridSquare target
    o.xoffset = xoffset     -- sub-tile position (0.0-1.0)
    o.yoffset = yoffset
    o.zoffset = zoffset
    o.rotation = rotation
    o.stopOnWalk = false     -- can drop while walking
    o.stopOnRun  = false     -- can drop while running
    o.maxTime = o:getDuration()
    return o
end
```

#### `getDuration()` — trait-aware

```lua
local maxTime = 50 * math.min(self.item:getActualWeight(), 3) * 0.1
if self.character:hasTrait(CharacterTrait.DEXTROUS)  then maxTime = maxTime * 0.5 end
if self.character:hasTrait(CharacterTrait.ALL_THUMBS) then maxTime = maxTime * 2.0 end
```

**Pattern:** Scale duration by item weight and check traits inside `getDuration()`. This is where trait modifiers belong — not hardcoded in `new()`.

#### `isValid()` — checks square capacity

```lua
local ground = self.sq:getTotalWeightOfItemsOnFloor()
if ground + self.item:getUnequippedWeight() > 50 then return false end
return self.character:getInventory():contains(self.item)
```

#### `complete()` — places item in world

```lua
-- Place item as world object on the target square
local worldItem = self.sq:AddWorldInventoryItem(self.item, self.xoffset, self.yoffset, self.zoffset, false)
worldItem:getWorldItem():setIgnoreRemoveSandbox(true)  -- prevent sandbox cleanup
-- Remove from inventory AFTER placing in world
self.character:getInventory():Remove(self.item)
sendRemoveItemFromContainer(self.character:getInventory(), self.item)
```

**Why remove AFTER placing:** If removal happened first and placing failed, the item would vanish. Always add to destination before removing from source.

#### `perform()` — sound continuation trick

```lua
-- If the next queued action is also a drop of the same item type,
-- pass the sound handle forward so audio doesn't stutter between items
local nextAction = actionQueue.queue[2]
if not nextAction or nextAction.item:getFullType() ~= self.item:getFullType() then
    self.character:stopOrTriggerSound(self.sound)
else
    nextAction.sound = self.sound  -- pass sound to next action
end
```

**Pattern:** Reusable between chained identical actions to avoid sound stutter.

---

### ISTransferAction — Utility Class for Container Transfers

**Source:** `ISTransferAction.lua`

**Note:** This is NOT a timed action subclass. It is a utility object that other timed actions call. Its `transferItem()` method handles the full complexity of moving items between containers, including floor drops, Radio special objects, and vehicle container weight sync.

#### Useful static helpers

```lua
-- Find a nearby floor square that has capacity for an item
ISTransferAction:getNotFullFloorSquare(character, item, destContainer)

-- Get a randomized drop position within a square
local x, y, z = ISTransferAction.GetDropItemOffset(character, square, item)

-- Remove item from hands/clothing if currently equipped, return true if it should be world-added
ISTransferAction:removeItemOnCharacter(character, item)
```

#### `transferItem()` — the core transfer

```lua
-- Handles: floor drops, picking up from floor, container-to-container, Radio special objects
ISTransferAction:transferItem(character, item, srcContainer, destContainer, dropSquare)
```

**Use this** instead of calling `srcContainer:Remove()` + `destContainer:AddItem()` directly. It handles all the edge cases.

---

## Weapon Actions

### ISReloadWeaponAction — Reload Firearm

**Source:** `ISReloadWeaponAction.lua`

**Pattern:** Animation-driven (`maxTime = -1`). Ammunition is consumed one bullet at a time inside `animEvent()`, not all at once. Demonstrates complex anim variable coordination.

#### Constructor

```lua
function ISReloadWeaponAction:new(character, gun)
    local o = ISBaseTimedAction.new(self, character)
    o.gun        = gun
    o.stopOnWalk = false
    o.stopOnAim  = false
    o.maxTime    = -1           -- animation controls timing
    o.useProgressBar = false    -- no progress bar; animation-driven
    return o
end
```

#### `isValid()` — gun must still be in primary hand

```lua
return self.character:getPrimaryHandItem() == self.gun
```

#### `start()` — animation variables

```lua
self:setAnimVariable("WeaponReloadType", tostring(self.gun:getWeaponReloadType()))
self:setAnimVariable("isLoading", true)
self:setActionAnim(CharacterActionAnims.Reload)
self.character:reportEvent("EventReloading")
```

#### `animEvent()` — bullet inserted per event

```lua
if event == 'loadFinished' then
    self:loadAmmo()   -- insert one bullet, check if full
    addXp(self.character, Perks.Reloading, xp)
end
if event == 'playReloadSound' then
    -- fires sound cues keyed by parameter: 'load', 'insertAmmoStart'
end
if event == 'changeWeaponSprite' then
    self:setOverrideHandModels(parameter, nil)  -- swap weapon sprite mid-animation
end
```

#### `stop()` / `perform()` — always clear anim variables

```lua
-- Both stop() and perform() must clear these or the animation state gets stuck
self.character:clearVariable("isLoading")
self.character:clearVariable("WeaponReloadType")
```

**Pattern:** Any `setAnimVariable()` call in `start()` needs a matching `clearVariable()` in BOTH `stop()` and `perform()`.

---

### ISRackFirearm — Rack / Unjam Firearm

**Source:** `ISRackFirearm.lua`

**Pattern:** Short animation-driven action. Demonstrates `forceStop()` inside `start()` when preconditions fail after the action has already begun.

#### `start()` — bail out if nothing to rack

```lua
if not ISReloadWeaponAction.canRack(self.gun) then
    self:forceComplete()  -- nothing to do; complete immediately
    return
end
self:setAnimVariable("isRacking", true)
self:setActionAnim(CharacterActionAnims.Reload)
```

**Pattern:** It is valid to call `forceComplete()` inside `start()`. Use this when the precondition that was true at queue time is no longer true when the action actually begins.

#### `animEvent()` — controls completion

```lua
if event == 'rackBullet'      then self:rackBullet() end    -- eject/chamber round
if event == 'rackingFinished' then self:forceComplete() end -- done
if event == 'unloadFinished'  then
    self:rackBullet()
    self:forceComplete()
end
```

---

## Long-Running / Background Actions

### ISReadABook — Read a Book

**Source:** `ISReadABook.lua`

**Pattern:** Long-duration action with per-frame progress tracking, XP multiplier buildup, and `isUsingTimeout = false` to prevent the action from ever timing out on its own.

#### Constructor

```lua
function ISReadABook:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.minutesPerPage = getSandboxOptions():getOptionByName("MinutesPerPage"):getValue() or 2.0
    o.caloriesModifier = 0.5   -- light reading burns fewer calories
    o.forceProgressBar = true
    o.maxTime = o:getDuration()
    return o
end
```

#### `isUsingTimeout()` — disable auto-timeout

```lua
function ISReadABook:isUsingTimeout()
    return false  -- action never completes from timer alone; must be manual or forceComplete
end
```

**Use case:** Actions that should run indefinitely until explicitly stopped (reading, resting, waiting). The action can still be interrupted by `stopOnWalk` etc.

#### `isValid()` — multiple conditions

```lua
if self.character:tooDarkToRead() then
    HaloTextHelper.addBadText(self.character, getText("ContextMenu_TooDark"))
    return false
end
return self.character:getInventory():contains(self.item)
   and (self.item:getNumberOfPages() <= 0 or
        self.item:getAlreadyReadPages() <= self.item:getNumberOfPages())
```

**Pattern:** `isValid()` can call `HaloTextHelper.addBadText()` or `addGoodText()` to show a floating text message explaining why the action stopped.

#### `getDuration()` — trait and worn-item modifiers

```lua
local time = numPages * self.minutesPerPage / f  -- sandbox option controls page speed
if self.character:hasTrait(CharacterTrait.FAST_READER) then time = time * 0.7 end
if self.character:hasTrait(CharacterTrait.SLOW_READER) then time = time * 1.3 end
-- Reading glasses = 10% faster
local eyeItem = self.character:getWornItems():getItem(ItemBodyLocation.EYES)
if eyeItem and eyeItem:getType() == "Glasses_Reading" then time = time * 0.9 end
-- Sitting = 10% faster
if self.character:isSitOnGround() or self.character:isSittingOnFurniture() then
    time = time * 0.9
end
```

**Pattern:** Check worn items in `getDuration()` using `character:getWornItems():getItem(ItemBodyLocation.X)` for slot-specific equipment bonuses.

#### `complete()` — grant XP multiplier and track progress

```lua
ISReadABook.checkMultiplier(self)        -- apply XP multiplier to perk
self.item:setAlreadyReadPages(self.item:getNumberOfPages())
sendSyncPlayerFields(self.character, 0x00000007)  -- sync perks + traits
syncItemFields(self.character, self.item)
```

---

## Patterns Cheat Sheet

| Need | Study | Key Method | Notes |
|------|-------|------------|-------|
| Consume food / item | `ISEatFoodAction` | `complete()` → `character:Eat()` | Item consumed in `complete()`, not `perform()` |
| Take a pill / medicine | `ISTakePillAction` | `complete()` → `getBodyDamage():JustTookPill()` | Simpler than eating; no percentage |
| Drink fluid with partial effect | `ISDrinkFromBottle` | `stop()` applies partial; `complete()` applies full | Partial effect on interrupt is opt-in |
| Apply bandage / treat wound | `ISApplyBandage` | `complete()` → `SetBandaged()` + `addXp()` | `waitToStart()` faces other player |
| Equip item to hand | `ISEquipWeaponAction` | `complete()` → `setPrimaryHandItem()` | `primary` and `twoHands` flags |
| Unequip item from hand | `ISUnequipAction` | `complete()` → `setPrimaryHandItem(nil)` | Always sync with `sendEquip()` |
| Wear clothing | `ISWearClothing` | `WearClothingAnimations` table | `setAnimVariable("WearClothingLocation", ...)` |
| Drop item to world | `ISDropWorldItemAction` | `complete()` → `sq:AddWorldInventoryItem()` | Remove from inventory AFTER placing |
| Transfer between containers | `ISTransferAction` | `transferItem()` utility | Not a timed action; call from `complete()` |
| Chop/mine repeating action | `ISChopTreeAction` | `animEvent("ChopTree")` per swing | `maxTime = -1`; `forceComplete()` when done |
| Reload firearm | `ISReloadWeaponAction` | `animEvent("loadFinished")` per bullet | Clear anim vars in BOTH `stop()` and `perform()` |
| Rack/unjam firearm | `ISRackFirearm` | `animEvent("rackingFinished")` | `forceComplete()` in `start()` if nothing to do |
| Long-running background action | `ISReadABook` | `isUsingTimeout() = false` | Never auto-completes; `forceStop()` to cancel |
| Face object before starting | `ISChopTreeAction` / `ISApplyBandage` | `waitToStart()` + `faceThisObject()` | Return `shouldBeTurning()` |
| Scale duration by traits | `ISDropWorldItemAction` | `getDuration()` | Check traits there, not in `new()` |
| Show "too dark" / feedback | `ISReadABook:isValid()` | `HaloTextHelper.addBadText()` | Call in `isValid()` before returning false |
| Drive inventory progress bar | Any | `update()` → `item:setJobDelta(getJobDelta())` | Required for item bar in UI to animate |
| Looping ambient sound | `ISEatFoodAction` | `update()` + `stop()` + `perform()` | Play in `start()`, replay in `update()` if ended, stop in both `stop()` and `perform()` |
| Show item in hand during action | Any | `start()` → `setOverrideHandModels(primary, secondary)` | Pass nil to hide a hand |
| Skill-reduced duration | `ISApplyBandage` | `getDuration()` → `120 - (level * 4)` | Standard pattern for skill scaling |
| Reload speed from perk + moodle | `ISReloadWeaponAction` | `setReloadSpeed()` helper | Pattern for perk + moodle combined modifier |
| Add action after current | Any | `ISTimedActionQueue.addAfter(self, nextAction)` | From `perform()`: chain next action |

---

## Key Player Methods Reference

Collected from the actions above:

```lua
-- Inventory
character:getInventory()                              -- ItemContainer
character:getInventory():contains(item)
character:getInventory():containsID(item:getID())     -- multiplayer-safe
character:getInventory():Remove(item)
character:getInventory():AddItem(item)
character:getInventory():getItemById(id)
character:getInventory():getFirstTypeEvalRecurse(fullType, predicateFn)
character:getInventory():getSomeType(itemKey, count)  -- returns ArrayList

-- Hands
character:getPrimaryHandItem()
character:getSecondaryHandItem()
character:setPrimaryHandItem(item)    -- pass nil to clear
character:setSecondaryHandItem(item)

-- Clothing / worn items
character:getWornItems():contains(item)
character:getWornItems():getItem(ItemBodyLocation.X)
character:setWornItem(bodyLocation, item)
character:removeWornItem(item)
character:isEquippedClothing(item)

-- Stats and moodles
character:getStats():get(CharacterStat.X)
character:getStats():remove(CharacterStat.X, amount)
character:getStats():set(CharacterStat.X, value)
character:getMoodles():getMoodleLevel(MoodleType.X)
character:getPerkLevel(Perks.X)

-- Body damage
character:getBodyDamage():getBodyPart(BodyPartType.FromIndex(i))
character:getBodyDamage():SetBandaged(partIndex, true, life, alcoholic, type)
character:getBodyDamage():JustTookPill(item)

-- XP
addXp(character, Perks.X, amount)
addXpMultiplier(character, perk, multiplier, minLevel, maxLevel)

-- Animation
self:setActionAnim(CharacterActionAnims.X)     -- or a string like "Loot"
self:setAnimVariable("Key", value)
self:clearVariable("Key")                       -- clear in stop() AND perform()
self:setOverrideHandModels(primaryItem, secondaryItem)
self:overrideWeaponType()
self:restoreWeaponType()

-- Sounds
character:getEmitter():playSound("SoundName")  -- returns sound handle
character:getEmitter():isPlaying(handle)
character:getEmitter():stopSound(handle)
character:stopOrTriggerSound(handle)           -- graceful stop with trigger
character:playSound("SoundName")               -- fire-and-forget (no handle)

-- Facing
character:faceThisObject(target)
character:shouldBeTurning()                    -- true while turning

-- Metabolics
character:setMetabolicTarget(Metabolics.X)

-- Halo text
HaloTextHelper.addBadText(character, getText("key"))
HaloTextHelper.addGoodText(character, getText("key"))

-- Multiplayer sync
sendEquip(character)
sendRemoveItemFromContainer(container, item)
sendAddItemToContainer(container, item)
syncItemFields(character, item)
syncBodyPart(bodyPart, flags)
```

---

## Common Pitfalls

### 1. Forgetting `ISBaseTimedAction.perform(self)` in `perform()`

**Symptom:** Action completes but the next action in queue never starts.
**Fix:** Always end `perform()` with `ISBaseTimedAction.perform(self)`.

### 2. Forgetting `ISBaseTimedAction.stop(self)` in `stop()`

**Symptom:** Interrupted action leaves the queue in a broken state; subsequent actions don't trigger.
**Fix:** Always end `stop()` with `ISBaseTimedAction.stop(self)`.

### 3. Putting the item effect in `perform()` instead of `complete()`

**Symptom:** Item consumed or stat changed even when action is interrupted.
**Fix:** Effects go in `complete()`. `perform()` is cleanup only.

### 4. Not clearing animation variables in `stop()`

**Symptom:** Character gets stuck in a wrong animation after interruption.
**Fix:** Any `setAnimVariable()` or `setActionAnim()` in `start()` needs `clearVariable()` in BOTH `stop()` and `perform()`.

### 5. Caching item reference in `new()` for multiplayer

**Symptom:** In multiplayer, the item reference is stale by the time `start()` runs.
**Fix:** In `start()`, re-resolve the item: `self.item = self.character:getInventory():getItemById(self.item:getID())`.

### 6. Using `character:HasTrait(string)` instead of `character:getTraits():contains(string)`

**Symptom:** Trait check always returns false or errors in B42.
**Fix:** Use `character:getTraits():contains("TraitId")`. `HasTrait` is legacy B41.

### 7. Setting `maxTime` without calling `getDuration()`

**Symptom:** Duration ignores sandbox options, trait modifiers, or item metadata.
**Fix:** Compute `maxTime` via a `getDuration()` method so it's centralised and testable.

### 8. `maxTime = -1` with no `forceComplete()` call

**Symptom:** Action runs forever; player is stuck.
**Fix:** For animation-driven actions, always call `forceComplete()` from `animEvent()` when the terminating event fires.
