--[[
PZLifeBustedWasted — arrest path for the Project Z Life wanted system.

Star-tier branching (per user spec):
  1-2 stars or 3 unarmed: police cuff player -> BUSTED -> jail -> released in 1hr
  3 armed / 4 stars      : police shoot -> WASTED-style -> hospital (existing Wasted mod handles)
  5 stars                : real death (this mod does NOT intervene)

Trigger: monitors player HP. When hitting BUSTED-eligible threshold while a
nearby attacker has police-clan brain.cid, intercept the damage and route to
the BUSTED transition instead of letting Wasted handle it.

Transition pattern (mirrors the existing Wasted.lua mechanism):
  UIManager.setFadeBeforeUI(playerNum, true) + FadeOut(1)
  Teleport player to nearest jail tile
  player:setGhostMode(true) during transit
  player:setBannedAttacking(true) + setBlockMovement(true)
  Show "BUSTED" text overlay (text-rendered, no texture asset needed)
  Schedule release at gameTime + 1 hour

Release pattern:
  FadeOut, teleport back to a civilian-safe coord (player's pre-arrest spot),
  Clear ghost/banned/blocked state, FadeIn,
  PZLifeWanted.RemoveStars(player, all)
]]

if not PZLifeWanted then
    print("[PZLifeBustedWasted] PZLifeWanted not loaded — depend on PZLifeWantedSystem")
    return
end

PZLifeBustedWasted = PZLifeBustedWasted or {}
PZLifeBustedWasted.DEBUG = false

local KEY = "pzlife_jail"

----------------------------------------------------------------------
-- Hardcoded jail coordinates (vanilla police stations + BWO additions).
-- Coords inferred from BWO's wastedLocations style. Approximate.
----------------------------------------------------------------------

local JAIL_LOCATIONS = {
    {x = 12858, y = 2173,   name = "Louisville PD"},
    {x = 11919, y = 6904,   name = "West Point PD"},
    {x = 10828, y = 9772,   name = "Muldraugh PD"},
    {x = 8085,  y = 11423,  name = "Rosewood Jail"},
    {x = 10095, y = 12698,  name = "March Ridge PD"},
}

local function nearestJail(x, y)
    local best, bestD = JAIL_LOCATIONS[1], math.huge
    for _, loc in ipairs(JAIL_LOCATIONS) do
        local dx, dy = loc.x - x, loc.y - y
        local d = dx * dx + dy * dy
        if d < bestD then best, bestD = loc, d end
    end
    return best
end

----------------------------------------------------------------------
-- Police-clan attacker detection
----------------------------------------------------------------------

local POLICE_CLAN_NAMES = {
    "PoliceBlue", "PoliceGray", "PoliceRiot", "SWAT", "PrisonGuard",
}

local policeClanIds = nil
local function getPoliceClanIds()
    if policeClanIds then return policeClanIds end
    policeClanIds = {}
    if Bandit and Bandit.clanMap then
        for _, name in ipairs(POLICE_CLAN_NAMES) do
            local id = Bandit.clanMap[name]
            if id and id ~= "" then policeClanIds[id] = true end
        end
    end
    return policeClanIds
end

local function nearestPoliceAttackerWithin(player, radius)
    local px, py, pz = player:getX(), player:getY(), player:getZ()
    if not BanditZombie or not BanditZombie.CacheLight then return nil end
    local r2 = radius * radius
    local clans = getPoliceClanIds()
    local best, bestD = nil, math.huge
    for bid, c in pairs(BanditZombie.CacheLight) do
        if c.z == pz then
            local dx, dy = c.x - px, c.y - py
            local d = dx * dx + dy * dy
            if d <= r2 and d < bestD then
                local zombie = BanditZombie.GetInstanceById and BanditZombie.GetInstanceById(bid) or nil
                if zombie and BanditBrain then
                    local b = BanditBrain.Get(zombie)
                    if b and b.clan and clans[b.clan] then
                        best, bestD = zombie, d
                    end
                end
            end
        end
    end
    return best
end

----------------------------------------------------------------------
-- BUSTED text overlay (no texture asset needed)
----------------------------------------------------------------------

require "ISUI/ISUIElement"

PZLifeBustedOverlay = ISUIElement:derive("PZLifeBustedOverlay")

function PZLifeBustedOverlay:new(text, durationMs)
    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    local o = ISUIElement:new(0, 0, screenW, screenH)
    setmetatable(o, self)
    self.__index = self
    o.text = text or "BUSTED"
    o.startMs = getTimeInMillis()
    o.durationMs = durationMs or 3000
    o.bConsumeMouseEvents = false
    return o
end

function PZLifeBustedOverlay:initialise()
    ISUIElement.initialise(self)
    self:addToUIManager()
end

function PZLifeBustedOverlay:render()
    local elapsed = getTimeInMillis() - self.startMs
    if elapsed > self.durationMs then
        self:setVisible(false); self:removeFromUIManager(); return
    end
    local alpha = 1
    if elapsed < 200 then alpha = elapsed / 200
    elseif elapsed > self.durationMs - 600 then alpha = (self.durationMs - elapsed) / 600 end

    local screenW = getCore():getScreenWidth()
    local screenH = getCore():getScreenHeight()
    -- Big red text centered
    local font = UIFont.Title
    local th = getTextManager():getFontHeight(font)
    local tw = getTextManager():MeasureStringX(font, self.text)
    self:drawRect(0, screenH/2 - th/2 - 24, screenW, th + 48, alpha * 0.6, 0, 0, 0)
    self:drawText(self.text, (screenW - tw) / 2, screenH/2 - th/2, 1, 0.1, 0.1, alpha, font)
end

function PZLifeBustedOverlay:prerender() end

----------------------------------------------------------------------
-- BUSTED transition (fade -> teleport -> hold -> release in 1hr)
----------------------------------------------------------------------

local function startBusted(player)
    local playerNum = player:getPlayerNum() or 0
    local md = player:getModData()
    if md[KEY] and md[KEY].active then return end  -- already in BUSTED state

    local px, py = player:getX(), player:getY()
    local jail = nearestJail(px, py)

    md[KEY] = {
        active = true,
        startedAt = getGameTime():getWorldAgeHours() * 60,
        releaseAt = getGameTime():getWorldAgeHours() * 60 + 60,  -- +1 in-game hour
        returnX = px,
        returnY = py,
        jailX = jail.x,
        jailY = jail.y,
        jailName = jail.name,
        phase = "fadeout",
        phaseStartedMs = getTimeInMillis(),
    }

    -- Heal so player doesn't die from residual damage
    pcall(function() player:getBodyDamage():AddGeneralHealth(80.0) end)
    pcall(function() player:StopBurning() end)

    -- Lockout
    pcall(function() player:setBannedAttacking(true) end)
    pcall(function() player:setBlockMovement(true) end)
    pcall(function() player:setGhostMode(true) end)

    -- Fade to black
    pcall(function() UIManager.setFadeBeforeUI(playerNum, true) end)
    pcall(function() UIManager.FadeOut(playerNum, 1) end)

    -- Show overlay
    local overlay = PZLifeBustedOverlay:new("BUSTED", 3000)
    overlay:initialise()

    -- Chat
    pcall(function()
        player:addLineChatElement("You're under arrest. Taken to " .. (jail.name or "jail") .. ".", 1, 0.5, 0.5)
    end)

    print("[PZLifeBustedWasted] BUSTED — teleporting to " .. (jail.name or "jail"))
end

local function tickBusted(player)
    local md = player:getModData()
    local s = md[KEY]
    if not s or not s.active then return end

    local playerNum = player:getPlayerNum() or 0
    local nowMs = getTimeInMillis()
    local nowMin = getGameTime():getWorldAgeHours() * 60

    if s.phase == "fadeout" and (nowMs - s.phaseStartedMs) >= 1000 then
        -- Teleport to jail cell
        pcall(function()
            player:setX(s.jailX); player:setY(s.jailY); player:setZ(0)
            player:setLx(s.jailX); player:setLy(s.jailY); player:setLz(0)
            getWorld():update()
        end)
        pcall(function() UIManager.FadeIn(playerNum, 1) end)
        s.phase = "incarcerated"
        s.phaseStartedMs = nowMs

    elseif s.phase == "incarcerated" then
        -- Player is in jail. Wait for release time.
        if nowMin >= (s.releaseAt or 0) then
            s.phase = "releasing"
            s.phaseStartedMs = nowMs
            pcall(function() UIManager.setFadeBeforeUI(playerNum, true) end)
            pcall(function() UIManager.FadeOut(playerNum, 1) end)
            local overlay = PZLifeBustedOverlay:new("RELEASED", 2500)
            overlay:initialise()
        end

    elseif s.phase == "releasing" and (nowMs - s.phaseStartedMs) >= 1000 then
        -- Teleport back
        pcall(function()
            player:setX(s.returnX); player:setY(s.returnY); player:setZ(0)
            player:setLx(s.returnX); player:setLy(s.returnY); player:setLz(0)
            getWorld():update()
        end)
        pcall(function() UIManager.FadeIn(playerNum, 1) end)
        pcall(function() UIManager.setFadeBeforeUI(playerNum, false) end)
        s.phase = "freeing"
        s.phaseStartedMs = nowMs

    elseif s.phase == "freeing" and (nowMs - s.phaseStartedMs) >= 1000 then
        -- Restore controls, clear stars, clear state
        pcall(function() player:setGhostMode(false) end)
        pcall(function() player:setBannedAttacking(false) end)
        pcall(function() player:setBlockMovement(false) end)
        if PZLifeWanted and PZLifeWanted.Reset then
            PZLifeWanted.Reset(player)
        end
        pcall(function()
            player:addLineChatElement("Released. You're free to go.", 0.6, 1, 0.6)
        end)
        md[KEY] = nil
        print("[PZLifeBustedWasted] released from jail")
    end
end

----------------------------------------------------------------------
-- HP-watch trigger
----------------------------------------------------------------------

local function isArmed(player)
    local primary = player:getPrimaryHandItem()
    if primary and primary.IsWeapon and primary:IsWeapon() then return true end
    local secondary = player:getSecondaryHandItem()
    if secondary and secondary.IsWeapon and secondary:IsWeapon() then return true end
    return false
end

local TRIGGER_HP = 0.30  -- BUSTED triggers at this HP (similar to Wasted's MinimumHP)

local function onPlayerUpdate(player)
    if not player or player:isDead() then return end
    local md = player:getModData()

    -- If already in BUSTED state, run state machine and stop
    if md[KEY] and md[KEY].active then
        tickBusted(player)
        return
    end

    -- Don't intervene if player is at full health-ish
    local hp = player:getBodyDamage():getHealth()
    if hp > TRIGGER_HP then return end

    -- Only trigger when stars warrant arrest path (1-3) and unarmed for tier 3
    local stars = PZLifeWanted.GetStars(player) or 0
    if stars < 1 or stars >= 4 then return end  -- 4-5 → let Wasted/death handle
    if stars == 3 and isArmed(player) then return end  -- armed at 3 → shoot path

    -- Need a police attacker nearby to actually be the cause
    local cop = nearestPoliceAttackerWithin(player, 6)
    if not cop then return end

    startBusted(player)
end

if Events and Events.OnPlayerUpdate then
    Events.OnPlayerUpdate.Add(onPlayerUpdate)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        print("[PZLifeBustedWasted] loaded — arrest path active for stars 1-3 unarmed")
    end)
end
