-- Sanity_traits / 3_SanityTraits_KillEvents.lua
-- Phase 1 / Plan 03: Zombie and survivor kill -> sanity decrement.
-- Loaded after 1_*.lua and 2_*.lua (alphabetical/numeric prefix order).
-- Source: .planning/phases/01-foundation/01-RESEARCH.md Patterns 3 & 4
-- IMPORTANT: B42 events are OnZombieDead (singular) and OnWeaponHitXp.
-- The plural-form zombie-event name and the legacy weapon-hit-character event from
-- reference/events.md DO NOT EXIST in B42 — use the names above instead.

-- ── CORE-03: Zombie kill -> reduce sanity by ZOMBIE_WEIGHT ───────────────────
-- OnZombieDead fires once per zombie death; in singleplayer the attacker is getPlayer().
-- Source: ProjectZomboid/media/lua/client/LastStand/Challenge2.lua:68, Tutorial/Steps.lua:913
local function onZombieDead(zed)
    local player = getPlayer()
    if not player then return end
    local md = player:getModData()
    if not md.SanityTraits then return end  -- guard: ModData not yet initialized

    local before = md.SanityTraits.sanity
    md.SanityTraits.sanity = math.max(SanityTraits.SANITY_MIN, before - SanityTraits.ZOMBIE_WEIGHT)
    print(SanityTraits.LOG_TAG .. " Zombie killed. Sanity: " .. tostring(before)
        .. " -> " .. tostring(md.SanityTraits.sanity))
    -- Plan 01.1-02 (D-15): record event for the Psyche tab event log.
    -- Delta is signed-negative metadata; the actual decrement was already applied above.
    SanityTraits.log("kill", "Zombie killed", -SanityTraits.ZOMBIE_WEIGHT)
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

    local md = owner:getModData()
    if not md.SanityTraits then return end  -- guard: ModData not yet initialized

    local before = md.SanityTraits.sanity
    md.SanityTraits.sanity = math.max(SanityTraits.SANITY_MIN, before - SanityTraits.SURVIVOR_WEIGHT)
    print(SanityTraits.LOG_TAG .. " Survivor killed. Sanity: " .. tostring(before)
        .. " -> " .. tostring(md.SanityTraits.sanity))
    -- Plan 01.1-02 (D-15): record event for the Psyche tab event log.
    -- Delta is signed-negative metadata; the actual decrement was already applied above.
    SanityTraits.log("kill", "Survivor killed", -SanityTraits.SURVIVOR_WEIGHT)
end

Events.OnWeaponHitXp.Add(onWeaponHitXp)
