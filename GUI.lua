-- Venture AOT v2.0 | GUI (MoonLIB)
-- by __TheDark | discord.gg/UHCwX78Npc

local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local F = _G.Venture and _G.Venture.F
if not F then
    warn("[Venture GUI] Functions not loaded!")
    return
end

-- ═══════════════════════════════════════════
-- LOAD MOONLIB
-- ═══════════════════════════════════════════
local MOONLIB_URL = "https://raw.githubusercontent.com/jakepscripts/moonlib/main/moonlibv2.lua"

local function httpGet(url)
    if syn and syn.request then
        local ok, res = pcall(syn.request, {Url=url, Method="GET"})
        if ok and res and res.Body then return res.Body end
    end
    if request then
        local ok, res = pcall(request, {Url=url, Method="GET"})
        if ok and res and res.Body then return res.Body end
    end
    if http_request then
        local ok, res = pcall(http_request, {Url=url, Method="GET"})
        if ok and res and res.Body then return res.Body end
    end
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok then return res end
    return nil
end

local code = httpGet(MOONLIB_URL)
if not code or #code < 100 then
    warn("[Venture GUI] Failed to load MoonLIB (size: " .. (code and #code or 0) .. ")")
    return
end

local fn, err = loadstring(code, "@MoonLIB")
if not fn then
    warn("[Venture GUI] Syntax error in MoonLIB: " .. tostring(err))
    return
end

local ok, Library = pcall(fn)
if not ok or not Library then
    warn("[Venture GUI] Runtime error in MoonLIB: " .. tostring(Library))
    return
end

-- ═══════════════════════════════════════════
-- CREATE WINDOW
-- ═══════════════════════════════════════════
local main = Library:CreateWindow(
    "Venture AOT",
    "#7b5cff",
    9160626035
)

-- ═══════════════════════════════════════════
-- TAB: MAIN
-- ═══════════════════════════════════════════
main:CreateTab("Main")

main:CreateSection("Main", "Titan Control")

main:CreateToggle("Main", "Titan ESP", F.Settings.ESP, function(v)
    F.Settings.ESP = v
end)

main:CreateToggle("Main", "Player ESP", F.Settings.PlayerESP, function(v)
    F.Settings.PlayerESP = v
end)

main:CreateToggle("Main", "Shifter ESP", F.Settings.ShifterESP, function(v)
    F.Settings.ShifterESP = v
end)

-- ═══════════════════════════════════════════
-- TAB: HITBOX
-- ═══════════════════════════════════════════
main:CreateTab("Hitbox")

main:CreateToggle("Hitbox", "Enable Hitbox", F.Settings.HitboxExpand, function(v)
    F.Settings.HitboxExpand = v
    if v then F.ApplyHitboxToAll() else F.ResetAllHitboxes() end
end)

main:CreateSlider("Hitbox", "Size X", false, 50, 500, F.Settings.HitboxSize.X, function(v)
    F.Settings.HitboxSize = Vector3.new(v, F.Settings.HitboxSize.Y, F.Settings.HitboxSize.Z)
    F.ApplyHitboxToAll()
end)

main:CreateSlider("Hitbox", "Size Y", false, 50, 500, F.Settings.HitboxSize.Y, function(v)
    F.Settings.HitboxSize = Vector3.new(F.Settings.HitboxSize.X, v, F.Settings.HitboxSize.Z)
    F.ApplyHitboxToAll()
end)

main:CreateSlider("Hitbox", "Size Z", false, 50, 500, F.Settings.HitboxSize.Z, function(v)
    F.Settings.HitboxSize = Vector3.new(F.Settings.HitboxSize.X, F.Settings.HitboxSize.Y, v)
    F.ApplyHitboxToAll()
end)

main:CreateToggle("Hitbox", "Show Visual", F.Settings.HitboxShowVisual, function(v)
    F.Settings.HitboxShowVisual = v
    if v then
        F.ApplyHitboxToAll()
    else
        for part, visual in pairs(F.State.hitboxVisuals) do
            if visual and visual.Parent then visual:Destroy() end
        end
        F.State.hitboxVisuals = {}
    end
end)

main:CreateButton("Hitbox", "Reset Hitboxes", "Restore original sizes", function()
    F.ResetAllHitboxes()
end)

-- ═══════════════════════════════════════════
-- TAB: MOVEMENT
-- ═══════════════════════════════════════════
main:CreateTab("Movement")

main:CreateToggle("Movement", "Noclip", F.Settings.Noclip, function(v)
    F.Settings.Noclip = v
    if v then F.StartNoclip() else F.StopNoclip() end
end)

main:CreateToggle("Movement", "FPS Booster", F.Settings.FPSBoosterEnabled, function(v)
    F.Settings.FPSBoosterEnabled = v
    if v then F.EnableFPSBooster() else F.DisableFPSBooster() end
end)

-- ═══════════════════════════════════════════
-- TAB: AUTO
-- ═══════════════════════════════════════════
main:CreateTab("Auto")

main:CreateSection("Auto", "AutoFarm")

main:CreateToggle("Auto", "Enable AutoFarm", F.Settings.AutoFarmEnabled, function(v)
    F.Settings.AutoFarmEnabled = v
    if v then
        if not F.Settings.HitboxExpand then
            F.Settings.HitboxExpand = true
            F.ApplyHitboxToAll()
        end
        if not F.Settings.Noclip then
            F.Settings.Noclip = true
            F.StartNoclip()
        end
    else
        F.ResetAllHitboxes()
        F.StopNoclip()
        F.CleanupFarm()
    end
end)

main:CreateSlider("Auto", "Orbit Speed", false, 100, 500, F.Settings.AutoFarmOrbitSpeed, function(v)
    F.Settings.AutoFarmOrbitSpeed = v
end)

main:CreateSlider("Auto", "Hover Height", false, 30, 150, F.Settings.AutoFarmHoverHeight, function(v)
    F.Settings.AutoFarmHoverHeight = v
end)

main:CreateSlider("Auto", "Orbit Radius", false, 30, 150, F.Settings.AutoFarmOrbitRadius, function(v)
    F.Settings.AutoFarmOrbitRadius = v
end)

main:CreateSlider("Auto", "Safe Distance", false, 50, 200, F.Settings.AutoFarmSafeDistance, function(v)
    F.Settings.AutoFarmSafeDistance = v
end)

main:CreateSlider("Auto", "Responsiveness", false, 5, 100, F.Settings.AutoFarmResponsiveness, function(v)
    F.Settings.AutoFarmResponsiveness = v
end)

main:CreateSection("Auto", "Auto Heal")

main:CreateToggle("Auto", "Enable Auto Heal", F.Settings.AutoHealEnabled, function(v)
    F.Settings.AutoHealEnabled = v
end)

main:CreateSlider("Auto", "HP Threshold %", false, 10, 100, F.Settings.AutoHealThreshold, function(v)
    F.Settings.AutoHealThreshold = v
end)

main:CreateButton("Auto", "Heal Now", "Manual trigger", function()
    F.TriggerAutoHeal()
end)

-- ═══════════════════════════════════════════
-- TAB: STREAMER
-- ═══════════════════════════════════════════
main:CreateTab("Streamer")

main:CreateToggle("Streamer", "Enable Streamer Mode", F.Settings.StreamerEnabled, function(v)
    if v then F.StreamerEnable() else F.StreamerDisable() end
end)

main:CreateTextbox("Streamer", "Fake Name", "Enter fake name...", function(text)
    F.Settings.StreamerFakeName = text
    if F.Settings.StreamerEnabled then F.StreamerApplyName() end
end)

main:CreateTextbox("Streamer", "Fake XP", "1000000", function(text)
    F.Settings.StreamerFakeXP = tonumber(text) or 1000000
end)

main:CreateTextbox("Streamer", "Fake Level", "1000", function(text)
    F.Settings.StreamerFakeLevel = tonumber(text) or 1000
end)

main:CreateTextbox("Streamer", "Fake Money", "1000000", function(text)
    F.Settings.StreamerFakeMoney = tonumber(text) or 1000000
end)

main:CreateToggle("Streamer", "Hide Kill Feed", F.Settings.StreamerHideKillFeed, function(v)
    F.Settings.StreamerHideKillFeed = v
end)

-- ═══════════════════════════════════════════
-- TAB: ANTI-AFK
-- ═══════════════════════════════════════════
main:CreateTab("Anti-AFK")

main:CreateToggle("Anti-AFK", "Enable Anti-AFK", F.Settings.AntiAFKEnabled, function(v)
    if v then F.AntiAFKEnable() else F.AntiAFKDisable() end
end)

main:CreateDropdown("Anti-AFK", "Mode", false, {"Jump", "Move", "Both"}, function(v)
    F.Settings.AntiAFKMode = v
end)

main:CreateSlider("Anti-AFK", "Interval (sec)", false, 5, 60, F.Settings.AntiAFKInterval, function(v)
    F.Settings.AntiAFKInterval = v
end)

-- ═══════════════════════════════════════════
-- TAB: SOCIAL (DEV only)
-- ═══════════════════════════════════════════
main:CreateTab("Social")

if LocalPlayer.Name == F.Settings.OwnerName then
    main:CreateSection("Social", "Announcements")

    local announceTitle = ""
    local announceText = ""

    main:CreateTextbox("Social", "Title", "Announcement title", function(v)
        announceTitle = v
    end)

    main:CreateTextbox("Social", "Message", "Message text", function(v)
        announceText = v
    end)

    main:CreateButton("Social", "Send Announcement", "Broadcast to all servers", function()
        if #announceTitle > 0 and #announceText > 0 then
            F.SendAnnouncement(announceTitle, announceText)
        else
            F.Notify("Announce", "Fill both fields", 3)
        end
    end)

    main:CreateButton("Social", "Test Banner", "Show test announcement", function()
        F.SendAnnouncement("Test", "This is a test announcement")
    end)

    main:CreateSection("Social", "Online Users")

    main:CreateButton("Social", "Refresh Online List", "Print to console", function()
        local users = F.FetchOnlineUsers()
        print("=== Online Users ===")
        for _, u in ipairs(users) do
            print("  " .. u.name .. " | " .. (u.role or "User") .. " | " .. u.job_id)
        end
    end)
else
    main:CreateSection("Social", "Info")
    main:CreateButton("Social", "Only DEV can access", "No permission", function() end)
end

-- ═══════════════════════════════════════════
-- TAB: SECURITY
-- ═══════════════════════════════════════════
main:CreateTab("Security")

main:CreateToggle("Security", "Auto-Kick on Mod", F.Settings.AutoKickOnMod, function(v)
    F.Settings.AutoKickOnMod = v
    if writefile then
        pcall(function()
            writefile("VentureSecurity.json", HttpService:JSONEncode({AutoKick = v}))
        end)
    end
end)

main:CreateSection("Security", "Server Controls")

main:CreateButton("Security", "Rejoin Same Server", "Teleport back", function()
    F.RejoinServer()
end)

main:CreateButton("Security", "Join New Server", "Find another", function()
    F.JoinNewServer()
end)

main:CreateButton("Security", "Copy Server ID", "To clipboard", function()
    F.CopyServerId()
end)

-- ═══════════════════════════════════════════
-- TAB: MISC
-- ═══════════════════════════════════════════
main:CreateTab("Misc")

main:CreateButton("Misc", "Copy Discord Link", "discord.gg/UHCwX78Npc", function()
    F.CopyDiscord()
end)

main:CreateSection("Misc", "Info")

main:CreateButton("Misc", "by __TheDark | v2.0", "Venture AOT", function() end)

-- ═══════════════════════════════════════════
-- DONE
-- ═══════════════════════════════════════════
print("[Venture GUI] Loaded successfully (MoonLIB)")
F.Notify("Venture AOT", "Interface loaded!", 3)

_G.Venture = _G.Venture or {}
_G.Venture.Library = Library

return Library
