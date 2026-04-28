# ModData & Save Data

Source: MrBounty/PZ-Mod---Doc

## Global ModData

Global ModData stores Lua tables keyed by string — persisted in the save and
optionally synced over the network.

### Core API

```lua
-- Create a new table (or get existing one)
local data = ModData.getOrCreate("MyMod_GlobalData")

-- Set values
data.score = 100
data.playerName = "Alice"

-- Retrieve later
local data = ModData.get("MyMod_GlobalData")
if data then
    print(data.score)
end

-- Check existence
if ModData.exists("MyMod_GlobalData") then ... end

-- Remove
ModData.remove("MyMod_GlobalData")
```

### Initialization Pattern

```lua
local function onInitModData(isNewGame)
    local data = ModData.getOrCreate("MyMod_GlobalData")
    if isNewGame then
        data.score = 0
    end
end

Events.OnInitGlobalModData.Add(onInitModData)
```

### Multiplayer Sync

ModData does NOT auto-sync. You must explicitly transmit/request it.

```lua
-- Server → all clients  (call on server side)
ModData.transmit("MyMod_GlobalData")

-- Client requests data from server
ModData.request("MyMod_GlobalData")

-- Receive callback (both sides)
local function onReceive(key, data)
    if key == "MyMod_GlobalData" then
        -- data is now updated
    end
end
Events.OnReceiveGlobalModData.Add(onReceive)
```

## Player ModData (per-character)

For data that belongs to a specific player character, use the player object's
modData instead of Global ModData.

```lua
local md = player:getModData()
md.myModPoints = md.myModPoints or 0
md.myModPoints = md.myModPoints + 10
```

This is automatically saved with the player save file — no extra work needed.

## JSON File Storage

For larger structured data, use `Json.lua` (from MrBounty/PZ-Mod---Doc or rxi/json.lua).
Place it in `media/lua/client/Json.lua`.

```lua
require "Json"

-- Save table to file
local function saveData(t, filename)
    local writer = getFileWriter(filename .. ".json", true, false)
    writer:write(json.encode(t))
    writer:close()
end

-- Load table from file
local function loadData(filename)
    local reader = getFileReader(filename .. ".json", true)
    if reader then
        local line = ""
        local data = reader:readLine()
        while data do
            line = line .. data
            data = reader:readLine()
        end
        reader:close()
        return json.decode(line)
    end
    return nil
end
```

## Text File Storage (simple — numbers, booleans, strings only)

```lua
local function saveFile(t, filename)
    local writer = getFileWriter(filename .. ".txt", true, false)
    for k, v in pairs(t) do
        writer:write(tostring(k) .. "=" .. tostring(v) .. ",\n")
    end
    writer:close()
end

local function loadFile(filename)
    local reader = getFileReader(filename .. ".txt", true)
    if not reader then return nil end
    local result = {}
    local line = reader:readLine()
    while line do
        for k, v in string.gmatch(line, "([^=]+)=([^,]+),") do
            -- coerce types
            if v == "true" then v = true
            elseif v == "false" then v = false
            elseif tonumber(v) then v = tonumber(v) end
            result[k] = v
        end
        line = reader:readLine()
    end
    reader:close()
    return result
end
```
