--[[
	GAKURAN // AUTO-PARRY  v1.0
	====================================
	Экзекутор : Delta (мобильный / ПК)
	Игра      : Gakuran (Roblox)
	Режимы    : Авто-пари (тап F) · Автоблок (холд F) · Даш от M2 (Q)
	Тема      : монохром, меню перетаскивается пальцем/мышью

	Как работает:
	  Скрипт сканирует врагов (игроки + NPC) в радиусе. Когда враг
	  запускает анимацию атаки, он ждёт, пока анимация дойдёт до точки
	  тайминга (слайдер "Тайминг пари") и делает короткий тап F —
	  это perfect block/парри (0 урона, 0 стамины, стан врага 0.15с).
	  Опционально: холд F для обычного блока, тап Q (даш) от M2.

	Настройки сохраняются в GakuranAP_Settings.json
	(Android Delta: папка Delta -> workspace; нужно разрешение на хранилище).
]]

local ok, err = pcall(function()

	-- ===== СЕРВИСЫ =====
	local Players   = game:GetService("Players")
	local UIS       = game:GetService("UserInputService")
	local VIM       = game:GetService("VirtualInputManager")
	local HttpService = game:GetService("HttpService")

	local LP = Players.LocalPlayer

	-- ===== ОБЩЕЕ СОСТОЯНИЕ (на случай повторного запуска) =====
	local env = getgenv and getgenv() or _G
	if env.GakuranAP_Running ~= nil then
		env.GakuranAP_Running = false
		task.wait(0.25)
		pcall(function()
			if env.GakuranAP_GUI then env.GakuranAP_GUI:Destroy() end
		end)
		task.wait(0.1)
	end
	env.GakuranAP_Running = true

	local holding = false
	local holdUntil = 0
	local parryBusy = false
	local dashBusy = false
	local lastTapAt = 0
	local lastDashAt = 0
	local npcScanAt = 0
	local enemyCache = {}
	local stats = { parry = 0, block = 0, dash = 0 }
	local flashText = ""
	local flashUntil = 0

	-- ===== НАСТРОЙКИ =====
	local CFG = {
		autoParry   = true,   -- тап F в окно пари
		autoBlock   = true,   -- холд F пока враг атакует
		autoDash    = false,  -- тап Q (даш) от M2, если пари выкл
		usePlayers  = true,   -- враги: игроки
		useNPCs     = true,   -- враги: NPC / мобы
		facingCheck = true,   -- парить только если враг смотрит на тебя
		smartDetect = true,   -- ловить атаки и без ключевых слов в имени
		debugLog    = false,  -- лог имён анимаций атак в консоль
		parryTiming = 0.65,   -- точка срабатывания пари (0.40 .. 0.90)
		range       = 12,     -- радиус действия (ступни)
		cooldown    = 0.28,   -- мин. пауза между тапами (сек)
		holdBlock   = 0.25,   -- сколько держать блок после атаки (сек)
	}

	local function loadCfg()
		local ok2, data = pcall(function()
			if not isfile then return nil end
			if not isfile("GakuranAP_Settings.json") then return nil end
			return HttpService:JSONDecode(readfile("GakuranAP_Settings.json"))
		end)
		if ok2 and type(data) == "table" then
			for k, v in pairs(data) do
				if CFG[k] ~= nil then CFG[k] = v end
			end
		end
	end

	local function saveCfg()
		pcall(function()
			if not writefile then return end
			writefile("GakuranAP_Settings.json", HttpService:JSONEncode(CFG))
		end)
	end

	loadCfg()

	-- ===== СИМУЛЯЦИЯ КЛАВИШ (F = блок/пари, Q = даш) =====
	local function toNum(code)
		return typeof(code) == "EnumItem" and code.Value or code
	end

	local function sendKey(code, down)
		if type(keypress) == "function" then
			local okk = pcall(function()
				if down then keypress(toNum(code)) else keyrelease(toNum(code)) end
			end)
			if okk then return end
		end
		pcall(function()
			VIM:SendKeyEvent(down, code, false, game)
		end)
	end

	local function tapKey(code)
		sendKey(code, false)
		task.wait(0.025)
		sendKey(code, true)
		task.wait(0.05)
		sendKey(code, false)
	end

	-- ===== ПОИСК АТАК ПО АНИМАЦИЯМ =====
	local ATTACK_KW = {
		"attack","atk","swing","slash","punch","kick","strike","combo",
		"light","heavy","m1","m2","jab","cross","hook","uppercut",
		"roundhouse","blitz","gatling","fury","strong","power","rush",
		"barrage","smash","thrust","spin",
	}
	local HEAVY_KW = { "heavy","m2","strong","power","special","fury","smash","overhead" }
	local IGNORE_KW = {
		"idle","run","walk","jump","dodge","block","parry","stun","ragdoll",
		"emote","dash","death","fall","swim","climb","sit","tool","hold",
		"carry","pickup","drop","laugh","wave","taunt","cheer","clap","stand",
	}

	local function kwMatch(name, list)
		for _, w in ipairs(list) do
			if name:find(w, 1, true) then return true end
		end
		return false
	end

	local function findAttackTrack(hum)
		-- проход 1: явные ключевые слова
		for _, tr in ipairs(hum:GetPlayingAnimationTracks()) do
			if tr.IsPlaying and tr.Speed > 0.1 then
				local n = (tr.Name or ""):lower()
				if kwMatch(n, ATTACK_KW) then return tr, n end
			end
		end
		-- проход 2: "умное" определение (любая не-игровая анимация)
		if CFG.smartDetect then
			for _, tr in ipairs(hum:GetPlayingAnimationTracks()) do
				if tr.IsPlaying and tr.Speed > 0.1 then
					local n = (tr.Name or ""):lower()
					if not kwMatch(n, IGNORE_KW) then return tr, n end
				end
			end
		end
		return nil
	end

	local function trackProgress(tr)
		local len = tr.Length
		if not len or len <= 0 then return 0 end
		return tr.TimePosition / len
	end

	-- ===== КЭШ ВРАГОВ =====
	local function addEnemy(char)
		if not char or enemyCache[char] then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return end

		local isPlayer = Players:GetPlayerFromCharacter(char) ~= nil
		if isPlayer then
			if not CFG.usePlayers then return end
		else
			if not CFG.useNPCs then return end
		end

		enemyCache[char] = { hum = hum, active = nil, tapped = false }
	end

	Players.PlayerAdded:Connect(function(p)
		if p == LP then return end
		p.CharacterAdded:Connect(function(char) addEnemy(char) end)
		if p.Character then addEnemy(p.Character) end
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LP then
			p.CharacterAdded:Connect(function(char) addEnemy(char) end)
			if p.Character then addEnemy(p.Character) end
		end
	end

	local function scanNPCs()
		-- скан всех Humanoid в Workspace каждые ~3с (подходит для мобильного)
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("Humanoid") and v.Parent and v.Parent ~= LP.Character then
				if not Players:GetPlayerFromCharacter(v.Parent) then
					addEnemy(v.Parent)
				end
			end
		end
	end

	-- ===== ОЦЕНКА УГРОЗЫ ОТ ВРАГА =====
	local function evalEnemy(char, data, myRoot)
		local root = char:FindFirstChild("HumanoidRootPart")
		local hum = data.hum
		if not root or not hum or hum.Health <= 0 then return nil end

		local dist = (root.Position - myRoot.Position).Magnitude
		if dist > CFG.range then return nil end

		local tr, trName = findAttackTrack(hum)
		if not tr then
			data.active, data.tapped = nil, false
			return nil
		end

		if CFG.debugLog and tr ~= data.active then
			print(string.format("[GakuranAP] атака врага: %s (дист %.1f)", trName, dist))
		end

		if tr ~= data.active then
			data.active, data.tapped = tr, false
		end
		if not tr.IsPlaying then
			data.active, data.tapped = nil, false
			return nil
		end

		local prog = trackProgress(tr)
		local inWindow = prog >= CFG.parryTiming - 0.08 and prog <= CFG.parryTiming + 0.08

		local facing = true
		if CFG.facingCheck then
			local dirToMe = (myRoot.Position - root.Position).Unit
			facing = root.CFrame.LookVector:Dot(dirToMe) > 0.15
		end

		return {
			data = data,
			isHeavy = kwMatch((trName or ""):lower(), HEAVY_KW),
			inWindow = inWindow,
			facing = facing,
			dist = dist,
		}
	end

	local function flash(txt)
		flashText = txt
		flashUntil = tick() + 0.18
	end

	-- ===== ОСНОВНОЙ ЦИКЛ БОЯ =====
	task.spawn(function()
		while env.GakuranAP_Running do
			task.wait(1 / 30)

			local myChar = LP.Character
			local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
			local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
			if not (myRoot and myHum and myHum.Health > 0) then
				if holding then
					sendKey(Enum.KeyCode.F, false)
					holding = false
				end
				continue
			end

			-- чистка кэша + скан NPC
			for char in pairs(enemyCache) do
				if char.Parent == nil then enemyCache[char] = nil end
			end
			if CFG.useNPCs and tick() > npcScanAt then
				npcScanAt = tick() + 3
				scanNPCs()
			end

			-- ищем врага в окне пари
			local threat = nil
			for char, data in pairs(enemyCache) do
				local t = evalEnemy(char, data, myRoot)
				if t and t.inWindow and t.facing then
					threat = t
					break
				end
			end

			-- АВТО-ПАРИ: один тап F на одну анимацию атаки
			if threat and CFG.autoParry and not parryBusy
				and not threat.data.tapped and tick() - lastTapAt >= CFG.cooldown then
				threat.data.tapped = true
				parryBusy = true
				task.spawn(function()
					tapKey(Enum.KeyCode.F)
					parryBusy = false
					lastTapAt = tick()
					stats.parry = stats.parry + 1
					flash("ПАРИ!")
				end)
			end

			-- АВТО-ДАШ от M2 (если пари выключено — M2 нельзя заблокировать)
			if threat and threat.isHeavy and CFG.autoDash and not CFG.autoParry
				and not dashBusy and tick() - lastDashAt >= 1.0 then
				dashBusy = true
				task.spawn(function()
					tapKey(Enum.KeyCode.Q)
					dashBusy = false
					lastDashAt = tick()
					stats.dash = stats.dash + 1
					flash("ДАШ!")
				end)
			end

			-- АВТО-БЛОК: держим F, пока любой враг в радиусе атакует
			local anyAttack = false
			for char, data in pairs(enemyCache) do
				if evalEnemy(char, data, myRoot) then
					anyAttack = true
					break
				end
			end
			if CFG.autoBlock and anyAttack then
				if not holding then
					sendKey(Enum.KeyCode.F, true)
					holding = true
					stats.block = stats.block + 1
					flash("БЛОК")
				end
				holdUntil = tick() + CFG.holdBlock
			elseif holding and tick() >= holdUntil then
				sendKey(Enum.KeyCode.F, false)
				holding = false
			end
		end
	end)

	-- ============================================================
	--  GUI: ЧЁРНО-БЕЛОЕ МЕНЮ (монохром, перетаскивание)
	-- ============================================================
	local C = {
		bg    = Color3.fromRGB(10, 10, 10),
		panel = Color3.fromRGB(19, 19, 19),
		line  = Color3.fromRGB(235, 235, 235),
		white = Color3.fromRGB(245, 245, 245),
		dim   = Color3.fromRGB(125, 125, 125),
		ink   = Color3.fromRGB(8, 8, 8),
	}

	local function mk(className, props)
		local inst = Instance.new(className)
		for k, v in pairs(props) do inst[k] = v end
		return inst
	end

	local gui = mk("ScreenGui", {
		Name = "GakuranAP",
		Parent = LP:WaitForChild("PlayerGui"),
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		DisplayOrder = 100,
	})
	env.GakuranAP_GUI = gui

	local main = mk("Frame", {
		Name = "Main",
		Parent = gui,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 60),
		Size = UDim2.new(0, 264, 0, 476),
		BackgroundColor3 = C.bg,
		BorderColor3 = C.line,
		BorderSizePixel = 2,
		Active = true,
	})

	-- === Тайтл-бар (перетаскивание) ===
	local title = mk("Frame", {
		Parent = main,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = C.white,
		BorderSizePixel = 0,
		Active = true,
	})
	mk("TextLabel", {
		Parent = title,
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(0, 190, 0, 34),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Text = "GAKURAN // AUTO-PARRY",
		TextColor3 = C.ink,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local minBtn = mk("TextButton", {
		Parent = title,
		Position = UDim2.new(0, 214, 0, 3),
		Size = UDim2.new(0, 20, 0, 28),
		BackgroundColor3 = C.bg,
		BorderColor3 = C.ink,
		BorderSizePixel = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Text = "-",
		TextColor3 = C.white,
		AutoButtonColor = false,
	})
	local closeBtn = mk("TextButton", {
		Parent = title,
		Position = UDim2.new(0, 238, 0, 3),
		Size = UDim2.new(0, 20, 0, 28),
		BackgroundColor3 = C.bg,
		BorderColor3 = C.ink,
		BorderSizePixel = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		Text = "×",
		TextColor3 = C.white,
		AutoButtonColor = false,
	})

	-- перетаскивание
	local function makeDraggable(frame)
		local dragging, dragStart, startPos = false
		frame.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = inp.Position
				startPos = main.Position
			end
		end)
		frame.InputChanged:Connect(function(inp)
			if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
				or inp.UserInputType == Enum.UserInputType.Touch) then
				local delta = inp.Position - dragStart
				main.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + delta.X,
					startPos.Y.Scale, startPos.Y.Offset + delta.Y
				)
			end
		end)
		UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
	end
	makeDraggable(title)

	local body = mk("Frame", {
		Parent = main,
		Position = UDim2.new(0, 0, 0, 34),
		Size = UDim2.new(1, 0, 0, 442),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	})

	local function makeSection(y, text)
		return mk("TextLabel", {
			Parent = body,
			Position = UDim2.new(0, 10, 0, y),
			Size = UDim2.new(0, 244, 0, 16),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			Text = "- " .. text .. " -",
			TextColor3 = C.dim,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	-- === Тогглы ===
	local function makeToggle(y, label, key)
		local row = mk("TextButton", {
			Parent = body,
			Position = UDim2.new(0, 8, 0, y),
			Size = UDim2.new(0, 248, 0, 24),
			BackgroundColor3 = C.panel,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
		})
		local box = mk("Frame", {
			Parent = row,
			Position = UDim2.new(0, 5, 0, 4),
			Size = UDim2.new(0, 16, 0, 16),
			BackgroundColor3 = C.bg,
			BorderColor3 = C.line,
			BorderSizePixel = 1,
		})
		local lbl = mk("TextLabel", {
			Parent = row,
			Position = UDim2.new(0, 27, 0, 0),
			Size = UDim2.new(0, 215, 0, 24),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 12,
			Text = label,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local function refresh()
			local on = CFG[key]
			box.BackgroundColor3 = on and C.white or C.bg
			lbl.TextColor3 = on and C.white or C.dim
		end
		row.MouseButton1Click:Connect(function()
			CFG[key] = not CFG[key]
			refresh()
			saveCfg()
		end)
		refresh()
		return row
	end

	-- === Слайдеры ===
	local function makeSlider(y, label, key, min, max, step, fmt)
		local lbl = mk("TextLabel", {
			Parent = body,
			Position = UDim2.new(0, 10, 0, y),
			Size = UDim2.new(0, 244, 0, 16),
			BackgroundTransparency = 1,
			Font = Enum.Font.Gotham,
			TextSize = 11,
			TextColor3 = C.dim,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		local track = mk("Frame", {
			Parent = body,
			Position = UDim2.new(0, 10, 0, y + 18),
			Size = UDim2.new(0, 244, 0, 6),
			BackgroundColor3 = C.panel,
			BorderColor3 = C.line,
			BorderSizePixel = 1,
			Active = true,
		})
		local fill = mk("Frame", {
			Parent = track,
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = C.white,
			BorderSizePixel = 0,
		})
		local knob = mk("TextButton", {
			Parent = track,
			Position = UDim2.new(0, -7, 0, -6),
			Size = UDim2.new(0, 14, 0, 18),
			BackgroundColor3 = C.white,
			BorderColor3 = C.line,
			BorderSizePixel = 1,
			Text = "",
			AutoButtonColor = false,
		})

		local dragging = false

		local function setFromX(px)
			local rel = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			local v = math.clamp(math.round((min + (max - min) * rel) / step) * step, min, max)
			CFG[key] = v
			update()
			saveCfg()
		end

		local function update()
			lbl.Text = label .. ":  " .. fmt(CFG[key])
			local rel = (CFG[key] - min) / (max - min)
			fill.Size = UDim2.new(rel, 0, 1, 0)
			knob.Position = UDim2.new(rel, -7, 0, -6)
		end

		local function begin(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				setFromX(inp.Position.X)
			end
		end
		track.InputBegan:Connect(begin)
		knob.InputBegan:Connect(begin)
		track.InputChanged:Connect(function(inp)
			if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
				or inp.UserInputType == Enum.UserInputType.Touch) then
				setFromX(inp.Position.X)
			end
		end)
		UIS.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1
				or inp.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)

		update()
	end

	-- === Сборка меню ===
	makeSection(6, "БОЙ")
	makeToggle(24, "Авто-пари (тап F)", "autoParry")
	makeToggle(50, "Автоблок (холд F)", "autoBlock")
	makeToggle(76, "Даш от M2 (Q)", "autoDash")
	makeToggle(102, "Враги: игроки", "usePlayers")
	makeToggle(128, "Враги: NPC / мобы", "useNPCs")
	makeToggle(154, "Фейс-чек (смотрит на тебя)", "facingCheck")
	makeToggle(180, "Умное определение атак", "smartDetect")
	makeToggle(206, "Лог анимаций (консоль)", "debugLog")

	makeSection(242, "НАСТРОЙКИ")
	makeSlider(260, "Тайминг пари", "parryTiming", 0.40, 0.90, 0.01,
		function(v) return string.format("%.0f%%", v * 100) end)
	makeSlider(302, "Дальность", "range", 4, 20, 1,
		function(v) return v .. " стд" end)
	makeSlider(344, "Кулдаун тапа", "cooldown", 0.10, 0.60, 0.01,
		function(v) return string.format("%.0f мс", v * 1000) end)

	-- статус-бар
	local statusBar = mk("Frame", {
		Parent = body,
		Position = UDim2.new(0, 8, 0, 388),
		Size = UDim2.new(0, 248, 0, 24),
		BackgroundColor3 = C.panel,
		BorderColor3 = C.line,
		BorderSizePixel = 1,
	})
	local countersLbl = mk("TextLabel", {
		Parent = statusBar,
		Position = UDim2.new(0, 6, 0, 0),
		Size = UDim2.new(0, 160, 0, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = C.white,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local statusLbl = mk("TextLabel", {
		Parent = statusBar,
		Position = UDim2.new(0, 166, 0, 0),
		Size = UDim2.new(0, 76, 0, 24),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		TextColor3 = C.dim,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	-- футер
	local resetBtn = mk("TextButton", {
		Parent = body,
		Position = UDim2.new(0, 8, 0, 418),
		Size = UDim2.new(0, 56, 0, 20),
		BackgroundColor3 = C.white,
		BorderSizePixel = 0,
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		Text = "СБРОС",
		TextColor3 = C.ink,
		AutoButtonColor = false,
	})
	mk("TextLabel", {
		Parent = body,
		Position = UDim2.new(0, 70, 0, 418),
		Size = UDim2.new(0, 186, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 10,
		Text = "F - блок/пари  ·  Q - даш",
		TextColor3 = C.dim,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	resetBtn.MouseButton1Click:Connect(function()
		stats.parry, stats.block, stats.dash = 0, 0, 0
	end)

	-- сворачивание / закрытие
	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		body.Visible = not minimized
		main.Size = minimized and UDim2.new(0, 264, 0, 34) or UDim2.new(0, 264, 0, 476)
		minBtn.Text = minimized and "+" or "-"
	end)
	closeBtn.MouseButton1Click:Connect(function()
		env.GakuranAP_Running = false
		env.GakuranAP_GUI = nil
		if holding then sendKey(Enum.KeyCode.F, false) end
		gui:Destroy()
	end)

	-- обновление статуса
	local function updateStatus()
		if tick() < flashUntil then
			statusLbl.Text = "> " .. flashText
			statusLbl.TextColor3 = C.white
		else
			statusLbl.Text = "> ожидание"
			statusLbl.TextColor3 = C.dim
		end
		countersLbl.Text = string.format(
			"ПАРИ: %d  ·  БЛОК: %d  ·  ДАШ: %d",
			stats.parry, stats.block, stats.dash
		)
	end
	task.spawn(function()
		while env.GakuranAP_Running and gui.Parent do
			task.wait(0.1)
			updateStatus()
		end
	end)

	print("[GakuranAP] загружен. F = блок/пари, Q = даш.")
end)

if not ok then
	warn("[GakuranAP] Ошибка запуска: " .. tostring(err))
end
