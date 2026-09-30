--[[
    ═══════════════════════════════════════════════════════════════════
    VENTURE AOT — Custom UI Library (Self-Contained)
    ═══════════════════════════════════════════════════════════════════
    Версия: 2.0
    Автор: Data Hub Team
    Работает: Xeno / Delta / Solara / Arceus X / Wave / Synapse
    
    Особенности:
    - Своя библиотека (не грузит чужие)
    - 4 темы: Dark, Purple, Red, White
    - Draggable, Toggle keybind, автосохранение
    - Toggle, Slider, Dropdown, Button, Textbox, Keybind,
      Colorpicker, Label, Divider, Section, Notification
    - Анимации Tween, glow-обводки
    ═══════════════════════════════════════════════════════════════════
--]]

-- ==================== SERVICES ====================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local HttpService        = game:GetService("HttpService")
local CoreGui            = game:GetService("CoreGui")
local LocalPlayer        = Players.LocalPlayer

-- ==================== UTILS ====================
local UI = {}
UI.__index = UI

local function New(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function Tween(obj, time, props, style)
    local t = TweenService:Create(obj, TweenInfo.new(
        time or 0.25,
        style or Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    ), props)
    t:Play()
    return t
end

local function Round(obj, radius)
    New("UICorner", { CornerRadius = UDim.new(0, radius or 6) }, obj)
end

local function Stroke(obj, color, thickness, transparency)
    New("UIStroke", {
        Color = color or Color3.fromRGB(60, 60, 80),
        Thickness = thickness or 1,
        Transparency = transparency or 0.5,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, obj)
end

local function Gradient(obj, c1, c2, rotation)
    New("UIGradient", {
        Color = ColorSequence.new(c1, c2),
        Rotation = rotation or 90,
    }, obj)
end

local function Pad(obj, px)
    New("UIPadding", {
        PaddingTop = UDim.new(0, px),
        PaddingBottom = UDim.new(0, px),
        PaddingLeft = UDim.new(0, px),
        PaddingRight = UDim.new(0, px),
    }, obj)
end

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

-- ==================== CONFIG ====================
local CONFIG_FILE = "VentureAOT_Config.json"
local Config = {
    Theme = "Dark",
    Keybind = "K",
    Size = {600, 420},
    Position = {0.5, 0.5},
    Opacity = 1,
    Blur = true,
    AutoSave = true,
    TabOrder = {"MAIN", "ESP", "MISC", "MOD DETECTOR", "STREAMER", "ONLINE", "ANNOUNCE"},
}

local function LoadConfig()
    if not (isfile and isfile(CONFIG_FILE)) then return end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if ok and type(data) == "table" then
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

local Theme = Themes[Config.Theme] or Themes.Dark

-- ==================== LIBRARY ROOT ====================
local Library = {
    ScreenGui = nil,
    MainFrame = nil,
    Header = nil,
    Sidebar = nil,
    Content = nil,
    Tabs = {},
    ActiveTab = nil,
    Elements = {},
    Notifications = {},
    ToggleKey = Enum.KeyCode[Config.Keybind] or Enum.KeyCode.K,
    Visible = true,
    Theme = Theme,
    Config = Config,
    Themes = Themes,
    _connections = {},
}

-- ==================== UI HELPERS ====================
function Library:Register(obj)
    table.insert(self.Elements, obj)
    return obj
end

function Library:SetTheme(themeName)
    local t = Themes[themeName]
    if not t then return end
    self.Theme = t
    Config.Theme = themeName
    SaveConfig()
    self:RefreshTheme()
end

function Library:RefreshTheme()
    local t = self.Theme
    if self.MainFrame then
        Tween(self.MainFrame, 0.25, {BackgroundColor3 = t.Secondary})
    end
    if self.Header then
        Tween(self.Header, 0.25, {BackgroundColor3 = t.Background})
    end
    if self.Sidebar then
        Tween(self.Sidebar, 0.25, {BackgroundColor3 = t.Background})
    end
    if self.Content then
        Tween(self.Content, 0.25, {BackgroundColor3 = t.Secondary})
    end
    for _, el in ipairs(self.Elements) do
        if el.Refresh then pcall(el.Refresh, el, t) end
    end
    for _, tab in pairs(self.Tabs) do
        if tab.Refresh then pcall(tab.Refresh, tab, t) end
    end
end

function Library:Notify(opts)
    opts = opts or {}
    local title = opts.Title or "Notification"
    local text  = opts.Content or opts.Text or ""
    local dur   = opts.Duration or 4

    local notif = New("Frame", {
        Size = UDim2.new(0, 320, 0, 70),
        Position = UDim2.new(1, 340, 1, -90 - #self.Notifications * 80),
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Parent = self.ScreenGui,
    })
    Round(notif, 8)
    Stroke(notif, self.Theme.Accent, 1.5, 0.3)
    New("Frame", {
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Parent = notif,
    })

    New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 24),
        Position = UDim2.new(0, 14, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.Theme.Accent,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 34),
        Position = UDim2.new(0, 14, 0, 30),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
    })

    table.insert(self.Notifications, notif)

    Tween(notif, 0.35, {Position = UDim2.new(1, -340, 1, -90 - (#self.Notifications - 1) * 80)})

    task.delay(dur, function()
        Tween(notif, 0.3, {Position = UDim2.new(1, 340, 1, notif.Position.Y.Offset)})
        task.wait(0.35)
        notif:Destroy()
        for i, n in ipairs(self.Notifications) do
            if n == notif then table.remove(self.Notifications, i) break end
        end
    end)
end

-- ==================== WINDOW ====================
function Library:MakeWindow(opts)
    opts = opts or {}
    local title = opts.Title or "VENTURE AOT"
    local subtitle = opts.Subtitle or "by Data Hub Team"
    local keybind = opts.Keybind or self.ToggleKey

    -- ScreenGui
    local gui = New("ScreenGui", {
        Name = "VentureAOT_GUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    self.ScreenGui = gui

    -- Main Frame
    local main = New("Frame", {
        Name = "Main",
        Size = UDim2.new(0, Config.Size[1], 0, Config.Size[2]),
        Position = UDim2.new(Config.Position[1], -Config.Size[1]/2, Config.Position[2], -Config.Size[2]/2),
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        Parent = gui,
    })
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    Round(main, 10)
    Stroke(main, self.Theme.Stroke, 1, 0.3)
    self.MainFrame = main

    -- Header
    local header = New("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Parent = main,
    })
    Round(header, 10)
    New("Frame", {
        Size = UDim2.new(1, 0, 0, 14),
        Position = UDim2.new(0, 0, 1, -14),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Parent = header,
    })
    self.Header = header

    -- Accent line under header
    New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = self.Theme.Accent,
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        Parent = header,
    })

    -- Title
    local titleLabel = New("TextLabel", {
        Size = UDim2.new(0, 300, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.Theme.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    self.TitleLabel = titleLabel

    -- Subtitle
    local subLabel = New("TextLabel", {
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 16, 0, 12),
        BackgroundTransparency = 1,
        Text = subtitle,
        TextColor3 = self.Theme.SubText,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    -- Minimize button
    local minBtn = New("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -70, 0, 5),
        BackgroundColor3 = self.Theme.Element,
        Text = "—",
        TextColor3 = self.Theme.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = header,
    })
    Round(minBtn, 6)
    minBtn.MouseEnter:Connect(function() Tween(minBtn, 0.15, {BackgroundColor3 = self.Theme.Hover}) end)
    minBtn.MouseLeave:Connect(function() Tween(minBtn, 0.15, {BackgroundColor3 = self.Theme.Element}) end)
    minBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)

    -- Close button
    local closeBtn = New("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -36, 0, 5),
        BackgroundColor3 = self.Theme.Element,
        Text = "✕",
        TextColor3 = self.Theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = header,
    })
    Round(closeBtn, 6)
    closeBtn.MouseEnter:Connect(function() Tween(closeBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}) end)
    closeBtn.MouseLeave:Connect(function() Tween(closeBtn, 0.15, {BackgroundColor3 = self.Theme.Element}) end)
    closeBtn.MouseButton1Click:Connect(function()
        self:Hide()
    end)

    -- Sidebar
    local sidebar = New("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 130, 1, -38),
        Position = UDim2.new(0, 0, 0, 38),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Parent = main,
    })
    self.Sidebar = sidebar
    local sidebarPad = New("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = sidebar,
    })
    local sidebarLayout = New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = sidebar,
    })

    -- Content area
    local content = New("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -130, 1, -38),
        Position = UDim2.new(0, 130, 0, 38),
        BackgroundColor3 = self.Theme.Secondary,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = main,
    })
    Round(content, 0)
    self.Content = content

    -- Content scroll + padding
    local contentScroll = New("ScrollingFrame", {
        Name = "Scroll",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = content,
    })
    local contentPad = New("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = contentScroll,
    })
    local contentLayout = New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = contentScroll,
    })
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
    end)
    self.ContentScroll = contentScroll

    -- Footer
    local footer = New("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 1, -20),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Parent = main,
    })
    New("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "by Data Hub Team | v2.0 | Keybind: " .. Config.Keybind,
        TextColor3 = self.Theme.SubText,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = footer,
    })
    self.Footer = footer

    -- Dragging
    self:MakeDraggable(header, main)

    -- Keybind toggle
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == self.ToggleKey then
            self:Toggle()
        end
    end)

    -- Opacity
    main.BackgroundTransparency = 1 - Config.Opacity

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
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
           or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            frame.Position = newPos
            Config.Position = {newPos.X.Scale, newPos.Y.Scale}
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                SaveConfig()
            end
        end
    end)
end

function Library:Toggle()
    self.Visible = not self.Visible
    if self.Visible then
        self.MainFrame.Visible = true
        self.MainFrame.Size = UDim2.new(0, self.MainFrame.Size.X.Offset * 0.9, 0, self.MainFrame.Size.Y.Offset * 0.9)
        Tween(self.MainFrame, 0.3, {
            Size = UDim2.new(0, Config.Size[1], 0, Config.Size[2]),
            BackgroundTransparency = 1 - Config.Opacity,
        })
    else
        Tween(self.MainFrame, 0.25, {
            Size = UDim2.new(0, self.MainFrame.Size.X.Offset * 0.9, 0, self.MainFrame.Size.Y.Offset * 0.9),
            BackgroundTransparency = 1,
        })
        task.delay(0.3, function() self.MainFrame.Visible = false end)
    end
end

function Library:Hide()
    self.Visible = false
    Tween(self.MainFrame, 0.25, {BackgroundTransparency = 1})
    task.delay(0.3, function() self.MainFrame.Visible = false end)
end

function Library:Show()
    self.Visible = true
    self.MainFrame.Visible = true
    Tween(self.MainFrame, 0.25, {BackgroundTransparency = 1 - Config.Opacity})
end

function Library:ToggleMinimize()
    -- Простое сворачивание — скрываем контент
    if self.Content.Visible then
        self.Content.Visible = false
        self.Sidebar.Visible = false
        Tween(self.MainFrame, 0.25, {Size = UDim2.new(0, Config.Size[1], 0, 38)})
    else
        self.Content.Visible = true
        self.Sidebar.Visible = true
        Tween(self.MainFrame, 0.25, {Size = UDim2.new(0, Config.Size[1], 0, Config.Size[2])})
    end
end

-- ==================== TAB ====================
function Library:MakeTab(name)
    local tab = {
        Name = name,
        Elements = {},
        _active = false,
        _btn = nil,
        _frame = nil,
        Theme = self.Theme,
    }

    -- Sidebar button
    local btn = New("TextButton", {
        Name = name .. "_Tab",
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.4,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = self.Sidebar,
    })
    Round(btn, 6)
    btn.MouseEnter:Connect(function()
        if not tab._active then
            Tween(btn, 0.15, {BackgroundColor3 = self.Theme.Hover, BackgroundTransparency = 0.2})
        end
    end)
    btn.MouseLeave:Connect(function()
        if not tab._active then
            Tween(btn, 0.15, {BackgroundColor3 = self.Theme.Element, BackgroundTransparency = 0.4})
        end
    end)

    -- Content frame
    local frame = New("Frame", {
        Name = name .. "_Frame",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.ContentScroll,
    })
    local frameLayout = New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = frame,
    })

    tab._btn = btn
    tab._frame = frame
    tab._layout = frameLayout
    tab.Library = self

    function tab:Activate()
        for _, t in pairs(self.Library.Tabs) do
            t._active = false
            t._frame.Visible = false
            if t._btn then
                Tween(t._btn, 0.15, {BackgroundColor3 = self.Library.Theme.Element, BackgroundTransparency = 0.4})
            end
        end
        self._active = true
        self._frame.Visible = true
        Tween(self._btn, 0.15, {BackgroundColor3 = self.Library.Theme.Accent, BackgroundTransparency = 0})
        self.Library.ActiveTab = self
    end

    btn.MouseButton1Click:Connect(function() tab:Activate() end)

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then tab:Activate() end

    return tab
end

-- ==================== SECTION ====================
function Library:MakeSection(tab, name)
    local section = New("Frame", {
        Name = "Section_" .. (name or ""),
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = tab._frame,
    })
    Round(section, 6)
    Stroke(section, self.Theme.Stroke, 1, 0.5)
    New("TextLabel", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = name or "Section",
        TextColor3 = self.Theme.Accent,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section,
    })
    return section
end

-- ==================== ELEMENTS ====================

-- Toggle (Switch, стиль Fluent)
function Library:MakeToggle(tab, opts)
    opts = opts or {}
    local name = opts.Name or "Toggle"
    local default = opts.Default or false
    local callback = opts.Callback or function() end
    local flag = opts.Flag

    local row = New("Frame", {
        Name = "Toggle_" .. name,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = tab._frame,
    })
    Round(row, 6)

    -- Label
    local label = New("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    -- Switch track
    local switch = New("Frame", {
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(1, -52, 0.5, -10),
        BackgroundColor3 = self.Theme.Stroke,
        BorderSizePixel = 0,
        Parent = row,
    })
    Round(switch, 10)

    -- Switch dot
    local dot = New("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = default and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = switch,
    })
    Round(dot, 8)

    local state = default

    local function setState(v, fire)
        state = v
        Tween(switch, 0.2, {BackgroundColor3 = v and self.Theme.Accent or self.Theme.Stroke})
        Tween(dot, 0.2, {Position = v and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)})
        if fire then callback(v) end
    end

    if default then setState(true, false) end

    local btn = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row,
    })
    btn.MouseEnter:Connect(function() Tween(row, 0.15, {BackgroundTransparency = 0.3}) end)
    btn.MouseLeave:Connect(function() Tween(row, 0.15, {BackgroundTransparency = 0.5}) end)
    btn.MouseButton1Click:Connect(function() setState(not state, true) end)

    local element = {
        Name = name,
        Flag = flag,
        Refresh = function(_, t)
            label.TextColor3 = t.Text
            Tween(row, 0.2, {BackgroundColor3 = t.Element})
            Tween(switch, 0.2, {BackgroundColor3 = state and t.Accent or t.Stroke})
        end,
        Set = function(v) setState(v, true) end,
        Get = function() return state end,
    }
    self:Register(element)
    return element
end

-- Button (с subtext, стиль Fluent)
function Library:MakeButton(tab, opts)
    opts = opts or {}
    local name = opts.Name or "Button"
    local subtext = opts.Subtext or ""
    local callback = opts.Callback or function() end

    local btn = New("TextButton", {
        Name = "Button_" .. name,
        Size = UDim2.new(1, 0, 0, subtext ~= "" and 42 or 32),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.4,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = tab._frame,
    })
    Round(btn, 6)
    Stroke(btn, self.Theme.Accent, 1, 0.6)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -20, subtext ~= "" and 0.55 or 1, 0),
        Position = UDim2.new(0, 12, 0, subtext ~= "" and 3 or 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn,
    })

    if subtext ~= "" then
        New("TextLabel", {
            Size = UDim2.new(1, -20, 0, 16),
            Position = UDim2.new(0, 12, 0, 22),
            BackgroundTransparency = 1,
            Text = subtext,
            TextColor3 = self.Theme.SubText,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = btn,
        })
    end

    btn.MouseEnter:Connect(function() Tween(btn, 0.15, {BackgroundTransparency = 0.2, BackgroundColor3 = self.Theme.Hover}) end)
    btn.MouseLeave:Connect(function() Tween(btn, 0.15, {BackgroundTransparency = 0.4, BackgroundColor3 = self.Theme.Element}) end)
    btn.MouseButton1Click:Connect(function()
        Tween(btn, 0.1, {Size = UDim2.new(1, -4, 0, btn.Size.Y.Offset - 2)})
        task.delay(0.1, function() Tween(btn, 0.1, {Size = UDim2.new(1, 0, 0, btn.Size.Y.Offset + 2)}) end)
        callback()
    end)

    local element = {
        Name = name,
        Refresh = function(_, t)
            Tween(btn, 0.2, {BackgroundColor3 = t.Element})
            label.TextColor3 = t.Text
        end,
    }
    self:Register(element)
    return element
end

-- Slider (стиль Orion — с числом справа)
function Library:MakeSlider(tab, opts)
    opts = opts or {}
    local name = opts.Name or "Slider"
    local min = opts.Min or 0
    local max = opts.Max or 100
    local default = opts.Default or min
    local step = opts.Step or 1
    local suffix = opts.Suffix or ""
    local callback = opts.Callback or function() end
    local flag = opts.Flag

    local row = New("Frame", {
        Name = "Slider_" .. name,
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = tab._frame,
    })
    Round(row, 6)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -100, 0, 20),
        Position = UDim2.new(0, 12, 0, 3),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local valueLabel = New("TextLabel", {
        Size = UDim2.new(0, 80, 0, 20),
        Position = UDim2.new(1, -90, 0, 3),
        BackgroundTransparency = 1,
        Text = tostring(default) .. suffix,
        TextColor3 = self.Theme.Accent,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    -- Track
    local track = New("Frame", {
        Size = UDim2.new(1, -24, 0, 6),
        Position = UDim2.new(0, 12, 0, 30),
        BackgroundColor3 = self.Theme.Stroke,
        BorderSizePixel = 0,
        Parent = row,
    })
    Round(track, 3)

    -- Fill
    local fill = New("Frame", {
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    Round(fill, 3)

    -- Knob
    local knob = New("Frame", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = track,
    })
    Round(knob, 7)

    local value = default
    local dragging = false

    local function setValue(v, fire)
        value = math.clamp(v, min, max)
        value = math.floor(value / step) * step
        local pct = (value - min) / (max - min)
        Tween(fill, 0.1, {Size = UDim2.new(pct, 0, 1, 0)})
        Tween(knob, 0.1, {Position = UDim2.new(pct, -7, 0.5, -7)})
        valueLabel.Text = tostring(math.floor(value * 100) / 100) .. suffix
        if fire then callback(value) end
    end

    -- Click + drag on track
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setValue(min + pos * (max - min), true)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            setValue(min + pos * (max - min), true)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local element = {
        Name = name,
        Flag = flag,
        Refresh = function(_, t)
            label.TextColor3 = t.Text
            valueLabel.TextColor3 = t.Accent
            Tween(row, 0.2, {BackgroundColor3 = t.Element})
            track.BackgroundColor3 = t.Stroke
            fill.BackgroundColor3 = t.Accent
        end,
        Set = function(v) setValue(v, true) end,
        Get = function() return value end,
    }
    self:Register(element)
    return element
end

-- Dropdown (стиль MoonLIB — со скроллом)
function Library:MakeDropdown(tab, opts)
    opts = opts or {}
    local name = opts.Name or "Dropdown"
    local options = opts.Options or {}
    local default = opts.Default or (options[1] or "")
    local callback = opts.Callback or function() end
    local flag = opts.Flag

    local row = New("Frame", {
        Name = "Dropdown_" .. name,
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = tab._frame,
    })
    Round(row, 6)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -100, 0, 20),
        Position = UDim2.new(0, 12, 0, 3),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local arrow = New("TextLabel", {
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -30, 0, 3),
        BackgroundTransparency = 1,
        Text = "▼",
        TextColor3 = self.Theme.Accent,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        Parent = row,
    })

    local selected = New("TextButton", {
        Size = UDim2.new(1, -24, 0, 16),
        Position = UDim2.new(0, 12, 0, 22),
        BackgroundTransparency = 1,
        Text = default,
        TextColor3 = self.Theme.SubText,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        Parent = row,
    })

    -- Dropdown container
    local container = New("ScrollingFrame", {
        Name = "DropdownList",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 4),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Visible = false,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Theme.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 10,
        Parent = row,
    })
    Round(container, 6)
    Stroke(container, self.Theme.Accent, 1, 0.5)
    local listLayout = New("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = container,
    })
    New("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = container,
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
                BackgroundTransparency = 0.5,
                Text = opt,
                TextColor3 = self.Theme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                AutoButtonColor = false,
                BorderSizePixel = 0,
                Parent = container,
            })
            Round(optBtn, 4)
            optBtn.MouseEnter:Connect(function() Tween(optBtn, 0.15, {BackgroundColor3 = self.Theme.Hover, BackgroundTransparency = 0.2}) end)
            optBtn.MouseLeave:Connect(function() Tween(optBtn, 0.15, {BackgroundColor3 = self.Theme.Element, BackgroundTransparency = 0.5}) end)
            optBtn.MouseButton1Click:Connect(function()
                selected.Text = opt
                isOpen = false
                Tween(container, 0.2, {Size = UDim2.new(1, 0, 0, 0)})
                task.delay(0.2, function() container.Visible = false end)
                Tween(arrow, 0.15, {Rotation = 0})
                callback(opt)
            end)
        end
        container.CanvasSize = UDim2.new(0, 0, 0, #options * 26 + 8)
    end
    buildList()

    local openBtn = New("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row,
    })
    openBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            container.Visible = true
            local targetH = math.min(#options * 26 + 8, 150)
            Tween(container, 0.2, {Size = UDim2.new(1, 0, 0, targetH)})
            Tween(arrow, 0.15, {Rotation = 180})
        else
            Tween(container, 0.2, {Size = UDim2.new(1, 0, 0, 0)})
            Tween(arrow, 0.15, {Rotation = 0})
            task.delay(0.2, function() container.Visible = false end)
        end
    end)

    local element = {
        Name = name,
        Flag = flag,
        Refresh = function(_, t)
            label.TextColor3 = t.Text
            Tween(row, 0.2, {BackgroundColor3 = t.Element})
            container.BackgroundColor3 = t.Background
        end,
        Set = function(v) selected.Text = v; callback(v) end,
        Get = function() return selected.Text end,
        RefreshOptions = function(newOpts)
            options = newOpts
            buildList()
        end,
    }
    self:Register(element)
    return element
end

-- Textbox
function Library:MakeTextbox(tab, opts)
    opts = opts or {}
    local name = opts.Name or "Input"
    local placeholder = opts.Placeholder or "Введите..."
    local default = opts.Default or ""
    local callback = opts.Callback or function() end
    local flag = opts.Flag

    local row = New("Frame", {
        Name = "Textbox_" .. name,
        Size = UDim2.new(1, 0, 0, 46),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = tab._frame,
    })
    Round(row, 6)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 12, 0, 3),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local box = New("TextBox", {
        Size = UDim2.new(1, -24, 0, 20),
        Position = UDim2.new(0, 12, 0, 22),
        BackgroundColor3 = self.Theme.Background,
        Text = default,
        PlaceholderText = placeholder,
        PlaceholderColor3 = self.Theme.SubText,
        TextColor3 = self.Theme.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    Round(box, 4)
    Pad(box, 4)
    box.FocusLost:Connect(function() callback(box.Text) end)

    local element = {
        Name = name,
        Flag = flag,
        Refresh = function(_, t)
            label.TextColor3 = t.Text
            Tween(row, 0.2, {BackgroundColor3 = t.Element})
            box.BackgroundColor3 = t.Background
            box.TextColor3 = t.Text
        end,
        Set = function(v) box.Text = v; callback(v) end,
        Get = function() return box.Text end,
    }
    self:Register(element)
    return element
end

-- Keybind (стиль LinUI)
function Library:MakeKeybind(tab, opts)
    opts = opts or {}
    local name = opts.Name or "Keybind"
    local default = opts.Default or "K"
    local callback = opts.Callback or function() end
    local flag = opts.Flag

    local row = New("Frame", {
        Name = "Keybind_" .. name,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = tab._frame,
    })
    Round(row, 6)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local keyBtn = New("TextButton", {
        Size = UDim2.new(0, 60, 0, 22),
        Position = UDim2.new(1, -70, 0.5, -11),
        BackgroundColor3 = self.Theme.Background,
        Text = default,
        TextColor3 = self.Theme.Accent,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = row,
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
                callback(currentKey)
            end
        end)
    end)

    local element = {
        Name = name,
        Flag = flag,
        Refresh = function(_, t)
            label.TextColor3 = t.Text
            Tween(row, 0.2, {BackgroundColor3 = t.Element})
            keyBtn.BackgroundColor3 = t.Background
            keyBtn.TextColor3 = t.Accent
        end,
        Set = function(v) currentKey = v; keyBtn.Text = v; callback(v) end,
        Get = function() return currentKey end,
    }
    self:Register(element)
    return element
end

-- Colorpicker (упрощённый, стиль Orion)
function Library:MakeColorpicker(tab, opts)
    opts = opts or {}
    local name = opts.Name or "Color"
    local default = opts.Default or Color3.fromRGB(255, 80, 80)
    local callback = opts.Callback or function() end
    local flag = opts.Flag

    local row = New("Frame", {
        Name = "Colorpicker_" .. name,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = tab._frame,
    })
    Round(row, 6)

    local label = New("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Theme.Text,
        TextSize = 13,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local swatch = New("TextButton", {
        Size = UDim2.new(0, 30, 0, 20),
        Position = UDim2.new(1, -42, 0.5, -10),
        BackgroundColor3 = default,
        Text = "",
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = row,
    })
    Round(swatch, 4)
    Stroke(swatch, Color3.fromRGB(255, 255, 255), 1, 0.5)

    local currentColor = default
    local pickerOpen = false

    -- Simple RGB picker (открывается при клике)
    swatch.MouseButton1Click:Connect(function()
        pickerOpen = not pickerOpen
        if pickerOpen then
            -- Быстрый случайный подбор для демо (можно расширить до полного picker'а)
            local r = math.random(0, 255) / 255
            local g = math.random(0, 255) / 255
            local b = math.random(0, 255) / 255
            currentColor = Color3.new(r, g, b)
            swatch.BackgroundColor3 = currentColor
            callback(currentColor)
            pickerOpen = false
        end
    end)

    local element = {
        Name = name,
        Flag = flag,
        Refresh = function(_, t)
            label.TextColor3 = t.Text
            Tween(row, 0.2, {BackgroundColor3 = t.Element})
        end,
        Set = function(c) currentColor = c; swatch.BackgroundColor3 = c; callback(c) end,
        Get = function() return currentColor end,
    }
    self:Register(element)
    return element
end

-- Label
function Library:MakeLabel(tab, text)
    local lbl = New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Theme.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tab._frame,
    })
    local element = {
        Refresh = function(_, t) lbl.TextColor3 = t.Text end,
        Set = function(txt) lbl.Text = txt end,
    }
    self:Register(element)
    return element
end

-- Divider
function Library:MakeDivider(tab)
    local div = New("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = self.Theme.Stroke,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = tab._frame,
    })
    local element = {
        Refresh = function(_, t) div.BackgroundColor3 = t.Stroke end,
    }
    self:Register(element)
    return div
end

-- ==================== BUILD UI ====================
local ui = Library:MakeWindow({
    Title = "VENTURE AOT",
    Subtitle = "by Data Hub Team | v2.0",
    Keybind = Enum.KeyCode[Config.Keybind] or Enum.KeyCode.K,
})

-- ==================== 1. MAIN ====================
local MainTab = ui:MakeTab("MAIN")
ui:MakeSection(MainTab, "⚡ Auto Functions")

ui:MakeToggle(MainTab, {
    Name = "Auto Farm",
    Default = false,
    Callback = function(v) print("[MAIN] AutoFarm:", v) end,
})

ui:MakeToggle(MainTab, {
    Name = "Hitbox Expander",
    Default = false,
    Callback = function(v)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character.HumanoidRootPart.Size = v and Vector3.new(10,10,10) or Vector3.new(2,2,1)
                plr.Character.HumanoidRootPart.Transparency = v and 0.7 or 1
            end
        end
    end,
})

local noclip = false
ui:MakeToggle(MainTab, {
    Name = "Noclip",
    Default = false,
    Callback = function(v) noclip = v end,
})
RunService.Stepped:Connect(function()
    if noclip and LocalPlayer.Character then
        for _, p in ipairs(LocalPlayer.Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

ui:MakeToggle(MainTab, {
    Name = "FPS Booster (всегда включён)",
    Default = true,
    Callback = function(v)
        if v then
            pcall(function()
                Lighting.GlobalShadows = false
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
        else
            pcall(function()
                Lighting.GlobalShadows = true
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level08
            end)
        end
    end,
})

local autoHeal = false
ui:MakeToggle(MainTab, {
    Name = "Auto Heal",
    Default = false,
    Callback = function(v) autoHeal = v end,
})
task.spawn(function()
    while task.wait(1) do
        if autoHeal and LocalPlayer.Character then
            local h = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h then h.Health = h.MaxHealth end
        end
    end
end)

ui:MakeDivider(MainTab)
ui:MakeSection(MainTab, "🛠️ Быстрые действия")

ui:MakeButton(MainTab, {
    Name = "Rejoin Server",
    Subtext = "Переподключиться к текущему серверу",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end,
})

ui:MakeButton(MainTab, {
    Name = "Server Hop",
    Subtext = "Найти другой сервер",
    Callback = function()
        local TS = game:GetService("TeleportService")
        local ok, data = pcall(function()
            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")).data
        end)
        if ok then
            for _, s in ipairs(data) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TS:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    return
                end
            end
        end
        ui:Notify({Title = "Server Hop", Content = "Серверы не найдены"})
    end,
})

-- ==================== 2. ESP ====================
local ESPTab = ui:MakeTab("ESP")
ui:MakeSection(ESPTab, "👁️ Визуальные функции")

local ESPState = {
    Player = false,
    Titan = false,
    Shifter = false,
    PlayerColor = Color3.fromRGB(255, 80, 80),
    TitanColor = Color3.fromRGB(255, 200, 80),
    ShifterColor = Color3.fromRGB(80, 255, 180),
}

local espObjects = {}
local function createESP(plr)
    if plr == LocalPlayer or espObjects[plr] then return end
    local box = Drawing.new("Square")
    box.Thickness = 2; box.Filled = false; box.Transparency = 1
    box.Color = ESPState.PlayerColor; box.Visible = false
    local name = Drawing.new("Text")
    name.Size = 14; name.Center = true; name.Outline = true
    name.Color = Color3.fromRGB(255,255,255); name.Visible = false
    espObjects[plr] = {box = box, name = name}
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(p)
    if espObjects[p] then
        espObjects[p].box:Remove()
        espObjects[p].name:Remove()
        espObjects[p] = nil
    end
end)
for _, p in ipairs(Players:GetPlayers()) do createESP(p) end

RunService.RenderStepped:Connect(function()
    for plr, o in pairs(espObjects) do
        local c = plr.Character
        if not c or not c:FindFirstChild("HumanoidRootPart") or not c:FindFirstChild("Head") then
            o.box.Visible = false; o.name.Visible = false
            continue
        end
        local pos, on = Camera.WorldToViewportPoint(c.HumanoidRootPart.Position)
        if not on then o.box.Visible = false; o.name.Visible = false; continue end
        local dist = (c.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
        if dist > 1000 then o.box.Visible = false; o.name.Visible = false; continue end
        local h = 1000/dist * 3
        o.box.Size = Vector2.new(h/2, h)
        o.box.Position = Vector2.new(pos.X - h/4, pos.Y - h/2)
        o.box.Color = ESPState.PlayerColor
        o.box.Visible = ESPState.Player
        o.name.Text = plr.Name .. " [" .. math.floor(dist) .. "]"
        o.name.Position = Vector2.new(pos.X, pos.Y - h/2 - 16)
        o.name.Visible = ESPState.Player
    end
end)

ui:MakeToggle(ESPTab, {Name = "Player ESP", Default = false, Callback = function(v) ESPState.Player = v end})
ui:MakeColorpicker(ESPTab, {Name = "Player Color", Default = ESPState.PlayerColor, Callback = function(c) ESPState.PlayerColor = c end})
ui:MakeToggle(ESPTab, {Name = "Titan ESP", Default = false, Callback = function(v) ESPState.Titan = v end})
ui:MakeColorpicker(ESPTab, {Name = "Titan Color", Default = ESPState.TitanColor, Callback = function(c) ESPState.TitanColor = c end})
ui:MakeToggle(ESPTab, {Name = "Shifter ESP", Default = false, Callback = function(v) ESPState.Shifter = v end})
ui:MakeColorpicker(ESPTab, {Name = "Shifter Color", Default = ESPState.ShifterColor, Callback = function(c) ESPState.ShifterColor = c end})

-- ==================== 3. MISC ====================
local MiscTab = ui:MakeTab("MISC")
ui:MakeSection(MiscTab, "🔧 Утилиты")

ui:MakeButton(MiscTab, {
    Name = "Copy Discord Invite",
    Subtext = "Скопировать ссылку на Discord-сервер",
    Callback = function()
        setclipboard("https://discord.gg/25ms")
        ui:Notify({Title = "Discord", Content = "Ссылка скопирована"})
    end,
})

local antiAFK = false
ui:MakeToggle(MiscTab, {Name = "Anti-AFK", Default = false, Callback = function(v) antiAFK = v end})
task.spawn(function()
    while task.wait(60) do
        if antiAFK then
            pcall(function()
                game:GetService("VirtualUser"):CaptureController()
                game:GetService("VirtualUser"):ClickButton2(Vector2.new())
            end)
        end
    end
end)

ui:MakeSlider(MiscTab, {
    Name = "WalkSpeed",
    Min = 16, Max = 200, Default = 16, Step = 2, Suffix = " spd",
    Callback = function(v)
        local c = LocalPlayer.Character
        if c and c:FindFirstChildOfClass("Humanoid") then c.Humanoid.WalkSpeed = v end
    end,
})

ui:MakeSlider(MiscTab, {
    Name = "JumpPower",
    Min = 50, Max = 300, Default = 50, Step = 5, Suffix = " jp",
    Callback = function(v)
        local c = LocalPlayer.Character
        if c and c:FindFirstChildOfClass("Humanoid") then c.Humanoid.JumpPower = v end
    end,
})

-- ==================== 4. MOD DETECTOR ====================
local ModTab = ui:MakeTab("MOD DETECTOR")
ui:MakeSection(ModTab, "🛡️ Mod Detector")

local modDetect = false
local autoKick = false

ui:MakeToggle(ModTab, {Name = "Enable Mod Detector", Default = false, Callback = function(v) modDetect = v end})
ui:MakeToggle(ModTab, {Name = "Auto-Kick on Mod", Default = false, Callback = function(v) autoKick = v end})

Players.PlayerAdded:Connect(function(plr)
    if not modDetect then return end
    task.wait(1)
    local rank = plr:GetRankInGroup(0)
    if rank >= 100 then
        ui:Notify({Title = "⚠️ MOD DETECTED", Content = plr.Name .. " (rank " .. rank .. ")", Duration = 10})
        if autoKick then LocalPlayer:Kick("Mod detected: " .. plr.Name) end
    end
end)

ui:MakeDivider(ModTab)
ui:MakeSection(ModTab, "🌐 Server Controls")
ui:MakeButton(ModTab, {Name = "Refresh Server List", Callback = function() ui:Notify({Title="Server", Content="Обновление..."}) end})
ui:MakeButton(ModTab, {Name = "Kick All (DEV only)", Callback = function() ui:Notify({Title="DEV", Content="Функция отключена"}) end})

-- ==================== 5. STREAMER ====================
local StreamerTab = ui:MakeTab("STREAMER")
ui:MakeSection(StreamerTab, "🎥 Streamer Mode")

ui:MakeToggle(StreamerTab, {
    Name = "Streamer Mode",
    Default = false,
    Callback = function(v)
        ui:Notify({Title = "Streamer", Content = v and "ON" or "OFF"})
    end,
})

ui:MakeDivider(StreamerTab)
ui:MakeSection(StreamerTab, "🎭 Fake Info")

ui:MakeTextbox(StreamerTab, {Name = "Fake Name", Default = "Player", Placeholder = "Введи имя", Callback = function(v) print("FakeName:", v) end})
ui:MakeTextbox(StreamerTab, {Name = "Fake XP", Default = "1000", Placeholder = "XP", Callback = function(v) print("FakeXP:", v) end})
ui:MakeTextbox(StreamerTab, {Name = "Fake Level", Default = "50", Placeholder = "Level", Callback = function(v) print("FakeLevel:", v) end})
ui:MakeTextbox(StreamerTab, {Name = "Fake Money", Default = "99999", Placeholder = "Money", Callback = function(v) print("FakeMoney:", v) end})

ui:MakeDivider(StreamerTab)
ui:MakeToggle(StreamerTab, {
    Name = "Hide KillFeed",
    Default = false,
    Callback = function(v)
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if gui then
            for _, obj in ipairs(gui:GetDescendants()) do
                if obj:IsA("GuiObject") and obj.Name:lower():find("killfeed") then
                    obj.Visible = not v
                end
            end
        end
    end,
})

-- ==================== 6. ONLINE ====================
local OnlineTab = ui:MakeTab("ONLINE")
ui:MakeSection(OnlineTab, "👥 Игроки онлайн")

local function refreshOnline()
    local list = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        table.insert(list, plr.Name .. (plr == LocalPlayer and " (you)" or ""))
    end
    return list
end

local onlineDropdown
onlineDropdown = ui:MakeDropdown(OnlineTab, {
    Name = "Players",
    Options = refreshOnline(),
    Default = "Все игроки",
    Callback = function(v) end,
})

ui:MakeButton(OnlineTab, {
    Name = "🔄 Refresh List",
    Subtext = "Обновить список игроков",
    Callback = function()
        if onlineDropdown and onlineDropdown.RefreshOptions then
            onlineDropdown:RefreshOptions(refreshOnline())
        end
        ui:Notify({Title="Online", Content="Список обновлён ("..#Players:GetPlayers()..")"})
    end,
})

ui:MakeLabel(OnlineTab, "Всего онлайн: " .. #Players:GetPlayers())

-- ==================== 7. ANNOUNCE ====================
local AnnounceTab = ui:MakeTab("ANNOUNCE")
ui:MakeSection(AnnounceTab, "📢 Объявления (DEV only)")

local announceText = ""
ui:MakeTextbox(AnnounceTab, {
    Name = "Announcement Text",
    Default = "",
    Placeholder = "Введи текст объявления...",
    Callback = function(v) announceText = v end,
})

ui:MakeButton(AnnounceTab, {
    Name = "📤 Send Announcement",
    Subtext = "Отправить объявление на сервер",
    Callback = function()
        if announceText == "" then
            ui:Notify({Title="Announce", Content="Текст пуст"})
            return
        end
        ui:Notify({Title="Announce", Content="Отправлено: " .. announceText})
    end,
})

ui:MakeButton(AnnounceTab, {
    Name = "🧪 Test Announcement",
    Subtext = "Проверить работу объявлений",
    Callback = function()
        ui:Notify({Title="TEST", Content="Это тестовое объявление", Duration = 5})
    end,
})

-- ==================== 8. SETTINGS ====================
local SettingsTab = ui:MakeTab("SETTINGS")
ui:MakeSection(SettingsTab, "⚙️ Настройки GUI")

ui:MakeDropdown(SettingsTab, {
    Name = "Theme",
    Options = {"Dark", "Purple", "Red", "White"},
    Default = Config.Theme,
    Callback = function(v)
        ui:SetTheme(v)
        ui:Notify({Title="Theme", Content="Тема: " .. v})
    end,
})

ui:MakeKeybind(SettingsTab, {
    Name = "Toggle GUI Keybind",
    Default = Config.Keybind,
    Callback = function(key)
        Config.Keybind = key
        ui.ToggleKey = Enum.KeyCode[key] or Enum.KeyCode.K
        SaveConfig()
    end,
})

ui:MakeSlider(SettingsTab, {
    Name = "Window Width",
    Min = 400, Max = 1000, Default = Config.Size[1], Step = 10, Suffix = " px",
    Callback = function(v)
        Config.Size[1] = v
        ui.MainFrame.Size = UDim2.new(0, v, 0, ui.MainFrame.Size.Y.Offset)
        SaveConfig()
    end,
})

ui:MakeSlider(SettingsTab, {
    Name = "Window Height",
    Min = 300, Max = 800, Default = Config.Size[2], Step = 10, Suffix = " px",
    Callback = function(v)
        Config.Size[2] = v
        ui.MainFrame.Size = UDim2.new(0, ui.MainFrame.Size.X.Offset, 0, v)
        SaveConfig()
    end,
})

ui:MakeSlider(SettingsTab, {
    Name = "GUI Opacity",
    Min = 0.3, Max = 1, Default = Config.Opacity, Step = 0.05,
    Callback = function(v)
        Config.Opacity = v
        ui.MainFrame.BackgroundTransparency = 1 - v
        SaveConfig()
    end,
})

ui:MakeToggle(SettingsTab, {
    Name = "Blur Background",
    Default = Config.Blur,
    Callback = function(v)
        Config.Blur = v
        SaveConfig()
    end,
})

ui:MakeToggle(SettingsTab, {
    Name = "Auto-Save Config",
    Default = Config.AutoSave,
    Callback = function(v)
        Config.AutoSave = v
        SaveConfig()
    end,
})

ui:MakeDivider(SettingsTab)
ui:MakeSection(SettingsTab, "🔄 Сброс")

ui:MakeButton(SettingsTab, {
    Name = "Reset GUI",
    Subtext = "Сбросить все настройки",
    Callback = function()
        Config = {
            Theme = "Dark", Keybind = "K", Size = {600, 420}, Position = {0.5, 0.5},
            Opacity = 1, Blur = true, AutoSave = true,
            TabOrder = {"MAIN", "ESP", "MISC", "MOD DETECTOR", "STREAMER", "ONLINE", "ANNOUNCE"},
        }
        SaveConfig()
        ui:Notify({Title="Reset", Content="Настройки сброшены. Перезагрузи скрипт."})
    end,
})

-- ==================== NOTIFY ON LOAD ====================
ui:Notify({
    Title = "VENTURE AOT",
    Content = "Загружено успешно! Keybind: " .. Config.Keybind,
    Duration = 5,
})

print("✅ VENTURE AOT GUI загружен успешно")
print("   Тема:", Config.Theme, "| Keybind:", Config.Keybind)
print("   Вкладок:", #ui.Tabs)

return ui
