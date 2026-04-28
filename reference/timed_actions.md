# Timed Actions

Source: MrBounty/PZ-Mod---Doc

## What They Are

A timed action is an in-game action that takes time — it shows the progress bar, plays animations, and can be cancelled by the player walking away or taking damage.

Base class: `media/lua/shared/TimedActions/ISBaseTimedAction.lua`
Vanilla examples: `media/lua/client/TimedActions/`

## File Location

`media/lua/client/TimedActions/MyMod_MyAction.lua`

## Skeleton

```lua
MyMod_MyAction = ISBaseTimedAction:derive("MyMod_MyAction")

function MyMod_MyAction:new(character, targetItem)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.targetItem = targetItem
    o.maxTime = 100          -- ticks; ~3 seconds at default game speed
    o.stopOnWalk = true      -- cancel if player walks
    o.stopOnRun = true
    return o
end

function MyMod_MyAction:isValid()
    -- return false to cancel before starting
    return self.targetItem ~= nil
end

function MyMod_MyAction:start()
    -- play animation
    self:setActionAnim("Loot")
    -- self.character:playSound("someSound")
end

function MyMod_MyAction:update()
    -- called every tick while action runs
    -- good for facing checks: self.character:faceLocation(x, y)
end

function MyMod_MyAction:perform()
    -- called when maxTime is reached (success)
    local inv = self.character:getInventory()
    -- inv:AddItem("Base.Nails")
    -- inv:Remove(self.targetItem)

    ISBaseTimedAction.perform(self) -- always call super
end

function MyMod_MyAction:stop()
    -- called on cancellation
    ISBaseTimedAction.stop(self)   -- always call super
end
```

## Triggering an Action

```lua
-- Queue a single action
ISTimedActionQueue.add(MyMod_MyAction:new(getPlayer(), someItem))

-- Queue multiple sequential actions
ISTimedActionQueue.add(ISWalkToTimedAction:new(player, x, y, z))
ISTimedActionQueue.add(MyMod_MyAction:new(player, someItem))
```

## Useful Config Flags

| Flag | Default | Effect |
|------|---------|--------|
| `stopOnWalk` | false | Cancel when player moves |
| `stopOnRun` | false | Cancel when player runs |
| `forceProgressBar` | false | Show bar even without animation |
| `maxTime` | — | Duration in ticks (~30 ticks/sec) |

## Common Animations

```lua
self:setActionAnim("Loot")       -- crouching loot
self:setActionAnim("BuildLow")   -- building on ground
self:setActionAnim("Craft")      -- hands together craft
self:setActionAnim("Bandage")    -- medical
self:setActionAnim("Eat")        -- eating
```
