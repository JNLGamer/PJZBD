-- Sanity_traits / 4_SanityTraits_Panel.lua
-- Phase 01.1 / Plan 02: Logger API (SanityTraits.log).
-- Phase 01.1 / Plan 03: SanityPanel class and ISCharacterInfoWindow wrap (added later).
--
-- Loaded last (numeric prefix "4_") so 1_-3_ files have already defined SanityTraits.* constants
-- and registered Events. SanityTraits.log is callable at runtime (after mod load), well before
-- any kill event actually fires.
--
-- Source: .planning/phases/01.1-sanity-tab-ui/01.1-RESEARCH.md "Logger API (D-15)" and "Pitfall 3"
-- Critical: FIFO eviction is performed on md.SanityTraits.log SOURCE ARRAY via table.remove(t)
-- (no second arg => removes last/oldest). Do NOT use ISScrollingListBox:removeFirst — it is
-- broken in vanilla (calls table.remove with index 0 which is a no-op in 1-indexed Lua).

-- ── Logger API (D-15) ────────────────────────────────────────────────────────
-- SanityTraits.log(category, text, delta)
--   category : "kill" | "stage" | "trait" | "recovery"   (D-13 — only these 4 are accepted)
--   text     : English display string (hardcoded per D-23)
--   delta    : signed integer or nil. nil for stage/trait/recovery events without a sanity change.
--
-- Inserts a structured entry at position 1 (newest at top per D-14), evicts from tail when the
-- log exceeds SanityTraits.LOG_MAX_ENTRIES (D-12). Caller is responsible for the actual sanity
-- decrement; this function only RECORDS the event.
local VALID_LOG_CATEGORIES = {
    kill     = true,
    stage    = true,
    trait    = true,
    recovery = true,
}

function SanityTraits.log(category, text, delta)
    -- Guard: invalid category (D-13)
    if not VALID_LOG_CATEGORIES[category] then
        print(SanityTraits.LOG_TAG .. " WARN: invalid log category '" .. tostring(category) .. "'")
        return
    end

    -- Guard: no live player (e.g. logger called before OnCreatePlayer fires, or in main menu)
    local player = getPlayer()
    if not player then return end

    local md = player:getModData()
    if not md.SanityTraits then return end          -- ModData not yet seeded (Plan 01 hasn't run)
    if not md.SanityTraits.log then return end      -- log array missing (shouldn't happen post-Plan 01 upgrade)

    -- Build entry (D-14 shape)
    local entry = {
        time     = getTimestampMs(),  -- engine-provided ms timestamp; deterministic across saves
        category = category,
        delta    = delta,             -- may be nil
        text     = text,
        icon     = nil,               -- v1 hardcodes nil; later phases may pass texture paths
    }

    -- Insert at position 1 (newest at top, D-14)
    table.insert(md.SanityTraits.log, 1, entry)

    -- FIFO eviction on the SOURCE ARRAY (D-12 — Pitfall 3 mitigation)
    -- table.remove(t) with no index removes the LAST element = oldest
    while #md.SanityTraits.log > SanityTraits.LOG_MAX_ENTRIES do
        table.remove(md.SanityTraits.log)
    end

    -- Console receipt (matches Phase 1 LOG_TAG style for grep consistency)
    print(SanityTraits.LOG_TAG .. " log[" .. category .. "] " .. text
        .. (delta and (" (delta=" .. tostring(delta) .. ")") or ""))
end

print(SanityTraits.LOG_TAG .. " Panel loader: SanityTraits.log ready")
