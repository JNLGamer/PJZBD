-- Sanity_traits / 6_SanityTraits_TimedDecay.lua
-- Phase 3 / Plan 02: Passive timed decay + contentment-gated recovery + sleep-bonus
-- edge-detection + daily-bonus-cap reset.
-- Loaded after 1_*.lua through 5_*.lua per numeric prefix order; consumes
-- SanityTraits.DECAY_RATE_BY_STAGE / RECOVERY_RATE_BY_STAGE / GOOD_EVENT_BONUS /
-- GOOD_EVENT_DAILY_CAP (Plan 03-01), SanityTraits.bumpCounter (Phase 01.2),
-- SanityTraits.isSystemDisabled + SanityTraits.evaluateStageTransitions (Phase 02).
--
-- Decisions honored:
--   D-36 (off-switch) — isSystemDisabled gate at top of every entry-point handler
--   D-37 (no clamping) — only math.max(SANITY_MIN, ...) and math.min(SANITY_MAX, ...)
--   D-43 (Events.EveryTenMinutes) — confirmed reference/events.md:45
--   D-44 (decay rates 1/2/3/4 by stage) — table read via computeStage
--   D-45 (recovery rates 1/2/2/2 + multi-moodle contentment gate) — UNHAPPY=0, STRESS<3, BORED<3, PANIC=0
--   D-46 (sleep edge-detect, no time-multiplier compensation, defensive guards)
--   D-47 (auto-vivified counters, bump-per-event cadence, silent ticks bump nothing)
--
-- Pitfall mitigations:
--   #1 silent ticks — `if sanity ~= before then ... end` brackets every counter+print+evaluator block
--   #2 BORED enum — using MoodleType.BORED (not BOREDOM); verified Translate/EN/Moodles.json:38-41
--   #4 nil player — `if not player then return end` after getPlayer()
--   #6 sleep flicker — lastSleepBonusGameDay caps sleep bonus to 1 per in-game day
--   #8 sleep accelerated time — accepted; no special-case path; sleptSafe bonus + sustained recovery
--                                during sleep nets positive at Stable, negative at Numb (D-46 / D-37)

-- ── applyBonusEvent: shared helper called by sleep edge-detect (this file) and by ──
-- the eat/read monkey-patches in Plan 03-03. Cap-aware; bumps counter ALWAYS;
-- adds sanity only while under cap. Defensive day-mismatch reset belt-and-suspenders
-- with Events.EveryDays handler below.
function SanityTraits.applyBonusEvent(player, eventType)
    -- Caller has verified: D-36 not disabled, ModData seeded, "safe" qualifier (e.g. PANIC=0 for sleep).
    local md = player:getModData().SanityTraits
    if not md then return end
    local currentDay = getGameTime():getDay()

    -- Cap-window reset (defensive; Events.EveryDays also resets — covers save/load spanning a day)
    if (md.lastBonusDay or -1) ~= currentDay then
        md.dailyBonusUsed = 0
        md.lastBonusDay = currentDay
    end

    local remaining = SanityTraits.GOOD_EVENT_DAILY_CAP - (md.dailyBonusUsed or 0)
    local awarded   = math.min(SanityTraits.GOOD_EVENT_BONUS, math.max(0, remaining))

    if awarded > 0 then
        local before = md.sanity
        md.sanity = math.min(SanityTraits.SANITY_MAX, before + awarded)
        md.dailyBonusUsed = (md.dailyBonusUsed or 0) + awarded
        print(SanityTraits.LOG_TAG .. " bonus[" .. eventType .. "]: +" .. tostring(awarded)
            .. " sanity=" .. tostring(before) .. " -> " .. tostring(md.sanity)
            .. " (capUsed=" .. tostring(md.dailyBonusUsed) .. "/" .. tostring(SanityTraits.GOOD_EVENT_DAILY_CAP) .. ")")
    else
        print(SanityTraits.LOG_TAG .. " bonus[" .. eventType .. "]: cap reached, +0 sanity")
    end

    -- ALWAYS bump counter (records activity even when capped) — D-47 cadence
    SanityTraits.bumpCounter("recoveries.fromGoodEvents." .. eventType, awarded)
    -- ALWAYS call evaluator (might cross the +50 hysteresis on the way up — D-39 stack-pop)
    SanityTraits.evaluateStageTransitions(player)
end

-- ── applyTimedSanityChange: the single EveryTenMinutes handler. ───────────────
-- Order: D-36 gate -> ModData guard -> sleep wake edge-detect -> decay pass
-- -> recovery pass (contentment-gated). One sanity mutation per pass; evaluator
-- called only when sanity actually moved (Pitfall 1).
function SanityTraits.applyTimedSanityChange(player)
    if not player then return end                                  -- Pitfall 4
    if SanityTraits.isSystemDisabled(player) then return end       -- D-36
    local md = player:getModData()
    if not md.SanityTraits then return end                         -- Phase 1 defensive guard

    local sanity   = md.SanityTraits.sanity
    local stageKey = SanityTraits.computeStage(sanity)

    -- ── Sleep wake edge-detect (D-46 + Pitfall 6) ──
    -- Fires the sleptSafe bonus on the false transition of player:isAsleep().
    -- "Safe" qualifier: PANIC moodle == 0 at wake (didn't wake to zombies).
    -- Capped to once per in-game day via lastSleepBonusGameDay (Pitfall 6).
    local nowAsleep = player:isAsleep()
    if md.SanityTraits.wasAsleep and not nowAsleep then
        if player:getMoodles():getMoodleLevel(MoodleType.PANIC) == 0 then
            local currentDay = getGameTime():getDay()
            if (md.SanityTraits.lastSleepBonusGameDay or -1) < currentDay then
                SanityTraits.applyBonusEvent(player, "sleptSafe")
                md.SanityTraits.lastSleepBonusGameDay = currentDay
                -- applyBonusEvent mutated md.SanityTraits.sanity; re-read for downstream branches
                sanity   = md.SanityTraits.sanity
                stageKey = SanityTraits.computeStage(sanity)
            end
        end
    end
    md.SanityTraits.wasAsleep = nowAsleep

    -- ── Distress signals from vanilla state (Phase 8) ──
    -- Read pain/panic/stress/unhappy moodles + current health + health-delta since last
    -- tick. These produce additional per-tick decay on top of the per-stage base rate.
    -- Verified API: player:getMoodles():getMoodleLevel(MoodleType.X) — vanilla pattern at
    -- ISHealthPanel.lua:460, ISVehicleMenu.lua:213, etc. Levels are 0..4.
    -- Verified API: player:getBodyDamage():getHealth() — returns 0..100, vanilla at
    -- ISHealthPanel.lua:441 ("InjuryRedTextTint = (100 - getHealth()) / 100").
    local moodles = player:getMoodles()
    local painLvl    = moodles:getMoodleLevel(MoodleType.PAIN)
    local panicLvl   = moodles:getMoodleLevel(MoodleType.PANIC)
    local stressLvl  = moodles:getMoodleLevel(MoodleType.STRESS)
    local unhappyLvl = moodles:getMoodleLevel(MoodleType.UNHAPPY)
    local currentHP  = player:getBodyDamage():getHealth() or 100

    local distress = 0
    distress = distress + painLvl    * SanityTraits.PAIN_DECAY_PER_LEVEL
    distress = distress + panicLvl   * SanityTraits.PANIC_DECAY_PER_LEVEL
    distress = distress + stressLvl  * SanityTraits.STRESS_DECAY_PER_LEVEL
    distress = distress + unhappyLvl * SanityTraits.UNHAPPY_DECAY_PER_LEVEL
    if currentHP < SanityTraits.LOW_HEALTH_THRESHOLD then
        distress = distress + SanityTraits.LOW_HEALTH_DECAY
    end

    -- Health-delta acute injury: sanity loss proportional to HP dropped this tick.
    -- Catches damage from any source (zombies, bleed, fall, infection, etc) without
    -- needing a dedicated event hook. Stored in ModData per-character.
    local lastHP    = md.SanityTraits.lastHealth or currentHP
    local hpLost    = lastHP - currentHP
    local acuteHurt = (hpLost > 0) and math.floor(hpLost * SanityTraits.HEALTH_DAMAGE_RATIO + 0.5) or 0
    md.SanityTraits.lastHealth = currentHP

    -- ── Decay pass (D-44 + Phase 8 distress; profile-aware per Phase 4 / Plan 03 OCC-01) ──
    -- HARDENED 0.7x base rate slows; FRAGILE 1.3x speeds up. Distress + acuteHurt are
    -- NOT scaled by profession multiplier — a hardened veteran still bleeds at the same
    -- rate as anyone else; their advantage is the calmer baseline, not pain immunity.
    -- broken stage absent from DECAY_RATE_BY_STAGE -> getEffectiveDecayRate returns 0.
    local baseDecay   = SanityTraits.getEffectiveDecayRate(player, stageKey)
    local totalDecay  = baseDecay + distress + acuteHurt
    if totalDecay > 0 and sanity > SanityTraits.SANITY_MIN then
        local before = sanity
        sanity = math.max(SanityTraits.SANITY_MIN, before - totalDecay)
        if sanity ~= before then                                   -- Pitfall 1: silent tick = no bump
            md.SanityTraits.sanity = sanity
            print(SanityTraits.LOG_TAG .. " decay tick: base=" .. tostring(baseDecay)
                .. " distress=" .. tostring(distress)
                .. " acute=" .. tostring(acuteHurt)
                .. " total=" .. tostring(totalDecay)
                .. " (" .. stageKey .. ") sanity=" .. tostring(before)
                .. " -> " .. tostring(sanity))
            SanityTraits.bumpCounter("decay.timedTicks", -totalDecay)
            SanityTraits.evaluateStageTransitions(player)
            -- Evaluator may have descended; refresh stageKey + sanity for the recovery pass
            sanity   = md.SanityTraits.sanity
            stageKey = SanityTraits.computeStage(sanity)
        end
    end

    -- ── Recovery pass (D-45 contentment gate + Phase 8 distress block) ──
    -- Original contentment gate: UNHAPPY=0 AND STRESS<3 AND BORED<3 AND PANIC=0
    -- Phase 8 additions: pain at any meaningful level OR low health blocks recovery.
    -- Rationale: a wounded character shouldn't be passively recovering sanity while
    -- bleeding out. Reuses moodle reads from the decay pass — no extra Java calls.
    local content = unhappyLvl == 0
        and stressLvl  < 3
        and moodles:getMoodleLevel(MoodleType.BORED)   < 3   -- Pitfall 2: BORED, NOT BOREDOM
        and panicLvl   == 0
        and painLvl    < SanityTraits.RECOVERY_PAIN_BLOCK
        and currentHP  >= SanityTraits.RECOVERY_HEALTH_BLOCK
    if content then
        local baseRecovery = SanityTraits.RECOVERY_RATE_BY_STAGE[stageKey] or 0
        local recoveryMul = SanityTraits.SANDBOX_RECOVERY_MULT or 1.0
        local recoveryRate = (baseRecovery > 0) and math.max(1, math.floor(baseRecovery * recoveryMul + 0.5)) or 0
        if recoveryRate > 0 and sanity < SanityTraits.SANITY_MAX then
            local before = sanity
            sanity = math.min(SanityTraits.SANITY_MAX, before + recoveryRate)
            if sanity ~= before then                               -- Pitfall 1
                md.SanityTraits.sanity = sanity
                print(SanityTraits.LOG_TAG .. " recovery tick: rate=" .. tostring(recoveryRate)
                    .. " (content, " .. stageKey .. ") sanity=" .. tostring(before)
                    .. " -> " .. tostring(sanity))
                SanityTraits.bumpCounter("recoveries.fromHappiness", recoveryRate)
                SanityTraits.evaluateStageTransitions(player)
            end
        end
    end
end

-- ── EveryTenMinutes registration (D-43) ──
-- No-args event; resolves player via getPlayer() inside.
local function onTenMinutes()
    SanityTraits.applyTimedSanityChange(getPlayer())
end
Events.EveryTenMinutes.Add(onTenMinutes)

-- ── EveryDays registration (daily-bonus cap reset, D-45) ──
-- Resets md.SanityTraits.dailyBonusUsed at the in-game day boundary. Inline reset
-- inside applyBonusEvent is belt-and-suspenders for save/load spanning a day boundary.
local function onEveryDays()
    local player = getPlayer()
    if not player then return end
    if SanityTraits.isSystemDisabled(player) then return end
    local md = player:getModData()
    if not md.SanityTraits then return end

    md.SanityTraits.dailyBonusUsed = 0
    md.SanityTraits.lastBonusDay = getGameTime():getDay()
    print(SanityTraits.LOG_TAG .. " daily bonus cap reset (day=" .. tostring(md.SanityTraits.lastBonusDay) .. ")")
end
Events.EveryDays.Add(onEveryDays)

print(SanityTraits.LOG_TAG .. " TimedDecay loader: applyTimedSanityChange + applyBonusEvent ready")

-- ── Bonus event hooks: monkey-patch vanilla TimedAction.complete (D-45) ───────
-- Pattern: capture original :complete, wrap with new function that calls original
-- FIRST (so vanilla unhappiness/boredom/skill effects land), THEN runs SanityTraits
-- logic. Each hook honors D-36 + ModData defensive guard before calling
-- applyBonusEvent. SP-only: we additionally check `self.character == getPlayer()`
-- so multiplayer scenarios don't accidentally double-fire (project is SP-only,
-- but this keeps the contract honest).

-- ── Read-book bonus (D-45 +5 sanity, capped) ──
-- ISReadABook is the vanilla skill-book/recreational-book reading action.
-- Source: ProjectZomboid/media/lua/shared/TimedActions/ISReadABook.lua:323 (:complete signature).
local _orig_ISReadABook_complete = ISReadABook.complete
function ISReadABook:complete()
    local result = _orig_ISReadABook_complete(self)
    -- Bonus only if action actually completed AND for the local SP player AND ModData seeded.
    if self.character
       and self.character == getPlayer()
       and not SanityTraits.isSystemDisabled(self.character)
       and self.character:getModData().SanityTraits then
        SanityTraits.applyBonusEvent(self.character, "readBook")
    end
    return result
end

-- ── Eat-well bonus (D-45 +5 sanity, capped; quality-food qualifier per Open Q2) ──
-- ISEatFoodAction is the vanilla food-consumption timed action.
-- Source: ProjectZomboid/media/lua/shared/TimedActions/ISEatFoodAction.lua:173 (:complete signature).
-- Qualifier: only items with measurable Unhappy or Boredom REDUCTION trigger the bonus.
-- Junk food (cigarettes, raw meat, spoiled food) has zero or positive Unhappy/Boredom changes
-- and will NOT trigger. Threshold -0.001 catches floating-point near-zero items as "no effect".
local _orig_ISEatFoodAction_complete = ISEatFoodAction.complete
function ISEatFoodAction:complete()
    local result = _orig_ISEatFoodAction_complete(self)
    if self.character
       and self.character == getPlayer()
       and not SanityTraits.isSystemDisabled(self.character)
       and self.character:getModData().SanityTraits
       and self.item then
        local unhappyDelta = (self.item.getUnhappyChange and self.item:getUnhappyChange()) or 0
        local boredomDelta = (self.item.getBoredomChange and self.item:getBoredomChange()) or 0
        if unhappyDelta < -0.001 or boredomDelta < -0.001 then
            SanityTraits.applyBonusEvent(self.character, "ateWell")
        end
        -- ── Phase 5 / D-53 / HABIT-01 cigarette consumption branch ──
        -- EatType=Cigarettes covers Cigar / CigaretteSingle / CigaretteRolled / Cigarillo (verified food.txt:15281+).
        -- Defensive method-existence check (self.item.getEatType) per Phase 3 monkey-patch convention.
        -- Bumps the counter; addiction trait is selected at next Hollow descent (Plan 05-03 evaluateAddictions).
        if self.item.getEatType and self.item:getEatType() == "Cigarettes" then
            SanityTraits.bumpCounter("consumption.cigarettes", 1)
        end
    end
    return result
end

-- ── Phase 5 / D-55 / HABIT-01: ISDrinkFluidAction alcohol-consumption hook ──
-- ISDrinkFluidAction is the vanilla fluid-consumption timed action (Beer, Wine, Whiskey, etc).
-- Source: ProjectZomboid/media/lua/shared/TimedActions/ISDrinkFluidAction.lua:104-107 (:complete)
--       + :131 (o.fluidContainer = item:getFluidContainer() — set in :new)
-- Detection: fluidContainer:getProperties():getAlcohol() > 0. Threshold is 0 (NOT 0.4) because
-- habit-tracking treats ANY alcohol as alcoholic consumption (beer at 0.05 alcohol counts).
-- The 0.4 threshold at ISHealthPanel.lua:1306 is for intoxication detection, not habit tracking.
-- Modded alcoholic fluids that set Alcohol > 0 in their fluid def are auto-counted.
local _orig_ISDrinkFluidAction_complete = ISDrinkFluidAction.complete
function ISDrinkFluidAction:complete()
    local result = _orig_ISDrinkFluidAction_complete(self)
    if self.character
       and self.character == getPlayer()
       and not SanityTraits.isSystemDisabled(self.character)
       and self.character:getModData().SanityTraits
       and self.fluidContainer then
        local props = self.fluidContainer:getProperties()
        if props and props.getAlcohol and props:getAlcohol() > 0 then
            SanityTraits.bumpCounter("consumption.alcohol", 1)
        end
    end
    return result
end

-- ── Phase 5 / D-54 / HABIT-01: ISTakePillAction painkiller-consumption hook ──
-- ISTakePillAction is the SHARED timed-action for ALL pill items (painkillers, anti-depressants,
-- beta-blockers, sleeping pills, vitamins). Source: ProjectZomboid/media/lua/shared/TimedActions/ISTakePillAction.lua:64-70.
-- D-54 filter: getType() == "Pills" — ONLY the vanilla painkiller (drainable.txt:1414-1427,
-- "Tooltip = Tooltip_Painkillers, Icon = PillsPainkiller"). Excludes PillsAntiDep, PillsBeta,
-- PillsSleepingTablets, PillsVitamins, PillsXanax — narrative-correct addiction scope.
-- Modded painkillers (e.g. Morphine) NOT auto-counted unless they register with getType()=="Pills";
-- expandable in Phase 6 sandbox or v2.
local _orig_ISTakePillAction_complete = ISTakePillAction.complete
function ISTakePillAction:complete()
    local result = _orig_ISTakePillAction_complete(self)
    if self.character
       and self.character == getPlayer()
       and not SanityTraits.isSystemDisabled(self.character)
       and self.character:getModData().SanityTraits
       and self.item
       and self.item.getType
       and self.item:getType() == "Pills" then
        SanityTraits.bumpCounter("consumption.painkillers", 1)
    end
    return result
end

print(SanityTraits.LOG_TAG .. " TimedDecay hooks: ISReadABook + ISEatFoodAction + ISDrinkFluidAction + ISTakePillAction monkey-patches installed")
