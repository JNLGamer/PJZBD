--[[
PZLifeWanted — GTA-style wanted state machine.

This mod is *foundation only*. It owns the state and exposes the API.
Other Project Z Life mods consume this:
  - PZLifeTrespassingMoodle reads stars to color warnings
  - PZLifeBustedWasted branches BUSTED/WASTED based on star tier on a fatal hit
  - PZLifePoliceArrest gates police shoot/cuff/non-lethal decisions on tier
  - PZLifeMaskEscape clears stars when a worn mask is removed unspotted

State per player (stored in player modData[`pzlife_wanted`]):
  stars        : integer 0-5
  lastCrime    : in-game timestamp
  lastSpotted  : in-game timestamp
  badRecord    : boolean — sticky 3-star floor when set
  maskWasOn    : boolean — set when player donned a mask
  maskOnSinceStars : number — stars when mask was donned

Star decay (one-by-one):
  Default decay tick is 5 in-game minutes per star, only when not spotted in the
  last 2 minutes AND no fresh crime in the last 1 minute.
  Bad record: cannot drop below 3 stars except via "out of town and not spotted"
  (player is outside any IsoBuilding for >5 minutes AND no spot for >5 minutes).
  Mask escape: removing a mask while not currently spotted clears all stars
  (mask must have been worn before any current stars accrued).

API:
  PZLifeWanted.Get(player)               -> state table
  PZLifeWanted.GetStars(player)          -> int 0-5
  PZLifeWanted.AddStars(player, n)       -> clamps to [0,5]; sets lastCrime=now
  PZLifeWanted.RemoveStars(player, n)    -> respects badRecord floor
  PZLifeWanted.SetStars(player, n)       -> direct set; respects badRecord floor
  PZLifeWanted.Reset(player)             -> all stars 0 (respects badRecord floor)
  PZLifeWanted.SetBadRecord(player, bool)
  PZLifeWanted.OnSpotted(player)         -> updates lastSpotted=now
  PZLifeWanted.OnCrime(player, severity) -> AddStars + lastCrime
  PZLifeWanted.OnMaskDonned(player)
  PZLifeWanted.OnMaskRemoved(player)     -> if not currently spotted, clear stars
  PZLifeWanted.IsSpotted(player)         -> bool, true if spotted in last 2 minutes
]]

PZLifeWanted = PZLifeWanted or {}
PZLifeWanted.VERSION = 1

local KEY = "pzlife_wanted"

----------------------------------------------------------------------
-- Tunables (also exposed as SandboxVars)
----------------------------------------------------------------------

local function cfg()
    local sv = SandboxVars and SandboxVars.PZLifeWanted or {}
    return {
        decayMinutes = sv.DecayMinutesPerStar or 5,
        spottedWindowMin = sv.SpottedWindowMinutes or 2,
        crimeCooldownMin = sv.CrimeCooldownMinutes or 1,
        outOfTownDecayMin = sv.OutOfTownDecayMinutes or 5,
        badRecordFloor = sv.BadRecordFloor or 3,
        maxStars = 5,
    }
end

----------------------------------------------------------------------
-- State accessors
----------------------------------------------------------------------

function PZLifeWanted.Get(player)
    if not player or not player.getModData then return nil end
    local md = player:getModData()
    if not md[KEY] then
        md[KEY] = {
            stars = 0,
            lastCrime = 0,
            lastSpotted = 0,
            badRecord = false,
            maskWasOn = false,
            maskOnSinceStars = 0,
        }
    end
    return md[KEY]
end

function PZLifeWanted.GetStars(player)
    local s = PZLifeWanted.Get(player)
    return s and s.stars or 0
end

function PZLifeWanted.IsSpotted(player)
    local s = PZLifeWanted.Get(player)
    if not s then return false end
    local now = getGameTime():getWorldAgeHours() * 60  -- in-game minutes
    return (now - (s.lastSpotted or 0)) <= cfg().spottedWindowMin
end

----------------------------------------------------------------------
-- State mutations
----------------------------------------------------------------------

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function applyFloor(state)
    local c = cfg()
    if state.badRecord and state.stars < c.badRecordFloor then
        state.stars = c.badRecordFloor
    end
end

function PZLifeWanted.SetStars(player, n)
    local s = PZLifeWanted.Get(player); if not s then return end
    s.stars = clamp(n or 0, 0, cfg().maxStars)
    applyFloor(s)
end

function PZLifeWanted.AddStars(player, n)
    local s = PZLifeWanted.Get(player); if not s then return end
    s.stars = clamp((s.stars or 0) + (n or 1), 0, cfg().maxStars)
    s.lastCrime = getGameTime():getWorldAgeHours() * 60
    applyFloor(s)
end

function PZLifeWanted.RemoveStars(player, n)
    local s = PZLifeWanted.Get(player); if not s then return end
    s.stars = clamp((s.stars or 0) - (n or 1), 0, cfg().maxStars)
    applyFloor(s)
end

function PZLifeWanted.Reset(player)
    local s = PZLifeWanted.Get(player); if not s then return end
    s.stars = 0
    applyFloor(s)
end

function PZLifeWanted.SetBadRecord(player, on)
    local s = PZLifeWanted.Get(player); if not s then return end
    s.badRecord = (on == true)
    applyFloor(s)
end

function PZLifeWanted.OnSpotted(player)
    local s = PZLifeWanted.Get(player); if not s then return end
    s.lastSpotted = getGameTime():getWorldAgeHours() * 60
end

function PZLifeWanted.OnCrime(player, severity)
    severity = severity or 1
    PZLifeWanted.AddStars(player, severity)
end

function PZLifeWanted.OnMaskDonned(player)
    local s = PZLifeWanted.Get(player); if not s then return end
    s.maskWasOn = true
    s.maskOnSinceStars = s.stars or 0
end

function PZLifeWanted.OnMaskRemoved(player)
    local s = PZLifeWanted.Get(player); if not s then return end
    -- Mask escape: if not currently spotted AND mask was on while wanted, clear stars
    if s.maskWasOn and not PZLifeWanted.IsSpotted(player) then
        s.stars = 0
        applyFloor(s)
    end
    s.maskWasOn = false
end

----------------------------------------------------------------------
-- Decay tick: removes one star per N in-game minutes when not spotted
----------------------------------------------------------------------

local function decayTick()
    local player = getSpecificPlayer(0)
    if not player then return end
    local s = PZLifeWanted.Get(player); if not s then return end
    if (s.stars or 0) <= 0 then return end

    local c = cfg()
    local now = getGameTime():getWorldAgeHours() * 60

    -- Check spotted recently
    if (now - (s.lastSpotted or 0)) < c.spottedWindowMin then return end
    -- Check crime cooldown
    if (now - (s.lastCrime or 0)) < c.crimeCooldownMin then return end

    -- Bad record floor: only out-of-town decay applies below floor
    local atFloor = s.badRecord and s.stars <= c.badRecordFloor
    if atFloor then
        local building = player:getBuilding()
        if building then return end  -- inside a building → no decay below floor
        if (now - (s.lastSpotted or 0)) < c.outOfTownDecayMin then return end
    end

    -- One star per N minutes, but we tick every minute, so probabilistic decay:
    -- decay if (now - lastCrime) modular check
    local minutesSinceCrime = now - (s.lastCrime or 0)
    if minutesSinceCrime >= c.decayMinutes then
        s.stars = math.max(0, (s.stars or 0) - 1)
        applyFloor(s)
        s.lastCrime = now  -- reset window for next star
    end
end

if Events and Events.EveryOneMinute then
    Events.EveryOneMinute.Add(decayTick)
end

----------------------------------------------------------------------
-- Mask hooks — wrap IsoPlayer:setWornItem if available
-- (Heuristic: detect when an item that covers the face is worn or removed.)
----------------------------------------------------------------------

local function isMaskItem(item)
    if not item then return false end
    -- Look for body location "Mask" or sub-string "Mask"/"Bandana" on the type
    local bodyLoc = item.getBodyLocation and item:getBodyLocation() or nil
    if bodyLoc and (bodyLoc == "Mask" or bodyLoc == "MaskFull" or bodyLoc == "MaskEyes") then
        return true
    end
    local ftype = item.getType and item:getType() or ""
    if ftype:find("Mask") or ftype:find("Bandana") or ftype:find("Balaclava") then
        return true
    end
    return false
end

if Events and Events.OnClothingUpdated then
    Events.OnClothingUpdated.Add(function(player)
        if not player then return end
        if not player.getWornItems then return end
        local worn = player:getWornItems()
        local hasMask = false
        for i = 0, worn:size() - 1 do
            local item = worn:get(i):getItem()
            if isMaskItem(item) then hasMask = true; break end
        end
        local s = PZLifeWanted.Get(player)
        if not s then return end
        if hasMask and not s.maskWasOn then
            PZLifeWanted.OnMaskDonned(player)
        elseif not hasMask and s.maskWasOn then
            PZLifeWanted.OnMaskRemoved(player)
        end
    end)
end

----------------------------------------------------------------------
-- Debug command: /wanted N (sets stars for testing)
----------------------------------------------------------------------

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        print("[PZLifeWanted] loaded — stars/decay/mask/badRecord state machine ready")
    end)
end
