# Lua (API) — Java/Lua Bridge in Project Zomboid

Source: PZwiki Lua (API) page, captured for B42 17.0.

PZ runs Lua via **Kahlua** (Java implementation of Lua 5.1). Lua scripts call into exposed Java classes; that bridge has overhead and dictates a lot of the API's quirks.

> Authority order for any PZ Lua question: this file → other `reference/*.md` → `ProjectZomboid/media/lua/` (vanilla call sites). **Do not use pzwiki.net at runtime — it returns 403.** Wiki content is captured here instead.

## Method calls: `:` vs `.`

| Kind | Syntax | Example |
|------|--------|---------|
| **Instance method** (needs an object) | `instance:methodName(args)` | `player:getMoveSpeed()` |
| **Static method** (class-level) | `ClassName.methodName(args)` | `IsoPlayer.getPlayers()` |
| **`LuaManager.GlobalObject` static** | bare global function | `getPlayer()`, `getCell()`, `getSpecificPlayer(n)` |

Only **public** Java methods are exposed to Lua. The JavaDocs at `projectzomboid.com/modding/` (linked from the wiki) only list exposed methods on exposed classes; the unofficial **LuaDocs** project mirrors this.

## Constructors

```lua
local instance = ClassName.new(args...)
```

`ClassName.new(...)` calls the class's `<init>` constructor. **Creating an `IsoZombie.new(getCell())` does not spawn a zombie in the world** — it just gives you an instance to pass to APIs that need one (e.g. `square:addCorpse(IsoDeadBody.new(zombie), false)`).

## Accessing fields

Fields are not directly exposed like methods. Three ways:

**1. Public static fields** — exposed as a global table named after the class:
```lua
local DEATH_MUSIC_NAME = IsoPlayer.DEATH_MUSIC_NAME
```

**2. Reflection (works for any field, including private)** — slower:
```lua
local function getJavaField(object, field)
    local offset = string.len(field)
    for i = 0, getNumClassFields(object) - 1 do
        local m = getClassField(object, i)
        if string.sub(tostring(m), -offset) == field then
            return getClassFieldVal(object, m)
        end
    end
    return nil
end
```

**3. Starlit Library** (3rd-party, cached, fast):
```lua
local fieldValue = object.field   -- direct dot access
```

**Caveat:** inherited fields cannot currently be read from a subclass instance.

## Hooking (monkey-patching) Java methods

You can intercept Java method calls **made from Lua** (not Java→Java internal calls):

```lua
local index = __classmetatables[ClassName.class].__index
local old_method = index.method
function index:method(...)
    old_method(self, ...)
    -- your code here
end
```

This is the canonical pattern for our `ISReadABook:complete` / `ISEatFoodAction:complete` patches in `6_SanityTraits_TimedDecay.lua`.

## Lua objects (ISBaseObject)

Pure-Lua classes derive from `ISBaseObject`:
```lua
MyClass = ISBaseObject:derive("MyClass")
function MyClass:new(...) ... end
```
Used extensively for UI (`ISPanel`, `ISButton`) and timed actions (`ISBaseTimedAction`). Globals by default. Use the **DOME** library if you need to access locally-scoped Lua objects in another file.

## Inheritance & nested classes

- Java classes form an inheritance chain. `IsoZombie` → `IsoGameCharacter` → `IsoMovingObject` → `IsoObject` → `GameEntity` → `Object`. A subclass instance inherits all public methods of its parents.
- **Nested classes** are written `ClassName.NestedClassName` (e.g. `PerkFactory.Perks`). Common pattern for enums.

## Class objects ≠ Lua tables

A Java class reference (e.g. `IsoPlayer`) is **not** a Lua table — it's a direct binding to the Java class. You can't `pairs()` it, can't add fields to it, can't treat it as a table. Use the documented methods only.

## Folder structure & load order

```
media/lua/
├── client/    -- client-only code (UI, per-player state)
├── server/    -- server-only (only loaded after a save loads)
└── shared/    -- both client and server
```

| Folder | Singleplayer | MP client | MP server |
|--------|:---:|:---:|:---:|
| `client/` | ✓ | ✓ | ✗ |
| `server/` | ✓ | ✓ | ✓ |
| `shared/` | ✓ | ✓ | ✓ |

**Load order** (every reload):
1. Shared — vanilla
2. Shared — mod
3. Client — vanilla
4. Client — mod
5. Server — vanilla *(only on save load)*
6. Server — mod *(only on save load)*

A mod's lua file with the same relative path as a vanilla file **overwrites** it. Avoid clashes by namespacing under a mod-named subfolder, e.g. `media/lua/client/MyMod/foo.lua`.

Within a single mod's `client/` folder, files load in **alphabetical order** — that's why our Sanity_traits files use `1_…lua` through `8_…lua` to control load sequence.

## Translation files

Translation `.txt` lives under `media/lua/shared/Translate/<LANG>/` but is **not** Lua — it's parsed differently. See `reference/translations` if it exists.

## luautils — Built-in Utility Functions

`luautils` is a global Lua table of helper functions provided by the game.

```lua
-- Movement
luautils.walkToContainer(container, playerNum)
luautils.walkAdj(character, square, keepActions)
luautils.walkAdjWindowOrDoor(char, square, obj, bool)

-- Math
luautils.round(value)              -- round to integer
luautils.round(value, decimals)    -- round to N decimals

-- Strings
luautils.split(str, separator)     -- returns Lua table of parts
luautils.trim(str)                 -- strip leading/trailing whitespace
luautils.stringStarts(str, prefix) -- prefix check, returns bool

-- Tables / misc
luautils.tableContains(t, value)   -- linear search
luautils.getConditionRGB(value)    -- returns ColorInfo for a condition bar value (0–1)
```

## SandboxVars — Reading Custom Sandbox Options

```lua
-- Safe read with fallback (nil for unset keys)
local val = SandboxVars.MyMod and SandboxVars.MyMod.MyKey or defaultValue
```

Custom options are defined in `media/scripts/sandbox_options.txt` and are available after `OnGameStart`.

## Common Java→Lua gotchas

1. **Java collections** (`ArrayList`, etc.) iterate by `:size()` and `:get(i)` (zero-indexed), **not** Lua's `#` and `[i]`.
2. Java methods that return a collection sometimes return `null` if empty — always nil-check before `:size()`.
3. **B41 → B42 trait API changed.**
   - `player:HasTrait("id")` — **broken in B42**, returns nil.
   - Custom traits (string IDs): use `player:getTraits():contains("id")` to check, `:add("id")` / `:remove("id")` to mutate.
   - Built-in traits (enum constants): use `player:getCharacterTraits():add(CharacterTrait.WEAK)` etc.
   - Iterating all traits: `player:getCharacterTraits():getKnownTraits()` returns an ArrayList (0-indexed).
4. `print()` from Lua is expensive in Kahlua — see [lua_optimization.md](lua_optimization.md) Rule 5.
5. Hooking a Java method only intercepts calls that originate **from Lua**. Java→Java internal calls bypass your hook.

## Workflow when implementing a new feature

1. Identify the **event** that fires when you need to react (`reference/events_catalog.md`).
2. Identify the **method(s)** you need on the player/world/item — check [`reference/player_api.md`](player_api.md) first, then grep `ProjectZomboid/media/lua/` for usage.
3. If the method isn't in `reference/`, **find at least one vanilla call site** in `ProjectZomboid/media/lua/` before writing it. Confirm receiver type, argument types, return type.
4. Write the code. Cache repeated Java method results in locals (lua_optimization.md Rule 3).
5. Test in-game with `-debug` flag enabled (see `reference/debug_mode.md`).

## See also (in this reference folder)

- [lua_optimization.md](lua_optimization.md) — perf rules
- [events_catalog.md](events_catalog.md) — full event listing
- [player_api.md](player_api.md) — IsoPlayer methods
- [ui_elements.md](ui_elements.md) — IS* widget API
- [timed_actions_examples.md](timed_actions_examples.md) — ISBaseTimedAction patterns
- [mod_structure.md](mod_structure.md) — file layout & mod.info
