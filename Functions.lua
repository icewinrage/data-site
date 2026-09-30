-- Venture AOT v2.0 | Functions
-- by __TheDark | discord.gg/UHCwX78Npc

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local F = {}
_G.Venture = _G.Venture or {}
_G.Venture.F = F

-- ═══════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════
F.Settings = {
    -- Hitbox
    HitboxExpand = false,
    HitboxSize = Vector3.new(300, 200, 300),
    HitboxShape = "Block",
    HitboxShowVisual = false,
    HitboxVisualColor = Color3.fromRGB(255, 100, 200),
    HitboxVisualTransparency = 0.6,
    HitboxParts = {Nape=true, Eyes=false, LeftArm=false, LeftLeg=false, RightArm=false, RightLeg=false},

    -- ESP
    ESP = false,
    PlayerESP = false,
    ShifterESP = false,
    ESPColor = Color3.fromRGB(255, 60, 60),
    NapeColor = Color3.fromRGB(80, 255, 120),
    TargetColor = Color3.fromRGB(255, 210, 60),

    -- Noclip
    Noclip = false,

    -- FPS Booster
    FPSBoosterEnabled = false,

    -- AutoFarm
    AutoFarmEnabled = false,
    AutoFarmOrbitSpeed = 220,
    AutoFarmHoverHeight = 70,
    AutoFarmOrbitRadius = 70,
    AutoFarmSafeDistance = 100,
    AutoFarmResponsiveness = 20,

    -- AutoHeal
    AutoHealEnabled = false,
    AutoHealThreshold = 80,

    -- Streamer
    StreamerEnabled = false,
    StreamerFakeName = "Streamer",
    StreamerFakeXP = 1000000,
    StreamerFakeLevel = 1000,
    StreamerFakeMoney = 1000000,
    StreamerHideKillFeed = true,
    _OriginalName = nil,
    _OriginalXP = nil,
    _OriginalLevel = nil,
    _OriginalMoney = nil,

    -- Anti-AFK
    AntiAFKEnabled = false,
    AntiAFKMode = "Both",
    AntiAFKInterval = 20,

    -- Security
    AutoKickOnMod = false,
    ModGroupId = 853580851,
    OwnerName = "eru_bleu",

    -- Supabase
    SupabaseUrl = "https://ilbxpnyeyhimlyxnmibx.supabase.co",
    SupabaseKey = "sb_publishable_5U3FsKotLEcidCucVDGVPw_LTDeNYEt",
    SupabaseTable = "venture_beacons",
    AnnounceTable = "venture_announcements",
}

F.State = {
    FarmState = {CurrentTitan=nil, LastKillTime=0, IsAttacking=false, OrbitAngle=0, AlignPos=nil, Attachments={}},
    HealerState = {IsHealing=false, SavedPosition=nil, LastHealTime=0},
    SecurityState = {ModsInServer={}, IsPaused=false},
    originalPartData = {},
    expandedParts = {},
    hitboxVisuals = {},
    noclipConnection = nil,
    fpsOriginalData = {},
    AntiAFKLastAction = 0,
    AntiAFKConnection = nil,
    AntiGrabConnection = nil,
    StreamerLoop = nil,
    SupabaseUsers = {},
    SupabaseBadges = {},
    SupabaseBadgeByPlayer = {},
    AnnounceLastSeenId = 0,
    AnnounceBanner = nil,
    MY_UID = nil,
    ESPObjects = {},
    RefillESP = {},
    PlayerESPObjects = {},
}

-- ═══════════════════════════════════════════
-- UTILS
-- ═══════════════════════════════════════════
function F.New(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end

function F.Tween(obj, time, props, style, dir)
    local info = TweenInfo.new(time or 0.25, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

function F.Notify(title, text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = dur or 5,
        })
    end)
end

function F.ISOTime(offset)
    offset = offset or 0
    return os.date("!%Y-%m-%dT%H:%M:%SZ", os.time() + offset)
end

function F.GetUserId()
    if F.State.MY_UID then return F.State.MY_UID end
    local uid
    if isfile and readfile and isfile("VentureUID.txt") then
        local ok, d = pcall(readfile, "VentureUID.txt")
        if ok and d and #d > 0 then uid = d end
    end
    if not uid then
        uid = tostring(math.random(100000, 999999)) .. "_" .. tostring(os.time())
        if writefile then pcall(writefile, "VentureUID.txt", uid) end
    end
    F.State.MY_UID = uid
    return uid
end

function F.HttpRequest(opts)
    if syn and syn.request then
        local ok, res = pcall(syn.request, opts)
        if ok and res then return res end
    end
    if request then
        local ok, res = pcall(request, opts)
        if ok and res then return res end
    end
    if http_request then
        local ok, res = pcall(http_request, opts)
        if ok and res then return res end
    end
    return nil
end

function F.HttpGet(url, headers)
    local res = F.HttpRequest({Url=url, Method="GET", Headers=headers or {}})
    if res and res.Body then return res.Body end
    return nil
end

function F.HttpPost(url, body, headers)
    local allHeaders = headers or {}
    allHeaders["Content-Type"] = "application/json"
    local res = F.HttpRequest({
        Url=url, Method="POST", Headers=allHeaders,
        Body=HttpService:JSONEncode(body)
    })
    if res then return res.Body end
    return nil
end

function F.HttpDelete(url, headers)
    local res = F.HttpRequest({Url=url, Method="DELETE", Headers=headers or {}})
    if res then return res.Body end
    return nil
end

-- ═══════════════════════════════════════════
-- TITANS / REFILLS
-- ═══════════════════════════════════════════
function F.GetTitans()
    local titans = {}
    local tf = Workspace:FindFirstChild("Titans")
    local af = tf and tf:FindFirstChild("Alive")
    if not af then return titans end
    local ch = LocalPlayer.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    for _, model in ipairs(af:GetChildren()) do
        if model:IsA("Model") then
            local hb = model:FindFirstChild("Hitboxes")
            if hb then
                local nape = hb:FindFirstChild("Nape")
                local head = hb:FindFirstChild("Head")
                local hum = model:FindFirstChildOfClass("Humanoid")
                if nape and nape:IsA("BasePart") then
                    local alive = true
                    if hum then alive = hum.Health > 0 else alive = model.Parent == af end
                    if model:GetAttribute("Dead") == true then alive = false end
                    if model:GetAttribute("HeadChopped") == true then alive = false end
                    if alive then
                        local dist = 9999
                        if root then dist = (root.Position - nape.Position).Magnitude end
                        table.insert(titans, {
                            Model = model, Nape = nape,
                            Head = (head and head:IsA("BasePart")) and head or nape,
                            Humanoid = hum, Distance = dist
                        })
                    end
                end
            end
        end
    end
    table.sort(titans, function(a, b) return a.Distance < b.Distance end)
    return titans
end

function F.GetRefills()
    local refills = {}
    local folder = Workspace:FindFirstChild("Refills")
    if not folder then return refills end
    local ch = LocalPlayer.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    for _, model in ipairs(folder:GetChildren()) do
        if model.Name:lower():find("blade") or model.Name:lower():find("refill") then
            local part = model.PrimaryPart
            if not part then
                for _, p in ipairs(model:GetDescendants()) do
                    if p:IsA("BasePart") then part = p; break end
                end
            end
            if part then
                local dist = 9999
                if root then dist = (root.Position - part.Position).Magnitude end
                table.insert(refills, {Model=model, Part=part, Distance=dist})
            end
        end
    end
    table.sort(refills, function(a, b) return a.Distance < b.Distance end)
    return refills
end

-- ═══════════════════════════════════════════
-- HITBOX
-- ═══════════════════════════════════════════
local function UpdateHitboxVisual(part)
    local S = F.State
    local visual = S.hitboxVisuals[part]
    if not visual and F.Settings.HitboxShowVisual then
        visual = Instance.new("SelectionBox")
        visual.Name = "VentureHitboxVisual"
        visual.Adornee = part
        visual.Color3 = F.Settings.HitboxVisualColor
        visual.LineThickness = 0.05
        visual.SurfaceTransparency = F.Settings.HitboxVisualTransparency
        visual.SurfaceColor3 = F.Settings.HitboxVisualColor
        visual.Parent = part
        S.hitboxVisuals[part] = visual
    end
    if visual then
        visual.Visible = F.Settings.HitboxShowVisual
        visual.Color3 = F.Settings.HitboxVisualColor
        visual.SurfaceColor3 = F.Settings.HitboxVisualColor
        visual.SurfaceTransparency = F.Settings.HitboxVisualTransparency
    end
end

local function ApplyHitboxToPart(part, partName)
    if not F.Settings.HitboxParts[partName] then return end
    if not part or not part.Parent or not part:IsA("BasePart") then return end
    local S = F.State
    if not S.originalPartData[part] then
        S.originalPartData[part] = {
            Size = part.Size, Shape = part.Shape,
            Transparency = part.Transparency, Color = part.Color,
            CanCollide = part.CanCollide, Massless = part.Massless,
            CanTouch = part.CanTouch, CanQuery = part.CanQuery
        }
    end
    pcall(function()
        part.Size = F.Settings.HitboxSize
        if F.Settings.HitboxShape == "Ball" then part.Shape = Enum.PartType.Ball
        elseif F.Settings.HitboxShape == "Cylinder" then part.Shape = Enum.PartType.Cylinder
        else part.Shape = Enum.PartType.Block end
        part.CanCollide = false
        part.Massless = true
        part.CanTouch = true
        part.CanQuery = true
    end)
    S.expandedParts[part] = true
    UpdateHitboxVisual(part)
end

function F.ApplyHitboxToAll()
    if not F.Settings.HitboxExpand then return end
    for _, t in ipairs(F.GetTitans()) do
        local hb = t.Model:FindFirstChild("Hitboxes")
        if hb then
            for partName, enabled in pairs(F.Settings.HitboxParts) do
                if enabled then
                    local p = hb:FindFirstChild(partName)
                    if p then ApplyHitboxToPart(p, partName) end
                end
            end
        end
    end
end

local function ResetHitboxPart(part)
    local S = F.State
    if not part or not S.originalPartData[part] then return end
    local orig = S.originalPartData[part]
    pcall(function()
        if part.Parent then
            part.Size = orig.Size; part.Shape = orig.Shape
            part.Transparency = orig.Transparency; part.Color = orig.Color
            part.CanCollide = orig.CanCollide; part.Massless = orig.Massless
            part.CanTouch = orig.CanTouch; part.CanQuery = orig.CanQuery
        end
    end)
    local visual = S.hitboxVisuals[part]
    if visual then visual:Destroy(); S.hitboxVisuals[part] = nil end
    S.expandedParts[part] = nil
end

function F.ResetAllHitboxes()
    local S = F.State
    for p, _ in pairs(S.expandedParts) do ResetHitboxPart(p) end
    S.expandedParts = {}
    for p, v in pairs(S.hitboxVisuals) do
        if v and v.Parent then v:Destroy() end
    end
    S.hitboxVisuals = {}
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if F.Settings.HitboxExpand then
            pcall(F.ApplyHitboxToAll)
        end
    end
end)

-- ═══════════════════════════════════════════
-- NOCLIP
-- ═══════════════════════════════════════════
function F.StartNoclip()
    if F.State.noclipConnection then return end
    F.State.noclipConnection = RunService.Stepped:Connect(function()
        if not F.Settings.Noclip then return end
        local ch = LocalPlayer.Character
        if not ch then return end
        for _, part in ipairs(ch:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end)
end

function F.StopNoclip()
    if F.State.noclipConnection then
        F.State.noclipConnection:Disconnect()
        F.State.noclipConnection = nil
    end
    local ch = LocalPlayer.Character
    if ch then
        for _, part in ipairs(ch:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.CanCollide = true end) end
        end
    end
end

-- ═══════════════════════════════════════════
-- FPS BOOSTER
-- ═══════════════════════════════════════════
function F.EnableFPSBooster()
    local S = F.State
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("PostEffect") or e:IsA("Atmosphere") then
            pcall(function() S.fpsOriginalData[e] = e.Enabled; e.Enabled = false end)
        end
    end
    S.fpsOriginalData.GlobalShadows = Lighting.GlobalShadows
    S.fpsOriginalData.ShadowSoftness = Lighting.ShadowSoftness
    Lighting.GlobalShadows = false
    Lighting.ShadowSoftness = 0
    for _, o in ipairs(Workspace:GetDescendants()) do
        if o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Fire") then
            pcall(function() S.fpsOriginalData[o] = o.Enabled; o.Enabled = false end)
        elseif o:IsA("Decal") or o:IsA("Texture") then
            pcall(function() S.fpsOriginalData[o] = o.Transparency; o.Transparency = 1 end)
        end
    end
    local Terrain = Workspace:FindFirstChildOfClass("Terrain")
    if Terrain then
        pcall(function()
            Terrain.Decoration = false
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 1
        end)
    end
end

function F.DisableFPSBooster()
    local S = F.State
    for obj, val in pairs(S.fpsOriginalData) do
        if typeof(obj) == "Instance" and obj.Parent then
            pcall(function()
                if obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("ParticleEmitter")
                   or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") then
                    obj.Enabled = val
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = val
                end
            end)
        end
    end
    if S.fpsOriginalData.GlobalShadows ~= nil then
        Lighting.GlobalShadows = S.fpsOriginalData.GlobalShadows
        Lighting.ShadowSoftness = S.fpsOriginalData.ShadowSoftness
    end
    S.fpsOriginalData = {}
end

-- ═══════════════════════════════════════════
-- PRESS E
-- ═══════════════════════════════════════════
function F.PressE()
    local ch = LocalPlayer.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if root then
        local nearest, nearDist = nil, 15
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local parent = obj.Parent
                local pos
                if parent and parent:IsA("BasePart") then pos = parent.Position
                elseif parent and parent:IsA("Attachment") and parent.Parent then pos = parent.WorldPosition end
                if pos then
                    local d = (root.Position - pos).Magnitude
                    if d < nearDist then nearDist = d; nearest = obj end
                end
            end
        end
        if nearest then
            pcall(function()
                nearest:InputHoldBegin()
                task.wait(0.1)
                nearest:InputHoldEnd()
            end)
            return
        end
    end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end)
end

-- ═══════════════════════════════════════════
-- AUTO HEAL
-- ═══════════════════════════════════════════
local function FindHealer()
    local map = Workspace:FindFirstChild("Map")
    if not map then return nil end
    return map:FindFirstChild("Healer")
end

function F.TriggerAutoHeal()
    local S = F.State
    if S.HealerState.IsHealing then return end
    local ch = LocalPlayer.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if not root then return end
    S.HealerState.SavedPosition = root.CFrame
    S.HealerState.IsHealing = true
    local healer = FindHealer()
    if not healer then S.HealerState.IsHealing = false; return end
    local hp = healer:GetPivot().Position
    root.CFrame = CFrame.new(hp + Vector3.new(0, 3, 0))
    root.Velocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.zero
    task.spawn(function()
        task.wait(0.6)
        for i = 1, 5 do F.PressE(); task.wait(0.3) end
        local start = tick()
        while tick() - start < 12 do
            task.wait(0.3)
            local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if h and h.Health >= h.MaxHealth then break end
        end
        task.wait(0.3)
        local r = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if r and S.HealerState.SavedPosition then
            r.CFrame = S.HealerState.SavedPosition
            r.Velocity = Vector3.zero
            r.AssemblyLinearVelocity = Vector3.zero
        end
        S.HealerState.IsHealing = false
        S.HealerState.SavedPosition = nil
        S.HealerState.LastHealTime = tick()
    end)
end

task.spawn(function()
    while true do
        task.wait(1)
        if F.Settings.AutoHealEnabled and not F.State.HealerState.IsHealing then
            if tick() - F.State.HealerState.LastHealTime < 5 then continue end
            local ch = LocalPlayer.Character
            local h = ch and ch:FindFirstChildOfClass("Humanoid")
            if h then
                local p = (h.Health / h.MaxHealth) * 100
                if p < F.Settings.AutoHealThreshold then F.TriggerAutoHeal() end
            end
        end
    end
end)

-- ═══════════════════════════════════════════
-- AUTO FARM
-- ═══════════════════════════════════════════
local function GetNearestTitanDist()
    local ch = LocalPlayer.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    if not root then return 9999, nil end
    local af = Workspace:FindFirstChild("Titans") and Workspace.Titans:FindFirstChild("Alive")
    if not af then return 9999, nil end
    local nd, nt = 9999, nil
    for _, m in ipairs(af:GetChildren()) do
        if m:IsA("Model") and m:GetAttribute("Dead") ~= true and m:GetAttribute("HeadChopped") ~= true then
            local d = (root.Position - m:GetPivot().Position).Magnitude
            if d < nd then nd = d; nt = m end
        end
    end
    return nd, nt
end

local function IsTitanDead(t)
    if not t or not t.Model or not t.Model.Parent or not t.Nape or not t.Nape.Parent then return true end
    if t.Humanoid and t.Humanoid.Health <= 0 then return true end
    if t.Model:GetAttribute("Dead") == true or t.Model:GetAttribute("HeadChopped") == true then return true end
    local af = Workspace:FindFirstChild("Titans") and Workspace.Titans:FindFirstChild("Alive")
    if af and t.Model.Parent ~= af then return true end
    return false
end

function F.CleanupFarm()
    local S = F.State
    if S.FarmState.AlignPos and S.FarmState.AlignPos.Parent then S.FarmState.AlignPos:Destroy() end
    S.FarmState.AlignPos = nil
    for _, a in ipairs(S.FarmState.Attachments) do if a and a.Parent then a:Destroy() end end
    S.FarmState.Attachments = {}
    S.FarmState.OrbitAngle = 0
end

local function HoverAroundTitan(titan)
    local S = F.State
    if S.FarmState.IsAttacking then return end
    S.FarmState.IsAttacking = true
    local ch = LocalPlayer.Character
    local root = ch and ch:FindFirstChild("HumanoidRootPart")
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not root or not hum or not titan.Nape.Parent then
        S.FarmState.IsAttacking = false
        return
    end
    hum.PlatformStand = true
    if F.Settings.Noclip then F.StartNoclip() end
    if F.Settings.HitboxExpand then F.ApplyHitboxToAll() end

    local rootAtt = Instance.new("Attachment")
    rootAtt.Name = "VentureAOT_RootAtt"
    rootAtt.Parent = root
    table.insert(S.FarmState.Attachments, rootAtt)

    local alignPos = Instance.new("AlignPosition")
    alignPos.Name = "VentureAOT_AlignPos"
    alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
    alignPos.Attachment0 = rootAtt
    alignPos.Position = root.Position
    alignPos.Responsiveness = F.Settings.AutoFarmResponsiveness
    alignPos.MaxForce = math.huge
    alignPos.MaxVelocity = math.huge
    alignPos.RigidityEnabled = false
    alignPos.ApplyAtCenterOfMass = false
    alignPos.Parent = root
    S.FarmState.AlignPos = alignPos

    local start = tick()
    task.spawn(function()
        while true do
            local dt = RunService.Heartbeat:Wait()
            if not F.Settings.AutoFarmEnabled then break end
            if S.SecurityState.IsPaused then break end
            if not root.Parent or not titan.Nape.Parent then break end
            if S.FarmState.CurrentTitan ~= titan then break end
            if IsTitanDead(titan) then break end
            if tick() - start > 30 then break end

            -- Плавное избегание других титанов
            local nd, nt = GetNearestTitanDist()
            if nd < F.Settings.AutoFarmSafeDistance and nt then
                local np = nt:GetPivot().Position
                local away = (root.Position - np).Unit
                local targetDist = F.Settings.AutoFarmSafeDistance + 10
                local safe = np + away * targetDist
                local target = Vector3.new(safe.X, safe.Y + F.Settings.AutoFarmHoverHeight, safe.Z)
                if alignPos then
                    alignPos.Position = target
                    alignPos.Responsiveness = 10
                end
                continue
            end

            -- Орбита вокруг текущего титана
            local center = titan.Nape.Position
            local angSpd = F.Settings.AutoFarmOrbitSpeed / F.Settings.AutoFarmOrbitRadius
            S.FarmState.OrbitAngle = S.FarmState.OrbitAngle + angSpd * dt
            local ox = math.cos(S.FarmState.OrbitAngle) * F.Settings.AutoFarmOrbitRadius
            local oz = math.sin(S.FarmState.OrbitAngle) * F.Settings.AutoFarmOrbitRadius
            local target = center + Vector3.new(ox, F.Settings.AutoFarmHoverHeight, oz)
            if alignPos then
                alignPos.Position = target
                alignPos.Responsiveness = F.Settings.AutoFarmResponsiveness
            end
        end
        F.CleanupFarm()
        task.wait(0.2)
        if hum then
            hum.PlatformStand = false
            hum.AutoRotate = true
        end
        S.FarmState.IsAttacking = false
    end)
end

task.spawn(function()
    while true do
        task.wait(0.1)
        local S = F.State
        if not F.Settings.AutoFarmEnabled then
            S.FarmState.IsAttacking = false
            S.FarmState.CurrentTitan = nil
            continue
        end
        if S.SecurityState.IsPaused then continue end
        if tick() - S.FarmState.LastKillTime < 0.5 then continue end
        if S.FarmState.CurrentTitan and IsTitanDead(S.FarmState.CurrentTitan) then
            S.FarmState.LastKillTime = tick()
            S.FarmState.CurrentTitan = nil
            S.FarmState.IsAttacking = false
            F.CleanupFarm()
            continue
        end
        if not S.FarmState.IsAttacking and not S.FarmState.CurrentTitan then
            local titans = F.GetTitans()
            if #titans > 0 then
                S.FarmState.CurrentTitan = titans[1]
                HoverAroundTitan(titans[1])
            end
        end
    end
end)

-- ═══════════════════════════════════════════
-- ANTI-GRAB
-- ═══════════════════════════════════════════
function F.StartAntiGrab()
    if F.State.AntiGrabConnection then return end
    F.State.AntiGrabConnection = RunService.Stepped:Connect(function()
        local ch = LocalPlayer.Character
        if not ch then return end
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        -- Проверка на grabbed (титан схватил)
        local grabbed = ch:GetAttribute("Grabbed")
        if grabbed then
            pcall(function()
                ch:SetAttribute("Grabbed", false)
            end)
        end

        -- PlatformStand — титан может схватить через это
        if hum.PlatformStand and F.Settings.AutoFarmEnabled then
            -- Разрешаем платформу только своему AutoFarm
            -- Если платформа включена не нашим скриптом — отключаем
            local hasOwnAlign = false
            for _, obj in ipairs(ch:GetDescendants()) do
                if obj.Name == "VentureAOT_AlignPos" then hasOwnAlign = true; break end
            end
            if not hasOwnAlign then
                hum.PlatformStand = false
            end
        end
    end)
end

function F.StopAntiGrab()
    if F.State.AntiGrabConnection then
        F.State.AntiGrabConnection:Disconnect()
        F.State.AntiGrabConnection = nil
    end
end

F.StartAntiGrab()

-- ═══════════════════════════════════════════
-- ESP
-- ═══════════════════════════════════════════
local HAS_DRAWING = (Drawing and Drawing.new ~= nil)

local function CreateESP_Drawing(model)
    local S = F.State
    if S.ESPObjects[model] then return end
    local box = Drawing.new("Square"); box.Thickness = 2; box.Filled = false; box.Visible = false
    local dot = Drawing.new("Circle"); dot.Radius = 6; dot.Filled = true; dot.Thickness = 1; dot.Visible = false
    local text = Drawing.new("Text"); text.Size = 14; text.Center = true; text.Outline = true; text.Font = 2; text.Visible = false
    S.ESPObjects[model] = {Box = box, NapeDot = dot, Text = text, Mode = "Drawing"}
end

local function CreateESP_Highlight(model)
    local S = F.State
    if S.ESPObjects[model] then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = F.Settings.ESPColor
    hl.FillTransparency = 0.6
    hl.OutlineColor = F.Settings.ESPColor
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model
    hl.Parent = model
    S.ESPObjects[model] = {Highlight = hl, Mode = "Highlight"}
end

local function CreateRefillESP_Drawing(model)
    local S = F.State
    if S.RefillESP[model] then return end
    local text = Drawing.new("Text")
    text.Size = 14; text.Center = true; text.Outline = true; text.Font = 2
    text.Color = Color3.fromRGB(60, 180, 255); text.Visible = false
    S.RefillESP[model] = {Text = text, Mode = "Drawing"}
end

local function CreateRefillESP_Highlight(model)
    local S = F.State
    if S.RefillESP[model] then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(60, 180, 255)
    hl.FillTransparency = 0.7
    hl.OutlineColor = Color3.fromRGB(60, 180, 255)
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = model
    hl.Parent = model
    S.RefillESP[model] = {Highlight = hl, Mode = "Highlight"}
end

local function CreatePlayerESP_Drawing(pl)
    local S = F.State
    if S.PlayerESPObjects[pl] then return end
    local box = Drawing.new("Square"); box.Thickness = 2; box.Filled = false; box.Visible = false
    local nm = Drawing.new("Text"); nm.Size = 14; nm.Center = true; nm.Outline = true; nm.Font = 2; nm.Visible = false
    local hp = Drawing.new("Text"); hp.Size = 12; hp.Center = true; hp.Outline = true; hp.Font = 2; hp.Visible = false
    S.PlayerESPObjects[pl] = {Box = box, Name = nm, HP = hp, Mode = "Drawing"}
end

local function CreatePlayerESP_Highlight(pl)
    local S = F.State
    if S.PlayerESPObjects[pl] then return end
    local hl = Instance.new("Highlight")
    hl.FillColor = Color3.fromRGB(255, 60, 60)
    hl.FillTransparency = 0.6
    hl.OutlineColor = Color3.fromRGB(255, 60, 60)
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = PlayerGui
    S.PlayerESPObjects[pl] = {Highlight = hl, Mode = "Highlight"}
end

function F.UpdateESP()
    local S = F.State
    local titans = F.GetTitans()
    local alive = {}
    for _, t in ipairs(titans) do
        alive[t.Model] = true
        if HAS_DRAWING then
            if not S.ESPObjects[t.Model] then CreateESP_Drawing(t.Model) end
            local d = S.ESPObjects[t.Model]
            if d then
                d.Box.Color = F.Settings.ESPColor
                d.NapeDot.Color = F.Settings.NapeColor
                if not F.Settings.ESP then
                    d.Box.Visible = false; d.NapeDot.Visible = false; d.Text.Visible = false
                else
                    local hPos, on = Camera:WorldToViewportPoint(t.Head.Position)
                    local nPos, nOn = Camera:WorldToViewportPoint(t.Nape.Position)
                    if on then
                        local scale = math.clamp(200 / math.max(t.Distance, 1), 0.3, 3)
                        local size = Vector2.new(20 * scale, 35 * scale)
                        d.Box.Size = size
                        d.Box.Position = Vector2.new(hPos.X - size.X / 2, hPos.Y - size.Y / 2)
                        d.Box.Visible = true
                        d.Text.Position = Vector2.new(hPos.X, hPos.Y - size.Y / 2 - 18)
                        d.Text.Text = t.Model.Name .. " [" .. math.floor(t.Distance) .. "]"
                        d.Text.Color = Color3.new(1, 1, 1)
                        d.Text.Visible = true
                    else
                        d.Box.Visible = false; d.Text.Visible = false
                    end
                    if nOn then
                        d.NapeDot.Position = Vector2.new(nPos.X, nPos.Y)
                        d.NapeDot.Visible = true
                    else
                        d.NapeDot.Visible = false
                    end
                end
            end
        else
            if F.Settings.ESP then
                if not S.ESPObjects[t.Model] then CreateESP_Highlight(t.Model) end
                local d = S.ESPObjects[t.Model]
                if d and d.Highlight then
                    d.Highlight.FillColor = F.Settings.ESPColor
                    d.Highlight.OutlineColor = F.Settings.ESPColor
                    d.Highlight.Enabled = true
                end
            else
                local d = S.ESPObjects[t.Model]
                if d and d.Highlight then d.Highlight.Enabled = false end
            end
        end
    end
    for m, d in pairs(S.ESPObjects) do
        if not alive[m] then
            if d.Mode == "Drawing" then
                for _, o in pairs(d) do
                    if typeof(o) == "userdata" or type(o) == "table" then
                        pcall(function() o:Destroy() end)
                    end
                end
            elseif d.Highlight then d.Highlight:Destroy() end
            S.ESPObjects[m] = nil
        end
    end

    -- Refills
    local refills = F.GetRefills()
    local aliveR = {}
    for _, r in ipairs(refills) do
        aliveR[r.Model] = true
        if HAS_DRAWING then
            if not S.RefillESP[r.Model] then CreateRefillESP_Drawing(r.Model) end
            local d = S.RefillESP[r.Model]
            if d then
                if not F.Settings.ESP then d.Text.Visible = false
                else
                    local pos, on = Camera:WorldToViewportPoint(r.Part.Position)
                    if on then
                        d.Text.Position = Vector2.new(pos.X, pos.Y)
                        d.Text.Text = "[Refill] [" .. math.floor(r.Distance) .. "]"
                        d.Text.Visible = true
                    else d.Text.Visible = false end
                end
            end
        else
            if F.Settings.ESP then
                if not S.RefillESP[r.Model] then CreateRefillESP_Highlight(r.Model) end
                local d = S.RefillESP[r.Model]
                if d and d.Highlight then d.Highlight.Enabled = true end
            else
                local d = S.RefillESP[r.Model]
                if d and d.Highlight then d.Highlight.Enabled = false end
            end
        end
    end
    for m, d in pairs(S.RefillESP) do
        if not aliveR[m] then
            if d.Mode == "Drawing" then pcall(function() d.Text:Destroy() end)
            elseif d.Highlight then d.Highlight:Destroy() end
            S.RefillESP[m] = nil
        end
    end

    -- Players
    if F.Settings.PlayerESP then
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer then
                if not S.PlayerESPObjects[pl] then
                    if HAS_DRAWING then CreatePlayerESP_Drawing(pl) else CreatePlayerESP_Highlight(pl) end
                end
                local d = S.PlayerESPObjects[pl]
                local ch = pl.Character
                local h = ch and ch:FindFirstChildOfClass("Humanoid")
                local rt = ch and ch:FindFirstChild("HumanoidRootPart")
                if h and rt and h.Health > 0 then
                    local pvpOff = pl:GetAttribute("PvPDisabled")
                    if d.Mode == "Drawing" then
                        local pos, on = Camera:WorldToViewportPoint(rt.Position)
                        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if on and myRoot then
                            local hpv = math.floor(h.Health)
                            local mx = math.floor(h.MaxHealth)
                            local pct = math.floor((h.Health / h.MaxHealth) * 100)
                            local pvpS = pvpOff and "OFF" or "ON"
                            local dist = (myRoot.Position - rt.Position).Magnitude
                            local scale = math.clamp(200 / math.max(dist, 1), 0.3, 3)
                            local size = Vector2.new(20 * scale, 35 * scale)
                            d.Box.Size = size
                            d.Box.Position = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)
                            d.Box.Color = pvpOff and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(255, 60, 60)
                            d.Box.Visible = true
                            d.Name.Position = Vector2.new(pos.X, pos.Y - size.Y / 2 - 40)
                            d.Name.Text = pl.Name .. " | " .. pvpS
                            d.Name.Visible = true
                            d.HP.Position = Vector2.new(pos.X, pos.Y - size.Y / 2 - 22)
                            d.HP.Text = "HP: " .. hpv .. "/" .. mx .. " (" .. pct .. "%)"
                            d.HP.Color = pct > 50 and Color3.fromRGB(100, 255, 100) or pct > 25 and Color3.fromRGB(255, 200, 60) or Color3.fromRGB(255, 60, 60)
                            d.HP.Visible = true
                        else
                            d.Box.Visible = false; d.Name.Visible = false; d.HP.Visible = false
                        end
                    else
                        if d.Highlight then
                            d.Highlight.Adornee = ch
                            d.Highlight.FillColor = pvpOff and Color3.fromRGB(100, 200, 100) or Color3.fromRGB(255, 60, 60)
                            d.Highlight.OutlineColor = d.Highlight.FillColor
                            d.Highlight.Enabled = true
                        end
                    end
                else
                    if d.Mode == "Drawing" then
                        d.Box.Visible = false; d.Name.Visible = false; d.HP.Visible = false
                    elseif d.Highlight then d.Highlight.Enabled = false end
                end
            end
        end
    else
        for _, d in pairs(S.PlayerESPObjects) do
            if d.Mode == "Drawing" then
                d.Box.Visible = false; d.Name.Visible = false; d.HP.Visible = false
            elseif d.Highlight then d.Highlight.Enabled = false end
        end
    end
end

RunService.RenderStepped:Connect(function() pcall(F.UpdateESP) end)

-- ═══════════════════════════════════════════
-- STREAMER MODE
-- ═══════════════════════════════════════════
local function SaveStreamerOriginal()
    local S = F.Settings
    if S._OriginalName then return end
    S._OriginalName = LocalPlayer.Name
    local ch = LocalPlayer.Character
    if ch then
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then S._OriginalName = hum.DisplayName or LocalPlayer.Name end
    end
    -- Сохраняем статистику
    local dr = LocalPlayer:FindFirstChild("DataReplica")
    if dr then
        local xp = dr:FindFirstChild("XP")
        if xp and (xp:IsA("NumberValue") or xp:IsA("IntValue")) then S._OriginalXP = xp.Value end
        local lv = dr:FindFirstChild("Level")
        if lv and (lv:IsA("NumberValue") or lv:IsA("IntValue")) then S._OriginalLevel = lv.Value end
    end
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        local m = ls:FindFirstChild("Money")
        if m and (m:IsA("NumberValue") or m:IsA("IntValue")) then S._OriginalMoney = m.Value end
    end
end

function F.StreamerApplyName()
    local S = F.Settings
    if not S.StreamerEnabled then return end
    local name = S.StreamerFakeName
    if not name or #name == 0 then return end
    pcall(function() LocalPlayer:SetAttribute("LoreName", name) end)
    pcall(function() LocalPlayer.DisplayName = name end)
    local ch = LocalPlayer.Character
    if ch then
        local hum = ch:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum.DisplayName = name end) end
    end
end

local function ApplyStreamerStats()
    local S = F.Settings
    if not S.StreamerEnabled then return end
    local dr = LocalPlayer:FindFirstChild("DataReplica")
    if dr then
        pcall(function()
            local xp = dr:FindFirstChild("XP")
            if xp and (xp:IsA("NumberValue") or xp:IsA("IntValue")) then xp.Value = S.StreamerFakeXP end
            local lv = dr:FindFirstChild("Level")
            if lv and (lv:IsA("NumberValue") or lv:IsA("IntValue")) then lv.Value = S.StreamerFakeLevel end
        end)
    end
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        pcall(function()
            local m = ls:FindFirstChild("Money")
            if m and (m:IsA("NumberValue") or m:IsA("IntValue")) then m.Value = S.StreamerFakeMoney end
        end)
    end
end

local function ApplyStreamerKillFeed()
    local S = F.Settings
    if not S.StreamerEnabled or not S.StreamerHideKillFeed then return end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    local screen = pg:FindFirstChild("Screen")
    if not screen then return end
    local kf = screen:FindFirstChild("KillFeed", true)
    if kf then pcall(function() kf:Destroy() end) end
end

function F.StreamerEnable()
    local S = F.Settings
    SaveStreamerOriginal()
    S.StreamerEnabled = true
    F.StreamerApplyName()
    ApplyStreamerStats()
    ApplyStreamerKillFeed()
    if F.State.StreamerLoop then F.State.StreamerLoop:Disconnect() end
    F.State.StreamerLoop = RunService.Heartbeat:Connect(function()
        if not S.StreamerEnabled then return end
        pcall(ApplyStreamerStats)
    end)
    -- Обновляем бейдж
    local ch = LocalPlayer.Character
    if ch then
        local head = ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
        if head then
            local old = head:FindFirstChild("VentureBadge")
            if old then old:Destroy() end
        end
    end
    F.Notify("Streamer Mode", "Enabled - CONTENT CREATOR", 3)
end

function F.StreamerDisable()
    local S = F.Settings
    S.StreamerEnabled = false
    if F.State.StreamerLoop then
        F.State.StreamerLoop:Disconnect()
        F.State.StreamerLoop = nil
    end
    -- Возвращаем оригинальный ник
    if S._OriginalName then
        pcall(function() LocalPlayer:SetAttribute("LoreName", S._OriginalName) end)
        pcall(function() LocalPlayer.DisplayName = S._OriginalName end)
        local ch = LocalPlayer.Character
        if ch then
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum.DisplayName = S._OriginalName end) end
        end
    end
    -- Возвращаем статистику
    if S._OriginalXP or S._OriginalLevel or S._OriginalMoney then
        local dr = LocalPlayer:FindFirstChild("DataReplica")
        if dr then
            pcall(function()
                if S._OriginalXP then
                    local xp = dr:FindFirstChild("XP")
                    if xp and (xp:IsA("NumberValue") or xp:IsA("IntValue")) then xp.Value = S._OriginalXP end
                end
                if S._OriginalLevel then
                    local lv = dr:FindFirstChild("Level")
                    if lv and (lv:IsA("NumberValue") or lv:IsA("IntValue")) then lv.Value = S._OriginalLevel end
                end
            end)
        end
        if S._OriginalMoney then
            local ls = LocalPlayer:FindFirstChild("leaderstats")
            if ls then
                pcall(function()
                    local m = ls:FindFirstChild("Money")
                    if m and (m:IsA("NumberValue") or m:IsA("IntValue")) then m.Value = S._OriginalMoney end
                end)
            end
        end
    end
    -- KillFeed не возвращаем (сервер сам пересоздаст)
    S._OriginalName = nil
    S._OriginalXP = nil
    S._OriginalLevel = nil
    S._OriginalMoney = nil
    -- Обновляем бейдж
    local ch = LocalPlayer.Character
    if ch then
        local head = ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
        if head then
            local old = head:FindFirstChild("VentureBadge")
            if old then old:Destroy() end
        end
    end
    F.Notify("Streamer Mode", "Disabled - Restored", 3)
end

-- ═══════════════════════════════════════════
-- ANTI-AFK
-- ═══════════════════════════════════════════
pcall(function()
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    end)
end)

local function DoAFKAction()
    local S = F.Settings
    local ch = LocalPlayer.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if S.AntiAFKMode == "Jump" or S.AntiAFKMode == "Both" then
        pcall(function() hum.Jump = true end)
    end
    if S.AntiAFKMode == "Move" or S.AntiAFKMode == "Both" then
        pcall(function()
            hum:Move(Vector3.new(0, 0, -1), false)
            task.wait(0.15)
            hum:Move(Vector3.new(0, 0, 1), false)
            task.wait(0.15)
            hum:Move(Vector3.zero, false)
        end)
    end
    F.State.AntiAFKLastAction = tick()
end

function F.AntiAFKEnable()
    F.Settings.AntiAFKEnabled = true
    F.State.AntiAFKLastAction = tick()
    if F.State.AntiAFKConnection then return end
    F.State.AntiAFKConnection = task.spawn(function()
        while F.Settings.AntiAFKEnabled do
            task.wait(1)
            if tick() - F.State.AntiAFKLastAction >= F.Settings.AntiAFKInterval then
                pcall(DoAFKAction)
            end
        end
    end)
    F.Notify("Anti-AFK", "Enabled", 3)
end

function F.AntiAFKDisable()
    F.Settings.AntiAFKEnabled = false
    F.State.AntiAFKConnection = nil
    F.Notify("Anti-AFK", "Disabled", 3)
end

-- ═══════════════════════════════════════════
-- SUPABASE BEACON
-- ═══════════════════════════════════════════
local function SupaHeaders()
    local S = F.Settings
    return {
        ["apikey"] = S.SupabaseKey,
        ["Authorization"] = "Bearer " .. S.SupabaseKey,
        ["Content-Type"] = "application/json",
        ["Prefer"] = "resolution=merge-duplicates",
    }
end

local function SupaTableUrl()
    local S = F.Settings
    return S.SupabaseUrl .. "/rest/v1/" .. S.SupabaseTable
end

local function SendBeacon()
    local S = F.Settings
    F.HttpPost(SupaTableUrl(), {
        user_id = F.GetUserId(),
        name = LocalPlayer.Name,
        role = (LocalPlayer.Name == S.OwnerName) and "Owner" or "User",
        job_id = game.JobId,
        place_id = tostring(game.PlaceId),
        last_seen = F.ISOTime(0),
    }, SupaHeaders())
end

local function SafeMakeBadge(pl, role)
    if not pl or not pl.Parent then return end
    local ch = pl.Character
    if not ch then return end
    local head = ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
    if not head then return end

    local S = F.State
    local Settings = F.Settings
    local old = S.SupabaseBadgeByPlayer[pl]
    if old and old.Parent then old:Destroy() end

    local isOwner = (role == "Owner")
    local isStreamer = (pl == LocalPlayer and Settings.StreamerEnabled)
    local width = (isOwner or isStreamer) and 150 or 130
    local height = (isOwner or isStreamer) and 32 or 28
    local infoSize = (isOwner or isStreamer) and 9 or 8

    local bg = Instance.new("BillboardGui")
    bg.Name = "VentureBadge"
    bg.Size = UDim2.fromOffset(width, height)
    bg.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
    bg.AlwaysOnTop = true
    bg.LightInfluence = 0
    bg.MaxDistance = 1000
    bg.Adornee = head
    bg.Parent = head

    local container = Instance.new("Frame")
    container.Size = UDim2.fromScale(1, 1)
    container.BackgroundColor3 = (isOwner or isStreamer) and Color3.fromRGB(35, 12, 60) or Color3.fromRGB(25, 12, 50)
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = bg
    Instance.new("UICorner", container).CornerRadius = UDim.new(1, 0)

    local grad = Instance.new("UIGradient")
    if isStreamer then
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 100, 30)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 160, 60)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 220, 120)),
        })
    else
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, isOwner and Color3.fromRGB(130, 50, 255) or Color3.fromRGB(90, 45, 200)),
            ColorSequenceKeypoint.new(0.5, isOwner and Color3.fromRGB(200, 100, 255) or Color3.fromRGB(150, 80, 240)),
            ColorSequenceKeypoint.new(1, isOwner and Color3.fromRGB(255, 170, 255) or Color3.fromRGB(210, 130, 255)),
        })
    end
    grad.Rotation = 30
    grad.Parent = container

    local stroke = Instance.new("UIStroke")
    if isStreamer then stroke.Color = Color3.fromRGB(255, 200, 100)
    elseif isOwner then stroke.Color = Color3.fromRGB(240, 180, 255)
    else stroke.Color = Color3.fromRGB(200, 150, 255) end
    stroke.Thickness = (isOwner or isStreamer) and 1.8 or 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = container

    local glow = Instance.new("UIStroke")
    if isStreamer then glow.Color = Color3.fromRGB(255, 180, 80)
    else glow.Color = isOwner and Color3.fromRGB(220, 130, 255) or Color3.fromRGB(170, 100, 255) end
    glow.Thickness = (isOwner or isStreamer) and 4 or 3
    glow.Transparency = 0.5
    glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    glow.Parent = container

    local icon = Instance.new("TextLabel")
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.Position = UDim2.new(0, (isOwner or isStreamer) and 8 or 6, 0.5, 0)
    icon.Size = UDim2.fromOffset((isOwner or isStreamer) and 16 or 14, (isOwner or isStreamer) and 16 or 14)
    icon.BackgroundTransparency = 1
    if isStreamer then icon.Text = "★"
    elseif isOwner then icon.Text = "👑"
    else icon.Text = "⚡" end
    icon.TextColor3 = isStreamer and Color3.fromRGB(255, 230, 120) or (isOwner and Color3.fromRGB(255, 220, 100) or Color3.fromRGB(230, 200, 255))
    icon.TextScaled = true
    icon.Font = Enum.Font.GothamBlack
    icon.ZIndex = 5
    icon.Parent = container

    local label = Instance.new("TextLabel")
    label.Position = UDim2.new(0, (isOwner or isStreamer) and 28 or 24, 0, 0)
    label.Size = UDim2.new(1, (isOwner or isStreamer) and -32 or -28, 1, 0)
    label.BackgroundTransparency = 1
    if isStreamer then label.Text = "CONTENT CREATOR"
    elseif isOwner then label.Text = "SCRIPT DEV"
    else label.Text = "SCRIPT USER" end
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.fromRGB(40, 0, 80)
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 5
    label.Parent = container

    S.SupabaseBadges[bg] = {BaseWidth = width, BaseHeight = height, Owner = pl, Head = head}
    S.SupabaseBadgeByPlayer[pl] = bg
end

task.spawn(function()
    while true do
        pcall(SendBeacon)
        task.wait(15)
    end
end)

task.spawn(function()
    while true do
        task.wait(10)
        pcall(function()
            local S = F.State
            if S.SupabaseBadgeByPlayer[LocalPlayer] then
                local old = S.SupabaseBadgeByPlayer[LocalPlayer]
                if old and old.Parent then old:Destroy() end
            end
            local role = (LocalPlayer.Name == F.Settings.OwnerName) and "Owner" or "User"
            SafeMakeBadge(LocalPlayer, role)
        end)
    end
end)

-- ═══════════════════════════════════════════
-- ANNOUNCE
-- ═══════════════════════════════════════════
local function AnnounceUrl()
    local S = F.Settings
    return S.SupabaseUrl .. "/rest/v1/" .. S.AnnounceTable
end

local function ShowAnnounceBanner(title, text)
    local S = F.State
    if S.AnnounceBanner and S.AnnounceBanner.Parent then S.AnnounceBanner:Destroy() end

    local gui = F.New("ScreenGui", {
        Name = "VentureAnnounce", ResetOnSpawn = false,
        DisplayOrder = 2147483000, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    }, PlayerGui)
    S.AnnounceBanner = gui

    local bg = F.New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, -100),
        Size = UDim2.new(0.7, 0, 0, 100),
        BackgroundColor3 = Color3.fromRGB(20, 5, 45),
        BorderSizePixel = 0, ZIndex = 1
    }, gui)
    F.New("UICorner", {CornerRadius = UDim.new(0, 14)}, bg)
    F.New("UIStroke", {Color = Color3.fromRGB(200, 100, 255), Thickness = 2.5}, bg)
    F.New("UIGradient", {Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 30, 160)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 10, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 30, 160)),
    }), Rotation = 0}, bg)

    F.New("TextLabel", {
        Position = UDim2.new(0, 16, 0, 8),
        Size = UDim2.new(1, -32, 0, 22),
        BackgroundTransparency = 1, Text = "ANNOUNCEMENT",
        TextColor3 = Color3.fromRGB(255, 220, 255),
        TextSize = 14, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2
    }, bg)
    F.New("TextLabel", {
        Position = UDim2.new(0, 16, 0, 30),
        Size = UDim2.new(1, -32, 0, 22),
        BackgroundTransparency = 1, Text = title or "",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 18, Font = Enum.Font.GothamBlack,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 2
    }, bg)
    F.New("TextLabel", {
        Position = UDim2.new(0, 16, 0, 54),
        Size = UDim2.new(1, -32, 0, 32),
        BackgroundTransparency = 1, Text = text or "",
        TextColor3 = Color3.fromRGB(230, 200, 255),
        TextSize = 13, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true, ZIndex = 2
    }, bg)
    F.New("TextLabel", {
        Position = UDim2.new(0, 16, 0, 88),
        Size = UDim2.new(1, -32, 0, 12),
        BackgroundTransparency = 1, Text = "by DEV",
        TextColor3 = Color3.fromRGB(200, 150, 255),
        TextSize = 10, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 2
    }, bg)

    F.Tween(bg, 0.4, {Position = UDim2.new(0.5, 0, 0, 20)}, Enum.EasingStyle.Back)
    task.spawn(function()
        task.wait(8)
        F.Tween(bg, 0.4, {Position = UDim2.new(0.5, 0, 0, -120)})
        task.wait(0.5)
        if gui.Parent then gui:Destroy() end
    end)
end

function F.SendAnnouncement(title, text)
    if LocalPlayer.Name ~= F.Settings.OwnerName then
        F.Notify("Denied", "Only DEV can announce", 3)
        return
    end
    F.HttpPost(AnnounceUrl(), {
        author = "DEV",
        title = title:sub(1, 60),
        text = text:sub(1, 200),
        created_at = F.ISOTime(0),
    }, SupaHeaders())
    ShowAnnounceBanner(title, text)
end

task.spawn(function()
    while true do
        task.wait(10)
        pcall(function()
            local S = F.State
            local cutoff = F.ISOTime(-86400)
            local url = AnnounceUrl() .. "?select=*&created_at=gte." .. cutoff .. "&order=id.desc&limit=1"
            local res = F.HttpGet(url, SupaHeaders())
            if res then
                local data = HttpService:JSONDecode(res)
                if type(data) == "table" and #data > 0 then
                    local item = data[1]
                    if item.id and item.id > S.AnnounceLastSeenId then
                        S.AnnounceLastSeenId = item.id
                        if item.author ~= LocalPlayer.Name then
                            ShowAnnounceBanner(item.title, item.text)
                        end
                    end
                end
            end
        end)
    end
end)

-- ═══════════════════════════════════════════
-- ONLINE
-- ═══════════════════════════════════════════
function F.FetchOnlineUsers()
    local S = F.Settings
    local cutoff = F.ISOTime(-60)
    local url = SupaTableUrl() .. "?last_seen=gte." .. cutoff .. "&order=last_seen.desc"
    local res = F.HttpGet(url, SupaHeaders())
    if not res then return {} end
    local ok, data = pcall(function() return HttpService:JSONDecode(res) end)
    if ok and type(data) == "table" then return data end
    return {}
end

-- ═══════════════════════════════════════════
-- MOD DETECTOR
-- ═══════════════════════════════════════════
local function IsModerator(player)
    if not player or player == LocalPlayer then return false, 0 end
    local ok, rank = pcall(function() return player:GetRankInGroup(F.Settings.ModGroupId) end)
    if ok and rank and rank > 0 then return true, rank end
    return false, 0
end

local function CheckMods()
    local S = F.State
    local found = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            local im, r = IsModerator(pl)
            if im then found[pl.Name] = r end
        end
    end
    S.SecurityState.ModsInServer = found
    local cnt = 0
    for _ in pairs(found) do cnt = cnt + 1 end
    if cnt > 0 then
        if not S.SecurityState.IsPaused then
            S.SecurityState.IsPaused = true
            F.Notify("MOD DETECTED", "All functions paused", 10)
            F.Settings.AutoFarmEnabled = false
            F.Settings.AutoHealEnabled = false
            F.Settings.HitboxExpand = false
            F.Settings.Noclip = false
            F.ResetAllHitboxes()
            F.StopNoclip()
            F.DisableFPSBooster()
            F.CleanupFarm()
        end
        if F.Settings.AutoKickOnMod then
            task.wait(1)
            pcall(function() TeleportService:Teleport(game.PlaceId) end)
        end
    else
        if S.SecurityState.IsPaused then
            S.SecurityState.IsPaused = false
        end
    end
end

Players.PlayerAdded:Connect(function() task.wait(2); pcall(CheckMods) end)
Players.PlayerRemoving:Connect(function(pl)
    if F.State.SecurityState.ModsInServer[pl.Name] then
        F.State.SecurityState.ModsInServer[pl.Name] = nil
        CheckMods()
    end
end)
task.spawn(function() while true do task.wait(15); pcall(CheckMods) end end)
task.wait(1)
CheckMods()

-- ═══════════════════════════════════════════
-- SERVER CONTROLS
-- ═══════════════════════════════════════════
function F.RejoinServer()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end

function F.JoinNewServer()
    pcall(function()
        TeleportService:Teleport(game.PlaceId)
    end)
end

function F.CopyServerId()
    if setclipboard then
        setclipboard(game.JobId)
        F.Notify("Copied", game.JobId:sub(1, 12) .. "...", 3)
    elseif toclipboard then
        toclipboard(game.JobId)
        F.Notify("Copied", game.JobId:sub(1, 12) .. "...", 3)
    end
end

function F.CopyDiscord()
    local link = "discord.gg/UHCwX78Npc"
    if setclipboard then
        setclipboard(link)
        F.Notify("Copied", link, 3)
    elseif toclipboard then
        toclipboard(link)
        F.Notify("Copied", link, 3)
    end
end

-- ═══════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════
-- Запускаем AntiGrab сразу
F.StartAntiGrab()

print("[Venture Functions] Loaded")

return F
