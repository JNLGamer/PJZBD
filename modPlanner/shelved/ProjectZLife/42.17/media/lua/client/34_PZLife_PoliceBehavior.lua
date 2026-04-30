-- ProjectZLife / 34_PZLife_PoliceBehavior.lua
-- M2 Phase 9: Police behavior tier — cuff/non-lethal/shoot-on-sight per wanted level.
-- (POLICE-01..02.)
--
-- WHAT: Modify how police NPCs respond to the player based on
-- PZLife.Wanted.read(player).stars:
--   ★    (1)  cuff — police approach to arrest (BUSTED path)
--   ★★   (2)  non-lethal first — still arrest, but use less force
--   ★★★  (3)  shoot on sight — unless player is unarmed (then 2★ treatment)
--   ★★★★ (4)  shoot to kill — WASTED catches via M2 P8
--   ★★★★★(5)  kill — no Wasted catch, real death (M2 P8 D-30 routes here)
--
-- HOW: Wraps the global `ZombiePrograms.Police` and `ZombiePrograms.SWAT`
-- entries (when present from Bandits + BWO) with a pre-decision check that
-- reads the player's wanted stars and ZEROS the targeting / hostility flags
-- on the bandit instance when the wanted level says "non-lethal."
--
-- The Bandits engine main loop calls each NPC's program.main(zombie) every
-- tick. By replacing main with a wrapper, we get a chance to override the
-- decision before the original runs. The wrapper:
--   1. Looks up the player from the zombie's brain (player follower / target)
--   2. Reads PZLife.Wanted.read(player).stars
--   3. For 1-2★: forces non-lethal — clears hostility, sets a short-range
--      "approach to cuff" task instead of letting the original program run
--   4. For 3-5★: lets the original program run (lethal targeting)
--   5. For 0★: lets the original program run (peacetime — they patrol/idle)
--
-- DEPENDENCIES (loaded via require=Bandits2,BanditsWeekOne):
--   * ZombiePrograms.Police, ZombiePrograms.SWAT (BWO ZPPolice.lua, ZPRiotPolice.lua)
--   * Bandit.SetHostile / Bandit.ClearTasks / Bandit.SetProgram (Bandits engine)
--   * BanditBrain.Get (Bandits engine)
--
-- DECISIONS LOGGED:
--   D-31 (M2 P9): Non-lethal "cuff" task is a synthetic placeholder for v1.
--     We just clear hostility; the actual cuff animation/teleport flow comes
--     when the cop gets within ~2 tiles, at which point M2 P8's BUSTED trigger
--     fires (low HP + 1-2★). Real cuff-pose logic = M3 P19+.
--   D-32 (M2 P9): Wraps both Police and SWAT programs identically. SWAT-tier
--     differentiation (more lethal at any star level) handled by underlying
--     ZP program; we only override at 1-2★.
--   D-33 (M2 P9): Hook installed at OnGameBoot — earliest possible point
--     where ZombiePrograms tables exist. Idempotency guard prevents
--     double-wrapping on save/reload.
--   D-34 (M2 P9): Unarmed → effective 2★ rule implemented as
--     `effectiveStars = max(stars, 2) when wielding weapon, else min(stars, 2)`
--     so 3★ + unarmed downgrades to non-lethal cuff path.

PZLife = PZLife or {}
PZLife.PoliceBehavior = PZLife.PoliceBehavior or {}

-- ── Helpers ─────────────────────────────────────────────────────────────────

local function getPlayerFromZombie(zombie)
    if not zombie then return nil end
    local brain = (BanditBrain and BanditBrain.Get and BanditBrain.Get(zombie)) or zombie.brain
    -- Fall back: just use the local player (singleplayer)
    return getPlayer()
end

local function isPlayerArmed(player)
    if not player then return false end
    local primary = player.getPrimaryHandItem and player:getPrimaryHandItem()
    local secondary = player.getSecondaryHandItem and player:getSecondaryHandItem()
    if primary and primary.getCategory and primary:getCategory() == "Weapon" then return true end
    if secondary and secondary.getCategory and secondary:getCategory() == "Weapon" then return true end
    return false
end

local function effectiveWantedStars(player)
    if not PZLife.Wanted or not PZLife.Wanted.read then return 0 end
    local w = PZLife.Wanted.read(player)
    local s = w.stars or 0
    -- D-34: unarmed at 3★ downgrades to 2★ treatment
    if s >= 3 and not isPlayerArmed(player) then return 2 end
    return s
end

-- ── Pre-decision: rewrite hostility on the bandit instance ──────────────────

local function applyTierOverride(zombie)
    local player = getPlayerFromZombie(zombie)
    if not player then return false end

    local stars = effectiveWantedStars(player)
    if stars == 0 then return false end

    -- 1-2★: non-lethal cuff path. Force clear hostility so the original
    -- program runs in patrol/approach mode rather than combat mode.
    if stars <= 2 then
        if Bandit and Bandit.SetHostile then
            local ok = pcall(function() Bandit.SetHostile(zombie, false) end)
            if ok and zombie.brain then
                zombie.brain.hostile = false
            end
        end
        return true  -- override applied
    end

    -- 3+★: let lethal targeting proceed (no override)
    return false
end

-- ── Program-wrap hook ───────────────────────────────────────────────────────

local function wrapProgram(programName)
    if not ZombiePrograms or not ZombiePrograms[programName] then return false end
    local prog = ZombiePrograms[programName]
    if not prog or type(prog.main) ~= "function" then return false end
    if prog.__pzlifeWrapped then return false end  -- idempotent

    local origMain = prog.main
    prog.main = function(zombie)
        applyTierOverride(zombie)
        return origMain(zombie)
    end
    prog.__pzlifeWrapped = true
    return true
end

local function installHooks()
    local wrapped = {}
    for _, name in ipairs({ "Police", "SWAT", "RiotPolice" }) do
        if wrapProgram(name) then
            wrapped[#wrapped + 1] = name
        end
    end
    if #wrapped > 0 then
        print(PZLife.LOG_TAG .. " PoliceBehavior: wrapped " .. table.concat(wrapped, ", "))
    else
        print(PZLife.LOG_TAG .. " PoliceBehavior: WARN — no Police/SWAT programs found in ZombiePrograms (BWO not loaded?)")
    end
end

-- ── Wiring ──────────────────────────────────────────────────────────────────

Events.OnGameBoot.Add(installHooks)
-- Defensive second attempt at OnGameStart in case BWO's programs register late
Events.OnGameStart.Add(installHooks)

print(PZLife.LOG_TAG .. " PoliceBehavior loaded (POLICE-01..02; wraps Police/SWAT/RiotPolice programs)")
