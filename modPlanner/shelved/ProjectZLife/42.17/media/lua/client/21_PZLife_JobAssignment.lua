-- ProjectZLife / 21_PZLife_JobAssignment.lua
-- M1 Phase 3 / Plan 02: Workplace assignment per profession (JOB-02).
--
-- WHAT: At OnCreatePlayer, look up the player's profession and pick a
-- workplace coord. Persist to player:getModData().PZLife.workplace.
-- Map Markers (22_*) reads this and renders a Workplace symbol.
--
-- M1 STRATEGY (deterministic placeholder):
--   The plan calls for "find nearest building of profession-appropriate type"
--   (mechanic→garage, doctor→hospital, etc.). Robust building-type discovery
--   needs BWORooms / Bandit-engine introspection that's not yet wired in our
--   replacement. For M1, we ship a deterministic placeholder: the workplace
--   coord is computed as `home_coord + profession-specific offset`. This:
--     - Always produces a valid coord (no engine-API risk)
--     - Is stable per profession (doctor's workplace is always at home+(60,0))
--     - Renders correctly on the world map (M1 P3 success criterion)
--     - Is replaced in M3 P19 (Job Application UI) when actual building
--       discovery becomes a hard requirement
--
-- The PROFESSION_WORKPLACE table is authored from the BWO official guide's
-- 9 paying jobs. Unknown professions fall back to a default offset.

PZLife = PZLife or {}
PZLife.JobAssignment = PZLife.JobAssignment or {}

-- ── Profession → workplace metadata ──────────────────────────────────────────
-- Each entry:
--   workplaceType — symbolic label rendered in console / map tooltip
--   offset        — { dx, dy } added to home coord to compute workplace coord
--                   (M1 placeholder; replaced by real discovery in M3)
--   buildingHints — keyword list for future real-discovery (informational)
PZLife.PROFESSION_WORKPLACE = {
    mechanic           = { workplaceType = "Garage",         offset = {  60,  0 }, buildingHints = { "garage", "carshop", "auto" } },
    doctor             = { workplaceType = "Hospital",       offset = { -60,  0 }, buildingHints = { "hospital", "clinic", "medical" } },
    nurse              = { workplaceType = "Clinic",         offset = { -50,  0 }, buildingHints = { "hospital", "clinic", "medical" } },
    lumberjack         = { workplaceType = "Forestry Yard",  offset = {   0, 80 }, buildingHints = { "forestry", "lumber", "logging" } },
    fireofficer        = { workplaceType = "Fire Station",   offset = {  40, 40 }, buildingHints = { "firestation", "fire" } },
    fireman            = { workplaceType = "Fire Station",   offset = {  40, 40 }, buildingHints = { "firestation", "fire" } },
    policeofficer      = { workplaceType = "Police Station", offset = { -40, 40 }, buildingHints = { "police", "station" } },
    parkranger         = { workplaceType = "Park HQ",        offset = {   0,-80 }, buildingHints = { "park", "ranger", "forest" } },
    fitnessinstructor  = { workplaceType = "Gym",            offset = {  30,-30 }, buildingHints = { "gym", "fitness" } },
    fisherman          = { workplaceType = "Restaurant",     offset = { -30,-30 }, buildingHints = { "restaurant", "kitchen" } },
    -- Default fallback (used when profession unknown / not yet supported)
    _default           = { workplaceType = "Workplace",      offset = {  50,  0 }, buildingHints = {} },
}

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function getProfessionId(player)
    if not player then return "_default" end
    local descriptor = player.getDescriptor and player:getDescriptor()
    if not descriptor or not descriptor.getProfession then return "_default" end
    local prof = descriptor:getProfession()
    if type(prof) == "string" then return prof:lower() end
    return "_default"
end

-- ── Public API ───────────────────────────────────────────────────────────────

function PZLife.JobAssignment.findWorkplaceForPlayer(player)
    local md = player and player:getModData() or {}
    local home = (md.PZLife and md.PZLife.home) or { x = 0, y = 0, z = 0 }

    local prof = getProfessionId(player)
    local entry = PZLife.PROFESSION_WORKPLACE[prof] or PZLife.PROFESSION_WORKPLACE._default

    return {
        x = home.x + entry.offset[1],
        y = home.y + entry.offset[2],
        z = home.z,
        buildingId = nil,
        workplaceType = entry.workplaceType,
        profession = prof,
        source = "m1-placeholder-offset",
    }
end

function PZLife.JobAssignment.assign(player)
    if not player then return end
    local md = player:getModData()
    md.PZLife = md.PZLife or {}
    if md.PZLife.workplace then
        return  -- idempotent
    end

    -- Run AFTER home assignment so we can offset relative to home.
    -- HomeAssignment.assign is idempotent and registered earlier; calling it
    -- here is a defensive no-op if already done.
    if PZLife.HomeAssignment and PZLife.HomeAssignment.assign then
        PZLife.HomeAssignment.assign(player)
    end

    local workplace = PZLife.JobAssignment.findWorkplaceForPlayer(player)
    md.PZLife.workplace = workplace

    print(string.format(
        "%s JobAssignment: %s assigned %s at (%d,%d,%d) [source=%s]",
        PZLife.LOG_TAG, workplace.profession, workplace.workplaceType,
        workplace.x, workplace.y, workplace.z, workplace.source
    ))
end

-- ── Wiring ───────────────────────────────────────────────────────────────────

local function onCreatePlayer(_, player)
    if not player then player = getPlayer() end
    PZLife.JobAssignment.assign(player)
end

Events.OnCreatePlayer.Add(onCreatePlayer)

print(PZLife.LOG_TAG .. " JobAssignment loaded (wired to OnCreatePlayer)")
