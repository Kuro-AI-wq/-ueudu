--[[ Volleyball Legends | Glass Menu v3.1
     - ВСЕ функции выключены при запуске (Island остаётся как кнопка меню)
     - Dynamic Island: FPS | время | пинг, прилипает к верхнему краю экрана
     - Исправлен лаг/высокий пинг (кэш мяча, троттлинг, без сканов каждый кадр)
     - +20 новых функций (см. вкладки)
     Горячие клавиши: RightShift - меню, End - выключить всё (паника)
]]

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
local ACCENT, ACCENT2, EASE, GFX, GRAY, GREEN, NAMES, OFFC, OPT, RED, S, THEMES, TeleportService, V, WHITE, YELLOW, apply, applyChat, applyFullbright, applyNames, ballEsp, clearBallFx, clearLookBeam, clearOutline, connect, conns, globalApply, hiddenScore, hideGameScoreboard, landMarker, lastBall, lookBeams, lp, outlines, saveSettings, sweep, trailData, updateBall, updateLookBeams, updateOutlines
do
local StarterGui = game:GetService("StarterGui")
TeleportService = game:GetService("TeleportService")
lp = Players.LocalPlayer

conns = {}
function connect(sig, fn)
    local c = sig:Connect(fn)
    table.insert(conns, c)
    return c
end

-- ========== STATE (всё выключено по умолчанию) ==========
S = {
    -- оптимизация
    quality = false, shadows = false, textures = false, materials = false,
    effects = false, accessories = false, autoboost = false, turbo = false, fpsunlock = false,
    lightlite = false, nosky = false, bgsave = false,
    -- визуал
    lookbeams = false, ballesp = false, ballmarker = false, balltrail = false,
    teamoutlines = false, fullbright = false, crosshair = false,
    hidenames = false, hideplayers = false, hidescore = false, hidechat = false,
    -- инфо под Island
    balldist = false, ballspeed = false, session = false, extstats = false, showscore = false,
    -- голы
    goalfx = false,
    -- утилиты
    afk = false, blur = false, joinnotify = false, pingwarn = false,
    clock12 = false, savecfg = false,
    -- Island = кнопка меню, поэтому видим сразу
    dynamicisland = true,
}

V = {fov = 0, theme = 1, islx = 0.5, isly = 12, docked = true, side = 1}

NAMES = {
    quality = "Низкая графика", shadows = "Тени", textures = "Текстуры",
    materials = "Материалы", effects = "Эффекты", accessories = "Аксессуары",
    autoboost = "Авто-буст", turbo = "Турбо-плавность", fpsunlock = "Разблокировка FPS", lightlite = "Простое освещение", nosky = "Убрать небо",
    bgsave = "Экономия в фоне", goalfx = "Эффекты голов", lookbeams = "Лучи взгляда", ballesp = "Ball ESP",
    ballmarker = "Маркер падения", balltrail = "След мяча", teamoutlines = "Контуры врагов",
    fullbright = "Яркий свет", crosshair = "Прицел", hidenames = "Скрыть ники",
    hideplayers = "Скрыть игроков", hidescore = "Скрыть табло", hidechat = "Скрыть чат",
    balldist = "Дистанция до мяча", ballspeed = "Скорость мяча", session = "Таймер сессии",
    extstats = "Расш. статистика", showscore = "Счёт под Island", afk = "Анти-АФК",
    blur = "Размытие фона", joinnotify = "Входы/выходы", pingwarn = "Предупр. о пинге",
    clock12 = "12-часовой формат", savecfg = "Сохранять настройки", dynamicisland = "Dynamic Island",
}

OPT = {"quality", "shadows", "textures", "materials", "effects", "accessories", "lightlite", "nosky"}
GFX = {quality = true, shadows = true, textures = true, materials = true,
             effects = true, accessories = true, hideplayers = true,
             lightlite = true, nosky = true}

local FX = {ParticleEmitter = true, Trail = true, Smoke = true, Fire = true, Sparkles = true, Beam = true}
local PROTECT = {ball = true, volleyball = true}
local SA_PROPS = {"ColorMap", "MetalnessMap", "NormalMap", "RoughnessMap"}

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

-- Сохранение: только если включено "Сохранять настройки" (иначе всегда старт с нуля)
local SAVE_FILE = "VL_Glass_Settings_v3.json"
function saveSettings()
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

-- ========== THEME ==========
THEMES = {
    {"Синий", Color3.fromRGB(10, 132, 255), Color3.fromRGB(90, 90, 230)},
    {"Фиолетовый", Color3.fromRGB(160, 100, 255), Color3.fromRGB(110, 70, 220)},
    {"Розовый", Color3.fromRGB(255, 80, 140), Color3.fromRGB(220, 60, 200)},
    {"Зелёный", Color3.fromRGB(52, 199, 89), Color3.fromRGB(20, 160, 140)},
    {"Оранжевый", Color3.fromRGB(255, 159, 10), Color3.fromRGB(255, 95, 60)},
}
if not THEMES[V.theme] then V.theme = 1 end

WHITE = Color3.new(1, 1, 1)
GRAY = Color3.fromRGB(160, 166, 190)
ACCENT, ACCENT2 = THEMES[V.theme][2], THEMES[V.theme][3]
GREEN = Color3.fromRGB(52, 199, 89)
YELLOW = Color3.fromRGB(255, 214, 10)
OFFC = Color3.fromRGB(70, 74, 92)
RED = Color3.fromRGB(255, 69, 58)
EASE = Enum.EasingStyle

-- ========== OPTIMIZATION ==========
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

function apply(v)
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
            set(v, "Reflectance", 0)
        else
            restore(v, "Material")
            restore(v, "Reflectance")
        end
        if v:IsA("MeshPart") then
            if S.materials then set(v, "RenderFidelity", Enum.RenderFidelity.Performance) else restore(v, "RenderFidelity") end
            if S.textures then set(v, "TextureID", "") else restore(v, "TextureID") end
        end
    elseif isDecal then
        if S.textures then set(v, "Transparency", 1) else restore(v, "Transparency") end
    else
        for _, p in ipairs(SA_PROPS) do
            if S.textures then set(v, p, "") else restore(v, p) end
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

function globalApply()
    pcall(function()
        local r = settings().Rendering
        if S.quality then set(r, "QualityLevel", Enum.QualityLevel.Level01) else restore(r, "QualityLevel") end
    end)
    pcall(function()
        if S.shadows then set(Lighting, "GlobalShadows", false) else restore(Lighting, "GlobalShadows") end
        if S.effects then set(Lighting, "FogEnd", 9e9) else restore(Lighting, "FogEnd") end
        for _, p in ipairs({"EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ShadowSoftness"}) do
            if S.lightlite then set(Lighting, p, 0) else restore(Lighting, p) end
        end
    end)
    local t = Workspace:FindFirstChildOfClass("Terrain")
    if t then
        for _, p in ipairs({"WaterWaveSize", "WaterWaveSpeed", "WaterReflectance"}) do
            if S.effects then set(t, p, 0) else restore(t, p) end
        end
    end
    for _, v in ipairs(Lighting:GetDescendants()) do pcall(lightingFx, v) end
end

local sweeping, again = false, false
function sweep()
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
    return S.shadows or S.textures or S.materials or S.effects or S.accessories or S.hideplayers
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

-- ========== VISUAL FEATURES ==========
local function isEnemy(plr)
    if plr == lp then return false end
    if plr.Team and lp.Team and plr.Team == lp.Team then return false end
    return true
end

-- Look beams
lookBeams = {}
function clearLookBeam(plr)
    local d = lookBeams[plr]
    if d then
        pcall(function() d.beam:Destroy() end)
        pcall(function() d.att0:Destroy() end)
        pcall(function() d.att1:Destroy() end)
        lookBeams[plr] = nil
    end
end

function updateLookBeams()
    if not S.lookbeams then
        for plr in pairs(lookBeams) do clearLookBeam(plr) end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if not isEnemy(plr) then
            clearLookBeam(plr)
        else
            local char = plr.Character
            local head = char and char:FindFirstChild("Head")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local origin = head or hrp
            if not origin then
                clearLookBeam(plr)
            else
                local data = lookBeams[plr]
                if not data or data.parent ~= origin or not origin:IsDescendantOf(Workspace) then
                    if data then clearLookBeam(plr) end
                    local att0 = Instance.new("Attachment")
                    att0.Name = "VL_Look0"
                    att0.Parent = origin
                    local att1 = Instance.new("Attachment")
                    att1.Name = "VL_Look1"
                    att1.Parent = origin
                    local beam = Instance.new("Beam")
                    beam.Name = "VL_LookBeam"
                    beam.Attachment0 = att0
                    beam.Attachment1 = att1
                    beam.Width0 = 0.12
                    beam.Width1 = 0.03
                    beam.FaceCamera = true
                    beam.Color = ColorSequence.new(Color3.fromRGB(255, 70, 130))
                    beam.Transparency = NumberSequence.new(0.05, 0.7)
                    beam.LightEmission = 0.85
                    beam.Parent = origin
                    data = {att0 = att0, att1 = att1, beam = beam, parent = origin}
                    lookBeams[plr] = data
                end
                local look = (head and head.CFrame.LookVector) or hrp.CFrame.LookVector
                data.att0.Position = Vector3.new(0, 0.25, 0)
                data.att1.Position = look * 4.5 + Vector3.new(0, 0.25, 0)
            end
        end
    end
end
connect(Players.PlayerRemoving, function(plr) clearLookBeam(plr) end)

-- Enemy outlines (исправлено: пересоздаётся после респавна)
outlines = {}
function clearOutline(plr)
    local o = outlines[plr]
    if o then pcall(function() o:Destroy() end) outlines[plr] = nil end
end

function updateOutlines()
    if not S.teamoutlines then
        for plr in pairs(outlines) do clearOutline(plr) end
        return
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        local char = plr.Character
        if not isEnemy(plr) or not char then
            clearOutline(plr)
        else
            local o = outlines[plr]
            if not o or o.Parent ~= char then
                clearOutline(plr)
                local hl = Instance.new("Highlight")
                hl.Name = "VL_Outline"
                hl.FillTransparency = 0.8
                hl.OutlineTransparency = 0.05
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillColor = Color3.fromRGB(255, 60, 80)
                hl.OutlineColor = Color3.fromRGB(255, 100, 120)
                hl.Parent = char
                outlines[plr] = hl
                o = hl
            end
            if plr.Team then
                o.FillColor = plr.Team.TeamColor.Color
                o.OutlineColor = plr.Team.TeamColor.Color
            end
        end
    end
end
connect(Players.PlayerRemoving, function(plr) clearOutline(plr) end)

-- ========== BALL (кэш вместо поиска по всему Workspace каждый кадр) ==========
ballEsp, landMarker, trailData = nil, nil, nil
lastBall = nil
local ballCache, lastScan = nil, 0
local groundCache, groundT = 0, 0

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local function asPart(x)
    if not x then return nil end
    if x:IsA("BasePart") then return x end
    if x:IsA("Model") then return x.PrimaryPart or x:FindFirstChildWhichIsA("BasePart", true) end
    return nil
end

local function sizeOk(p)
    local m = p.Size.Magnitude
    return m < 12 and m > 0.4
end

local function findBall()
    if ballCache and ballCache.Parent and ballCache:IsDescendantOf(Workspace) then
        return ballCache
    end
    ballCache = nil
    local now = os.clock()
    if now - lastScan < 2 then return nil end
    lastScan = now
    for _, nm in ipairs({"Ball", "Volleyball", "ball", "volleyball"}) do
        local p = asPart(Workspace:FindFirstChild(nm, true))
        if p and sizeOk(p) and not charOf(p) then ballCache = p return p end
    end
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n = string.lower(v.Name)
            if string.find(n, "ball") and sizeOk(v) and not charOf(v) then
                ballCache = v
                return v
            end
        end
    end
    return nil
end

local function groundBelow(pos, ball)
    local ign = {ball}
    if landMarker then ign[#ign + 1] = landMarker end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then ign[#ign + 1] = p.Character end
    end
    rayParams.FilterDescendantsInstances = ign
    local r = Workspace:Raycast(pos, Vector3.new(0, -300, 0), rayParams)
    return r and r.Position.Y or 0
end

local function clearTrail()
    if trailData then
        pcall(function() trailData.trail:Destroy() end)
        pcall(function() trailData.a0:Destroy() end)
        pcall(function() trailData.a1:Destroy() end)
        trailData = nil
    end
end

function clearBallFx()
    if ballEsp then pcall(function() ballEsp:Destroy() end) ballEsp = nil end
    if landMarker then pcall(function() landMarker:Destroy() end) landMarker = nil end
    clearTrail()
end

function updateBall()
    local want = S.ballesp or S.ballmarker or S.balltrail or S.balldist or S.ballspeed
    local ball = want and findBall() or nil
    lastBall = ball
    if not ball then clearBallFx() return end

    -- ESP
    if S.ballesp then
        if not ballEsp or ballEsp.Parent ~= ball then
            if ballEsp then pcall(function() ballEsp:Destroy() end) end
            local hl = Instance.new("Highlight")
            hl.Name = "VL_BallESP"
            hl.FillColor = Color3.fromRGB(255, 210, 60)
            hl.OutlineColor = Color3.fromRGB(255, 255, 120)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = ball
            ballEsp = hl
        end
    elseif ballEsp then
        pcall(function() ballEsp:Destroy() end)
        ballEsp = nil
    end

    -- Trail (след мяча)
    if S.balltrail then
        if not trailData or trailData.trail.Parent ~= ball then
            clearTrail()
            local r = math.max(ball.Size.X, ball.Size.Y) / 2
            local a0 = Instance.new("Attachment")
            a0.Name = "VL_T0"
            a0.Position = Vector3.new(0, r * 0.8, 0)
            a0.Parent = ball
            local a1 = Instance.new("Attachment")
            a1.Name = "VL_T1"
            a1.Position = Vector3.new(0, -r * 0.8, 0)
            a1.Parent = ball
            local tr = Instance.new("Trail")
            tr.Name = "VL_Trail"
            tr.Attachment0 = a0
            tr.Attachment1 = a1
            tr.Lifetime = 0.4
            tr.MinLength = 0.05
            tr.LightEmission = 0.8
            tr.FaceCamera = true
            tr.Color = ColorSequence.new(ACCENT)
            tr.Transparency = NumberSequence.new(0.2, 1)
            tr.WidthScale = NumberSequence.new(1, 0)
            tr.Parent = ball
            trailData = {trail = tr, a0 = a0, a1 = a1}
        end
    else
        clearTrail()
    end

    -- Маркер падения (теперь плоский диск на земле + raycast до пола)
    if S.ballmarker then
        if not landMarker or not landMarker.Parent then
            local m = Instance.new("Part")
            m.Name = "VL_LandMarker"
            m.Anchored = true
            m.CanCollide = false
            m.CanQuery = false
            m.CanTouch = false
            m.CastShadow = false
            m.Size = Vector3.new(0.15, 2.6, 2.6)
            m.Shape = Enum.PartType.Cylinder
            m.Material = Enum.Material.Neon
            m.Color = ACCENT
            m.Transparency = 1
            m.Parent = Workspace
            landMarker = m
        end
        local vel = ball.AssemblyLinearVelocity
        if vel.Magnitude > 0.4 then
            local now = os.clock()
            if now - groundT > 0.25 then
                groundT = now
                groundCache = groundBelow(ball.Position, ball)
            end
            local rad = ball.Size.Y / 2
            local g = Vector3.new(0, -Workspace.Gravity, 0)
            local p, v, t, dt = ball.Position, vel, 0, 0.03
            while t < 4 do
                v = v + g * dt
                p = p + v * dt
                t = t + dt
                if p.Y <= groundCache + rad and v.Y < 0 then break end
            end
            landMarker.Transparency = 0.25
            landMarker.CFrame = CFrame.new(p.X, groundCache + 0.08, p.Z) * CFrame.Angles(0, 0, math.rad(90))
        else
            landMarker.Transparency = 1
        end
    elseif landMarker then
        pcall(function() landMarker:Destroy() end)
        landMarker = nil
    end
end

-- ========== EXTRA FEATURES ==========
function applyFullbright()
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

function applyChat()
    pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, not S.hidechat) end)
end

function applyNames()
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

-- Скрыть родное табло (узкие ключевые слова, чтобы не прятать весь HUD)
hiddenScore = setmetatable({}, {__mode = "k"})
local function isScoreName(gui)
    local n = string.lower(gui.Name)
    return string.find(n, "score") ~= nil or string.find(n, "tablo") ~= nil
end
function hideGameScoreboard(state)
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    if state then
        for _, gui in ipairs(pg:GetDescendants()) do
            if gui:IsA("GuiObject") and isScoreName(gui) and hiddenScore[gui] == nil then
                hiddenScore[gui] = gui.Visible
                gui.Visible = false
            end
        end
    else
        for gui, vis in pairs(hiddenScore) do
            pcall(function() gui.Visible = vis end)
            hiddenScore[gui] = nil
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
end

-- Чтение счёта (с кэшем метки: полный скан PlayerGui максимум раз в 2 с)
local lastScore = "0-0"
local scoreLabel, scoreScanT = nil, 0
local prevA, prevB = nil, nil
local goalFx

local function parseScore(txt)
    local t = string.gsub(txt, "%s+", "")
    local a, b = string.match(t, "^(%d+)[-:/](%d+)$")
    if a and b then return tonumber(a), tonumber(b) end
end

local DOCK_EXTRA, EAR, ISL_H, ISL_W, ISL_W_DOCK, applyTheme, blur, clockText, corner, currentTab, gui, highlightTab, infoLbl, islCurY, islFX, islFloatY, islGlow, islShake, island, islandDocked, new, notify, open, origFov, pollScore, refreshMaster, setDocked, setState, shimmer, styleIsland, switchTab, themedPills, toggleMenu, tw, updateIsland
do
local function readScoreNums(now)
    if scoreLabel and scoreLabel.Parent then
        local a, b = parseScore(scoreLabel.Text)
        if a then return a, b end
    end
    scoreLabel = nil
    if now - scoreScanT < 2 then return nil end
    scoreScanT = now
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    local best, bestSize = nil, 0
    for _, v in ipairs(pg:GetDescendants()) do
        if (v:IsA("TextLabel") or v:IsA("TextButton")) and v.Visible and v.AbsoluteSize.Y > 10 then
            if parseScore(v.Text) then
                local size = v.AbsoluteSize.X * v.AbsoluteSize.Y
                if size > bestSize then bestSize = size best = v end
            end
        end
    end
    if best then
        scoreLabel = best
        return parseScore(best.Text)
    end
end

function pollScore(now)
    local a, b = readScoreNums(now)
    if not a then return end
    lastScore = a .. "-" .. b
    if prevA and (a + b) >= (prevA + prevB) and (a > prevA or b > prevB) then
        if S.goalfx and goalFx then
            local leftScored = (a - prevA) >= (b - prevB)
            local mine = (V.side == 1) == leftScored
            goalFx(mine, a, b)
        end
    end
    prevA, prevB = a, b
end

-- FOV

pcall(function() RunService:UnbindFromRenderStep("VL_FOV") end)
RunService:BindToRenderStep("VL_FOV", Enum.RenderPriority.Camera.Value + 1, function()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    if V.fov > 0 then
        if not origFov then origFov = cam.FieldOfView end
        cam.FieldOfView = V.fov
    elseif origFov then
        cam.FieldOfView = origFov
        origFov = nil
    end
end)

-- ========== UI ==========
function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
function tw(o, t, props, style, dir)
    local tween = TweenService:Create(o, TweenInfo.new(t, style or EASE.Quint, dir or Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end
function corner(o, r)
    return new("UICorner", {CornerRadius = r}, o)
end

gui = new("ScreenGui", {
    Name = "VLGlassMenu",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 999
})
local parentOk = pcall(function()
    gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not parentOk or not gui.Parent then
    gui.Parent = lp:WaitForChild("PlayerGui")
end

blur = new("BlurEffect", {Name = "VLGlassBlur", Size = 0}, Lighting)

open = false
currentTab = "opt"


themedPills = {}

-- Toast
local toast = new("CanvasGroup", {
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, -70),
    Size = UDim2.fromOffset(280, 42),
    BackgroundColor3 = Color3.fromRGB(22, 24, 36),
    BackgroundTransparency = 0.1,
    GroupTransparency = 1
}, gui)
corner(toast, UDim.new(1, 0))
new("UIStroke", {Color = WHITE, Transparency = 0.85, Thickness = 1}, toast)
local toastTxt = new("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "",
    Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = WHITE, TextTruncate = Enum.TextTruncate.AtEnd
}, toast)
local toastId = 0
function notify(text)
    toastId = toastId + 1
    local id = toastId
    toastTxt.Text = text
    -- уходит ниже Island, чтобы не перекрывать его
    tw(toast, 0.35, {Position = UDim2.new(0.5, 0, 0, 62), GroupTransparency = 0}, EASE.Back)
    task.delay(1.8, function()
        if id == toastId then
            tw(toast, 0.28, {Position = UDim2.new(0.5, 0, 0, -70), GroupTransparency = 1})
        end
    end)
end

-- ========== DYNAMIC ISLAND (матовое стекло: FPS | TIME | PING) ==========
ISL_H, ISL_W, ISL_W_DOCK, DOCK_EXTRA, EAR = 40, 236, 256, 24, 11
local ISL_TINT = Color3.fromRGB(16, 18, 28)
local ISL_ALPHA = 0.36

islandDocked = V.docked
islFX = math.clamp(V.islx, 0.1, 0.9)
islFloatY = math.clamp(V.isly, 8, 400)
islCurY = islandDocked and -DOCK_EXTRA or islFloatY
local goalExtra = 0
islShake = 0

local function islSize()
    return UDim2.fromOffset(
        (islandDocked and ISL_W_DOCK or ISL_W) + goalExtra,
        ISL_H + (islandDocked and DOCK_EXTRA or 0)
    )
end

-- свечение по краю экрана при голе (создаётся первым, чтобы быть позади Island)
local edgeGlow = new("CanvasGroup", {
    Size = UDim2.new(1, 0, 0, 190), BackgroundColor3 = GREEN,
    BackgroundTransparency = 0, GroupTransparency = 1, Active = false
}, gui)
new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(0.3, 1)}, edgeGlow)

island = new("Frame", {
    Name = "DynamicIsland",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.fromOffset(0, islCurY),
    Size = islSize(),
    BackgroundColor3 = ISL_TINT,
    BackgroundTransparency = ISL_ALPHA,
    Active = true,
    Visible = S.dynamicisland
}, gui)
corner(island, UDim.new(0, ISL_H / 2))
local islScale = new("UIScale", {Scale = 1}, island)

-- ободок со "световой кромкой": ярко сверху, тускло в середине, мягко снизу
local islStroke = new("UIStroke", {
    Color = islandDocked and ACCENT:Lerp(WHITE, 0.5) or WHITE,
    Thickness = 1.3, Transparency = 0,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
}, island)
new("UIGradient", {
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.45, 0.78),
        NumberSequenceKeypoint.new(1, 0.4),
    })
}, islStroke)

-- стеклянный слой (клипается скруглением)
local glass = new("CanvasGroup", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1
}, island)
corner(glass, UDim.new(0, ISL_H / 2))

local gloss = new("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0
}, glass)
new("UIGradient", {
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(0.4, 0.8),
        NumberSequenceKeypoint.new(0.62, 0.94),
        NumberSequenceKeypoint.new(1, 0.97),
    })
}, gloss)

-- мягкое свечение акцентным цветом снизу
islGlow = new("Frame", {
    AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
    Size = UDim2.new(1, 0, 0, 16), BackgroundColor3 = ACCENT, BorderSizePixel = 0
}, glass)
new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0.55)}, islGlow)

-- блик, который изредка пробегает по стеклу
shimmer = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(-1, 0.5),
    Size = UDim2.fromOffset(46, 160), Rotation = 18,
    BackgroundColor3 = WHITE, BorderSizePixel = 0
}, glass)
new("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.82),
        NumberSequenceKeypoint.new(1, 1),
    })
}, shimmer)

-- вспышка при голе
local goalOverlay = new("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = GREEN,
    BackgroundTransparency = 1, BorderSizePixel = 0
}, glass)

-- "Уши" - вогнутые скругления по бокам, когда Island слит с верхним краем
local EAR_COLOR = ISL_TINT:Lerp(WHITE, 0.07)
local function makeEar(isRight)
    local g = new("CanvasGroup", {
        AnchorPoint = Vector2.new(isRight and 0 or 1, 0),
        Position = UDim2.new(isRight and 1 or 0, 0, 0, DOCK_EXTRA),
        Size = UDim2.fromOffset(EAR, EAR),
        BackgroundTransparency = 1,
        GroupTransparency = islandDocked and 0 or 1
    }, island)
    for i = 0, EAR - 1 do
        local yc = i + 0.5
        local s = math.sqrt(math.max(0, EAR * EAR - (yc - EAR) * (yc - EAR)))
        local w = math.max(0, EAR - s)
        if w > 0.2 then
            new("Frame", {
                AnchorPoint = Vector2.new(isRight and 0 or 1, 0),
                Position = UDim2.new(isRight and 0 or 1, 0, 0, i),
                Size = UDim2.fromOffset(w, 1),
                BackgroundColor3 = EAR_COLOR,
                BackgroundTransparency = ISL_ALPHA,
                BorderSizePixel = 0
            }, g)
        end
    end
    return g
end
local earL, earR = makeEar(false), makeEar(true)

-- основное содержимое (CanvasGroup, чтобы плавно прятать при голе)
local islContent = new("CanvasGroup", {
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.fromScale(0, 1),
    Size = UDim2.new(1, 0, 0, ISL_H),
    BackgroundTransparency = 1
}, island)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    Padding = UDim.new(0, 0)
}, islContent)

local function islLabel(order)
    return new("TextLabel", {
        Size = UDim2.fromOffset(72, 26), BackgroundTransparency = 1, RichText = true,
        Text = "--", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = WHITE, LayoutOrder = order
    }, islContent)
end
local function islDivider(order)
    return new("Frame", {
        Size = UDim2.fromOffset(1, 14), BackgroundColor3 = WHITE, BackgroundTransparency = 0.8,
        BorderSizePixel = 0, LayoutOrder = order
    }, islContent)
end
local islFps = islLabel(1)
islDivider(2)
local islTime = islLabel(3)
islDivider(4)
local islPing = islLabel(5)

-- надпись при голе
local goalGroup = new("CanvasGroup", {
    AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
    Size = UDim2.new(1, 0, 0, ISL_H), BackgroundTransparency = 1, GroupTransparency = 1
}, island)
local goalLbl = new("TextLabel", {
    Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, RichText = true,
    Text = "", Font = Enum.Font.GothamBlack, TextSize = 16, TextColor3 = WHITE
}, goalGroup)

-- Инфо-пилюля под Island (тоже стеклянная)
infoLbl = new("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 1, 7),
    Size = UDim2.fromOffset(0, 22),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundColor3 = ISL_TINT,
    BackgroundTransparency = 0.4,
    Text = "",
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = Color3.fromRGB(255, 226, 150),
    Visible = false
}, island)
corner(infoLbl, UDim.new(1, 0))
new("UIStroke", {Color = WHITE, Thickness = 1, Transparency = 0.85}, infoLbl)
new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}, infoLbl)

local function hex(c) return "#" .. c:ToHex() end
local function rt(val, col, unit)
    return string.format('<font color="%s">%s</font><font color="#8c92ad" size="10"> %s</font>', hex(col), tostring(val), unit)
end
local function fpsColor(f) return f >= 55 and GREEN or (f >= 30 and YELLOW or RED) end
local function pingColor(p) return p <= 80 and GREEN or (p <= 150 and YELLOW or RED) end

function clockText()
    if S.clock12 then
        local t = os.date("%I:%M %p")
        return (string.gsub(t, "^0", ""))
    end
    return os.date("%H:%M")
end

function updateIsland(fps, ping)
    if not S.dynamicisland then
        island.Visible = false
        return
    end
    island.Visible = true
    islFps.Text = rt(fps, fpsColor(fps), "FPS")
    islTime.Text = clockText()
    islPing.Text = rt(ping, pingColor(ping), "ms")
end

styleIsland = function(pulse)
    islStroke.Color = open and ACCENT or (islandDocked and ACCENT:Lerp(WHITE, 0.5) or WHITE)
    if pulse then islStroke.Thickness = 2.6 end
    tw(islStroke, 0.5, {Thickness = 1.3})
end

local function islCenterY()
    return island.AbsolutePosition.Y + island.AbsoluteSize.Y - (ISL_H / 2) * islScale.Scale
end

local function ripple(col, cy, big)
    local cx = island.AbsolutePosition.X + island.AbsoluteSize.X / 2
    local r = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(cx, cy or 0),
        Size = UDim2.fromOffset(60, 12),
        BackgroundTransparency = 1
    }, gui)
    corner(r, UDim.new(1, 0))
    local st = new("UIStroke", {Color = col or ACCENT, Thickness = 2.5, Transparency = 0.05}, r)
    tw(r, 0.7, {Size = big and UDim2.fromOffset(520, 130) or UDim2.fromOffset(340, 70)})
    tw(st, 0.7, {Transparency = 1, Thickness = 0.5})
    task.delay(0.75, function() pcall(function() r:Destroy() end) end)
end

local function burst(col)
    local cx = island.AbsolutePosition.X + island.AbsoluteSize.X / 2
    local cy = islCenterY()
    for _ = 1, 20 do
        local ang = math.random() * math.pi * 2
        local dist = math.random(50, 160)
        local sz = math.random(3, 7)
        local p = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
            Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = col, BorderSizePixel = 0
        }, gui)
        corner(p, UDim.new(1, 0))
        local t = 0.6 + math.random() * 0.5
        tw(p, t, {
            Position = UDim2.fromOffset(cx + math.cos(ang) * dist, cy + math.sin(ang) * dist * 0.7),
            BackgroundTransparency = 1, Size = UDim2.fromOffset(1, 1)
        })
        task.delay(t + 0.05, function() pcall(function() p:Destroy() end) end)
    end
end

-- Слияние с верхним краем / отрыв от него
function setDocked(d)
    if islandDocked == d then return end
    islandDocked = d
    V.docked = d
    tw(island, 0.4, {Size = islSize()}, EASE.Back)
    tw(earL, 0.3, {GroupTransparency = d and 0 or 1})
    tw(earR, 0.3, {GroupTransparency = d and 0 or 1})
    if d then
        islScale.Scale = 1.09
        tw(islScale, 0.6, {Scale = 1}, EASE.Elastic)
        ripple(ACCENT, 0, false)
    else
        islScale.Scale = 0.93
        tw(islScale, 0.45, {Scale = 1}, EASE.Back)
    end
    styleIsland(d)
end

-- ГОЛ: зелёный - наш, красный - нам забили
local goalToken = 0
goalFx = function(mine, a, b)
    goalToken = goalToken + 1
    local id = goalToken
    local col = mine and GREEN or RED
    goalLbl.Text = string.format('%s   <font color="#ffffff">%s : %s</font>', mine and "ГОЛ!" or "ПРОПУЩЕН", tostring(a), tostring(b))
    goalLbl.TextColor3 = col
    goalOverlay.BackgroundColor3 = col
    edgeGlow.BackgroundColor3 = col

    tw(islContent, 0.15, {GroupTransparency = 1})
    tw(goalGroup, 0.2, {GroupTransparency = 0})
    goalExtra = 56
    tw(island, 0.45, {Size = islSize()}, EASE.Back)
    islScale.Scale = 1.15
    tw(islScale, 0.8, {Scale = 1}, EASE.Elastic)
    islStroke.Color = col
    islStroke.Thickness = 3.5
    tw(islStroke, 1.4, {Thickness = 1.3})
    burst(col)
    if not mine then islShake = 9 end

    task.spawn(function()
        for i = 1, 3 do
            if goalToken ~= id then return end
            goalOverlay.BackgroundTransparency = 0.4
            tw(goalOverlay, 0.65, {BackgroundTransparency = 1})
            tw(edgeGlow, 0.12, {GroupTransparency = 0.1})
            ripple(col, islCenterY(), i == 1)
            task.wait(0.14)
            tw(edgeGlow, 0.6, {GroupTransparency = 1})
            task.wait(0.5)
        end
    end)

    task.delay(2.9, function()
        if goalToken ~= id then return end
        goalExtra = 0
        tw(island, 0.45, {Size = islSize()}, EASE.Back)
        tw(goalGroup, 0.25, {GroupTransparency = 1})
        tw(islContent, 0.3, {GroupTransparency = 0})
        styleIsland(false)
    end)
end
end

-- Crosshair
local crossHolder = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 1, Visible = S.crosshair
}, gui)
local crossStroke
do
local crossDot = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(5, 5), BackgroundColor3 = WHITE
}, crossHolder)
corner(crossDot, UDim.new(1, 0))
new("UIStroke", {Color = Color3.new(0, 0, 0), Thickness = 1, Transparency = 0.3}, crossDot)
local crossRing = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1
}, crossHolder)
corner(crossRing, UDim.new(1, 0))
crossStroke = new("UIStroke", {Color = ACCENT, Thickness = 1.5, Transparency = 0.2}, crossRing)
end

-- ========== PANEL ==========
local panel = new("CanvasGroup", {
    Name = "Panel",
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    GroupTransparency = 1,
    Visible = false,
    Active = true
}, gui)
corner(panel, UDim.new(0, 20))
local panelScale = new("UIScale", {Scale = 0.88}, panel)

do
local bgOverlay = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(12, 14, 22),
    BackgroundTransparency = 0.12
}, panel)
corner(bgOverlay, UDim.new(0, 20))
new("UIGradient", {
    Rotation = 110,
    Color = ColorSequence.new(Color3.fromRGB(28, 32, 50), Color3.fromRGB(10, 12, 20))
}, bgOverlay)
end
new("UIStroke", {Color = WHITE, Thickness = 1.1, Transparency = 0.5}, panel)

local statsLbl
do
local header = new("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1}, panel)
new("TextLabel", {
    Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -60, 0, 20), BackgroundTransparency = 1,
    Text = "Glass Menu  v3.2", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = WHITE,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)
statsLbl = new("TextLabel", {
    Position = UDim2.fromOffset(16, 30), Size = UDim2.new(1, -60, 0, 16), BackgroundTransparency = 1,
    Text = "FPS --  •  Пинг -- мс", Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = GRAY,
    TextXAlignment = Enum.TextXAlignment.Left
}, header)

local closeBtn = new("TextButton", {
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10),
    Size = UDim2.fromOffset(28, 28), BackgroundColor3 = WHITE, BackgroundTransparency = 0.9,
    Text = "×", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = WHITE, AutoButtonColor = false
}, header)
corner(closeBtn, UDim.new(0, 8))
closeBtn.MouseEnter:Connect(function() tw(closeBtn, 0.15, {BackgroundTransparency = 0.7, TextColor3 = RED}) end)
closeBtn.MouseLeave:Connect(function() tw(closeBtn, 0.15, {BackgroundTransparency = 0.9, TextColor3 = WHITE}) end)
closeBtn.Activated:Connect(function() if open then toggleMenu() end end)
end

local tabBar = new("Frame", {
    Position = UDim2.fromOffset(12, 52), Size = UDim2.new(1, -24, 0, 30),
    BackgroundColor3 = WHITE, BackgroundTransparency = 0.93
}, panel)
corner(tabBar, UDim.new(0, 9))
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 3)}, tabBar)
new("UIPadding", {PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3), PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3)}, tabBar)

local tabs = {}
local function makeTab(id, title)
    local b = new("TextButton", {
        Size = UDim2.new(0.25, -3, 1, 0), BackgroundTransparency = 1, Text = title,
        Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = GRAY, AutoButtonColor = false
    }, tabBar)
    corner(b, UDim.new(0, 7))
    tabs[id] = b
    b.Activated:Connect(function() switchTab(id) end)
    return b
end
makeTab("opt", "Оптим.")
makeTab("vis", "Визуал")
makeTab("util", "Утилиты")
makeTab("srv", "Сервер")

highlightTab = function(id)
    for k, b in pairs(tabs) do
        if k == id then
            b.BackgroundTransparency = 0.1
            b.BackgroundColor3 = ACCENT
            b.TextColor3 = WHITE
        else
            b.BackgroundTransparency = 1
            b.TextColor3 = GRAY
        end
    end
end

local scroll = new("ScrollingFrame", {
    Position = UDim2.fromOffset(0, 88), Size = UDim2.new(1, 0, 1, -142),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y
}, panel)
new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)
new("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 8)}, scroll)

local order = 0
local switches = {}
local contentByTab = {opt = {}, vis = {}, util = {}, srv = {}}

local function section(text, tab)
    order = order + 1
    local lbl = new("TextLabel", {
        LayoutOrder = order, Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Text = "  " .. text, Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = GRAY,
        TextXAlignment = Enum.TextXAlignment.Left, Visible = (tab == currentTab)
    }, scroll)
    table.insert(contentByTab[tab], lbl)
end

local function flash(o)
    o.BackgroundTransparency = 0.85
    tw(o, 0.35, {BackgroundTransparency = 1})
end

local function rowBase(tab, height, clickable)
    order = order + 1
    local r = new(clickable and "TextButton" or "Frame", {
        LayoutOrder = order, Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = WHITE,
        BackgroundTransparency = 1, Visible = (tab == currentTab)
    }, scroll)
    if clickable then
        r.Text = ""
        r.AutoButtonColor = false
    end
    corner(r, UDim.new(0, 11))
    table.insert(contentByTab[tab], r)
    return r
end

local function rowTexts(r, title, sub, titleColor)
    new("TextLabel", {
        Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -76, 0, 16), BackgroundTransparency = 1,
        Text = title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = titleColor or WHITE,
        TextXAlignment = Enum.TextXAlignment.Left
    }, r)
    if sub then
        new("TextLabel", {
            Position = UDim2.fromOffset(10, 24), Size = UDim2.new(1, -76, 0, 14), BackgroundTransparency = 1,
            Text = sub, Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = GRAY,
            TextXAlignment = Enum.TextXAlignment.Left
        }, r)
    end
end

local function addSwitch(key, title, sub, tab)
    local r = rowBase(tab, 48, true)
    rowTexts(r, title, sub)
    local track = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(42, 24), BackgroundColor3 = OFFC
    }, r)
    corner(track, UDim.new(1, 0))
    local knob = new("Frame", {
        Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = WHITE
    }, track)
    corner(knob, UDim.new(1, 0))
    switches[key] = function(on, animate)
        local t = animate and 0.25 or 0
        tw(track, t, {BackgroundColor3 = on and GREEN or OFFC})
        tw(knob, t, {Position = on and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3)}, EASE.Back)
    end
    switches[key](S[key], false)
    r.Activated:Connect(function()
        flash(r)
        setState(key, not S[key])
    end)
end

local function addButton(title, sub, tab, fn, titleColor)
    local r = rowBase(tab, 48, true)
    rowTexts(r, title, sub, titleColor)
    new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(20, 24),
        BackgroundTransparency = 1, Text = "›", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = GRAY
    }, r)
    r.Activated:Connect(function()
        flash(r)
        fn()
    end)
end

local function addInfo(tab)
    local r = rowBase(tab, 30, false)
    return new("TextLabel", {
        Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
        Text = "--", Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = GRAY,
        TextXAlignment = Enum.TextXAlignment.Left
    }, r)
end

local function addSegment(title, tab, labels, values, current, onSelect)
    local n = #labels
    local row = rowBase(tab, 64, false)
    new("TextLabel", {
        Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 16), BackgroundTransparency = 1,
        Text = title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = WHITE,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)
    local bg = new("Frame", {
        Position = UDim2.new(0, 4, 0, 26), Size = UDim2.new(1, -8, 0, 32),
        BackgroundColor3 = WHITE, BackgroundTransparency = 0.9
    }, row)
    corner(bg, UDim.new(1, 0))
    local pill = new("Frame", {
        Size = UDim2.new(1 / n, -4, 1, -6), BackgroundColor3 = ACCENT, Visible = false
    }, bg)
    corner(pill, UDim.new(1, 0))
    table.insert(themedPills, pill)
    local function place(i, animate)
        pill.Visible = true
        local pos = UDim2.new((i - 1) / n, 2, 0, 3)
        if animate then tw(pill, 0.28, {Position = pos}, EASE.Back) else pill.Position = pos end
    end
    for i = 1, n do
        local b = new("TextButton", {
            Size = UDim2.new(1 / n, 0, 1, 0), Position = UDim2.new((i - 1) / n, 0, 0, 0),
            BackgroundTransparency = 1, Text = labels[i], Font = Enum.Font.GothamBold,
            TextSize = 12, TextColor3 = WHITE, ZIndex = 2, AutoButtonColor = false
        }, bg)
        b.Activated:Connect(function()
            place(i, true)
            onSelect(values[i])
        end)
        if values[i] == current then place(i, false) end
    end
end

local themeStrokes = {}
local lastCap = 60
local bgCapped = false
local function addThemeRow(tab)
    local row = rowBase(tab, 64, false)
    new("TextLabel", {
        Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 16), BackgroundTransparency = 1,
        Text = "Цвет интерфейса", Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = WHITE,
        TextXAlignment = Enum.TextXAlignment.Left
    }, row)
    local holder = new("Frame", {
        Position = UDim2.fromOffset(10, 28), Size = UDim2.new(1, -20, 0, 28), BackgroundTransparency = 1
    }, row)
    new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder}, holder)
    for i, t in ipairs(THEMES) do
        local d = new("TextButton", {
            LayoutOrder = i, Size = UDim2.fromOffset(26, 26), BackgroundColor3 = t[2],
            Text = "", AutoButtonColor = false
        }, holder)
        corner(d, UDim.new(1, 0))
        themeStrokes[i] = new("UIStroke", {Color = WHITE, Thickness = 2, Transparency = (i == V.theme) and 0 or 1}, d)
        d.Activated:Connect(function()
            V.theme = i
            applyTheme()
            saveSettings()
            notify("Цвет: " .. t[1])
        end)
    end
end

-- ---------- ВКЛАДКА: ОПТИМИЗАЦИЯ ----------
section("Плавность", "opt")
addSwitch("turbo", "Турбо-плавность", "Максимум FPS, картинка остаётся красивой", "opt")
addSwitch("fpsunlock", "Разблокировка FPS", "Снимает лимит 60 FPS", "opt")
section("Графика", "opt")
addSwitch("quality", "Низкая графика", "Минимальный уровень рендера", "opt")
addSwitch("shadows", "Тени", "Отключить тени", "opt")
addSwitch("textures", "Текстуры", "Убрать текстуры и декали", "opt")
addSwitch("materials", "Материалы и модели", "Простые материалы", "opt")
addSwitch("effects", "Эффекты", "Частицы, туман, блум, вода", "opt")
addSwitch("accessories", "Аксессуары игроков", "Скрыть чужие аксессуары", "opt")
addSwitch("lightlite", "Простое освещение", "Без отражений и мягких теней", "opt")
addSwitch("nosky", "Убрать небо", "Без звёзд, солнца и луны", "opt")
section("Умное", "opt")
addSwitch("autoboost", "Авто-буст", "Сам включит низкую графику при FPS < 28", "opt")
addSwitch("bgsave", "Экономия в фоне", "FPS 10, пока окно игры не в фокусе (ПК)", "opt")

-- ---------- ВКЛАДКА: ВИЗУАЛ ----------
section("Мяч и враги", "vis")
addSwitch("lookbeams", "Лучи взгляда", "Куда смотрит враг", "vis")
addSwitch("teamoutlines", "Контуры врагов", "Только противники", "vis")
addSwitch("ballesp", "Ball ESP", "Подсветка мяча через стены", "vis")
addSwitch("ballmarker", "Маркер падения", "Диск на полу, где упадёт мяч", "vis")
addSwitch("balltrail", "След мяча", "Светящийся шлейф за мячом", "vis")
section("Картинка", "vis")
addSwitch("fullbright", "Яркий свет", "Убирает тёмные участки карты", "vis")
addSwitch("crosshair", "Прицел", "Точка в центре экрана", "vis")
addSegment("Поле зрения (FOV)", "vis", {"Выкл", "80", "90", "100", "120"}, {0, 80, 90, 100, 120}, V.fov, function(v)
    V.fov = v
    saveSettings()
    notify(v == 0 and "FOV: по умолчанию" or ("FOV: " .. v))
end)
section("Интерфейс игры", "vis")
addSwitch("hidenames", "Скрыть ники", "Имена над игроками", "vis")
addSwitch("hideplayers", "Скрыть игроков", "Только на твоём экране", "vis")
addSwitch("hidescore", "Скрыть табло счёта", "Прячет родное табло", "vis")
addSwitch("hidechat", "Скрыть чат", "Убирает окно чата Roblox", "vis")

-- ---------- ВКЛАДКА: УТИЛИТЫ ----------
section("Голы", "util")
addSwitch("goalfx", "Эффекты голов", "Island горит зелёным/красным при голе", "util")
addSegment("Моя сторона на табло", "util", {"Слева", "Справа"}, {1, 2}, V.side, function(v)
    V.side = v
    saveSettings()
    notify(v == 1 and "Мой счёт слева" or "Мой счёт справа")
end)
addButton("Тест: мой гол", "Показать зелёный эффект", "util", function() goalFx(true, prevA or 1, prevB or 0) end)
addButton("Тест: нам забили", "Показать красный эффект", "util", function() goalFx(false, prevA or 0, prevB or 1) end)
section("Под Dynamic Island", "util")
addSwitch("balldist", "Дистанция до мяча", "В студах, под Island", "util")
addSwitch("ballspeed", "Скорость мяча", "Студов в секунду", "util")
addSwitch("session", "Таймер сессии", "Сколько ты уже играешь", "util")
addSwitch("extstats", "Расширенная статистика", "Средний/мин. FPS и память", "util")
addSwitch("showscore", "Счёт матча", "Читается из родного табло", "util")
section("Island и уведомления", "util")
addSwitch("dynamicisland", "Dynamic Island", "Тяни к верхнему краю - прилипнет", "util")
addSwitch("clock12", "12-часовой формат", "Время с AM/PM", "util")
addSwitch("joinnotify", "Входы и выходы", "Уведомление, когда игрок заходит/уходит", "util")
addSwitch("pingwarn", "Предупреждение о пинге", "Уведомит, если пинг > 150", "util")
section("Система", "util")
addSwitch("afk", "Анти-АФК", "Не кикает за бездействие", "util")
addSwitch("blur", "Размытие фона", "Матовое стекло при открытом меню", "util")
addSwitch("savecfg", "Сохранять настройки", "Иначе при запуске всё выключено", "util")
addSegment("Лимит FPS", "util", {"30", "60", "120", "∞"}, {30, 60, 120, 0}, -1, function(c)
    if S.fpsunlock then setState("fpsunlock", false, true) end
    local ok = pcall(function()
        if not setfpscap then error("no") end
        setfpscap(c == 0 and 999 or c)
        lastCap = c == 0 and 999 or c
    end)
    notify(ok and ("Лимит FPS: " .. (c == 0 and "∞" or tostring(c))) or "Не поддерживается")
end)
addThemeRow("util")

do
local function panic()
    for k in pairs(S) do
        if k ~= "dynamicisland" and k ~= "savecfg" and S[k] then setState(k, false, true) end
    end
    if open then toggleMenu() end
    notify("Всё выключено")
end
addButton("Выключить всё (End)", "Мгновенно отключает все функции", "util", panic, RED)
addButton("Выгрузить скрипт", "Полностью убрать меню и эффекты", "util", function()
    if ENV.VL_Cleanup then ENV.VL_Cleanup() end
end, RED)

-- ---------- ВКЛАДКА: СЕРВЕР ----------
section("Текущий сервер", "srv")
local srvInfo = addInfo("srv")
addButton("Перезайти", "На этот же сервер", "srv", function()
    notify("Перезаход...")
    pcall(function()
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, lp)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp)
        end
    end)
end)
addButton("Другой сервер", "Перейти на другой публичный сервер", "srv", function()
    task.spawn(function()
        notify("Ищу сервер...")
        local ok, body = pcall(function()
            return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100")
        end)
        if not ok then notify("HTTP недоступен в этом экзекуторе") return end
        local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
        if not (ok2 and data and data.data) then notify("Не удалось получить список") return end
        local best
        for _, s in ipairs(data.data) do
            if s.id ~= game.JobId and s.playing and s.maxPlayers and s.playing < s.maxPlayers - 1 then
                if not best or s.playing > best.playing then best = s end
            end
        end
        if not best then notify("Подходящих серверов нет") return end
        notify("Телепорт...")
        pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, lp) end)
    end)
end)
addButton("Скопировать JobId", "ID текущего сервера в буфер", "srv", function()
    local ok = pcall(function()
        local f = setclipboard or toclipboard
        f(game.JobId)
    end)
    notify(ok and "JobId скопирован" or "Буфер недоступен")
end)

-- ---------- Мастер-кнопка (только графика) ----------
local masterGrad
do
local master = new("TextButton", {
    AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -12),
    Size = UDim2.new(1, -24, 0, 38), BackgroundColor3 = WHITE, Text = "Включить всю графику",
    Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = WHITE, AutoButtonColor = false
}, panel)
corner(master, UDim.new(1, 0))
masterGrad = new("UIGradient", {Color = ColorSequence.new(ACCENT, ACCENT2)}, master)
local masterScale = new("UIScale", {}, master)
master.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        tw(masterScale, 0.08, {Scale = 0.95})
    end
end)
master.InputEnded:Connect(function() tw(masterScale, 0.28, {Scale = 1}, EASE.Back) end)

local function allOn()
    for _, k in ipairs(OPT) do if not S[k] then return false end end
    return true
end
refreshMaster = function()
    master.Text = allOn() and "Выключить всю графику" or "Включить всю графику"
end
master.Activated:Connect(function()
    local target = not allOn()
    task.spawn(function()
        for _, k in ipairs(OPT) do
            if S[k] ~= target then setState(k, target, true) end
            task.wait(0.05)
        end
        notify(target and "Максимальный буст" or "Графика сброшена")
    end)
end)
end

-- ========== TURBO / FPS (v3.2) ==========
local TB = {keys = {"shadows", "effects", "lightlite", "materials", "fpsunlock"}, capSet = false}
TB.setCap = function(n)
    local ok = false
    if setfpscap then ok = pcall(setfpscap, n) end
    if not ok then
        -- запасной путь через флаг планировщика (если исполнитель поддерживает)
        local sf = setfflag or (getgenv and getgenv().setfflag)
        if sf then ok = pcall(sf, "DFIntTaskSchedulerTargetFps", tostring(n)) end
    end
    return ok
end

-- ========== LOGIC ==========
local boosted = nil

setState = function(key, val, quiet)
    S[key] = val
    if switches[key] then switches[key](val, true) end
    if key == "blur" and open then tw(blur, 0.25, {Size = val and 14 or 0}) end
    if key == "lookbeams" then updateLookBeams() end
    if key == "teamoutlines" then updateOutlines() end
    if key == "dynamicisland" then island.Visible = val end
    if key == "hidescore" then hideGameScoreboard(val) end
    if key == "goalfx" then prevA, prevB = nil, nil end
    if key == "hidechat" then applyChat() end
    if key == "fullbright" then applyFullbright() end
    if key == "hidenames" then applyNames() end
    if key == "crosshair" then crossHolder.Visible = val end
    if key == "ballesp" or key == "ballmarker" or key == "balltrail" or key == "balldist" or key == "ballspeed" then
        updateBall()
    end
    if key == "fpsunlock" then
        local ok = TB.setCap(val and 999 or lastCap)
        TB.capSet = val and ok
        if val and not ok then notify("FPS: не поддерживается исполнителем") end
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
    if not quiet then notify(NAMES[key] .. (val and ": вкл" or ": выкл")) end
    refreshMaster()
    saveSettings()
    if GFX[key] then
        task.spawn(function() globalApply() sweep() end)
    end
end

switchTab = function(id)
    currentTab = id
    highlightTab(id)
    for tab, list in pairs(contentByTab) do
        for _, obj in ipairs(list) do
            obj.Visible = (tab == id)
        end
    end
    scroll.CanvasPosition = Vector2.new(0, 0)
end
highlightTab("opt")

applyTheme = function()
    ACCENT, ACCENT2 = THEMES[V.theme][2], THEMES[V.theme][3]
    highlightTab(currentTab)
    for _, p in ipairs(themedPills) do p.BackgroundColor3 = ACCENT end
    masterGrad.Color = ColorSequence.new(ACCENT, ACCENT2)
    for i, st in ipairs(themeStrokes) do st.Transparency = (i == V.theme) and 0 or 1 end
    crossStroke.Color = ACCENT
    islGlow.BackgroundColor3 = ACCENT
    styleIsland(false)
    if trailData then trailData.trail.Color = ColorSequence.new(ACCENT) end
    if landMarker then landMarker.Color = ACCENT end
end

local function placePanel()
    local vs = gui.AbsoluteSize
    local w = math.min(300, vs.X - 16)
    local h = math.min(450, vs.Y - 20)
    panel.Size = UDim2.fromOffset(w, h)
    panel.Position = UDim2.fromScale(0.5, 0.5)
end

toggleMenu = function()
    open = not open
    if open then
        placePanel()
        panel.Visible = true
        panel.GroupTransparency = 1
        panelScale.Scale = 0.85
        tw(panel, 0.28, {GroupTransparency = 0})
        tw(panelScale, 0.4, {Scale = 1}, EASE.Back)
        if S.blur then tw(blur, 0.3, {Size = 14}) end
    else
        tw(panel, 0.2, {GroupTransparency = 1})
        tw(panelScale, 0.2, {Scale = 0.88}, EASE.Quad, Enum.EasingDirection.In)
        tw(blur, 0.2, {Size = 0})
        task.delay(0.22, function()
            if not open then panel.Visible = false end
        end)
    end
    styleIsland(open)
end

-- ========== DRAG + TAP ISLAND (с магнитом к верхнему краю) ==========
do
local dragging, moved = false, false
local dragStart, dragInput, startPX, startY
island.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        moved = false
        dragStart = input.Position
        dragInput = input
        startPX = islFX * gui.AbsoluteSize.X
        startY = islandDocked and 0 or islFloatY
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                conn:Disconnect()
                dragging = false
                if moved then
                    V.islx, V.isly = islFX, islFloatY
                    saveSettings()
                else
                    toggleMenu()
                end
            end
        end)
    end
end)
connect(UIS.InputChanged, function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       (input.UserInputType == Enum.UserInputType.Touch and input == dragInput) then
        local delta = input.Position - dragStart
        if not moved and delta.Magnitude > 8 then moved = true end
        if moved then
            local vs = gui.AbsoluteSize
            local half = (ISL_W_DOCK / 2 + 6) / vs.X
            islFX = math.clamp((startPX + delta.X) / vs.X, half, 1 - half)
            local newY = startY + delta.Y
            if newY < 26 then
                setDocked(true)
            elseif newY > 44 then
                setDocked(false)
            end
            if not islandDocked then
                islFloatY = math.clamp(newY, 8, vs.Y - 60)
            end
        end
    end
end)
end
connect(UIS.InputBegan, function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        toggleMenu()
    elseif input.KeyCode == Enum.KeyCode.End then
        panic()
    end
end)

-- Join/leave
connect(Players.PlayerAdded, function(p)
    if S.joinnotify then notify(p.DisplayName .. " зашёл") end
end)
connect(Players.PlayerRemoving, function(p)
    if S.joinnotify then notify(p.DisplayName .. " вышел") end
end)

-- Экономия в фоне
connect(UIS.WindowFocusReleased, function()
    if S.bgsave and setfpscap then
        bgCapped = true
        pcall(setfpscap, 10)
    end
end)
connect(UIS.WindowFocused, function()
    if bgCapped then
        bgCapped = false
        pcall(setfpscap, S.fpsunlock and 999 or lastCap)
    end
end)

-- ========== MAIN LOOP ==========
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

local startClock = os.clock()
local frames, t0 = 0, os.clock()
local fpsNow, pingNow, pingEma = 60, 0, nil
local fpsHist = {}
local acc25, acc12, accSlow = 0, 0, 0
local lowCount, highPing, lastPingWarn = 0, 0, 0
local scoreT = 0

connect(RunService.Heartbeat, function(dt)
    frames = frames + 1
    local now = os.clock()

    -- плавное движение Island (без конфликта с твинами)
    do
        local target = islandDocked and -DOCK_EXTRA or islFloatY
        islCurY = islCurY + (target - islCurY) * (1 - math.exp(-dt * 16))
        local vs = gui.AbsoluteSize
        local shake = 0
        if islShake > 0.15 then
            shake = math.sin(now * 70) * islShake
            islShake = islShake * math.exp(-dt * 5)
        else
            islShake = 0
        end
        island.Position = UDim2.fromOffset(math.floor(islFX * vs.X + shake + 0.5), math.floor(islCurY + 0.5))
        -- блик по стеклу раз в 7 секунд
        local ph = (now % 7) / 7
        shimmer.Position = UDim2.fromScale(ph < 0.4 and (-0.15 + (ph / 0.4) * 1.3) or -1, 0.5)
    end

    -- FPS / пинг / статистика (2 раза в секунду)
    if now - t0 >= 0.5 then
        fpsNow = math.floor(frames / (now - t0) + 0.5)
        local p = readPing()
        pingEma = pingEma and (pingEma * 0.5 + p * 0.5) or p
        pingNow = math.floor(pingEma + 0.5)
        frames = 0
        t0 = now

        table.insert(fpsHist, fpsNow)
        if #fpsHist > 120 then table.remove(fpsHist, 1) end

        if open then
            statsLbl.Text = string.format("FPS %d  •  Пинг %d мс  •  %s", fpsNow, pingNow, clockText())
            local pl = #Players:GetPlayers()
            srvInfo.Text = string.format("Игроков %d/%d  •  Аптайм %s", pl, Players.MaxPlayers, fmtTime(Workspace.DistributedGameTime))
        end
        updateIsland(fpsNow, pingNow)

        -- авто-буст
        if S.autoboost then
            if fpsNow < 28 then lowCount = lowCount + 1 else lowCount = 0 end
            if lowCount >= 4 and not boosted then
                boosted = {}
                for _, k in ipairs({"quality", "shadows", "effects"}) do
                    if not S[k] then
                        boosted[#boosted + 1] = k
                        setState(k, true, true)
                    end
                end
                notify("Авто-буст включён")
            end
        else
            lowCount = 0
        end

        -- предупреждение о пинге
        if S.pingwarn then
            if pingNow > 150 then highPing = highPing + 1 else highPing = 0 end
            if highPing >= 3 and now - lastPingWarn > 20 then
                lastPingWarn = now
                notify("Высокий пинг: " .. pingNow .. " мс")
            end
        end

        -- табло не должно "оживать"
        if S.hidescore then
            for g in pairs(hiddenScore) do
                if g.Parent and g.Visible then g.Visible = false end
            end
        end
    end

    -- каждый кадр - только то, что реально нужно плавным
    if S.lookbeams then updateLookBeams() end
    if S.ballesp or S.ballmarker or S.balltrail or S.balldist or S.ballspeed then updateBall() end

    -- 0.25 с
    acc25 = acc25 + dt
    if acc25 >= 0.25 then
        acc25 = 0
        if S.teamoutlines then updateOutlines() end
        if S.hidenames then applyNames() end
    end

    -- 1 с
    accSlow = accSlow + dt
    if accSlow >= 1 then
        accSlow = 0
        if S.fullbright then applyFullbright() end
        if S.fpsunlock then TB.setCap(999) end
    end

    -- опрос счёта (кэшированная метка, дёшево)
    if S.goalfx or S.showscore then
        scoreT = scoreT + dt
        if scoreT >= 0.4 then
            scoreT = 0
            pollScore(now)
        end
    end

    -- Инфо-пилюля под Island (~8 раз в секунду)
    acc12 = acc12 + dt
    if acc12 >= 0.12 then
        acc12 = 0
        local parts = {}
        local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if S.balldist and lastBall and hrp then
            parts[#parts + 1] = string.format("Мяч %.0f", (hrp.Position - lastBall.Position).Magnitude)
        end
        if S.ballspeed and lastBall then
            parts[#parts + 1] = string.format("Скор. %.0f", lastBall.AssemblyLinearVelocity.Magnitude)
        end
        if S.session then
            parts[#parts + 1] = "Сессия " .. fmtTime(now - startClock)
        end
        if S.showscore then
            parts[#parts + 1] = "Счёт " .. lastScore
        end
        if S.extstats and #fpsHist > 0 then
            local sum, mn = 0, math.huge
            for _, f in ipairs(fpsHist) do
                sum = sum + f
                if f < mn then mn = f end
            end
            local mem = 0
            pcall(function() mem = Stats:GetTotalMemoryUsageMb() end)
            parts[#parts + 1] = string.format("ср %d · мин %d · %dМБ", math.floor(sum / #fpsHist + 0.5), mn, math.floor(mem + 0.5))
        end
        if S.dynamicisland and #parts > 0 then
            infoLbl.Text = table.concat(parts, "  •  ")
            infoLbl.Visible = true
        else
            infoLbl.Visible = false
        end
    end
end)

-- ========== INIT ==========
for k, v in pairs(S) do
    if switches[k] then switches[k](v, false) end
end
if S.crosshair then crossHolder.Visible = true end
if S.hidescore then hideGameScoreboard(true) end
if S.hidechat then applyChat() end
if S.fullbright then applyFullbright() end
for k in pairs(GFX) do
    if S[k] then task.spawn(function() globalApply() sweep() end) break end
end
applyTheme()
refreshMaster()
updateIsland(60, 0)

ENV.VL_Cleanup = function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep("VL_FOV") end)
    if bgCapped or TB.capSet then pcall(TB.setCap, lastCap) end
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam and origFov then cam.FieldOfView = origFov end
    end)
    for k in pairs(S) do S[k] = false end
    for plr in pairs(lookBeams) do clearLookBeam(plr) end
    for plr in pairs(outlines) do clearOutline(plr) end
    clearBallFx()
    hideGameScoreboard(false)
    applyChat()
    applyFullbright()
    applyNames()
    pcall(globalApply)
    for _, v in ipairs(Workspace:GetDescendants()) do pcall(apply, v) end
    pcall(function() blur:Destroy() end)
    pcall(function() gui:Destroy() end)
    ENV.VL_Cleanup = nil
end
end

task.delay(0.3, function()
    notify("Glass Menu v3.2 готов")
end)

print("[VL Glass] v3.2 Loaded successfully")
