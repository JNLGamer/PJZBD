-- Sanity_traits / 10_SanityTraits_DespairActions.lua
-- Phase 7: ISBaseTimedAction subclasses for gun and sharp-object despair methods,
--          plus SanityTraits.applyInterruptedSHEffects.
-- Loaded last (numeric prefix "10_"); consumes SanityTraits.* from 1_-9_*.lua.

-- ── ISSTDespairGunAction ──────────────────────────────────────────────────────
-- Requires a loaded ranged weapon in the primary hand.
-- Hollow: ~200-tick hesitation so the player can still cancel by moving.
-- Numb / Broken: 1 tick (near-instant; no window to change mind).
ISSTDespairGunAction = ISBaseTimedAction:derive("ISSTDespairGunAction")

function ISSTDespairGunAction:new(character, withHesitation)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self
    o.stopOnWalk = true
    o.stopOnRun  = true
    -- ~200 ticks ≈ 6-7 seconds at normal game speed (tune in-game if needed)
    o.maxTime    = withHesitation and 200 or 1
    return o
end

function ISSTDespairGunAction:isValid()
    local weapon = self.character:getPrimaryHandItem()
    return weapon ~= nil
        and weapon.IsWeapon and weapon:IsWeapon()
        and weapon.isRanged and weapon:isRanged()
        and weapon.getCurrentAmmoCount and weapon:getCurrentAmmoCount() > 0
end

function ISSTDespairGunAction:perform()
    -- Apply health=0 to trigger the vanilla death sequence
    self.character:getBodyDamage():setHealth(0)
    ISBaseTimedAction.perform(self)
end

-- ── ISSTDespairSharpAction ────────────────────────────────────────────────────
-- Requires a sharp item in the inventory; always ~240 ticks so the player can
-- stop in time at every stage.
-- perform() = completed = lethal.
-- stop()    = cancelled/interrupted = non-lethal SH effects + cooldown.
--
-- _completed flag: ISBaseTimedAction.perform() calls stopAction() internally,
-- which fires stop(). Without this guard a successful action would ALSO apply
-- the interrupt effects. The flag lets stop() know which path fired.
ISSTDespairSharpAction = ISBaseTimedAction:derive("ISSTDespairSharpAction")

function ISSTDespairSharpAction:new(character, sharpItem)
    local o = ISBaseTimedAction.new(self, character)
    setmetatable(o, self)
    self.__index = self
    o.stopOnWalk  = true
    o.stopOnRun   = true
    o.maxTime     = 240   -- ~8 seconds; tune in-game if needed
    o.sharpItem   = sharpItem
    o._completed  = false
    return o
end

function ISSTDespairSharpAction:isValid()
    if not SanityTraits.canSHAgain(self.character) then return false end
    return self.character:getInventory():contains(self.sharpItem)
end

function ISSTDespairSharpAction:perform()
    self._completed = true
    self.character:getBodyDamage():setHealth(0)
    ISBaseTimedAction.perform(self)
end

function ISSTDespairSharpAction:stop()
    if self._completed then return end   -- action completed normally; skip interrupt effects
    SanityTraits.applyInterruptedSHEffects(self.character)
    ISBaseTimedAction.stop(self)
end

-- ── applyInterruptedSHEffects ─────────────────────────────────────────────────
-- Called when a sharp-object attempt is cancelled mid-action.
-- Raises pain / unhappy / stress moodles, applies a sanity penalty,
-- and sets the 24-hour cooldown. Does NOT kill the player.
function SanityTraits.applyInterruptedSHEffects(player)
    if not player then return end
    local md = player:getModData().SanityTraits
    if not md then return end

    -- Set cooldown
    md.lastSHTime = getGameTime():getWorldAgeHours()

    -- Raise moodles (clamped to 4)
    local moodles = player:getMoodles()
    local function raise(moodleType, by)
        local cur = moodles:getMoodleLevel(moodleType) or 0
        moodles:setMoodleLevel(moodleType, math.min(4, cur + by))
    end
    raise(MoodleType.PAIN,    2)
    raise(MoodleType.UNHAPPY, 2)
    raise(MoodleType.STRESS,  1)

    -- Sanity penalty: the attempt itself worsens the mental state
    local penalty = 30
    md.sanity = math.max(SanityTraits.SANITY_MIN, (md.sanity or 0) - penalty)
    SanityTraits.evaluateStageTransitions(player)

    print(SanityTraits.LOG_TAG .. " [Despair] SH interrupted: moodles raised, -"
        .. penalty .. " sanity=" .. tostring(md.sanity)
        .. ", cooldown set at " .. string.format("%.2f", md.lastSHTime) .. "h")
end

print(SanityTraits.LOG_TAG .. " DespairActions loaded: ISSTDespairGunAction + ISSTDespairSharpAction")
