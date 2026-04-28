-- ISPanel window example
-- Place at: media/lua/client/UI/MyMod_Window.lua
--
-- Press Y to open/close the window.

MyMod_Window = ISPanel:derive("MyMod_Window")

-- ── Constructor ──────────────────────────────────────────────────────────────

function MyMod_Window:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0.9}
    o.borderColor     = {r=0.5, g=0.5, b=0.5, a=1.0}
    o.moveWithMouse   = true
    o.title           = "My Mod Window"
    return o
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function MyMod_Window:initialise()
    ISPanel.initialise(self)
end

function MyMod_Window:create()
    local pad = 8

    -- Title label is drawn manually in render()

    -- Text entry
    self.nameEntry = ISTextEntryBox:new("Enter text...", pad, 30, self.width - pad*2, 20)
    self.nameEntry:initialise()
    self.nameEntry:instantiate()
    self:addChild(self.nameEntry)

    -- Tick box
    self.optionTick = ISTickBox:new(pad, 60, 150, 20, "", self, MyMod_Window.onTick)
    self.optionTick:initialise()
    self.optionTick:instantiate()
    self.optionTick:addOption("Enable feature")
    self:addChild(self.optionTick)

    -- Confirm button
    local btnW, btnH = 80, 20
    self.confirmBtn = ISButton:new(
        pad,
        self.height - btnH - pad,
        btnW, btnH,
        "Confirm",
        self,
        MyMod_Window.onConfirm
    )
    self.confirmBtn:initialise()
    self.confirmBtn:instantiate()
    self:addChild(self.confirmBtn)

    -- Cancel button
    self.cancelBtn = ISButton:new(
        self.width - btnW - pad,
        self.height - btnH - pad,
        btnW, btnH,
        "Cancel",
        self,
        MyMod_Window.onCancel
    )
    self.cancelBtn:initialise()
    self.cancelBtn:instantiate()
    self:addChild(self.cancelBtn)
end

-- ── Rendering ─────────────────────────────────────────────────────────────────

function MyMod_Window:prerender()
    ISPanel.prerender(self)
end

function MyMod_Window:render()
    self:drawText(self.title, 8, 8, 1, 1, 1, 1, UIFont.Small)
end

-- ── Callbacks ─────────────────────────────────────────────────────────────────

function MyMod_Window:onTick(index, selected)
    -- index = which checkbox (1-based), selected = bool
end

function MyMod_Window:onConfirm()
    local text    = self.nameEntry:getText()
    local enabled = self.optionTick:isSelected(1)
    -- do something with text and enabled...
    self:close()
end

function MyMod_Window:onCancel()
    self:close()
end

function MyMod_Window:close()
    self:setVisible(false)
    self:removeFromUIManager()
    MyMod_Window.instance = nil
end

-- ── Show / Hide ───────────────────────────────────────────────────────────────

function MyMod_Window.toggle()
    if MyMod_Window.instance then
        MyMod_Window.instance:close()
    else
        local w, h = 300, 180
        local x = (getCore():getScreenWidth()  - w) / 2
        local y = (getCore():getScreenHeight() - h) / 2
        MyMod_Window.instance = MyMod_Window:new(x, y, w, h)
        MyMod_Window.instance:initialise()
        MyMod_Window.instance:addToUIManager()
    end
end

-- ── Key binding ──────────────────────────────────────────────────────────────

local function onKeyPressed(key)
    if key == 21 then  -- Y key
        MyMod_Window.toggle()
    end
end

Events.OnKeyPressed.Add(onKeyPressed)
