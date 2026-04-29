--[[
BanditStub — minimal API stubs so BWO and dependent mods can load without
the real Bandits NPC engine installed.

NOTE: This provides NO functionality. All NPC AI, combat, civilian
behaviors, etc. are silently no-op. The point is to let BWO's Lua files
LOAD without crashing on `attempt to index nil` errors during init, so
you can validate the rest of the patch-mod scaffold (chat pause, map
markers, trespassing moodle, wanted system, etc.) in isolation.

For real Bandits gameplay, install the actual Bandits NPC mod and disable
this dummy stub.

This file lives in `shared/` so it loads on both client and server contexts.
]]

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function stubFn() return nil end
local function stubFalse() return false end
local function stubZero() return 0 end
local function stubEmptyStr() return "" end
local function stubTable() return {} end

local function permissiveStringTable()
    return setmetatable({}, {__index = function() return "" end})
end

local function permissiveSoundTable()
    return setmetatable({}, {__index = function()
        return {prefix = "", chance = 0, randMax = 0, length = 0}
    end})
end

local function permissiveNumberTable()
    return setmetatable({}, {__index = function() return 0 end})
end

local function permissiveEmptyTarget()
    return {x = nil, y = nil, z = nil, dist = math.huge, id = nil}
end

------------------------------------------------------------
-- Bandit (core API)
------------------------------------------------------------

Bandit = Bandit or {}
Bandit.SoundTab = Bandit.SoundTab or permissiveSoundTable()
Bandit.SoundStopList = Bandit.SoundStopList or {}
Bandit.clanMap = Bandit.clanMap or permissiveStringTable()
Bandit.Expertise = Bandit.Expertise or permissiveNumberTable()
Bandit.VisualDamage = Bandit.VisualDamage or {Melee = {}, Gun = {}}
Bandit.Engine = false  -- signal to BWO that real engine is absent

-- No-op functions covering common BWO call sites
Bandit.HasExpertise = Bandit.HasExpertise or stubFalse
Bandit.IsHostile = Bandit.IsHostile or stubFalse
Bandit.SetHostile = Bandit.SetHostile or stubFn
Bandit.IsMoving = Bandit.IsMoving or stubFalse
Bandit.SetMoving = Bandit.SetMoving or stubFn
Bandit.Say = Bandit.Say or stubFn
Bandit.SayLocation = Bandit.SayLocation or stubFn
Bandit.GetWeapons = Bandit.GetWeapons or function() return {primary = {}, secondary = {}, melee = ""} end
Bandit.GetCombatWalktype = Bandit.GetCombatWalktype or function() return "Walk" end
Bandit.UpdateInfection = Bandit.UpdateInfection or stubFn
Bandit.ForceStationary = Bandit.ForceStationary or stubFn
Bandit.ForceSyncPart = Bandit.ForceSyncPart or stubFn
Bandit.ApplyVisuals = Bandit.ApplyVisuals or stubFn
Bandit.GetSkinTexture = Bandit.GetSkinTexture or function() return "MaleBody" end
Bandit.GetHairStyle = Bandit.GetHairStyle or function() return "Bald" end
Bandit.GetBeardStyle = Bandit.GetBeardStyle or stubFn
Bandit.GetHairColor = Bandit.GetHairColor or function() return {r = 0, g = 0, b = 0} end

------------------------------------------------------------
-- BanditUtils
------------------------------------------------------------

BanditUtils = BanditUtils or {}

BanditUtils.DistTo = BanditUtils.DistTo or function(x1, y1, x2, y2)
    local dx = (x2 or 0) - (x1 or 0)
    local dy = (y2 or 0) - (y1 or 0)
    return math.sqrt(dx * dx + dy * dy)
end

BanditUtils.DistToManhattan = BanditUtils.DistToManhattan or function(x1, y1, x2, y2)
    return math.abs((x2 or 0) - (x1 or 0)) + math.abs((y2 or 0) - (y1 or 0))
end

BanditUtils.GetMoveTask = BanditUtils.GetMoveTask or stubTable
BanditUtils.GetMoveTaskTarget = BanditUtils.GetMoveTaskTarget or stubTable
BanditUtils.GetTarget = BanditUtils.GetTarget or function() return permissiveEmptyTarget(), nil end
BanditUtils.GetClosestPlayerLocation = BanditUtils.GetClosestPlayerLocation or permissiveEmptyTarget
BanditUtils.GetClosestZombieLocation = BanditUtils.GetClosestZombieLocation or permissiveEmptyTarget
BanditUtils.GetClosestEnemyBanditLocation = BanditUtils.GetClosestEnemyBanditLocation or permissiveEmptyTarget
BanditUtils.LineClear = BanditUtils.LineClear or stubFalse
BanditUtils.HasZoneType = BanditUtils.HasZoneType or stubFalse
BanditUtils.GetGroundType = BanditUtils.GetGroundType or stubEmptyStr
BanditUtils.GetCharacterID = BanditUtils.GetCharacterID or stubEmptyStr
BanditUtils.IsController = BanditUtils.IsController or stubFalse
BanditUtils.Choice = BanditUtils.Choice or function(t) return t and t[1] or nil end
BanditUtils.AddPriceInflation = BanditUtils.AddPriceInflation or function(p) return math.floor(p or 0) end
BanditUtils.CalcAngle = BanditUtils.CalcAngle or stubZero
BanditUtils.ItemVisuals = BanditUtils.ItemVisuals or {}
BanditUtils.ModifyWeapon = BanditUtils.ModifyWeapon or function(w) return w end
BanditUtils.dec2rgb = BanditUtils.dec2rgb or function() return {r = 1, g = 1, b = 1} end

------------------------------------------------------------
-- BanditBrain
------------------------------------------------------------

BanditBrain = BanditBrain or {}
BanditBrain.Get = BanditBrain.Get or stubFn
BanditBrain.Update = BanditBrain.Update or stubFn
BanditBrain.Remove = BanditBrain.Remove or stubFn
BanditBrain.HasTask = BanditBrain.HasTask or stubFalse
BanditBrain.HasActionTask = BanditBrain.HasActionTask or stubFalse
BanditBrain.HasMoveTask = BanditBrain.HasMoveTask or stubFalse
BanditBrain.HasTaskType = BanditBrain.HasTaskType or stubFalse
BanditBrain.HasTaskTypes = BanditBrain.HasTaskTypes or stubFalse
BanditBrain.IsBareHands = BanditBrain.IsBareHands or function() return true end
BanditBrain.IsOutOfAmmo = BanditBrain.IsOutOfAmmo or function() return true end
BanditBrain.NeedResupplySlot = BanditBrain.NeedResupplySlot or stubFalse

------------------------------------------------------------
-- BanditCompatibility
------------------------------------------------------------

BanditCompatibility = BanditCompatibility or {}
BanditCompatibility.InstanceItem = BanditCompatibility.InstanceItem or stubFn
BanditCompatibility.GetBodyLocationsOrdered = BanditCompatibility.GetBodyLocationsOrdered or stubTable

------------------------------------------------------------
-- BanditPrograms
------------------------------------------------------------

BanditPrograms = BanditPrograms or {}
BanditPrograms.Weapon = BanditPrograms.Weapon or {
    Switch = stubTable, Aim = stubTable, Shoot = stubTable, Rack = stubTable,
}
BanditPrograms.Symptoms = BanditPrograms.Symptoms or stubTable
BanditPrograms.Events = BanditPrograms.Events or stubTable

------------------------------------------------------------
-- BanditZombie
------------------------------------------------------------

BanditZombie = BanditZombie or {}
BanditZombie.Cache = BanditZombie.Cache or {}
BanditZombie.CacheLight = BanditZombie.CacheLight or {}
BanditZombie.GetAll = BanditZombie.GetAll or stubTable
BanditZombie.GetAllB = BanditZombie.GetAllB or stubTable
BanditZombie.GetInstanceById = BanditZombie.GetInstanceById or stubFn

------------------------------------------------------------
-- BanditCustom / BanditPlayer / BanditPlayerBase
------------------------------------------------------------

BanditCustom = BanditCustom or {banditData = {}, clanData = {}, Save = stubFn}

BanditPlayer = BanditPlayer or {}
BanditPlayer.GetPlayerById = BanditPlayer.GetPlayerById or stubFn

BanditPlayerBase = BanditPlayerBase or {}
BanditPlayerBase.GetBaseClosest = BanditPlayerBase.GetBaseClosest or function() return nil, nil end
BanditPlayerBase.GetContainerClosest = BanditPlayerBase.GetContainerClosest or function() return nil, nil end
BanditPlayerBase.GetContainerWithItem = BanditPlayerBase.GetContainerWithItem or stubFn
BanditPlayerBase.GetFarm = BanditPlayerBase.GetFarm or stubFn

------------------------------------------------------------
-- ZombiePrograms / ZombieActions / RPC dispatchers
------------------------------------------------------------

ZombiePrograms = ZombiePrograms or {}
ZombieActions = ZombieActions or {}
BanditServer = BanditServer or {Commands = {}}
ZSClient = ZSClient or {Commands = {}}

------------------------------------------------------------
-- Server-side mod data accessors used by BWO
------------------------------------------------------------

local _bmd = {Posts = {}, Bases = {}, VisitedBuildings = {}, Kills = {}, Nukes = {}}
function GetBanditModData() return _bmd end
function TransmitBanditModData() end

local _clusters = {}
function GetBanditClusterData(id) _clusters[id] = _clusters[id] or {}; return _clusters[id] end
function TransmitBanditCluster() end

local _bwo = {Nukes = {}}
function GetBWOModData() return _bwo end

------------------------------------------------------------
-- Marker handler stub (so BanditMapMarkers' override has a target)
------------------------------------------------------------

BanditEventMarkerHandler = BanditEventMarkerHandler or {markers = {}, set = stubFn}

------------------------------------------------------------
-- BanditEventMarker class stub
------------------------------------------------------------

BanditEventMarker = BanditEventMarker or {
    iconSize = 96,
    clickableSize = 45,
    maxRange = 500,
    new = function() return {} end,
    render = stubFn,
    prerender = stubFn,
    update = stubFn,
}

print("[Bandits2Dummy] minimal Bandits API stubs loaded — BWO can load but features are no-op")
