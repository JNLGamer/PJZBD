-- ProjectZLife / 30_PZLife_ItemPrices.lua
-- M2 Phase 5: Item price tags in inventory (ITEMS-01..04). Absorbs BanditsWeekOneItemTags.
--
-- WHAT: When the player views a container that's NOT theirs (a shop's till, a
-- house's fridge, etc.), each item gets a price prefix (`$NN`) or property
-- marker (`#`) drawn in green/red. Replicates BWO's required-mod-stack
-- functionality natively so users don't need to install a separate mod.
--
-- ALGORITHM (faithful reimplementation of BWOInventoryMarkers.lua, line-by-line
-- semantically, namespaced as PZLife.ItemPrices.*):
--   * Skip player-owned containers (worn clothing, hand inventory, items the
--     player picked up)
--   * Look up the room the container's parent object sits in
--   * Ask BWORooms.TakeIntention(room, customName) for the (canTake,
--     shouldPay) tuple — this is the canonical room intent classifier from
--     BWO that decides "shop" vs "private property" vs "free"
--   * If shouldPay: price = floor(weight × PriceMultiplier × 10) routed
--     through BanditUtils.AddPriceInflation(); color is green if player has
--     enough Money items, red otherwise
--   * If canTake == false (private property, not a shop): show "#" red marker
--   * Else (free territory): no marker
--
-- DEPENDENCIES (still load because Project Z Life require=Bandits2,BanditsWeekOne):
--   * BWORooms.TakeIntention — room classifier
--   * BanditUtils.AddPriceInflation — economy curve
--   * SandboxVars.BanditsWeekOne.PriceMultiplier — global multiplier
--
-- HOOK: Monkey-patches ISInventoryPane.renderdetails after the original runs,
-- only when doDragged == false (so prices don't flash during drag operations).
-- Idempotent: __pzlifeHookedRenderDetails guard prevents double-hooking on
-- save/reload cycles.
--
-- M2 P5.1 (deferred): Inventory Tetris tooltip integration. Tetris hooks
-- ISInventoryPane.updateTooltip / ISInventoryPane.doTooltipForItem; need a
-- separate hook chain that doesn't conflict with Tetris's own patches. Will
-- ship as a decimal phase insertion when M2 P5 vanilla-pane is UAT-validated.
--
-- DECISIONS LOGGED:
--   D-12 (M2 P5): Wire-compatible with existing BWOItemTags algorithm. Same
--     PriceMultiplier sandbox key, same inflation function, same money-count
--     predicate. Saves migrating from BWOItemTags-era games see identical
--     pricing — no economic shock.
--   D-13 (M2 P5): No new sandbox keys this phase. The BanditsWeekOne
--     PriceMultiplier sandbox value is the single tuning knob. M4 P22
--     consolidation may expose ProjectZLife-specific multipliers as needed.
--   D-14 (M2 P5): Tetris compat deferred to M2 P5.1 (decimal-phase
--     insertion). Vanilla pane hook ships now; Tetris ships once vanilla
--     UAT confirms the algorithm works.

require("ISUI/ISInventoryPane")

PZLife = PZLife or {}
PZLife.ItemPrices = PZLife.ItemPrices or {}

-- ── Logging ──────────────────────────────────────────────────────────────────

PZLife.ItemPrices.DEBUG = false  -- flip true for verbose debug

local function dbgLog(msg)
    if not PZLife.ItemPrices.DEBUG then return end
    print(PZLife.LOG_TAG .. " ItemPrices: " .. tostring(msg))
end

local function safeCall(fn, ...)
    local ok, a, b, c = pcall(fn, ...)
    if not ok then
        dbgLog("ERROR: " .. tostring(a))
        return nil
    end
    return a, b, c
end

-- ── Internal helpers (faithful copies from BWOInventoryMarkers) ──────────────

local function getContainerCustomName(object)
    if not object then return nil end
    local sprite = (object.getSprite and object:getSprite()) or nil
    if not sprite then return nil end
    local props = (sprite.getProperties and sprite:getProperties()) or nil
    if not props then return nil end
    local val = safeCall(function()
        if props.Val then
            return props:Val("CustomName")
        end
        return nil
    end)
    if val and val ~= "" then return val end
    return nil
end

local function isPlayerOwnedContainer(container, player)
    if not container then return false end

    if player and player.getInventory and container == player:getInventory() then
        return true
    end

    local parent = (container.getParent and container:getParent()) or nil
    if parent and instanceof(parent, "IsoPlayer") then
        return true
    end

    local containingItem = (container.getContainingItem and container:getContainingItem()) or nil
    if containingItem then
        local ownerContainer = (containingItem.getContainer and containingItem:getContainer()) or nil
        if ownerContainer then
            if player and player.getInventory and ownerContainer == player:getInventory() then
                return true
            end
            local ownerParent = (ownerContainer.getParent and ownerContainer:getParent()) or nil
            if ownerParent and instanceof(ownerParent, "IsoPlayer") then
                return true
            end
        end
    end

    return false
end

-- ── Public API ───────────────────────────────────────────────────────────────

-- Returns { text = "$NN" or "#", color = {r,g,b,a} } or nil for no marker.
-- Public so other modules (e.g. M2 P5.1 Tetris hook, M2 P10 job income) can
-- call it for the same room-intent classification.
function PZLife.ItemPrices.GetItemMarker(container, item, player, totalWeight)
    if not container or not item then return nil end
    if not BWORooms or not BWORooms.TakeIntention then
        -- BWORooms is part of BanditsWeekOne — should always be loaded since
        -- we declare require=BanditsWeekOne. If we ever drop that require,
        -- this guard becomes the silent-degradation path.
        return nil
    end

    -- Skip body-slot containers
    if container.getType and (container:getType() == "inventorymale" or container:getType() == "inventoryfemale") then
        return nil
    end
    if isPlayerOwnedContainer(container, player) then
        return nil
    end

    -- Find the world object → square → room
    local object = (container.getParent and container:getParent()) or nil
    if not object then return nil end
    local square = (object.getSquare and object:getSquare()) or nil
    if not square then return nil end
    local room = (square.getRoom and square:getRoom()) or nil
    if not room then return nil end

    local customName = getContainerCustomName(object)

    local canTake, shouldPay = safeCall(function()
        return BWORooms.TakeIntention(room, customName)
    end)

    if canTake == nil and shouldPay == nil then
        return nil
    end

    if shouldPay then
        local weight = totalWeight
        if weight == nil then
            weight = item.getActualWeight and item:getActualWeight() or 0
        end
        local multiplier = (SandboxVars and SandboxVars.BanditsWeekOne and SandboxVars.BanditsWeekOne.PriceMultiplier) or 1
        local priceBase = weight * multiplier * 10
        local price
        if BanditUtils and BanditUtils.AddPriceInflation then
            price = BanditUtils.AddPriceInflation(priceBase)
        else
            price = math.floor(priceBase)
        end
        if price == 0 then price = 1 end

        -- Count Money items in player inventory (recursive)
        local moneyCount = 0
        if player and player.getInventory then
            local function predicateMoney(it)
                return it:getType() == "Money"
            end
            local inventory = player:getInventory()
            local items = ArrayList.new()
            inventory:getAllEvalRecurse(predicateMoney, items)
            moneyCount = items:size()
        end

        local canPay = moneyCount >= price
        local color = canPay and { r = 0, g = 1, b = 0, a = 1 }
                              or { r = 1, g = 0, b = 0, a = 1 }
        return { text = "$" .. tostring(price), color = color }
    end

    if canTake == false then
        return { text = "#", color = { r = 1, g = 0, b = 0, a = 1 } }
    end

    return nil
end

-- ── Render helper for the inventory pane ─────────────────────────────────────

local function drawItemPrefixInDetails(pane)
    if not pane.items or not pane.inventory then return end

    local font = pane.font or UIFont.Small
    local textManager = getTextManager()
    local fh = textManager:getFontHeight(font)
    local textDY = (pane.itemHgt - fh) / 2
    local yScroll = pane.getYScroll and pane:getYScroll() or 0
    local height = pane.getHeight and pane:getHeight() or 0
    local player = getSpecificPlayer(pane.player)
    local padding = 6

    for index, entry in ipairs(pane.items) do
        local item = entry
        local totalWeight = nil
        if entry.items then
            item = entry.items[1]
            if entry.weight then
                totalWeight = entry.weight
            elseif entry.count and entry.count > 1 then
                local perItemWeight = item.getActualWeight and item:getActualWeight() or 0
                totalWeight = perItemWeight * math.max(1, entry.count - 1)
            end
        end
        if item then
            local topOfItem = (index - 1) * pane.itemHgt + yScroll
            if not ((topOfItem + pane.itemHgt < 0) or (topOfItem > height)) then
                local marker = PZLife.ItemPrices.GetItemMarker(pane.inventory, item, player, totalWeight)
                if marker and marker.text and marker.color then
                    local y = ((index - 1) * pane.itemHgt) + pane.headerHgt + textDY
                    local textWidth = textManager:MeasureStringX(font, marker.text)
                    local x = pane.column4 - textWidth - padding
                    pane:drawText(marker.text, x, y, marker.color.r, marker.color.g, marker.color.b, marker.color.a, font)
                end
            end
        end
    end
end

-- ── Monkey-patch hook installation (idempotent) ──────────────────────────────

local function hookInventoryPaneRenderDetails()
    if not ISInventoryPane or not ISInventoryPane.renderdetails then return end
    if ISInventoryPane.__pzlifeHookedRenderDetails then return end

    ISInventoryPane.__pzlifeHookedRenderDetails = true
    local origRenderDetails = ISInventoryPane.renderdetails
    ISInventoryPane.renderdetails = function(self, doDragged)
        local result = origRenderDetails(self, doDragged)
        if doDragged == false then
            drawItemPrefixInDetails(self)
        end
        return result
    end

    print(PZLife.LOG_TAG .. " ItemPrices: hooked ISInventoryPane.renderdetails")
end

hookInventoryPaneRenderDetails()

print(PZLife.LOG_TAG .. " ItemPrices loaded (ITEMS-01..04)")
