# PZ Events Catalog

> Build 42 — Scanned from `ProjectZomboid/media/lua/` (1,350 files)
> Confidence: HIGH = used in 5+ places, MED = 2-4 places, LOW = 1 place

## How to use events

```lua
-- Add a handler
local function myHandler(param1, param2)
    -- your code
end
Events.EventName.Add(myHandler)

-- Remove a handler (important — always store a reference to the same function)
Events.EventName.Remove(myHandler)
```

Named-function pattern (preferred for cleanup):

```lua
MyMod = {}

function MyMod.onPlayerDeath(playerObj)
    -- do stuff
end

Events.OnPlayerDeath.Add(MyMod.onPlayerDeath)

-- Cleanup:
Events.OnPlayerDeath.Remove(MyMod.onPlayerDeath)
```

---

## Quick-Reference Table

| Event | Category | Parameters | Confidence | Side |
|-------|----------|------------|------------|------|
| `OnGameBoot` | Lifecycle | none | HIGH | shared |
| `OnGameStart` | Lifecycle | none | HIGH | shared |
| `OnNewGame` | Lifecycle | none | HIGH | shared |
| `OnLoad` | Lifecycle | none | MED | server |
| `OnInitWorld` | Lifecycle | none | MED | client |
| `OnGameTimeLoaded` | Lifecycle | none | MED | shared |
| `OnInitGlobalModData` | Lifecycle | `isNewGame: bool` | MED | shared |
| `OnServerStarted` | Lifecycle | none | MED | server/shared |
| `OnMainMenuEnter` | Lifecycle | none | LOW | client |
| `OnResetLua` | Lifecycle | `reason: string` | MED | client |
| `OnGameStateEnter` | Lifecycle | (unknown) | LOW | client |
| `OnPostSave` | Lifecycle | none | MED | client |
| `OnPreDistributionMerge` | Lifecycle | none | LOW | server |
| `OnDistributionMerge` | Lifecycle | none | LOW | server |
| `OnPostDistributionMerge` | Lifecycle | none | MED | server |
| `OnLoadMapZones` | Map | none | MED | shared |
| `OnLoadedMapZones` | Map | none | MED | shared |
| `OnLoadSoundBanks` | Lifecycle | none | LOW | shared |
| `OnInitRecordedMedia` | Lifecycle | none | LOW | shared |
| `OnTemplateTextInit` | Lifecycle | none | LOW | server |
| `OnLoadRadioScripts` | Lifecycle | none | MED | server |
| `OnClimateManagerInit` | Lifecycle | none | LOW | server |
| `OnSGlobalObjectSystemInit` | Lifecycle | none | LOW | server |
| `OnCGlobalObjectSystemInit` | Lifecycle | none | LOW | client |
| `OnPlayerDeath` | Player | `playerObj: IsoPlayer` | HIGH | shared |
| `OnCreatePlayer` | Player | `playerIndex: int` | HIGH | shared |
| `OnPlayerUpdate` | Player | `player: IsoPlayer` | MED | client |
| `OnPlayerMove` | Player | `player: IsoPlayer` | MED | server |
| `OnPlayerAttackFinished` | Player | `playerObj: IsoPlayer, weapon: HandWeapon` | MED | shared |
| `LevelPerk` | Player | `owner: IsoPlayer, perk: PerkFactory.Perk, level: int, addBuffer: bool` | MED | shared |
| `AddXP` | Player | `owner: IsoPlayer, type: PerkFactory.Perk, amount: float` | MED | server |
| `OnClothingUpdated` | Player | `chr: IsoCharacter` | MED | client |
| `OnSleepingTick` | Player | `playerIndex: int, hourOfDay: float` | LOW | client |
| `OnCreateSurvivor` | Player | `survivor: IsoSurvivor` | LOW | shared |
| `OnCharacterCollide` | Player | `player: IsoPlayer, entity` | LOW | shared |
| `OnZombieDead` | Zombies | `zombie: IsoZombie` | HIGH | client |
| `OnHitZombie` | Zombies | `zombie: IsoZombie, wielder: IsoGameCharacter, bodyPart: BodyPartType, weapon: HandWeapon` | MED | shared |
| `OnWeaponHitXp` | Combat | `owner: IsoGameCharacter, weapon: HandWeapon, hitObject, damage: float, hitCount: int` | MED | server |
| `OnWeaponSwingHitPoint` | Combat | `player: IsoPlayer, weapon: HandWeapon` | LOW | shared |
| `OnWeaponHitTree` | Combat | `owner: IsoGameCharacter, weapon: HandWeapon` | LOW | server |
| `OnWeaponHitCharacter` | Combat | `attacker: IsoGameCharacter, target: IsoGameCharacter, weapon: HandWeapon, damage: float` | LOW | shared |
| `OnPressReloadButton` | Combat | (unknown) | LOW | shared |
| `OnPressRackButton` | Combat | (unknown) | LOW | shared |
| `OnTick` | Time | none | HIGH | client |
| `OnRenderTick` | Time | `ticks: int` | MED | client |
| `EveryTenMinutes` | Time | none | HIGH | shared |
| `EveryHours` | Time | none | HIGH | shared |
| `EveryDays` | Time | none | HIGH | shared |
| `EveryOneMinute` | Time | none | MED | shared |
| `OnEquipPrimary` | Items | `player: IsoPlayer, inventoryItem: InventoryItem` | MED | client |
| `OnEquipSecondary` | Items | `player: IsoPlayer, inventoryItem: InventoryItem` | LOW | client |
| `OnContainerUpdate` | Items | `object: IsoObject` | MED | client |
| `OnItemFound` | Items | `character: IsoGameCharacter, itemType: string, distanceTravelled: float` | MED | shared |
| `OnObjectAdded` | World | `isoObject: IsoObject` | LOW | server |
| `OnObjectAboutToBeRemoved` | World | `isoObject: IsoObject` | LOW | server |
| `OnDestroyIsoThumpable` | World | `isoObject: IsoObject, playerObj: IsoPlayer` | MED | server |
| `OnWaterAmountChange` | World | `object: IsoObject, prevAmount: float` | LOW | server |
| `OnDynamicMovableRecipe` | World | `sprite, recipe, item: InventoryItem, player: IsoPlayer` | LOW | shared |
| `OnDoTileBuilding2` | World | (unknown) | LOW | server |
| `OnDoTileBuilding3` | World | (unknown) | LOW | server |
| `OnDeadBodySpawn` | World | (unknown) | LOW | client |
| `OnPressWalkTo` | World | (unknown) | LOW | client |
| `OnObjectLeftMouseButtonUp` | World | (unknown) | LOW | server |
| `OnObjectLeftMouseButtonDown` | World | (unknown) | LOW | server |
| `OnObjectRightMouseButtonUp` | World | (unknown) | LOW | server |
| `OnObjectRightMouseButtonDown` | World | (unknown) | LOW | server |
| `LoadGridsquare` | World | (unknown) | LOW | client |
| `OnWeatherPeriodStart` | Climate | none | LOW | shared |
| `OnWeatherPeriodStage` | Climate | none | LOW | shared |
| `OnWeatherPeriodComplete` | Climate | none | LOW | shared |
| `OnClimateTickDebug` | Climate | `mgr: ClimateManager` | MED | client |
| `OnThunderEvent` | Climate | `x: int, y: int, strike: bool, light: bool, rumble: bool` | LOW | client |
| `OnInitSeasons` | Climate | none | LOW | client |
| `OnKeyPressed` | UI/Input | `key: int` | HIGH | client |
| `OnKeyStartPressed` | UI/Input | `key: int` | HIGH | client |
| `OnKeyKeepPressed` | UI/Input | `key: int` | HIGH | client |
| `OnMouseDown` | UI/Input | (unknown) | MED | client |
| `OnRightMouseDown` | UI/Input | (unknown) | LOW | server |
| `OnPreUIDraw` | UI | none | MED | client |
| `OnPostUIDraw` | UI | none | MED | client |
| `RenderOpaqueObjectsInWorld` | UI | none | MED | server |
| `OnResolutionChange` | UI | none | HIGH | client |
| `DoSpecialTooltip` | UI | (unknown) | MED | client |
| `OnContextKey` | UI | (unknown) | MED | client |
| `OnFillWorldObjectContextMenu` | UI | `player: int, context: ISContextMenu, worldobjects: table, test: bool` | HIGH | client |
| `OnFillInventoryObjectContextMenu` | UI | `playerNum: int, context: ISContextMenu, items: table, test: bool` | MED | client |
| `OnChatWindowInit` | UI | none | LOW | client |
| `OnAddMessage` | UI | (message object) | LOW | client |
| `OnTabAdded` | UI | (unknown) | LOW | client |
| `OnTabRemoved` | UI | (unknown) | LOW | client |
| `OnSetDefaultTab` | UI | (unknown) | LOW | client |
| `OnAlertMessage` | UI | (unknown) | LOW | client |
| `OnAdminMessage` | UI | (unknown) | LOW | client |
| `SetDragItem` | UI | (unknown) | LOW | client |
| `OnGamepadConnect` | Input | (gamepad info) | MED | shared |
| `OnGamepadDisconnect` | Input | (gamepad info) | MED | shared |
| `OnJoypadActivate` | Input | `joypadIndex: int` | MED | shared |
| `OnJoypadActivateUI` | Input | (unknown) | LOW | shared |
| `OnJoypadBeforeDeactivate` | Input | (unknown) | MED | shared |
| `OnJoypadDeactivate` | Input | (unknown) | LOW | shared |
| `OnJoypadBeforeReactivate` | Input | (unknown) | LOW | shared |
| `OnJoypadReactivate` | Input | (unknown) | LOW | shared |
| `OnJoypadRenderUI` | Input | (unknown) | LOW | shared |
| `OnCoopJoinFailed` | Multiplayer | (unknown) | LOW | shared |
| `OnClientCommand` | Multiplayer | `module: string, command: string, player: IsoPlayer, args: table` | HIGH | server |
| `OnServerCommand` | Multiplayer | `module: string, command: string, args: table` | MED | client |
| `OnConnected` | Multiplayer | none | MED | client |
| `OnConnectFailed` | Multiplayer | none | MED | client |
| `OnDisconnect` | Multiplayer | none | MED | client |
| `OnConnectionStateChanged` | Multiplayer | (unknown) | MED | client |
| `OnScoreboardUpdate` | Multiplayer | (unknown) | HIGH | client |
| `OnMiniScoreboardUpdate` | Multiplayer | (unknown) | HIGH | client |
| `OnRolesReceived` | Multiplayer | (unknown) | MED | client |
| `OnNetworkUsersReceived` | Multiplayer | (unknown) | LOW | client |
| `OnReceiveUserlog` | Multiplayer | (log data) | MED | client |
| `OnSafehousesChanged` | Multiplayer | none | HIGH | client |
| `ReceiveSafehouseInvite` | Multiplayer | (unknown) | LOW | client |
| `AcceptedSafehouseInvite` | Multiplayer | (unknown) | LOW | client |
| `OnWarUpdate` | Multiplayer | (unknown) | LOW | client |
| `SyncFaction` | Multiplayer | (unknown) | LOW | client |
| `ReceiveFactionInvite` | Multiplayer | (unknown) | LOW | client |
| `AcceptedFactionInvite` | Multiplayer | (unknown) | LOW | client |
| `RequestTrade` | Multiplayer | (unknown) | LOW | client |
| `AcceptedTrade` | Multiplayer | (unknown) | LOW | client |
| `TradingUIAddItem` | Multiplayer | (unknown) | LOW | client |
| `TradingUIRemoveItem` | Multiplayer | (unknown) | LOW | client |
| `TradingUIUpdateState` | Multiplayer | (unknown) | LOW | client |
| `ViewTickets` | Multiplayer | (unknown) | LOW | client |
| `ViewBannedIPs` | Multiplayer | (unknown) | LOW | client |
| `ViewBannedSteamIDs` | Multiplayer | (unknown) | LOW | client |
| `RefreshCheats` | Multiplayer | none | LOW | client |
| `ServerPinged` | Multiplayer | (unknown) | LOW | client |
| `OnCoopServerMessage` | Multiplayer | (unknown) | LOW | client |
| `OnQRReceived` | Multiplayer | (unknown) | LOW | client |
| `OnGoogleAuthRequest` | Multiplayer | (unknown) | LOW | client |
| `OnAcceptInvite` | Multiplayer | none | LOW | client |
| `OnSteamGameJoin` | Multiplayer | none | LOW | client |
| `MngInvReceiveItems` | Multiplayer | (unknown) | LOW | client |
| `OnServerWorkshopItems` | Multiplayer | (unknown) | LOW | client |
| `OnServerStartSaving` | Multiplayer | none | LOW | client |
| `OnServerFinishSaving` | Multiplayer | none | LOW | client |
| `OnSteamFriendStatusChanged` | Steam | (unknown) | LOW | client |
| `OnSteamWorkshopItemCreated` | Steam | (unknown) | LOW | client |
| `OnSteamWorkshopItemNotCreated` | Steam | (unknown) | LOW | client |
| `OnSteamWorkshopItemUpdated` | Steam | (unknown) | LOW | client |
| `OnSteamWorkshopItemNotUpdated` | Steam | (unknown) | LOW | client |
| `OnSteamServerResponded` | Steam | (unknown) | LOW | client |
| `OnSteamServerResponded2` | Steam | (unknown) | LOW | client |
| `OnSteamServerFailedToRespond2` | Steam | (unknown) | LOW | client |
| `OnSteamRulesRefreshComplete` | Steam | (unknown) | LOW | client |
| `OnSteamRefreshInternetServers` | Steam | (unknown) | LOW | client |
| `OnEnterVehicle` | Vehicles | `character: IsoGameCharacter` | MED | client |
| `OnExitVehicle` | Vehicles | `character: IsoGameCharacter` | MED | client |
| `OnSwitchVehicleSeat` | Vehicles | `character: IsoGameCharacter` | MED | client |
| `OnUseVehicle` | Vehicles | `character: IsoGameCharacter, vehicle: BaseVehicle` | LOW | server |
| `OnVehicleHorn` | Vehicles | `character: IsoGameCharacter, vehicle: BaseVehicle, pressed: bool` | LOW | server |
| `OnVehicleDamageTexture` | Vehicles | (unknown) | LOW | client |
| `OnSpawnVehicleStart` | Vehicles | `vehicle: BaseVehicle` | LOW | server |
| `OnMechanicActionDone` | Vehicles | (unknown) | LOW | client |
| `OnFishingActionMPUpdate` | Fishing | (unknown) | MED | shared |
| `OnAnimalTracks` | Animals | (unknown) | LOW | client |
| `OnClickedAnimalForContext` | Animals | (unknown) | LOW | client |
| `OnProcessAction` | Actions | `action: string, character: IsoGameCharacter, args: table` | LOW | shared |
| `OnProcessTransaction` | Actions | (unknown) | LOW | server |
| `OnChallengeQuery` | Game Mode | (unknown) | MED | client |
| `OnModsModified` | Mods | none | MED | client |
| `OnDesignationZoneUpdatedNetwork` | World | (unknown) | LOW | client |
| `onEnableSearchMode` | Foraging | none | LOW | client |
| `onDisableSearchMode` | Foraging | none | LOW | client |
| `onToggleSearchMode` | Foraging | none | LOW | client |
| `onUpdateIcon` | Foraging | (unknown) | LOW | client |
| `OnOverrideSearchManager` | Foraging | (unknown) | LOW | client |
| `SwitchChatStream` | Chat | (unknown) | LOW | client |
| `OnDeviceText` | Radio | (unknown) | LOW | shared |

---

## Game Lifecycle

### Events.OnGameBoot
**Parameters:** none
**When it fires:** Very first Lua execution on launch, before any world exists. UI doesn't exist yet. Fires even on the main menu.
**Confidence:** HIGH
**Side:** shared

```lua
Events.OnGameBoot.Add(function()
    -- safe: initialize tables, load definitions, register bindings
    MyMod.init()
end)
```

**Cleanup:** `Events.OnGameBoot.Remove(myHandler)`

---

### Events.OnGameStart
**Parameters:** none
**When it fires:** The game world has finished loading and the player is in-world. Fires for both new and loaded saves. The most common hook for mod initialization.
**Confidence:** HIGH
**Side:** shared (fires on client in singleplayer; server has `OnServerStarted`)

```lua
Events.OnGameStart.Add(function()
    local player = getPlayer()
    -- player object is available here
    MyMod.setupPlayer(player)
end)
```

**Cleanup:** `Events.OnGameStart.Remove(myHandler)`

---

### Events.OnNewGame
**Parameters:** none
**When it fires:** Brand-new save only (not when loading an existing one). Use this to set up initial mod state that should only happen once.
**Confidence:** HIGH
**Side:** shared

```lua
Events.OnNewGame.Add(function()
    -- first-time setup only
    local player = getPlayer()
    player:getModData().MyMod_firstRun = true
end)
```

---

### Events.OnLoad
**Parameters:** none
**When it fires:** An existing save is loaded (not new game). Server-side. Use together with `OnNewGame` to handle both cases.
**Confidence:** MED
**Side:** server

```lua
Events.OnLoad.Add(function()
    -- restore state from moddata
end)
```

---

### Events.OnInitGlobalModData
**Parameters:** `isNewGame: bool`
**When it fires:** Global ModData system is initialized. `isNewGame` is `true` on first run.
**Confidence:** MED
**Side:** shared

```lua
Events.OnInitGlobalModData.Add(function(isNewGame)
    local data = ModData.getOrCreate("MyMod")
    if isNewGame then
        data.killCount = 0
    end
end)
```

---

### Events.OnServerStarted
**Parameters:** none
**When it fires:** Server has started (MP or listen-server). Equivalent to `OnGameStart` on the server side.
**Confidence:** MED
**Side:** server/shared

---

### Events.OnInitWorld
**Parameters:** none
**When it fires:** World is initializing, before the player object exists. Used by character creation screens.
**Confidence:** MED
**Side:** client

---

### Events.OnGameTimeLoaded
**Parameters:** none
**When it fires:** Game clock and time data are loaded. Fires on MP client after connecting.
**Confidence:** MED
**Side:** shared

---

### Events.OnResetLua
**Parameters:** `reason: string`
**When it fires:** Lua VM is being reset (e.g. main menu return, server disconnect). Clean up resources here.
**Confidence:** MED
**Side:** client

```lua
Events.OnResetLua.Add(function(reason)
    MyMod.cleanup()
end)
```

---

### Events.OnPostSave
**Parameters:** none
**When it fires:** After a save completes. Safe to do cleanup/notifications.
**Confidence:** MED
**Side:** client

---

### Events.OnPostDistributionMerge
**Parameters:** none
**When it fires:** After loot distribution tables have been merged from all mods. Add custom loot here.
**Confidence:** MED
**Side:** server

---

### Events.OnPreDistributionMerge / OnDistributionMerge
**Parameters:** none
**When it fires:** Before/during loot table merging. For modifying distribution before/during the merge pass.
**Confidence:** LOW
**Side:** server

---

## Player

### Events.OnCreatePlayer
**Parameters:** `playerIndex: int`
**When it fires:** A player object is created (new character or after death respawn). Use `getSpecificPlayer(playerIndex)` to get the IsoPlayer.
**Confidence:** HIGH
**Side:** shared

```lua
Events.OnCreatePlayer.Add(function(playerIndex)
    local player = getSpecificPlayer(playerIndex)
    if not player then return end
    -- initialize per-player data
    local md = player:getModData()
    if not md.MyMod_sanity then
        md.MyMod_sanity = 100
    end
end)
```

**Cleanup:** `Events.OnCreatePlayer.Remove(myHandler)`

---

### Events.OnPlayerDeath
**Parameters:** `playerObj: IsoPlayer`
**When it fires:** Player dies (health reaches zero). Called before the death animation.
**Confidence:** HIGH
**Side:** shared

```lua
Events.OnPlayerDeath.Add(function(playerObj)
    local num = playerObj:getPlayerNum()
    -- save or reset data, close UIs, etc.
end)
```

---

### Events.OnPlayerUpdate
**Parameters:** `player: IsoPlayer`
**When it fires:** Every update tick for this player. Expensive — keep handlers lightweight.
**Confidence:** MED
**Side:** client

```lua
Events.OnPlayerUpdate.Add(function(player)
    if not player:isLocalPlayer() then return end
    -- check state each frame
end)
```

---

### Events.OnPlayerMove
**Parameters:** `player: IsoPlayer`
**When it fires:** Player position changes. Server-side.
**Confidence:** MED
**Side:** server

---

### Events.LevelPerk
**Parameters:** `owner: IsoPlayer, perk: PerkFactory.Perk, level: int, addBuffer: bool`
**When it fires:** A skill/perk levels up. `perk` is a perk constant (e.g. `Perks.Strength`).
**Confidence:** MED
**Side:** shared

```lua
Events.LevelPerk.Add(function(owner, perk, level, addBuffer)
    if perk == Perks.Axe and level >= 5 then
        -- player reached axe level 5
    end
end)
```

---

### Events.AddXP
**Parameters:** `owner: IsoPlayer, type: PerkFactory.Perk, amount: float`
**When it fires:** XP is added to a skill. Fires before the XP is applied — cannot cancel but can observe.
**Confidence:** MED
**Side:** server

---

### Events.OnPlayerAttackFinished
**Parameters:** `playerObj: IsoPlayer, weapon: HandWeapon`
**When it fires:** Attack animation completes (melee or ranged). Weapon may be nil if unarmed.
**Confidence:** MED
**Side:** shared

---

### Events.OnClothingUpdated
**Parameters:** `chr: IsoCharacter`
**When it fires:** Player's clothing or equipped items changed (equip/unequip/condition change).
**Confidence:** MED
**Side:** client

---

### Events.OnSleepingTick
**Parameters:** `playerIndex: int, hourOfDay: float`
**When it fires:** Each tick while a player is sleeping. `hourOfDay` is the current in-game hour (0-24).
**Confidence:** LOW
**Side:** client

---

### Events.OnCreateSurvivor
**Parameters:** `survivor: IsoSurvivor`
**When it fires:** An NPC survivor is created (not zombies).
**Confidence:** LOW
**Side:** shared

---

## Zombies

### Events.OnZombieDead
**Parameters:** `zombie: IsoZombie`
**When it fires:** A zombie dies. Note: in the Challenge2 LastStand mode this is called with no parameters. The Tutorial's `FightStep:OnMomDead(zed)` shows the parameter IS the zombie. Use defensively: check if the parameter is nil.
**Confidence:** HIGH
**Side:** client

```lua
Events.OnZombieDead.Add(function(zombie)
    if not zombie then return end
    -- zombie:getX(), zombie:getY(), zombie:getZ() for position
    local md = getPlayer():getModData()
    md.MyMod_killCount = (md.MyMod_killCount or 0) + 1
end)
```

**Cleanup:** `Events.OnZombieDead.Remove(myHandler)`

---

### Events.OnHitZombie
**Parameters:** `zombie: IsoZombie, wielder: IsoGameCharacter, bodyPart: BodyPartType, weapon: HandWeapon`
**When it fires:** A weapon successfully hits a zombie (before death). All parameters can potentially be nil — guard accordingly.
**Confidence:** MED
**Side:** shared

```lua
Events.OnHitZombie.Add(function(zombie, wielder, bodyPart, weapon)
    if not zombie or not weapon then return end
    -- wielder may be a player or NPC
end)
```

---

## Combat

### Events.OnWeaponHitXp
**Parameters:** `owner: IsoGameCharacter, weapon: HandWeapon, hitObject, damage: float, hitCount: int`
**When it fires:** Weapon hits any target (zombie, survivor, player, tree, etc.) and XP may be awarded. `hitObject` type varies.
**Confidence:** MED
**Side:** server

```lua
Events.OnWeaponHitXp.Add(function(owner, weapon, hitObject, damage, hitCount)
    if not weapon then return end
    -- hitCount is cumulative hits in this swing
end)
```

---

### Events.OnWeaponHitTree
**Parameters:** `owner: IsoGameCharacter, weapon: HandWeapon`
**When it fires:** Weapon (e.g. axe) hits a tree. Used for lumber XP.
**Confidence:** LOW
**Side:** server

---

### Events.OnWeaponSwingHitPoint
**Parameters:** `player: IsoPlayer, weapon: HandWeapon`
**When it fires:** A ranged weapon fires (hit point registered). Used for ammo tracking.
**Confidence:** LOW
**Side:** shared

---

### Events.OnWeaponHitCharacter
**Parameters:** `attacker: IsoGameCharacter, target: IsoGameCharacter, weapon: HandWeapon, damage: float`
**When it fires:** Weapon hits any living character (player or NPC). Useful for NPC kill detection: check `target:isDead()` after the hit.
**Confidence:** LOW
**Side:** shared

```lua
Events.OnWeaponHitCharacter.Add(function(attacker, target, weapon, damage)
    if target and target:isDead() then
        -- target was just killed
    end
end)
```

---

### Events.OnPlayerAttackFinished
*(also listed under Player — same event)*

---

## Time

### Events.OnTick
**Parameters:** none
**When it fires:** Every game engine tick (real time, not game time). Very high frequency — runs even when paused. Keep handlers fast.
**Confidence:** HIGH
**Side:** client

```lua
Events.OnTick.Add(function()
    -- runs ~30-60x per second real time
end)
```

---

### Events.OnRenderTick
**Parameters:** `ticks: int`
**When it fires:** Every render frame. Similar to OnTick but tied to render pipeline.
**Confidence:** MED
**Side:** client

---

### Events.EveryTenMinutes
**Parameters:** none
**When it fires:** Every 10 in-game minutes. The standard polling interval for mod effects, mood checks, world updates.
**Confidence:** HIGH
**Side:** shared

```lua
Events.EveryTenMinutes.Add(function()
    local player = getPlayer()
    if not player or player:isDead() then return end
    -- check moodles, apply periodic effects, etc.
    local moodles = player:getMoodles()
end)
```

**Cleanup:** `Events.EveryTenMinutes.Remove(myHandler)`

---

### Events.EveryHours
**Parameters:** none
**When it fires:** Every in-game hour. Good for less-frequent periodic updates (farming, traps, radio).
**Confidence:** HIGH
**Side:** shared

---

### Events.EveryDays
**Parameters:** none
**When it fires:** Every in-game day (midnight rollover). Use for daily resets, loot respawn.
**Confidence:** HIGH
**Side:** shared

---

### Events.EveryOneMinute
**Parameters:** none
**When it fires:** Every in-game minute. More frequent than EveryTenMinutes — use sparingly.
**Confidence:** MED
**Side:** shared

---

## Items / Inventory

### Events.OnEquipPrimary
**Parameters:** `player: IsoPlayer, inventoryItem: InventoryItem`
**When it fires:** Player equips an item in the primary hand. `inventoryItem` may be nil if unequipping.
**Confidence:** MED
**Side:** client

```lua
Events.OnEquipPrimary.Add(function(player, inventoryItem)
    if not inventoryItem then return end
    local itemType = inventoryItem:getType()
end)
```

---

### Events.OnEquipSecondary
**Parameters:** `player: IsoPlayer, inventoryItem: InventoryItem`
**When it fires:** Player equips an item in the secondary (off) hand.
**Confidence:** LOW
**Side:** client

---

### Events.OnContainerUpdate
**Parameters:** `object: IsoObject`
**When it fires:** An IsoObject with a container (inventory) is added/removed from the world (e.g., campfire placed/removed). Not for item-level changes.
**Confidence:** MED
**Side:** client

---

### Events.OnItemFound
**Parameters:** `character: IsoGameCharacter, itemType: string, distanceTravelled: float`
**When it fires:** An item is found via the foraging/search system. `distanceTravelled` is distance walked since last find.
**Confidence:** MED
**Side:** shared

---

## World / Map

### Events.OnLoadMapZones
**Parameters:** none
**When it fires:** Map zone data is being loaded (metazones, basements, etc.). Register custom zone handlers here.
**Confidence:** MED
**Side:** shared

---

### Events.OnLoadedMapZones
**Parameters:** none
**When it fires:** Map zone data has finished loading. Safe to read zone data.
**Confidence:** MED
**Side:** shared

---

### Events.OnObjectAdded
**Parameters:** `isoObject: IsoObject`
**When it fires:** An IsoObject is placed in the world.
**Confidence:** LOW
**Side:** server

---

### Events.OnObjectAboutToBeRemoved
**Parameters:** `isoObject: IsoObject`
**When it fires:** An IsoObject is about to be removed from the world.
**Confidence:** LOW
**Side:** server

---

### Events.OnDestroyIsoThumpable
**Parameters:** `isoObject: IsoObject, playerObj: IsoPlayer`
**When it fires:** A thumpable object (door, wall, window) is destroyed. `playerObj` may be nil (zombie destroyed it).
**Confidence:** MED
**Side:** server

---

### Events.OnWaterAmountChange
**Parameters:** `object: IsoObject, prevAmount: float`
**When it fires:** The water level in a container changes (rain barrel, sink, etc.).
**Confidence:** LOW
**Side:** server

---

### Events.OnDynamicMovableRecipe
**Parameters:** `sprite: string, recipe, item: InventoryItem, player: IsoPlayer`
**When it fires:** Dynamic moveable recipe is being processed for an inventory item.
**Confidence:** LOW
**Side:** shared

---

## UI

### Events.OnFillWorldObjectContextMenu
**Parameters:** `player: int, context: ISContextMenu, worldobjects: table, test: bool`
**When it fires:** Right-click context menu is being built for a world object. Add menu options here. `test` is `true` during a quick pass to check if any menu would appear.
**Confidence:** HIGH
**Side:** client

```lua
Events.OnFillWorldObjectContextMenu.Add(function(player, context, worldobjects, test)
    if test then return end
    for _, obj in ipairs(worldobjects) do
        if obj:getObjectName() == "Gravestone" then
            context:addOption("Mourn", player, MyMod.onMourn, obj)
        end
    end
end)
```

---

### Events.OnFillInventoryObjectContextMenu
**Parameters:** `playerNum: int, context: ISContextMenu, items: table, test: bool`
**When it fires:** Right-click context menu for inventory items.
**Confidence:** MED
**Side:** client

```lua
Events.OnFillInventoryObjectContextMenu.Add(function(playerNum, context, items, test)
    if test then return end
    for _, item in ipairs(items) do
        -- item is an InventoryItem
    end
end)
```

---

### Events.OnKeyPressed
**Parameters:** `key: int`
**When it fires:** A keyboard key is released (key-up). `key` is a Keyboard constant.
**Confidence:** HIGH
**Side:** client

```lua
Events.OnKeyPressed.Add(function(key)
    if key == Keyboard.KEY_H then
        -- H was pressed
    end
end)
```

Common key codes:
```
Keyboard.KEY_ESCAPE = 1
Keyboard.KEY_SPACE  = 57
Keyboard.KEY_RETURN = 28
```

---

### Events.OnKeyStartPressed
**Parameters:** `key: int`
**When it fires:** Key is first pressed down (key-down, before repeat).
**Confidence:** HIGH
**Side:** client

---

### Events.OnKeyKeepPressed
**Parameters:** `key: int`
**When it fires:** Key is held and repeating each tick.
**Confidence:** HIGH
**Side:** client

---

### Events.OnPreUIDraw
**Parameters:** none
**When it fires:** Before the UI layer is drawn each frame. Use for custom drawing with UIManager.
**Confidence:** MED
**Side:** client

---

### Events.OnPostUIDraw
**Parameters:** none
**When it fires:** After the UI layer is drawn each frame.
**Confidence:** MED
**Side:** client

---

### Events.OnResolutionChange
**Parameters:** none
**When it fires:** Screen resolution or window size changes. Reposition UI elements here.
**Confidence:** HIGH
**Side:** client

---

### Events.DoSpecialTooltip
**Parameters:** (tooltip object — exact type unclear)
**When it fires:** Special tooltip rendering pass.
**Confidence:** MED
**Side:** client

---

## Multiplayer

### Events.OnClientCommand
**Parameters:** `module: string, command: string, player: IsoPlayer, args: table`
**When it fires:** Server receives a Lua command from a client. Filter by `module` to avoid processing other mods' commands.
**Confidence:** HIGH
**Side:** server

```lua
-- Server side
Events.OnClientCommand.Add(function(module, command, player, args)
    if module ~= "MyMod" then return end
    if command == "reportKill" then
        -- args.victimType, etc.
    end
end)
```

Send from client:
```lua
sendClientCommand(player, "MyMod", "reportKill", { victimType = "zombie" })
```

---

### Events.OnServerCommand
**Parameters:** `module: string, command: string, args: table`
**When it fires:** Client receives a Lua command from the server. Filter by `module`.
**Confidence:** MED
**Side:** client

```lua
-- Client side
Events.OnServerCommand.Add(function(module, command, args)
    if module ~= "MyMod" then return end
    if command == "syncSanity" then
        MyMod.sanity = args.sanity
    end
end)
```

Send from server:
```lua
sendServerCommand(player, "MyMod", "syncSanity", { sanity = 80 })
```

---

### Events.OnConnected
**Parameters:** none
**When it fires:** Client successfully connects to a server.
**Confidence:** MED
**Side:** client

---

### Events.OnConnectFailed
**Parameters:** none
**When it fires:** Connection attempt failed.
**Confidence:** MED
**Side:** client

---

### Events.OnDisconnect
**Parameters:** none
**When it fires:** Client disconnects from server.
**Confidence:** MED
**Side:** client

---

### Events.OnScoreboardUpdate / OnMiniScoreboardUpdate
**Parameters:** (scoreboard data — exact type unclear)
**When it fires:** Server pushes player list update.
**Confidence:** HIGH
**Side:** client

---

### Events.OnSafehousesChanged
**Parameters:** none
**When it fires:** Safehouse list is updated (claimed, released, member changed).
**Confidence:** HIGH
**Side:** client

---

## Vehicles

### Events.OnEnterVehicle
**Parameters:** `character: IsoGameCharacter`
**When it fires:** A character (player or NPC) enters a vehicle. Check `instanceof(character, 'IsoPlayer')` to filter.
**Confidence:** MED
**Side:** client

```lua
Events.OnEnterVehicle.Add(function(character)
    if not instanceof(character, 'IsoPlayer') then return end
    local vehicle = character:getVehicle()
    -- vehicle is now set
end)
```

---

### Events.OnExitVehicle
**Parameters:** `character: IsoGameCharacter`
**When it fires:** A character exits a vehicle.
**Confidence:** MED
**Side:** client

---

### Events.OnSwitchVehicleSeat
**Parameters:** `character: IsoGameCharacter`
**When it fires:** A character moves between seats in the same vehicle.
**Confidence:** MED
**Side:** client

---

### Events.OnUseVehicle
**Parameters:** `character: IsoGameCharacter, vehicle: BaseVehicle`
**When it fires:** Player interacts with a vehicle (enter/exit action). Server-side.
**Confidence:** LOW
**Side:** server

---

### Events.OnVehicleHorn
**Parameters:** `character: IsoGameCharacter, vehicle: BaseVehicle, pressed: bool`
**When it fires:** Vehicle horn is pressed or released.
**Confidence:** LOW
**Side:** server

---

### Events.OnSpawnVehicleStart
**Parameters:** `vehicle: BaseVehicle`
**When it fires:** A vehicle is about to be spawned into the world. Used to swap vehicle types by profession.
**Confidence:** LOW
**Side:** server

---

## Climate / Weather

### Events.OnWeatherPeriodStart
**Parameters:** none
**When it fires:** A new weather period begins.
**Confidence:** LOW
**Side:** shared

---

### Events.OnWeatherPeriodStage
**Parameters:** none
**When it fires:** Current weather period advances to a new stage.
**Confidence:** LOW
**Side:** shared

---

### Events.OnWeatherPeriodComplete
**Parameters:** none
**When it fires:** Current weather period ends.
**Confidence:** LOW
**Side:** shared

---

### Events.OnClimateTickDebug
**Parameters:** `mgr: ClimateManager`
**When it fires:** Debug climate tick. Only active when debug UI is open.
**Confidence:** MED
**Side:** client

---

### Events.OnThunderEvent
**Parameters:** `x: int, y: int, strike: bool, light: bool, rumble: bool`
**When it fires:** A thunder/lightning event occurs at world coordinates.
**Confidence:** LOW
**Side:** client

---

## Foraging / Search Mode

### Events.onEnableSearchMode / onDisableSearchMode / onToggleSearchMode
**Parameters:** none
**When it fires:** Player enters or exits search/foraging mode.
**Confidence:** LOW
**Side:** client
**Note:** These are `LuaEventManager.AddEvent`-registered events with lowercase `on` prefix — match exactly.

---

## Actions / Timed Actions

### Events.OnProcessAction
**Parameters:** `action: string, character: IsoGameCharacter, args: table`
**When it fires:** A timed action is processed/executed.
**Confidence:** LOW
**Side:** shared

---

## Gamepad / Controller

### Events.OnGamepadConnect
**Parameters:** (gamepad info)
**When it fires:** A gamepad is connected.
**Confidence:** MED
**Side:** shared

---

### Events.OnGamepadDisconnect
**Parameters:** (gamepad info)
**When it fires:** A gamepad is disconnected.
**Confidence:** MED
**Side:** shared

---

### Events.OnJoypadActivate
**Parameters:** `joypadIndex: int`
**When it fires:** A joypad slot is activated (player assigned to gamepad).
**Confidence:** MED
**Side:** shared

---

## Mod / Workshop

### Events.OnModsModified
**Parameters:** none
**When it fires:** Mod list changes (mod enabled/disabled). Fires in the mod selector screen.
**Confidence:** MED
**Side:** client

---

## Sanity_traits Mod — Most Relevant Events

For the psychological deterioration system, these are the highest-value events:

| Priority | Event | Purpose | Parameters |
|----------|-------|---------|------------|
| **CRITICAL** | `OnZombieDead` | Increment kill counter | `zombie: IsoZombie` |
| **CRITICAL** | `EveryTenMinutes` | Decay/recovery tick, mood check | none |
| **HIGH** | `OnCreatePlayer` | Initialize mod data on new character | `playerIndex: int` |
| **HIGH** | `OnPlayerDeath` | Reset or persist state on death | `playerObj: IsoPlayer` |
| **HIGH** | `LevelPerk` | React to skill changes if needed | `owner, perk, level, addBuffer` |
| **MED** | `OnWeaponHitCharacter` | Detect NPC/survivor kills (check `target:isDead()`) | `attacker, target, weapon, damage` |
| **MED** | `OnGameStart` | Restore saved state on load | none |
| **MED** | `OnNewGame` | Initialize state for new characters | none |
| **MED** | `OnFillWorldObjectContextMenu` | Debug/inspect options | `player, context, worldobjects, test` |
| LOW | `OnTick` | Avoid unless needed — expensive | none |

---

## Notes and Gotchas

1. **`OnZombieDead` parameters**: The Challenge2 (Last Stand) handler takes no parameters, but the Tutorial's `FightStep:OnMomDead(zed)` shows the zombie IS passed. In normal gameplay the zombie param is present. Always guard: `if not zombie then return end`.

2. **`OnTick` vs `EveryTenMinutes`**: `OnTick` fires dozens of times per second. For sanity decay, `EveryTenMinutes` is correct — it maps to in-game time progression, not real time.

3. **`OnGameStart` vs `OnNewGame`**: `OnGameStart` fires for both new AND loaded games. `OnNewGame` fires only on first creation. Use `OnNewGame` for first-time moddata initialization; use `OnGameStart` for restoring UI or registering hooks.

4. **Client vs Server**: In singleplayer, client and server Lua run in the same process. Events in `client/` files fire on the game client; `server/` events fire on the server logic. `shared/` fires on both. For singleplayer-only mods (like Sanity_traits v1), this distinction matters mainly for `OnClientCommand`/`OnServerCommand` — you can skip those entirely.

5. **Removing handlers**: Always store the handler as a named function reference. Lambda/anonymous functions passed to `Add` cannot be passed to `Remove`.

6. **`OnFillWorldObjectContextMenu` test pass**: The `test` parameter is `true` when PZ is quickly checking whether any context menu would appear at all. Return early without adding options: `if test then return end`.

7. **`LuaEventManager.AddEvent`**: Some events (vehicles, search mode) are dynamically registered via `LuaEventManager.AddEvent("EventName")`. They work identically to built-in events — `Events.EventName.Add(handler)` — but must be registered before use. The game files that use them register them at file load time, so they're available by `OnGameStart`.
