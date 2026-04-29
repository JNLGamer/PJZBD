# PZ UI Elements Reference

> Build 42 — extracted from `ProjectZomboid/media/lua/client/ISUI/`
> All coordinates are local to the parent element unless noted otherwise.
> Color values are 0.0–1.0 floats.

---

## Class Summary

| Class | Inherits | Description |
|-------|----------|-------------|
| `ISUIElement` | `ISBaseObject` | Abstract base class. All UI inherits from this. |
| `ISPanel` | `ISUIElement` | Filled rectangle; general-purpose container. |
| `ISWindow` | `ISUIElement` | Titled, resizable window with client-area helpers. |
| `ISButton` | `ISPanel` | Clickable button with hover/press animation and tooltip. |
| `ISLabel` | `ISUIElement` | Single-line text display. Auto-sizes to text. |
| `ISImage` | `ISPanel` | Texture display with optional click callback. |
| `ISScrollBar` | `ISUIElement` | Vertical or horizontal scroll bar; used internally by scroll-aware panels. |
| `ISTickBox` | `ISPanel` | List of labelled checkboxes, optional radio-button mode. |
| `ISTextEntryBox` | `ISPanelJoypad` | Single- or multi-line editable text field. |
| `ISScrollingListBox` | `ISPanelJoypad` | Scrollable list of text rows with selection. |
| `ISContextMenu` | `ISPanel` | Right-click style drop-down menu with optional sub-menus. |
| `ISRadialMenu` | `ISPanelJoypad` | Circular slice menu (for joypad / radial actions). |
| `ISTabPanel` | `ISPanel` | Tabbed container; each tab shows one child panel. |
| `ISRichTextPanel` | `ISPanel` | Markup-driven text panel supporting colour, size, and image tags. |
| `ISToolTip` | `ISPanel` | Floating tooltip that auto-sizes to title + description. |

---

## UIFont Constants

Used everywhere a `font` parameter is required.

```lua
UIFont.Small       -- most common default
UIFont.NewSmall
UIFont.Medium
UIFont.Large
UIFont.Normal
UIFont.Massive
UIFont.Intro
UIFont.Cred1
UIFont.Cred2
```

---

## ISUIElement

Base class. Every widget inherits all methods listed here.

### Constructor

```lua
ISUIElement:new(x, y, width, height)
```

| Param | Type | Description |
|-------|------|-------------|
| `x` | number | Left edge, relative to parent (or screen if root) |
| `y` | number | Top edge |
| `width` | number | Pixel width |
| `height` | number | Pixel height |

### Lifecycle Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `initialise` | `()` | Must call after `new()`. Sets up `self.children`. |
| `instantiate` | `()` | Creates the Java-side `javaObject`. Called automatically by most operations. |
| `createChildren` | `()` | Override to create child widgets instead of `initialise()`. |
| `addToUIManager` | `()` | Makes the element visible and managed by the engine. |
| `removeFromUIManager` | `()` | Hides and unregisters from the engine. Sets `self.removed = true`. |
| `close` | `()` | Calls `setVisible(false)`. |

### Position and Size

| Method | Signature | Notes |
|--------|-----------|-------|
| `setX` | `(x)` | Clamps to screen edge if `getKeepOnScreen()` is true. |
| `setY` | `(y)` | Same clamping behaviour. |
| `setWidth` | `(w)` | |
| `setHeight` | `(h)` | |
| `getX` | `()` → number | |
| `getY` | `()` → number | |
| `getWidth` | `()` → number | |
| `getHeight` | `()` → number | |
| `getRight` | `()` → number | `x + width` |
| `getBottom` | `()` → number | `y + height` |
| `getAbsoluteX` | `()` → number | Screen-space X (accounts for all parent offsets). |
| `getAbsoluteY` | `()` → number | Screen-space Y. |
| `getCentreX` | `()` → number | `width / 2` |
| `getCentreY` | `()` → number | `height / 2` |
| `centerOnScreen` | `(playerNum)` | Moves element to screen centre for the given split-screen player. |
| `shrinkWrap` | `(padRight, padBottom [, predicate])` | Resizes to tightly contain children. |

### Anchoring (resize-with-parent)

```lua
self:setAnchorLeft(true)    -- follows left edge of parent (default true)
self:setAnchorRight(false)  -- stretches / follows right edge
self:setAnchorTop(true)     -- default true
self:setAnchorBottom(false) -- stretches / follows bottom edge

-- Convenience: set all four at once
self:setAnchorsTBLR(top, bottom, left, right)
self:setAnchors(bool)       -- sets all four to the same value
```

### Scroll Support

| Method | Notes |
|--------|-------|
| `addScrollBars([addHorizontal])` | Creates `self.vscroll` (and optionally `self.hscroll`). |
| `setScrollHeight(h)` | Sets virtual/content height; triggers scrollbar recalc. |
| `setScrollWidth(w)` | Sets virtual/content width. |
| `getScrollHeight()` | Returns virtual content height. |
| `setYScroll(y)` | Programmatic scroll; value is negative offset (0 = top). |
| `setXScroll(x)` | |
| `getYScroll()` | |
| `getXScroll()` | |
| `updateScrollbars()` | Recalculate scrollbar positions (called automatically). |
| `isVScrollBarVisible()` | `true` if content taller than view area. |

### Visibility and Input

| Method | Notes |
|--------|-------|
| `setVisible(bool)` | Show/hide. Triggers `visibleFunction` if set. |
| `isVisible()` | |
| `isReallyVisible()` | Checks parent chain too. |
| `setEnabled(bool)` | Enable/disable input processing. |
| `isEnabled()` | |
| `setWantKeyEvents(bool)` | Must be `true` for `onKeyPress` / `onKeyReleased` to fire. |
| `setWantExtraMouseEvents(bool)` | Enables `onMouseMove` / `onMouseMoveOutside`. |
| `setForceCursorVisible(bool)` | Always show OS cursor while over this element. |
| `setCapture(bool)` | Capture all mouse events even when mouse leaves bounds. |
| `bringToTop()` | Move to front of draw order. |
| `setAlwaysOnTop(bool)` | Always render above other elements. |
| `setRenderThisPlayerOnly(playerNum)` | Split-screen: only draw for one player. |

### Child Management

| Method | Signature | Notes |
|--------|-----------|-------|
| `addChild` | `(element)` | Instantiates both sides if needed; sets `element.parent = self`. |
| `removeChild` | `(element)` | Detaches from Java parent. |
| `clearChildren` | `()` | Removes all children. |
| `getChildren` | `()` → table | Keyed by `element.ID`. |
| `getParent` | `()` → element | |

### Drawing (call inside `render()` or `prerender()`)

All draw calls take coordinates **local to the element** (0,0 = top-left corner).

```lua
-- Filled rectangle
self:drawRect(x, y, w, h, a, r, g, b)

-- Border-only rectangle
self:drawRectBorder(x, y, w, h, a, r, g, b)

-- "Static" variants offset by scroll position (use for fixed-position chrome)
self:drawRectStatic(x, y, w, h, a, r, g, b)
self:drawRectBorderStatic(x, y, w, h, a, r, g, b)

-- Textures
self:drawTexture(texture, x, y, a [, r, g, b])
self:drawTextureScaled(texture, x, y, w, h, a [, r, g, b])
self:drawTextureScaledAspect(texture, x, y, w, h, a [, r, g, b])
self:drawTextureTiled(texture, x, y, w, h [, r, g, b, a])

-- Text
self:drawText(str, x, y, r, g, b, a [, font])       -- left-aligned
self:drawTextCentre(str, x, y, r, g, b, a [, font]) -- centred at x
self:drawTextRight(str, x, y, r, g, b, a [, font])  -- right-aligned at x

-- Convenience
self:drawProgressBar(x, y, w, h, fraction, fgColor)  -- fgColor = {r,g,b,a}

-- Load a texture
local tex = getTexture("media/ui/SomeFile.png")
```

### Event Hooks (override in subclasses)

| Hook | Signature | Notes |
|------|-----------|-------|
| `prerender` | `()` | Called before children render. Good for background fills. |
| `render` | `()` | Called after children render. |
| `update` | `()` | Called every frame, regardless of visibility. |
| `onMouseDown` | `(x, y)` | Left button pressed while over element. |
| `onMouseUp` | `(x, y)` | Left button released while over element. |
| `onMouseDownOutside` | `(x, y)` | Left button pressed outside bounds. |
| `onMouseUpOutside` | `(x, y)` | Left button released outside bounds. |
| `onRightMouseDown` | `(x, y)` | |
| `onRightMouseUp` | `(x, y)` | |
| `onMouseMove` | `(dx, dy)` | Mouse moved while over element. Requires `setWantExtraMouseEvents(true)`. |
| `onMouseMoveOutside` | `(dx, dy)` | Mouse moved while NOT over element. |
| `onMouseWheel` | `(delta)` → bool | `delta` is +1 (scroll up) or -1. Return `true` to consume. |
| `onFocus` | `(x, y)` | Element received focus (base calls `bringToTop` for roots). |
| `onLoseFocus` | `(x, y)` | Element lost focus. |
| `onResize` | `()` | Called when size changes; updates `self.width/height` and scrollbars. |
| `onKeyPress` | `(key)` | Requires `setWantKeyEvents(true)`. |

### Notable Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.x` | constructor | Local X position |
| `self.y` | constructor | Local Y position |
| `self.width` | constructor | |
| `self.height` | constructor | |
| `self.anchorLeft` | `true` | |
| `self.anchorRight` | `false` | |
| `self.anchorTop` | `true` | |
| `self.anchorBottom` | `false` | |
| `self.minimumWidth` | `0` | Enforced in `onResize`. |
| `self.minimumHeight` | `0` | |
| `self.removed` | `false` | Set to `true` by `removeFromUIManager`. |
| `self.parent` | `nil` | Set by `addChild`. |
| `self.children` | `{}` | Set by `initialise`. |
| `self.javaObject` | `nil` | Java-side peer; set by `instantiate`. |
| `self.keepOnScreen` | `nil` | If `nil`, roots are kept on screen; children are not. |

---

## ISPanel

General-purpose container with an optional filled background and border.

### Constructor

```lua
ISPanel:new(x, y, width, height)
```

### Additional Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.background` | `true` | Draw background rectangle in `prerender`. |
| `self.backgroundColor` | `{r=0,g=0,b=0,a=0.5}` | |
| `self.borderColor` | `{r=0.4,g=0.4,b=0.4,a=1}` | |
| `self.moveWithMouse` | `false` | If `true`, drag the panel by left-clicking and dragging. |

### Key Methods

| Method | Notes |
|--------|-------|
| `noBackground()` | Sets `self.background = false`. Disables fill and border. |
| `close()` | Calls `setVisible(false)`. |

### Usage Pattern

```lua
local panel = ISPanel:new(100, 100, 300, 200)
panel:initialise()
panel:instantiate()
panel.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
panel.borderColor = {r=0.6, g=0.6, b=0.6, a=1}
panel:addToUIManager()

-- Add a child
local child = ISLabel:new(10, 10, 20, "Hello", 1, 1, 1, 1, UIFont.Small, true)
child:initialise()
panel:addChild(child)
```

---

## ISWindow

Titled window with built-in resize handle at the bottom-right corner.

### Constructor

```lua
ISWindow:new(title, x, y, width, height)
```

| Param | Type | Description |
|-------|------|-------------|
| `title` | string | Drawn centred in the title bar |
| `x,y,width,height` | number | Geometry |

### Constants

```lua
ISWindow.TitleBarHeight = 19   -- height of the title bar in pixels
ISWindow.SideMargin     = 12   -- left/right client inset
ISWindow.BottomMargin   = 12   -- bottom client inset
```

### Client Area Helpers

| Method | Returns | Notes |
|--------|---------|-------|
| `getClientLeft()` | number | `SideMargin` |
| `getClientRight()` | number | `width - SideMargin` |
| `getClientTop()` | number | Title bar height + toolbar heights |
| `getClientBottom()` | number | `height - BottomMargin` |
| `getClientWidth()` | number | `width - SideMargin*2` |
| `getClientHeight()` | number | `height - BottomMargin - TitleBarHeight` |
| `getNClientTop()` | number | `TitleBarHeight` (without toolbars) |

### Toolbar Support

```lua
self:addToolbar(toolbarPanel, height)
self:removeToolbar(toolbarPanel)
self:getTotalToolbarHeight()    -- sum of all toolbar heights
```

### Notable Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.title` | constructor | Drawn in title bar by `render`. |
| `self.hasClose` | `true` | Whether a close button is expected (not drawn here — subclass responsibility). |
| `self.resizing` | `false` | Set to `true` during bottom-right corner drag. |

### Usage Pattern

```lua
local win = ISWindow:new("My Window", 200, 150, 400, 300)
win:initialise()
win:instantiate()
win:addToUIManager()

-- Place content inside client area
local btn = ISButton:new(win:getClientLeft(), win:getClientTop(), 100, 24, "OK", win, myCallback)
btn:initialise()
win:addChild(btn)
```

---

## ISButton

Clickable button. Supports icon, hover fade, tooltip, and repeat-while-held.

### Constructor

```lua
ISButton:new(x, y, width, height, title, clicktarget, onclick, onmousedown, allowMouseUpProcessing)
```

| Param | Type | Description |
|-------|------|-------------|
| `x,y,width,height` | number | Geometry. Width auto-expands to fit `title` text. |
| `title` | string | Label text |
| `clicktarget` | any | Passed as first arg to `onclick` |
| `onclick` | function | `onclick(clicktarget, button, arg1..arg4)` |
| `onmousedown` | function | `onmousedown(clicktarget, button, x, y)` — fires on press, not release |
| `allowMouseUpProcessing` | bool | If `true`, fires `onclick` even if mouse moved off and back on |

### Key Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `setTitle` | `(title)` | Change button text |
| `getTitle` | `()` → string | |
| `setFont` | `(UIFont)` | |
| `setImage` | `(texture)` | Show an icon; centered in the button |
| `setEnable` | `(bool)` | Greys out button and disables `onclick` |
| `isEnabled` | `()` → bool | |
| `setDisplayBackground` | `(bool)` | Show/hide the filled background |
| `setTooltip` | `(str)` | Hover tooltip text |
| `setWidthToTitle` | `([minWidth])` | Auto-size width to fit current title |
| `setOnClick` | `(func, arg1, arg2, arg3, arg4)` | Replaces the `onclick` function after construction |
| `setOnMouseOverFunction` | `(func)` | `func(target, button, x, y)` called while hovering |
| `setOnMouseOutFunction` | `(func)` | `func(target, button, dx, dy)` called on mouse-out |
| `setRepeatWhilePressed` | `(func)` | Called repeatedly while held; interval = `repeatWhilePressedTimer` ms |
| `forceClick` | `()` | Fires `onclick` programmatically |
| `setBackgroundRGBA` | `(r, g, b, a)` | |
| `setBackgroundColorMouseOverRGBA` | `(r, g, b, a)` | |
| `setBorderRGBA` | `(r, g, b, a)` | |
| `setTextureRGBA` | `(r, g, b, a)` | Tint for the icon texture |
| `enableAcceptColor` | `()` | Green accept style (uses `getCore():getGoodHighlitedColor()`) |
| `enableCancelColor` | `()` | Red cancel style |
| `restoreDefaultColors` | `()` | Resets to dark background, grey border |
| `setSound` | `(which, soundName)` | `which` = `"activate"` to change the click sound |

### Notable Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.enable` | `true` | Whether button responds to clicks |
| `self.displayBackground` | `true` | Draw filled background |
| `self.titleLeft` | `false` | If `true`, left-aligns the title instead of centring |
| `self.yoffset` | `0` | Vertical text nudge |
| `self.blinkBG` | `nil` | If set, background pulses when not hovered |
| `self.blinkImage` | `nil` | Icon alpha pulses |
| `self.iconRight` | `nil` | Texture drawn at far right (e.g., an arrow indicator) |
| `self.textureBackground` | `nil` | Texture drawn behind text |
| `self.repeatWhilePressedTimer` | `500` | ms delay between repeat callbacks |
| `self.sounds.activate` | `"UIActivateButton"` | Sound played on click |

### Usage Pattern

```lua
local function onOK(target, button)
    print("clicked")
end

local btn = ISButton:new(10, 10, 120, 28, "OK", myPanel, onOK)
btn:initialise()
myPanel:addChild(btn)

-- Icon-only button
btn:setImage(getTexture("media/ui/MyIcon.png"))
btn:setTitle("")
btn:setDisplayBackground(false)

-- Tooltip
btn:setTooltip("Click to confirm")
```

---

## ISLabel

Non-interactive text display. Auto-computes width from text content.

### Constructor

```lua
ISLabel:new(x, y, height, name, r, g, b, a, font, bLeft)
```

| Param | Type | Description |
|-------|------|-------------|
| `x,y` | number | Position. If `bLeft` is false/nil the label is **right-anchored** at x (x becomes the right edge). |
| `height` | number | If ≤ 0, auto-set to font line height. |
| `name` | string | Text to display |
| `r,g,b,a` | number | Text colour (0–1) |
| `font` | UIFont | Defaults to `UIFont.Small` |
| `bLeft` | bool | `true` = x is the left edge; `false/nil` = x is the right edge |

### Key Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `setName` | `(name)` | Update text. Recomputes width and repositions. |
| `setNameWithoutMoving` | `(name)` | Update text and width but do not move x. |
| `getName` | `()` → string | |
| `setColor` | `(r, g, b)` | |
| `setWidthToName` | `([minWidth])` | Resize width to fit current text. |
| `setHeightToFont` | `([minHeight])` | |
| `setHeightToName` | `([minHeight])` | Handles multi-line text. |
| `setTooltip` | `(str)` | Hover tooltip. |
| `setTranslation` | `(translatedStr)` | Shows a different string but keeps `self.name` as the key. |
| `getFontHeight` | `()` → number | |

### Notable Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.center` | `false` | If `true`, text is drawn centred (drawTextCentre). |
| `self.textColor` | `nil` | If set (table `{r,g,b,a}`), overrides `r,g,b,a` fields. |

### Usage Pattern

```lua
-- Left-anchored label at x=10
local lbl = ISLabel:new(10, 50, 20, "Status:", 1, 1, 1, 1, UIFont.Small, true)
lbl:initialise()
parent:addChild(lbl)

-- Update text later
lbl:setName("Ready")
```

---

## ISImage

Displays a texture inside a panel area. Optionally clickable.

### Constructor

```lua
ISImage:new(x, y, width, height, texture)
```

| Param | Type | Description |
|-------|------|-------------|
| `texture` | Texture or `nil` | Result of `getTexture("media/...")` |

### Key Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `getTexture` | `()` → Texture | |
| `setColor` | `(r, g, b)` | Tint the background colour (also tints texture since `backgroundColor` is used for draw alpha/tint). |
| `setMouseOverText` | `(text)` | Tooltip-style text shown on hover via `ISToolTip`. |

### Notable Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.texture` | constructor | The texture to draw |
| `self.autoScale` | `false` | If `true`, scales texture to fill width/height |
| `self.scaledWidth / scaledHeight` | `nil` | Explicit draw size (preserves aspect if `noAspect` is false) |
| `self.noAspect` | `false` | If `true`, stretches without preserving aspect ratio |
| `self.doBorder` | `false` | Draw a border rect around the image |
| `self.onclick` | `nil` | `onclick(target, imageElement)` — set directly on the object |
| `self.target` | `nil` | Passed as first arg to `onclick` |
| `self.textureOverride` | `nil` | Drawn centred on top of the main texture |
| `self.backgroundColor` | `{r=1,g=1,b=1,a=1}` | Tint / alpha for the texture draw call |

### Usage Pattern

```lua
local img = ISImage:new(0, 0, 64, 64, getTexture("media/ui/SomeIcon.png"))
img:initialise()
img.autoScale = true
parent:addChild(img)

-- Clickable image
img.onclick = function(target, imgObj)
    print("image clicked")
end
img.target = myObject
```

---

## ISScrollBar

Vertical or horizontal scroll bar. Usually created automatically by `addScrollBars()`.
You typically don't instantiate this directly.

### Constructor

```lua
ISScrollBar:new(parent, vertical)
```

| Param | Type | Description |
|-------|------|-------------|
| `parent` | ISUIElement | The scrollable container this bar controls. |
| `vertical` | bool | `true` = vertical bar; `false` = horizontal bar. |

### Creating on a panel (standard pattern)

```lua
-- Add both bars
self:addScrollBars(true)   -- true = also add horizontal bar

-- Add only vertical (most common)
self:addScrollBars()

-- After adding, set content height
self:setScrollHeight(totalContentPixels)
```

### Key Methods

| Method | Notes |
|--------|-------|
| `updatePos()` | Recomputes thumb position from parent scroll state. Called by `updateScrollbars()`. |
| `refresh()` | Clamps parent scroll to valid range. |
| `hitTest(x, y)` | Returns part name: `"thumb"`, `"arrowUp"`, `"arrowDown"`, `"trackUp"`, `"trackDown"` (or horizontal equivalents). |

### Notable Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.vertical` | constructor | Orientation |
| `self.pos` | `0` | Normalised scroll position (0=top, 1=bottom). |
| `self.background` | `true` | Draw track background |

---

## ISTickBox

A stack of labelled checkboxes. Supports optional radio-button mode (`onlyOnePossibility`).

### Constructor

```lua
ISTickBox:new(x, y, width, height, name, changeOptionTarget, changeOptionMethod, changeOptionArg1, changeOptionArg2)
```

| Param | Type | Description |
|-------|------|-------------|
| `name` | string | Internal name, not displayed |
| `changeOptionTarget` | any | First arg to callback |
| `changeOptionMethod` | function | `method(target, optionIndex, isSelected, arg1, arg2, tickBox)` |
| `changeOptionArg1/2` | any | Extra args passed to callback |

### Key Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `addOption` | `(name, data [, texture])` → index | Appends a checkbox row. Returns 1-based index. |
| `clearOptions` | `()` | Remove all options and reset state. |
| `isSelected` | `(index)` → bool | |
| `setSelected` | `(index, bool)` | Programmatically tick/untick. |
| `getOptionCount` | `()` → number | |
| `getOptionData` | `(index)` → any | Returns the `data` value passed to `addOption`. |
| `disableOption` | `(name, bool)` | Grey out a specific option by its text label. |
| `setFont` | `(UIFont)` | |
| `setWidthToFit` | `()` | Auto-resize width to longest option text. |

### Notable Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.onlyOnePossibility` | `nil` | If truthy, acts as radio buttons (selecting one deselects others). |
| `self.boxSize` | equals `height` | Size in pixels of the tick box square. |
| `self.leftMargin` | `0` | Left padding before the tick box. |
| `self.textGap` | `10` | Gap between box and label text. |
| `self.enable` | `true` | Greyed out when `false`. |
| `self.autoWidth` | `nil` | If truthy, width grows automatically as options are added. |
| `self.choicesColor` | `{r=0.7,g=0.7,b=0.7,a=1}` | Text colour for enabled options. |

### Usage Pattern

```lua
local function onChanged(target, index, isSelected, arg1, arg2, tickBox)
    print("Option " .. index .. " is now " .. tostring(isSelected))
end

local tb = ISTickBox:new(10, 10, 200, 20, "myTick", self, onChanged)
tb:initialise()
tb:addOption("Enable feature", "featureKey")
tb:addOption("Show warnings", "warningsKey")
tb:setSelected(1, true)   -- tick first option by default
parent:addChild(tb)
```

---

## ISTextEntryBox

Single- or multi-line editable text input field.
Uses `UITextBox2` Java peer (not `UIElement`).

### Constructor

```lua
ISTextEntryBox:new(title, x, y, width, height)
```

| Param | Type | Description |
|-------|------|-------------|
| `title` | string | Initial text content |
| `x,y,width,height` | number | Geometry |

> Note: Constructor is defined in `ISPanelJoypad` style — call as `ISTextEntryBox:new(...)`.

### Key Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `getText` | `()` → string | Current text contents |
| `setText` | `(str)` | Replace contents; cursor moves to end |
| `setFont` | `(UIFont)` | |
| `setEditable` | `(bool)` | Read-only when false |
| `isEditable` | `()` → bool | |
| `setMultipleLine` | `(bool)` | Enable multi-line mode |
| `setMaxLines` | `(n)` | Limit number of lines |
| `setMaxTextLength` | `(n)` | Character limit |
| `setOnlyNumbers` | `(bool)` | Restrict input to digits |
| `setOnlyText` | `(bool)` | Restrict to non-numeric characters |
| `setForceUpperCase` | `(bool)` | |
| `setMasked` | `(bool)` | Password-style masking |
| `setClearButton` | `(bool)` | Show an X button to clear text |
| `setPlaceholderText` | `(str)` | Greyed hint text shown when empty |
| `setPlaceholderTextRGBA` | `(r,g,b,a)` | |
| `setTextRGBA` | `(r,g,b,a)` | |
| `setSelectable` | `(bool)` | Allow text selection |
| `focus` | `()` | Programmatically focus the field |
| `unfocus` | `()` | |
| `isFocused` | `()` → bool | |
| `getCursorPos` | `()` → number | Caret position (character index) |
| `setCursorPos` | `(charIndex)` | |
| `ignoreFirstInput` | `()` | Suppress the next key event (useful when focus is gained via key press) |

### Event Hooks (override in subclass)

| Hook | Notes |
|------|-------|
| `onCommandEntered()` | Called when Enter is pressed |
| `onTextChange()` | Called on any text change; also fires `onTextChangeFunction(target, self)` |
| `onLostFocus()` | |

### Notable Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.onTextChangeFunction` | `nil` | `function(target, textEntryBox)` set after construction |
| `self.target` | `nil` | Passed to `onTextChangeFunction` |

### Usage Pattern

```lua
local entry = ISTextEntryBox:new("", 10, 10, 200, 24)
entry:initialise()
entry:instantiate()
entry:setFont(UIFont.Small)
entry:setMaxTextLength(50)
entry.onTextChangeFunction = function(target, box)
    print("text is now: " .. box:getText())
end
parent:addChild(entry)
```

---

## ISScrollingListBox

Scrollable list of text rows with selection highlight and optional tooltips.

### Constructor

```lua
ISScrollingListBox:new(x, y, width, height)
```

### Key Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `addItem` | `(name, item [, tooltip])` → itemTable | Appends a row. `item` is arbitrary data; `name` is display text. |
| `insertItem` | `(index, name, item)` → itemTable | Insert at position. |
| `addUniqueItem` | `(name, item [, tooltip])` | Adds only if `name` not already present. |
| `removeItem` | `(itemText)` → itemTable | Remove first row with matching text. |
| `removeItemByIndex` | `(index)` → itemTable | Remove by 1-based index. |
| `removeMatchingItems` | `(itemText)` → bool, table | Remove all rows with matching text. |
| `removeFirst` | `()` | Remove first row. |
| `clear` | `()` | Remove all rows, reset selection. |
| `contains` | `(itemText)` → bool | |
| `size` | `()` → number | Row count. |
| `getItem` | `([index])` → itemTable | Returns item at `index` or `selected` if omitted. |
| `getIndexOf` | `(itemText)` → number | 1-based index or -1. |
| `sort` | `([comparator])` | Sorts by text by default. |
| `setFont` | `(fontName, padY)` | `fontName` is a string key of `UIFont`, e.g. `"Small"`. |
| `setOnMouseDownFunction` | `(target, func)` | `func(target, item)` — fires on row click. |
| `setOnMouseDoubleClick` | `(target, func)` | `func(target, item)` — fires on double-click. |
| `setTextColorRGBA` | `(r,g,b,a)` | Default text colour. |
| `setSelectedTextColorRGBA` | `(r,g,b,a)` | Text colour for selected row. |
| `setItemTextColorRGBA` | `(index, r,g,b,a)` | Per-row text colour. |
| `addColumn` | `(name, size)` | Add a named column (multi-column layout). |
| `rowAt` | `(x, y)` → number | Hit-test local coordinates; returns 1-based row or -1. |

### Notable Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.selected` | `1` | 1-based index of selected row (-1 = none). |
| `self.itemheight` | font+padding | Row height in pixels. |
| `self.font` | `UIFont.Large` | |
| `self.drawBorder` | `false` | Draw border around the whole list. |
| `self.selectionColor` | `{r=0.7,g=0.35,b=0.15,a=0.3}` | Selection highlight colour. |
| `self.mouseOverHighlightColor` | `{r=1,g=1,b=1,a=0.1}` | Hover highlight colour. |
| `self.altBgColor` | `nil` | If set, alternating row background colour. |

### Override Hooks

| Hook | Notes |
|------|-------|
| `doDrawItem(y, item, alt)` → nextY | Override to customise per-row rendering. |
| `drawSelection(x, y, w, h)` | Override to change selection fill. |
| `drawMouseOverHighlight(x, y, w, h)` | Override to change hover fill. |

### Usage Pattern

```lua
local list = ISScrollingListBox:new(10, 10, 200, 300)
list:initialise()
list:setFont("Small", 4)
list:setOnMouseDownFunction(self, function(target, item)
    print("selected: " .. tostring(item))
end)
parent:addChild(list)

list:addItem("Row One",   myDataObject1)
list:addItem("Row Two",   myDataObject2)
list.selected = 1
list:setScrollHeight(list.count * list.itemheight)
```

---

## ISContextMenu

Drop-down right-click style menu with optional sub-menus.
In vanilla code, per-player instances are obtained via `ISContextMenu.getNew(player)`.

### Constructor

```lua
ISContextMenu:new(x, y, width, height [, zoom])
```

Width and height auto-adjust via `calcWidth()` / `calcHeight()` as options are added.

### Creating via the vanilla global instance

```lua
-- Retrieve (or create) the per-player context menu
local menu = ISContextMenu.getNew(player)   -- called from OnFillWorldObjectContextMenu etc.

-- Alternatively, create a standalone menu
local menu = ISContextMenu:new(getMouseX(), getMouseY(), 0, 0)
menu:initialise()
menu:instantiate()
menu:addToUIManager()
```

### Key Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `addOption` | `(name, target, onSelect, param1...param10)` → option | Appends a menu item. `onSelect(target, param1...param10)` called on click. Returns the option table. |
| `addOptionOnTop` | `(name, target, onSelect, ...)` → option | Prepend at top. |
| `addSubMenu` | `(parentOption, subMenu)` | Link a child `ISContextMenu` to a parent option. |
| `removeLastOption` | `()` | |
| `removeOptionByName` | `(name)` | Remove by display text. |
| `getOptionFromName` | `(name)` → option | Find option by text. |
| `clear` | `()` | Remove all options. |
| `isEmpty` | `()` → bool | |
| `setFont` | `(UIFont)` | Change font (affects item height). |
| `setOptionChecked` | `(option, bool)` | Show/hide a checkmark next to an option. |
| `hideSelf` | `()` | Hide this menu. |
| `hideAndChildren` | `()` | Hide this and all sub-menus. |
| `closeAll` | `()` | Close the entire menu tree. |

### Option Table Fields (returned by `addOption`)

```lua
local opt = menu:addOption("Do Thing", self, myFunc, arg1)
opt.notAvailable = true     -- grey out but still show
opt.isDisabled   = true     -- same effect
opt.toolTip      = ISToolTip:new()  -- attach a tooltip
opt.iconTexture  = getTexture("...")-- icon shown left of text
opt.color        = {r=1,g=0,b=0}   -- tint for iconTexture
```

### Usage Pattern

```lua
-- Typical world-object context menu hook
Events.OnFillWorldObjectContextMenu.Add(function(playerNum, context, worldObjects, test)
    local opt = context:addOption("My Action", playerObj, myActionFunc, extraArg)
    opt.toolTip = ISToolTip:new()
    opt.toolTip:initialise()
    opt.toolTip.description = "Does my action"
end)
```

---

## ISRadialMenu

Circular slice menu. Typically used for joypad/controller radial action selection.

### Constructor

```lua
ISRadialMenu:new(x, y, innerRadius, outerRadius, playerNum)
```

| Param | Type | Description |
|-------|------|-------------|
| `innerRadius` | number | Radius of the dead-zone hole |
| `outerRadius` | number | Outer radius; also determines `width = height = outerRadius * 2` |
| `playerNum` | number | 0-based split-screen player index |

### Key Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `addSlice` | `(text, texture, command, arg1...arg6)` | Append a slice. `command(arg1...arg6)` is called on selection. |
| `clear` | `()` | Remove all slices. |
| `isEmpty` | `()` → bool | |
| `setSliceText` | `(sliceIndex, text)` | 1-based index. |
| `setSliceTexture` | `(sliceIndex, texture)` | |
| `getSliceCommand` | `(sliceIndex)` → commandTable | Returns `{func, arg1...arg6}`. |
| `center` | `()` | Move to centre of player's screen. |
| `undisplay` | `()` | Remove from UI manager (plays undisplay sound). |
| `setHideWhenButtonReleased` | `(button)` | Auto-undisplay and select on joypad button release. |

### Notable Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.innerRadius` | constructor | |
| `self.outerRadius` | constructor | |
| `self.slices` | `{}` | Array of slice tables |
| `self.playerNum` | constructor | |
| `self.disableJoypadNavigation` | `true` | |

### Usage Pattern

```lua
local radial = ISRadialMenu:new(0, 0, 50, 150, 0)
radial:initialise()
radial:instantiate()
radial:center()

radial:addSlice("Attack", getTexture("media/ui/SwordIcon.png"), myAttackFunc, playerObj)
radial:addSlice("Defend", getTexture("media/ui/ShieldIcon.png"), myDefendFunc, playerObj)

radial:addToUIManager()
radial:setVisible(true)
```

---

## ISTabPanel

Tabbed panel container. Each tab is a named child panel; only the active one is visible.

### Constructor

```lua
ISTabPanel:new(x, y, width, height)
```

### Key Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `addView` | `(name, view)` | Appends a tab. First tab auto-becomes active. `view` is any `ISPanel`/`ISUIElement`. |
| `activateView` | `(name)` → bool | Switch active tab by name. Hides previous, shows new. |
| `getView` | `(name)` → element | Returns the panel for a tab name. |
| `getActiveView` | `()` → element | Returns the currently visible panel. |
| `getActiveViewIndex` | `()` → number | 1-based index. |
| `removeView` | `(view)` | |
| `replaceView` | `(oldView, newPanel)` | |
| `setEqualTabWidth` | `(bool)` | Default `true`; if false, tabs size to their label. |
| `setCenterTabs` | `(bool)` | Centre tabs horizontally when they fit. |
| `setTabsTransparency` | `(alpha)` | |
| `setTextTransparency` | `(alpha)` | |
| `ensureVisible` | `(index)` | Scroll tab strip to show tab at 1-based index. |
| `setOnTabTornOff` | `(target, method)` | Callback when a tab is torn off into a new window. |

### Notable Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.tabHeight` | font height + 6 | Pixel height of the tab strip. |
| `self.tabPadX` | `20` | Horizontal padding within each tab label. |
| `self.allowDraggingTabs` | `false` | Allow reordering tabs by dragging. |
| `self.allowTornOffTabs` | `false` | Allow dragging a tab out to a new window. |
| `self.equalTabWidth` | `true` | All tabs same width. |
| `self.centerTabs` | `false` | |
| `self.blinkTab` | `nil` | Name of a tab to make blink. |

### Usage Pattern

```lua
local tabs = ISTabPanel:new(0, 0, 400, 300)
tabs:initialise()
tabs:instantiate()

local page1 = ISPanel:new(0, 0, 400, 300 - tabs.tabHeight)
page1:initialise()

local page2 = ISPanel:new(0, 0, 400, 300 - tabs.tabHeight)
page2:initialise()

tabs:addView("Info",     page1)
tabs:addView("Settings", page2)

parent:addChild(tabs)

-- Switch tab programmatically
tabs:activateView("Settings")
```

---

## ISRichTextPanel

Markup-driven scrollable text panel. Parses inline tags for colour, size, images, and line breaks.

### Constructor

```lua
ISRichTextPanel:new(x, y, width, height)
```

### Key Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `setText` | `(text)` | Set the markup string. Call `paginate()` to layout. |
| `paginate` | `()` | Re-layout text (called automatically when needed). |
| `setMargins` | `(left, top, right, bottom)` | Content margins in pixels. |
| `setMaxLines` | `(n)` | Truncate at N lines (0 = unlimited). |
| `updateAutoScroll` | `()` | Advance auto-scroll by `self.autoScrollSpeed` pixels per frame. |

### Markup Tag Reference

Tags are embedded inline in the text string using `<TAG>` syntax:

```
<LINE>        -- line break (newline)
<BR>          -- double-spaced break
<H1>          -- large centred white heading
<H2>          -- medium left-aligned grey heading
<TEXT>        -- reset to body text style
<CENTRE>      -- centre-align following text
<LEFT>        -- left-align
<RIGHT>       -- right-align

<RGB:r,g,b>         -- set colour (0–1 floats)
<PUSHRGB:r,g,b>     -- push colour onto stack
<POPRGB>            -- pop colour from stack
<GHC>               -- use game "good highlight" colour
<BHC>               -- use game "bad highlight" colour
<RED>               -- shorthand red
<ORANGE>            -- shorthand orange
<GREEN>             -- shorthand green

<SIZE:small>        -- UIFont.NewSmall
<SIZE:medium>       -- UIFont.Medium
<SIZE:large>        -- UIFont.Large
<SIZE:intro>        -- UIFont.Intro

<IMAGE:path,width,height>  -- inline image
```

### Notable Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.text` | `""` | Markup string |
| `self.autosetheight` | `true` | Auto-resize height to fit content |
| `self.defaultFont` | `UIFont.NewSmall` | Base font |
| `self.marginLeft/Top/Right/Bottom` | `20/10/10/10` | Content margins |
| `self.clip` | `false` | Clip content to panel bounds |
| `self.maxLines` | `0` | 0 = unlimited |
| `self.autoScrollSpeed` | `nil` | Pixels/frame for auto-scrolling |

### Usage Pattern

```lua
local rtPanel = ISRichTextPanel:new(0, 0, 400, 200)
rtPanel:initialise()
rtPanel:instantiate()
rtPanel:setMargins(10, 10, 10, 10)

rtPanel:setText("<H1>Title<LINE><TEXT><RGB:0.8,0.8,0.8>Normal body text.<LINE><GHC>Highlighted text.")
rtPanel:paginate()

parent:addChild(rtPanel)
```

---

## ISToolTip

Floating tooltip panel. Auto-sizes to title + rich-text description.
Most commonly created and owned by a button/label via `ISButton:setTooltip` or directly.

### Constructor

```lua
ISToolTip:new()   -- no geometry arguments; auto-sizes on layout
```

### Key Methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `setTitle` / `setName` | `(str)` | Large header text (drawn in `UIFont.Medium`). |
| `setDescription` | `(str)` | Body text (supports rich-text markup via embedded `ISRichTextPanel`). |
| `setTexture` | `(texturePath)` | Display an image left of the text. |
| `setTextureDirectly` | `(texture)` | Same but accepts a Texture object. |
| `setOwner` | `(uiElement)` | Parent widget; tooltip auto-hides if owner is invisible. |
| `setDesiredPosition` | `(x, y)` | Pin to a specific screen position. |
| `setAlwaysOnTop` | `(bool)` | Call after `addToUIManager`. |
| `reset` | `()` | Clear all content back to defaults. |
| `doLayout` | `()` | Recompute size (called automatically in `prerender`). |

### Notable Fields

| Field | Default | Description |
|-------|---------|-------------|
| `self.name` | `nil` | Header text |
| `self.description` | `""` | Body markup text |
| `self.texture` | `nil` | Optional image |
| `self.owner` | `nil` | Owning widget |
| `self.followMouse` | `true` | If false, stays at `desiredX/Y`. |
| `self.maxLineWidth` | `nil` | Max pixels per text line (nil = auto). |
| `self.footNote` | `nil` | Small text drawn at bottom (e.g., key hint). |
| `self.defaultMyWidth` | `220` | Minimum tooltip width in pixels. |
| `self.nameMarginX` | `50` | Extra horizontal margin for header. |

### Usage Pattern

```lua
-- Attached to a button (simplest — use setTooltip)
btn:setTooltip("This does the thing.")

-- Manual tooltip on a custom widget
local tip = ISToolTip:new()
tip:initialise()
tip:instantiate()
tip:setAlwaysOnTop(true)
tip:setOwner(myWidget)
tip:setTitle("Item Name")
tip.description = "<RGB:0.8,0.8,0.8>Stat 1: 42<LINE>Stat 2: 7"
tip:addToUIManager()
tip:setVisible(true)
tip:setDesiredPosition(getMouseX(), getMouseY() + 20)

-- Hide when done
tip:setVisible(false)
tip:removeFromUIManager()
```

---

## Common Patterns

### Root window lifecycle

```lua
-- 1. Construct
local win = ISPanel:new(100, 100, 400, 300)
win:initialise()
win:instantiate()

-- 2. Populate children
local lbl = ISLabel:new(10, 10, 20, "Hello", 1,1,1,1, UIFont.Small, true)
lbl:initialise()
win:addChild(lbl)

-- 3. Show
win:addToUIManager()

-- 4. Hide / destroy
win:setVisible(false)
win:removeFromUIManager()
```

### Scrollable content panel

```lua
local scroll = ISPanel:new(0, 0, 300, 200)
scroll:initialise()
scroll:instantiate()
scroll:addScrollBars()          -- adds self.vscroll

-- Set total content height after populating
scroll:setScrollHeight(totalChildrenHeight)
```

### Wrapping an arbitrary panel in a titled, collapsable window

```lua
local inner = ISPanel:new(0, 0, 400, 300)
inner:initialise()
local outer = inner:wrapInCollapsableWindow("My Window", true)
outer:addToUIManager()
```

### Text measurement

```lua
local w = getTextManager():MeasureStringX(UIFont.Small, "Some text")
local h = getTextManager():MeasureStringY(UIFont.Small, "Some text")
local lineH = getTextManager():getFontHeight(UIFont.Small)
```

### Loading textures

```lua
-- Mod texture (relative to media/)
local tex = getTexture("media/ui/MyIcon.png")

-- Vanilla UI texture
local tex = getTexture("media/ui/Panel_VScroll_ButtonUp.png")
```

---

## UIFont Quick Reference

| Constant | Approximate height | Use |
|----------|--------------------|-----|
| `UIFont.Small` | ~12 px | Default for most UI |
| `UIFont.NewSmall` | ~12 px | Tooltip body text default |
| `UIFont.Medium` | ~16 px | Subheadings, tooltip titles |
| `UIFont.Large` | ~20 px | List boxes default, headings |
| `UIFont.Normal` | ~14 px | |
| `UIFont.Massive` | ~32 px | |

Actual pixel heights vary by OS DPI scaling. Use `getTextManager():getFontHeight(UIFont.X)` for runtime values.
