-- Sanity_traits / 9_SanityTraits_DespairMoodle.lua
-- Phase 7: Despair moodle HUD, thought bubbles, Numb auto-trigger,
--          substance suppression, Give Up context menu, and SH cooldown helper.
-- Loaded after 1_-8_*.lua (numeric prefix); consumes SanityTraits.DESPAIR,
-- SanityTraits.THOUGHT_BUBBLES, SanityTraits.computeStage, SanityTraits.isSystemDisabled.

-- ── Sharp item detection ──────────────────────────────────────────────────────
local SHARP_ITEMS = {
    "Base.HuntingKnife", "Base.Knife", "Base.KitchenKnife",
    "Base.Scissors",     "Base.ScalpelRusted", "Base.Scalpel",
}

function SanityTraits.findSharpItem(player)
    local inv = player:getInventory()
    for _, itemType in ipairs(SHARP_ITEMS) do
        local item = inv:FindAndReturn(itemType)
        if item then return item end
    end
    return nil
end

-- ── SH cooldown check ────────────────────────────────────────────────────────
function SanityTraits.canSHAgain(player)
    local md = player:getModData().SanityTraits
    if not md or md.lastSHTime == nil then return true end
    local hours = getGameTime():getWorldAgeHours() - md.lastSHTime
    return hours >= (SanityTraits.DESPAIR.SH_COOLDOWN_HOURS or 24)
end

-- ── Suicidal moodle active check ─────────────────────────────────────────────
-- Returns true if the moodle should be shown (stage qualifies + not suppressed).
function SanityTraits.isSuicidalMoodleActive(player)
    if SanityTraits.isSystemDisabled(player) then return false end
    local md = player:getModData().SanityTraits
    if not md then return false end
    local stageKey = SanityTraits.computeStage(md.sanity or 0)
    if stageKey ~= "hollow" and stageKey ~= "numb" and stageKey ~= "broken" then return false end
    local now = getGameTime():getWorldAgeHours()
    return not (md.suicidalSuppressedUntil and now < md.suicidalSuppressedUntil)
end

-- ── Substance suppression ────────────────────────────────────────────────────
-- Called by ISDrinkFluidAction and ISTakePillAction monkey-patches below.
-- Extends md.suicidalSuppressedUntil forward; logs substanceUseCount for Phase 5.
function SanityTraits.suppressSuicidalMoodle(player)
    if SanityTraits.isSystemDisabled(player) then return end
    local md = player:getModData().SanityTraits
    if not md then return end
    local stageKey = SanityTraits.computeStage(md.sanity or 0)
    if stageKey ~= "hollow" and stageKey ~= "numb" and stageKey ~= "broken" then return end

    local hours = SanityTraits.DESPAIR.SUBSTANCE_SUPPRESS_HOURS or 4
    if stageKey == "broken" then hours = hours / 2 end  -- barely works at Broken

    local nowH  = getGameTime():getWorldAgeHours()
    local until_ = math.max(md.suicidalSuppressedUntil or 0, nowH + hours)
    md.suicidalSuppressedUntil = until_
    md.substanceUseCount = (md.substanceUseCount or 0) + 1

    print(SanityTraits.LOG_TAG .. " [Despair] substance suppression: +" .. hours
        .. "h (suppressed until " .. string.format("%.1f", until_)
        .. "h, total uses=" .. tostring(md.substanceUseCount) .. ")")
end

-- ── Thought bubbles + Numb auto-trigger (EveryTenMinutes) ────────────────────
-- Separate registration from 6_TimedDecay so concerns stay isolated.
local function onDespairTick()
    local player = getPlayer()
    if not player then return end
    if SanityTraits.isSystemDisabled(player) then return end
    local md = player:getModData().SanityTraits
    if not md then return end

    local stageKey = SanityTraits.computeStage(md.sanity or 0)
    local D = SanityTraits.DESPAIR

    -- Thought bubbles: Hollow and Numb stages only (Broken = apathy, silence)
    local bubbleChance = 0
    if     stageKey == "hollow" then bubbleChance = D.THOUGHT_BUBBLE_CHANCE_HOLLOW
    elseif stageKey == "numb"   then bubbleChance = D.THOUGHT_BUBBLE_CHANCE_NUMB
    end
    if bubbleChance > 0 and ZombRand(100) < bubbleChance then
        local pool = SanityTraits.THOUGHT_BUBBLES
        if pool and #pool > 0 then
            player:Say(pool[ZombRand(#pool) + 1])
        end
    end

    -- Auto-trigger: Numb only (Broken = don't care enough to act; Hollow = not yet automatic)
    if stageKey == "numb" and ZombRand(100) < (D.AUTO_TRIGGER_CHANCE_NUMB or 5) then
        if SanityTraits.isSuicidalMoodleActive(player) then
            print(SanityTraits.LOG_TAG .. " [Despair] auto-trigger fired (Numb)")
            SanityTraits.triggerDespairAction(player, false, nil)
        end
    end
end
Events.EveryTenMinutes.Add(onDespairTick)

-- ── triggerDespairAction ──────────────────────────────────────────────────────
-- withHesitation: true = long timed action (Hollow); false = near-instant (Numb/Broken)
-- method: "gun" | "sharp" | nil (nil = auto-pick based on inventory)
function SanityTraits.triggerDespairAction(player, withHesitation, method)
    if not player then return end
    if SanityTraits.isSystemDisabled(player) then return end

    if not method then
        local weapon = player:getPrimaryHandItem()
        local gunReady = weapon
            and weapon.IsWeapon and weapon:IsWeapon()
            and weapon.isRanged and weapon:isRanged()
            and weapon.getCurrentAmmoCount and weapon:getCurrentAmmoCount() > 0
        if gunReady then
            method = "gun"
        elseif SanityTraits.findSharpItem(player) then
            method = "sharp"
        else
            return  -- no method available
        end
    end

    if method == "gun" then
        if not (ISSTDespairGunAction) then return end
        local action = ISSTDespairGunAction:new(player, withHesitation)
        ISTimedActionQueue.add(action)
    elseif method == "sharp" then
        if not SanityTraits.canSHAgain(player) then return end
        local item = SanityTraits.findSharpItem(player)
        if not item then return end
        if not (ISSTDespairSharpAction) then return end
        local action = ISSTDespairSharpAction:new(player, item)
        ISTimedActionQueue.add(action)
    end
end

-- ── Give Up context menu (invoked by SanityPanel button) ─────────────────────
function SanityTraits.onGiveUpClick(player)
    if not player then return end
    if SanityTraits.isSystemDisabled(player) then return end
    local md = player:getModData().SanityTraits
    if not md then return end

    local stageKey      = SanityTraits.computeStage(md.sanity or 0)
    local withHesitation = (stageKey == "hollow")

    local weapon = player:getPrimaryHandItem()
    local hasGun = weapon
        and weapon.IsWeapon and weapon:IsWeapon()
        and weapon.isRanged and weapon:isRanged()
        and weapon.getCurrentAmmoCount and weapon:getCurrentAmmoCount() > 0
    local hasSharp  = SanityTraits.findSharpItem(player) ~= nil
    local sharpOk   = hasSharp and SanityTraits.canSHAgain(player)

    if not hasGun and not hasSharp then return end

    local context = ISContextMenu.get(0, getMouseX(), getMouseY())

    if hasGun then
        context:addOption("Firearm", player, SanityTraits.triggerDespairAction, withHesitation, "gun")
    end
    if sharpOk then
        context:addOption("Sharp object", player, SanityTraits.triggerDespairAction, withHesitation, "sharp")
    elseif hasSharp then
        local opt = context:addOption("Sharp object  (cooldown active)", player, nil)
        opt.notAvailable = true
    end
end

-- ── Custom Suicidal moodle HUD ────────────────────────────────────────────────
-- ISPanel subclass anchored to the right side of the screen near vanilla moodles.
-- Color-coded per stage: Hollow=yellow, Numb=orange, Broken=dark-red.
-- Fades to 30% alpha when suppressed by substances; shows remaining suppression
-- hours as a small label below the icon.
local DespairMoodleHUD = ISPanel:derive("DespairMoodleHUD")

function DespairMoodleHUD:new()
    local o = ISPanel.new(self, 0, 130, 52, 52)
    setmetatable(o, self)
    self.__index = self
    o:noBackground()
    return o
end

function DespairMoodleHUD:prerender()
    -- Re-anchor to screen right edge every frame to handle resolution changes.
    self:setX(getCore():getScreenWidth() - 58)
end

function DespairMoodleHUD:render()
    local player = getPlayer()
    if not player or SanityTraits.isSystemDisabled(player) then return end
    local md = player:getModData().SanityTraits
    if not md then return end

    local stageKey = SanityTraits.computeStage(md.sanity or 0)
    if stageKey ~= "hollow" and stageKey ~= "numb" and stageKey ~= "broken" then return end

    -- Lazy texture load (getTexture is safe to call per-frame after load)
    if not self.iconTex then
        self.iconTex = getTexture("media/ui/Moodles/48/Mood_Sad.png")
    end
    if not self.iconTex then return end

    local now = getGameTime():getWorldAgeHours()
    local isSuppressed = md.suicidalSuppressedUntil and now < md.suicidalSuppressedUntil

    local alpha = isSuppressed and 0.3 or 1.0
    local r, g, b
    if     stageKey == "hollow" then r, g, b = 0.9, 0.8, 0.2
    elseif stageKey == "numb"   then r, g, b = 1.0, 0.5, 0.1
    else                             r, g, b = 0.8, 0.1, 0.1 end

    self:drawTextureScaledAspect(self.iconTex, 2, 2, 48, 48, alpha, r, g, b)

    -- If suppressed: show remaining hours in small text below icon
    if isSuppressed then
        local left = md.suicidalSuppressedUntil - now
        self:drawText(string.format("%.1fh", left), 2, 50, 0.6, 0.6, 0.6, 0.7, UIFont.Small)
    end
end

local function onGameStart_DespairHUD()
    local hud = DespairMoodleHUD:new()
    hud:initialise()
    hud:instantiate()
    hud:addToUIManager()
end
Events.OnGameStart.Add(onGameStart_DespairHUD)

-- ── Substance monkey-patches (chains off Phase 5 patches in 6_TimedDecay.lua) ─
-- Alcohol: chains off ISDrinkFluidAction.complete (Phase 5 already patched it)
local _orig_ISDrinkFluidAction_complete_despair = ISDrinkFluidAction.complete
function ISDrinkFluidAction:complete()
    local result = _orig_ISDrinkFluidAction_complete_despair(self)
    if self.character
       and self.character == getPlayer()
       and not SanityTraits.isSystemDisabled(self.character)
       and self.character:getModData().SanityTraits
       and self.fluidContainer then
        local props = self.fluidContainer:getProperties()
        if props and props.getAlcohol and props:getAlcohol() > 0 then
            SanityTraits.suppressSuicidalMoodle(self.character)
        end
    end
    return result
end

-- Anti-depressants, sleeping pills, beta-blockers, xanax:
-- Phase 5 only tracks getType()=="Pills" (vanilla painkillers); these other pill types
-- are excluded from the Phase 5 habit counter but DO suppress the despair moodle.
local _orig_ISTakePillAction_complete_despair = ISTakePillAction.complete
function ISTakePillAction:complete()
    local result = _orig_ISTakePillAction_complete_despair(self)
    if self.character
       and self.character == getPlayer()
       and not SanityTraits.isSystemDisabled(self.character)
       and self.character:getModData().SanityTraits
       and self.item and self.item.getType then
        local t = self.item:getType()
        if t == "PillsAntiDep"
        or t == "PillsSleepingTablets"
        or t == "PillsBeta"
        or t == "PillsXanax" then
            SanityTraits.suppressSuicidalMoodle(self.character)
        end
    end
    return result
end

print(SanityTraits.LOG_TAG .. " DespairMoodle loaded: HUD + thought bubbles + auto-trigger + substance suppression")
