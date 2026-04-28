# Event System

Source: MrBounty/PZ-Mod---Doc

## Pattern

```lua
local function myHandler(param1, param2)
    -- your code
end

Events.EventName.Add(myHandler)
```

To remove a handler:
```lua
Events.EventName.Remove(myHandler)
```

## Common Events

### Startup

| Event | When | Parameters |
|-------|------|------------|
| `OnGameBoot` | Very first thing on launch | none |
| `OnGameStart` | Game world is loaded | none |
| `OnNewGame` | Brand new save is created | none |
| `OnInitGlobalModData` | ModData system ready | `isNewGame` (bool) |

### Player

| Event | When | Parameters |
|-------|------|------------|
| `OnKeyPressed` | Player presses a key | `key` (int key code) |
| `OnKeyKeepPressed` | Key held down each tick | `key` (int) |
| `OnPlayerDeath` | Player dies | `player` |
| `OnCharacterCollide` | Player collides with something | `player`, `entity` |
| `OnCreatePlayer` | Player object created | `playerIndex`, `player` |

### World / Time

| Event | When | Parameters |
|-------|------|------------|
| `EveryTenMinutes` | Every 10 in-game minutes | none |
| `EveryOneMinute` | Every 1 in-game minute | none |
| `EveryDays` | Every in-game day | none |
| `OnTick` | Every game tick | `tick` (number) |
| `OnTickEvenPaused` | Every tick, even when paused | `tick` |

### Items / Inventory

| Event | When | Parameters |
|-------|------|------------|
| `OnObjectAboutToBeRemoved` | Object being deleted | `object` |
| `OnContainerUpdate` | Inventory container changes | `container` |
| `OnWeaponHitCharacter` | Weapon hits a character | `attacker`, `target`, `weapon`, `damage` |
| `OnWeaponSwing` | Weapon swing starts | `character`, `weapon` |

### Zombies

| Event | When | Parameters |
|-------|------|------------|
| `OnZombiesDead` | Zombie(s) killed | `zombie` |

### Multiplayer

| Event | When | Parameters |
|-------|------|------------|
| `OnClientCommand` | Server receives command from client | `module`, `command`, `player`, `args` |
| `OnServerCommand` | Client receives command from server | `module`, `command`, `args` |

## Key Code Reference (OnKeyPressed)

```lua
-- Common key codes
-- Q = 16,  E = 18,  R = 19,  T = 20,  Y = 21
-- F = 33,  G = 34,  H = 35
-- Space = 57,  Enter = 28,  Escape = 1
-- Use Keyboard.isKeyDown(key) for polling instead of events
```

## Example: Fire code every 10 in-game minutes

```lua
local function onTenMinutes()
    local player = getPlayer()
    if player then
        -- do something to player periodically
    end
end

Events.EveryTenMinutes.Add(onTenMinutes)
```
