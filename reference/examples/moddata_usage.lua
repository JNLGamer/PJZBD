-- Global ModData usage example
-- Place at: media/lua/shared/MyMod_ModData.lua

MyMod_Data = MyMod_Data or {}

local DATA_KEY = "MyMod_SaveData"

-- ── Initialize on world load ──────────────────────────────────────────────────

local function onInitModData(isNewGame)
    local data = ModData.getOrCreate(DATA_KEY)
    if isNewGame then
        -- seed defaults for a fresh save
        data.totalZombiesKilled = 0
        data.daysSurvived       = 0
    end
    MyMod_Data.cache = data
end

Events.OnInitGlobalModData.Add(onInitModData)

-- ── Accessors ─────────────────────────────────────────────────────────────────

function MyMod_Data.get()
    return MyMod_Data.cache or ModData.getOrCreate(DATA_KEY)
end

function MyMod_Data.addKill()
    local d = MyMod_Data.get()
    d.totalZombiesKilled = (d.totalZombiesKilled or 0) + 1
end

-- ── Multiplayer sync ──────────────────────────────────────────────────────────

-- Call on server after updating data to push to all clients
function MyMod_Data.transmit()
    ModData.transmit(DATA_KEY)
end

-- Called on client when server sends updated data
local function onReceive(key, data)
    if key == DATA_KEY then
        MyMod_Data.cache = data
    end
end

Events.OnReceiveGlobalModData.Add(onReceive)

-- ── Per-player modData (saved automatically with character) ───────────────────

function MyMod_Data.getPlayerData(player)
    local md = player:getModData()
    if not md.MyMod then
        md.MyMod = { points = 0, level = 1 }
    end
    return md.MyMod
end

function MyMod_Data.addPoints(player, amount)
    local pd = MyMod_Data.getPlayerData(player)
    pd.points = pd.points + amount
end
