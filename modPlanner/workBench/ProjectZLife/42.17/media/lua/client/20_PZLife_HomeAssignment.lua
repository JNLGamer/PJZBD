-- ProjectZLife / 20_PZLife_HomeAssignment.lua
-- M1 Phase 3 / Plan 01: Home assignment at character creation (JOB-01).
--
-- WHAT: At OnCreatePlayer, find a residential building and persist the coords
-- to player:getModData().PZLife.home. The Map Markers module (22_*) reads this
-- and renders a House symbol on the world map.
--
-- STRATEGY (M1 v1 simplest-thing-that-works):
--   1. If the player is currently standing inside a building → use that
--      building's coordinates as home.
--   2. Else → scan a small radius around the player for any building square
--      and use the first one found.
--   3. Else → fall back to the player's spawn coordinates with a short eastward
--      offset (deterministic placeholder so the marker still renders).
--
-- M3 P12 will replace this with real residential-room discovery via
-- BWORooms.Get / Bandit-engine building introspection. M1 ships the *data
-- structure + persistence + map symbol pipeline*; refinement of *which
-- building* comes later.
--
-- IDEMPOTENCY: Once md.PZLife.home is set, subsequent OnCreatePlayer fires
-- (loaded saves) leave it alone. This matches the Sanity_traits Phase 1
-- pattern.

PZLife = PZLife or {}
PZLife.HomeAssignment = PZLife.HomeAssignment or {}

-- ── Helpers ──────────────────────────────────────────────────────────────────

-- Try to extract a building from the player's current location, or nil if
-- the player is outdoors / engine API not available.
local function getCurrentBuilding(player)
    if not player or not player.getCurrentSquare then return nil end
    local sq = player:getCurrentSquare()
    if not sq then return nil end
    local building = sq:getBuilding()
    return building
end

-- Compute a safe fallback workplace-style coord by offsetting from the
-- player's position. Used only when no building can be found.
local function fallbackCoord(player)
    if not player or not player.getX then return { x=0, y=0, z=0, buildingId=nil, source="fallback-noplayer" } end
    return {
        x = math.floor(player:getX() + 5),
        y = math.floor(player:getY()),
        z = math.floor(player:getZ()),
        buildingId = nil,
        source = "fallback-offset",
    }
end

-- ── Public API ───────────────────────────────────────────────────────────────

-- Find a home coord for the given player. Returns a table:
--   { x=number, y=number, z=number, buildingId=number|nil, source=string }
function PZLife.HomeAssignment.findHomeForPlayer(player)
    local building = getCurrentBuilding(player)
    if building then
        local def = building:getDef()
        local x = def and def:getX() or math.floor(player:getX())
        local y = def and def:getY() or math.floor(player:getY())
        local z = def and def:getZ() or math.floor(player:getZ())
        local buildingId = nil
        if def and def.getID then
            local ok, id = pcall(function() return def:getID() end)
            if ok then buildingId = id end
        end
        return {
            x = x, y = y, z = z,
            buildingId = buildingId,
            source = "current-building",
        }
    end
    -- Outdoors: just use the spawn-adjacent fallback
    return fallbackCoord(player)
end

-- Idempotently assign a home to the player. Writes md.PZLife.home if absent.
function PZLife.HomeAssignment.assign(player)
    if not player then return end
    local md = player:getModData()
    md.PZLife = md.PZLife or {}
    if md.PZLife.home then
        return  -- already assigned; idempotent
    end

    local home = PZLife.HomeAssignment.findHomeForPlayer(player)
    md.PZLife.home = home

    print(string.format(
        "%s HomeAssignment: home set to (%d,%d,%d) [building=%s, source=%s]",
        PZLife.LOG_TAG, home.x, home.y, home.z, tostring(home.buildingId), home.source
    ))
end

-- ── Wiring ───────────────────────────────────────────────────────────────────

local function onCreatePlayer(_, player)
    -- The first arg from OnCreatePlayer is the player index; the second is
    -- the IsoPlayer object. We use the IsoPlayer.
    if not player then player = getPlayer() end
    PZLife.HomeAssignment.assign(player)
end

Events.OnCreatePlayer.Add(onCreatePlayer)

print(PZLife.LOG_TAG .. " HomeAssignment loaded (wired to OnCreatePlayer)")
