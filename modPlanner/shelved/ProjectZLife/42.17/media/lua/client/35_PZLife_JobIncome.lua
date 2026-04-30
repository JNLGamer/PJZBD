-- ProjectZLife / 35_PZLife_JobIncome.lua
-- M2 Phase 10: Per-profession job income math (JOB-04).
--
-- WHAT: Per the BWO official guide, 9 professions earn money via specific
-- in-game actions. This module implements payment hooks for each:
--
--   1. Universal: trash pickup (any worker, any garbage container)
--   2. Mechanic — fix cars in car shops               [ISMechanicAction]
--   3. Doctor / Nurse — heal wounded NPCs             [ISHealAction]
--   4. Lumberjack — collect logs in log containers    [InventoryTransfer (Log)]
--   5. Policeman — shoot bad people (bandits)         [OnZombieDead with bandit clan]
--   6. Fireman — extinguish fires                     [ZAExtinguish completion]
--   7. Park ranger — forage out-of-place items        [ISForageAction]
--   8. Fitness instructor — exercise near other people [ISExerciseAction proximity]
--   9. Fisherman — put fish in restaurant fridges     [InventoryTransfer (Fish to fridge)]
--
-- v1 SCOPE: Ship core 4 (mechanic, doctor, lumberjack, fireman, policeman) +
-- universal trash pickup. The other 4 (park ranger, fitness, fisherman) ship
-- as stubs that log "TODO: pay for X" so users see them in console even
-- without payment — refinement when M3 P19 (Job Application UI) lands.
--
-- PAYMENT MODEL:
--   * Per profession: payment_per_action (in-game dollars added as Money items)
--   * Tunable via SandboxVars in M4 P22; for v1, hardcoded defaults
--   * Restricted to player's CURRENT job per md.PZLife.workplace.profession
--     (so a doctor character doesn't get paid for fixing cars)
--   * Universal trash pickup pays ANY profession (everyone can do menial work)
--
-- DECISIONS LOGGED:
--   D-35 (M2 P10): Payment goes into `player.getInventory():AddItem("Base.Money")`
--     — mirrors the same Money item type the wanted ladder counts. Wire-compatible
--     with BWO economy + Wasted's medical fees.
--   D-36 (M2 P10): Profession check uses `md.PZLife.workplace.profession` (set
--     in M1 P3 by JobAssignment). For v1 this is the player's starting profession;
--     M3 P19 lets the player change jobs at runtime.
--   D-37 (M2 P10): Bandit-kill payment for policeman uses OnZombieDead +
--     `BanditZombie.GetInstanceById(zombie).brain.clan != 0` to identify
--     bandit kills (clan 0 = neutral civilian; non-zero = faction NPC).
--   D-38 (M2 P10): Stub professions (parkranger, fitnessinstructor, fisherman)
--     log a TODO line on their would-be payment trigger but don't pay yet.
--     M3 P19 ships full implementation.

PZLife = PZLife or {}
PZLife.JobIncome = PZLife.JobIncome or {}

-- ── Pay rates (defaults; SandboxVars override in M4 P22) ────────────────────

PZLife.JobIncome.PAY = {
    trash_pickup       = 1,    -- universal
    mechanic_repair    = 25,
    doctor_heal        = 15,
    lumberjack_log     = 8,
    policeman_bandit   = 30,
    fireman_extinguish = 18,
    parkranger_forage  = 5,    -- stub
    fitness_exercise   = 3,    -- stub
    fisherman_fish     = 12,   -- stub
}

-- ── Helpers ─────────────────────────────────────────────────────────────────

local function getProfession(player)
    if not player then return nil end
    local md = player:getModData()
    if md.PZLife and md.PZLife.workplace then
        return md.PZLife.workplace.profession
    end
    return nil
end

local function payPlayer(player, amount, reason)
    if not player or not amount or amount <= 0 then return end
    local inv = player:getInventory()
    if not inv then return end

    for _ = 1, amount do
        inv:AddItem("Base.Money")
    end

    if player.addLineChatElement then
        player:addLineChatElement(
            string.format("+ $%d (%s)", amount, tostring(reason)),
            0.1, 1.0, 0.3
        )
    end
    print(string.format("%s JobIncome: paid $%d to player (reason=%s)",
        PZLife.LOG_TAG, amount, tostring(reason)))
end

local function isJob(player, professionId)
    return getProfession(player) == professionId
end

-- ── Mechanic — pay on vehicle repair completion ─────────────────────────────

local function hookMechanic()
    if not ISMechanicAction or ISMechanicAction.__pzlifePaid then return end
    if not ISMechanicAction.complete then return end
    ISMechanicAction.__pzlifePaid = true
    local origComplete = ISMechanicAction.complete
    ISMechanicAction.complete = function(self)
        local result = origComplete(self)
        local player = self.character or getPlayer()
        if isJob(player, "mechanic") then
            payPlayer(player, PZLife.JobIncome.PAY.mechanic_repair, "vehicle repair")
        end
        return result
    end
    print(PZLife.LOG_TAG .. " JobIncome: ISMechanicAction.complete hooked (mechanic)")
end

-- ── Doctor / Nurse — pay on heal action completion ──────────────────────────

local function hookDoctor()
    if not ISHealAction or ISHealAction.__pzlifePaid then return end
    if not ISHealAction.complete then return end
    ISHealAction.__pzlifePaid = true
    local origComplete = ISHealAction.complete
    ISHealAction.complete = function(self)
        local result = origComplete(self)
        local player = self.character or getPlayer()
        if isJob(player, "doctor") or isJob(player, "nurse") then
            payPlayer(player, PZLife.JobIncome.PAY.doctor_heal, "patient healed")
        end
        return result
    end
    print(PZLife.LOG_TAG .. " JobIncome: ISHealAction.complete hooked (doctor/nurse)")
end

-- ── Lumberjack — pay on log deposit (InventoryTransfer to log container) ────

local function hookLumberjack()
    if not ISInventoryTransferAction or ISInventoryTransferAction.__pzlifeLumberPaid then return end
    if not ISInventoryTransferAction.complete then return end
    ISInventoryTransferAction.__pzlifeLumberPaid = true
    local origComplete = ISInventoryTransferAction.complete
    ISInventoryTransferAction.complete = function(self)
        local result = origComplete(self)
        local player = self.character or getPlayer()
        if isJob(player, "lumberjack") and self.item and self.item.getType then
            local t = self.item:getType()
            if t == "Log" or (type(t) == "string" and t:find("Log", 1, true)) then
                -- Confirm destination is a log container by checking the container parent
                local destContainer = self.destContainer
                if destContainer and destContainer.getType then
                    local destType = destContainer:getType()
                    if destType and destType:lower():find("log") then
                        payPlayer(player, PZLife.JobIncome.PAY.lumberjack_log, "log deposited")
                    end
                end
            end
        end
        return result
    end
    print(PZLife.LOG_TAG .. " JobIncome: ISInventoryTransferAction.complete hooked (lumberjack)")
end

-- ── Policeman — pay on bandit-NPC kill (OnZombieDead) ───────────────────────

local function hookPoliceman()
    Events.OnZombieDead.Add(function(zombie)
        local player = getPlayer()
        if not isJob(player, "policeofficer") then return end
        if not BanditZombie or not BanditZombie.GetInstanceById then return end

        -- Check if the dead "zombie" was actually a bandit (clan != 0)
        local id = (zombie.getOnlineID and zombie:getOnlineID()) or nil
        if not id then return end
        local civ = BanditZombie.GetInstanceById(id)
        if civ and civ.brain and civ.brain.clan and civ.brain.clan ~= 0 then
            payPlayer(player, PZLife.JobIncome.PAY.policeman_bandit, "bandit eliminated")
        end
    end)
    print(PZLife.LOG_TAG .. " JobIncome: OnZombieDead hooked (policeman)")
end

-- ── Fireman — pay on fire extinguish (defensive — multiple possible APIs) ───

local function hookFireman()
    -- Try ZAExtinguish first (BWO ZombieActions)
    if ZAExtinguish and ZAExtinguish.complete and not ZAExtinguish.__pzlifePaid then
        ZAExtinguish.__pzlifePaid = true
        local orig = ZAExtinguish.complete
        ZAExtinguish.complete = function(self, ...)
            local result = orig(self, ...)
            local player = self.character or getPlayer()
            if isJob(player, "fireofficer") or isJob(player, "fireman") then
                payPlayer(player, PZLife.JobIncome.PAY.fireman_extinguish, "fire extinguished")
            end
            return result
        end
        print(PZLife.LOG_TAG .. " JobIncome: ZAExtinguish.complete hooked (fireman)")
        return
    end
    print(PZLife.LOG_TAG .. " JobIncome: WARN — fireman hook not installed (ZAExtinguish not found at hook time)")
end

-- ── Universal trash pickup (any player picking up Garbage* items) ───────────

local function hookTrashPickup()
    -- Hook ISInventoryTransferAction with a lighter check for trash items
    -- Idempotency: shares __pzlifeLumberPaid flag, but we register a SECOND
    -- wrapper that only checks for trash items.
    if not ISInventoryTransferAction or not ISInventoryTransferAction.complete then return end
    if ISInventoryTransferAction.__pzlifeTrashPaid then return end
    ISInventoryTransferAction.__pzlifeTrashPaid = true
    local prevComplete = ISInventoryTransferAction.complete  -- could be the lumberjack-wrapped version
    ISInventoryTransferAction.complete = function(self)
        local result = prevComplete(self)
        local player = self.character or getPlayer()
        if self.item and self.item.getType then
            local t = self.item:getType()
            if type(t) == "string" and (t:find("Garbage", 1, true) or t:find("Trash", 1, true)) then
                payPlayer(player, PZLife.JobIncome.PAY.trash_pickup, "trash collected")
            end
        end
        return result
    end
    print(PZLife.LOG_TAG .. " JobIncome: trash-pickup hook installed (universal)")
end

-- ── Stub hooks for the 3 deferred professions ───────────────────────────────

local function logStubs()
    -- These don't install hooks; just announce they exist.
    print(PZLife.LOG_TAG .. " JobIncome: park ranger / fitness instructor / fisherman income deferred to M3 P19 (currently no payment)")
end

-- ── Wiring ──────────────────────────────────────────────────────────────────

local function installHooks()
    hookMechanic()
    hookDoctor()
    hookLumberjack()
    hookTrashPickup()  -- AFTER lumberjack so it wraps the lumberjack-wrapped version
    hookPoliceman()
    hookFireman()
    logStubs()
end

Events.OnGameBoot.Add(installHooks)
-- Second-pass safety in case some action classes load late
Events.OnGameStart.Add(function()
    if not ZAExtinguish or not ZAExtinguish.__pzlifePaid then
        hookFireman()
    end
end)

print(PZLife.LOG_TAG .. " JobIncome loaded (JOB-04; 5 professions + trash-pickup wired)")
