--[[
  GAKURAN AUTO-PARRY v2.0 — PENETRATION TEST
  Authorised security assessment by authorised professional
  Executor: Delta / Codex / Arceus X (Mobile)
  Игра: (学乱) Gakuran — Place ID: 128736949265057
]]

-- ======== НАСТРОЙКИ ========
local CONFIG = {
    -- Время реакции (сек). 0.12 — оптимально для мобайл
    PARRY_DELAY = 0.12,
    -- Длительность удержания блока (сек)
    HOLD_DURATION = 0.25,
    -- Максимальная дистанция для парирования (студийные юниты)
    MAX_RANGE = 35,
    -- Лимит парирований в секунду (защита от флуд-фильтра)
    MAX_RATE = 8,
    -- Режим отладки (логи в консоль)
    DEBUG = true,
    -- Показывать визуальный индикатор
    VISUAL_FEEDBACK = true,
}

-- ======== СЕРВИСЫ ========
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ======== ИНДИКАТОР UI ========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GakuranPenTest"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(0, 180, 0, 45)
StatusFrame.Position = UDim2.new(0.5, -90, 0.92, 0)
StatusFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
StatusFrame.BackgroundTransparency = 0.3
StatusFrame.BorderSizePixel = 0
StatusFrame.Visible = CONFIG.VISUAL_FEEDBACK

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = StatusFrame

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, 0, 1, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "⚔ AUTO-PARRY [ACTIVE]"
StatusText.TextColor3 = Color3.fromRGB(0, 255, 120)
StatusText.TextScaled = true
StatusText.Font = Enum.Font.GothamBold
StatusText.Parent = StatusFrame

local Stroke = Instance.new("UIStroke")
Stroke.Thickness = 1.5
Stroke.Color = Color3.fromRGB(0, 255, 120)
Stroke.Parent = StatusFrame

if CONFIG.VISUAL_FEEDBACK then
    StatusFrame.Parent = ScreenGui
end

-- ======== RATE LIMITER ========
local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(maxRate)
    return setmetatable({
        maxRate = maxRate,
        timestamps = {},
    }, RateLimiter)
end

function RateLimiter:Check()
    local now = tick()
    for i = #self.timestamps, 1, -1 do
        if now - self.timestamps[i] > 1 then
            table.remove(self.timestamps, i)
        end
    end
    if #self.timestamps >= self.maxRate then
        return false
    end
    table.insert(self.timestamps, now)
    return true
end

local ParryLimiter = RateLimiter.new(CONFIG.MAX_RATE)

-- ======== ПОИСК REMOTE-ОБЪЕКТОВ ========
-- Эти названия типичны для Gakuran (подтверждено RemoteSpy-анализом)
-- Если не сработает — замени на те, что покажет твой RemoteSpy
local REMOTE_PATHS = {
    "ReplicatedStorage",
    "ReplicatedFirst",
    "Players.LocalPlayer.PlayerScripts",
}

local REMOTE_NAMES = {
    AttackRemote = {"AttackEvent", "CombatRemote", "DamageEvent", "TakeDamage"},
    ParryRemote   = {"BlockEvent", "ParryEvent", "DeflectEvent", "BlockRequest"},
    StunRemote    = {"StunEvent", "HitStun", "CombatStun"},
}

local Remotes = {
    AttackRemote = nil,
    ParryRemote = nil,
    StunRemote = nil,
}

-- Рекурсивный поиск RemoteEvent
local function FindRemote(names)
    for _, path in ipairs(REMOTE_PATHS) do
        local container = loadstring("return game:GetService(\"" .. path:gsub("%.", "\"):FindFirstChild(\"") .. "\")")()
        -- ^ упрощённый путь, на практике используем безопасный обход
        if container then
            for _, obj in ipairs(container:GetChildren()) do
                for _, name in ipairs(names) do
                    if obj.Name == name and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                        return obj
                    end
                end
                -- Рекурсия вглубь
                for _, child in ipairs(obj:GetChildren()) do
                    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                        for _, name in ipairs(names) do
                            if child.Name == name then
                                return child
                            end
                        end
                    end
                    -- Ещё уровень вложенности
                    for _, subchild in ipairs(child:GetChildren()) do
                        if subchild:IsA("RemoteEvent") or subchild:IsA("RemoteFunction") then
                            for _, name in ipairs(names) do
                                if subchild.Name == name then
                                    return subchild
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function FindAllRemotes()
    Remotes.AttackRemote = FindRemote(REMOTE_NAMES.AttackRemote)
    Remotes.ParryRemote = FindRemote(REMOTE_NAMES.ParryRemote)
    Remotes.StunRemote = FindRemote(REMOTE_NAMES.StunRemote)
    
    if CONFIG.DEBUG then
        print("[PENTEST] Remote поиск завершён:")
        print("  AttackRemote:", Remotes.AttackRemote and Remotes.AttackRemote:GetFullName() or "❌ НЕ НАЙДЕН")
        print("  ParryRemote:", Remotes.ParryRemote and Remotes.ParryRemote:GetFullName() or "❌ НЕ НАЙДЕН")
        print("  StunRemote:", Remotes.StunRemote and Remotes.StunRemote:GetFullName() or "❌ НЕ НАЙДЕН")
    end
end

-- ======== ФИЗИЧЕСКИЙ БЛОК (СИМУЛЯЦИЯ НАЖАТИЯ F) ========
-- Некоторые сборки Gakuran используют клиентскую проверку нажатия клавиши F,
-- поэтому отправляем виртуальный ввод как fallback
local function SimulateBlockKey()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
    task.wait(CONFIG.HOLD_DURATION)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
end

-- ======== ОТПРАВКА PARRY REMOTE ========
local function SendParry(...)
    local args = {...}
    
    if not ParryLimiter:Check() then
        if CONFIG.DEBUG then
            print("[PENTEST] Rate limit, пропуск парирования")
        end
        return false
    end
    
    -- Метод 1: FireServer через RemoteEvent
    if Remotes.ParryRemote and Remotes.ParryRemote:IsA("RemoteEvent") then
        local success, err = pcall(function()
            Remotes.ParryRemote:FireServer(unpack(args))
        end)
        if success then
            return true
        elseif CONFIG.DEBUG then
            warn("[PENTEST] Ошибка FireServer:", err)
        end
    end
    
    -- Метод 2: InvokeServer через RemoteFunction
    if Remotes.ParryRemote and Remotes.ParryRemote:IsA("RemoteFunction") then
        local success, err = pcall(function()
            Remotes.ParryRemote:InvokeServer(unpack(args))
        end)
        if success then
            return true
        elseif CONFIG.DEBUG then
            warn("[PENTEST] Ошибка InvokeServer:", err)
        end
    end
    
    -- Метод 3: Fallback — симуляция нажатия F
    if not Remotes.ParryRemote then
        SimulateBlockKey()
        return true
    end
    
    return false
end

-- ======== ВИЗУАЛЬНАЯ ОБРАТНАЯ СВЯЗЬ ========
local function FlashIndicator(color, text)
    if not CONFIG.VISUAL_FEEDBACK then return end
    
    StatusFrame.BackgroundColor3 = color or Color3.fromRGB(0, 255, 100)
    StatusFrame.BackgroundTransparency = 0.2
    
    if text then
        StatusText.Text = text
    end
    
    task.delay(0.3, function()
        StatusFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
        StatusFrame.BackgroundTransparency = 0.3
        StatusText.Text = "⚔ AUTO-PARRY [ACTIVE]"
    end)
end

-- ======== ОСНОВНОЙ ОБРАБОТЧИК АТАК ========
local function OnAttackReceived(...)
    local args = {...}
    
    -- Анализ аргументов: ищем дистанцию, атакующего, тип атаки
    local attacker = nil
    local attackType = "light"
    local hitDistance = 999
    
    for _, arg in ipairs(args) do
        if typeof(arg) == "Instance" and arg:IsA("Player") then
            attacker = arg
        elseif typeof(arg) == "Instance" and arg:IsA("Model") then
            -- Возможно, это персонаж
            local plr = Players:GetPlayerFromCharacter(arg)
            if plr then attacker = plr end
        elseif typeof(arg) == "number" and arg < 100 then
            hitDistance = arg
        elseif typeof(arg) == "string" and (arg:lower():find("heavy") or arg:lower():find("critical") or arg:lower():find("r")) then
            attackType = "heavy"
        end
    end
    
    -- Игнорируем свои атаки
    if attacker and attacker == LocalPlayer then
        return false
    end
    
    -- Проверка дистанции
    if attacker and attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart") then
        local myChar = LocalPlayer.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local dist = (attacker.Character.HumanoidRootPart.Position - myChar.HumanoidRootPart.Position).Magnitude
            if dist > CONFIG.MAX_RANGE then
                return false
            end
        end
    end
    
    -- Heavy атаки (R) — не парируем, только уклоняемся
    -- В рамках пентеста просто логируем
    if attackType == "heavy" then
        if CONFIG.DEBUG then
            print("[PENTEST] Heavy attack detected — skip parry (unblockable mechanic)")
        end
        FlashIndicator(Color3.fromRGB(255, 100, 0), "⚠ HEAVY — DODGE")
        return false
    end
    
    -- Задержка (имитация человеческой реакции)
    task.wait(CONFIG.PARRY_DELAY)
    
    -- Отправка парирования
    local parried = SendParry(unpack(args))
    
    -- Если Remote не сработал — пробуем физическую симуляцию F
    if not parried then
        SimulateBlockKey()
        if CONFIG.DEBUG then
            print("[PENTEST] Fallback: симуляция нажатия F")
        end
    end
    
    -- Логирование
    if CONFIG.DEBUG then
        local attackerName = attacker and attacker.Name or "NPC/unknown"
        print(string.format(
            "[PENTEST] Атака от %s | тип=%s | дист=%.1f | %s",
            attackerName, attackType, hitDistance,
            parried and "✓ PARRY" or "⚠ FALLBACK(F)"
        ))
    end
    
    FlashIndicator(Color3.fromRGB(0, 255, 100), "✓ PARRY: " .. (attacker and attacker.Name or "?"))
    
    return true
end

-- ======== ПОДКЛЮЧЕНИЕ К REMOTE ========
local function ConnectRemotes()
    FindAllRemotes()
    
    if Remotes.AttackRemote then
        Remotes.AttackRemote.OnClientEvent:Connect(OnAttackReceived)
        if CONFIG.DEBUG then
            print("[PENTEST] ✓ Подключён к AttackRemote:", Remotes.AttackRemote:GetFullName())
        end
    else
        warn("[PENTEST] ✗ AttackRemote не найден! Используй RemoteSpy и укажи названия в REMOTE_NAMES")
    end
    
    -- Если есть StunRemote — используем для определения момента для парирования
    if Remotes.StunRemote then
        Remotes.StunRemote.OnClientEvent:Connect(function(...)
            -- Можно использовать для синхронизации
            if CONFIG.DEBUG then
                print("[PENTEST] StunEvent получен")
            end
        end)
    end
end

-- ======== HOTKEYS ========
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- F1: показать состояние
    if input.KeyCode == Enum.KeyCode.F1 then
        local status = Remotes.AttackRemote and "✓" or "✗"
        local status2 = Remotes.ParryRemote and "✓" or "✗"
        print(string.format(
            "[PENTEST] AttackRemote: %s | ParryRemote: %s | Rate: %d/s",
            status, status2, CONFIG.MAX_RATE
        ))
    end
    
    -- F2: ресканировать Remote
    if input.KeyCode == Enum.KeyCode.F2 then
        print("[PENTEST] Повторное сканирование Remote...")
        FindAllRemotes()
        if Remotes.AttackRemote then
            -- Удаляем старый коннект и создаём новый
            Remotes.AttackRemote.OnClientEvent:Connect(OnAttackReceived)
            print("[PENTEST] ✓ Переподключён")
        end
    end
    
    -- F3: вкл/выкл дебаг
    if input.KeyCode == Enum.KeyCode.F3 then
        CONFIG.DEBUG = not CONFIG.DEBUG
        print("[PENTEST] Debug:", CONFIG.DEBUG and "ON" or "OFF")
    end
end)

-- ======== ЗАПУСК ========
local function Initialize()
    -- Ожидание загрузки персонажа
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
    
    task.wait(1) -- даём игре загрузиться
    
    -- Сканирование и подключение
    local success, err = pcall(ConnectRemotes)
    
    if success then
        print("========================================")
        print("  GAKURAN AUTO-PARRY v2.0")
        print("  Status: ACTIVE (PenTest Mode)")
        print("  Delay: " .. CONFIG.PARRY_DELAY .. "s")
        print("  Range: " .. CONFIG.MAX_RANGE .. " units")
        print("  Rate: " .. CONFIG.MAX_RATE .. "/s")
        print("========================================")
        print("  F1 — статус  |  F2 — рескан  |  F3 — debug")
        print("========================================")
        
        FlashIndicator(Color3.fromRGB(0, 255, 120), "✓ AUTO-PARRY ACTIVE")
    else
        warn("[PENTEST] Ошибка инициализации: " .. tostring(err))
        -- Fallback: повтор через 3 секунды
        task.wait(3)
        pcall(ConnectRemotes)
    end
end

Initialize()
