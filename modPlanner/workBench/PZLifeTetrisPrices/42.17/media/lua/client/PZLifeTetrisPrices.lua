--[[
PZLifeTetrisPrices — show price tags in BOTH vanilla inventory AND Inventory Tetris tooltips.

The existing `BanditsWeekOneAddonItemTags` mod hooks `ISInventoryPane.renderdetails`
to draw price tags in the right-hand vanilla details list. That hook does NOT
fire when Inventory Tetris is active because Tetris replaces the rendering
mode with grid cells.

What both UIs DO share: they both spawn `ISToolTipInv` for the hover tooltip.
By wrapping `ISToolTipInv:render` we inject a price line into the tooltip
regardless of which inventory UI is active.

Reuses the price-calc function `BWOItemTags.GetItemMarker(container, item, player, totalWeight)`
which returns:
  {text="$<price>", color={r,g,b,a}}  for buyable
  {text="#",        color=red}        for property (theft)
  nil                                  if not in a flagged container

We append a colored "Price: $X" line just below the existing tooltip rectangle.
]]

if not ISToolTipInv then return end
if not BWOItemTags or not BWOItemTags.GetItemMarker then
    print("[PZLifeTetrisPrices] BWOItemTags not loaded; will retry on game start")
end

PZLifeTetrisPrices = PZLifeTetrisPrices or {}

local function getMarkerSafely(item, player)
    if not BWOItemTags or not BWOItemTags.GetItemMarker then return nil end
    if not item or not item.getContainer then return nil end
    local container = item:getContainer()
    if not container then return nil end
    local ok, marker = pcall(BWOItemTags.GetItemMarker, container, item, player, nil)
    if ok then return marker end
    return nil
end

PZLifeTetrisPrices.OriginalRender = PZLifeTetrisPrices.OriginalRender or ISToolTipInv.render

function ISToolTipInv:render()
    PZLifeTetrisPrices.OriginalRender(self)

    local item = self.item
    if not item then return end

    -- Resolve player from tooltip's character; tooltip stores it via setCharacter
    local player = (self.character or self:getCharacter and self:getCharacter()) or getSpecificPlayer(0)

    local marker = getMarkerSafely(item, player)
    if not marker or not marker.text then return end

    -- Render the price text in a small bordered rect below the tooltip
    local tt = self.tooltip
    if not tt then return end

    local font = UIFont.Small
    local fh = getTextManager():getFontHeight(font)
    local label = "Price: " .. marker.text
    local tw = getTextManager():MeasureStringX(font, label)
    local padX, padY = 6, 3
    local boxW = tw + padX * 2
    local boxH = fh + padY * 2
    local boxX = tt:getX()
    local boxY = tt:getY() + tt:getHeight() + 2

    -- background + border
    self:drawRect(boxX - self.x, boxY - self.y, boxW, boxH, 0.85, 0, 0, 0)
    self:drawRectBorder(boxX - self.x, boxY - self.y, boxW, boxH, 1, 0.5, 0.5, 0.5)
    -- text
    self:drawText(label, boxX - self.x + padX, boxY - self.y + padY,
        marker.color.r or 1, marker.color.g or 1, marker.color.b or 1, marker.color.a or 1,
        font)
end

if Events and Events.OnGameStart then
    Events.OnGameStart.Add(function()
        if BWOItemTags and BWOItemTags.GetItemMarker then
            print("[PZLifeTetrisPrices] loaded — price tooltip injection active for vanilla + Tetris")
        else
            print("[PZLifeTetrisPrices] WARNING: BWOItemTags not found; tooltip injection inactive")
        end
    end)
end
