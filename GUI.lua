-- Venture AOT v2.0 | GUI
-- by __TheDark | discord.gg/UHCwX78Npc

local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local F = _G.Venture and _G.Venture.F
if not F then
    warn("[Venture GUI] Functions not loaded!")
    return
end

-- ═══════════════════════════════════════════
-- LOAD LINUI
-- ═══════════════════════════════════════════
local LINUI_URL = "https://reallinen.github.io/Files/Scripts/Linui.lua"

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

local code = httpGet(LINUI_URL)
if not code or #code < 100 then
    warn("[Venture GUI] Failed to load LinUI (size: " .. (code and #code or 0) .. ")")
    return
end

local fn, err = loadstring(code, "@LinUI")
if not fn then
    warn("[Venture GUI] Syntax error in LinUI: " .. tostring(err))
    return
end

local ok, Library = pcall(fn)
if not ok or not Library then
    warn("[Venture GUI] Runtime error in LinUI: " .. tostring(Library))
    return
end

-- ═══════════════════════════════════════════
-- MAIN SECTIONS
-- ═══════════════════════════════════════════

-- ─── TITAN CONTROL ───
local TitanSection = Library:Section("Titan Control")

TitanSection:Toggle({
    Text = "Titan ESP",
    Value = F.Settings.ESP,
    Callback = function(v) F.Settings.ESP = v end,
})

TitanSection:Toggle({
    Text = "Player ESP",
    Value = F.Settings.PlayerESP,
    Callback = function(v) F.Settings.PlayerESP = v end,
})

TitanSection:Toggle({
    Text = "Shifter ESP",
    Value = F.Settings.ShifterESP,
    Callback = function(v) F.Settings.ShifterESP = v end,
})

-- ─── HITBOX ───
local HitboxSection = Library:Section("Hitbox Expander")

HitboxSection:Toggle({
    Text = "Enable Hitbox",
    Value = F.Settings.HitboxExpand,
    Callback = function(v)
        F.Settings.HitboxExpand = v
        if v then F.ApplyHitboxToAll() else F.ResetAllHitboxes() end
    end,
})

HitboxSection:Slider({
    Text = "Size X",
    Min = 50, Max = 500, Value = F.Settings.HitboxSize.X,
    Callback = function(v)
        F.Settings.HitboxSize = Vector3.new(v, F.Settings.HitboxSize.Y, F.Settings.HitboxSize.Z)
        F.ApplyHitboxToAll()
    end,
})

HitboxSection:Slider({
    Text = "Size Y",
    Min = 50, Max = 500, Value = F.Settings.HitboxSize.Y,
    Callback = function(v)
        F.Settings.HitboxSize = Vector3.new(F.Settings.HitboxSize.X, v, F.Settings.HitboxSize.Z)
        F.ApplyHitboxToAll()
    end,
})

HitboxSection:Slider({
    Text = "Size Z",
    Min = 50, Max = 500, Value = F.Settings.HitboxSize.Z,
    Callback = function(v)
        F.Settings.HitboxSize = Vector3.new(F.Settings.HitboxSize.X, F.Settings.HitboxSize.Y, v)
        F.ApplyHitboxToAll()
    end,
})

HitboxSection:Toggle({
    Text = "Show Visual",
    Value = F.Settings.HitboxShowVisual,
    Callback = function(v)
        F.Settings.HitboxShowVisual = v
        if v then
            F.ApplyHitboxToAll()
        else
            for part, visual in pairs(F.State.hitboxVisuals) do
                if visual and visual.Parent then visual:Destroy() end
            end
            F.State.hitboxVisuals = {}
        end
    end,
})

HitboxSection:Button({
    Text = "Reset Hitboxes",
    Callback = function() F.ResetAllHitboxes() end,
})

-- ─── MOVEMENT ───
local MoveSection = Library:Section("Movement")

MoveSection:Toggle({
    Text = "Noclip",
    Value = F.Settings.Noclip,
    Callback = function(v)
        F.Settings.Noclip = v
        if v then F.StartNoclip() else F.StopNoclip() end
    end,
})

MoveSection:Toggle({
    Text = "FPS Booster",
    Value = F.Settings.FPSBoosterEnabled,
    Callback = function(v)
        F.Settings.FPSBoosterEnabled = v
        if v then F.EnableFPSBooster() else F.DisableFPSBooster() end
    end,
})

-- ─── AUTO FARM ───
local AutoSection = Library:Section("AutoFarm")

AutoSection:Toggle({
    Text = "Enable AutoFarm",
    Value = F.Settings.AutoFarmEnabled,
    Callback = function(v)
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
    end,
})

AutoSection:Slider({
    Text = "Orbit Speed",
    Min = 100, Max = 500, Value = F.Settings.AutoFarmOrbitSpeed,
    Callback = function(v) F.Settings.AutoFarmOrbitSpeed = v end,
})

AutoSection:Slider({
    Text = "Hover Height",
    Min = 30, Max = 150, Value = F.Settings.AutoFarmHoverHeight,
    Callback = function(v) F.Settings.AutoFarmHoverHeight = v end,
})

AutoSection:Slider({
    Text = "Orbit Radius",
    Min = 30, Max = 150, Value = F.Settings.AutoFarmOrbitRadius,
    Callback = function(v) F.Settings.AutoFarmOrbitRadius = v end,
})

AutoSection:Slider({
    Text = "Safe Distance",
    Min = 50, Max = 200, Value = F.Settings.AutoFarmSafeDistance,
    Callback = function(v) F.Settings.AutoFarmSafeDistance = v end,
})

AutoSection:Slider({
    Text = "Responsiveness",
    Min = 5, Max = 100, Value = F.Settings.AutoFarmResponsiveness,
    Callback = function(v) F.Settings.AutoFarmResponsiveness = v end,
})

-- ─── AUTO HEAL ───
local HealSection = Library:Section("Auto Heal")

HealSection:Toggle({
    Text = "Enable Auto Heal",
    Value = F.Settings.AutoHealEnabled,
    Callback = function(v) F.Settings.AutoHealEnabled = v end,
})

HealSection:Slider({
    Text = "HP Threshold %",
    Min = 10, Max = 100, Value = F.Settings.AutoHealThreshold,
    Callback = function(v) F.Settings.AutoHealThreshold = v end,
})

HealSection:Button({
    Text = "Heal Now",
    Callback = function() F.TriggerAutoHeal() end,
})

-- ─── STREAMER MODE ───
local StreamerSection = Library:Section("Streamer Mode")

StreamerSection:Toggle({
    Text = "Enable Streamer Mode",
    Value = F.Settings.StreamerEnabled,
    Callback = function(v)
        if v then F.StreamerEnable() else F.StreamerDisable() end
    end,
})

StreamerSection:Textbox({
    Text = "Fake Name",
    Placeholder = "Enter fake name...",
    Value = F.Settings.StreamerFakeName,
    Callback = function(text)
        F.Settings.StreamerFakeName = text
        if F.Settings.StreamerEnabled then F.StreamerApplyName() end
    end,
})

StreamerSection:Textbox({
    Text = "Fake XP",
    Placeholder = "1000000",
    Value = tostring(F.Settings.StreamerFakeXP),
    Callback = function(text)
        F.Settings.StreamerFakeXP = tonumber(text) or 1000000
    end,
})

StreamerSection:Textbox({
    Text = "Fake Level",
    Placeholder = "1000",
    Value = tostring(F.Settings.StreamerFakeLevel),
    Callback = function(text)
        F.Settings.StreamerFakeLevel = tonumber(text) or 1000
    end,
})

StreamerSection:Textbox({
    Text = "Fake Money",
    Placeholder = "1000000",
    Value = tostring(F.Settings.StreamerFakeMoney),
    Callback = function(text)
        F.Settings.StreamerFakeMoney = tonumber(text) or 1000000
    end,
})

StreamerSection:Toggle({
    Text = "Hide Kill Feed",
    Value = F.Settings.StreamerHideKillFeed,
    Callback = function(v) F.Settings.StreamerHideKillFeed = v end,
})

-- ─── ANTI-AFK ───
local AFKSection = Library:Section("Anti-AFK")

AFKSection:Toggle({
    Text = "Enable Anti-AFK",
    Value = F.Settings.AntiAFKEnabled,
    Callback = function(v)
        if v then F.AntiAFKEnable() else F.AntiAFKDisable() end
    end,
})

AFKSection:Dropdown({
    Text = "Mode",
    Data = {"Jump", "Move", "Both"},
    Callback = function(v) F.Settings.AntiAFKMode = v end,
})

AFKSection:Slider({
    Text = "Interval (sec)",
    Min = 5, Max = 60, Value = F.Settings.AntiAFKInterval,
    Callback = function(v) F.Settings.AntiAFKInterval = v end,
})

-- ─── ANNOUNCE (DEV only) ───
local AnnounceSection = Library:Section("Announce (DEV)")

if LocalPlayer.Name == F.Settings.OwnerName then
    AnnounceSection:Button({
        Text = "Send Announcement",
        Callback = function()
            -- Простой prompt через TextBox — используем фиксированные поля
            local title = "Venture Update"
            local text = "New features available!"
            F.SendAnnouncement(title, text)
        end,
    })
    AnnounceSection:Textbox({
        Text = "Title",
        Placeholder = "Announcement title",
        Value = "",
        Callback = function(v) F._AnnounceTitle = v end,
    })
    AnnounceSection:Textbox({
        Text = "Message",
        Placeholder = "Message text",
        Value = "",
        Callback = function(v) F._AnnounceText = v end,
    })
    AnnounceSection:Button({
        Text = "Send Custom",
        Callback = function()
            if F._AnnounceTitle and F._AnnounceText then
                F.SendAnnouncement(F._AnnounceTitle, F._AnnounceText)
            end
        end,
    })
    AnnounceSection:Button({
        Text = "Test Banner",
        Callback = function()
            F.SendAnnouncement("Test", "This is a test announcement")
        end,
    })
else
    AnnounceSection:Label({Text = "Only SCRIPT DEV can announce"})
end

-- ─── ONLINE (DEV only) ───
local OnlineSection = Library:Section("Online Users (DEV)")

if LocalPlayer.Name == F.Settings.OwnerName then
    OnlineSection:Button({
        Text = "Refresh List",
        Callback = function()
            local users = F.FetchOnlineUsers()
            print("=== Online Users ===")
            for _, u in ipairs(users) do
                print("  " .. u.name .. " | " .. (u.role or "User") .. " | " .. u.job_id)
            end
        end,
    })
else
    OnlineSection:Label({Text = "Only SCRIPT DEV can view"})
end

-- ─── SECURITY ───
local SecuritySection = Library:Section("Security")

SecuritySection:Toggle({
    Text = "Auto-Kick on Mod",
    Value = F.Settings.AutoKickOnMod,
    Callback = function(v)
        F.Settings.AutoKickOnMod = v
        if writefile then
            pcall(function()
                writefile("VentureSecurity.json", HttpService:JSONEncode({AutoKick = v}))
            end)
        end
    end,
})

SecuritySection:Button({
    Text = "Rejoin Same Server",
    Callback = function() F.RejoinServer() end,
})

SecuritySection:Button({
    Text = "Join New Server",
    Callback = function() F.JoinNewServer() end,
})

SecuritySection:Button({
    Text = "Copy Server ID",
    Callback = function() F.CopyServerId() end,
})

-- ─── MISC ───
local MiscSection = Library:Section("Misc")

MiscSection:Button({
    Text = "Copy Discord Link",
    Callback = function() F.CopyDiscord() end,
})

MiscSection:Label({
    Text = "by __TheDark | v2.0",
})

-- ═══════════════════════════════════════════
-- DONE
-- ═══════════════════════════════════════════
print("[Venture GUI] Loaded successfully")
F.Notify("Venture AOT", "Interface loaded!", 3)

_G.Venture = _G.Venture or {}
_G.Venture.Library = Library

return Library
