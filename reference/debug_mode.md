# Debug Mode

Source: [`wiki_dump/Debug mode - PZwiki.txt`](wiki_dump/Debug%20mode%20-%20PZwiki.txt) (PZwiki, last updated for 41.78.18 — most info still applies in 42).

## Enabling

Add `-debug` to PZ's launch options. Two ways:

**Steam:** right-click Project Zomboid in your Steam library → Properties → General → Launch Options → enter `-debug`. Save and launch.

**Shortcut:** create a shortcut to `ProjectZomboid64.exe`, edit its Target field to add `-debug` after the path.

In-game, when debug mode is active, a **gray bug icon** appears on the left of the HUD. Click it to open the debug menu (icon turns red while open).

## In-game Lua console

The Lua console is the primary tool for testing mods in real time. Two ways to access:

- **F11** — opens the Lua Debugger (default keybind, rebindable in options). The console is part of this UI.
- **Right-click in-world → Command Console** (debug mode only) — also called "Lua Console" in options.

From the console you can run any Lua expression. Common mod-debugging snippets:

```lua
-- inspect player ModData
print(getPlayer():getModData().YourModNamespace.someField)

-- list all detected mods (use to confirm yours is found)
for i, dir in ipairs(getModDirectoryTable()) do
    local info = getModInfo(dir)
    print(i, dir, info and info:getId(), info and info:isAvailable())
end

-- force-fire your event handler
YourModNamespace.someHandler(getPlayer())

-- reset ModData mid-session (useful when iterating)
getPlayer():getModData().YourModNamespace = nil
```

`print()` output goes to:
- The Lua console window itself
- `%UserProfile%/Zomboid/console.txt` (the same log file as game errors)

You can `tail -f` console.txt while playing to watch live output without alt-tabbing.

## Debug menu sections (most useful for mod development)

Click the bug icon → debug menu opens with these tabs:

| Section | What's there |
|---------|--------------|
| **General debuggers → Game** | GameSpeed slider (1x to 1000x), spawn helicopter event |
| **General debuggers → Player Stats and Body** | Sliders for hunger, thirst, fatigue, panic, stress, sanity, infection level. Toggles for God Mode, Ghost (zombies don't see you), Invisible, IsInfected, IsOnFire |
| **Cheats** | Build Cheat (instant build), Health Panel Cheat (full health debug), Mechanics Cheat, Unlimited Carry, Unlimited Ammo, Instant Actions |
| **Items List** | Spawn any item directly into player inventory by name |
| **Player's Stats** | Adjust traits and skills mid-game |
| **isoRegions** | Visualize buildings on map (performance hog — turn off when done) |
| **Zombie Population** | Map view of all zombies as colored squares |
| **GlobalModData** | Inspect/modify the global ModData store |

## Debug Scenarios

The main menu shows a "Debug Scenarios" list when in debug mode (double-click to start). These are pre-defined test scenarios — useful for testing a mod against a known game state.

Custom scenarios can be created by editing `ProjectZomboid/media/lua/client/DebugUIs/Scenarios/DebugScenario.lua` (read-only — copy to your mod and override).

## Debug log filtering

Two startup args control console verbosity:

```
-debuglog=Network,-Sound      # enable Network logs, disable Sound
-debuglog=All                  # everything
-disablelog=Network,Sound      # server-only equivalent
```

Filter values come from `zombie.debug.DebugType` (Java).

## Spawning NPCs for testing

In debug mode you can spawn non-zombie characters (used in our Phase 1 UAT test #4 for survivor-kill detection):

1. Open debug menu → Cheats → ensure cheats are enabled
2. Right-click the world tile where you want to spawn → debug submenu → spawn NPC variant
3. Or use the Lua console:
   ```lua
   -- spawn a survivor at player's position (B42 — verify exact API in current build)
   local p = getPlayer()
   local survivor = SurvivorFactory.CreateSurvivor()
   getCell():addLamppost(survivor)  -- placeholder; actual API call may differ
   ```

Verify the exact spawn API against the current B42 game source before relying on this — the wiki section is partially outdated.

## Resetting after a debug crash

If a debug option causes the client to freeze or crash on launch, edit:

```
%UserProfile%/Zomboid/debug-options.init
```

Set the offending option to `false` and relaunch.

## Cross-references

- [startup_parameters.md](startup_parameters.md) — full list of `-debug`, `-debuglog`, etc.
- [b42_mod_loading.md](b42_mod_loading.md) — using the Lua console to verify your mod is detected
- [wiki_dump/Debug mode - PZwiki.txt](wiki_dump/Debug%20mode%20-%20PZwiki.txt) — full wiki page
