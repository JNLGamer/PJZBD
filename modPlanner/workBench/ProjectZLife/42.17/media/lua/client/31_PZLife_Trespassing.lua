-- ProjectZLife / 31_PZLife_Trespassing.lua
-- M2 Phase 6: Escalating trespassing warnings. Absorbs BanditsWeekOneTrespassing.
--
-- WHAT: Replace BWO's binary "trespassing moodle" with escalating text
-- warnings tied to NPC line-of-sight detection:
--   * Idle (not trespassing or not seen): no warning
--   * Warning 1: "This is private property"           (3s in trespass+seen)
--   * Warning 2: "You're trespassing — leave now"     (3s more)
--   * Warning 3: "I'm calling the cops!"              (3s more)
-- At Warning 3, raises wanted-stars by 1 (TRESPASS-03 → WANTED-01).
--
-- TWO CONDITIONS for escalation (per the user's spec):
--   1. The room is intrusion-marked (BWORooms.IsIntrusion — same as BWO)
--   2. At least one nearby NPC has line-of-sight to the player
--      (BanditUtils.LineClear within RADIUS tiles)
--
-- If trespass is true but no NPC sees: timer pauses (don't escalate; don't reset).
-- If trespass goes false: timer + warning level reset to idle.
--
-- DEPENDENCIES (still load — Project Z Life require=Bandits2,BanditsWeekOne):
--   * BWORooms.IsIntrusion       — room intent classifier
--   * BanditUtils.LineClear      — line-of-sight check
--   * BanditUtils.DistTo         — distance check
--   * BanditZombie.GetAllB       — iterate live NPC instances
--
-- DECISIONS LOGGED:
--   D-15 (M2 P6): Text-based ISPanel replaces BWO's image moodle. Per user
--     spec: "Text instead of image (visual warnings)".
--   D-16 (M2 P6): 3-second linger per warning level. Quick enough to feel
--     responsive; long enough to read each line. Tunable via SandboxVars
--     when M4 P22 lands.
--   D-17 (M2 P6): NPC-LOS gating uses 12-tile radius + LineClear. Avoids
--     escalating when player is alone in an empty house (a common loot
--     scenario that shouldn't trigger police).
--   D-18 (M2 P6): Warning 3 raises wanted by exactly 1 (not all 5). The
--     full GTA-style escalation comes from repeated trespass attempts /
--     cumulative crime, not a single trespass instance.

require "ISUI/ISPanel"

PZLife = PZLife or {}
PZLife.Trespassing = PZLife.Trespassing or {}

-- ── Configuration ────────────────────────────────────────────────────────────

PZLife.Trespassing.LOS_RADIUS_TILES   = 12   -- NPC must be within this radius
PZLife.Trespassing.LEVEL_DURATION_MS  = 3000 -- ms before next escalation level

PZLife.Trespassing.LABELS = {
    [0] = "",
    [1] = "This is private property",
    [2] = "You're trespassing — leave now",
    [3] = "I'm calling the cops!",
}

PZLife.Trespassing.COLORS = {
    [0] = { r = 1.0, g = 1.0, b = 1.0, a = 0.0 },  -- invisible
    [1] = { r = 1.0, g = 0.95, b = 0.4, a = 1.0 }, -- yellow
    [2] = { r = 1.0, g = 0.6, b = 0.1, a = 1.0 },  -- orange
    [3] = { r = 1.0, g = 0.15, b = 0.15, a = 1.0 }, -- red
}

-- ── Trespass detection ──────────────────────────────────────────────────────

function PZLife.Trespassing.isPlayerTrespassing(player)
    if not player then return false end
    if player.isOutside and player:isOutside() then return false end
    local square = player.getSquare and player:getSquare()
    if not square then return false end
    local room = square.getRoom and square:getRoom()
    if not room then return false end
    if BWORooms and BWORooms.IsIntrusion then
        return BWORooms.IsIntrusion(room) == true
    end
    return false
end

function PZLife.Trespassing.isPlayerSeenByNPC(player)
    if not player then return false end
    if not BanditZombie or not BanditZombie.GetAllB then return false end
    if not BanditUtils or not BanditUtils.LineClear then return false end

    local px, py, pz = player:getX(), player:getY(), player:getZ()
    local radius = PZLife.Trespassing.LOS_RADIUS_TILES

    local ok, npcs = pcall(BanditZombie.GetAllB)
    if not ok or not npcs then return false end

    for i = 1, (npcs.size and npcs:size() or 0) do
        local npc = npcs:get(i - 1)
        if npc and npc.x and npc.y and npc.z then
            local dx, dy = npc.x - px, npc.y - py
            local distSq = dx * dx + dy * dy
            if distSq <= radius * radius then
                local clearOk, clear = pcall(function()
                    return BanditUtils.LineClear(px, py, pz, npc.x, npc.y, npc.z, true)
                end)
                if clearOk and clear then
                    return true, npc
                end
            end
        end
    end
    return false
end

-- ── State machine ───────────────────────────────────────────────────────────

local function ensureState(player)
    local md = player:getModData()
    md.PZLife = md.PZLife or {}
    md.PZLife.trespass = md.PZLife.trespass or { level = 0, levelEnteredAt = 0 }
    return md.PZLife.trespass
end

function PZLife.Trespassing.advance(player, nowMs)
    local state = ensureState(player)
    local trespassing = PZLife.Trespassing.isPlayerTrespassing(player)

    if not trespassing then
        if state.level ~= 0 then
            state.level = 0
            state.levelEnteredAt = nowMs
        end
        return state
    end

    local seen = PZLife.Trespassing.isPlayerSeenByNPC(player)
    if not seen then
        -- Trespassing but unseen: hold current level, don't escalate.
        return state
    end

    -- Trespassing AND seen: escalate every LEVEL_DURATION_MS until level 3.
    if state.level == 0 then
        state.level = 1
        state.levelEnteredAt = nowMs
    elseif state.level < 3 and (nowMs - state.levelEnteredAt) >= PZLife.Trespassing.LEVEL_DURATION_MS then
        state.level = state.level + 1
        state.levelEnteredAt = nowMs
        if state.level == 3 then
            -- Trigger the wanted-star raise via late-bound call to Wanted module.
            if PZLife.Wanted and PZLife.Wanted.raise then
                PZLife.Wanted.raise(player, 1, "trespass-warning-3")
            else
                print(PZLife.LOG_TAG .. " Trespassing: WARN — PZLife.Wanted not loaded; cannot raise wanted at W3")
            end
        end
    end

    return state
end

-- ── Render layer (ISPanel-derived) ──────────────────────────────────────────

PZLife.Trespassing.Banner = ISPanel:derive("PZLifeTrespassBanner")
local Banner = PZLife.Trespassing.Banner

function Banner:new(playerIndex)
    local o = ISPanel:new(0, 0, 480, 36)
    setmetatable(o, self)
    self.__index = self
    o.playerIndex = playerIndex
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    o.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    o:setVisible(false)
    return o
end

function Banner:prerender()
    ISPanel.prerender(self)
end

function Banner:render()
    local player = getSpecificPlayer(self.playerIndex)
    if not player then return end
    local nowMs = getTimestampMs and getTimestampMs() or (os.time() * 1000)
    local state = PZLife.Trespassing.advance(player, nowMs)
    if state.level == 0 then
        self:setVisible(false)
        return
    end

    local label = PZLife.Trespassing.LABELS[state.level] or ""
    local color = PZLife.Trespassing.COLORS[state.level] or PZLife.Trespassing.COLORS[1]
    local font  = UIFont.Medium

    local left  = getPlayerScreenLeft(self.playerIndex)
    local top   = getPlayerScreenTop(self.playerIndex)
    local width = getPlayerScreenWidth(self.playerIndex)
    local tw    = getTextManager():MeasureStringX(font, label)

    self:setX(left + (width - self.width) / 2)
    self:setY(top + 110)
    self:setVisible(true)

    -- Drop shadow then label text
    self:drawText(label, (self.width - tw) / 2 + 1, 7, 0, 0, 0, 0.85, font)
    self:drawText(label, (self.width - tw) / 2,     6, color.r, color.g, color.b, color.a, font)
end

-- ── Per-player banner instance bookkeeping ──────────────────────────────────

local bannerInstances = {}

local function ensureBanner(playerIndex)
    if bannerInstances[playerIndex] then return end
    local b = Banner:new(playerIndex)
    b:initialise()
    b:addToUIManager()
    bannerInstances[playerIndex] = b
    print(PZLife.LOG_TAG .. " Trespassing: banner ensured for player " .. tostring(playerIndex))
end

Events.OnCreatePlayer.Add(ensureBanner)
Events.OnGameStart.Add(function()
    local count = getNumActivePlayers()
    for i = 0, count - 1 do
        ensureBanner(i)
    end
end)

print(PZLife.LOG_TAG .. " Trespassing loaded (TRESPASS-01..03; uses LOS gating)")
