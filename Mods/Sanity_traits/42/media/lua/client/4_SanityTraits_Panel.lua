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

-- ── SanityPanel class (D-04) ─────────────────────────────────────────────────
-- Subclass of ISPanelJoypad. Mirrors ISCharacterProtection lifecycle:
--   :new -> :initialise -> :createChildren (called when added as child via panel:addView)
--   :prerender (super draws bg) -> :render (per-frame redraw)
--
-- Player handle uses getSpecificPlayer(self.playerNum) per D-22 (NOT getPlayer()).
-- Per-frame refresh model per D-20: :render re-reads md.SanityTraits each call;
-- listbox + debuff row only rebuild when their cached count differs (Pitfall 5).
SanityPanel = ISPanelJoypad:derive("SanityPanel")

function SanityPanel:new(x, y, width, height, playerNum)
    local o = ISPanelJoypad:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.playerNum = playerNum
    -- D-22: getSpecificPlayer (NOT getPlayer) — matches vanilla ISCharacterProtection style
    o.char = getSpecificPlayer(playerNum)
    -- Visual styling per UI-SPEC Color section
    o.background      = true
    o.backgroundColor = {r=0,   g=0,   b=0,   a=0.8}
    o.borderColor     = {r=0.4, g=0.4, b=0.4, a=1}
    -- Cache counters used by render-time refresh (Pitfall 5 mitigation).
    -- -1 forces first :render frame to detect a "change" and populate the listbox + debuff row.
    o.lastLogCount     = -1
    o.lastAppliedCount = -1
    return o
end

function SanityPanel:initialise()
    ISPanelJoypad.initialise(self)
end

function SanityPanel:createChildren()
    ISPanelJoypad.createChildren(self)

    -- ── Event log ISScrollingListBox child (D-21 takes most vertical space) ──
    -- CRITICAL Pitfall 4: lifecycle order is :new -> :initialise -> :instantiate -> setFont -> addChild.
    -- Skipping :instantiate breaks the scrollbar (Java-side UIElement never created).
    local logX = 10
    local logY = 54   -- below header (bar y=10 + barH=14 + 4 gap + stage label ~18 + 8 = ~54)
    local debuffRowY = self.height - 24 - 10   -- 24 = slotSize, 10 = bottom margin
    local logH = math.max(40, debuffRowY - logY - 8)
    local logW = self.width - 20

    self.eventLog = ISScrollingListBox:new(logX, logY, logW, logH)
    self.eventLog:initialise()
    self.eventLog:instantiate()                  -- REQUIRED — Pitfall 4
    self.eventLog:setFont(UIFont.Small, 4)        -- 4 = itemPadY per UI-SPEC
    self.eventLog.backgroundColor = {r=0, g=0, b=0, a=0.4}
    self:addChild(self.eventLog)

    -- ── Debuff icon row (D-16): 6 reserved slots, all initially hidden ───────
    -- Slots beyond #appliedTraits stay invisible; no empty placeholder boxes drawn.
    self.debuffSlots = {}
    local slotSize = 24
    local slotGap  = 4
    local rowY     = self.height - slotSize - 10
    local rowX     = 10
    for i = 1, SanityTraits.DEBUFF_SLOT_COUNT do
        local sx = rowX + (i - 1) * (slotSize + slotGap)
        local img = ISImage:new(sx, rowY, slotSize, slotSize, nil)
        img:initialise()
        img:instantiate()
        img:setVisible(false)   -- D-16: only filled slots render
        img.traitId     = nil   -- our own tag; updated by refreshDebuffRow in :render
        img.useFallback = false -- our own tag; signals procedural fallback rect required
        self:addChild(img)
        self.debuffSlots[i] = img
    end
end
