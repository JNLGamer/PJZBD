# UI (ISPanel Windows)

Source: MrBounty/PZ-Mod---Doc

## Concept

All UI windows derive from `ISPanel`. You implement lifecycle methods, add child
elements, then show/hide the window by adding/removing it from the UI manager.

## File Location

`media/lua/client/UI/MyMod_MyWindow.lua`

## Window Skeleton

```lua
MyMod_MyWindow = ISPanel:derive("MyMod_MyWindow")

function MyMod_MyWindow:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.borderColor     = {r=0.4, g=0.4, b=0.4, a=1.0}
    o.moveWithMouse   = true
    return o
end

function MyMod_MyWindow:initialise()
    ISPanel.initialise(self)
end

function MyMod_MyWindow:create()
    -- Add child elements here (called once after initialise)
    local btnW, btnH = 100, 20
    self.cancelBtn = ISButton:new(
        self.width - btnW - 5,  -- x relative to panel
        self.height - btnH - 5, -- y
        btnW, btnH,
        "Cancel",
        self,
        MyMod_MyWindow.onCancel
    )
    self.cancelBtn:initialise()
    self.cancelBtn:instantiate()
    self:addChild(self.cancelBtn)
end

function MyMod_MyWindow:prerender()
    -- draw background (ISPanel does this, call super)
    ISPanel.prerender(self)
end

function MyMod_MyWindow:render()
    -- draw text labels
    self:drawText("Hello!", 10, 10, 1, 1, 1, 1, UIFont.Small)
end

function MyMod_MyWindow:onCancel()
    self:setVisible(false)
    self:removeFromUIManager()
end
```

## Showing and Hiding

```lua
-- Show
if not MyMod_MyWindow.instance then
    MyMod_MyWindow.instance = MyMod_MyWindow:new(100, 100, 300, 200)
    MyMod_MyWindow.instance:initialise()
    MyMod_MyWindow.instance:addToUIManager()
else
    MyMod_MyWindow.instance:setVisible(true)
    MyMod_MyWindow.instance:addToUIManager()
end

-- Hide
MyMod_MyWindow.instance:setVisible(false)
MyMod_MyWindow.instance:removeFromUIManager()
```

## Available Child Elements

### ISButton
```lua
local btn = ISButton:new(x, y, w, h, "Label", targetObj, targetObj.onClickMethod)
btn:initialise()
btn:instantiate()
panel:addChild(btn)
```

### ISTickBox
```lua
local tick = ISTickBox:new(x, y, w, h, "", self, self.onTick)
tick:initialise()
tick:instantiate()
tick:addOption("Enable Feature")   -- adds a checkbox line
panel:addChild(tick)

-- Read value
local enabled = tick:isSelected(1) -- 1-indexed option
```

### ISComboBox
```lua
local combo = ISComboBox:new(x, y, w, h, self, self.onChange)
combo:initialise()
combo:instantiate()
combo:addOption("Option A")
combo:addOption("Option B")
panel:addChild(combo)
-- combo.selected = "Option A"
```

### ISTextEntryBox
```lua
local entry = ISTextEntryBox:new("default text", x, y, w, h)
entry:initialise()
entry:instantiate()
panel:addChild(entry)
-- entry:getText()  /  entry:setText("value")
```

### ISScrollingListBox
```lua
local list = ISScrollingListBox:new(x, y, w, h)
list:initialise()
list:instantiate()
panel:addChild(list)
list:addItem("Row Label", itemObject)
-- list.selected  (index)  /  list:getSelectedItem()
```

## Drawing Helpers (inside render/prerender)

```lua
self:drawRect(x, y, w, h, a, r, g, b)             -- filled rect
self:drawRectBorder(x, y, w, h, a, r, g, b)       -- outline rect
self:drawText("text", x, y, r, g, b, a, UIFont.Small)
-- UIFont options: Small, Medium, Large, Massive, Title, NewSmall
```

## Open Window with Keypress

```lua
local function onKeyPressed(key)
    if key == 21 then -- Y key
        -- toggle window
    end
end
Events.OnKeyPressed.Add(onKeyPressed)
```
