--[[
BanditCivilDecorum — caps how many NPCs may react to the same incident.

Symptom this fixes: every gardener / janitor / civilian in earshot runs to
the same corpse / protest / barbecue, creating an obvious "the world is
staged for the player" feel. By capping reactor count within a radius
of any reported target, NPCs out past the cap silently look elsewhere.

Patches:
  BWOObjects.FindDeadBody(bandit)         → wrap with cap
  BWOObjects.FindGMD(bandit, type)        → wrap with cap

The wrap counts how many bandits in BanditZombie.CacheLight are within
the cap radius of the target's (x, y, z). If count >= cap, returns the
"empty target" pattern Bandits already understands: {x=nil, y=nil, z=nil}.

Cap and radius are configurable via SandboxVars.BanditCivilDecorum.*
(declared in sandbox-options.txt). Defaults are conservative:
  cap=4 reactors per incident
  radius=8 tiles
]]

if not BWOObjects then
    print("[BanditCivilDecorum] BWOObjects not found — BWO not loaded? Skipping patch.")
    return
end

BanditCivilDecorum = BanditCivilDecorum or {}

local function getConfig()
    local sv = SandboxVars and SandboxVars.BanditCivilDecorum or nil
    return {
        cap = (sv and sv.MassGatherCap) or 4,
        radius = (sv and sv.MassGatherRadius) or 8,
    }
end

-- Count bandits/zombies near a world coordinate.
-- Uses BanditZombie.CacheLight (pos-only cache maintained by Bandits engine)
-- to avoid expensive per-tick world scans.
local function countReactorsNear(tx, ty, tz, radius)
    if not BanditZombie or not BanditZombie.CacheLight then return 0 end
    local r2 = radius * radius
    local count = 0
    for _, czombie in pairs(BanditZombie.CacheLight) do
        if czombie.z == tz then
            local dx = czombie.x - tx
            local dy = czombie.y - ty
            if (dx * dx) + (dy * dy) <= r2 then
                count = count + 1
            end
        end
    end
    return count
end

local function emptyTarget()
    return {x = nil, y = nil, z = nil}
end

-- Patch FindDeadBody
if BWOObjects.FindDeadBody then
    BanditCivilDecorum.OriginalFindDeadBody = BanditCivilDecorum.OriginalFindDeadBody or BWOObjects.FindDeadBody
    BWOObjects.FindDeadBody = function(bandit, ...)
        local target = BanditCivilDecorum.OriginalFindDeadBody(bandit, ...)
        if not target or not target.x or not target.y then return target end
        local cfg = getConfig()
        local count = countReactorsNear(target.x, target.y, target.z or 0, cfg.radius)
        if count >= cfg.cap then
            return emptyTarget()
        end
        return target
    end
end

-- Patch FindGMD (general game-mod-data finder; covers protest, trash, mailbox, barbecue, etc.)
if BWOObjects.FindGMD then
    BanditCivilDecorum.OriginalFindGMD = BanditCivilDecorum.OriginalFindGMD or BWOObjects.FindGMD
    BWOObjects.FindGMD = function(bandit, gmdType, ...)
        local target = BanditCivilDecorum.OriginalFindGMD(bandit, gmdType, ...)
        if not target or not target.x or not target.y then return target end
        -- Don't cap utility tasks like "trash" or "mailbox" too aggressively —
        -- those need someone to handle them. Only cap "social" gatherings.
        local SOCIAL_TYPES = {protest = true, barbecue = true, party = true}
        if not SOCIAL_TYPES[gmdType] then return target end
        local cfg = getConfig()
        local count = countReactorsNear(target.x, target.y, target.z or 0, cfg.radius)
        if count >= cfg.cap then
            return emptyTarget()
        end
        return target
    end
end

print("[BanditCivilDecorum] loaded — capping reactor count at incidents (cap=" ..
      getConfig().cap .. ", radius=" .. getConfig().radius .. ")")
