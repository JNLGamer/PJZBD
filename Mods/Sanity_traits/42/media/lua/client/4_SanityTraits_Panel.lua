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
    local logY = 62   -- GAP-03 closure (Plan 01.1-05): below header with +8px clearance for UIFont.Medium stage label descender (was 54; user observed clipped 'g' in 'Stage: Stable')
    local debuffRowY = self.height - 24 - 10   -- 24 = slotSize, 10 = bottom margin
    local logH = math.max(40, debuffRowY - logY - 8)
    -- GAP-05 closure (Plan 01.1-05): logW formula is now parametric on barW.
    -- (barW + 18) where 18 = 10 right margin + 8 gap between log and bar.
    -- At barW=18 this is self.width - 20 - 36 (Plan 04 hardcoded 32 for barW=14).
    -- Keeping the formula parametric so future barW tweaks don't drift logW out of sync.
    local logW = self.width - 20 - (18 + 18)

    self.eventLog = ISScrollingListBox:new(logX, logY, logW, logH)
    self.eventLog:initialise()
    self.eventLog:instantiate()                  -- REQUIRED — Pitfall 4
    self.eventLog:setFont(UIFont.Small, 4)        -- 4 = itemPadY per UI-SPEC
    -- GAP-04 closure (Plan 01.1-05): opaque slightly-lighter dark grey for visible contrast
    -- against panel bg {r=0,g=0,b=0,a=0.8}. Was {r=0,g=0,b=0,a=0.4} which blended invisibly.
    self.eventLog.backgroundColor = {r=0.08, g=0.08, b=0.08, a=1}
    -- GAP-04 closure (Plan 01.1-05): vanilla ISScrollingListBox built-in 1px border render.
    -- Verified at ProjectZomboid/media/lua/client/ISUI/ISScrollingListBox.lua line 484; default
    -- borderColor = {r=0.4, g=0.4, b=0.4, a=0.9} (line 707) matches our panel-border visual style.
    self.eventLog.drawBorder = true
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

-- ── Format helpers (private to this file) ────────────────────────────────────

-- Format a log entry table into the listbox display string per UI-SPEC:
--   "D{day} {HH:MM} - {text} ({signedDelta})"
-- The delta is rendered in parens with a sign only when non-nil; otherwise omitted.
-- Time prefix is computed at render-time from getGameTime() (not from entry.time —
-- that ms timestamp is just for sort/dedup integrity, not display).
local function formatLogEntryDisplay(entry)
    local gt = getGameTime()
    local day  = gt and gt:getDay()     or 0
    local hour = gt and gt:getHour()    or 0
    local min  = gt and gt:getMinutes() or 0
    local prefix = string.format("D%d %02d:%02d", day, hour, min)
    if entry.delta then
        local sign = entry.delta >= 0 and "+" or ""
        return prefix .. " - " .. entry.text .. " (" .. sign .. tostring(entry.delta) .. ")"
    else
        return prefix .. " - " .. entry.text
    end
end

-- TraitFactory icon lookup with nil guard. Critical Correction 1 / Pitfall 1:
-- vanilla does NOT ship Trait_<id>.png for our negative traits (cowardly,
-- hemophobic, etc.). Use trait:getTexture() instead — the same call vanilla
-- uses at ISCharacterScreen.lua:606. Returns the trait Java object alongside
-- the texture so the caller can also use trait:getLabel() / trait:getDescription().
local function getTraitTextureSafe(traitId)
    local trait = TraitFactory.getTrait(traitId)
    if trait then return trait, trait:getTexture() end
    return nil, nil
end

-- ── Sanity bar: vertical orientation, always-on gradient, track-mask fill ────
-- GAP-01/GAP-02 closure (Plan 01.1-04). Amends D-05 and D-21 visual contract.
--
-- Render passes (in this order):
--   1. Gradient backdrop: ALWAYS render the full bar as 10 horizontal bands
--      lerping green->yellow->red from TOP to BOTTOM. The gradient is permanent
--      and never changes shape with sanity. (GAP-02 fix.)
--   2. Track mask: paint the empty TOP portion (height = (1 - pct) * h) with
--      BAR_TRACK dark grey. This hides the gradient where sanity is "drained."
--      The remaining bottom portion (height = pct * h) shows the gradient.
--      This is the FILL: bottom-up, anchored at the red end. (GAP-02 fix.)
--   3. Threshold ticks: 4 horizontal 1px lines spanning the bar's full width
--      at proportional Y positions along the bar. Higher threshold = nearer top
--      (since high sanity = top of bar). Always visible, drawn OVER the
--      track-mask so they remain visible in empty portions. (D-07 preserved.)
--   4. Border: drawn last so it sits over everything.
--
-- The function accepts arbitrary x/y/w/h so it works regardless of where the
-- caller positions the bar. Callers (only :render in this file) pass the
-- right-edge column coordinates (Task 2 sets barX = self.width - 14 - 10 etc.).
function SanityPanel:drawSanityBar(x, y, w, h, sanity, sanityMax)
    local pct = sanity / sanityMax    -- 0..1
    if pct < 0 then pct = 0 end
    if pct > 1 then pct = 1 end

    -- ── Pass 1: Always-on gradient backdrop (10 bands, GREEN at TOP -> RED at BOTTOM) ──
    local BAND_COUNT = 10
    local bandH = h / BAND_COUNT
    for band = 1, BAND_COUNT do
        local bandPct = (band - 0.5) / BAND_COUNT   -- 0..1, top->bottom centroid
        local r, g, b
        if bandPct < 0.5 then
            -- green to yellow: r climbs 0->1, g stays 1
            local t = bandPct / 0.5
            r, g, b = t, 1.0, 0.0
        else
            -- yellow to red: r stays 1, g drops 1->0
            local t = (bandPct - 0.5) / 0.5
            r, g, b = 1.0, 1.0 - t, 0.0
        end
        -- Use ceil for the last band to avoid sub-pixel gap at the bottom edge
        local bandY = y + math.floor((band - 1) * bandH)
        local thisBandH = (band == BAND_COUNT) and (y + h - bandY) or math.ceil(bandH)
        self:drawRect(x, bandY, w, thisBandH, 1, r, g, b)
    end

    -- ── Pass 2: Track mask over the empty TOP portion (fill from BOTTOM) ──
    -- emptyH = how much of the top is "drained." pct=1 -> emptyH=0 (full bar visible);
    -- pct=0 -> emptyH=h (no gradient visible, only dark track); pct=0.5 -> emptyH=h/2.
    local emptyH = math.floor(h * (1 - pct))
    if emptyH > 0 then
        self:drawRect(x, y, w, emptyH, 1, 0.1, 0.1, 0.1)   -- BAR_TRACK dark grey
    end

    -- ── Pass 3: 4 always-visible threshold ticks (D-07 preserved, rotated 90°) ──
    -- Tick = 1px-tall horizontal line spanning the bar's full width.
    -- High threshold (750=sad) sits near TOP; low threshold (50=desensitized) near BOTTOM.
    -- Drawn AFTER track mask so ticks remain visible even in the empty portion.
    local th = SanityTraits.STAGE_THRESHOLDS
    local thresholds = { th.sad, th.depressed, th.traumatized, th.desensitized }
    for _, threshold in ipairs(thresholds) do
        local tickY = y + h - math.floor(h * (threshold / sanityMax))
        self:drawRect(x, tickY, w, 1, 1, 0.9, 0.9, 0.9)   -- TICK_COLOR off-white
    end

    -- ── Pass 4: Border (drawn last, sits over gradient + mask + ticks) ──
    self:drawRectBorder(x, y, w, h, 1, 0.6, 0.6, 0.6)   -- BAR_BORDER (lightened in Plan 05 / GAP-05 for contrast against panel border {r=0.4,g=0.4,b=0.4})
end

-- ── Listbox refresh (Pitfall 5: only rebuild when #log changed) ──────────────
-- The listbox is a DERIVED VIEW of md.SanityTraits.log (the source array). FIFO
-- eviction is performed on the source array by SanityTraits.log() (Plan 02);
-- here we just rebuild from the array when its count differs from our cache.
function SanityPanel:refreshLogList(md)
    local logArr = md and md.log or nil
    local cur = (logArr and #logArr) or 0
    if cur == self.lastLogCount then return end

    self.eventLog:clear()

    if cur == 0 then
        -- Empty-state placeholder per UI-SPEC Empty State / Copywriting Contract.
        -- Backing item is nil (we never need to look it up).
        self.eventLog:addItem("No events yet.", nil, nil)
    else
        -- newest at index 1; iterate in order so display preserves "newest at top"
        for i = 1, #logArr do
            local entry = logArr[i]
            local label = formatLogEntryDisplay(entry)
            self.eventLog:addItem(label, entry, nil)
        end
    end

    self.lastLogCount = cur
end

-- ── Debuff row refresh (Pitfall 5 + Critical Correction 1 + Critical Correction 2) ──
-- Cache pattern: only rebuild when #appliedTraits differs from lastAppliedCount.
-- Icon source: TraitFactory.getTrait(id):getTexture() (Critical Correction 1).
-- Tooltip: ISImage:setMouseOverText with "\n" line breaks (Critical Correction 2).
function SanityPanel:refreshDebuffRow(md)
    local arr = md and md.appliedTraits or nil
    local cur = (arr and #arr) or 0
    if cur == self.lastAppliedCount then return end

    for i = 1, SanityTraits.DEBUFF_SLOT_COUNT do
        local slot  = self.debuffSlots[i]
        local entry = arr and arr[i] or nil
        if entry then
            slot.traitId = entry.traitId
            local trait, tex = getTraitTextureSafe(entry.traitId)

            if tex then
                slot.texture     = tex
                slot.useFallback = false
            else
                slot.texture     = nil
                slot.useFallback = true   -- :render will draw the procedural rect on top
            end

            -- Tooltip (D-19): 3 lines via "\n", per Critical Correction 2 (setMouseOverText).
            -- Line 1: trait label, Line 2: trait description, blank line, then attribution.
            local stageKey  = entry.appliedAtStage or "stable"
            local stageName = SanityTraits.STAGE_NAMES[stageKey] or stageKey
            local label = (trait and trait:getLabel())       or entry.traitId
            local desc  = (trait and trait:getDescription()) or ""
            local tipText = label .. "\n" .. desc .. "\n\nApplied by Sanity Traits at " .. stageName
            slot:setMouseOverText(tipText)

            slot:setVisible(true)
        else
            slot.traitId     = nil
            slot.texture     = nil
            slot.useFallback = false
            slot:setMouseOverText("")
            slot:setVisible(false)
        end
    end

    self.lastAppliedCount = cur
end

-- ── Lifecycle render hooks ───────────────────────────────────────────────────

function SanityPanel:prerender()
    ISPanelJoypad.prerender(self)   -- inherited bg draw
end

-- Per-frame redraw (D-20). Re-reads md.SanityTraits each call — no event subscription,
-- no polling. Listbox + debuff row only rebuild when their cached counts changed.
function SanityPanel:render()
    -- Re-acquire player if it was nil at construction (Pitfall 6 mitigation)
    if not self.char then
        self.char = getSpecificPlayer(self.playerNum)
        if not self.char then return end
    end

    local md = self.char:getModData().SanityTraits
    if not md then return end   -- Plan 01 ModData not yet seeded (shouldn't happen post-OnCreatePlayer)

    -- ── Header: vertical bar (right edge) + numeric readout + stage label (top-left) ──
    -- GAP-01/GAP-02 closure (Plan 01.1-04). Bar moved to right edge column;
    -- readout and stage label moved to top-left in the freed horizontal space.
    local sanity = md.sanity or 0
    local sanityMax = SanityTraits.SANITY_MAX

    -- Vertical bar pinned to right edge: 14px wide column with 10px right margin.
    -- Bar height fills panel vertical space minus top margin (10), debuff row size (24),
    -- bottom margin (10), and a 4px gap above the debuff row = 48px reserved.
    local barW = 18
    local barX = self.width - barW - 10
    local barY = 10
    local barH = math.max(40, self.height - 48)

    self:drawSanityBar(barX, barY, barW, barH, sanity, sanityMax)

    -- D-06 numeric readout EXACTLY in format "%d / %d (%d%%)" — TOP-LEFT (was right of bar)
    local readoutX = 10
    local readoutY = 10
    local pct = math.floor((sanity / sanityMax) * 100)
    local readout = string.format("%d / %d (%d%%)", sanity, sanityMax, pct)
    self:drawText(readout, readoutX, readoutY, 1, 1, 1, 1, UIFont.Small)

    -- D-09 stage label "Stage: <thematic>" — TOP-LEFT below readout (was below bar)
    local stageX = 10
    local stageY = 30   -- readoutY (10) + UIFont.Small line height (~12) + 8px gap
    local stageKey  = SanityTraits.computeStage(sanity)
    local stageName = SanityTraits.STAGE_NAMES[stageKey] or stageKey
    self:drawText("Stage: " .. stageName, stageX, stageY, 1, 1, 1, 1, UIFont.Medium)

    -- GAP-03 closure (Plan 01.1-05): 1px horizontal divider between header and event log.
    -- Y=50 sits between stage label glyph bottom (~48) and logY (62). Color matches panel
    -- border {r=0.4,g=0.4,b=0.4} for visual consistency. Width parametric on barW so the
    -- divider stops at the listbox's right edge (does not extend under the bar column).
    self:drawRect(10, 50, self.width - 20 - (barW + 18), 1, 1, 0.4, 0.4, 0.4)

    -- ── Refresh listbox + debuff row only when their counts changed ──
    self:refreshLogList(md)
    self:refreshDebuffRow(md)

    -- ── Procedural fallback rect for any debuff slot whose trait texture is nil ──
    -- Pitfall 1 mitigation. We draw on top of the ISImage's slot position; the ISImage
    -- itself shows nothing (texture=nil) when useFallback is true, so painting our rect
    -- over its position is correct and complete.
    for i = 1, SanityTraits.DEBUFF_SLOT_COUNT do
        local slot = self.debuffSlots[i]
        if slot:isVisible() and slot.useFallback and slot.traitId then
            local sx = slot:getX()
            local sy = slot:getY()
            self:drawRect(sx, sy, 18, 18, 1, 0.3, 0.3, 0.3)
            self:drawRectBorder(sx, sy, 18, 18, 1, 0.6, 0.6, 0.6)
            -- last char of traitId, drawn at small offset
            self:drawText(string.sub(slot.traitId, -1), sx + 6, sy + 1, 1, 1, 1, 1, UIFont.Small)
        end
    end
end

-- ── ISCharacterInfoWindow:createChildren wrap (D-01, D-02, D-03) ─────────────
-- Composability rule: never replace vanilla functions; wrap them.
-- Pitfall 2: defensive nil guard — if vanilla source somehow loaded later (or
-- failed to load), refuse to wrap and print an explicit error so the user has
-- a clear console.txt signal instead of a cryptic "attempt to index a nil value".
--
-- Critical Correction 3: ship default ISTabPanel behavior. Vanilla's tab-strip
-- total-width hint is local to vanilla's :createChildren and inaccessible after
-- the wrap returns. We do NOT manually resize the panel or the parent window.
-- ISTabPanel renders built-in scroll arrows when the strip overflows.
if not ISCharacterInfoWindow then
    print(SanityTraits.LOG_TAG .. " ERROR: ISCharacterInfoWindow not loaded; cannot install Psyche tab")
else
    local origCreateChildren = ISCharacterInfoWindow.createChildren
    function ISCharacterInfoWindow:createChildren()
        -- Vanilla creates Info, Skills, Health, Protection, ClothingIns (5 tabs).
        -- After this call, self.panel exists and has 5 views.
        origCreateChildren(self)

        -- Build our 6th view. Sized to fit inside the existing panel area.
        -- Position/size mirrors how vanilla constructs each tab view at lines 127-149.
        local panelX = 0
        local panelY = 8
        local panelW = self.charScreen and self.charScreen.width or self.width
        local panelH = self.height - 8

        self.sanityView = SanityPanel:new(panelX, panelY, panelW, panelH, self.playerNum)
        self.sanityView:initialise()
        -- ISTabPanel:addView internally calls self:addChild(view) which triggers
        -- our SanityPanel:createChildren() lifecycle. Order matches vanilla's
        -- tab construction at lines 127-149.
        self.panel:addView("Psyche", self.sanityView)

        print(SanityTraits.LOG_TAG .. " Psyche tab installed")
    end
end
