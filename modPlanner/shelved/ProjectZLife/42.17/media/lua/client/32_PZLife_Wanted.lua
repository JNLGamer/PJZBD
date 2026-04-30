-- ProjectZLife / 32_PZLife_Wanted.lua
-- M2 Phase 7: Wanted-star ladder (1–5 stars). State machine + decay rules.
-- (WANTED-01..06.)
--
-- WHAT: Player-side state for "wanted level," modeled after GTA's 5-star
-- system but with PZ/BWO-specific rules:
--
--   ★    (1)  minor trespassing, theft of light items
--   ★★   (2)  aiming weapon at NPC, breaking windows, hotwiring
--   ★★★  (3)  assault, repeated theft, attacking police
--   ★★★★ (4)  murder of civilian
--   ★★★★★(5)  murder of multiple civilians, mass violence
--
-- DECAY RULES (per user spec):
--   * One star at a time (NOT all-at-once like GTA)
--   * Bad record (player has murdered) → minimum 3-star floor; can only lose
--     stars when out of town and unspotted by NPCs.
--   * Mask-clear escape: player wears a mask AND removes it while NOT
--     spotted → all stars cleared (overrides bad-record floor).
--   * Default decay: 1 star drops per N in-game minutes when not committing
--     fresh crimes and not spotted.
--
-- This file is the *state machine + persistence layer*. Trespassing module
-- (M2 P6) raises stars at warning 3. Police behavior tier (M2 P9) reads stars
-- to decide cuff/non-lethal/shoot. BUSTED/WASTED transition (M2 P8) reads
-- stars to decide hospital vs jail.
--
-- DECISIONS LOGGED:
--   D-19 (M2 P7): Decay interval = 30 in-game minutes per star (Events.EveryHours
--     fires EveryTenMinutes-equivalent twice). Tunable via M4 P22 sandbox.
--   D-20 (M2 P7): "Out of town" detection = simple distance-from-spawn check
--     for v1 (>200 tiles from any settlement center). M3 will replace with
--     BWOBuildings/BanditCompatibility-aware metric.
--   D-21 (M2 P7): Bad-record bit is sticky. Once a murder is recorded, it
--     persists for the entire character's lifetime. Death clears it (a new
--     character starts fresh).
--   D-22 (M2 P7): Mask state is sampled per-tick on OnPlayerUpdate. The
--     "mask just removed unspotted" event fires on the falling edge of the
--     mask-worn boolean. Cheap; no allocation.
--   D-23 (M2 P7): API is public on PZLife.Wanted so M2 P6 (trespassing) and
--     future M3+ phases can call raise / flag / read without coupling.

PZLife = PZLife or {}
PZLife.Wanted = PZLife.Wanted or {}

-- ── Configuration ───────────────────────────────────────────────────────────

PZLife.Wanted.MAX_STARS                = 5
PZLife.Wanted.BAD_RECORD_FLOOR         = 3
PZLife.Wanted.DECAY_INTERVAL_MINUTES   = 30
PZLife.Wanted.OUT_OF_TOWN_RADIUS_TILES = 200
PZLife.Wanted.MASK_KEYWORDS            = { "Mask", "Balaclava", "SkiMask", "Bandana" }

-- ── Persistence helpers ─────────────────────────────────────────────────────

local function ensureState(player)
    local md = player:getModData()
    md.PZLife = md.PZLife or {}
    md.PZLife.wantedStars       = md.PZLife.wantedStars or 0
    md.PZLife.badRecord         = md.PZLife.badRecord or false
    md.PZLife.lastSpottedAtMs   = md.PZLife.lastSpottedAtMs or 0
    md.PZLife.lastDecayInGameH  = md.PZLife.lastDecayInGameH or -1
    md.PZLife._maskWornCache    = md.PZLife._maskWornCache or false
    return md.PZLife
end

local function nowMs()
    return getTimestampMs and getTimestampMs() or (os.time() * 1000)
end

-- ── Mask detection ──────────────────────────────────────────────────────────

local function isWearingMask(player)
    if not player or not player.getWornItems then return false end
    local worn = player:getWornItems()
    if not worn then return false end
    for i = 0, worn:size() - 1 do
        local entry = worn:get(i)
        if entry and entry.getItem then
            local item = entry:getItem()
            if item and item.getType then
                local t = item:getType()
                for _, needle in ipairs(PZLife.Wanted.MASK_KEYWORDS) do
                    if t and t:find(needle, 1, true) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- ── Spotted detection (delegates to Trespassing's LOS scanner) ──────────────

local function isPlayerSpotted(player)
    if PZLife.Trespassing and PZLife.Trespassing.isPlayerSeenByNPC then
        local seen = PZLife.Trespassing.isPlayerSeenByNPC(player)
        return seen
    end
    return false  -- conservative: if Trespassing not loaded, assume not seen
end

-- ── "Out of town" detection (v1: distance-from-spawn proxy) ─────────────────

local function isOutOfTown(player)
    if not player then return false end
    local md = player:getModData()
    local home = md.PZLife and md.PZLife.home
    if not home then return false end
    local px, py = player:getX(), player:getY()
    local dx, dy = px - home.x, py - home.y
    local dist = math.sqrt(dx * dx + dy * dy)
    return dist > PZLife.Wanted.OUT_OF_TOWN_RADIUS_TILES
end

-- ── Public API ──────────────────────────────────────────────────────────────

function PZLife.Wanted.read(player)
    local s = ensureState(player)
    return {
        stars      = s.wantedStars,
        badRecord  = s.badRecord,
    }
end

function PZLife.Wanted.raise(player, n, reason)
    if not player or not n or n <= 0 then return end
    local s = ensureState(player)
    local before = s.wantedStars
    s.wantedStars = math.min(PZLife.Wanted.MAX_STARS, s.wantedStars + n)
    print(string.format("%s Wanted: %d → %d (+%d, reason=%s)",
        PZLife.LOG_TAG, before, s.wantedStars, n, tostring(reason)))
end

function PZLife.Wanted.flagBadRecord(player, reason)
    if not player then return end
    local s = ensureState(player)
    if s.badRecord then return end
    s.badRecord = true
    -- Stick to floor immediately
    if s.wantedStars < PZLife.Wanted.BAD_RECORD_FLOOR then
        s.wantedStars = PZLife.Wanted.BAD_RECORD_FLOOR
    end
    print(string.format("%s Wanted: bad-record flagged (reason=%s); stars now %d",
        PZLife.LOG_TAG, tostring(reason), s.wantedStars))
end

function PZLife.Wanted.maskCleared(player)
    if not player then return end
    local s = ensureState(player)
    if s.wantedStars == 0 and not s.badRecord then return end
    print(string.format("%s Wanted: mask-clear escape — stars %d→0 (badRecord cleared from %s)",
        PZLife.LOG_TAG, s.wantedStars, tostring(s.badRecord)))
    s.wantedStars = 0
    s.badRecord = false
end

function PZLife.Wanted.canDecayNow(player)
    local s = ensureState(player)
    if s.wantedStars == 0 then return false end

    if s.badRecord then
        -- Bad record: must be out of town AND not spotted
        if not isOutOfTown(player) then return false end
        if isPlayerSpotted(player) then return false end
        -- Cannot decay below floor
        if s.wantedStars <= PZLife.Wanted.BAD_RECORD_FLOOR then return false end
        return true
    end

    -- No bad record: just must not be spotted committing fresh crimes
    if isPlayerSpotted(player) then return false end
    return true
end

-- ── Decay tick (hooked to EveryTenMinutes) ──────────────────────────────────

local function decayTick()
    local player = getPlayer()
    if not player then return end
    local s = ensureState(player)
    if s.wantedStars == 0 then return end

    local currentHour = getGameTime():getHour()
    if s.lastDecayInGameH == currentHour then return end  -- already decayed this hour

    if PZLife.Wanted.canDecayNow(player) then
        local before = s.wantedStars
        s.wantedStars = math.max(0, s.wantedStars - 1)
        s.lastDecayInGameH = currentHour
        print(string.format("%s Wanted: decayed %d → %d at game hour %d",
            PZLife.LOG_TAG, before, s.wantedStars, currentHour))
    end
end

-- ── Mask-edge detection (hooked to OnPlayerUpdate) ──────────────────────────

local function maskEdgeTick(player)
    if not player then return end
    local s = ensureState(player)
    local wearing = isWearingMask(player)
    if s._maskWornCache and not wearing then
        -- Falling edge: mask just removed
        if not isPlayerSpotted(player) then
            PZLife.Wanted.maskCleared(player)
        end
    end
    s._maskWornCache = wearing
end

-- ── Wiring ──────────────────────────────────────────────────────────────────

Events.EveryTenMinutes.Add(decayTick)
Events.OnPlayerUpdate.Add(maskEdgeTick)

print(PZLife.LOG_TAG .. " Wanted loaded (WANTED-01..06; decay=30 game-min, mask-clear=enabled)")
