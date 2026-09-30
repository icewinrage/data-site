-- Venture AOT v2.0 | Main
-- by __TheDark | discord.gg/UHCwX78Npc

local REPO_USER = "icewinrage"
local REPO_NAME = "data-site"
local REPO_BRANCH = "main"
local PLACE_ID = 129554597954928

local BASE_URL = string.format(
    "https://cdn.jsdelivr.net/gh/%s/%s@%s/",
    REPO_USER, REPO_NAME, REPO_BRANCH
)

-- ═══════════════════════════════════════════
-- PLACE CHECK
-- ═══════════════════════════════════════════
if game.PlaceId ~= PLACE_ID then
    warn("[Venture] Wrong place. This script only works in Venture AOT.")
    return
end

-- ═══════════════════════════════════════════
-- EXECUTOR CHECK
-- ═══════════════════════════════════════════
local ExecutorChecks = {
    hasHttpGet = (game.HttpGet ~= nil),
    hasLoadstring = (loadstring ~= nil or load ~= nil),
    hasRequest = (request ~= nil or http_request ~= nil or (syn and syn.request ~= nil)),
    hasClipboard = (setclipboard ~= nil or toclipboard ~= nil),
    hasFileIO = (writefile ~= nil and readfile ~= nil and isfile ~= nil),
}

local function GetExecutorName()
    if syn and syn.request then return "Synapse"
    elseif fluxus then return "Fluxus"
    elseif krnl then return "Krnl"
    elseif is_sirhurt_closure then return "SirHurt"
    elseif secure_load then return "Sentinel"
    elseif Xeno then return "Xeno"
    elseif getexecutorname then
        local ok, n = pcall(getexecutorname)
        if ok and n then return n end
    elseif identifyexecutor then
        local ok, n = pcall(identifyexecutor)
        if ok and n then return n end
    end
    return "Unknown"
end

local EXECUTOR = GetExecutorName()

if not ExecutorChecks.hasLoadstring then
    warn("[Venture] Executor doesn't support loadstring. Aborting.")
    return
end

if not ExecutorChecks.hasHttpGet and not ExecutorChecks.hasRequest then
    warn("[Venture] Executor doesn't support HTTP. Aborting.")
    return
end

-- ═══════════════════════════════════════════
-- ANTI RE-INJECT
-- ═══════════════════════════════════════════
local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local existingMain = PlayerGui:FindFirstChild("VentureLoadingGui")

if existingMain then
    -- Уже запущено — уведомление и выход
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Venture AOT",
            Text = "Script is already running!",
            Duration = 4,
        })
    end)
    return
end

-- ═══════════════════════════════════════════
-- LOADING NOTIFICATION
-- ═══════════════════════════════════════════
local LoadingGui = Instance.new("ScreenGui")
LoadingGui.Name = "VentureLoadingGui"
LoadingGui.ResetOnSpawn = false
LoadingGui.IgnoreGuiInset = true
LoadingGui.DisplayOrder = 2147483647
LoadingGui.Parent = PlayerGui

local loadingFrame = Instance.new("Frame")
loadingFrame.Size = UDim2.fromOffset(360, 70)
loadingFrame.Position = UDim2.new(0.5, -180, 0, -100)
loadingFrame.BackgroundColor3 = Color3.fromRGB(15, 8, 30)
loadingFrame.BackgroundTransparency = 0.05
loadingFrame.BorderSizePixel = 0
loadingFrame.Parent = LoadingGui
Instance.new("UICorner", loadingFrame).CornerRadius = UDim.new(0, 12)

local loadingStroke = Instance.new("UIStroke")
loadingStroke.Color = Color3.fromRGB(125, 92, 255)
loadingStroke.Thickness = 2
loadingStroke.Transparency = 0.2
loadingStroke.Parent = loadingFrame

local loadingTitle = Instance.new("TextLabel")
loadingTitle.Position = UDim2.new(0, 20, 0, 12)
loadingTitle.Size = UDim2.new(1, -40, 0, 22)
loadingTitle.BackgroundTransparency = 1
loadingTitle.Text = "Loading Script..."
loadingTitle.TextColor3 = Color3.fromRGB(220, 200, 255)
loadingTitle.TextSize = 18
loadingTitle.Font = Enum.Font.GothamBold
loadingTitle.TextXAlignment = Enum.TextXAlignment.Left
loadingTitle.Parent = loadingFrame

local loadingSub = Instance.new("TextLabel")
loadingSub.Position = UDim2.new(0, 20, 0, 36)
loadingSub.Size = UDim2.new(1, -40, 0, 18)
loadingSub.BackgroundTransparency = 1
loadingSub.Text = "by __TheDark  |  " .. EXECUTOR
loadingSub.TextColor3 = Color3.fromRGB(153, 157, 178)
loadingSub.TextSize = 11
loadingSub.Font = Enum.Font.Gotham
loadingSub.TextXAlignment = Enum.TextXAlignment.Left
loadingSub.Parent = loadingFrame

local TS = game:GetService("TweenService")
TS:Create(loadingFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back), {
    Position = UDim2.new(0.5, -180, 0, 20)
}):Play()

-- ═══════════════════════════════════════════
-- HTTP
-- ═══════════════════════════════════════════
local function httpGet(url)
    if syn and syn.request then
        local ok, res = pcall(syn.request, {Url = url, Method = "GET"})
        if ok and res and res.Body then return res.Body end
    end
    if request then
        local ok, res = pcall(request, {Url = url, Method = "GET"})
        if ok and res and res.Body then return res.Body end
    end
    if http_request then
        local ok, res = pcall(http_request, {Url = url, Method = "GET"})
        if ok and res and res.Body then return res.Body end
    end
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok then return res end
    return nil
end

-- ═══════════════════════════════════════════
-- LOAD MODULES
-- ═══════════════════════════════════════════
local START_TIME = tick()

_G.Venture = _G.Venture or {}
_G.Venture.ExecutorName = EXECUTOR
_G.Venture.PlaceId = PLACE_ID

local function LoadModule(name)
    local url = BASE_URL .. name .. ".lua"
    local code = httpGet(url)
    if not code or #code < 100 then
        warn("[Venture] Failed to load " .. name .. " (size: " .. (code and #code or 0) .. ")")
        return false
    end
    local fn, err = loadstring(code, "@" .. name)
    if not fn then
        warn("[Venture] Syntax error in " .. name .. ": " .. tostring(err))
        return false
    end
    local ok, result = pcall(fn)
    if not ok then
        warn("[Venture] Runtime error in " .. name .. ": " .. tostring(result))
        return false
    end
    print("[Venture] Loaded: " .. name)
    return true
end

LoadModule("Functions")
LoadModule("GUI")

local LOAD_TIME = string.format("%.2f", tick() - START_TIME)

-- ═══════════════════════════════════════════
-- SUCCESS NOTIFICATION
-- ═══════════════════════════════════════════
loadingTitle.Text = "Successfully Loaded!"
loadingTitle.TextColor3 = Color3.fromRGB(180, 255, 180)
loadingSub.Text = "Loaded in " .. LOAD_TIME .. "s  |  Thanks for using!"
loadingStroke.Color = Color3.fromRGB(80, 220, 120)

task.wait(4)

TS:Create(loadingFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
    Position = UDim2.new(0.5, -180, 0, -100),
    BackgroundTransparency = 1
}):Play()
TS:Create(loadingStroke, TweenInfo.new(0.4), {Transparency = 1}):Play()
TS:Create(loadingTitle, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
TS:Create(loadingSub, TweenInfo.new(0.4), {TextTransparency = 1}):Play()

task.wait(0.5)
LoadingGui:Destroy()

-- ═══════════════════════════════════════════
-- TELEPORT RE-EXEC
-- ═══════════════════════════════════════════
local AUTO_EXEC = [[
    wait(0.5)
    loadstring(game:HttpGet("https://cdn.jsdelivr.net/gh/]] .. REPO_USER .. [[/]] .. REPO_NAME .. [[@]] .. REPO_BRANCH .. [[/Main.lua"))()
]]

local function RegisterQueue()
    if syn and syn.queue_on_teleport then
        pcall(function() syn.queue_on_teleport(AUTO_EXEC) end)
    end
    if fluxus and fluxus.queue_on_teleport then
        pcall(function() fluxus.queue_on_teleport(AUTO_EXEC) end)
    end
    if queue_on_teleport then
        pcall(function() queue_on_teleport(AUTO_EXEC) end)
    end
end

RegisterQueue()

task.spawn(function()
    while true do
        task.wait(30)
        pcall(RegisterQueue)
    end
end)

print("[Venture AOT v2.0] Loaded in " .. LOAD_TIME .. "s | Executor: " .. EXECUTOR)
