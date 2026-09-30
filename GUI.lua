--[[
    ═══════════════════════════════════════════════════════════════════════
    VENTURE AOT v2.0 — Universal GUI (No LinUI / No external libs)
    ═══════════════════════════════════════════════════════════════════════
    Работает на: Xeno / Delta / Solara / Arceus X / Wave / Krnl / Synapse / Fluxus / Oxygen / Codex
    Не требует: Drawing, gethui, syn.protect_gui, LinUI, Linoria, WindUI
    ═══════════════════════════════════════════════════════════════════════
--]]

-- ==================== SERVICES ====================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== F HOOK ====================
local F = (_G.Venture and _G.Venture.F) or {}
local S = F.Settings or {}
_G.Venture = _G.Venture or {}
_G.Venture.F = F
S = F.Settings or S

-- ==================== CONFIG ====================
local CONFIG_FILE = "VentureAOT_GUI_Config.json"
local Config = {
    Theme = "Dark",
    Keybind = "K",
    Size = {620, 440},
    Position = {0.5, 0.5},
    Opacity = 1,
    AutoSave = true,
    Minimized = false,
}

local function LoadConfig()
    if not (isfile and readfile and isfile(CONFIG_FILE)) then return end
    local ok, raw = pcall(readfile, CONFIG_FILE)
    if not ok or not raw then return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if ok2 and type(data) == "table" then
        for k, v in pairs(data) do Config[k] = v end
    end
end

local function SaveConfig()
    if not (writefile and Config.AutoSave) then return end
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end)
end

LoadConfig()

-- ==================== THEMES ====================
local Themes = {
    Dark = {
        Background = Color3.fromRGB(12, 12, 18),
        Secondary  = Color3.fromRGB(22, 22, 30),
        Accent     = Color3.fromRGB(125, 92, 255),
        Text       = Color3.fromRGB(230, 230, 245),
        SubText    = Color3.fromRGB(150, 150, 170),
        Hover      = Color3.fromRGB(35, 35, 48),
        Stroke     = Color3.fromRGB(60, 60, 80),
        Element    = Color3.fromRGB(30, 30, 42),
    },
    Purple = {
        Background = Color3.fromRGB(22, 8, 40),
        Secondary  = Color3.fromRGB(35, 15, 60),
        Accent     = Color3.fromRGB(200, 100, 255),
        Text       = Color3.fromRGB(240, 220, 255),
        SubText    = Color3.fromRGB(180, 150, 210),
        Hover      = Color3.fromRGB(55, 25, 90),
        Stroke     = Color3.fromRGB(90, 50, 140),
        Element    = Color3.fromRGB(45, 20, 75),
    },
    Red = {
        Background = Color3.fromRGB(25, 5, 5),
        Secondary  = Color3.fromRGB(40, 10, 10),
        Accent     = Color3.fromRGB(255, 60, 60),
        Text       = Color3.fromRGB(255, 220, 220),
        SubText    = Color3.fromRGB(200, 140, 140),
        Hover      = Color3.fromRGB(60, 15, 15),
        Stroke     = Color3.fromRGB(100, 30, 30),
        Element    = Color3.fromRGB(50, 12, 12),
    },
    White = {
        Background = Color3.fromRGB(240, 240, 245),
        Secondary  = Color3.fromRGB(225, 225, 232),
        Accent     = Color3.fromRGB(80, 90, 220),
        Text       = Color3.fromRGB(30, 30, 50),
        SubText    = Color3.fromRGB(90, 90, 110),
        Hover      = Color3.fromRGB(210, 210, 220),
        Stroke     = Color3.fromRGB(180, 180, 195),
        Element    = Color3.fromRGB(215, 215, 225),
    },
}

-- ==================== UTILS ====================
local function New(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function Tween(obj, time, props, style, dir)
    local info = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function Round(obj, r)
    New("UICorner", { CornerRadius = UDim.new(0, r or 6) }, obj)
end

local function Stroke(obj, color, thickness, transparency)
    New("UIStroke", {
        Color = color or Color3.fromRGB(60, 60, 80),
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
end

local function Pad(obj, px, py)
    New("UIPadding", {
        PaddingTop = UDim.new(0, py or 0),
        PaddingBottom = UDim.new(0, py or 0),
        PaddingLeft = UDim.new(0, px or 0),
        PaddingRight = UDim.new(0, px or 0),
    }, obj)
end

-- ==================== LIBRARY ====================
local Library = {
    Theme = Themes[Config.Theme] or Themes.Dark,
    Config = Config,
    Themes = Themes,
    Tabs = {},
    Elements = {},
    Notifications = {},
    ToggleKey = Enum.KeyCode[Config.Keybind] or Enum.KeyCode.K,
    Visible = true,
}

function Library:Register(el)
    table.insert(self.Elements, el)
    return el
end

function Library:SetTheme(name)
    local t = Themes[name]
    if not t then return end
    self.Theme = t
    Config.Theme = name
    SaveConfig()
    self:RefreshTheme()
end

function Library:RefreshTheme()
    local t = self.Theme
    if self.MainFrame then Tween(self.MainFrame, 0.2, { BackgroundColor3 = t.Secondary }) end
    if self.Header then Tween(self.Header, 0.2, { BackgroundColor3 = t.Background }) end
    if self.Sidebar then Tween(self.Sidebar, 0.2, { BackgroundColor3 = t.Background }) end
    if self.Content then Tween(self.Content, 0.2, { BackgroundColor3 = t.Secondary }) end
    if self.Footer then Tween(self.Footer, 0.2, { BackgroundColor3 = t.Background }) end
    for _, el in ipairs(self.Elements) do
        if el.Refresh then pcall(el.Refresh, el, t) end
    end
end

function Library:Notify(opts)
    opts = opts or {}
    local title = opts.Title or "Venture"
    local text  = opts.Content or opts.Text or ""
    local dur   = opts.Duration or 4

    local n = New("Frame", {
        Size = UDim2.new(0, 300, 0, 70),
        Position = UDim2.new(1, 320, 1, -80 - (#self.Notifications * 80)),
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Parent = self.ScreenGui,
    })
    Round(n, 8)
    Stroke(n, self.Theme.Accent, 1.5, 0.3)
    New("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Parent = n,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 22),
        Position = UDim2.new(0, 14, 0, 8),
        BackgroundTransparency = 1, Text = title,
        TextColor3 = self.Theme.Accent, TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = n,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 34),
        Position = UDim2.new(0, 14, 0, 30),
        BackgroundTransparency = 1, Text = text,
        TextColor3 = self.Theme.Text, TextSize = 12,
        Font = Enum.Font.Gotham, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = n,
    })
    table.insert(self.Notifications, n)
    Tween(n, 0.3, { Position = UDim2.new(1, -320, 1, -80 - (#self.Notifications - 1) * 80) })

    task.delay(dur, function()
        Tween(n, 0.3, { Position = UDim2.new(1, 320, 1, n.Position.Y.Offset) })
        task.wait(0.35)
        if n.Parent then n:Destroy() end
        for i, x in ipairs(self.Notifications) do
            if x == n then table.remove(self.Notifications, i) break end
        end
    end)
end

-- ==================== WINDOW ====================
function Library:MakeWindow(opts)
    opts = opts or {}
    local title = opts.Title or "VENTURE AOT"
    local subtitle = opts.Subtitle or ""

    local gui = New("ScreenGui", {
        Name = "VentureAOT_GUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    -- Безопасный парент: CoreGui -> PlayerGui
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok or not gui.Parent then gui.Parent = PlayerGui end
    self.ScreenGui = gui

    local main = New("Frame", {
        Name = "Main",
        Size = UDim2.new(0, Config.Size[1], 0, Config.Size[2]),
        Position = UDim2.new(Config.Position[1], 0, Config.Position[2], 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Theme.Secondary,
        BackgroundTransparency = 1 - Config.Opacity,
        BorderSizePixel = 0,
        Parent = gui,
    })
    Round(main, 10)
    Stroke(main, self.Theme.Stroke, 1, 0.3)
    self.MainFrame = main

    -- Header
    local header = New("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Parent = main,
    })
    Round(header, 10)
    New("Frame", {
        Size = UDim2.new(1, 0, 0, 16),
        Position = UDim2.new(0, 0, 1, -16),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Parent = header,
    })
    New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = self.Theme.Accent,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Parent = header,
    })
    self.Header = header

    New("TextLabel", {
        Size = UDim2.new(0, 300, 0, 22),
        Position = UDim2.new(0, 16, 0, 6),
        BackgroundTransparency = 1,
        Text = title, TextColor3 = self.Theme.Text, TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
    })
    New("TextLabel", {
        Size = UDim2.new(0, 300, 0, 14),
        Position = UDim2.new(0, 16, 0, 23),
        BackgroundTransparency = 1,
        Text = subtitle, TextColor3 = self.Theme.SubText, TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
    })

    -- Minimize btn
    local minBtn = New("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -70, 0, 6),
        BackgroundColor3 = self.Theme.Element,
        Text = "—", TextColor3 = self.Theme.Text, TextSize = 16,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false, BorderSizePixel = 0, Parent = header,
    })
    Round(minBtn, 6)
    minBtn.MouseEnter:Connect(function() Tween(minBtn, 0.15, { BackgroundColor3 = self.Theme.Hover }) end)
    minBtn.MouseLeave:Connect(function() Tween(minBtn, 0.15, { BackgroundColor3 = self.Theme.Element }) end)
    minBtn.MouseButton1Click:Connect(function() self:ToggleMinimize() end)
    self.MinBtn = minBtn

    -- Close btn
    local closeBtn = New("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -36, 0, 6),
        BackgroundColor3 = self.Theme.Element,
        Text = "✕", TextColor3 = self.Theme.Text, TextSize = 14,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false, BorderSizePixel = 0, Parent = header,
    })
    Round(closeBtn, 6)
    closeBtn.MouseEnter:Connect(function() Tween(closeBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(200, 50, 50) }) end)
    closeBtn.MouseLeave:Connect(function() Tween(closeBtn, 0.15, { BackgroundColor3 = self.Theme.Element }) end)
    closeBtn.MouseButton1Click:Connect(function() self:Hide() end)

    -- Sidebar
    local sidebar = New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 140, 1, -60),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0, Parent = main,
    })
    Pad(sidebar, 8, 8)
    New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = sidebar,
    })
    self.Sidebar = sidebar

    -- Content
    local content = New("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -140, 1, -60),
        Position = UDim2.new(0, 140, 0, 40),
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        ClipsDescendants = true, Parent = main,
    })
    self.Content = content

    local scroll = New("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = content,
    })
    Pad(scroll, 12, 10)
    local layout = New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = scroll,
    })
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
    self.Scroll = scroll
    self.ScrollLayout = layout

    -- Footer
    local footer = New("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 1, -20),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0, Parent = main,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "Venture AOT v2.0 | by __TheDark",
        TextColor3 = self.Theme.SubText, TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = footer,
    })
    self.Footer = footer

    self:MakeDraggable(header, main)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == self.ToggleKey then self:Toggle() end
    end)

    return self
end

function Library:MakeDraggable(handle, frame)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    SaveConfig()
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Library:Toggle()
    self.Visible = not self.Visible
    if self.Visible then
        self.MainFrame.Visible = true
        Tween(self.MainFrame, 0.3, { BackgroundTransparency = 1 - Config.Opacity })
    else
        Tween(self.MainFrame, 0.25, { BackgroundTransparency = 1 })
        task.delay(0.3, function() self.MainFrame.Visible = false end)
    end
end

function Library:Hide()
    self.Visible = false
    Tween(self.MainFrame, 0.25, { BackgroundTransparency = 1 })
    task.delay(0.3, function() self.MainFrame.Visible = false end)
end

function Library:Show()
    self.Visible = true
    self.MainFrame.Visible = true
    Tween(self.MainFrame, 0.25, { BackgroundTransparency = 1 - Config.Opacity })
end

function Library:ToggleMinimize()
    Config.Minimized = not Config.Minimized
    SaveConfig()
    if Config.Minimized then
        self.Sidebar.Visible = false
        self.Content.Visible = false
        self.Footer.Visible = false
        Tween(self.MainFrame, 0.3, { Size = UDim2.new(0, Config.Size[1], 0, 40) })
    else
        Tween(self.MainFrame, 0.3, { Size = UDim2.new(0, Config.Size[1], 0, Config.Size[2]) })
        task.delay(0.2, function()
            self.Sidebar.Visible = true
            self.Content.Visible = true
            self.Footer.Visible = true
        end)
    end
end

-- ==================== TAB ====================
function Library:MakeTab(name)
    local tab = {
        Name = name, Elements = {}, _active = false,
        _btn = nil, _frame = nil, Library = self,
    }

    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.3,
        Text = name, TextColor3 = self.Theme.Text, TextSize = 13,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false, BorderSizePixel = 0, Parent = self.Sidebar,
    })
    Round(btn, 6)
    btn.MouseEnter:Connect(function()
        if not tab._active then Tween(btn, 0.15, { BackgroundColor3 = self.Theme.Hover, BackgroundTransparency = 0.1 }) end
    end)
    btn.MouseLeave:Connect(function()
        if not tab._active then Tween(btn, 0.15, { BackgroundColor3 = self.Theme.Element, BackgroundTransparency = 0.3 }) end
    end)

    local frame = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Visible = false, Parent = self.Scroll,
    })
    local layout = New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8), Parent = frame,
    })

    tab._btn = btn
    tab._frame = frame
    tab._layout = layout

    function tab:Activate()
        for _, t in ipairs(self.Library.Tabs) do
            t._active = false
            t._frame.Visible = false
            if t._btn then
                Tween(t._btn, 0.15, { BackgroundColor3 = self.Library.Theme.Element, BackgroundTransparency = 0.3 })
            end
        end
        self._active = true
        self._frame.Visible = true
        Tween(self._btn, 0.2, { BackgroundColor3 = self.Library.Theme.Accent, BackgroundTransparency = 0 })
    end

    btn.MouseButton1Click:Connect(function() tab:Activate() end)

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then tab:Activate() end
    return tab
end

-- ==================== SECTION (COLLAPSIBLE) ====================
function Library:MakeSection(tab, name)
    local section = New("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0, Parent = tab._frame,
    })
    Round(section, 6)
    Stroke(section, self.Theme.Stroke, 1, 0.5)

    local arrow = New("TextLabel", {
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1, Text = "▼",
        TextColor3 = self.Theme.Accent, TextSize = 12,
        Font = Enum.Font.GothamBold, Parent = section,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -36, 1, 0),
        Position = UDim2.new(0, 26, 0, 0),
        BackgroundTransparency = 1, Text = name or "Section",
        TextColor3 = self.Theme.Accent, TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = section,
    })

    local container = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Parent = tab._frame,
    })
    local cLayout = New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6), Parent = container,
    })

    local collapsed = false
    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Text = "", Parent = section,
    })
    btn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        Tween(arrow, 0.2, { Rotation = collapsed and -90 or 0 })
        container.Visible = not collapsed
    end)

    local element = {
        Container = container,
        Collapsed = function() return collapsed end,
        Refresh = function(_, t)
            Tween(section, 0.2, { BackgroundColor3 = t.Background })
            arrow.TextColor3 = t.Accent
        end,
    }
    self:Register(element)
    table.insert(tab.Elements, element)
    return container
end

-- ==================== ELEMENTS ====================

-- TOGGLE
function Library:MakeToggle(parent, opts)
    opts = opts or {}
    local name    = opts.Name or "Toggle"
    local default = opts.Default or false
    local callback = opts.Callback or function() end

    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0, Parent = parent,
    })
    Round(row, 6)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = name,
        TextColor3 = self.Theme.Text, TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })

    local switch = New("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = default and self.Theme.Accent or self.Theme.Stroke,
        BorderSizePixel = 0, Parent = row,
    })
    Round(switch, 10)

    local dot = New("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = default and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0, Parent = switch,
    })
    Round(dot, 8)

    local state = default
    local function setState(v, fire)
        state = v
        Tween(switch, 0.2, { BackgroundColor3 = v and self.Theme.Accent or self.Theme.Stroke })
        Tween(dot, 0.2, { Position = v and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2) })
        if fire then pcall(callback, v) end
    end

    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, Text = "", Parent = row,
    })
    btn.MouseEnter:Connect(function() Tween(row, 0.15, { BackgroundTransparency = 0.3 }) end)
    btn.MouseLeave:Connect(function() Tween(row, 0.15, { BackgroundTransparency = 0.5 }) end)
    btn.MouseButton1Click:Connect(function() setState(not state, true) end)

    local el = {
        Name = name,
        Set = function(v) setState(v, true) end,
        Get = function() return state end,
        Refresh = function(_, t)
            label.TextColor3 = t.Text
            Tween(row, 0.2, { BackgroundColor3 = t.Element })
            Tween(switch, 0.2, { BackgroundColor3 = state and t.Accent or t.Stroke })
        end,
    }
    self:Register(el)
    return el
end

-- BUTTON
function Library:MakeButton(parent, opts)
    opts = opts or {}
    local name     = opts.Name or "Button"
    local subtext  = opts.Subtext or ""
    local callback = opts.Callback or function() end
    local danger   = opts.Danger or false

    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 0, subtext ~= "" and 44 or 34),
        BackgroundColor3 = danger and Color3.fromRGB(120, 30, 30) or self.Theme.Element,
        BackgroundTransparency = 0.4,
        Text = "", AutoButtonColor = false,
        BorderSizePixel = 0, Parent = parent,
    })
    Round(btn, 6)
    Stroke(btn, danger and Color3.fromRGB(255, 80, 80) or self.Theme.Accent, 1, 0.6)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -20, subtext ~= "" and 0.55 or 1, 0),
        Position = UDim2.new(0, 12, 0, subtext ~= "" and 4 or 0),
        BackgroundTransparency = 1, Text = name,
        TextColor3 = self.Theme.Text, TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
    })

    if subtext ~= "" then
        New("TextLabel", {
            Size = UDim2.new(1, -20, 0, 16),
            Position = UDim2.new(0, 12, 0, 24),
            BackgroundTransparency = 1, Text = subtext,
            TextColor3 = self.Theme.SubText, TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = btn,
        })
    end

    btn.MouseEnter:Connect(function()
        Tween(btn, 0.15, { BackgroundTransparency = 0.15, BackgroundColor3 = danger and Color3.fromRGB(150, 40, 40) or self.Theme.Hover })
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.15, { BackgroundTransparency = 0.4, BackgroundColor3 = danger and Color3.fromRGB(120, 30, 30) or self.Theme.Element })
    end)
    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)

    local el = {
        Name = name,
        Refresh = function(_, t)
            Tween(btn, 0.2, { BackgroundColor3 = danger and Color3.fromRGB(120, 30, 30) or t.Element })
            label.TextColor3 = t.Text
        end,
    }
    self:Register(el)
    return el
end

-- SLIDER
function Library:MakeSlider(parent, opts)
    opts = opts or {}
    local name     = opts.Name or "Slider"
    local min      = opts.Min or 0
    local max      = opts.Max or 100
    local default  = opts.Default or min
    local step     = opts.Step or 1
    local suffix   = opts.Suffix or ""
    local callback = opts.Callback or function() end

    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0, Parent = parent,
    })
    Round(row, 6)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -110, 0, 20),
        Position = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1, Text = name,
        TextColor3 = self.Theme.Text, TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })

    local valueLabel = New("TextLabel", {
        Size = UDim2.new(0, 90, 0, 20),
        Position = UDim2.new(1, -100, 0, 4),
        BackgroundTransparency = 1,
        Text = tostring(default) .. suffix,
        TextColor3 = self.Theme.Accent, TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
    })

    local track = New("Frame", {
        Size = UDim2.new(1, -24, 0, 6),
        Position = UDim2.new(0, 12, 0, 32),
        BackgroundColor3 = self.Theme.Stroke,
        BorderSizePixel = 0, Parent = row,
    })
    Round(track, 3)

    local fill = New("Frame", {
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0, Parent = track,
    })
    Round(fill, 3)

    local knob = New("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0, Parent = track,
    })
    Round(knob, 7)

    local value = default
    local dragging = false

    local function setValue(v, fire)
        value = math.clamp(v, min, max)
        value = math.floor(value / step + 0.5) * step
        local pct = (value - min) / (max - min)
        Tween(fill, 0.08, { Size = UDim2.new(pct, 0, 1, 0) })
        Tween(knob, 0.08, { Position = UDim2.new(pct, -7, 0.5, -7) })
        local show = (step < 1) and (math.floor(value * 100) / 100) or math.floor(value)
        valueLabel.Text = tostring(show) .. suffix
        if fire then pcall(callback, value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setValue(min + pct * (max - min), true)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setValue(min + pct * (max - min), true)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local el = {
        Name = name,
        Set = function(v) setValue(v, true) end,
        Get = function() return value end,
        Refresh = function(_, t)
            label.TextColor3 = t.Text
            valueLabel.TextColor3 = t.Accent
            Tween(row, 0.2, { BackgroundColor3 = t.Element })
            track.BackgroundColor3 = t.Stroke
            fill.BackgroundColor3 = t.Accent
        end,
    }
    self:Register(el)
    return el
end

-- DROPDOWN (упрощённый, без ScrollingFrame внутри)
function Library:MakeDropdown(parent, opts)
    opts = opts or {}
    local name     = opts.Name or "Dropdown"
    local options  = opts.Options or {}
    local default  = opts.Default or (options[1] or "")
    local callback = opts.Callback or function() end

    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0, Parent = parent,
    })
    Round(row, 6)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -100, 0, 20),
        Position = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1, Text = name,
        TextColor3 = self.Theme.Text, TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })

    local arrow = New("TextLabel", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -30, 0, 4),
        BackgroundTransparency = 1, Text = "▼",
        TextColor3 = self.Theme.Accent, TextSize = 12,
        Font = Enum.Font.GothamBold, Parent = row,
    })

    local selected = New("TextButton", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.new(0, 12, 0, 24),
        BackgroundTransparency = 1, Text = default,
        TextColor3 = self.Theme.SubText, TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false, Parent = row,
    })

    local container = New("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 6),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0, Visible = false,
        ZIndex = 20, Parent = row,
    })
    Round(container, 6)
    Stroke(container, self.Theme.Accent, 1, 0.5)
    Pad(container, 4, 4)
    New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3), Parent = container,
    })

    local isOpen = false

    local function buildList()
        for _, c in ipairs(container:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(options) do
            local optBtn = New("TextButton", {
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundColor3 = self.Theme.Element,
                BackgroundTransparency = 0.6,
                Text = opt, TextColor3 = self.Theme.Text, TextSize = 12,
                Font = Enum.Font.Gotham,
                AutoButtonColor = false, BorderSizePixel = 0, Parent = container,
            })
            Round(optBtn, 4)
            optBtn.MouseEnter:Connect(function()
                Tween(optBtn, 0.15, { BackgroundColor3 = self.Theme.Hover, BackgroundTransparency = 0.2 })
            end)
            optBtn.MouseLeave:Connect(function()
                Tween(optBtn, 0.15, { BackgroundColor3 = self.Theme.Element, BackgroundTransparency = 0.6 })
            end)
            optBtn.MouseButton1Click:Connect(function()
                selected.Text = opt
                isOpen = false
                container.Visible = false
                Tween(arrow, 0.15, { Rotation = 0 })
                pcall(callback, opt)
            end)
        end
        container.Size = UDim2.new(1, 0, 0, math.min(#options * 27 + 8, 160))
    end
    buildList()

    selected.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        container.Visible = isOpen
        Tween(arrow, 0.15, { Rotation = isOpen and 180 or 0 })
    end)

    local el = {
        Name = name,
        Set = function(v) selected.Text = v; callback(v) end,
        Get = function() return selected.Text end,
        SetOptions = function(newOpts)
            options = newOpts
            buildList()
        end,
        Refresh = function(_, t)
            label.TextColor3 = t.Text
            Tween(row, 0.2, { BackgroundColor3 = t.Element })
            container.BackgroundColor3 = t.Background
        end,
    }
    self:Register(el)
    return el
end

-- TEXTBOX
function Library:MakeTextbox(parent, opts)
    opts = opts or {}
    local name        = opts.Name or "Input"
    local placeholder = opts.Placeholder or "Введите..."
    local default     = opts.Default or ""
    local callback    = opts.Callback or function() end

    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0, Parent = parent,
    })
    Round(row, 6)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 12, 0, 4),
        BackgroundTransparency = 1, Text = name,
        TextColor3 = self.Theme.Text, TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })

    local box = New("TextBox", {
        Size = UDim2.new(1, -24, 0, 22),
        Position = UDim2.new(0, 12, 0, 24),
        BackgroundColor3 = self.Theme.Background,
        Text = default, PlaceholderText = placeholder,
        PlaceholderColor3 = self.Theme.SubText,
        TextColor3 = self.Theme.Text, TextSize = 12,
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0, ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    Round(box, 4)
    Pad(box, 4, 0)
    box.FocusLost:Connect(function(enter) pcall(callback, box.Text, enter) end)

    local el = {
        Name = name,
        Set = function(v) box.Text = v; callback(v) end,
        Get = function() return box.Text end,
        Refresh = function(_, t)
            label.TextColor3 = t.Text
            Tween(row, 0.2, { BackgroundColor3 = t.Element })
            box.BackgroundColor3 = t.Background
            box.TextColor3 = t.Text
        end,
    }
    self:Register(el)
    return el
end

-- KEYBIND
function Library:MakeKeybind(parent, opts)
    opts = opts or {}
    local name     = opts.Name or "Keybind"
    local default  = opts.Default or "K"
    local callback = opts.Callback or function() end

    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0, Parent = parent,
    })
    Round(row, 6)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = name,
        TextColor3 = self.Theme.Text, TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })

    local keyBtn = New("TextButton", {
        Size = UDim2.new(0, 60, 0, 22),
        Position = UDim2.new(1, -70, 0.5, -11),
        BackgroundColor3 = self.Theme.Background,
        Text = default, TextColor3 = self.Theme.Accent, TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false, BorderSizePixel = 0, Parent = row,
    })
    Round(keyBtn, 4)
    Stroke(keyBtn, self.Theme.Accent, 1, 0.5)

    local currentKey = default
    local listening = false

    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."
        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKey = input.KeyCode.Name
                keyBtn.Text = currentKey
                listening = false
                conn:Disconnect()
                pcall(callback, currentKey)
            end
        end)
    end)

    local el = {
        Name = name,
        Set = function(v) currentKey = v; keyBtn.Text = v; callback(v) end,
        Get = function() return currentKey end,
        Refresh = function(_, t)
            label.TextColor3 = t.Text
            Tween(row, 0.2, { BackgroundColor3 = t.Element })
            keyBtn.BackgroundColor3 = t.Background
            keyBtn.TextColor3 = t.Accent
        end,
    }
    self:Register(el)
    return el
end

-- COLORPICKER (упрощённый: 3 слайдера R/G/B)
function Library:MakeColorpicker(parent, opts)
    opts = opts or {}
    local name     = opts.Name or "Color"
    local default  = opts.Default or Color3.fromRGB(255, 80, 80)
    local callback = opts.Callback or function() end

    local row = New("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0, Parent = parent,
    })
    Round(row, 6)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = name,
        TextColor3 = self.Theme.Text, TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })

    local swatch = New("TextButton", {
        Size = UDim2.new(0, 34, 0, 22),
        Position = UDim2.new(1, -46, 0.5, -11),
        BackgroundColor3 = default, Text = "",
        AutoButtonColor = false, BorderSizePixel = 0, Parent = row,
    })
    Round(swatch, 4)
    Stroke(swatch, Color3.fromRGB(255, 255, 255), 1, 0.5)

    local current = default
    local popup = nil

    local function closePopup()
        if popup then popup:Destroy(); popup = nil end
    end

    local function openPopup()
        if popup then closePopup(); return end
        local p = New("Frame", {
            Size = UDim2.new(0, 200, 0, 150),
            Position = UDim2.new(1, 10, 0, 0),
            BackgroundColor3 = self.Theme.Background,
            BorderSizePixel = 0, ZIndex = 50, Parent = row,
        })
        Round(p, 8)
        Stroke(p, self.Theme.Accent, 1.5, 0.3)

        local preview = New("Frame", {
            Size = UDim2.new(1, -20, 0, 26),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundColor3 = current,
            BorderSizePixel = 0, Parent = p,
        })
        Round(preview, 4)

        local vals = {current.R, current.G, current.B}
        local names = {"R", "G", "B"}

        local function apply()
            current = Color3.new(vals[1], vals[2], vals[3])
            swatch.BackgroundColor3 = current
            preview.BackgroundColor3 = current
            pcall(callback, current)
        end

        for i = 1, 3 do
            local sy = 46 + (i - 1) * 28
            New("TextLabel", {
                Size = UDim2.new(0, 16, 0, 20),
                Position = UDim2.new(0, 10, 0, sy),
                BackgroundTransparency = 1, Text = names[i],
                TextColor3 = self.Theme.Accent, TextSize = 12,
                Font = Enum.Font.GothamBold, Parent = p,
            })
            local track = New("Frame", {
                Size = UDim2.new(1, -50, 0, 8),
                Position = UDim2.new(0, 30, 0, sy + 6),
                BackgroundColor3 = self.Theme.Stroke,
                BorderSizePixel = 0, Parent = p,
            })
            Round(track, 4)
            local fill = New("Frame", {
                Size = UDim2.new(vals[i], 0, 1, 0),
                BackgroundColor3 = self.Theme.Accent,
                BorderSizePixel = 0, Parent = track,
            })
            Round(fill, 4)
            local dragging = false
            local function update(x)
                local pct = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                vals[i] = pct
                apply()
            end
            track.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    update(inp.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    update(inp.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
            end)
        end

        local close = New("TextButton", {
            Size = UDim2.new(1, -20, 0, 22),
            Position = UDim2.new(0, 10, 0, 132),
            BackgroundColor3 = self.Theme.Accent,
            Text = "OK", TextColor3 = Color3.fromRGB(255,255,255),
            TextSize = 12, Font = Enum.Font.GothamBold,
            AutoButtonColor = false, BorderSizePixel = 0, Parent = p,
        })
        Round(close, 4)
        close.MouseButton1Click:Connect(closePopup)
        popup = p
    end

    swatch.MouseButton1Click:Connect(openPopup)

    local el = {
        Name = name,
        Set = function(c) current = c; swatch.BackgroundColor3 = c; callback(c) end,
        Get = function() return current end,
        Refresh = function(_, t)
            label.TextColor3 = t.Text
            Tween(row, 0.2, { BackgroundColor3 = t.Element })
        end,
    }
    self:Register(el)
    return el
end

-- LABEL
function Library:MakeLabel(parent, text)
    local lbl = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1, Text = text,
        TextColor3 = self.Theme.Text, TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = parent,
    })
    local el = {
        Refresh = function(_, t) lbl.TextColor3 = t.Text end,
        Set = function(txt) lbl.Text = txt end,
    }
    self:Register(el)
    return el
end

-- DIVIDER
function Library:MakeDivider(parent)
    local div = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = self.Theme.Stroke,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0, Parent = parent,
    })
    local el = { Refresh = function(_, t) div.BackgroundColor3 = t.Stroke end }
    self:Register(el)
    return div
end

-- ═══════════════════════════════════════════════════════════════════
-- ИНИЦИАЛИЗАЦИЯ
-- ═══════════════════════════════════════════════════════════════════

if not (_G.Venture and _G.Venture.F and _G.Venture.F.Settings) then
    warn("[Venture GUI] Functions.lua не загружен — GUI работает в режиме заглушки.")
    F = { Settings = {}, State = {}, Notify = function(t, x) warn(t, x) end }
    S = F.Settings
    _G.Venture.F = F
else
    S = F.Settings
end

local ui = Library:MakeWindow({
    Title = "VENTURE AOT",
    Subtitle = "by __TheDark  |  " .. (_G.Venture.ExecutorName or "Executor"),
})

-- ═══════════════════════════════════════════════════════════════════
-- 1. MAIN
-- ═══════════════════════════════════════════════════════════════════
local MainTab = ui:MakeTab("MAIN")

local AutoFarmSection = ui:MakeSection(MainTab, "🌾 Auto Farm")

ui:MakeToggle(AutoFarmSection, {
    Name = "Enable Auto Farm",
    Default = S.AutoFarmEnabled or false,
    Callback = function(v) S.AutoFarmEnabled = v end,
})

ui:MakeSlider(AutoFarmSection, {
    Name = "Orbit Speed",
    Min = 50, Max = 500, Default = S.AutoFarmOrbitSpeed or 220, Step = 5,
    Callback = function(v) S.AutoFarmOrbitSpeed = v end,
})

ui:MakeSlider(AutoFarmSection, {
    Name = "Hover Height",
    Min = 10, Max = 200, Default = S.AutoFarmHoverHeight or 70, Step = 1,
    Suffix = " studs",
    Callback = function(v) S.AutoFarmHoverHeight = v end,
})

ui:MakeSlider(AutoFarmSection, {
    Name = "Orbit Radius",
    Min = 20, Max = 300, Default = S.AutoFarmOrbitRadius or 70, Step = 5,
    Suffix = " r",
    Callback = function(v) S.AutoFarmOrbitRadius = v end,
})

ui:MakeSlider(AutoFarmSection, {
    Name = "Safe Distance",
    Min = 30, Max = 500, Default = S.AutoFarmSafeDistance or 100, Step = 10,
    Suffix = " studs",
    Callback = function(v) S.AutoFarmSafeDistance = v end,
})

ui:MakeSlider(AutoFarmSection, {
    Name = "Responsiveness",
    Min = 5, Max = 100, Default = S.AutoFarmResponsiveness or 20, Step = 1,
    Callback = function(v) S.AutoFarmResponsiveness = v end,
})

local AutoHealSection = ui:MakeSection(MainTab, "💚 Auto Heal")

ui:MakeToggle(AutoHealSection, {
    Name = "Enable Auto Heal",
    Default = S.AutoHealEnabled or false,
    Callback = function(v) S.AutoHealEnabled = v end,
})

ui:MakeSlider(AutoHealSection, {
    Name = "HP Threshold",
    Min = 10, Max = 100, Default = S.AutoHealThreshold or 80, Step = 5,
    Suffix = "%",
    Callback = function(v) S.AutoHealThreshold = v end,
})

local HitboxSection = ui:MakeSection(MainTab, "📦 Hitbox Expander")

ui:MakeToggle(HitboxSection, {
    Name = "Enable Hitbox",
    Default = S.HitboxExpand or false,
    Callback = function(v)
        S.HitboxExpand = v
        if not v and F.ResetAllHitboxes then F.ResetAllHitboxes() end
    end,
})

ui:MakeDropdown(HitboxSection, {
    Name = "Shape",
    Options = {"Block", "Ball", "Cylinder"},
    Default = S.HitboxShape or "Block",
    Callback = function(v) S.HitboxShape = v end,
})

ui:MakeSlider(HitboxSection, {
    Name = "Size X",
    Min = 5, Max = 500, Default = S.HitboxSize and S.HitboxSize.X or 300, Step = 5,
    Callback = function(v) S.HitboxSize = Vector3.new(v, S.HitboxSize.Y, S.HitboxSize.Z) end,
})
ui:MakeSlider(HitboxSection, {
    Name = "Size Y",
    Min = 5, Max = 500, Default = S.HitboxSize and S.HitboxSize.Y or 200, Step = 5,
    Callback = function(v) S.HitboxSize = Vector3.new(S.HitboxSize.X, v, S.HitboxSize.Z) end,
})
ui:MakeSlider(HitboxSection, {
    Name = "Size Z",
    Min = 5, Max = 500, Default = S.HitboxSize and S.HitboxSize.Z or 300, Step = 5,
    Callback = function(v) S.HitboxSize = Vector3.new(S.HitboxSize.X, S.HitboxSize.Y, v) end,
})

ui:MakeLabel(HitboxSection, "🎯 Hitbox Parts")

ui:MakeToggle(HitboxSection, {
    Name = "Nape", Default = S.HitboxParts and S.HitboxParts.Nape or true,
    Callback = function(v) S.HitboxParts.Nape = v end,
})
ui:MakeToggle(HitboxSection, {
    Name = "Eyes", Default = S.HitboxParts and S.HitboxParts.Eyes or false,
    Callback = function(v) S.HitboxParts.Eyes = v end,
})
ui:MakeToggle(HitboxSection, {
    Name = "Left Arm", Default = S.HitboxParts and S.HitboxParts.LeftArm or false,
    Callback = function(v) S.HitboxParts.LeftArm = v end,
})
ui:MakeToggle(HitboxSection, {
    Name = "Left Leg", Default = S.HitboxParts and S.HitboxParts.LeftLeg or false,
    Callback = function(v) S.HitboxParts.LeftLeg = v end,
})
ui:MakeToggle(HitboxSection, {
    Name = "Right Arm", Default = S.HitboxParts and S.HitboxParts.RightArm or false,
    Callback = function(v) S.HitboxParts.RightArm = v end,
})
ui:MakeToggle(HitboxSection, {
    Name = "Right Leg", Default = S.HitboxParts and S.HitboxParts.RightLeg or false,
    Callback = function(v) S.HitboxParts.RightLeg = v end,
})

ui:MakeDivider(HitboxSection)
ui:MakeToggle(HitboxSection, {
    Name = "Show Visual", Default = S.HitboxShowVisual or false,
    Callback = function(v) S.HitboxShowVisual = v end,
})
ui:MakeColorpicker(HitboxSection, {
    Name = "Visual Color", Default = S.HitboxVisualColor or Color3.fromRGB(255, 100, 200),
    Callback = function(c) S.HitboxVisualColor = c end,
})
ui:MakeSlider(HitboxSection, {
    Name = "Visual Transparency", Min = 0, Max = 1,
    Default = S.HitboxVisualTransparency or 0.6, Step = 0.05,
    Callback = function(v) S.HitboxVisualTransparency = v end,
})

local MiscMainSection = ui:MakeSection(MainTab, "⚙️ Movement & Performance")

ui:MakeToggle(MiscMainSection, {
    Name = "Noclip", Default = S.Noclip or false,
    Callback = function(v)
        S.Noclip = v
        if v and F.StartNoclip then F.StartNoclip() end
        if not v and F.StopNoclip then F.StopNoclip() end
    end,
})

ui:MakeToggle(MiscMainSection, {
    Name = "FPS Booster", Default = S.FPSBoosterEnabled or false,
    Callback = function(v)
        S.FPSBoosterEnabled = v
        if v and F.EnableFPSBooster then F.EnableFPSBooster() end
        if not v and F.DisableFPSBooster then F.DisableFPSBooster() end
    end,
})

local QuickSection = ui:MakeSection(MainTab, "🛠️ Quick Actions")

ui:MakeButton(QuickSection, {
    Name = "Rejoin Server", Subtext = "Переподключиться к текущему серверу",
    Callback = function() if F.RejoinServer then F.RejoinServer() end end,
})
ui:MakeButton(QuickSection, {
    Name = "Join New Server", Subtext = "Перейти на случайный сервер",
    Callback = function() if F.JoinNewServer then F.JoinNewServer() end end,
})
ui:MakeButton(QuickSection, {
    Name = "Copy Server ID", Subtext = "Скопировать JobId",
    Callback = function() if F.CopyServerId then F.CopyServerId() end end,
})

-- ═══════════════════════════════════════════════════════════════════
-- 2. ESP
-- ═══════════════════════════════════════════════════════════════════
local ESPTab = ui:MakeTab("ESP")
local ESPSection = ui:MakeSection(ESPTab, "👁️ Visuals")

ui:MakeToggle(ESPSection, { Name = "Titan ESP", Default = S.ESP or false,
    Callback = function(v) S.ESP = v end })
ui:MakeToggle(ESPSection, { Name = "Player ESP", Default = S.PlayerESP or false,
    Callback = function(v) S.PlayerESP = v end })
ui:MakeToggle(ESPSection, { Name = "Shifter ESP", Default = S.ShifterESP or false,
    Callback = function(v) S.ShifterESP = v end })

ui:MakeDivider(ESPSection)
ui:MakeColorpicker(ESPSection, { Name = "ESP Color", Default = S.ESPColor or Color3.fromRGB(255, 60, 60),
    Callback = function(c) S.ESPColor = c end })
ui:MakeColorpicker(ESPSection, { Name = "Nape Color", Default = S.NapeColor or Color3.fromRGB(80, 255, 120),
    Callback = function(c) S.NapeColor = c end })
ui:MakeColorpicker(ESPSection, { Name = "Target Color", Default = S.TargetColor or Color3.fromRGB(255, 210, 60),
    Callback = function(c) S.TargetColor = c end })

-- ═══════════════════════════════════════════════════════════════════
-- 3. MISC
-- ═══════════════════════════════════════════════════════════════════
local MiscTab = ui:MakeTab("MISC")

local PlayerSection = ui:MakeSection(MiscTab, "🏃 Player")
ui:MakeSlider(PlayerSection, {
    Name = "WalkSpeed", Min = 16, Max = 200, Default = 16, Step = 2,
    Callback = function(v)
        local c = LocalPlayer.Character
        if c and c:FindFirstChildOfClass("Humanoid") then c.Humanoid.WalkSpeed = v end
    end,
})
ui:MakeSlider(PlayerSection, {
    Name = "JumpPower", Min = 50, Max = 300, Default = 50, Step = 5,
    Callback = function(v)
        local c = LocalPlayer.Character
        if c and c:FindFirstChildOfClass("Humanoid") then c.Humanoid.JumpPower = v end
    end,
})

local AntiAFKSection = ui:MakeSection(MiscTab, "💤 Anti-AFK")
ui:MakeToggle(AntiAFKSection, {
    Name = "Enable Anti-AFK", Default = S.AntiAFKEnabled or false,
    Callback = function(v)
        S.AntiAFKEnabled = v
        if v and F.AntiAFKEnable then F.AntiAFKEnable() end
        if not v and F.AntiAFKDisable then F.AntiAFKDisable() end
    end,
})
ui:MakeDropdown(AntiAFKSection, {
    Name = "Mode", Options = {"Both", "Jump", "Move"},
    Default = S.AntiAFKMode or "Both",
    Callback = function(v) S.AntiAFKMode = v end,
})
ui:MakeSlider(AntiAFKSection, {
    Name = "Interval", Min = 5, Max = 120, Default = S.AntiAFKInterval or 20, Step = 1,
    Suffix = " sec",
    Callback = function(v) S.AntiAFKInterval = v end,
})

local SocialSection = ui:MakeSection(MiscTab, "🌐 Social")
ui:MakeButton(SocialSection, {
    Name = "Copy Discord", Subtext = "discord.gg/UHCwX78Npc",
    Callback = function() if F.CopyDiscord then F.CopyDiscord() end end,
})

-- ═══════════════════════════════════════════════════════════════════
-- 4. MOD DETECTOR
-- ═══════════════════════════════════════════════════════════════════
local ModTab = ui:MakeTab("MOD DETECTOR")
local ModSection = ui:MakeSection(ModTab, "🛡️ Mod Detector")

ui:MakeToggle(ModSection, {
    Name = "Auto-Kick on Mod", Default = S.AutoKickOnMod or false,
    Callback = function(v) S.AutoKickOnMod = v end,
})
ui:MakeLabel(ModSection, "Mod Group: " .. tostring(S.ModGroupId or "—"))
ui:MakeDivider(ModSection)
ui:MakeLabel(ModSection, "📋 Список модераторов:")
local ModListLabel = ui:MakeLabel(ModSection, "Загрузка...")
task.spawn(function()
    while task.wait(5) do
        local mods = (F.State and F.State.SecurityState and F.State.SecurityState.ModsInServer) or {}
        local list = {}
        for name, rank in pairs(mods) do
            table.insert(list, name .. " (rank " .. rank .. ")")
        end
        if #list > 0 then
            ModListLabel:Set("• " .. table.concat(list, "\n• "))
        else
            ModListLabel:Set("Нет модераторов ✅")
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- 5. STREAMER
-- ═══════════════════════════════════════════════════════════════════
local StreamerTab = ui:MakeTab("STREAMER")
local StreamerSection = ui:MakeSection(StreamerTab, "🎥 Streamer Mode")

ui:MakeToggle(StreamerSection, {
    Name = "Enable Streamer Mode", Default = S.StreamerEnabled or false,
    Callback = function(v)
        if v and F.StreamerEnable then F.StreamerEnable() end
        if not v and F.StreamerDisable then F.StreamerDisable() end
    end,
})
ui:MakeToggle(StreamerSection, {
    Name = "Hide KillFeed", Default = S.StreamerHideKillFeed or false,
    Callback = function(v) S.StreamerHideKillFeed = v end,
})
ui:MakeDivider(StreamerSection)
ui:MakeTextbox(StreamerSection, { Name = "Fake Name", Default = S.StreamerFakeName or "Streamer",
    Callback = function(v) S.StreamerFakeName = v end })
ui:MakeTextbox(StreamerSection, { Name = "Fake XP", Default = tostring(S.StreamerFakeXP or 1000000),
    Callback = function(v) S.StreamerFakeXP = tonumber(v) or 0 end })
ui:MakeTextbox(StreamerSection, { Name = "Fake Level", Default = tostring(S.StreamerFakeLevel or 1000),
    Callback = function(v) S.StreamerFakeLevel = tonumber(v) or 0 end })
ui:MakeTextbox(StreamerSection, { Name = "Fake Money", Default = tostring(S.StreamerFakeMoney or 1000000),
    Callback = function(v) S.StreamerFakeMoney = tonumber(v) or 0 end })

-- ═══════════════════════════════════════════════════════════════════
-- 6. ONLINE
-- ═══════════════════════════════════════════════════════════════════
local OnlineTab = ui:MakeTab("ONLINE")
local OnlineSection = ui:MakeSection(OnlineTab, "👥 Players Online")

local OnlineDropdown = ui:MakeDropdown(OnlineSection, {
    Name = "Список онлайн", Options = {"Загрузка..."}, Default = "Загрузка...",
})
local OnlineCount = ui:MakeLabel(OnlineSection, "Всего онлайн: ...")

ui:MakeButton(OnlineSection, {
    Name = "🔄 Refresh Online List",
    Callback = function()
        if F.FetchOnlineUsers then
            local users = F.FetchOnlineUsers()
            local names = {}
            for _, u in ipairs(users) do
                table.insert(names, (u.name or "?") .. " (" .. (u.role or "User") .. ")")
            end
            if #names == 0 then names = {"Никого нет"} end
            OnlineDropdown:SetOptions(names)
            OnlineCount:Set("Всего онлайн: " .. #users)
        else
            OnlineCount:Set("Supabase не настроен")
        end
    end,
})

task.spawn(function()
    while task.wait(15) do
        pcall(function()
            if F.FetchOnlineUsers then
                local users = F.FetchOnlineUsers()
                local names = {}
                for _, u in ipairs(users) do
                    table.insert(names, (u.name or "?") .. " (" .. (u.role or "User") .. ")")
                end
                if #names == 0 then names = {"Никого нет"} end
                OnlineDropdown:SetOptions(names)
                OnlineCount:Set("Всего онлайн: " .. #users)
            end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════════
-- 7. ANNOUNCE
-- ═══════════════════════════════════════════════════════════════════
local AnnounceTab = ui:MakeTab("ANNOUNCE")
local AnnounceSection = ui:MakeSection(AnnounceTab, "📢 Announcements (DEV only)")

local AnnounceTitle = "Announcement"
local AnnounceText = ""
ui:MakeTextbox(AnnounceSection, {
    Name = "Title", Default = "Announcement", Placeholder = "Заголовок",
    Callback = function(v) AnnounceTitle = v end,
})
ui:MakeTextbox(AnnounceSection, {
    Name = "Text", Default = "", Placeholder = "Текст...",
    Callback = function(v) AnnounceText = v end,
})
ui:MakeButton(AnnounceSection, {
    Name = "📤 Send Announcement",
    Callback = function()
        if F.SendAnnouncement then F.SendAnnouncement(AnnounceTitle, AnnounceText) end
    end,
})
ui:MakeDivider(AnnounceSection)
ui:MakeLabel(AnnounceSection, "⚠️ Только владелец скрипта может отправлять")

-- ═══════════════════════════════════════════════════════════════════
-- 8. SETTINGS
-- ═══════════════════════════════════════════════════════════════════
local SettingsTab = ui:MakeTab("SETTINGS")
local SettingsSection = ui:MakeSection(SettingsTab, "⚙️ Настройки")

ui:MakeDropdown(SettingsSection, {
    Name = "Тема", Options = {"Dark", "Purple", "Red", "White"},
    Default = Config.Theme or "Dark",
    Callback = function(v) ui:SetTheme(v) end,
})
ui:MakeKeybind(SettingsSection, {
    Name = "Toggle Keybind", Default = Config.Keybind or "K",
    Callback = function(v)
        Config.Keybind = v
        ui.ToggleKey = Enum.KeyCode[v] or Enum.KeyCode.K
        SaveConfig()
    end,
})
ui:MakeButton(SettingsSection, {
    Name = "💾 Save Config",
    Callback = function() SaveConfig(); ui:Notify({ Title = "Config", Content = "Сохранено" }) end,
})
ui:MakeButton(SettingsSection, {
    Name = "🗑️ Reset Config", Danger = true,
    Callback = function()
        if delfile and isfile and isfile(CONFIG_FILE) then pcall(delfile, CONFIG_FILE) end
        ui:Notify({ Title = "Config", Content = "Сброшено (перезайди)" })
    end,
})
ui:MakeButton(SettingsSection, {
    Name = "❌ Unload Script", Danger = true,
    Callback = function()
        if ui.ScreenGui then ui.ScreenGui:Destroy() end
        F.Settings.HitboxExpand = false
        if F.ResetAllHitboxes then F.ResetAllHitboxes() end
        if F.StopNoclip then F.StopNoclip() end
        if F.DisableFPSBooster then F.DisableFPSBooster() end
        if F.CleanupFarm then F.CleanupFarm() end
    end,
})

ui:Notify({ Title = "Venture AOT", Content = "GUI загружен | " .. (_G.Venture.ExecutorName or "Executor"), Duration = 5 })

print("[Venture GUI] Loaded (universal, no LinUI)")
