-- Sanity_traits / 3_SanityTraits_KillEvents.lua
-- Phase 1 / Plan 03: Zombie and survivor kill -> sanity decrement.
-- Loaded after 1_*.lua and 2_*.lua (alphabetical/numeric prefix order).
-- Source: .planning/phases/01-foundation/01-RESEARCH.md Patterns 3 & 4
-- IMPORTANT: B42 events are OnZombieDead (singular) and OnWeaponHitXp.
-- The plural-form name and OnWeaponHitCharacter from reference/events.md DO NOT EXIST in B42.

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
end

Events.OnZombieDead.Add(onZombieDead)
