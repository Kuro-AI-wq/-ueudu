--[[ Graphics+  |  лучше графика • плавность • лёгкое размытие при повороте камеры • оптимизация
     Кнопка-«искра» открывает панель. Зажми и тяни — кнопку можно поставить куда угодно.
     Всё клиентское и обратимое: выключил функцию или выгрузил скрипт — настройки вернулись как были. ]]

local ENV = (getgenv and getgenv()) or _G
if ENV.VLG_Cleanup then pcall(ENV.VLG_Cleanup) end   -- защита от двойного запуска
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer
local EASE = Enum.EasingStyle
local WHITE = Color3.new(1, 1, 1)
local SAVE_FILE = "VL_Graphics_Settings.json"

-- ===================== состояние =====================
local S = {   -- включено / выключено
    enhance = true,     -- цвет + мягкое свечение
    softshadow = true,  -- мягкие тени
    hq = true,          -- максимальное качество рендера
    motion = true,      -- лёгкое размытие при повороте камеры
    rays = false,       -- лучи солнца
    dof = false,        -- глубина резкости
    keep = true,        -- держать FPS на цели (умный регулятор)
    smart = true,       -- умная оптимизация карты (мелкие тени)
}
local V = {style = 2, power = 2, mblur = 1, target = 60, bx = -1, by = -1}
local SUP = {}          -- что регулятор временно отключил ради FPS
local UI = {}           -- элементы интерфейса
local F = {log = {}}    -- функции и журнал ошибок
local L = {fps = 60}    -- живой FPS
local conns = {}        -- все соединения (отключаются при выгрузке)

local function connect(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end
local function runSection(name, fn)   -- каждая секция в pcall, ошибки — в журнал
    local ok, err = pcall(fn)
    if not ok then
        F.log[#F.log + 1] = name .. ": " .. tostring(err)
        warn("[Graphics+] " .. name .. ": " .. tostring(err))
        if F.logUpdate then F.logUpdate() end
    end
end
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function tw(o, t, props, style, dir)
    local tween = TweenService:Create(o, TweenInfo.new(t, style or EASE.Quint, dir or Enum.EasingDirection.Out), props)
    tween:Play()
    return tween
end
local function corner(o, r) return new("UICorner", {CornerRadius = r}, o) end

-- ===================== настройки (файл) =====================
runSection("settings", function()
    if not (isfile and readfile and isfile(SAVE_FILE)) then return end
    local d = HttpService:JSONDecode(readfile(SAVE_FILE))
    if type(d) ~= "table" then return end
    for k, v in pairs(d.S or {}) do if type(S[k]) == "boolean" and type(v) == "boolean" then S[k] = v end end
    for k, v in pairs(d.V or {}) do if type(V[k]) == "number" and type(v) == "number" then V[k] = v end end
end)
local saveToken = 0
function F.saveNow()
    pcall(function()
        if writefile then writefile(SAVE_FILE, HttpService:JSONEncode({S = S, V = V})) end
    end)
end
function F.save()   -- с задержкой, чтобы не писать файл на каждый тап
    saveToken = saveToken + 1
    local t = saveToken
    task.delay(1, function() if t == saveToken then F.saveNow() end end)
end

-- ===================== улучшение картинки =====================
local FX = {}       -- созданные эффекты
local SAVED = {}    -- оригинальные значения (Lighting, качество) для отката
local STYLES = {
    {con = 0.04, sat = 0.06, bri = 0.0, tint = Color3.fromRGB(255, 255, 255), bi = 0.15, bs = 14, bt = 1.2},   -- Чистая
    {con = 0.12, sat = -0.02, bri = -0.01, tint = Color3.fromRGB(255, 244, 232), bi = 0.30, bs = 24, bt = 1.0}, -- Кино
    {con = 0.10, sat = 0.25, bri = 0.01, tint = Color3.fromRGB(255, 252, 248), bi = 0.35, bs = 20, bt = 1.0},   -- Сочная
}
local POWER = {0.6, 1, 1.4}
local function eff(k) return S[k] and not SUP[k] end

local function ensure(key, class, props)
    local o = FX[key]
    if not o or not o.Parent then
        o = new(class, props, nil)
        o.Name = "VLG_" .. key
        o.Parent = Lighting
        FX[key] = o
    end
    return o
end
local function drop(key)
    if FX[key] then
        pcall(function() FX[key]:Destroy() end)
        FX[key] = nil
    end
end
local function lset(prop, val)
    pcall(function()
        if SAVED[prop] == nil then SAVED[prop] = Lighting[prop] end
        Lighting[prop] = val
    end)
end
local function lrestore(prop)
    if SAVED[prop] ~= nil then
        local v = SAVED[prop]
        SAVED[prop] = nil
        pcall(function() Lighting[prop] = v end)
    end
end

runSection("effects", function()
    function F.applyFx()
        local st, k = STYLES[V.style] or STYLES[2], POWER[V.power] or 1
        if S.enhance then
            local cc = ensure("cc", "ColorCorrectionEffect", {Contrast = 0, Saturation = 0, Brightness = 0})
            tw(cc, 0.35, {Contrast = st.con * k, Saturation = st.sat * k, Brightness = st.bri * k, TintColor = st.tint})
        else
            drop("cc")
        end
        if S.enhance and not SUP.bloom then
            local b = ensure("bloom", "BloomEffect", {Intensity = 0, Size = 14, Threshold = 1.2})
            tw(b, 0.35, {Intensity = st.bi * k, Size = st.bs, Threshold = st.bt})
        else
            drop("bloom")
        end
        if eff("rays") then
            local r = ensure("rays", "SunRaysEffect", {Intensity = 0, Spread = 0.7})
            tw(r, 0.35, {Intensity = 0.08 * k})
        else
            drop("rays")
        end
        if eff("dof") then
            local d = ensure("dof", "DepthOfFieldEffect", {FarIntensity = 0, NearIntensity = 0, FocusDistance = 60, InFocusRadius = 80})
            tw(d, 0.35, {FarIntensity = 0.12 * k})
        else
            drop("dof")
        end
    end
    function F.applyLight()
        if eff("softshadow") then
            lset("GlobalShadows", true)
            lset("ShadowSoftness", 0.45)
        else
            lrestore("GlobalShadows")
            lrestore("ShadowSoftness")
        end
        pcall(function()
            local r = settings().Rendering
            if eff("hq") then
                if SAVED.quality == nil then SAVED.quality = r.QualityLevel end
                r.QualityLevel = Enum.QualityLevel.Level10
            elseif SAVED.quality ~= nil then
                r.QualityLevel = SAVED.quality
                SAVED.quality = nil
            end
        end)
    end
end)

-- ===================== лёгкое размытие при повороте камеры =====================
local MB = {smooth = 0, prev = nil, last = 0}
local MBLUR = {{k = 2.2, max = 6}, {k = 3.4, max = 10}}    -- Лёгкое / Среднее
function F.applyMotion()
    if eff("motion") then
        ensure("blur", "BlurEffect", {Size = 0, Enabled = false})
    else
        drop("blur")
        MB.smooth, MB.prev = 0, nil
    end
end

-- один кадровый обработчик: считает FPS и (если нужно) размытие
local frames, t0 = 0, os.clock()
connect(RunService.RenderStepped, function(dt)
    frames = frames + 1
    local now = os.clock()
    if now - t0 >= 0.5 then
        local f = frames / (now - t0)
        L.fps = L.fps * 0.5 + f * 0.5
        frames, t0 = 0, now
    end
    local blur = FX.blur
    if not blur then return end
    local cam = Workspace.CurrentCamera
    if not cam or dt <= 0 then return end
    local look = cam.CFrame.LookVector
    if MB.prev then
        local d = math.acos(math.clamp(look:Dot(MB.prev), -1, 1))
        if d < 1 then   -- резкие скачки камеры (телепорт) пропускаем
            local m = MBLUR[V.mblur] or MBLUR[1]
            local target = math.clamp((d / dt - 1.2) * m.k, 0, m.max)
            MB.smooth = MB.smooth + (target - MB.smooth) * math.min(1, dt * 14)
            if math.abs(MB.smooth - MB.last) > 0.25 or (MB.smooth < 0.25 and MB.last ~= 0) then
                MB.last = MB.smooth < 0.25 and 0 or MB.smooth
                blur.Size = MB.last
                blur.Enabled = MB.last > 0
            end
        end
    end
    MB.prev = look
end)

-- ===================== умная оптимизация карты (мелкие детали без теней) =====================
runSection("smart", function()
    local touched = setmetatable({}, {__mode = "k"})
    local sweepId = 0
    local function inChar(p)
        local m = p:FindFirstAncestorOfClass("Model")
        while m do
            if m:FindFirstChildOfClass("Humanoid") then return true end
            local pm = m.Parent
            m = pm and pm:FindFirstAncestorOfClass("Model")
        end
        return false
    end
    local function consider(v)
        if not v:IsA("BasePart") or v:IsA("Terrain") then return end
        if not v.CastShadow or touched[v] ~= nil then return end
        local s = v.Size
        if s.X * s.Y * s.Z < 0.6 and not inChar(v) then
            touched[v] = true
            v.CastShadow = false
        end
    end
    function F.smartOn()
        sweepId = sweepId + 1
        local id = sweepId
        task.spawn(function()
            local n = 0
            for _, v in ipairs(Workspace:GetDescendants()) do
                if id ~= sweepId or not S.smart then return end
                pcall(consider, v)
                n = n + 1
                if n % 300 == 0 then task.wait() end
            end
        end)
    end
    function F.smartOff()
        sweepId = sweepId + 1
        for p in pairs(touched) do
            pcall(function() p.CastShadow = true end)
            touched[p] = nil
        end
    end
    connect(Workspace.DescendantAdded, function(v)
        if S.smart then task.defer(pcall, consider, v) end
    end)
end)

-- ===================== умный регулятор FPS =====================
function F.applyAll()
    if F.applyFx then F.applyFx() end
    if F.applyLight then F.applyLight() end
    F.applyMotion()
end

runSection("governor", function()
    local ORDER = {"dof", "rays", "motion", "bloom", "hq", "softshadow"}   -- от менее заметного к более
    local SM = {stack = {}, low = 0, ok = 0, hold = 0, pre = {}, gain = {}}
    local function active(k)
        if k == "bloom" then return S.enhance end
        return S[k]
    end
    local function degrade()
        for _, k in ipairs(ORDER) do
            if active(k) and not SUP[k] then
                SUP[k] = true
                SM.stack[#SM.stack + 1] = k
                SM.pre[#SM.stack] = SM.ema or L.fps
                SM.settle = os.clock() + 6
                SM.hold = os.clock() + 25
                F.applyAll()
                return
            end
        end
    end
    local function recover()
        local k = table.remove(SM.stack)
        if k then
            SUP[k] = nil
            SM.settle = nil
            F.applyAll()
        end
    end
    function F.keepReset()
        SUP, SM.stack, SM.low, SM.ok, SM.pre, SM.gain, SM.ema, SM.settle = {}, {}, 0, 0, {}, {}, nil, nil
        F.applyAll()
        if UI.status then UI.status.Text = S.keep and "Регулятор: всё включено" or "Регулятор выключен" end
    end
    local acc = 0
    connect(RunService.Heartbeat, function(dt)
        if not S.keep then return end
        acc = acc + dt
        if acc < 1 then return end
        acc = 0
        local f, tgt = L.fps, V.target
        SM.ema = SM.ema and (SM.ema * 0.7 + f * 0.3) or f
        local lvl = #SM.stack
        if SM.settle and os.clock() >= SM.settle then
            SM.gain[lvl] = math.max(2, SM.ema - (SM.pre[lvl] or SM.ema))
            SM.settle = nil
        end
        if f < tgt - 4 then SM.low, SM.ok = SM.low + 1, 0
        elseif f >= tgt - 1 then SM.ok, SM.low = SM.ok + 1, 0
        else SM.low, SM.ok = 0, 0 end
        if SM.low >= 3 then
            SM.low = 0
            degrade()
        elseif SM.ok >= 12 and lvl > 0 and os.clock() > SM.hold and (SM.ema - (SM.gain[lvl] or 8)) >= tgt - 1 then
            SM.ok = 0
            recover()
        end
        if UI.status then
            UI.status.Text = string.format("FPS %d  ·  цель %d  ·  экономия %d из %d", math.floor(f + 0.5), tgt, #SM.stack, #ORDER)
        end
    end)
end)

-- ===================== интерфейс (лёгкий: без вложенных групп и постоянных анимаций) =====================
local open = false
local switches = {}
local setState
runSection("ui", function()
    local TEXT, SUB, OFF, ONT = Color3.fromRGB(228, 230, 236), Color3.fromRGB(162, 166, 178), Color3.fromRGB(100, 104, 116), Color3.fromRGB(38, 40, 48)
    local GRAPH1, GRAPH2, GRAPH3 = Color3.fromRGB(92, 94, 102), Color3.fromRGB(60, 62, 70), Color3.fromRGB(82, 84, 94)
    local PEARL = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(0.4, Color3.fromRGB(150, 154, 166)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(238, 240, 248)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
    })

    UI.gui = new("ScreenGui", {
        Name = "VLGraphics", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 998,
    }, nil)
    local okParent = pcall(function() UI.gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not okParent or not UI.gui.Parent then
        UI.gui.Parent = lp:WaitForChild("PlayerGui", 10)
    end
    local gui = UI.gui

    local function label(parent, x, y, w, h, text, size, color, bold, align)
        return new("TextLabel", {
            Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), BackgroundTransparency = 1, Text = text,
            Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham, TextSize = size, TextColor3 = color, RichText = true,
            TextXAlignment = align or Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        }, parent)
    end

    -- всплеск «пузыря» при включении
    function F.pop(x, y, big)
        local ring = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(10, 10),
            BackgroundTransparency = 1, ZIndex = 30,
        }, gui)
        corner(ring, UDim.new(1, 0))
        local st = new("UIStroke", {Color = WHITE, Thickness = 2, Transparency = 0.15}, ring)
        local R = big and 70 or 40
        tw(ring, 0.55, {Size = UDim2.fromOffset(R, R)})
        tw(st, 0.55, {Transparency = 1})
        task.delay(0.6, function() ring:Destroy() end)
        if big then
            for i = 1, 6 do
                local a = (i / 6) * math.pi * 2 + math.random() * 0.4
                local d = 22 + math.random() * 18
                local dot = new("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(6, 6),
                    BackgroundColor3 = WHITE, BackgroundTransparency = 0.15, BorderSizePixel = 0, ZIndex = 30,
                }, gui)
                corner(dot, UDim.new(1, 0))
                tw(dot, 0.5, {Position = UDim2.fromOffset(x + math.cos(a) * d, y + math.sin(a) * d), Size = UDim2.fromOffset(2, 2), BackgroundTransparency = 1})
                task.delay(0.55, function() dot:Destroy() end)
            end
        end
    end

    -- кнопка-«искра»
    UI.btn = new("TextButton", {
        Name = "Spark", Size = UDim2.fromOffset(44, 44), Position = UDim2.fromOffset(14, 120), BackgroundColor3 = WHITE,
        BackgroundTransparency = 0.12, Text = "", AutoButtonColor = false, ZIndex = 20,
    }, gui)
    corner(UI.btn, UDim.new(1, 0))
    new("UIGradient", {Color = ColorSequence.new(GRAPH1, GRAPH2), Rotation = 60}, UI.btn)
    local bs = new("UIStroke", {Color = WHITE, Transparency = 0.35, Thickness = 1.4}, UI.btn)
    new("UIGradient", {Color = PEARL, Rotation = 30}, bs)
    local star = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
    }, UI.btn)
    for _, rot in ipairs({0, 90, 45, 135}) do
        local long = (rot == 0 or rot == 90)
        local bar = new("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = long and UDim2.fromOffset(22, 3) or UDim2.fromOffset(13, 2), Rotation = rot, BackgroundColor3 = WHITE,
            BackgroundTransparency = long and 0.05 or 0.35, BorderSizePixel = 0,
        }, star)
        corner(bar, UDim.new(1, 0))
    end
    local btnScale = new("UIScale", {}, UI.btn)

    -- панель
    UI.panel = new("Frame", {
        Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(330, 460),
        BackgroundTransparency = 1, Visible = false, ZIndex = 10,
    }, gui)
    UI.pscale = new("UIScale", {Scale = 0.94}, UI.panel)
    UI.pbg = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0.16, BorderSizePixel = 0}, UI.panel)
    corner(UI.pbg, UDim.new(0, 28))
    new("UIGradient", {
        Color = ColorSequence.new({ColorSequenceKeypoint.new(0, GRAPH1), ColorSequenceKeypoint.new(0.5, GRAPH2), ColorSequenceKeypoint.new(1, GRAPH3)}),
        Rotation = 60,
    }, UI.pbg)
    local ps = new("UIStroke", {Color = WHITE, Transparency = 0.45, Thickness = 1.5}, UI.pbg)
    new("UIGradient", {Color = PEARL, Rotation = 30}, ps)

    label(UI.panel, 20, 12, 200, 24, "Graphics+", 18, TEXT, true)
    UI.status = label(UI.panel, 20, 36, 290, 16, "Регулятор: всё включено", 11, SUB)
    UI.scroll = new("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 62), Size = UDim2.new(1, 0, 1, -70), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = WHITE, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
    }, UI.panel)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center}, UI.scroll)
    new("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 12)}, UI.scroll)

    local order = 0
    local function nextOrder() order = order + 1 return order end
    local function card(h)
        local r = new("Frame", {
            LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = WHITE, BackgroundTransparency = 0.92, BorderSizePixel = 0,
        }, UI.scroll)
        corner(r, UDim.new(0, 18))
        new("UIStroke", {Color = WHITE, Transparency = 0.82, Thickness = 1}, r)
        return r
    end
    local function section(text)
        local l = label(UI.scroll, 0, 0, 100, 26, "  " .. text, 12, SUB, true)
        l.Size = UDim2.new(1, 0, 0, 26)
        l.LayoutOrder = nextOrder()
    end
    local function press(hit, scale)
        hit.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then tw(scale, 0.08, {Scale = 0.97}) end
        end)
        hit.InputEnded:Connect(function() tw(scale, 0.25, {Scale = 1}, EASE.Back) end)
    end

    local function addSwitch(key, title, sub)
        local r = card(56)
        label(r, 16, 9, 210, 20, title, 14, TEXT, true)
        label(r, 16, 30, 230, 16, sub, 11, SUB)
        local track = new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.5, 0), Size = UDim2.fromOffset(46, 26), BackgroundColor3 = OFF, BorderSizePixel = 0}, r)
        corner(track, UDim.new(1, 0))
        local knob = new("Frame", {AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(20, 20), BackgroundColor3 = WHITE, BorderSizePixel = 0}, track)
        corner(knob, UDim.new(1, 0))
        local shine = new("Frame", {Position = UDim2.fromOffset(4, 3), Size = UDim2.fromOffset(7, 5), BackgroundColor3 = WHITE, BackgroundTransparency = 0.4, BorderSizePixel = 0, Rotation = -25}, knob)
        corner(shine, UDim.new(1, 0))
        local glow = new("UIStroke", {Color = WHITE, Thickness = 2, Transparency = 1}, track)
        switches[key] = function(on, animate)
            local pos = on and UDim2.new(0, 23, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
            local col = on and Color3.fromRGB(238, 240, 246) or OFF
            local kc = on and ONT or WHITE
            local gt = on and 0.4 or 1
            if animate then
                tw(track, 0.25, {BackgroundColor3 = col})
                tw(knob, 0.4, {Position = pos}, EASE.Back)
                tw(knob, 0.25, {BackgroundColor3 = kc})
                tw(glow, 0.3, {Transparency = gt})
            else
                track.BackgroundColor3, knob.Position, knob.BackgroundColor3, glow.Transparency = col, pos, kc, gt
            end
        end
        switches[key](S[key], false)
        local sc = new("UIScale", {}, r)
        local hit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5}, r)
        press(hit, sc)
        hit.Activated:Connect(function()
            setState(key, not S[key])
            local ap, sz = track.AbsolutePosition, track.AbsoluteSize
            F.pop(ap.X + sz.X / 2, ap.Y + sz.Y / 2, S[key])
        end)
    end

    local function addSegment(title, labels, values, get, set)
        local r = card(68)
        label(r, 16, 8, 250, 20, title, 14, TEXT, true)
        local bar = new("Frame", {Position = UDim2.fromOffset(12, 32), Size = UDim2.new(1, -24, 0, 28), BackgroundColor3 = WHITE, BackgroundTransparency = 0.88, BorderSizePixel = 0}, r)
        corner(bar, UDim.new(1, 0))
        local n = #labels
        local ind = new("Frame", {Size = UDim2.new(1 / n, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2), BackgroundColor3 = Color3.fromRGB(238, 240, 246), BorderSizePixel = 0}, bar)
        corner(ind, UDim.new(1, 0))
        local btns = {}
        local function refresh(animate)
            local cur = get()
            for i, v in ipairs(values) do
                if v == cur then
                    local pos = UDim2.new((i - 1) / n, 2, 0, 2)
                    if animate then tw(ind, 0.3, {Position = pos}, EASE.Back) else ind.Position = pos end
                end
                btns[i].TextColor3 = (v == cur) and ONT or SUB
            end
        end
        for i, text in ipairs(labels) do
            btns[i] = new("TextButton", {
                Position = UDim2.new((i - 1) / n, 0, 0, 0), Size = UDim2.new(1 / n, 0, 1, 0), BackgroundTransparency = 1, Text = text,
                Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = SUB, AutoButtonColor = false, ZIndex = 3,
            }, bar)
            btns[i].Activated:Connect(function()
                set(values[i])
                refresh(true)
            end)
        end
        refresh(false)
    end

    local function addButton(title, sub, fn, danger)
        local r = card(sub and 56 or 46)
        label(r, 16, sub and 9 or 13, 270, 20, title, 14, danger and Color3.fromRGB(255, 120, 110) or TEXT, true)
        if sub then label(r, 16, 30, 270, 16, sub, 11, SUB) end
        local sc = new("UIScale", {}, r)
        local hit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5}, r)
        press(hit, sc)
        hit.Activated:Connect(fn)
    end

    setState = function(key, val)
        S[key] = val
        if switches[key] then switches[key](val, true) end
        if key == "smart" then
            if val then F.smartOn() else F.smartOff() end
        elseif key == "keep" then
            F.keepReset()
        else
            F.applyAll()
        end
        F.save()
    end

    section("Картинка")
    addSwitch("enhance", "Улучшение графики", "Цвет, контраст и мягкое свечение")
    addSegment("Стиль", {"Чистая", "Кино", "Сочная"}, {1, 2, 3}, function() return V.style end, function(v)
        V.style = v
        F.applyFx()
        F.save()
    end)
    addSegment("Сила эффекта", {"Мягко", "Средне", "Сильно"}, {1, 2, 3}, function() return V.power end, function(v)
        V.power = v
        F.applyFx()
        F.save()
    end)
    addSwitch("softshadow", "Мягкие тени", "Плавные края теней")
    addSwitch("hq", "Максимум качества", "Полное качество рендера (регулятор снизит при просадках)")
    addSwitch("rays", "Лучи солнца", "Лёгкая атмосфера")
    addSwitch("dof", "Глубина резкости", "Далёкий фон чуть мягче")

    section("Размытие при повороте")
    addSwitch("motion", "Размытие при повороте", "Появляется только когда крутишь камеру")
    addSegment("Сила размытия", {"Лёгкое", "Среднее"}, {1, 2}, function() return V.mblur end, function(v)
        V.mblur = v
        F.save()
    end)

    section("Плавность и оптимизация")
    addSwitch("keep", "Держать FPS на цели", "Сам снижает эффекты при просадках и возвращает")
    addSegment("Цель FPS", {"30", "45", "60"}, {30, 45, 60}, function() return V.target end, function(v)
        V.target = v
        F.keepReset()
        F.save()
    end)
    addSwitch("smart", "Умная оптимизация", "Убирает тени у мелких деталей карты, вид почти не меняется")

    section("Система")
    UI.logInfo = label(UI.scroll, 0, 0, 100, 22, "  Журнал: ошибок нет", 11, SUB)
    UI.logInfo.Size = UDim2.new(1, 0, 0, 22)
    UI.logInfo.LayoutOrder = nextOrder()
    function F.logUpdate()
        local n = #F.log
        UI.logInfo.Text = n == 0 and "  Журнал: ошибок нет" or ("  Журнал: " .. n .. " ош. · " .. string.sub(F.log[n], 1, 40))
    end
    addButton("Скопировать журнал", "Ошибки секций для отладки", function()
        pcall(function()
            local f = setclipboard or toclipboard
            f(#F.log == 0 and "Ошибок нет" or table.concat(F.log, "\n"))
        end)
    end)
    addButton("Выгрузить скрипт", "Вернуть всё как было", function()
        if ENV.VLG_Cleanup then ENV.VLG_Cleanup() end
    end, true)
    F.logUpdate()

    -- размеры панели под экран
    local function fit()
        local vs = gui.AbsoluteSize
        UI.panel.Size = UDim2.fromOffset(math.min(330, vs.X - 20), math.min(470, vs.Y - 30))
    end
    connect(gui:GetPropertyChangedSignal("AbsoluteSize"), fit)
    fit()

    -- открыть / закрыть
    function F.toggle()
        open = not open
        if open then
            UI.panel.Visible = true
            UI.pscale.Scale = 0.94
            UI.pbg.BackgroundTransparency = 1
            tw(UI.pscale, 0.28, {Scale = 1}, EASE.Back)
            tw(UI.pbg, 0.25, {BackgroundTransparency = 0.16})
        else
            tw(UI.pscale, 0.18, {Scale = 0.96}, EASE.Quad, Enum.EasingDirection.In)
            tw(UI.pbg, 0.18, {BackgroundTransparency = 1})
            task.delay(0.2, function() if not open then UI.panel.Visible = false end end)
        end
    end

    -- перетаскивание кнопки куда угодно (тап = открыть/закрыть)
    local drag = {on = false, moved = false}
    if V.bx >= 0 and V.by >= 0 then UI.btn.Position = UDim2.fromOffset(V.bx, V.by) end
    UI.btn.InputBegan:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
        drag.on, drag.moved = true, false
        drag.start, drag.pos, drag.input = i.Position, UI.btn.Position, i
        tw(btnScale, 0.1, {Scale = 0.9})
        local c
        c = i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then
                c:Disconnect()
                drag.on = false
                tw(btnScale, 0.3, {Scale = 1}, EASE.Back)
                if drag.moved then
                    V.bx, V.by = UI.btn.Position.X.Offset, UI.btn.Position.Y.Offset
                    F.save()
                else
                    F.toggle()
                end
            end
        end)
    end)
    connect(UIS.InputChanged, function(i)
        if not drag.on then return end
        if not (i.UserInputType == Enum.UserInputType.MouseMovement or (i.UserInputType == Enum.UserInputType.Touch and i == drag.input)) then return end
        local d = i.Position - drag.start
        if not drag.moved and d.Magnitude > 8 then drag.moved = true end
        if drag.moved then
            local vs = gui.AbsoluteSize
            UI.btn.Position = UDim2.fromOffset(
                math.clamp(drag.pos.X.Offset + d.X, 0, vs.X - 44),
                math.clamp(drag.pos.Y.Offset + d.Y, 0, vs.Y - 44))
        end
    end)
end)

-- ===================== старт и выгрузка =====================
runSection("start", function()
    F.applyAll()
    if S.smart then F.smartOn() end
    F.keepReset()
end)

ENV.VLG_Cleanup = function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    F.saveNow()
    for k in pairs(FX) do drop(k) end
    for prop in pairs(SAVED) do
        if prop == "quality" then
            pcall(function() settings().Rendering.QualityLevel = SAVED.quality end)
            SAVED.quality = nil
        else
            lrestore(prop)
        end
    end
    if F.smartOff then pcall(F.smartOff) end
    pcall(function() UI.gui:Destroy() end)
    ENV.VLG_Cleanup = nil
end
print("[Graphics+] загружен")
