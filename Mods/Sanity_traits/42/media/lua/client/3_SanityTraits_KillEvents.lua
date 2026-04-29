-- Sanity_traits / 3_SanityTraits_KillEvents.lua
-- Phase 1 / Plan 03: Zombie and survivor kill -> sanity decrement.
-- Loaded after 1_*.lua and 2_*.lua (alphabetical/numeric prefix order).
-- Source: .planning/phases/01-foundation/01-RESEARCH.md Patterns 3 & 4
-- IMPORTANT: B42 events are OnZombieDead (singular) and OnWeaponHitXp.
-- The plural-form zombie-event name and the legacy weapon-hit-character event from
-- reference/events.md DO NOT EXIST in B42 — use the names above instead.
--
-- Phase 01.2 / Plan 04: switched from SanityTraits.log to SanityTraits.bumpCounter.
-- Phase 1 console receipts ("Zombie killed. Sanity: X -> Y") preserved verbatim.

-- ── CORE-03: Zombie kill -> reduce sanity by ZOMBIE_WEIGHT ───────────────────
-- OnZombieDead fires once per zombie death; in singleplayer the attacker is getPlayer().
-- Source: ProjectZomboid/media/lua/client/LastStand/Challenge2.lua:68, Tutorial/Steps.lua:913
local function onZombieDead(zed)
    local player = getPlayer()
    if not player then return end

    -- D-36 (Phase 2): in-game off-switch — early-return BEFORE reading ModData if
    -- the system is disabled. Trips after Broken applies base:desensitized (the
    -- final tick where evaluator did work; subsequent kills are silent forever).
    -- Also catches Veteran (vanilla GrantedTraits) — defensive belt-and-suspenders
    -- with the OnCreatePlayer check (Plan 03), since Veteran's ModData was never
    -- seeded but kills could still arrive before any other guard.
    if SanityTraits.isSystemDisabled(player) then return end

    local md = player:getModData()
    if not md.SanityTraits then return end  -- guard: ModData not yet initialized

    local before = md.SanityTraits.sanity
    md.SanityTraits.sanity = math.max(SanityTraits.SANITY_MIN, before - SanityTraits.ZOMBIE_WEIGHT)
    print(SanityTraits.LOG_TAG .. " Zombie killed. Sanity: " .. tostring(before)
        .. " -> " .. tostring(md.SanityTraits.sanity))
    -- Phase 01.2 / Plan 04 (D-27): increment the counter tree instead of the deprecated log.
    -- Delta is signed-negative metadata for the bumpCounter console receipt.
    -- The actual sanity decrement is already applied above; bumpCounter does NOT touch sanity.
    SanityTraits.bumpCounter("zombiesKilled", -SanityTraits.ZOMBIE_WEIGHT)

    -- Phase 2 (STAGE-02): evaluate stage transitions AFTER sanity decrement and
    -- counter bump. Idempotent — if the kill didn't cross a threshold, this is a
    -- no-op. Cascades through intermediate stages on multi-stage skips (rare in
    -- single-kill scope; possible if ZOMBIE_WEIGHT is sandbox-tuned high in Phase 6).
    SanityTraits.evaluateStageTransitions(player)
end

Events.OnZombieDead.Add(onZombieDead)

-- ── CORE-04: Survivor (non-zombie) kill -> reduce sanity by SURVIVOR_WEIGHT ───
-- OnWeaponHitXp fires for every weapon hit; we filter for non-zombie targets that just died.
-- Source: ProjectZomboid/media/lua/server/XpSystem/XpUpdate.lua:48 (signature)
-- Source: ProjectZomboid/media/lua/shared/Items/OnBreak.lua:62 (instanceof IsoZombie pattern)
-- Pitfall 3 (RESEARCH.md): multi-hit edge case; in singleplayer Phase 1 scope this is acceptable.
local function onWeaponHitXp(owner, weapon, hitObject, damage, hitCount)
    if not owner or not hitObject then return end

    -- Filter: target is NOT a zombie (zombies are CORE-03's territory) AND just died from this hit
    if instanceof(hitObject, "IsoZombie") then return end
    if not hitObject:isDead() then return end

    -- D-36 (Phase 2): in-game off-switch (after the cheap target-classification filters,
    -- before ModData access). Same rationale as onZombieDead: catches Broken-applied
    -- and Veteran characters before sanity arithmetic.
    if SanityTraits.isSystemDisabled(owner) then return end

    local md = owner:getModData()
    if not md.SanityTraits then return end  -- guard: ModData not yet initialized

    local before = md.SanityTraits.sanity
    md.SanityTraits.sanity = math.max(SanityTraits.SANITY_MIN, before - SanityTraits.SURVIVOR_WEIGHT)
    print(SanityTraits.LOG_TAG .. " Survivor killed. Sanity: " .. tostring(before)
        .. " -> " .. tostring(md.SanityTraits.sanity))
    -- Phase 01.2 / Plan 04 (D-27): increment the counter tree instead of the deprecated log.
    -- Delta is signed-negative metadata for the bumpCounter console receipt.
    -- The actual sanity decrement is already applied above; bumpCounter does NOT touch sanity.
    SanityTraits.bumpCounter("survivorsKilled", -SanityTraits.SURVIVOR_WEIGHT)

    -- Phase 2 (STAGE-02): evaluate stage transitions AFTER sanity decrement.
    -- Survivor kill weight (default 30) is 3x zombie weight — more likely to skip
    -- a stage in one event. The cascade in evaluator handles multi-stage skips.
    SanityTraits.evaluateStageTransitions(owner)
end

Events.OnWeaponHitXp.Add(onWeaponHitXp)
