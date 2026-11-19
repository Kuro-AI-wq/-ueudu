if not game:IsLoaded() then game.Loaded:Wait() end

local ENV = (getgenv and getgenv()) or _G
if ENV.VL_Cleanup then pcall(ENV.VL_Cleanup) end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local TextService = game:GetService("TextService")
local lp = Players.LocalPlayer

local EASE = Enum.EasingStyle
local WHITE = Color3.new(1, 1, 1)
local GREEN = Color3.fromRGB(52, 199, 89)
local YELLOW = Color3.fromRGB(255, 214, 10)
local RED = Color3.fromRGB(255, 69, 58)

local conns = {}
local function connect(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end

local S = {
    quality = false, shadows = false, textures = false, materials = false,
    effects = false, accessories = false, lightlite = false, nosky = false, noglare = false,
    turbo = false, fpsunlock = false, autoboost = false, bgsave = false,
    fullbright = false, crosshair = false,
    hidenames = false, hideplayers = false, hidescore = false, hidechat = false,
    clock12 = false, joinnotify = false, pingwarn = false, islhover = true,
    afk = false, blur = false, savecfg = false,
}
local V = {fov = 0, theme = 1, hue = -1}

local NAMES = {
    quality = "Низкая графика", shadows = "Тени", textures = "Текстуры", materials = "Материалы",
    effects = "Эффекты", accessories = "Аксессуары", lightlite = "Простое освещение",
    nosky = "Без неба", noglare = "Без бликов", turbo = "Турбо-плавность",
    fpsunlock = "Разблокировка FPS", autoboost = "Авто-буст", bgsave = "Экономия в фоне",
    fullbright = "Яркий свет", crosshair = "Прицел", hidenames = "Скрыть ники",
    hideplayers = "Скрыть игроков", hidescore = "Скрыть табло", hidechat = "Скрыть чат",
    clock12 = "12-часовой формат", joinnotify = "Входы и выходы", pingwarn = "Предупр. о пинге",
    islhover = "Раскрытие по наведению", afk = "Анти-АФК", blur = "Размытие фона",
    savecfg = "Сохранение настроек",
}

local OPT = {"quality", "shadows", "textures", "materials", "effects", "accessories", "lightlite", "nosky", "noglare"}
local GFX = {
    quality = true, shadows = true, textures = true, materials = true, effects = true,
    accessories = true, hideplayers = true, lightlite = true, nosky = true, noglare = true,
}

local F = {}
local TB = {keys = {"shadows", "effects", "lightlite", "materials", "fpsunlock"}, cap = 60, capSet = false, bg = false}

local FX = {ParticleEmitter = true, Trail = true, Smoke = true, Fire = true, Sparkles = true, Beam = true}
local PROTECT = {ball = true, volleyball = true}
local SA_PROPS = {"ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap"}
local GLOSSY = {
    [Enum.Material.Glass] = true, [Enum.Material.Metal] = true, [Enum.Material.DiamondPlate] = true,
    [Enum.Material.Foil] = true, [Enum.Material.Marble] = true, [Enum.Material.Granite] = true,
    [Enum.Material.Ice] = true, [Enum.Material.CorrodedMetal] = true,
}

local saved = setmetatable({}, {__mode = "k"})
local function set(inst, prop, val)
    pcall(function()
        local s = saved[inst]
        if not s then s = {} saved[inst] = s end
        if s[prop] == nil then s[prop] = inst[prop] end
        inst[prop] = val
    end)
end
local function restore(inst, prop)
    local s = saved[inst]
    if s and s[prop] ~= nil then
        local v = s[prop]
        s[prop] = nil
        pcall(function() inst[prop] = v end)
    end
end
local function orig(inst, prop)
    local s = saved[inst]
    if s and s[prop] ~= nil then return s[prop] end
    return inst[prop]
end

local SAVE_FILE = "VL_Glass_Settings_v5.json"
local function saveSettings()
    pcall(function()
        if not writefile then return end
        if S.savecfg then
            writefile(SAVE_FILE, HttpService:JSONEncode({S = S, V = V}))
        else
            writefile(SAVE_FILE, HttpService:JSONEncode({S = {savecfg = false}, V = {}}))
        end
    end)
end
pcall(function()
    if readfile and isfile and isfile(SAVE_FILE) then
        local data = HttpService:JSONDecode(readfile(SAVE_FILE))
        if data and data.S and data.S.savecfg == true then
            for k, v in pairs(data.S) do
                if S[k] ~= nil and type(v) == type(S[k]) then S[k] = v end
            end
            for k, v in pairs(data.V or {}) do
                if V[k] ~= nil and type(v) == type(V[k]) then V[k] = v end
            end
        end
    end
end)

local THEMES = {
    {name = "Тёмная", bg = Color3.fromRGB(16, 18, 28), g2 = Color3.fromRGB(16, 18, 28), bgT = 0.08,
        card = Color3.new(1, 1, 1), cardT = 0.93, text = Color3.new(1, 1, 1), sub = Color3.fromRGB(160, 166, 190),
        accent = Color3.fromRGB(10, 132, 255), accent2 = Color3.fromRGB(94, 92, 230),
        stroke = Color3.new(1, 1, 1), strokeT = 0.86, off = Color3.fromRGB(70, 74, 92)},
    {name = "Светлая", bg = Color3.fromRGB(242, 245, 251), g2 = Color3.fromRGB(226, 232, 246), bgT = 0.05,
        card = Color3.new(1, 1, 1), cardT = 0.2, text = Color3.fromRGB(24, 28, 40), sub = Color3.fromRGB(104, 112, 134),
        accent = Color3.fromRGB(10, 132, 255), accent2 = Color3.fromRGB(94, 110, 255),
        stroke = Color3.new(0, 0, 0), strokeT = 0.9, off = Color3.fromRGB(190, 196, 212)},
    {name = "Неон", bg = Color3.fromRGB(10, 6, 24), g2 = Color3.fromRGB(26, 8, 48), bgT = 0.06,
        card = Color3.fromRGB(150, 80, 255), cardT = 0.9, text = Color3.new(1, 1, 1), sub = Color3.fromRGB(176, 156, 224),
        accent = Color3.fromRGB(0, 235, 200), accent2 = Color3.fromRGB(190, 80, 255),
        stroke = Color3.fromRGB(0, 235, 200), strokeT = 0.78, off = Color3.fromRGB(56, 40, 92)},
    {name = "Закат", bg = Color3.fromRGB(40, 16, 54), g2 = Color3.fromRGB(14, 22, 58), bgT = 0.06,
        card = Color3.new(1, 1, 1), cardT = 0.92, text = Color3.new(1, 1, 1), sub = Color3.fromRGB(198, 172, 212),
        accent = Color3.fromRGB(255, 92, 140), accent2 = Color3.fromRGB(255, 164, 60),
        stroke = Color3.new(1, 1, 1), strokeT = 0.84, off = Color3.fromRGB(86, 60, 104)},
}
if not THEMES[V.theme] then V.theme = 1 end

local P = {}
local function computeP()
    local th = THEMES[V.theme] or THEMES[1]
    for k, v in pairs(th) do P[k] = v end
    if V.hue >= 0 then
        P.accent = Color3.fromHSV(V.hue, 0.72, 1)
        P.accent2 = Color3.fromHSV((V.hue + 0.1) % 1, 0.78, 0.95)
    end
end
computeP()

local reg = {}
local grads = {}
local refreshers = {}
local switches = {}

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do
        if type(v) == "string" and string.sub(v, 1, 1) == "@" then
            local key = string.sub(v, 2)
            reg[#reg + 1] = {o, k, key}
            o[k] = P[key]
        else
            o[k] = v
        end
    end
    o.Parent = parent
    return o
end
local function tw(o, t, props, style, dir)
    local tween = TweenService:Create(o, TweenInfo.new(t, style or EASE.Quint, dir or Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end
local function corner(o, r)
    return new("UICorner", {CornerRadius = r}, o)
end
local function accentGrad(o, rot)
    local g = new("UIGradient", {Color = ColorSequence.new(P.accent, P.accent2), Rotation = rot or 0}, o)
    grads[#grads + 1] = g
    return g
end

local function isProtected(v)
    local p = v
    while p and p ~= Workspace do
        if PROTECT[string.lower(p.Name)] then return true end
        p = p.Parent
    end
    return false
end

local function charOf(v)
    local m = v:FindFirstAncestorOfClass("Model")
    while m do
        local owner = Players:GetPlayerFromCharacter(m) or Players:FindFirstChild(m.Name)
        if m:FindFirstChildOfClass("Humanoid") or owner then return m, owner end
        local p = m.Parent
        m = p and p:FindFirstAncestorOfClass("Model")
    end
end

local function apply(v)
    if v:IsA("Terrain") or isProtected(v) then return end
    local cls = v.ClassName
    if FX[cls] or cls == "Clouds" then
        if S.effects then set(v, "Enabled", false) else restore(v, "Enabled") end
        return
    end
    local isPart = v:IsA("BasePart")
    local isDecal = v:IsA("Decal") or v:IsA("Texture")
    local isSA = cls == "SurfaceAppearance"
    if not (isPart or isDecal or isSA) then return end

    local char, owner = charOf(v)
    if char then
        if isPart then
            if S.shadows then set(v, "CastShadow", false) else restore(v, "CastShadow") end
        end
        if owner and owner ~= lp and (isPart or isDecal) then
            local hide = S.hideplayers or (S.accessories and v:FindFirstAncestorOfClass("Accessory") ~= nil)
            if hide then set(v, "Transparency", 1) else restore(v, "Transparency") end
        end
        return
    end

    if isPart then
        if S.shadows then set(v, "CastShadow", false) else restore(v, "CastShadow") end
        if S.materials then
            set(v, "Material", Enum.Material.SmoothPlastic)
        elseif S.noglare and GLOSSY[orig(v, "Material")] then
            set(v, "Material", Enum.Material.Plastic)
        else
            restore(v, "Material")
        end
        if S.materials or S.noglare then set(v, "Reflectance", 0) else restore(v, "Reflectance") end
        if v:IsA("MeshPart") then
            if S.materials then set(v, "RenderFidelity", Enum.RenderFidelity.Performance) else restore(v, "RenderFidelity") end
            if S.textures then set(v, "TextureID", "") else restore(v, "TextureID") end
        end
    elseif isDecal then
        if S.textures then set(v, "Transparency", 1) else restore(v, "Transparency") end
    else
        for _, p in ipairs(SA_PROPS) do
            local kill = S.textures or (S.noglare and (p == "MetalnessMap" or p == "RoughnessMap"))
            if kill then set(v, p, "") else restore(v, p) end
        end
    end
end

local function lightingFx(v)
    if v.Name == "VLGlassBlur" then return end
    if v:IsA("PostEffect") then
        if S.effects then set(v, "Enabled", false) else restore(v, "Enabled") end
    elseif v:IsA("Atmosphere") then
        if S.effects then set(v, "Density", 0) else restore(v, "Density") end
    elseif v:IsA("Sky") then
        if S.nosky then
            set(v, "CelestialBodiesShown", false)
            set(v, "StarCount", 0)
        else
            restore(v, "CelestialBodiesShown")
            restore(v, "StarCount")
        end
    end
end

local function globalApply()
    pcall(function()
        local r = settings().Rendering
        if S.quality then set(r, "QualityLevel", Enum.QualityLevel.Level01) else restore(r, "QualityLevel") end
    end)
    pcall(function()
        if S.shadows then set(Lighting, "GlobalShadows", false) else restore(Lighting, "GlobalShadows") end
        if S.effects then set(Lighting, "FogEnd", 9e9) else restore(Lighting, "FogEnd") end
        for _, p in ipairs({"EnvironmentDiffuseScale", "ShadowSoftness"}) do
            if S.lightlite then set(Lighting, p, 0) else restore(Lighting, p) end
        end
        if S.lightlite or S.noglare then set(Lighting, "EnvironmentSpecularScale", 0) else restore(Lighting, "EnvironmentSpecularScale") end
    end)
    local t = Workspace:FindFirstChildOfClass("Terrain")
    if t then
        for _, p in ipairs({"WaterWaveSize", "WaterWaveSpeed"}) do
            if S.effects then set(t, p, 0) else restore(t, p) end
        end
        if S.effects or S.noglare then set(t, "WaterReflectance", 0) else restore(t, "WaterReflectance") end
    end
    for _, v in ipairs(Lighting:GetDescendants()) do pcall(lightingFx, v) end
end

local sweeping, again = false, false
local function sweep()
    if sweeping then again = true return end
    sweeping = true
    repeat
        again = false
        local n = 0
        for _, v in ipairs(Workspace:GetDescendants()) do
            pcall(apply, v)
            n = n + 1
            if n % 250 == 0 then task.wait() end
            if again then break end
        end
    until not again
    sweeping = false
end

local function active()
    return S.shadows or S.textures or S.materials or S.effects or S.accessories or S.hideplayers or S.noglare
end

connect(Workspace.DescendantAdded, function(v)
    if active() then task.defer(pcall, apply, v) end
end)
connect(Lighting.DescendantAdded, function(v) task.defer(pcall, lightingFx, v) end)

connect(lp.Idled, function()
    if S.afk then
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:CaptureController()
            vu:ClickButton2(Vector2.new())
        end)
    end
end)

local function applyFullbright()
    pcall(function()
        if S.fullbright then
            set(Lighting, "Brightness", 2.5)
            set(Lighting, "ClockTime", 14)
            set(Lighting, "Ambient", Color3.fromRGB(170, 170, 170))
            set(Lighting, "OutdoorAmbient", Color3.fromRGB(170, 170, 170))
            set(Lighting, "ExposureCompensation", 0)
        else
            for _, p in ipairs({"Brightness", "ClockTime", "Ambient", "OutdoorAmbient", "ExposureCompensation"}) do
                restore(Lighting, p)
            end
        end
    end)
end

local function applyChat()
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, not S.hidechat) end)
end

local function applyNames()
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr ~= lp and plr.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                if S.hidenames then
                    set(hum, "DisplayDistanceType", Enum.HumanoidDisplayDistanceType.None)
                else
                    restore(hum, "DisplayDistanceType")
                end
            end
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BillboardGui") then
                    if S.hidenames then set(d, "Enabled", false) else restore(d, "Enabled") end
                end
            end
        end
    end
end

local hiddenScore = setmetatable({}, {__mode = "k"})
local function isScoreName(g)
    local n = string.lower(g.Name)
    return string.find(n, "score") ~= nil or string.find(n, "tablo") ~= nil
end
local function hideScoreboard(state)
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    if state then
        for _, g in ipairs(pg:GetDescendants()) do
            if g:IsA("GuiObject") and isScoreName(g) and hiddenScore[g] == nil then
                hiddenScore[g] = g.Visible
                g.Visible = false
            end
        end
    else
        for g, vis in pairs(hiddenScore) do
            pcall(function() g.Visible = vis end)
            hiddenScore[g] = nil
        end
    end
end
do
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    if pg then
        connect(pg.DescendantAdded, function(g)
            if S.hidescore and g:IsA("GuiObject") and isScoreName(g) and hiddenScore[g] == nil then
                hiddenScore[g] = g.Visible
                g.Visible = false
            end
        end)
    end
end

pcall(function() RunService:UnbindFromRenderStep("VL_FOV") end)
RunService:BindToRenderStep("VL_FOV", Enum.RenderPriority.Camera.Value + 1, function()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if V.fov > 0 then
        if not TB.origFov then TB.origFov = cam.FieldOfView end
        cam.FieldOfView = V.fov
    elseif TB.origFov then
        cam.FieldOfView = TB.origFov
        TB.origFov = nil
    end
end)

TB.setCap = function(n)
    local ok = false
    if setfpscap then ok = pcall(setfpscap, n) end
    if not ok then
        local sf = setfflag or (getgenv and getgenv().setfflag)
        if sf then ok = pcall(sf, "DFIntTaskSchedulerTargetFps", tostring(n)) end
    end
    return ok
end

local gui = new("ScreenGui", {
    Name = "VLGlassMenu", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
}, nil)
local parentOk = pcall(function()
    gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not parentOk or not gui.Parent then
    gui.Parent = lp:WaitForChild("PlayerGui")
end
local blur = new("BlurEffect", {Name = "VLGlassBlur", Size = 0}, Lighting)
local open = false

local cross = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, Visible = false,
}, gui)
local crossH = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(18, 2), BackgroundColor3 = "@accent", BorderSizePixel = 0,
}, cross)
corner(crossH, UDim.new(1, 0))
local crossV = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(2, 18), BackgroundColor3 = "@accent", BorderSizePixel = 0,
}, cross)
corner(crossV, UDim.new(1, 0))
local crossDot = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(4, 4), BackgroundColor3 = WHITE, BorderSizePixel = 0,
}, cross)
corner(crossDot, UDim.new(1, 0))
reg[#reg + 1] = {crossH, "BackgroundColor3", "accent"}
reg[#reg + 1] = {crossV, "BackgroundColor3", "accent"}

local function label(parent, x, y, w, h, size, font, align)
    return new("TextLabel", {
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1,
        Text = "", RichText = true, Font = font or Enum.Font.GothamMedium, TextSize = size,
        TextColor3 = WHITE, TextXAlignment = align or Enum.TextXAlignment.Left,
    }, parent)
end
local function hex(c) return "#" .. c:ToHex() end
local function fpsColor(f) return f >= 55 and GREEN or (f >= 30 and YELLOW or RED) end
local function pingColor(p) return p <= 80 and GREEN or (p <= 150 and YELLOW or RED) end
local GRAYHEX = "#9aa0b4"

local ISL_W, ISL_H, DET_W, DET_H = 236, 40, 300, 186
local IS = {mode = "idle", pinned = false, hover = false, inn = 0, out = 0, tid = 0, noteW = 236}

local island = new("Frame", {
    Name = "Island", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8),
    Size = UDim2.fromOffset(ISL_W, ISL_H), BackgroundColor3 = Color3.fromRGB(8, 32, 42), BackgroundTransparency = 0.18,
    ClipsDescendants = true, ZIndex = 50,
}, gui)
local islCorner = corner(island, UDim.new(0, 20))
local islStroke = new("UIStroke", {Color = Color3.fromRGB(0, 200, 180), Transparency = 0.55, Thickness = 1.2}, island)
new("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(12, 48, 62), Color3.fromRGB(4, 18, 28)), Rotation = 90}, island)

local idleG = new("CanvasGroup", {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0),
    Size = UDim2.fromOffset(ISL_W, ISL_H), BackgroundTransparency = 1,
}, island)
local idleLbl = new("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, RichText = true, Text = "",
    Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = WHITE,
}, idleG)

local noteG = new("CanvasGroup", {Size = UDim2.new(1, 0, 0, ISL_H), BackgroundTransparency = 1, GroupTransparency = 1}, island)
local noteDot = new("Frame", {
    AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 0.5, 0), Size = UDim2.fromOffset(8, 8),
    BackgroundColor3 = "@accent",
}, noteG)
corner(noteDot, UDim.new(1, 0))
local noteLbl = new("TextLabel", {
    Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -46, 1, 0), BackgroundTransparency = 1, Text = "",
    Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, noteG)

local detG = new("CanvasGroup", {
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0),
    Size = UDim2.fromOffset(DET_W, DET_H), BackgroundTransparency = 1, GroupTransparency = 1,
}, island)
local fpsBig = label(detG, 16, 8, 120, 36, 30, Enum.Font.GothamBold)
local fpsUnit = label(detG, 16, 42, 120, 16, 11, Enum.Font.Gotham)
fpsUnit.Text = '<font color="' .. GRAYHEX .. '">FPS</font>'
local fpsStat = label(detG, 16, 60, 130, 16, 11, Enum.Font.Gotham)
local statLbls = {}
for i = 1, 5 do
    statLbls[i] = label(detG, 150, 10 + (i - 1) * 17, 134, 16, 12, Enum.Font.Gotham, Enum.TextXAlignment.Right)
end
local bars = {}
for i = 1, 24 do
    local b = new("Frame", {
        AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(16 + (i - 1) * 11.2, 124),
        Size = UDim2.fromOffset(8, 3), BackgroundColor3 = GREEN, BorderSizePixel = 0,
    }, detG)
    corner(b, UDim.new(0, 3))
    bars[i] = b
end
local hintLbl = label(detG, 16, 128, 268, 14, 12, Enum.Font.Gotham)
hintLbl.TextTransparency = 1
reg[#reg + 1] = {hintLbl, "TextColor3", "accent"}
hintLbl.TextColor3 = P.accent
local menuBtn = new("TextButton", {
    Position = UDim2.fromOffset(16, 146), Size = UDim2.fromOffset(268, 32),
    BackgroundColor3 = Color3.fromRGB(20, 160, 90), BackgroundTransparency = 0.25,
    Text = "Интерфейс", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = WHITE, AutoButtonColor = false,
}, detG)
corner(menuBtn, UDim.new(1, 0))
new("UIStroke", {Color = Color3.fromRGB(80, 255, 160), Transparency = 0.4, Thickness = 1}, menuBtn)
new("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(30, 200, 110), Color3.fromRGB(10, 120, 70)), Rotation = 90}, menuBtn)
local menuScale = new("UIScale", {}, menuBtn)

local islBtn = new("TextButton", {
    Size = UDim2.new(1, 0, 0, ISL_H), BackgroundTransparency = 1, Text = "", ZIndex = 60, AutoButtonColor = false,
}, island)

-- Drag + edge snap for Dynamic Island (touch & mouse)
local drag = {active = false, startPos = nil, startInput = nil, moved = false}
local SNAP_PAD = 12
local function clampIsland(x, y, w, h)
    local vs = gui.AbsoluteSize
    local minX, maxX = w * 0.5 + SNAP_PAD, vs.X - w * 0.5 - SNAP_PAD
    local minY, maxY = SNAP_PAD, vs.Y - h - SNAP_PAD
    return math.clamp(x, minX, maxX), math.clamp(y, minY, maxY)
end
local function snapIsland()
    local vs = gui.AbsoluteSize
    local ap = island.AbsolutePosition
    local sz = island.AbsoluteSize
    local cx = ap.X + sz.X * 0.5
    local cy = ap.Y
    local w, h = sz.X, sz.Y
    local targets = {
        {x = vs.X * 0.5, y = SNAP_PAD}, -- top center
        {x = vs.X * 0.5, y = vs.Y - h - SNAP_PAD}, -- bottom center
        {x = w * 0.5 + SNAP_PAD, y = SNAP_PAD}, -- top left
        {x = vs.X - w * 0.5 - SNAP_PAD, y = SNAP_PAD}, -- top right
        {x = w * 0.5 + SNAP_PAD, y = vs.Y - h - SNAP_PAD}, -- bottom left
        {x = vs.X - w * 0.5 - SNAP_PAD, y = vs.Y - h - SNAP_PAD}, -- bottom right
    }
    local best, bestD = targets[1], math.huge
    for _, t in ipairs(targets) do
        local d = (t.x - cx) ^ 2 + (t.y - cy) ^ 2
        if d < bestD then bestD, best = d, t end
    end
    -- only snap if reasonably close (within ~120px)
    if bestD < 14000 then
        tw(island, 0.35, {Position = UDim2.fromOffset(best.x, best.y)}, EASE.Back)
    else
        local nx, ny = clampIsland(cx, cy, w, h)
        tw(island, 0.25, {Position = UDim2.fromOffset(nx, ny)}, EASE.Quint)
    end
end
islBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag.active = true
        drag.moved = false
        drag.startInput = Vector2.new(input.Position.X, input.Position.Y)
        local ap = island.AbsolutePosition
        drag.startPos = Vector2.new(ap.X + island.AbsoluteSize.X * 0.5, ap.Y)
    end
end)
connect(UIS.InputChanged, function(input)
    if not drag.active then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - drag.startInput
        if delta.Magnitude > 6 then drag.moved = true end
        if drag.moved then
            local nx = drag.startPos.X + delta.X
            local ny = drag.startPos.Y + delta.Y
            local w = island.AbsoluteSize.X
            local h = island.AbsoluteSize.Y
            nx, ny = clampIsland(nx, ny, w, h)
            island.Position = UDim2.fromOffset(nx, ny)
        end
    end
end)
connect(UIS.InputEnded, function(input)
    if not drag.active then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if drag.moved then
            snapIsland()
            task.delay(0.05, function() drag.moved = false end)
        else
            drag.moved = false
        end
        drag.active = false
    end
end)

local function islSet(mode, force)
    if IS.mode == mode and not force then return end
    IS.mode = mode
    local w, h, r = ISL_W, ISL_H, 20
    if mode == "expanded" then w, h, r = DET_W, DET_H, 28
    elseif mode == "notice" then w = IS.noteW end
    local grow = mode ~= "idle"
    tw(island, grow and 0.55 or 0.4, {Size = UDim2.fromOffset(w, h)}, grow and EASE.Back or EASE.Quint)
    tw(islCorner, 0.4, {CornerRadius = UDim.new(0, r)})
    tw(idleG, 0.2, {GroupTransparency = mode == "idle" and 0 or 1})
    tw(noteG, 0.2, {GroupTransparency = mode == "notice" and 0 or 1})
    tw(detG, mode == "expanded" and 0.35 or 0.15, {GroupTransparency = mode == "expanded" and 0 or 1})
end
F.islSet = islSet

function F.notify(text)
    IS.tid = IS.tid + 1
    local id = IS.tid
    if IS.mode == "expanded" then
        hintLbl.Text = text
        tw(hintLbl, 0.2, {TextTransparency = 0})
        task.delay(2.4, function()
            if id == IS.tid then tw(hintLbl, 0.3, {TextTransparency = 1}) end
        end)
        return
    end
    noteLbl.Text = text
    local w = 236
    pcall(function()
        w = TextService:GetTextSize(text, 14, Enum.Font.GothamMedium, Vector2.new(400, 40)).X + 64
    end)
    IS.noteW = math.clamp(w, 236, 360)
    islSet("notice", true)
    task.delay(2.2, function()
        if id == IS.tid and IS.mode == "notice" then
            islSet(IS.pinned and "expanded" or "idle")
        end
    end)
end

islBtn.Activated:Connect(function()
    if drag.moved then return end
    if IS.mode == "expanded" then
        IS.pinned = false
        IS.hover = false
        islSet("idle")
    else
        IS.pinned = true
        islSet("expanded")
    end
end)
menuBtn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        tw(menuScale, 0.08, {Scale = 0.96})
    end
end)
menuBtn.InputEnded:Connect(function() tw(menuScale, 0.3, {Scale = 1}, EASE.Back) end)
menuBtn.Activated:Connect(function()
    IS.pinned = false
    IS.hover = false
    islSet("idle")
    F.toggleMenu()
end)

local panel = new("CanvasGroup", {
    Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 28),
    Size = UDim2.fromOffset(380, 500), BackgroundColor3 = WHITE, BackgroundTransparency = "@bgT",
    GroupTransparency = 1, Visible = false, ZIndex = 10,
}, gui)
corner(panel, UDim.new(0, 26))
new("UIStroke", {Color = "@stroke", Transparency = "@strokeT", Thickness = 1.2}, panel)
local panelGrad = new("UIGradient", {Color = ColorSequence.new(P.bg, P.g2), Rotation = 70}, panel)
local panelScale = new("UIScale", {Scale = 0.9}, panel)
local sheen = new("Frame", {Size = UDim2.new(1, 0, 0, 120), BackgroundColor3 = WHITE, BorderSizePixel = 0}, panel)
new("UIGradient", {
    Rotation = 90,
    Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.93), NumberSequenceKeypoint.new(1, 1)}),
}, sheen)

new("TextLabel", {
    Position = UDim2.fromOffset(90, 12), Size = UDim2.new(1, -140, 0, 22), BackgroundTransparency = 1,
    Text = "Glass Menu", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = "@text",
    TextXAlignment = Enum.TextXAlignment.Left,
}, panel)
local statsLbl = new("TextLabel", {
    Position = UDim2.fromOffset(90, 34), Size = UDim2.new(1, -140, 0, 16), BackgroundTransparency = 1,
    Text = "", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = "@sub", TextXAlignment = Enum.TextXAlignment.Left,
}, panel)
local closeBtn = new("TextButton", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = "@card", BackgroundTransparency = "@cardT", Text = "×", Font = Enum.Font.GothamBold,
    TextSize = 20, TextColor3 = "@text", AutoButtonColor = false,
}, panel)
corner(closeBtn, UDim.new(1, 0))
closeBtn.Activated:Connect(function() F.toggleMenu() end)

local TAB_NAMES = {"FPS", "Графика", "Вид", "Остров", "Ещё"}
local NT = #TAB_NAMES
local SIDE_W = 78
local tabBar = new("Frame", {
    Position = UDim2.new(0, 10, 0, 58), Size = UDim2.fromOffset(SIDE_W, 420),
    BackgroundColor3 = "@card", BackgroundTransparency = "@cardT",
}, panel)
corner(tabBar, UDim.new(0, 16))
new("UIStroke", {Color = "@stroke", Transparency = "@strokeT", Thickness = 1}, tabBar)
local tabInd = new("Frame", {
    Position = UDim2.new(0, 4, 0, 4), Size = UDim2.new(1, -8, 0, 72), BackgroundColor3 = WHITE,
}, tabBar)
corner(tabInd, UDim.new(0, 12))
accentGrad(tabInd, 90)
local tabBtns = {}
local curTab = 1
local pages = {}
for i = 1, NT do
    tabBtns[i] = new("TextButton", {
        Position = UDim2.new(0, 0, 0, (i - 1) * 80 + 4), Size = UDim2.new(1, 0, 0, 72), BackgroundTransparency = 1,
        Text = TAB_NAMES[i], Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = WHITE, AutoButtonColor = false,
        ZIndex = 3, TextWrapped = true,
    }, tabBar)
    local g = new("CanvasGroup", {
        Position = UDim2.new(0, SIDE_W + 14, 0, 58), Size = UDim2.new(1, -(SIDE_W + 24), 1, -70), BackgroundTransparency = 1, Visible = false,
    }, panel)
    local sf = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = "@accent", AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
    }, g)
    new("UIListLayout", {
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center,
    }, sf)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 10),
    }, sf)
    pages[i] = {g = g, sf = sf, n = 0}
end

local function refreshTabs(animate)
    for i, b in ipairs(tabBtns) do
        local c = (i == curTab) and WHITE or P.sub
        if animate then tw(b, 0.25, {TextColor3 = c}) else b.TextColor3 = c end
    end
end
refreshers[#refreshers + 1] = refreshTabs

local function switchTab(i, instant)
    curTab = i
    for j, pg in ipairs(pages) do
        if j ~= i then pg.g.Visible = false end
    end
    local pg = pages[i]
    pg.sf.CanvasPosition = Vector2.new(0, 0)
    pg.g.Visible = true
    local pos = UDim2.new(0, SIDE_W + 14, 0, 58)
    local posTab = UDim2.new(0, 4, 0, (i - 1) * 80 + 4)
    if instant then
        pg.g.GroupTransparency = 0
        pg.g.Position = pos
        tabInd.Position = posTab
    else
        pg.g.GroupTransparency = 1
        pg.g.Position = UDim2.new(0, SIDE_W + 30, 0, 58)
        tw(pg.g, 0.35, {GroupTransparency = 0, Position = pos})
        tw(tabInd, 0.45, {Position = posTab}, EASE.Back)
    end
    refreshTabs(not instant)
end
for i, b in ipairs(tabBtns) do
    b.Activated:Connect(function() switchTab(i, false) end)
end

local function rowBase(pg, h)
    pg.n = pg.n + 1
    local r = new("Frame", {
        Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = "@card", BackgroundTransparency = "@cardT", LayoutOrder = pg.n,
    }, pg.sf)
    corner(r, UDim.new(0, 14))
    new("UIStroke", {Color = "@stroke", Transparency = "@strokeT", Thickness = 1}, r)
    return r
end

local function rowTexts(r, title, sub, padR)
    local w = -(padR or 20) - 14
    local t = new("TextLabel", {
        Position = UDim2.fromOffset(14, sub and 8 or 0), Size = UDim2.new(1, w, sub and 0 or 1, sub and 20 or 0),
        BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = "@text",
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, r)
    if sub then
        new("TextLabel", {
            Position = UDim2.fromOffset(14, 29), Size = UDim2.new(1, w, 0, 16), BackgroundTransparency = 1, Text = sub,
            Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = "@sub", TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }, r)
    end
    return t
end

local function pressFx(hit, scale)
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            tw(scale, 0.08, {Scale = 0.97})
        end
    end)
    hit.InputEnded:Connect(function() tw(scale, 0.35, {Scale = 1}, EASE.Back) end)
end

local function section(pg, text)
    pg.n = pg.n + 1
    local l = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamBold,
        TextSize = 12, TextColor3 = "@accent", TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = pg.n,
    }, pg.sf)
    new("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingTop = UDim.new(0, 6)}, l)
end

local function addSwitch(pg, key, title, sub)
    local r = rowBase(pg, 58)
    rowTexts(r, title, sub, 80)
    local track = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(46, 26),
        BackgroundColor3 = P.off,
    }, r)
    corner(track, UDim.new(1, 0))
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(20, 20),
        BackgroundColor3 = WHITE,
    }, track)
    corner(knob, UDim.new(1, 0))
    local hit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5}, r)
    local scale = new("UIScale", {}, r)
    pressFx(hit, scale)
    local function refresh(animate)
        local on = S[key]
        local col = on and P.accent or P.off
        local pos = on and UDim2.new(1, -23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        if animate then
            tw(track, 0.25, {BackgroundColor3 = col})
            tw(knob, 0.45, {Position = pos}, EASE.Back)
        else
            track.BackgroundColor3 = col
            knob.Position = pos
        end
    end
    refresh(false)
    refreshers[#refreshers + 1] = refresh
    switches[key] = refresh
    hit.Activated:Connect(function() F.setState(key, not S[key]) end)
end

local function addButton(pg, title, sub, fn, danger)
    local r = rowBase(pg, sub and 58 or 46)
    local t = rowTexts(r, title, sub, 20)
    if danger then t.TextColor3 = RED end
    local hit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5}, r)
    local scale = new("UIScale", {}, r)
    pressFx(hit, scale)
    hit.Activated:Connect(fn)
    return t
end

local function addInfo(pg)
    local r = rowBase(pg, 40)
    return new("TextLabel", {
        Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(14, 0), BackgroundTransparency = 1, Text = "",
        Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = "@sub", TextXAlignment = Enum.TextXAlignment.Left,
    }, r)
end

local function addSegment(pg, title, labels, values, getCur, onSelect)
    local r = rowBase(pg, 82)
    new("TextLabel", {
        Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 20), BackgroundTransparency = 1, Text = title,
        Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = "@text", TextXAlignment = Enum.TextXAlignment.Left,
    }, r)
    local bar = new("Frame", {
        Position = UDim2.new(0, 14, 0, 38), Size = UDim2.new(1, -28, 0, 32), BackgroundColor3 = "@off", BackgroundTransparency = 0.55,
    }, r)
    corner(bar, UDim.new(1, 0))
    local n = #labels
    local ind = new("Frame", {Size = UDim2.new(1 / n, -6, 1, -6), Position = UDim2.new(0, 3, 0, 3), BackgroundColor3 = WHITE}, bar)
    corner(ind, UDim.new(1, 0))
    accentGrad(ind, 0)
    local btns = {}
    local refresh
    for i = 1, n do
        local b = new("TextButton", {
            Position = UDim2.new((i - 1) / n, 0, 0, 0), Size = UDim2.new(1 / n, 0, 1, 0), BackgroundTransparency = 1,
            Text = labels[i], Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = WHITE, AutoButtonColor = false, ZIndex = 3,
        }, bar)
        btns[i] = b
        b.Activated:Connect(function()
            onSelect(values[i])
            refresh(true)
        end)
    end
    refresh = function(animate)
        local cur = getCur()
        local idx
        for i, v in ipairs(values) do
            if v == cur then idx = i end
        end
        ind.Visible = idx ~= nil
        if idx then
            local pos = UDim2.new((idx - 1) / n, 3, 0, 3)
            if animate then tw(ind, 0.45, {Position = pos}, EASE.Back) else ind.Position = pos end
        end
        for i, b in ipairs(btns) do
            local c = (i == idx) and WHITE or P.sub
            if animate then tw(b, 0.25, {TextColor3 = c}) else b.TextColor3 = c end
        end
    end
    refresh(false)
    refreshers[#refreshers + 1] = refresh
end

local function applyTheme(animate)
    computeP()
    for _, e in ipairs(reg) do
        local o, prop, key = e[1], e[2], e[3]
        if animate then
            tw(o, 0.35, {[prop] = P[key]})
        else
            o[prop] = P[key]
        end
    end
    for _, g in ipairs(grads) do g.Color = ColorSequence.new(P.accent, P.accent2) end
    panelGrad.Color = ColorSequence.new(P.bg, P.g2)
    for _, fn in ipairs(refreshers) do fn(animate) end
end

local function addHue(pg)
    local r = rowBase(pg, 82)
    new("TextLabel", {
        Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 20), BackgroundTransparency = 1,
        Text = "Свой акцентный цвет", Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = "@text",
        TextXAlignment = Enum.TextXAlignment.Left,
    }, r)
    local track = new("TextButton", {
        Position = UDim2.new(0, 14, 0, 46), Size = UDim2.new(1, -28, 0, 14), BackgroundColor3 = WHITE, Text = "",
        AutoButtonColor = false,
    }, r)
    corner(track, UDim.new(1, 0))
    local stops = {}
    for i = 0, 6 do
        stops[#stops + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.72, 1))
    end
    new("UIGradient", {Color = ColorSequence.new(stops)}, track)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = WHITE, Visible = false, ZIndex = 4,
    }, track)
    corner(knob, UDim.new(1, 0))
    new("UIStroke", {Color = Color3.new(0, 0, 0), Transparency = 0.7, Thickness = 1.5}, knob)
    local dragging = false
    local function setFromX(x)
        local ap, sz = track.AbsolutePosition, track.AbsoluteSize
        local h = math.clamp((x - ap.X) / math.max(sz.X, 1), 0, 1)
        V.hue = h
        knob.Visible = true
        knob.Position = UDim2.new(h, 0, 0.5, 0)
        applyTheme(false)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(i.Position.X)
        end
    end)
    connect(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setFromX(i.Position.X)
        end
    end)
    connect(UIS.InputEnded, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            saveSettings()
        end
    end)
    local function refresh()
        knob.Visible = V.hue >= 0
        if V.hue >= 0 then knob.Position = UDim2.new(V.hue, 0, 0.5, 0) end
    end
    refresh()
    return refresh
end

local pgFps, pgGfx, pgView, pgIsl, pgMore = pages[1], pages[2], pages[3], pages[4], pages[5]

section(pgFps, "Плавность")
addSwitch(pgFps, "turbo", "Турбо-плавность", "Максимум FPS, картинка остаётся красивой")
addSwitch(pgFps, "fpsunlock", "Разблокировка FPS", "Снимает лимит 60 FPS")
addSwitch(pgFps, "autoboost", "Авто-буст", "Сам облегчит графику при FPS ниже 28")
addSwitch(pgFps, "bgsave", "Экономия в фоне", "FPS 10, пока окно не в фокусе (ПК)")
section(pgFps, "Лимит кадров")
addSegment(pgFps, "Лимит FPS", {"30", "60", "120", "∞"}, {30, 60, 120, 0}, function() return TB.chosen or -1 end, function(c)
    if S.fpsunlock then F.setState("fpsunlock", false, true) end
    local ok = TB.setCap(c == 0 and 999 or c)
    if ok then
        TB.cap = c == 0 and 999 or c
        TB.chosen = c
    end
    F.notify(ok and ("Лимит FPS: " .. (c == 0 and "∞" or tostring(c))) or "Не поддерживается")
end)

local masterLbl
section(pgGfx, "Быстро")
masterLbl = addButton(pgGfx, "Включить всю графику", "Все пункты ниже одним нажатием", function()
    local target = false
    for _, k in ipairs(OPT) do if not S[k] then target = true end end
    task.spawn(function()
        for _, k in ipairs(OPT) do
            if S[k] ~= target then F.setState(k, target, true) end
            task.wait(0.05)
        end
        F.notify(target and "Максимальный буст" or "Графика сброшена")
    end)
end)
function F.refreshMaster()
    local all = true
    for _, k in ipairs(OPT) do if not S[k] then all = false end end
    masterLbl.Text = all and "Выключить всю графику" or "Включить всю графику"
end
section(pgGfx, "Графика")
addSwitch(pgGfx, "quality", "Низкая графика", "Минимальный уровень рендера")
addSwitch(pgGfx, "shadows", "Тени", "Отключить тени")
addSwitch(pgGfx, "textures", "Текстуры", "Убрать текстуры и декали")
addSwitch(pgGfx, "materials", "Материалы и модели", "Простые материалы")
addSwitch(pgGfx, "effects", "Эффекты", "Частицы, туман, блум, вода")
addSwitch(pgGfx, "accessories", "Аксессуары игроков", "Скрыть чужие аксессуары")
section(pgGfx, "Освещение")
addSwitch(pgGfx, "noglare", "Без бликов и отражений", "Матовый пол, без блеска")
addSwitch(pgGfx, "lightlite", "Простое освещение", "Без отражений и мягких теней")
addSwitch(pgGfx, "nosky", "Убрать небо", "Без звёзд, солнца и луны")

section(pgView, "Картинка")
addSwitch(pgView, "fullbright", "Яркий свет", "Убирает тёмные участки карты")
addSwitch(pgView, "crosshair", "Прицел", "Точка в центре экрана")
addSegment(pgView, "Поле зрения (FOV)", {"Выкл", "80", "90", "100", "120"}, {0, 80, 90, 100, 120}, function() return V.fov end, function(v)
    V.fov = v
    saveSettings()
    F.notify(v == 0 and "FOV: по умолчанию" or ("FOV: " .. v))
end)
section(pgView, "Интерфейс игры")
addSwitch(pgView, "hidenames", "Скрыть ники", "Имена над игроками")
addSwitch(pgView, "hideplayers", "Скрыть игроков", "Только на твоём экране")
addSwitch(pgView, "hidescore", "Скрыть табло счёта", "Прячет родное табло")
addSwitch(pgView, "hidechat", "Скрыть чат", "Убирает окно чата Roblox")

section(pgIsl, "Оформление")
local themeNames, themeIdx = {}, {}
for i, t in ipairs(THEMES) do
    themeNames[i] = t.name
    themeIdx[i] = i
end
addSegment(pgIsl, "Тема", themeNames, themeIdx, function() return V.theme end, function(v)
    V.theme = v
    applyTheme(true)
    saveSettings()
end)
local hueRefresh = addHue(pgIsl)
addButton(pgIsl, "Цвет темы", "Вернуть акцент выбранной темы", function()
    V.hue = -1
    hueRefresh()
    applyTheme(true)
    saveSettings()
end)
section(pgIsl, "Остров")
addSwitch(pgIsl, "islhover", "Раскрытие по наведению", "ПК: наведи курсор на Остров")
addSwitch(pgIsl, "clock12", "12-часовой формат", "Время с AM/PM")
addSwitch(pgIsl, "joinnotify", "Входы и выходы", "Уведомление в Острове")
addSwitch(pgIsl, "pingwarn", "Предупреждение о пинге", "Если пинг выше 150")

section(pgMore, "Система")
addSwitch(pgMore, "afk", "Анти-АФК", "Не кикает за бездействие")
addSwitch(pgMore, "blur", "Размытие фона", "Матовое стекло при открытом меню")
addSwitch(pgMore, "savecfg", "Сохранять настройки", "Иначе при запуске всё выключено")

local function panic()
    for k in pairs(S) do
        if k ~= "savecfg" and k ~= "islhover" and S[k] then F.setState(k, false, true) end
    end
    if open then F.toggleMenu() end
    F.notify("Всё выключено")
end
addButton(pgMore, "Выключить всё (End)", "Мгновенно отключает все функции", panic, true)
addButton(pgMore, "Выгрузить скрипт", "Полностью убрать меню и эффекты", function()
    if ENV.VL_Cleanup then ENV.VL_Cleanup() end
end, true)

section(pgMore, "Сервер")
local srvInfo = addInfo(pgMore)
addButton(pgMore, "Перезайти", "На этот же сервер", function()
    F.notify("Перезаход...")
    pcall(function()
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, lp)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
        end
    end)
end)
addButton(pgMore, "Другой сервер", "Перейти на другой публичный сервер", function()
    task.spawn(function()
        F.notify("Ищу сервер...")
        local ok, body = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")
        end)
        if not ok then F.notify("HTTP недоступен в этом исполнителе") return end
        local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
        if not (ok2 and data and data.data) then F.notify("Не удалось получить список") return end
        local best
        for _, s in ipairs(data.data) do
            if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers - 1 then
                if not best or s.playing > best.playing then best = s end
            end
        end
        if not best then F.notify("Подходящих серверов нет") return end
        F.notify("Телепорт...")
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, lp) end)
    end)
end)
addButton(pgMore, "Скопировать JobId", "ID текущего сервера в буфер", function()
    local ok = pcall(function()
        local f = setclipboard or toclipboard
        f(game.JobId)
    end)
    F.notify(ok and "JobId скопирован" or "Буфер недоступен")
end)

local boosted = nil
local function setState(key, val, quiet)
    S[key] = val
    if switches[key] then switches[key](true) end
    if key == "blur" and open then tw(blur, 0.25, {Size = val and 14 or 0}) end
    if key == "hidescore" then hideScoreboard(val) end
    if key == "hidechat" then applyChat() end
    if key == "fullbright" then applyFullbright() end
    if key == "hidenames" then applyNames() end
    if key == "crosshair" then cross.Visible = val end
    if key == "fpsunlock" then
        local ok = TB.setCap(val and 999 or TB.cap)
        TB.capSet = val and ok
        if val and not ok then F.notify("FPS: не поддерживается исполнителем") end
    end
    if key == "turbo" then
        if val then
            TB.set = {}
            for _, k in ipairs(TB.keys) do
                if not S[k] then
                    TB.set[#TB.set + 1] = k
                    setState(k, true, true)
                end
            end
        else
            for _, k in ipairs(TB.set or TB.keys) do setState(k, false, true) end
            TB.set = nil
        end
    end
    if key == "autoboost" and not val and boosted then
        for _, k in ipairs(boosted) do setState(k, false, true) end
        boosted = nil
    end
    if not quiet then F.notify(NAMES[key] .. (val and ": вкл" or ": выкл")) end
    F.refreshMaster()
    saveSettings()
    if GFX[key] then
        task.spawn(function() globalApply() sweep() end)
    end
end
F.setState = setState

local function placePanel()
    local vs = gui.AbsoluteSize
    panel.Size = UDim2.fromOffset(math.min(380, vs.X - 16), math.min(500, vs.Y - 90))
end

function F.toggleMenu()
    open = not open
    menuBtn.Text = open and "Закрыть" or "Интерфейс"
    if open then
        placePanel()
        panel.Visible = true
        panel.GroupTransparency = 1
        panel.Position = UDim2.new(0.5, 0, 0.5, 48)
        panelScale.Scale = 0.86
        tw(panel, 0.3, {GroupTransparency = 0})
        tw(panel, 0.55, {Position = UDim2.new(0.5, 0, 0.5, 28)})
        tw(panelScale, 0.55, {Scale = 1}, EASE.Back)
        if S.blur then tw(blur, 0.3, {Size = 14}) end
        tw(islStroke, 0.3, {Color = Color3.fromRGB(0, 220, 190), Transparency = 0.25})
    else
        tw(panel, 0.22, {GroupTransparency = 1})
        tw(panelScale, 0.22, {Scale = 0.9}, EASE.Quad, Enum.EasingDirection.In)
        tw(blur, 0.2, {Size = 0})
        tw(islStroke, 0.3, {Color = Color3.fromRGB(0, 200, 180), Transparency = 0.55})
        task.delay(0.24, function()
            if not open then panel.Visible = false end
        end)
    end
end

local function fmtTime(sec)
    sec = math.floor(sec)
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%02d:%02d", m, s)
end

local function readPing()
    local p
    pcall(function() p = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
    if not p then pcall(function() p = lp:GetNetworkPing() * 1000 end) end
    return p or 0
end

local L = {frames = 0, t0 = os.clock(), start = os.clock(), fps = 60, ping = 0, ema = nil, hist = {},
    slow = 0, low = 0, hp = 0, lpw = 0}

local function updateIsland()
    local f, p = L.fps, L.ping
    local clock = os.date(S.clock12 and "%I:%M %p" or "%H:%M")
    idleLbl.Text = string.format(
        '<font color="%s"><b>%d</b></font> <font color="%s">FPS</font>   %s   <font color="%s"><b>%d</b></font> <font color="%s">мс</font>',
        hex(fpsColor(f)), f, GRAYHEX, clock, hex(pingColor(p)), p, GRAYHEX)
    if open then
        statsLbl.Text = string.format("FPS %d  •  Пинг %d мс  •  %s", f, p, clock)
        srvInfo.Text = string.format("Игроков %d/%d  •  Аптайм %s", #Players:GetPlayers(), Players.MaxPlayers, fmtTime(Workspace.DistributedGameTime))
    end
    if IS.mode ~= "expanded" then return end
    local sum, mn, n = 0, 9999, #L.hist
    for _, v in ipairs(L.hist) do
        sum = sum + v
        if v < mn then mn = v end
    end
    if n == 0 then mn = f; sum = f; n = 1 end
    local mem = 0
    pcall(function() mem = Stats:GetTotalMemoryUsageMb() end)
    fpsBig.Text = string.format('<font color="%s">%d</font>', hex(fpsColor(f)), f)
    fpsStat.Text = string.format('<font color="%s">ср %d · мин %d</font>', GRAYHEX, math.floor(sum / n + 0.5), mn)
    statLbls[1].Text = string.format('<font color="%s">Пинг</font>  <font color="%s"><b>%d</b></font> мс', GRAYHEX, hex(pingColor(p)), p)
    statLbls[2].Text = string.format('<font color="%s">Память</font>  <b>%d</b> МБ', GRAYHEX, math.floor(mem + 0.5))
    statLbls[3].Text = string.format('<font color="%s">Игроков</font>  <b>%d/%d</b>', GRAYHEX, #Players:GetPlayers(), Players.MaxPlayers)
    statLbls[4].Text = string.format('<font color="%s">Сессия</font>  <b>%s</b>', GRAYHEX, fmtTime(os.clock() - L.start))
    statLbls[5].Text = string.format('<font color="%s">Время</font>  <b>%s</b>', GRAYHEX, clock)
    local ref = 60
    for _, v in ipairs(L.hist) do
        if v > ref then ref = v end
    end
    local nh = #L.hist
    for i, b in ipairs(bars) do
        local v = L.hist[nh - 24 + i] or 0
        local hgt = math.max(3, math.floor(26 * math.min(v / ref, 1)))
        tw(b, 0.35, {Size = UDim2.fromOffset(8, hgt), BackgroundColor3 = fpsColor(v)})
    end
end

local function mouseOverIsland()
    if not UIS.MouseEnabled then return false end
    local m = UIS:GetMouseLocation()
    local ap, sz = island.AbsolutePosition, island.AbsoluteSize
    return m.X >= ap.X - 8 and m.X <= ap.X + sz.X + 8 and m.Y >= ap.Y - 8 and m.Y <= ap.Y + sz.Y + 8
end

connect(RunService.Heartbeat, function(dt)
    L.frames = L.frames + 1
    local now = os.clock()
    if now - L.t0 >= 0.5 then
        L.fps = math.floor(L.frames / (now - L.t0) + 0.5)
        local p = readPing()
        L.ema = L.ema and (L.ema * 0.5 + p * 0.5) or p
        L.ping = math.floor(L.ema + 0.5)
        L.frames = 0
        L.t0 = now
        L.hist[#L.hist + 1] = L.fps
        if #L.hist > 120 then table.remove(L.hist, 1) end
        updateIsland()

        if S.autoboost then
            if L.fps < 28 then L.low = L.low + 1 else L.low = 0 end
            if L.low >= 4 and not boosted then
                boosted = {}
                for _, k in ipairs({"quality", "shadows", "effects"}) do
                    if not S[k] then
                        boosted[#boosted + 1] = k
                        setState(k, true, true)
                    end
                end
                F.notify("Авто-буст включён")
            end
        else
            L.low = 0
        end

        if S.pingwarn then
            if L.ping > 150 then L.hp = L.hp + 1 else L.hp = 0 end
            if L.hp >= 3 and now - L.lpw > 20 then
                L.lpw = now
                F.notify("Высокий пинг: " .. L.ping .. " мс")
            end
        end

        if S.hidescore then
            for g in pairs(hiddenScore) do
                if g.Parent and g.Visible then g.Visible = false end
            end
        end
    end

    L.slow = L.slow + dt
    if L.slow >= 1 then
        L.slow = 0
        if S.fullbright then applyFullbright() end
        if S.fpsunlock then TB.setCap(999) end
        if S.hidenames then applyNames() end
    end

    if S.islhover then
        if mouseOverIsland() then
            IS.out = 0
            IS.inn = IS.inn + dt
            if IS.inn >= 0.12 and IS.mode == "idle" and not open then
                IS.hover = true
                islSet("expanded")
            end
        else
            IS.inn = 0
            if IS.mode == "expanded" and IS.hover and not IS.pinned then
                IS.out = IS.out + dt
                if IS.out >= 0.3 then
                    IS.hover = false
                    islSet("idle")
                end
            end
        end
    end
end)

connect(UIS.InputBegan, function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        F.toggleMenu()
    elseif input.KeyCode == Enum.KeyCode.End then
        panic()
    end
end)

connect(Players.PlayerAdded, function(p)
    if S.joinnotify then F.notify(p.DisplayName .. " зашёл") end
end)
connect(Players.PlayerRemoving, function(p)
    if S.joinnotify then F.notify(p.DisplayName .. " вышел") end
end)

connect(UIS.WindowFocusReleased, function()
    if S.bgsave and setfpscap then
        TB.bg = true
        pcall(setfpscap, 10)
    end
end)
connect(UIS.WindowFocused, function()
    if TB.bg then
        TB.bg = false
        pcall(setfpscap, S.fpsunlock and 999 or TB.cap)
    end
end)

for _, fn in ipairs(refreshers) do fn(false) end
applyTheme(false)
switchTab(1, true)
if S.crosshair then cross.Visible = true end
if S.hidescore then hideScoreboard(true) end
if S.hidechat then applyChat() end
if S.fullbright then applyFullbright() end
if S.fpsunlock then TB.capSet = TB.setCap(999) end
for k in pairs(GFX) do
    if S[k] then
        task.spawn(function() globalApply() sweep() end)
        break
    end
end
F.refreshMaster()
updateIsland()

ENV.VL_Cleanup = function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep("VL_FOV") end)
    if TB.capSet or TB.bg then pcall(TB.setCap, TB.cap) end
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam and TB.origFov then cam.FieldOfView = TB.origFov end
    end)
    for k in pairs(S) do S[k] = false end
    hideScoreboard(false)
    applyChat()
    applyFullbright()
    applyNames()
    pcall(globalApply)
    for _, v in ipairs(Workspace:GetDescendants()) do pcall(apply, v) end
    pcall(function() blur:Destroy() end)
    pcall(function() gui:Destroy() end)
    ENV.VL_Cleanup = nil
end

task.delay(0.4, function()
    F.notify("Glass Menu v5 готов")
end)

print("[VL Glass] v5 Loaded successfully")
