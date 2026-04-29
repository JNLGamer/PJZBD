--[[
PZLifeTrespassMoodle — text-based escalating trespassing warnings.

Replaces the BWOTrespass image moodle with a text panel that:
  Level 0: idle (panel hidden)
  Level 1: "Private property — please leave"           (yellow, 20s grace)
  Level 2: "You're trespassing — leave NOW"            (orange, 20s grace)
  Level 3: "I'm calling the cops!"                     (red, raises wanted stars)

Escalation rules:
  - Player must be in an Intrusion room AND spotted by a nearby NPC.
  - Levels advance every (gracePeriod) seconds the player stays in violation.
  - Level 3 calls PZLifeWanted.OnCrime(player, 1) once, then resets to level 0.
  - Leaving the intrusion room or going unspotted ramps the level back down.

The original BWOTrespass image moodle is force-hidden by overriding its
isTrespassing call to return false (its only visibility predicate).
]]

require "ISUI/ISPanel"

PZLifeTrespass = PZLifeTrespass or {}
PZLifeTrespass.DEBUG = false
PZLifeTrespass.state = PZLifeTrespass.state or {}  -- per-playerIndex { level, lastTickMin, lastEscalateMin }

local function tlog(msg)
    if PZLifeTrespass.DEBUG then print("[PZLifeTrespass] " .. tostring(msg)) end
end

local LEVEL_TEXTS = {
    [1] = "Private property — please leave.",
    [2] = "You're trespassing — leave NOW.",
    [3] = "I'm calling the cops!",
}
local LEVEL_COLORS = {
    [1] = {r = 1.0, g = 0.85, b = 0.2},   -- yellow
    [2] = {r = 1.0, g = 0.55, b = 0.1},   -- orange
    [3] = {r = 1.0, g = 0.15, b = 0.1},   -- red
}
local GRACE_MINUTES_PER_LEVEL = 0.5  -- in-game minutes between level escalations

----------------------------------------------------------------------
-- Detection helpers
----------------------------------------------------------------------

local function isInIntrusion(player)
    if not player or player:isOutside() then return false end
    local sq = player:getSquare(); if not sq then return false end
    local room = sq:getRoom(); if not room then return false end
    if BWORooms and BWORooms.IsIntrusion then
        local ok, res = pcall(BWORooms.IsIntrusion, room)
        if ok then return res == true end
    end
    return false
end

local function isPlayerSpotted(player)
    -- Heuristic: any bandit/civilian in the player's room within ~12 tiles
    -- counts as "spotting" the player.
    if not BanditZombie or not BanditZombie.CacheLight then
        return false
    end
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    for _, c in pairs(BanditZombie.CacheLight) do
        if c.z == pz then
            local dx = c.x - px
            local dy = c.y - py
            if (dx * dx + dy * dy) <= 144 then  -- 12 tiles
                return true
            end
        end
    end
    return false
end

----------------------------------------------------------------------
-- Moodle UI panel
----------------------------------------------------------------------

PZLifeTrespassPanel = ISPanel:derive("PZLifeTrespassPanel")

local PANEL_WIDTH = 360
local PANEL_HEIGHT = 32

function PZLifeTrespassPanel:new(playerIndex)
    local screenLeft = getPlayerScreenLeft(playerIndex)
    local screenWidth = getPlayerScreenWidth(playerIndex)
    local x = screenLeft + (screenWidth - PANEL_WIDTH) / 2
    local y = getPlayerScreenTop(playerIndex) + 90
    local o = ISPanel:new(x, y, PANEL_WIDTH, PANEL_HEIGHT)
    setmetatable(o, self)
    self.__index = self
    o.playerIndex = playerIndex
    o.backgroundColor = {r = 0, g = 0, b = 0, a = 0.55}
    o.borderColor = {r = 1, g = 1, b = 1, a = 0.0}
    o:setVisible(false)
    return o
end

function PZLifeTrespassPanel:prerender()
    ISPanel.prerender(self)
    local s = PZLifeTrespass.state[self.playerIndex]
    if not s or s.level <= 0 then
        self:setVisible(false)
        return
    end
    local text = LEVEL_TEXTS[s.level] or ""
    local color = LEVEL_COLORS[s.level] or {r=1,g=1,b=1}
    -- Re-center based on text width
    local tw = getTextManager():MeasureStringX(UIFont.Medium, text)
    local th = getTextManager():getFontHeight(UIFont.Medium)
    self:drawTextCentre(text, self.width / 2, (self.height - th) / 2, color.r, color.g, color.b, 1, UIFont.Medium)
end

function PZLifeTrespassPanel:render() end

local function ensurePanel(playerIndex)
    if PZLifeTrespass.panels and PZLifeTrespass.panels[playerIndex] then return end
    PZLifeTrespass.panels = PZLifeTrespass.panels or {}
    local panel = PZLifeTrespassPanel:new(playerIndex)
    panel:initialise()
    panel:addToUIManager()
    PZLifeTrespass.panels[playerIndex] = panel
end

----------------------------------------------------------------------
-- Tick — drives escalation
----------------------------------------------------------------------

local function tick(player, playerIndex)
    if not player then return end
    PZLifeTrespass.state[playerIndex] = PZLifeTrespass.state[playerIndex] or {
        level = 0,
        lastEscalateMin = 0,
    }
    local s = PZLifeTrespass.state[playerIndex]
    local nowMin = getGameTime():getWorldAgeHours() * 60

    local intruding = isInIntrusion(player)
    local spotted = intruding and isPlayerSpotted(player)

    -- Hide panel if not actively warning
    local panel = (PZLifeTrespass.panels or {})[playerIndex]

    if not intruding then
        -- Player left the intrusion room — drop level over time
        if s.level > 0 and (nowMin - (s.lastEscalateMin or 0)) >= GRACE_MINUTES_PER_LEVEL then
            s.level = math.max(0, s.level - 1)
            s.lastEscalateMin = nowMin
        end
    elseif spotted then
        -- Escalate
        if s.level == 0 then
            s.level = 1
            s.lastEscalateMin = nowMin
        elseif (nowMin - (s.lastEscalateMin or 0)) >= GRACE_MINUTES_PER_LEVEL then
            if s.level < 3 then
                s.level = s.level + 1
                s.lastEscalateMin = nowMin
                if s.level == 3 then
                    -- Trigger crime -> raise stars
                    if PZLifeWanted and PZLifeWanted.OnCrime then
                        PZLifeWanted.OnCrime(player, 1)
                    end
                end
            else
                -- Already level 3 — keep raising stars while still inside + spotted
                if PZLifeWanted and PZLifeWanted.OnSpotted then
                    PZLifeWanted.OnSpotted(player)
                end
            end
        end
    end

    if panel then
        panel:setVisible(s.level > 0)
    end
end

----------------------------------------------------------------------
-- Event wiring
----------------------------------------------------------------------

if Events and Events.OnPlayerUpdate then
    Events.OnPlayerUpdate.Add(function(player)
        if not player then return end
        local idx = player:getPlayerNum() or 0
        ensurePanel(idx)
        tick(player, idx)
    end)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        local n = getNumActivePlayers() or 1
        for i = 0, n - 1 do
            ensurePanel(i)
        end
        print("[PZLifeTrespass] loaded — text moodle active")
    end)
end

----------------------------------------------------------------------
-- Suppress the original BWOTrespass image moodle (if present)
----------------------------------------------------------------------

if BWOTrespassMoodle then
    -- Force-hide the moodle by overriding its update function
    local origUpdate = BWOTrespassMoodle.update
    function BWOTrespassMoodle:update()
        ISPanel.update(self)
        self:setVisible(false)
    end
end
