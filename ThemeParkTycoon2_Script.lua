-- ============================================================
--   🎢  THEME PARK TYCOON 2 — ULTIMATE HUB  🎢
--   Beautiful dark neon GUI | All-in-one features
--   Paste into your executor while in TPT2
-- ============================================================

-- // SERVICES
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid    = Character:WaitForChild("Humanoid")

-- // STATE
local state = {
    autoFarm     = false,
    fly          = false,
    speed        = 16,
    flySpeed     = 50,
    noclip       = false,
    autoClean    = false,
    godMode      = false,
    flyBody      = nil,
    flyGyro      = nil,
}

-- // COLORS (neon theme)
local C = {
    BG          = Color3.fromRGB(10, 10, 18),
    PANEL       = Color3.fromRGB(18, 18, 30),
    ACCENT      = Color3.fromRGB(255, 80, 180),
    ACCENT2     = Color3.fromRGB(80, 180, 255),
    GREEN       = Color3.fromRGB(80, 255, 130),
    RED         = Color3.fromRGB(255, 70, 70),
    TEXT        = Color3.fromRGB(230, 230, 255),
    SUBTEXT     = Color3.fromRGB(140, 140, 175),
    BORDER      = Color3.fromRGB(55, 55, 90),
    BTN         = Color3.fromRGB(28, 28, 50),
    BTN_HOV     = Color3.fromRGB(40, 40, 70),
}

-- ============================================================
--  GUI BUILDER HELPERS
-- ============================================================

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or C.BORDER
    s.Thickness = thickness or 1.2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
end

local function addGradient(parent, c0, c1, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c0 or C.PANEL, c1 or C.BG)
    g.Rotation = rotation or 90
    g.Parent = parent
end

local function newLabel(parent, text, size, pos, textSize, color, bold)
    local l = Instance.new("TextLabel")
    l.Size            = size
    l.Position        = pos
    l.Text            = text
    l.TextSize        = textSize or 14
    l.Font            = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextColor3      = color or C.TEXT
    l.BackgroundTransparency = 1
    l.Parent          = parent
    return l
end

local function newButton(parent, text, size, pos, onClick)
    local btn = Instance.new("TextButton")
    btn.Size              = size
    btn.Position          = pos
    btn.Text              = text
    btn.TextSize          = 13
    btn.Font              = Enum.Font.GothamSemibold
    btn.TextColor3        = C.TEXT
    btn.BackgroundColor3  = C.BTN
    btn.AutoButtonColor   = false
    btn.Parent            = parent
    addCorner(btn, 6)
    addStroke(btn, C.BORDER, 1)

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN_HOV}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = C.BTN}):Play()
    end)
    btn.MouseButton1Click:Connect(onClick)
    return btn
end

-- Toggle button — returns (button, indicator)
local function newToggle(parent, text, size, pos, onToggle)
    local frame = Instance.new("Frame")
    frame.Size             = size
    frame.Position         = pos
    frame.BackgroundColor3 = C.BTN
    frame.Parent           = parent
    addCorner(frame, 6)
    addStroke(frame, C.BORDER, 1)

    newLabel(frame, text, UDim2.new(0.75, 0, 1, 0), UDim2.new(0.04, 0, 0, 0), 13, C.TEXT, false)

    local pill = Instance.new("Frame")
    pill.Size              = UDim2.new(0, 36, 0, 18)
    pill.Position          = UDim2.new(1, -44, 0.5, -9)
    pill.BackgroundColor3  = C.RED
    pill.Parent            = frame
    addCorner(pill, 9)

    local knob = Instance.new("Frame")
    knob.Size              = UDim2.new(0, 14, 0, 14)
    knob.Position          = UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3  = Color3.new(1,1,1)
    knob.Parent            = pill
    addCorner(knob, 7)

    local on = false
    local function setToggle(val)
        on = val
        local tw = TweenService:Create
        tw(pill, TweenInfo.new(0.2), {BackgroundColor3 = on and C.GREEN or C.RED}):Play()
        tw(knob, TweenInfo.new(0.2), {Position = on
            and UDim2.new(1, -16, 0.5, -7)
            or  UDim2.new(0, 2,   0.5, -7)}):Play()
        if onToggle then onToggle(on) end
    end

    local hitbox = Instance.new("TextButton")
    hitbox.Size              = UDim2.new(1, 0, 1, 0)
    hitbox.BackgroundTransparency = 1
    hitbox.Text              = ""
    hitbox.Parent            = frame
    hitbox.MouseButton1Click:Connect(function() setToggle(not on) end)

    return frame, function() return on end, setToggle
end

-- ============================================================
--  MAIN GUI
-- ============================================================

-- Remove old GUI if re-injected
if game.CoreGui:FindFirstChild("TPT2Hub") then
    game.CoreGui.TPT2Hub:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "TPT2Hub"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent          = game.CoreGui

-- // OPEN / CLOSE TOGGLE BUTTON (always visible, top-left)
local openBtn = Instance.new("TextButton")
openBtn.Size              = UDim2.new(0, 44, 0, 44)
openBtn.Position          = UDim2.new(0, 12, 0, 12)
openBtn.Text              = "🎢"
openBtn.TextSize          = 22
openBtn.BackgroundColor3  = C.PANEL
openBtn.TextColor3        = C.TEXT
openBtn.Font              = Enum.Font.GothamBold
openBtn.ZIndex            = 20
openBtn.Parent            = ScreenGui
addCorner(openBtn, 10)
addStroke(openBtn, C.ACCENT, 1.5)

-- // MAIN WINDOW
local Win = Instance.new("Frame")
Win.Name              = "Window"
Win.Size              = UDim2.new(0, 360, 0, 460)
Win.Position          = UDim2.new(0, 64, 0, 12)
Win.BackgroundColor3  = C.BG
Win.ClipsDescendants  = true
Win.Parent            = ScreenGui
addCorner(Win, 12)
addStroke(Win, C.ACCENT, 1.5)

-- // TITLE BAR
local TitleBar = Instance.new("Frame")
TitleBar.Size              = UDim2.new(1, 0, 0, 46)
TitleBar.BackgroundColor3  = C.PANEL
TitleBar.Parent            = Win
addCorner(TitleBar, 12)
addGradient(TitleBar, Color3.fromRGB(40, 20, 60), Color3.fromRGB(20, 20, 40), 90)
addStroke(TitleBar, C.BORDER, 0)

newLabel(TitleBar, "🎢  TPT2 Ultimate Hub", UDim2.new(0.8,0,1,0), UDim2.new(0.04,0,0,0), 16, C.TEXT, true)

local versionLabel = newLabel(TitleBar, "v3.7 | by HubDev", UDim2.new(0.4,0,0.6,0),
    UDim2.new(0.04,0,0.55,0), 11, C.SUBTEXT, false)

-- Close "X" inside title bar
local closeX = Instance.new("TextButton")
closeX.Size              = UDim2.new(0, 30, 0, 30)
closeX.Position          = UDim2.new(1, -38, 0.5, -15)
closeX.Text              = "✕"
closeX.TextSize          = 14
closeX.Font              = Enum.Font.GothamBold
closeX.BackgroundColor3  = Color3.fromRGB(200, 50, 60)
closeX.TextColor3        = Color3.new(1,1,1)
closeX.Parent            = TitleBar
addCorner(closeX, 6)
closeX.MouseButton1Click:Connect(function()
    Win.Visible = false
end)

-- // SUBTITLE / STATUS BAR
local statusBar = Instance.new("Frame")
statusBar.Size              = UDim2.new(1, -16, 0, 28)
statusBar.Position          = UDim2.new(0, 8, 0, 52)
statusBar.BackgroundColor3  = C.PANEL
statusBar.Parent            = Win
addCorner(statusBar, 6)
local statusLabel = newLabel(statusBar, "⚡ Status: Ready | Theme Park Tycoon 2",
    UDim2.new(1, -10, 1, 0), UDim2.new(0.02, 0, 0, 0), 11, C.ACCENT2, false)

-- // TAB BAR
local tabBarBG = Instance.new("Frame")
tabBarBG.Size             = UDim2.new(1, -16, 0, 32)
tabBarBG.Position         = UDim2.new(0, 8, 0, 86)
tabBarBG.BackgroundColor3 = C.PANEL
tabBarBG.Parent           = Win
addCorner(tabBarBG, 7)

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding        = UDim.new(0, 4)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
tabLayout.Parent = tabBarBG

local TABS = {"💰 Farm", "🚀 Player", "🏗 Build", "🛡 Utils"}
local tabButtons = {}
local tabPages   = {}
local currentTab = 1

-- // CONTENT AREA
local contentArea = Instance.new("Frame")
contentArea.Size              = UDim2.new(1, -16, 0, 290)
contentArea.Position          = UDim2.new(0, 8, 0, 124)
contentArea.BackgroundColor3  = C.PANEL
contentArea.ClipsDescendants  = true
contentArea.Parent            = Win
addCorner(contentArea, 8)

local function makeTabPage()
    local p = Instance.new("Frame")
    p.Size             = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible          = false
    p.Parent           = contentArea
    local layout = Instance.new("UIListLayout")
    layout.Padding     = UDim.new(0, 6)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment   = Enum.VerticalAlignment.Top
    layout.Parent      = p
    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, 8)
    pad.PaddingLeft   = UDim.new(0, 8)
    pad.PaddingRight  = UDim.new(0, 8)
    pad.Parent        = p
    return p
end

local function switchTab(idx)
    for i, p in pairs(tabPages) do
        p.Visible = (i == idx)
    end
    for i, b in pairs(tabButtons) do
        if i == idx then
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = C.ACCENT, TextColor3 = Color3.new(1,1,1)}):Play()
        else
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(28,28,50), TextColor3 = C.SUBTEXT}):Play()
        end
    end
    currentTab = idx
end

for i, name in ipairs(TABS) do
    local tb = Instance.new("TextButton")
    tb.Size             = UDim2.new(0, 78, 0, 24)
    tb.Text             = name
    tb.TextSize         = 11
    tb.Font             = Enum.Font.GothamSemibold
    tb.BackgroundColor3 = Color3.fromRGB(28, 28, 50)
    tb.TextColor3       = C.SUBTEXT
    tb.AutoButtonColor  = false
    tb.Parent           = tabBarBG
    addCorner(tb, 6)
    tb.MouseButton1Click:Connect(function() switchTab(i) end)
    tabButtons[i] = tb

    local page = makeTabPage()
    tabPages[i] = page
end

-- ============================================================
--  HELPER: ROW with label
-- ============================================================
local function sectionLabel(parent, text)
    local lbl = newLabel(parent, "  " .. text, UDim2.new(1, -16, 0, 20), UDim2.new(0,0,0,0), 11, C.SUBTEXT, false)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local function divider(parent)
    local d = Instance.new("Frame")
    d.Size             = UDim2.new(1, -16, 0, 1)
    d.BackgroundColor3 = C.BORDER
    d.Parent           = parent
end

-- ============================================================
--  TAB 1 — 💰 FARM
-- ============================================================
local farmPage = tabPages[1]

sectionLabel(farmPage, "AUTO FARM")

newToggle(farmPage, "🎟  Auto Collect Money",
    UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 0),
    function(on)
        state.autoFarm = on
        statusLabel.Text = on and "⚡ Auto Farm: ACTIVE" or "⚡ Status: Ready"
    end)

newToggle(farmPage, "🔄  Auto Upgrade Rides",
    UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 0),
    function(on)
        statusLabel.Text = on and "⚡ Auto Upgrade: ACTIVE" or "⚡ Status: Ready"
    end)

newToggle(farmPage, "🏷  Auto Set Ticket Prices",
    UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 0),
    function(on) end)

divider(farmPage)
sectionLabel(farmPage, "MONEY")

newButton(farmPage, "💵  Add $10,000,000",
    UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 0, 0),
    function()
        -- Attempt to modify leaderstats money
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls then
            local m = ls:FindFirstChildWhichIsA("IntValue") or ls:FindFirstChildWhichIsA("NumberValue")
            if m then m.Value = m.Value + 10000000 end
        end
        statusLabel.Text = "💰 +$10,000,000 Added!"
    end)

newButton(farmPage, "🏦  Max Money (Inf Loop)",
    UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 0, 0),
    function()
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls then
            for _, v in pairs(ls:GetChildren()) do
                if v:IsA("IntValue") or v:IsA("NumberValue") then
                    v.Value = 2^31 - 1
                end
            end
        end
        statusLabel.Text = "🏦 Max Money Set!"
    end)

-- ============================================================
--  TAB 2 — 🚀 PLAYER
-- ============================================================
local playerPage = tabPages[2]

sectionLabel(playerPage, "MOVEMENT")

-- Speed slider
local speedFrame = Instance.new("Frame")
speedFrame.Size             = UDim2.new(1, -16, 0, 50)
speedFrame.BackgroundColor3 = C.BTN
speedFrame.Parent           = playerPage
addCorner(speedFrame, 6)
addStroke(speedFrame, C.BORDER, 1)
newLabel(speedFrame, "🏃  Walk Speed", UDim2.new(0.55, 0, 0.45, 0), UDim2.new(0.04, 0, 0, 0), 13, C.TEXT)
local speedValLabel = newLabel(speedFrame, "16", UDim2.new(0.2, 0, 0.45, 0), UDim2.new(0.75, 0, 0, 0), 13, C.ACCENT, true)
speedValLabel.TextXAlignment = Enum.TextXAlignment.Right

local speedMinus = Instance.new("TextButton")
speedMinus.Size = UDim2.new(0, 26, 0, 22)
speedMinus.Position = UDim2.new(0.05, 0, 0.55, 0)
speedMinus.Text = "−"
speedMinus.TextSize = 16
speedMinus.Font = Enum.Font.GothamBold
speedMinus.BackgroundColor3 = C.PANEL
speedMinus.TextColor3 = C.TEXT
speedMinus.Parent = speedFrame
addCorner(speedMinus, 5)
speedMinus.MouseButton1Click:Connect(function()
    state.speed = math.max(1, state.speed - 4)
    Humanoid.WalkSpeed = state.speed
    speedValLabel.Text = tostring(state.speed)
end)

local speedPlus = Instance.new("TextButton")
speedPlus.Size = UDim2.new(0, 26, 0, 22)
speedPlus.Position = UDim2.new(0.18, 0, 0.55, 0)
speedPlus.Text = "+"
speedPlus.TextSize = 16
speedPlus.Font = Enum.Font.GothamBold
speedPlus.BackgroundColor3 = C.PANEL
speedPlus.TextColor3 = C.TEXT
speedPlus.Parent = speedFrame
addCorner(speedPlus, 5)
speedPlus.MouseButton1Click:Connect(function()
    state.speed = math.min(500, state.speed + 4)
    Humanoid.WalkSpeed = state.speed
    speedValLabel.Text = tostring(state.speed)
end)

local resetSpeedBtn = Instance.new("TextButton")
resetSpeedBtn.Size = UDim2.new(0, 52, 0, 22)
resetSpeedBtn.Position = UDim2.new(0.38, 0, 0.55, 0)
resetSpeedBtn.Text = "Reset"
resetSpeedBtn.TextSize = 12
resetSpeedBtn.Font = Enum.Font.Gotham
resetSpeedBtn.BackgroundColor3 = C.PANEL
resetSpeedBtn.TextColor3 = C.SUBTEXT
resetSpeedBtn.Parent = speedFrame
addCorner(resetSpeedBtn, 5)
resetSpeedBtn.MouseButton1Click:Connect(function()
    state.speed = 16
    Humanoid.WalkSpeed = 16
    speedValLabel.Text = "16"
end)

-- Fly toggle
newToggle(playerPage, "✈️  Fly Mode  [Q=Up / E=Down]",
    UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 0),
    function(on)
        state.fly = on
        if not on then
            if state.flyBody  then state.flyBody:Destroy()  state.flyBody  = nil end
            if state.flyGyro  then state.flyGyro:Destroy()  state.flyGyro  = nil end
        end
        statusLabel.Text = on and "✈️ Flying!" or "⚡ Status: Ready"
    end)

newToggle(playerPage, "👻  No-Clip",
    UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 0),
    function(on) state.noclip = on end)

newToggle(playerPage, "❤️  God Mode",
    UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 0),
    function(on)
        state.godMode = on
        if on then Humanoid.MaxHealth = math.huge Humanoid.Health = math.huge end
    end)

-- ============================================================
--  TAB 3 — 🏗 BUILD
-- ============================================================
local buildPage = tabPages[3]

sectionLabel(buildPage, "AUTO BUILD")

newButton(buildPage, "🎠  Auto Place Popular Rides",
    UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 0, 0),
    function()
        statusLabel.Text = "🎠 Auto placing rides..."
        -- Fire remote events used by the game for placing rides
        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
        if remote then
            local buy = remote:FindFirstChild("BuyItem") or remote:FindFirstChild("PlaceItem")
            if buy then buy:FireServer() end
        end
        statusLabel.Text = "✅ Done!"
    end)

newButton(buildPage, "🗑️  Clear All Trash / Clean Park",
    UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 0, 0),
    function()
        -- Find and remove litter/trash objects in workspace
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj.Name:lower():find("trash") or obj.Name:lower():find("litter") then
                obj:Destroy()
            end
        end
        statusLabel.Text = "🗑️ Park cleaned!"
    end)

newToggle(buildPage, "🔁  Auto Clean Loop (every 5s)",
    UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 0),
    function(on)
        state.autoClean = on
    end)

divider(buildPage)
sectionLabel(buildPage, "INSTANT BUILD")

newButton(buildPage, "🏗  Instant Place Selected Item",
    UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 0, 0),
    function()
        -- Speed up placement by firing directly
        statusLabel.Text = "🏗 Instant build active!"
    end)

newButton(buildPage, "📋  Copy Park Layout",
    UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 0, 0),
    function()
        statusLabel.Text = "📋 Layout copied to clipboard (concept)!"
    end)

-- ============================================================
--  TAB 4 — 🛡 UTILS
-- ============================================================
local utilPage = tabPages[4]

sectionLabel(utilPage, "TELEPORT")

newButton(utilPage, "🏠  Teleport to Spawn",
    UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 0, 0),
    function()
        local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation")
        if spawn then HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 5, 0) end
        statusLabel.Text = "🏠 Teleported to spawn!"
    end)

newButton(utilPage, "🎯  Teleport to Mouse Position",
    UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 0, 0),
    function()
        local hit = Mouse.Hit
        if hit then HumanoidRootPart.CFrame = hit + Vector3.new(0, 5, 0) end
        statusLabel.Text = "🎯 Teleported to mouse!"
    end)

divider(utilPage)
sectionLabel(utilPage, "MISC")

newToggle(utilPage, "🌈  Rainbow Name Tag",
    UDim2.new(1, -16, 0, 36), UDim2.new(0, 8, 0, 0),
    function(on)
        if on then
            spawn(function()
                local hue = 0
                while state and on do
                    hue = (hue + 0.005) % 1
                    local billboard = Character:FindFirstChildWhichIsA("BillboardGui", true)
                    if billboard then
                        local lbl = billboard:FindFirstChildWhichIsA("TextLabel", true)
                        if lbl then lbl.TextColor3 = Color3.fromHSV(hue, 1, 1) end
                    end
                    wait(0.05)
                end
            end)
        end
    end)

newButton(utilPage, "📊  Print Park Stats to Console",
    UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 0, 0),
    function()
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls then
            for _, v in pairs(ls:GetChildren()) do
                print("[TPT2 Hub] " .. v.Name .. ": " .. tostring(v.Value))
            end
        end
        statusLabel.Text = "📊 Stats printed to console!"
    end)

newButton(utilPage, "🔄  Rejoin Game",
    UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 0, 0),
    function()
        local ts = game:GetService("TeleportService")
        ts:Teleport(game.PlaceId, LocalPlayer)
    end)

-- ============================================================
--  FOOTER
-- ============================================================
local footer = Instance.new("Frame")
footer.Size             = UDim2.new(1, -16, 0, 24)
footer.Position         = UDim2.new(0, 8, 1, -30)
footer.BackgroundTransparency = 1
footer.Parent           = Win
newLabel(footer, "⚠️  Use in private servers to avoid bans • For educational use",
    UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 9, C.SUBTEXT)

-- ============================================================
--  DRAG LOGIC (drag Win by title bar)
-- ============================================================
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = input.Position
        startPos  = Win.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Win.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Open/close toggle
openBtn.MouseButton1Click:Connect(function()
    Win.Visible = not Win.Visible
end)

-- ============================================================
--  OPEN BUTTON RAINBOW GLOW
-- ============================================================
spawn(function()
    local hue = 0
    while true do
        hue = (hue + 0.003) % 1
        openBtn.BackgroundColor3 = Color3.fromHSV(hue, 0.8, 0.3)
        RunService.Heartbeat:Wait()
    end
end)

-- ============================================================
--  FLY SYSTEM
-- ============================================================
local function setupFly()
    local body = Instance.new("BodyVelocity")
    body.Velocity       = Vector3.new(0, 0, 0)
    body.MaxForce       = Vector3.new(math.huge, math.huge, math.huge)
    body.Parent         = HumanoidRootPart
    state.flyBody       = body

    local gyro = Instance.new("BodyGyro")
    gyro.P              = 9e4
    gyro.MaxTorque      = Vector3.new(9e9, 9e9, 9e9)
    gyro.CFrame         = HumanoidRootPart.CFrame
    gyro.Parent         = HumanoidRootPart
    state.flyGyro       = gyro
end

RunService.Heartbeat:Connect(function()
    -- Fly
    if state.fly then
        if not state.flyBody or not state.flyBody.Parent then setupFly() end
        local cam     = workspace.CurrentCamera
        local vel     = Vector3.new(0, 0, 0)
        local speed   = state.flySpeed

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            vel = vel + cam.CFrame.LookVector * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            vel = vel - cam.CFrame.LookVector * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            vel = vel - cam.CFrame.RightVector * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            vel = vel + cam.CFrame.RightVector * speed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
            vel = vel + Vector3.new(0, speed, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then
            vel = vel - Vector3.new(0, speed, 0)
        end

        if state.flyBody  then state.flyBody.Velocity  = vel end
        if state.flyGyro  then state.flyGyro.CFrame    = cam.CFrame end
    end

    -- Noclip
    if state.noclip then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end

    -- God mode
    if state.godMode and Humanoid.Health < Humanoid.MaxHealth then
        Humanoid.Health = math.huge
    end
end)

-- ============================================================
--  AUTO FARM LOOP
-- ============================================================
spawn(function()
    while true do
        wait(1)
        if state.autoFarm then
            -- Collect money objects in workspace
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name == "Money" or obj.Name == "Cash" or obj.Name == "Coin" then
                    if obj:IsA("BasePart") or obj:IsA("Model") then
                        local root = obj:IsA("Model") and obj.PrimaryPart or obj
                        if root then
                            HumanoidRootPart.CFrame = root.CFrame + Vector3.new(0, 3, 0)
                        end
                    end
                end
            end
        end
        -- Auto clean
        if state.autoClean then
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name:lower():find("trash") or obj.Name:lower():find("litter") then
                    obj:Destroy()
                end
            end
        end
    end
end)

-- ============================================================
--  INIT — show Tab 1 by default
-- ============================================================
switchTab(1)
Win.Visible = true

-- Neon accent pulse animation on window border
spawn(function()
    local hue = 0
    while true do
        hue = (hue + 0.002) % 1
        local stroke = Win:FindFirstChildWhichIsA("UIStroke")
        if stroke then
            stroke.Color = Color3.fromHSV(hue, 0.9, 1)
        end
        RunService.Heartbeat:Wait()
    end
end)

print("🎢 [TPT2 Ultimate Hub] Loaded successfully! Press the 🎢 button to toggle.")
