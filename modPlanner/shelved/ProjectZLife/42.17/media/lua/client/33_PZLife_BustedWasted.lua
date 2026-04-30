-- ProjectZLife / 33_PZLife_BustedWasted.lua
-- M2 Phase 8: BUSTED / WASTED transitions. Absorbs Wasted mod natively.
-- (HOSP-01..05.)
--
-- WHAT: Branch on wanted-star tier when player health is critical or arrest
-- conditions are met:
--   ★    (1)   → BUSTED → cuffed → jail (auto-release after 1 in-game hour)
--   ★★   (2)   → BUSTED → arrested → jail
--   ★★★★ (4)   → WASTED → killed → hospital (medical fees + debt)
--   ★★★★★(5)   → permadeath (no transition; let normal death apply)
--
-- The fade-teleport-restore sequence is faithfully ported from Wasted.lua
-- (UIManager.setFadeBeforeUI + FadeOut → teleport + heal + charge → FadeIn
-- + restore). State machine ticks at the same cadence as Wasted (tick 4 =
-- fade-out, tick 35 = teleport+heal+charge, tick 40 = restore, tick 500 = reset).
--
-- Save migration: at OnGameStart, if WastedModData exists, port the player's
-- characterDebt entry into md.PZLife.medicalDebt and leave the original
-- WastedModData untouched (Wasted is incompatible= so won't be loaded; the
-- old ModData blob just sits dormant in the save).
--
-- DEPENDENCIES (still load — Project Z Life require=Bandits2,BanditsWeekOne):
--   * BanditUtils.DistTo  — find-closest math
--   * BanditZombie.GetAllB / GetInstanceById / Bandit.SetHostile — de-hostile civs on respawn
--   * BWOPlayer.tick      — Wasted's frame-rate gate (we copy its cadence)
--   * BWOPopControl.Medics.On — Wasted's "is medic system available" check
--   * BWOTex.tex/.alpha/.speed/.mode — BWO's screen-overlay primitive
--
-- DECISIONS LOGGED:
--   D-24 (M2 P8): Faithful port of Wasted's tick cadence (4=fade, 35=teleport,
--     40=restore, 500=reset). Diverging cadence would feel jarring to BWO
--     veterans; same cadence preserves muscle memory.
--   D-25 (M2 P8): Hospital coords ported verbatim from Wasted.lua (8 city
--     hospitals + Lake Fallas). Jail coords are placeholders: hospital coord
--     + (0, +50) offset for v1. M3 will replace with real jail discovery
--     when BWOBuildings/PrisonGuard data is wired.
--   D-26 (M2 P8): Body-part healing simplified to AddGeneralHealth(300.0)
--     + StopBurning. Wasted's full per-body-part bandage/stitch/splint/burn
--     loop is omitted from v1 — it adds ~100 lines for a marginal UX win.
--     M3 P19 (Job Application UI) can come back and add it if user reports it.
--   D-27 (M2 P8): Item removal simplified to mode 1 only (drop hand items).
--     Wasted's modes 2/3/4 (gun/weapon/all-item removal) are omitted for v1.
--     User can configure full item removal in M4 P22 sandbox-options pass.
--   D-28 (M2 P8): Auto-release for BUSTED: 60 in-game minutes (1 hour) after
--     teleport. Implemented via in-game-time delta check on each player tick.
--   D-29 (M2 P8): Save migration is one-shot at OnGameStart and idempotent:
--     once md.PZLife.medicalDebt is populated, subsequent loads see it and
--     skip migration. Wasted's WastedModData blob is untouched (no cleanup
--     needed since Wasted mod won't load on Project Z Life worlds).
--   D-30 (M2 P8): Permadeath at 5★ is a no-op in this module — we simply
--     don't trigger a transition. PZ's natural death + character-respawn flow
--     applies. M2 P9 (police behavior) ensures cops actually inflict the
--     killing blow at 5★ to make this trigger condition reachable.

PZLife = PZLife or {}
PZLife.BustedWasted = PZLife.BustedWasted or {}

-- ── Configuration ───────────────────────────────────────────────────────────

PZLife.BustedWasted.MIN_HP                = 5     -- HP threshold for transition
PZLife.BustedWasted.MAX_INJURIES          = 12    -- skip transition if too injured
PZLife.BustedWasted.MEDICAL_FEE_BASE      = 4     -- multiplier^MedicalCost in fees
PZLife.BustedWasted.JAIL_HOLD_GAME_HOURS  = 1     -- auto-release after 1 in-game hour
PZLife.BustedWasted.MEDICAL_OVERLAY_PATH  = "media/ui/wasted.png"  -- BWO ships this
PZLife.BustedWasted.JAIL_OVERLAY_PATH     = "media/ui/wasted.png"  -- placeholder until BUSTED tex authored

PZLife.BustedWasted.HOSPITAL_LOCATIONS = {
    { name = "LV Central",      x = 12939, y = 2093  },
    { name = "LV St Peregrin",  x = 12460, y = 3706  },
    { name = "West Point",      x = 11869, y = 6904  },
    { name = "Muldraugh",       x = 10883, y = 10040 },
    { name = "March Ridge",     x = 10160, y = 12761 },
    { name = "Rosewood",        x =  8098, y = 11527 },
    { name = "Jamieton",        x =  5492, y = 9585  },
    { name = "Lake Fallas",     x =  7293, y = 8394  },
}

-- v1 placeholder: jail = hospital + (0, +50). Replaced in M3 by real jail discovery.
PZLife.BustedWasted.JAIL_LOCATIONS = {}
for _, h in ipairs(PZLife.BustedWasted.HOSPITAL_LOCATIONS) do
    table.insert(PZLife.BustedWasted.JAIL_LOCATIONS, {
        name = h.name .. " jail",
        x = h.x,
        y = h.y + 50,
    })
end

-- ── Helpers ─────────────────────────────────────────────────────────────────

local function findClosest(locations, x, y)
    if not BanditUtils or not BanditUtils.DistTo then
        return locations[1]  -- fallback: just pick first
    end
    local closest = locations[1]
    local closestDist = math.huge
    for _, loc in ipairs(locations) do
        local d = BanditUtils.DistTo(loc.x, loc.y, x, y)
        if d < closestDist then
            closestDist = d
            closest = loc
        end
    end
    return closest
end

local function ensureState(player)
    local md = player:getModData()
    md.PZLife = md.PZLife or {}
    md.PZLife.medicalDebt = md.PZLife.medicalDebt or 0
    md.PZLife.transition  = md.PZLife.transition  or { active = false }
    md.PZLife.jailReleaseGameHour = md.PZLife.jailReleaseGameHour or -1
    return md.PZLife
end

local function dehostileCivs()
    if not BanditZombie or not BanditZombie.GetAllB then return end
    local civs = BanditZombie.GetAllB()
    for _, civ in pairs(civs) do
        if civ.brain and civ.brain.clan == 0 and civ.brain.hostile then
            local actor = BanditZombie.GetInstanceById(civ.id)
            if actor and Bandit and Bandit.SetHostile then
                Bandit.SetHostile(actor, false)
            end
        end
    end
end

local function showOverlay(texturePath)
    if not BWOTex then return end
    BWOTex.tex   = getTexture(texturePath)
    BWOTex.speed = 0.08
    BWOTex.mode  = "center"
    BWOTex.alpha = 2.4
end

local function chargeMedicalFees(player, injuriesCount)
    local s = ensureState(player)
    local sbCost = (SandboxVars and SandboxVars.Wasted and SandboxVars.Wasted.MedicalCost) or 1
    if sbCost <= 1 then return end

    local cnt = injuriesCount * (PZLife.BustedWasted.MEDICAL_FEE_BASE ^ sbCost)
    local owed = cnt + s.medicalDebt
    s.medicalDebt = 0

    local inv = player:getInventory()
    local moneys = ArrayList.new()
    inv:getAllEvalRecurse(function(it) return it:getType() == "Money" end, moneys)
    local cash = moneys:size()
    local paid = math.min(cash, owed)
    for _ = 1, paid do
        inv:RemoveOneOf("Money", true)
    end
    local outstanding = math.max(0, owed - paid)
    s.medicalDebt = outstanding

    if outstanding > 0 then
        player:addLineChatElement(
            string.format("Medical fees: $%d. Paid $%d. Outstanding debt: $%d.", owed, paid, outstanding),
            0, 1, 0
        )
    else
        player:addLineChatElement(
            string.format("Medical fees: $%d. Paid in full.", owed),
            0, 1, 0
        )
    end
end

-- ── Public API ──────────────────────────────────────────────────────────────

-- Begin a BUSTED or WASTED transition. mode = "busted" | "wasted".
function PZLife.BustedWasted.begin(player, mode)
    if not player then return end
    local s = ensureState(player)
    if s.transition.active then return end  -- already in flight; idempotent

    local px, py = player:getX(), player:getY()
    local destinations = (mode == "busted") and PZLife.BustedWasted.JAIL_LOCATIONS or PZLife.BustedWasted.HOSPITAL_LOCATIONS
    local target = findClosest(destinations, px, py)

    s.transition = {
        active   = true,
        mode     = mode,
        tick     = 0,
        targetX  = target.x,
        targetY  = target.y,
        targetName = target.name,
    }

    -- Pre-fade incapacitation
    local playerDmg = player:getBodyDamage()
    playerDmg:AddGeneralHealth(300.0)
    player:StopBurning()
    player:clearVariable("BumpFallType")
    player:setBumpType("stagger")
    player:setBumpFallType("pushedFront")
    player:setBumpFall(true)
    player:setBannedAttacking(true)
    player:setBlockMovement(true)
    player:setGhostMode(true)
    player:dropHandItems()  -- D-27 simplification

    showOverlay(mode == "busted" and PZLife.BustedWasted.JAIL_OVERLAY_PATH
                                  or PZLife.BustedWasted.MEDICAL_OVERLAY_PATH)
    dehostileCivs()
    if mode == "busted" then
        player:playSound("ZSDayStart")
    else
        player:playSound("ZSDayStart")
    end

    print(string.format("%s BustedWasted: %s transition begun → %s (%d,%d)",
        PZLife.LOG_TAG, mode, target.name, target.x, target.y))
end

-- ── Tick handler — drives the fade/teleport/restore sequence ────────────────

local function transitionTick(player)
    local s = ensureState(player)
    if not s.transition.active then return end
    s.transition.tick = s.transition.tick + 1
    local t  = s.transition.tick
    local n  = player:getPlayerNum()

    if t == 4 then
        UIManager.setFadeBeforeUI(n, true)
        UIManager.FadeOut(n, 1)
    elseif t == 35 then
        -- Teleport + heal + charge fees
        local injuriesCount = 6  -- D-26 simplification: hardcoded baseline injury count
        local playerDmg = player:getBodyDamage()
        playerDmg:AddGeneralHealth(300.0)
        player:StopBurning()
        player:setX(s.transition.targetX)
        player:setY(s.transition.targetY)
        player:setZ(0)
        player:setLx(s.transition.targetX)
        player:setLy(s.transition.targetY)
        player:setLz(0)
        getWorld():update()
        if s.transition.mode == "wasted" then
            chargeMedicalFees(player, injuriesCount)
        end
        if s.transition.mode == "busted" then
            -- Schedule auto-release
            local releaseAt = (getGameTime():getHour() + PZLife.BustedWasted.JAIL_HOLD_GAME_HOURS) % 24
            s.jailReleaseGameHour = releaseAt
            print(string.format("%s BustedWasted: jail auto-release at game hour %d",
                PZLife.LOG_TAG, releaseAt))
        end
    elseif t == 40 then
        player:setGhostMode(false)
        UIManager.FadeIn(n, 1)
        UIManager.setFadeBeforeUI(n, false)
        player:setBannedAttacking(false)
        player:setBlockMovement(false)
        if s.transition.mode == "wasted" then
            -- WASTED: clear all wanted stars + bad-record on revive
            if PZLife.Wanted and PZLife.Wanted.maskCleared then
                PZLife.Wanted.maskCleared(player)
            end
        end
        -- BUSTED stays in lockup until auto-release tick
    elseif t > 500 then
        s.transition.active = false
        s.transition.tick   = 0
    end
end

-- ── Auto-release for BUSTED ─────────────────────────────────────────────────

local function jailReleaseTick(player)
    local s = ensureState(player)
    if s.jailReleaseGameHour < 0 then return end
    local hour = getGameTime():getHour()
    if hour ~= s.jailReleaseGameHour then return end

    -- Released: clear stars (BUSTED clears 1-2★ wanted on release)
    if PZLife.Wanted and PZLife.Wanted.read and PZLife.Wanted.maskCleared then
        local w = PZLife.Wanted.read(player)
        if w.stars > 0 and not w.badRecord then
            -- Use the same "clear all" pathway since BUSTED served the time
            PZLife.Wanted.maskCleared(player)
        end
    end
    s.jailReleaseGameHour = -1
    if player.addLineChatElement then
        player:addLineChatElement("Released from jail. Time served.", 0.4, 0.7, 1)
    end
    print(PZLife.LOG_TAG .. " BustedWasted: jail auto-release fired")
end

-- ── Trigger detection (per-tick) ────────────────────────────────────────────

local function checkTrigger(player)
    if not player then return end
    local s = ensureState(player)
    if s.transition.active then return end  -- already transitioning

    local hp = player:getBodyDamage():getHealth()
    if hp > PZLife.BustedWasted.MIN_HP then return end

    if not PZLife.Wanted or not PZLife.Wanted.read then return end
    local w = PZLife.Wanted.read(player)

    if w.stars >= 5 then
        -- D-30: permadeath; do nothing, let PZ kill them
        return
    elseif w.stars >= 4 then
        PZLife.BustedWasted.begin(player, "wasted")
    elseif w.stars >= 1 then
        -- 1-2★ → BUSTED. 3★ falls through to natural death (no Wasted catch).
        if w.stars <= 2 then
            PZLife.BustedWasted.begin(player, "busted")
        end
    end
end

-- ── Save migration: import WastedModData.characterDebt → md.PZLife.medicalDebt ─

local function migrateWastedDebt(player)
    if not player then return end
    local s = ensureState(player)
    if s._wastedDebtMigrated then return end  -- idempotent

    local wmd = ModData.exists("WastedModData") and ModData.get("WastedModData") or nil
    if wmd and wmd.characterDebt then
        local fullName = player:getFullName()
        local owed = wmd.characterDebt[fullName]
        if owed and owed > 0 then
            s.medicalDebt = (s.medicalDebt or 0) + owed
            print(string.format("%s BustedWasted: migrated $%d medical debt from WastedModData for %s",
                PZLife.LOG_TAG, owed, fullName))
        end
    end
    s._wastedDebtMigrated = true
end

-- ── Wiring ──────────────────────────────────────────────────────────────────

local function onPlayerUpdate(player)
    if not player then return end
    -- Frame-rate gate: same cadence Wasted used (every 4th BWOPlayer tick)
    if BWOPlayer and BWOPlayer.tick then
        if (BWOPlayer.tick % 4) ~= 0 then return end
    end
    checkTrigger(player)
    transitionTick(player)
    jailReleaseTick(player)
end

local function onCreatePlayer(_, player)
    if not player then player = getPlayer() end
    migrateWastedDebt(player)
end

Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnPlayerUpdate.Add(onPlayerUpdate)

print(PZLife.LOG_TAG .. " BustedWasted loaded (HOSP-01..05; absorbs Wasted mod)")
