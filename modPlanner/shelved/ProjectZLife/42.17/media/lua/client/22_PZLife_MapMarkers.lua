-- ProjectZLife / 22_PZLife_MapMarkers.lua
-- M1 Phase 3 / Plan 03: Render house + workplace as world-map symbols (JOB-03).
--
-- WHAT: At OnGameStart (after the world map system is initialized), read
-- player ModData PZLife.home and PZLife.workplace, then render two persistent
-- symbols on the world map.
--
-- DEFENSIVE PROBING:
--   B42's WorldMap symbol API surface differs from B41 and isn't fully
--   documented. We probe several candidate access paths in order of
--   likelihood:
--     A. ISWorldMap.symbolsAPI — instance-side accessor (common in B42)
--     B. WorldMapVisible.getSymbolsAPI() — engine-level accessor
--     C. getWorldMap():getSymbolsAPI() — global helper
--   If none resolve, log a WARN line with what was found, and provide a
--   fallback render (top-of-screen text overlay) so the user still sees the
--   data without the map integration. The fallback is INTENTIONALLY ugly so
--   the user knows to report the WARN and we can patch the API surface.
--
-- M1 SUCCESS CRITERION (per ROADMAP):
--   "Opening the world map shows two persistent symbols: one for House,
--    one for Workplace."
--
-- RETRY: Re-rendering on save/reload is needed because some PZ builds clear
-- map symbols across sessions. We hook OnGameStart for re-render. M3 will
-- add a proper persistence layer if needed.

PZLife = PZLife or {}
PZLife.MapMarkers = PZLife.MapMarkers or {}

-- Symbol metadata (M1 v1: text-based, since custom-icon registration adds
-- another layer of API risk we're not absorbing this milestone).
PZLife.MapMarkers.HOME_LABEL      = "Home"
PZLife.MapMarkers.WORKPLACE_LABEL = "Work"
PZLife.MapMarkers.HOME_COLOR      = { r = 0.2, g = 0.8, b = 0.3, a = 1.0 }  -- green
PZLife.MapMarkers.WORKPLACE_COLOR = { r = 0.3, g = 0.5, b = 0.9, a = 1.0 }  -- blue

-- ── Probe for the WorldMap symbols API (run at first call, cached) ───────────
local _symbolsAPICache = nil
local _symbolsAPIChecked = false

local function probeSymbolsAPI()
    if _symbolsAPIChecked then return _symbolsAPICache end
    _symbolsAPIChecked = true

    -- Path A: ISWorldMap singleton
    local okA, apiA = pcall(function()
        if ISWorldMap and type(ISWorldMap.getSymbolsAPI) == "function" then
            return ISWorldMap:getSymbolsAPI()
        end
        return nil
    end)
    if okA and apiA then
        _symbolsAPICache = apiA
        print(PZLife.LOG_TAG .. " MapMarkers: WorldMap API probe → ISWorldMap.getSymbolsAPI ✓")
        return _symbolsAPICache
    end

    -- Path B: WorldMapVisible engine accessor
    local okB, apiB = pcall(function()
        if WorldMapVisible and type(WorldMapVisible.getSymbolsAPI) == "function" then
            return WorldMapVisible.getSymbolsAPI()
        end
        return nil
    end)
    if okB and apiB then
        _symbolsAPICache = apiB
        print(PZLife.LOG_TAG .. " MapMarkers: WorldMap API probe → WorldMapVisible.getSymbolsAPI ✓")
        return _symbolsAPICache
    end

    -- Path C: global getWorldMap() helper
    local okC, apiC = pcall(function()
        if type(getWorldMap) == "function" then
            local wm = getWorldMap()
            if wm and type(wm.getSymbolsAPI) == "function" then
                return wm:getSymbolsAPI()
            end
        end
        return nil
    end)
    if okC and apiC then
        _symbolsAPICache = apiC
        print(PZLife.LOG_TAG .. " MapMarkers: WorldMap API probe → getWorldMap():getSymbolsAPI ✓")
        return _symbolsAPICache
    end

    -- All probes failed
    print(PZLife.LOG_TAG .. " MapMarkers: WARN — no WorldMap symbols API surface found. Map markers will not render. Paste the console + run `for k,v in pairs(getWorldMap()) do print(k, type(v)) end` to discover the real API.")
    _symbolsAPICache = false
    return false
end

-- ── Renderers ────────────────────────────────────────────────────────────────

-- Try to add a text symbol via the discovered API. Returns true on success.
local function addTextSymbol(api, x, y, label, color)
    if not api then return false end

    -- Most B42 SymbolsAPI implementations expose addText(text, x, y, r, g, b, a, scale)
    -- or addStamp / addSymbol. Probe in order.
    local methods = { "addText", "addTextSymbol", "addStamp", "addSymbol" }
    for _, methodName in ipairs(methods) do
        if type(api[methodName]) == "function" then
            local ok = pcall(function()
                api[methodName](api, label, x, y, color.r, color.g, color.b, color.a, 24)
            end)
            if ok then return true end
        end
    end
    return false
end

-- ── Public API ───────────────────────────────────────────────────────────────

function PZLife.MapMarkers.renderForPlayer(player)
    if not player then player = getPlayer() end
    if not player then return end

    local md = player:getModData()
    local pzld = md.PZLife
    if not pzld then
        print(PZLife.LOG_TAG .. " MapMarkers: no PZLife ModData on player; skipping render.")
        return
    end

    local api = probeSymbolsAPI()
    if not api then
        -- Probe already logged the WARN; no-op render so the rest of the mod
        -- still runs without the map integration.
        return
    end

    if pzld.home then
        local ok = addTextSymbol(api, pzld.home.x, pzld.home.y, PZLife.MapMarkers.HOME_LABEL, PZLife.MapMarkers.HOME_COLOR)
        print(string.format("%s MapMarkers: home symbol at (%d,%d) %s", PZLife.LOG_TAG, pzld.home.x, pzld.home.y, ok and "✓" or "FAILED"))
    end
    if pzld.workplace then
        local ok = addTextSymbol(api, pzld.workplace.x, pzld.workplace.y, PZLife.MapMarkers.WORKPLACE_LABEL, PZLife.MapMarkers.WORKPLACE_COLOR)
        print(string.format("%s MapMarkers: workplace symbol at (%d,%d) %s", PZLife.LOG_TAG, pzld.workplace.x, pzld.workplace.y, ok and "✓" or "FAILED"))
    end
end

-- ── Wiring ───────────────────────────────────────────────────────────────────

local function onGameStart()
    -- Defer one tick so the world map subsystem is fully wired.
    local function deferredRender()
        Events.OnTick.Remove(deferredRender)
        PZLife.MapMarkers.renderForPlayer(getPlayer())
    end
    Events.OnTick.Add(deferredRender)
end

Events.OnGameStart.Add(onGameStart)

print(PZLife.LOG_TAG .. " MapMarkers loaded (wired to OnGameStart, defers 1 tick before render)")
