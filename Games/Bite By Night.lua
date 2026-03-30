local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local workspace = game:GetService("Workspace")

local Cresent = loadstring(game:HttpGet("https://raw.githubusercontent.com/Dawsig/lib/refs/heads/main/alotofit"))()

local Window = Cresent:Create({
	Title = "Bite By Night",
	Description = "By Cresent",
	Config = {
		Loader = true
	}
})

local function notify(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 2
		})
	end)
end

local function getAliveFolder()
	return workspace:FindFirstChild("PLAYERS") and workspace.PLAYERS:FindFirstChild("ALIVE")
end

local function getKillerFolder()
	return workspace:FindFirstChild("PLAYERS") and workspace.PLAYERS:FindFirstChild("KILLER")
end

local function getAliveNames()
	local t = {"Closest"}
	local alive = getAliveFolder()
	if alive then
		for _, v in ipairs(alive:GetChildren()) do
			table.insert(t, v.Name)
		end
	end
	return t
end

local hometab = Window:Tab("Home")
local maintab = Window:Tab("Main")
local survivortab = Window:Tab("Survivor")
local killertab = Window:Tab("Killer")
local vistab = Window:Tab("Visual")
local tpstab = Window:Tab("Teleport")
local infotab = Window:Tab("Info")

hometab:Button("Bite By Night", function() end)
hometab:Button("Show / Hide GUI: Right Alt", function() end)
hometab:Dropdown({
	Title = "Status",
	Desc = "Script state",
	Selection = {"Released"},
	Default = "Released",
	Locked = true
}, function() end)

local pp = Instance.new("Part")
pp.Name = "pp"
pp.Size = Vector3.new(50, 2, 50)
pp.Position = Vector3.new(0, 1000, 0)
pp.Anchored = true
pp.CanCollide = true
pp.Material = Enum.Material.ForceField
pp.Color = Color3.fromRGB(0, 170, 255)
pp.Transparency = 0.3
pp.Parent = workspace

-- MAIN
maintab:Section("Character Movement Features.")

local infiniteSprint = false
local sprintConn = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

maintab:Toggle("Infinite Sprint", false, function(state)
	infiniteSprint = state
	if sprintConn then
		sprintConn:Disconnect()
		sprintConn = nil
	end

	if state then
		sprintConn = RunService.Heartbeat:Connect(function()
			if not infiniteSprint then return end
			local char = Players.LocalPlayer.Character
			if not char then return end

			if isMobile then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum and hum.MoveDirection.Magnitude > 0 then
					char:SetAttribute("WalkSpeed", 24)
				else
					char:SetAttribute("WalkSpeed", 12)
				end
			else
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
					char:SetAttribute("WalkSpeed", 25)
				else
					char:SetAttribute("WalkSpeed", 12)
				end
			end
		end)
		notify("Infinite Sprint", "Enabled.")
		else
		local char = Players.LocalPlayer.Character
		if char then
			char:SetAttribute("WalkSpeed", 12)
		end
		notify("Infinite Sprint", "Disabled.")
	end
end)

local jumpBoost = false
local jpLoop, jpCA = nil, nil

maintab:Toggle("Allow Jumping", false, function(state)
	jumpBoost = state

	local function applyJumpPower()
		local char = Players.LocalPlayer.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end

		if hum.UseJumpPower then
			hum.JumpPower = state and 1.5 or 0
		else
			hum.JumpHeight = state and 1.5 or 0
		end
	end

	if jpLoop then jpLoop:Disconnect() jpLoop = nil end
	if jpCA then jpCA:Disconnect() jpCA = nil end

	if state then
		applyJumpPower()

		local currentHum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if currentHum then
			jpLoop = currentHum:GetPropertyChangedSignal("JumpPower"):Connect(applyJumpPower)
		end

		jpCA = Players.LocalPlayer.CharacterAdded:Connect(function(newChar)
			local hum = newChar:WaitForChild("Humanoid")
			applyJumpPower()
			if jpLoop then jpLoop:Disconnect() end
			jpLoop = hum:GetPropertyChangedSignal("JumpPower"):Connect(applyJumpPower)
		end)

		notify("Allow Jumping", "Enabled.")
	else
		applyJumpPower()
		notify("Allow Jumping", "Disabled.")
	end
end)

local flying = false
local flyConn = nil

maintab:Toggle("Flight", false, function(state)
	flying = state
	if flyConn then
		flyConn:Disconnect()
		flyConn = nil
	end

	local plr = Players.LocalPlayer
	local Camera = workspace.CurrentCamera

	if flying then
		local char = plr.Character
		if not char then return end

		local root = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not root or not hum then return end

		hum.PlatformStand = true
		root.Anchored = true

		local function noCollide()
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end

		noCollide()

		flyConn = RunService.RenderStepped:Connect(function(dt)
			if not flying or not root or not root.Parent then return end
			noCollide()

			local move = Vector3.zero
			local speed = 125

			if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= Camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Camera.CFrame.RightVector end

			if move.Magnitude > 0 then
				root.CFrame = root.CFrame + (move.Unit * speed * dt)
			end

			root.CFrame = CFrame.new(root.Position, root.Position + Camera.CFrame.LookVector)
		end)

		notify("Flight", "Enabled.")
	else
		local char = plr.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then hum.PlatformStand = false end
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then root.Anchored = false end
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
		notify("Flight", "Disabled.")
	end
end)

local noclipEnabled = false
local noclipConn = nil

maintab:Toggle("Noclip", false, function(state)
	noclipEnabled = state
	if noclipConn then
		noclipConn:Disconnect()
		noclipConn = nil
	end

	if state then
		noclipConn = RunService.Stepped:Connect(function()
			if not noclipEnabled then return end
			local char = Players.LocalPlayer.Character
			if not char then return end
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end)
		notify("Noclip", "Enabled.")
	else
		local char = Players.LocalPlayer.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = true
				end
			end
		end
		notify("Noclip", "Disabled.")
	end
end)

local lockOnEnabled = false
local lockedTarget = nil
local inputConnection = nil
local renderConnection = nil
local camera = workspace.CurrentCamera
local player = Players.LocalPlayer

maintab:Toggle("Lock On", false, function()
	lockOnEnabled = not lockOnEnabled
	notify("Lock On", lockOnEnabled and "Enabled." or "Disabled.")

	if lockOnEnabled then
		inputConnection = UserInputService.InputBegan:Connect(function(input, gp)
			if gp then return end
			if input.UserInputType == Enum.UserInputType.MouseButton2 then
				if lockedTarget then
					lockedTarget = nil
				else
					local char = player.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if not hrp then return end

					local closest, shortest = nil, math.huge
					for _, other in ipairs(Players:GetPlayers()) do
						if other ~= player and other.Character and other.Character:FindFirstChild("HumanoidRootPart") then
							local dist = (hrp.Position - other.Character.HumanoidRootPart.Position).Magnitude
							if dist < shortest then
								shortest = dist
								closest = other
							end
						end
					end

					if closest then
						lockedTarget = closest.Character:FindFirstChild("HumanoidRootPart")
					end
				end
			end
		end)

		renderConnection = RunService.RenderStepped:Connect(function()
			if lockedTarget then
				camera.CFrame = CFrame.new(camera.CFrame.Position, lockedTarget.Position)
			end
		end)
	else
		lockedTarget = nil
		if inputConnection then inputConnection:Disconnect() inputConnection = nil end
		if renderConnection then renderConnection:Disconnect() renderConnection = nil end
	end
end)

local oldLighting = {}

maintab:Toggle("Full Bright", false, function(state)
	if state then
		oldLighting.Brightness = Lighting.Brightness
		oldLighting.ClockTime = Lighting.ClockTime
		oldLighting.FogEnd = Lighting.FogEnd
		oldLighting.GlobalShadows = Lighting.GlobalShadows
		oldLighting.Ambient = Lighting.Ambient

		Lighting.Brightness = 5
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(255,255,255)
		notify("Full Bright", "Enabled.")
	else
		if next(oldLighting) then
			Lighting.Brightness = oldLighting.Brightness
			Lighting.ClockTime = oldLighting.ClockTime
			Lighting.FogEnd = oldLighting.FogEnd
			Lighting.GlobalShadows = oldLighting.GlobalShadows
			Lighting.Ambient = oldLighting.Ambient
		end
		notify("Full Bright", "Disabled.")
	end
end)

-- SURVIVOR
survivortab:Section("Survivor Features.")

local AutoGen = false
local genConn = nil

survivortab:Toggle("Auto Generator", false, function(v)
	AutoGen = v
	if genConn then genConn:Disconnect() genConn = nil end

	if AutoGen then
		genConn = RunService.RenderStepped:Connect(function()
			local plr = Players.LocalPlayer
			if plr.PlayerGui:FindFirstChild("Gen") then
				plr.PlayerGui.Gen.GeneratorMain.Event:FireServer(true)
			end
		end)
		notify("Auto Generator", "Enabled.")
	else
		notify("Auto Generator", "Disabled.")
	end
end)

local autoEscape = false
local autoEscapeConn = nil

survivortab:Toggle("Auto Escape", false, function(state)
	autoEscape = state
	if autoEscapeConn then autoEscapeConn:Disconnect() autoEscapeConn = nil end

	if state then
		local teleported = false
		autoEscapeConn = RunService.RenderStepped:Connect(function()
			if teleported or not autoEscape then return end
			local char = player.Character
			if not char then return end
			if not workspace.GAME.CAN_ESCAPE.Value then return end
			if char.Parent ~= workspace.PLAYERS.ALIVE then return end

			local map = workspace.MAPS:FindFirstChild("GAME MAP")
			if not map then return end
			local escapes = map:FindFirstChild("Escapes")
			if not escapes then return end

			for _, part in pairs(escapes:GetChildren()) do
				if part:IsA("BasePart")
					and part:GetAttribute("Enabled")
					and part:FindFirstChildOfClass("Highlight")
					and part:FindFirstChildOfClass("Highlight").Enabled then

					local root = char:FindFirstChild("HumanoidRootPart")
					if root then
						teleported = true
						root.Anchored = true
						char.PrimaryPart.CFrame = part.CFrame

						task.delay(1.5, function()
							root.Anchored = false
						end)

						task.delay(10, function()
							teleported = false
						end)
					end
				end
			end
		end)
		notify("Auto Escape", "Enabled.")
	else
		notify("Auto Escape", "Disabled.")
	end
end)

local dotConn = nil

survivortab:Toggle("Auto Barricade", false, function(state)
	if dotConn then dotConn:Disconnect() dotConn = nil end

	if state then
		dotConn = RunService.RenderStepped:Connect(function()
			local gui = player:WaitForChild("PlayerGui")
			local dot = gui:FindFirstChild("Dot")
			if dot and dot:IsA("ScreenGui") then
				local container = dot:FindFirstChild("Container")
				if container then
					local frame = container:FindFirstChild("Frame")
					if frame and frame:IsA("GuiObject") then
						if not dot.Enabled then
							dot:Destroy()
							return
						end
						frame.AnchorPoint = Vector2.new(0.5, 0.5)
						frame.Position = UDim2.new(0.5, 0, 0.5, 0)
					end
				end
			end
		end)
		notify("Auto Barricade", "Enabled.")
	else
		notify("Auto Barricade", "Disabled.")
	end
end)

local safeTeleport = false
local lastPosition = nil

survivortab:Toggle("Safety Area", false, function(state)
	safeTeleport = state
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if state then
		lastPosition = root.CFrame
		root.CFrame = CFrame.new(0, 1003, 0)
		notify("Safety Area", "Enabled.")
	else
		if lastPosition then
			root.CFrame = lastPosition
			lastPosition = nil
		end
		notify("Safety Area", "Disabled.")
	end
end)

local viewKiller = false
local killerAddedConn, killerRemovedConn = nil, nil

survivortab:Toggle("View Killer", false, function(state)
	viewKiller = state
	local cam = workspace.CurrentCamera
	local killerFolder = getKillerFolder()

	if killerAddedConn then killerAddedConn:Disconnect() killerAddedConn = nil end
	if killerRemovedConn then killerRemovedConn:Disconnect() killerRemovedConn = nil end

	if state then
		local function setKillerCamera(killerChar)
			local hum = killerChar:FindFirstChildOfClass("Humanoid")
			if hum then cam.CameraSubject = hum end
		end

		if killerFolder then
			local killer = killerFolder:GetChildren()[1]
			if killer then
				setKillerCamera(killer)
			end

			killerAddedConn = killerFolder.ChildAdded:Connect(function(child)
				setKillerCamera(child)
			end)

			killerRemovedConn = killerFolder.ChildRemoved:Connect(function()
				if viewKiller then
					local char = player.Character
					if char then
						local hum = char:FindFirstChildOfClass("Humanoid")
						if hum then cam.CameraSubject = hum end
					end
				end
			end)
		end

		notify("View Killer", "Enabled.")
	else
		local char = player.Character
		if char then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then cam.CameraSubject = hum end
		end
		notify("View Killer", "Disabled.")
	end
end)

local antiDeath = {
	enabled = false,
	threshold = 30,
	conn = nil,
	lastPos = nil,
	teleported = false,
	debounce = false
}

survivortab:Toggle("Anti Death", false, function(state)
	antiDeath.enabled = state
	if antiDeath.conn then antiDeath.conn:Disconnect() antiDeath.conn = nil end

	if state then
		antiDeath.conn = RunService.Heartbeat:Connect(function()
			local char = player.Character
			if not char then return end

			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum then return end

			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then return end

			if hum.Health < antiDeath.threshold and hum.Health > 0 and not antiDeath.teleported and not antiDeath.debounce then
				antiDeath.debounce = true
				antiDeath.teleported = true
				antiDeath.lastPos = root.CFrame
				root.CFrame = pp.CFrame + Vector3.new(0, 5, 0)

				task.delay(1, function()
					antiDeath.debounce = false
				end)
			elseif hum.Health >= antiDeath.threshold and antiDeath.teleported and antiDeath.lastPos and not antiDeath.debounce then
				antiDeath.debounce = true
				root.CFrame = antiDeath.lastPos
				antiDeath.lastPos = nil
				antiDeath.teleported = false

				task.delay(1, function()
					antiDeath.debounce = false
				end)
			end
		end)
		notify("Anti Death", "Enabled.")
	else
		antiDeath.lastPos = nil
		antiDeath.teleported = false
		antiDeath.debounce = false
		notify("Anti Death", "Disabled.")
	end
end)

survivortab:Slider("Health Threshold", 30, 100, 80, function(v)
	antiDeath.threshold = v
end)

-- VISUAL
vistab:Section("Visual Features.")

local esp = { survivors = {}, killers = {}, generators = {} }

local function newBox(obj, color)
	local root = obj:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local g = Instance.new("BillboardGui")
	g.Name = "ESPBox"
	g.Size = UDim2.new(4, 0, 6, 0)
	g.AlwaysOnTop = true
	g.Adornee = root
	g.Parent = root

	local t = Instance.new("Frame")
	t.Size = UDim2.new(1, 0, 0, 2)
	t.BackgroundColor3 = color
	t.BorderSizePixel = 0
	t.Parent = g

	local b = Instance.new("Frame")
	b.Size = UDim2.new(1, 0, 0, 2)
	b.Position = UDim2.new(0, 0, 1, -2)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Parent = g

	local l = Instance.new("Frame")
	l.Size = UDim2.new(0, 2, 1, 0)
	l.BackgroundColor3 = color
	l.BorderSizePixel = 0
	l.Parent = g

	local r = Instance.new("Frame")
	r.Size = UDim2.new(0, 2, 1, 0)
	r.Position = UDim2.new(1, -2, 0, 0)
	r.BackgroundColor3 = color
	r.BorderSizePixel = 0
	r.Parent = g

	return g
end

local function add(tbl, obj, color)
	if not tbl[obj] and obj then
		tbl[obj] = newBox(obj, color)
	end
end

local function clear(tbl)
	for obj, b in pairs(tbl) do
		if b then b:Destroy() end
		tbl[obj] = nil
	end
end

vistab:Toggle("Survivor ESP", false, function(state)
	local alive = getAliveFolder()
	if not alive then return end

	if state then
		notify("Survivor ESP", "Enabled.")
		for _, v in ipairs(alive:GetChildren()) do
			if v:IsA("Model") then
				add(esp.survivors, v, Color3.fromRGB(80, 180, 255))
			end
		end
		esp.survivorConn = alive.ChildAdded:Connect(function(v)
			if v:IsA("Model") then
				add(esp.survivors, v, Color3.fromRGB(80, 180, 255))
			end
		end)
	else
		notify("Survivor ESP", "Disabled.")
		if esp.survivorConn then esp.survivorConn:Disconnect() end
		clear(esp.survivors)
	end
end)

vistab:Toggle("Killer ESP", false, function(state)
	local killers = getKillerFolder()
	if not killers then return end

	if state then
		notify("Killer ESP", "Enabled.")
		for _, v in ipairs(killers:GetChildren()) do
			if v:IsA("Model") then
				add(esp.killers, v, Color3.fromRGB(255, 80, 80))
			end
		end
		esp.killerConn = killers.ChildAdded:Connect(function(v)
			if v:IsA("Model") then
				add(esp.killers, v, Color3.fromRGB(255, 80, 80))
			end
		end)
	else
		notify("Killer ESP", "Disabled.")
		if esp.killerConn then esp.killerConn:Disconnect() end
		clear(esp.killers)
	end
end)

vistab:Toggle("Generator ESP", false, function(state)
	if state then
		notify("Generator ESP", "Enabled.")
		task.spawn(function()
			repeat task.wait() until workspace:FindFirstChild("MAPS")
			for _, v in ipairs(workspace:GetDescendants()) do
				if v:IsA("Model") and v.Name == "Generator" then
					add(esp.generators, v, Color3.fromRGB(0, 255, 100))
				end
			end
			esp.genConn = workspace.DescendantAdded:Connect(function(v)
				if v:IsA("Model") and v.Name == "Generator" then
					add(esp.generators, v, Color3.fromRGB(0, 255, 100))
				end
			end)
		end)
	else
		notify("Generator ESP", "Disabled.")
		if esp.genConn then esp.genConn:Disconnect() end
		clear(esp.generators)
	end
end)

-- TELEPORT
tpstab:Section("Teleport Features.")

local function getRoot()
	local char = player.Character or player.CharacterAdded:Wait()
	return char, char:WaitForChild("HumanoidRootPart")
end

local function getOrderedGenerators()
	local folder = workspace.MAPS["GAME MAP"].Generators
	local models = {}
	for _, v in ipairs(folder:GetChildren()) do
		if v:IsA("Model") then
			table.insert(models, v)
		end
	end
	table.sort(models, function(a, b)
		return (a:GetAttribute("Order") or 0) < (b:GetAttribute("Order") or 0)
	end)
	return models
end

local function teleportToModel(model)
	if not model then return end
	local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if not part then return end
	local _, root = getRoot()
	root.CFrame = CFrame.new(part.CFrame.Position + part.CFrame.LookVector * 5)
end

local generatorIndex = 1
tpstab:Button("Generator TP", function()
	local models = getOrderedGenerators()
	if #models == 0 then return end
	teleportToModel(models[generatorIndex])
	generatorIndex += 1
	if generatorIndex > #models then
		generatorIndex = 1
	end
end)

local batteryIndex = 1
local function setupBatteries()
	local batteries = {}
	local ignore = workspace:FindFirstChild("IGNORE")
	if not ignore then return batteries end

	for _, v in ipairs(ignore:GetDescendants()) do
		if v:IsA("MeshPart") and v.Name == "Battery" then
			table.insert(batteries, v)
		end
	end

	table.sort(batteries, function(a, b)
		return (a:GetAttribute("Order") or 0) < (b:GetAttribute("Order") or 0)
	end)

	return batteries
end

tpstab:Button("Battery TP", function()
	local _, root = getRoot()
	local batteries = setupBatteries()
	if #batteries == 0 then return end

	local battery = batteries[batteryIndex]
	root.CFrame = battery.CFrame + Vector3.new(0, 3, 0)

	batteryIndex += 1
	if batteryIndex > #batteries then
		batteryIndex = 1
	end
end)

-- KILLER
killertab:Section("Killer Features.")

local tpKill = false
local tpConn = nil
local targetName = "Closest"
local mode = "Closest"

killertab:Toggle("TP Kill", false, function(state)
	tpKill = state
	if tpConn then tpConn:Disconnect() tpConn = nil end

	if tpKill then
		notify("TP Kill", "Enabled.")

		tpConn = RunService.Heartbeat:Connect(function()
			local char = player.Character
			if not char then return end
			local root = char:FindFirstChild("HumanoidRootPart")
			if not root then return end

			local targetChar

			if mode == "Closest" then
				local closest
				local dist = math.huge
				local alive = getAliveFolder()
				if alive then
					for _, v in ipairs(alive:GetChildren()) do
						local hrp = v:FindFirstChild("HumanoidRootPart")
						if hrp then
							local d = (root.Position - hrp.Position).Magnitude
							if d < dist then
								dist = d
								closest = v
							end
						end
					end
				end
				targetChar = closest
			else
				local alive = getAliveFolder()
				if alive then
					targetChar = alive:FindFirstChild(targetName)
				end
			end

			if targetChar then
				local hrp = targetChar:FindFirstChild("HumanoidRootPart")
				if hrp then
					root.CFrame = hrp.CFrame * CFrame.new(0, 0, 3)
				end
			end
		end)
	else
		notify("TP Kill", "Disabled.")
	end
end)

killertab:Dropdown({
	Title = "Target Player",
	Desc = "No search needed",
	Selection = getAliveNames(),
	Default = "Closest"
}, function(v)
	if v == "Closest" then
		mode = "Closest"
		targetName = "Closest"
	else
		mode = "Specific"
		targetName = v
	end
end)

killertab:Dropdown({
	Title = "Mode",
	Desc = "Choose kill mode",
	Selection = {"Closest", "Random"},
	Default = "Closest"
}, function(v)
	mode = v
end)

-- INFO
infotab:Section("Information")
infotab:Button("GUI Controls: Right Alt", function() end)
infotab:Dropdown({
	Title = "Info",
	Desc = "Empty",
	Selection = {"NIL"},
	Default = "NIL",
	Locked = true
}, function() end)