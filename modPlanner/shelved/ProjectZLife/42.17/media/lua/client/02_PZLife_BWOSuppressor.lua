-- ProjectZLife / 02_PZLife_BWOSuppressor.lua
-- M1 Phase 1 / Plan 02-03: Suppress BanditsWeekOne's Events.OnTick callbacks.
--
-- WHY: BWO is loaded as a hard dependency for its ~410 MB of assets (sounds,
-- animations, textures, maps). But its Lua execution would race with our own
-- pop control, scheduler, and event system. We let BWO load (so its assets
-- register), then at OnGameStart we walk the OnTick callback list and remove
-- any callback whose source path matches one of the BWO files in
-- PZLife.BWO_TICK_SOURCES (defined in 01_PZLife_Init.lua).
--
-- HOW: Two-pass design — first pass logs without removing (read-only),
-- second pass removes. The read-only pass is gated by PZLife.SUPPRESSOR_DRY_RUN
-- so the user can validate the introspection works before committing to
-- removal. Default: dry run is FALSE (we remove on first run).
--
-- DEFENSIVE NOTES:
--   * `Events.OnTick.callbacks` may be named differently across B42 builds.
--     We probe several known field names defensively.
--   * `debug.getinfo(fn, "S").source` may return nil for engine-side callbacks.
--   * Iterating-while-removing the callback list is unsafe; we collect first,
--     then call .Remove() in a second pass.
--
-- Source spec: .planning-ProjectZLife/research/SUMMARY.md ("Pitfalls" table)
--              and the approved plan's M1 P1 strategy.

PZLife = PZLife or {}

-- Set to true to log without removing (debugging aid). Default: false (real run).
PZLife.SUPPRESSOR_DRY_RUN = false

-- ── Probe for the callback list field on a PZ Events.<Name> object ───────────
-- Returns the callback list, or nil if no known field matched.
local function getCallbackList(eventObj)
    if type(eventObj) ~= "table" then return nil end
    -- Known PZ B42 field names (in order of likelihood)
    if type(eventObj.callbacks)   == "table" then return eventObj.callbacks   end
    if type(eventObj._callbacks)  == "table" then return eventObj._callbacks  end
    if type(eventObj.__callbacks) == "table" then return eventObj.__callbacks end
    return nil
end

-- ── Decide whether a callback's source path is a BWO suppression target ──────
local function isBWOSource(sourcePath)
    if type(sourcePath) ~= "string" then return false end
    for _, needle in ipairs(PZLife.BWO_TICK_SOURCES) do
        if sourcePath:find(needle, 1, true) then  -- plain substring match
            return true, needle
        end
    end
    return false
end

-- ── Suppression entry point: walks OnTick callbacks, removes BWO ones ────────
local function suppressBWOOnTick()
    local list = getCallbackList(Events.OnTick)
    if not list then
        print(PZLife.LOG_TAG .. " WARN: Events.OnTick has no readable callback list — suppression skipped (B42 Events API may have changed)")
        return
    end

    local total       = #list
    local toRemove    = {}
    local matchCounts = {}

    for i = 1, total do
        local cb = list[i]
        if type(cb) == "function" then
            local ok, info = pcall(debug.getinfo, cb, "S")
            local source   = (ok and info and info.source) or "<unknown>"
            local matched, needle = isBWOSource(source)
            if matched then
                toRemove[#toRemove + 1] = cb
                matchCounts[needle] = (matchCounts[needle] or 0) + 1
            end
        end
    end

    -- Diagnostic banner
    print(string.format(
        "%s OnTick callbacks scanned: %d total, %d BWO-matching (dry_run=%s)",
        PZLife.LOG_TAG, total, #toRemove, tostring(PZLife.SUPPRESSOR_DRY_RUN)
    ))
    for needle, count in pairs(matchCounts) do
        print(string.format("%s   - %s: %d callback(s)", PZLife.LOG_TAG, needle, count))
    end

    if PZLife.SUPPRESSOR_DRY_RUN then
        print(PZLife.LOG_TAG .. " DRY RUN — no callbacks removed.")
        return
    end

    -- Removal pass
    local removed = 0
    for _, cb in ipairs(toRemove) do
        local ok = pcall(function() Events.OnTick.Remove(cb) end)
        if ok then removed = removed + 1 end
    end

    print(string.format("%s OnTick suppression complete: %d callbacks removed.", PZLife.LOG_TAG, removed))
end

-- Wire to OnGameStart so all mod files (including BWO) have finished loading
-- their callback registrations before we walk the list.
Events.OnGameStart.Add(suppressBWOOnTick)

print(PZLife.LOG_TAG .. " BWOSuppressor armed (will fire at OnGameStart)")
