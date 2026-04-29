--[[
BanditMapMarkers — replaces the BanditEventMarker on-screen draggable widget with:
  (REPLACE) persistent world-map symbol at the event's world coordinates
  (B) one-line chat alert in the player's chatbox, colored by event type
  (C) 2-second top-right fade icon as a "look at me" pulse

Single chokepoint: BanditEventMarkerHandler.set(eventID, icon, duration, posX, posY, color, desc)

This catches every caller in Bandits + BanditsWeekOne:
  - Home (player base) — green, 1 week
  - Arson — red, 1 hour
  - Protests — green, 8 hours
  - Entertainment — pink, 1 hour
  - Cops, SWAT, Paramedics, Firemen — 1 hour each
  - Plus all Bandits-internal markers (raids, bandit events, etc.)

The original BanditEventMarker UI element is also stubbed (render/prerender/update no-ops)
as belt-and-suspenders against any caller that bypasses the handler.
]]

if not BanditEventMarkerHandler then return end

BanditMapMarkers = BanditMapMarkers or {}
BanditMapMarkers.markers = BanditMapMarkers.markers or {}  -- [eventID] = {icon, posX, posY, color, desc, expireAt}
BanditMapMarkers.flashes = BanditMapMarkers.flashes or {}  -- queued flash UI elements

----------------------------------------------------------------------
-- (C) Flash UI element — top-right 2-second fade
----------------------------------------------------------------------

require "ISUI/ISUIElement"

BanditMapMarkerFlash = ISUIElement:derive("BanditMapMarkerFlash")

local FLASH_SIZE = 64
local FLASH_DURATION_MS = 2000
local FLASH_FADE_IN_MS = 200
local FLASH_FADE_OUT_MS = 600
local FLASH_RIGHT_OFFSET = 32   -- px from right edge
local FLASH_TOP_OFFSET = 120    -- px from top edge (below moodles)

function BanditMapMarkerFlash:new(icon, color, desc)
    local screenW = getCore():getScreenWidth()
    local x = screenW - FLASH_SIZE - FLASH_RIGHT_OFFSET
    local y = FLASH_TOP_OFFSET + (#BanditMapMarkers.flashes * (FLASH_SIZE + 8))  -- stack
    local o = ISUIElement:new(x, y, FLASH_SIZE, FLASH_SIZE)
    setmetatable(o, self)
    self.__index = self
    o.startMs = getTimeInMillis()
    o.icon = icon and getTexture(icon) or nil
    o.color = color or {r=1, g=1, b=1, a=1}
    o.desc = desc or ""
    o.bConsumeMouseEvents = false
    o.moveWithMouse = false
    return o
end

function BanditMapMarkerFlash:initialise()
    ISUIElement.initialise(self)
    self:addToUIManager()
    table.insert(BanditMapMarkers.flashes, self)
end

function BanditMapMarkerFlash:render()
    local elapsed = getTimeInMillis() - self.startMs
    if elapsed > FLASH_DURATION_MS then
        self:setVisible(false)
        self:removeFromUIManager()
        for i, f in ipairs(BanditMapMarkers.flashes) do
            if f == self then table.remove(BanditMapMarkers.flashes, i); break end
        end
        return
    end

    local alpha = 1.0
    if elapsed < FLASH_FADE_IN_MS then
        alpha = elapsed / FLASH_FADE_IN_MS
    elseif elapsed > (FLASH_DURATION_MS - FLASH_FADE_OUT_MS) then
        alpha = (FLASH_DURATION_MS - elapsed) / FLASH_FADE_OUT_MS
    end

    -- Background tint behind icon for readability
    self:drawRect(0, 0, FLASH_SIZE, FLASH_SIZE, alpha * 0.5, 0, 0, 0)
    -- Colored border in event color
    self:drawRectBorder(0, 0, FLASH_SIZE, FLASH_SIZE, alpha, self.color.r, self.color.g, self.color.b)
    -- Icon
    if self.icon then
        self:drawTextureScaled(self.icon, 4, 4, FLASH_SIZE - 8, FLASH_SIZE - 8, alpha, 1, 1, 1)
    end
    -- Description label below icon
    if self.desc and self.desc ~= "" then
        self:drawText(self.desc, 0, FLASH_SIZE + 2, self.color.r, self.color.g, self.color.b, alpha, UIFont.Small)
    end
end

function BanditMapMarkerFlash:prerender() end

function BanditMapMarkers.Flash(icon, color, desc)
    local f = BanditMapMarkerFlash:new(icon, color, desc)
    f:initialise()
    return f
end

----------------------------------------------------------------------
-- (REPLACE) Override BanditEventMarkerHandler.set
----------------------------------------------------------------------

BanditMapMarkers.OriginalSet = BanditMapMarkers.OriginalSet or BanditEventMarkerHandler.set

BanditEventMarkerHandler.set = function(eventID, icon, duration, posX, posY, color, desc)
    if not eventID or not posX or not posY then return end
    color = color or {r = 1, g = 1, b = 1, a = 1}

    -- Store marker for map-open render
    BanditMapMarkers.markers[eventID] = {
        icon = icon,
        posX = posX,
        posY = posY,
        color = color,
        desc = desc or "Event",
        startedAt = getGametimeTimestamp(),
        duration = duration or 3600,
        expireAt = getGametimeTimestamp() + (duration or 3600),
        symbolRef = nil,  -- filled when added to map UI
    }

    -- (B) Chat alert
    local player = getSpecificPlayer(0)
    if player then
        local descText = desc or "Event"
        local locText = string.format(" (%d, %d)", math.floor(posX), math.floor(posY))
        player:addLineChatElement(descText .. locText, color.r or 1, color.g or 1, color.b or 1)
    end

    -- (C) Flash icon
    pcall(function() BanditMapMarkers.Flash(icon, color, desc) end)

    -- If the world map is currently open, add symbol immediately
    pcall(function() BanditMapMarkers.AddSymbolToOpenMap(eventID) end)
end

----------------------------------------------------------------------
-- World map hook — add stored symbols when map opens
----------------------------------------------------------------------

BanditMapMarkers.activeMapUI = nil  -- track currently-open map UI

local function addAllSymbolsToMap(mapUI)
    if not mapUI or not mapUI.mapAPI then return end
    local symbolsAPI = mapUI.mapAPI:getSymbolsAPIv2()
    if not symbolsAPI then return end

    local now = getGametimeTimestamp()
    for eventID, m in pairs(BanditMapMarkers.markers) do
        if (m.expireAt or 0) > now then
            -- Only add if not already added in this map session
            if not m.symbolRef or m.symbolRef.mapUI ~= mapUI then
                local ok, sym = pcall(function()
                    if m.icon and m.icon ~= "" then
                        return symbolsAPI:addTexture(m.icon, m.posX, m.posY)
                    end
                end)
                if ok and sym then
                    m.symbolRef = {symbol = sym, mapUI = mapUI}
                end
            end
        end
    end
end

function BanditMapMarkers.AddSymbolToOpenMap(eventID)
    if not BanditMapMarkers.activeMapUI then return end
    local mapUI = BanditMapMarkers.activeMapUI
    if not mapUI or not mapUI.mapAPI then return end
    local symbolsAPI = mapUI.mapAPI:getSymbolsAPIv2()
    if not symbolsAPI then return end
    local m = BanditMapMarkers.markers[eventID]
    if not m then return end
    pcall(function()
        if m.icon and m.icon ~= "" then
            local sym = symbolsAPI:addTexture(m.icon, m.posX, m.posY)
            if sym then m.symbolRef = {symbol = sym, mapUI = mapUI} end
        end
    end)
end

-- Hook ISWorldMap:createChildren so we add symbols on map open
if ISWorldMap then
    BanditMapMarkers.OriginalCreateChildren = BanditMapMarkers.OriginalCreateChildren or ISWorldMap.createChildren
    function ISWorldMap:createChildren(...)
        local result = BanditMapMarkers.OriginalCreateChildren(self, ...)
        BanditMapMarkers.activeMapUI = self
        pcall(function() addAllSymbolsToMap(self) end)
        return result
    end

    -- On close, drop our active reference
    BanditMapMarkers.OriginalClose = BanditMapMarkers.OriginalClose or ISWorldMap.close
    if BanditMapMarkers.OriginalClose then
        function ISWorldMap:close(...)
            if BanditMapMarkers.activeMapUI == self then
                BanditMapMarkers.activeMapUI = nil
                -- Clear our symbol refs (they belonged to the closing UI)
                for _, m in pairs(BanditMapMarkers.markers) do
                    if m.symbolRef and m.symbolRef.mapUI == self then
                        m.symbolRef = nil
                    end
                end
            end
            return BanditMapMarkers.OriginalClose(self, ...)
        end
    end
end

----------------------------------------------------------------------
-- Belt-and-suspenders: stub the original UI widget
----------------------------------------------------------------------

if BanditEventMarker then
    BanditEventMarker.render = function(self) end
    BanditEventMarker.prerender = function(self) end
    BanditEventMarker.update = function(self) end
    -- Keep :setDuration so existing handler logic doesn't error,
    -- but it has no visible effect now.
end

----------------------------------------------------------------------
-- Cleanup expired markers
----------------------------------------------------------------------

local function cleanupExpired()
    local now = getGametimeTimestamp()
    local toRemove = {}
    for eventID, m in pairs(BanditMapMarkers.markers) do
        if (m.expireAt or 0) <= now then
            table.insert(toRemove, eventID)
        end
    end
    for _, eventID in ipairs(toRemove) do
        local m = BanditMapMarkers.markers[eventID]
        -- Remove from map if still attached
        if m and m.symbolRef and m.symbolRef.mapUI and m.symbolRef.mapUI.mapAPI then
            pcall(function()
                local symbolsAPI = m.symbolRef.mapUI.mapAPI:getSymbolsAPIv2()
                if symbolsAPI and m.symbolRef.symbol then
                    symbolsAPI:removeSymbol(m.symbolRef.symbol)
                end
            end)
        end
        BanditMapMarkers.markers[eventID] = nil
    end
end

Events.EveryTenMinutes.Add(cleanupExpired)

----------------------------------------------------------------------
-- Init log
----------------------------------------------------------------------

print("[BanditMapMarkers] loaded — replaces BanditEventMarker UI with map symbols + chat alert + flash")
