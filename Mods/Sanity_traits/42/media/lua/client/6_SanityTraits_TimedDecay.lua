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

    -- ── Decay pass (D-44; profile-aware per Phase 4 / Plan 03 OCC-01) ──
    -- HARDENED 0.7x: Stable rate stays 1 (floor-of-1 holds; max(1, floor(0.7+0.5))=1);
    --                Numb rate becomes 3 (floor(2.8+0.5)=3, was 4); meaningful slowdown.
    -- FRAGILE 1.3x:  Stable rate stays 1 (max(1, floor(1.3+0.5))=1);
    --                Numb rate becomes 5 (floor(5.2+0.5)=5, was 4); ~30% faster decay.
    -- broken stage absent from DECAY_RATE_BY_STAGE -> getEffectiveDecayRate returns 0 (Pitfall 5 short-circuit).
    local decayRate = SanityTraits.getEffectiveDecayRate(player, stageKey)
    if decayRate > 0 and sanity > SanityTraits.SANITY_MIN then
        local before = sanity
        sanity = math.max(SanityTraits.SANITY_MIN, before - decayRate)
        if sanity ~= before then                                   -- Pitfall 1: silent tick = no bump
            md.SanityTraits.sanity = sanity
            print(SanityTraits.LOG_TAG .. " decay tick: rate=" .. tostring(decayRate)
                .. " (" .. stageKey .. ") sanity=" .. tostring(before)
                .. " -> " .. tostring(sanity))
            SanityTraits.bumpCounter("decay.timedTicks", -decayRate)
            SanityTraits.evaluateStageTransitions(player)
            -- Evaluator may have descended; refresh stageKey + sanity for the recovery pass
            sanity   = md.SanityTraits.sanity
            stageKey = SanityTraits.computeStage(sanity)
        end
    end

    -- ── Recovery pass (D-45 contentment gate) ──
    local moodles = player:getMoodles()
    local content = moodles:getMoodleLevel(MoodleType.UNHAPPY) == 0
        and moodles:getMoodleLevel(MoodleType.STRESS)  < 3
        and moodles:getMoodleLevel(MoodleType.BORED)   < 3   -- Pitfall 2: BORED, NOT BOREDOM
        and moodles:getMoodleLevel(MoodleType.PANIC)   == 0
    if content then
        local recoveryRate = SanityTraits.RECOVERY_RATE_BY_STAGE[stageKey] or 0
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
    end
    return result
end

print(SanityTraits.LOG_TAG .. " TimedDecay hooks: ISReadABook + ISEatFoodAction monkey-patches installed")
