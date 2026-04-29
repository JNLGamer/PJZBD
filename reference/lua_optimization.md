# Lua Optimization for PZ Mods

Source: PZwiki Mod Optimization — B42.10.0

## Rule 1: Don't Run It If You Don't Need To

Check whether work is necessary before doing it. Especially critical in per-zombie or per-tick events.

```lua
-- Bad: runs setSkeleton (expensive) every tick even after done
local function OnZombieUpdate(zombie)
    zombie:setSkeleton(true)
end

-- Good: skip if already done
local function OnZombieUpdate(zombie)
    if not zombie:isSkeleton() then
        zombie:setSkeleton(true)
    end
end
```

**Exception:** if the getter is also expensive, skipping the check can be faster. When in doubt, benchmark.

## Rule 2: Local Variables, Never Global

Global access is slower and pollutes the namespace.

```lua
-- Bad
myVariable = "Hello"
MyFunctions = {}

-- Good
local myVariable = "Hello"
local MyFunctions = {}
```

To use a global vanilla value, cache it locally at file scope:

```lua
local ProceduralDistributions = ProceduralDistributions
```

## Rule 3: Cache — Don't Retrieve Twice

Every Java method call from Lua has overhead. Cache results in locals.

```lua
-- Bad: calls getPrimaryHandItem() 6+ times
local function OnPlayerUpdate(player)
    if player:getPrimaryHandItem() and instanceof(player:getPrimaryHandItem(), "HandWeapon") then
        if player:getPrimaryHandItem():isRanged() then
            if player:getPrimaryHandItem():getCurrentAmmoCount() ~= player:getPrimaryHandItem():getMaxAmmo() then
                player:getPrimaryHandItem():setCurrentAmmoCount(player:getPrimaryHandItem():getMaxAmmo())
            end
        end
    end
end

-- Good: 6 Java calls total instead of 13
local function OnPlayerUpdate(player)
    local weapon = player:getPrimaryHandItem()
    if weapon and instanceof(weapon, "HandWeapon") and weapon:isRanged() then
        local maxAmmo = weapon:getMaxAmmo()
        if weapon:getCurrentAmmoCount() ~= maxAmmo then
            weapon:setCurrentAmmoCount(maxAmmo)
        end
    end
end
```

Cache at file scope when the object doesn't change between calls (e.g. the zombie list):

```lua
local zombieList

Events.OnPostMapLoad.Add(function(cell)
    zombieList = cell:getZombieList()
end)

Events.OnTick.Add(function()
    print(zombieList:size())
end)
```

## Rule 4: Minimize Function Calls

Function call overhead in Kahlua (PZ's Lua runtime) is significant. Inline math instead of using `math.*`:

```lua
-- math.max
local res = value > maxvalue and value or maxvalue
-- math.min
local res = value < minvalue and value or minvalue
-- math.min/max combo
local res = value > minvalue and (value < maxvalue and value or maxvalue) or minvalue
-- math.pow
local res = value ^ exponent
-- math.sqrt
local res = value ^ 0.5
-- math.floor
local res = value - value % 1
-- math.abs
local res = value < 0 and -value or value
```

## Rule 5: Remove All print() Calls Before Release

`print()` is extremely expensive. Even a single `print()` per in-game hour across many mods causes visible lag spikes. Debug mode does not reduce the cost. **Delete every print before uploading.**

## Rule 6: Use table.newarray() for Integer-Keyed Tables

Proper array tables (integer keys starting at 1) are faster to iterate than key tables:

```lua
-- slower iteration
local t = { "a", "b", "c" }

-- faster — use table.newarray()
local t = table.newarray("a", "b", "c")

-- or convert existing
t = table.newarray(t)

-- iterate properly (much faster than ipairs)
for i = 1, #t do
    local v = t[i]
end
```

**Warning:** proper arrays can't be saved in ModData or sent over the network.

## Rule 7: Replace pairs/ipairs with Index Loops

```lua
-- Slow
for i, v in ipairs(t) do print(v) end

-- Fast
for i = 1, #t do
    local v = t[i]
    print(v)
end
```

For key tables, use a parallel array of keys to avoid `pairs`:

```lua
local lookup = { key1 = "Hello", key2 = "World" }
local keys = table.newarray("key1", "key2")
for i = 1, #keys do
    local v = lookup[keys[i]]
end
```

## Rule 8: Load Balance Per-Tick Work

If you're running per-zombie logic, don't process all zombies every tick. Process N per tick:

```lua
local zombieList
local zeroTick = 0

Events.OnGameStart.Add(function()
    zombieList = getPlayer():getCell():getZombieList()
end)

Events.OnTick.Add(function(tick)
    local zombieIndex = tick - zeroTick
    if zombieList:size() > zombieIndex then
        local zombie = zombieList:get(zombieIndex)
        -- process this one zombie
    else
        zeroTick = tick + 1
    end
end)
```

## Rule 9: Use newrandom() Instead of ZombRand

`ZombRand` generates high-quality randomness that's overkill for most uses:

```lua
local myRandom = newrandom()
local value = myRandom:random(min, max)
```

## Benchmarking

```lua
GameTime.setServerTimeShift(0) -- required before using getServerTime
local getTime = GameTime.getServerTime

local totalTime, calls = 0, 0

function benchmark(fct, ...)
    local start = getTime()
    fct(...)
    totalTime = totalTime + (getTime() - start)
    calls = calls + 1
end

function printBenchmark()
    if calls ~= 0 then
        print("Average:", totalTime / calls)
        totalTime, calls = 0, 0
    end
end
```

## Texture / Model Size Guidelines (from The Indie Stone)

| Asset type | Max texture size |
|-----------|-----------------|
| Vehicles | 512×512 |
| Body / Clothing | 256×256 |
| Weapons | 128×128 (varies) |
| Hats | 128×128 |

Keep polycount at or below vanilla equivalents to avoid memory leaks.
