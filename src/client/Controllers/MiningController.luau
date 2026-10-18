--!strict
-- Manuelles Mining auf Client-Seite (docs/03 §4, docs/09 §16): Klick mit ausgerüsteter
-- Spitzhacke → Schlag-Animation → Hit-Anfrage an den Server → nur bei bestätigtem Ergebnis
-- Feedback (Brocken, "+1 Coal"). Der Client berechnet keine Erzmenge.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Mines = require(Shared.Definitions.Mines)
local Ores = require(Shared.Definitions.Ores)
local Pickaxes = require(Shared.Definitions.Pickaxes)
local PrestigeLogic = require(Shared.Util.PrestigeLogic)

local Net = require(script.Parent.Parent.Net)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)
local PlotController = require(script.Parent.PlotController)
local ElevatorController = require(script.Parent.ElevatorController)
local NotificationController = require(script.Parent.NotificationController)
local HudController = require(script.Parent.HudController)
local SoundController = require(script.Parent.SoundController)
local AmbienceConfig = require(Shared.Config.AmbienceConfig)

local MiningController = {}

local PICKAXE_TOOL = "Pickaxe"
-- Zeit vom Klick bis zum "Aufprall" der Hacke (passt zur Standard-Slash-Animation)
local IMPACT_DELAY = 0.22

local player = Players.LocalPlayer
local busyUntil = 0

local function distanceToBox(point: Vector3, box: BasePart): number
	local localPoint = box.CFrame:PointToObjectSpace(point)
	local half = box.Size / 2
	local clamped = Vector3.new(
		math.clamp(localPoint.X, -half.X, half.X),
		math.clamp(localPoint.Y, -half.Y, half.Y),
		math.clamp(localPoint.Z, -half.Z, half.Z)
	)
	return (localPoint - clamped).Magnitude
end

-- Nächste eigene Abbauzone und Abstand dazu
local function nearestSlot(position: Vector3): (BasePart?, number)
	local plotId = PlotController.GetPlotId()
	local best: BasePart? = nil
	local bestDistance = math.huge
	for _, zone in CollectionService:GetTagged("MiningSlot") do
		if zone:IsA("BasePart") and zone:GetAttribute("PlotId") == plotId then
			local d = distanceToBox(position, zone)
			if d < bestDistance then
				best, bestDistance = zone, d
			end
		end
	end
	return best, bestDistance
end

-- Nächster Erzbrocken in der Wand als Trefferpunkt für Effekte
local function nearestOrePart(zone: BasePart, position: Vector3): BasePart?
	local slotFolder = zone.Parent
	local vein = slotFolder and slotFolder:FindFirstChild("OreVein")
	if not vein then
		return nil
	end
	local best: BasePart? = nil
	local bestDistance = math.huge
	for _, p in vein:GetChildren() do
		if p:IsA("BasePart") then
			local d = (p.Position - position).Magnitude
			if d < bestDistance then
				best, bestDistance = p, d
			end
		end
	end
	return best
end

local function spawnDebris(at: Vector3, color: Color3)
	for _ = 1, 6 do
		local chip = Instance.new("Part")
		chip.Size = Vector3.one * (0.25 + math.random() * 0.35)
		chip.Color = color
		chip.Material = Enum.Material.Slate
		chip.CanCollide = true
		chip.CanQuery = false
		chip.CanTouch = false
		chip.CFrame = CFrame.new(at) * CFrame.Angles(math.random() * 3, math.random() * 3, math.random() * 3)
		chip.AssemblyLinearVelocity = Vector3.new(math.random(-8, 8), math.random(6, 14), math.random(-8, 8))
		chip.Parent = workspace
		Debris:AddItem(chip, 1.2)
	end
end

-- Staubwolke am Treffpunkt (docs/19 §6)
local function spawnDust(at: Vector3)
	local cfg = AmbienceConfig.MineDust
	local anchor = Instance.new("Attachment")
	anchor.WorldPosition = at
	anchor.Parent = workspace.Terrain
	local dust = Instance.new("ParticleEmitter")
	dust.Texture = "rbxasset://textures/particles/smoke_main.dds"
	dust.Color = ColorSequence.new(cfg.Color)
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, cfg.Size * 0.5), NumberSequenceKeypoint.new(1, cfg.Size * 1.6) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	dust.Lifetime = NumberRange.new(cfg.Lifetime * 0.7, cfg.Lifetime)
	dust.Speed = NumberRange.new(2, 5)
	dust.SpreadAngle = Vector2.new(70, 70)
	dust.Drag = 3
	dust.Acceleration = Vector3.new(0, -2, 0)
	dust.Rate = 0
	dust.Parent = anchor
	dust:Emit(cfg.Count)
	Debris:AddItem(anchor, cfg.Lifetime + 0.5)
end

local function floatingText(at: Vector3, text: string)
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.CFrame = CFrame.new(at + Vector3.new(0, 1.5, 0))
	anchor.Parent = workspace

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 40)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 26
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.Text = text
	label.Parent = gui

	TweenService:Create(anchor, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = anchor.CFrame + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(label, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(anchor, 1)
end

-- Rare Drop (docs/03 §8, docs/09 §17): großer Schriftzug, Glanz, Funken, Sound – nur nach
-- Bestätigung durch den Server
local RARE_GOLD = Color3.fromRGB(255, 205, 70)
local function rareEffect(at: Vector3, rare: any)
	local ore = Ores.Get(rare.OreId)
	local color = if ore then ore.Color else RARE_GOLD
	local name = if ore then string.upper(ore.DisplayName) else ""
	local isOre = rare.Kind == "Ore"
	local title = if isOre then Strings.Hud.RareDrop else Strings.Hud.LuckyDrop
	local line = if isOre then `+{rare.Amount} {name}` else `x{rare.Multiplier} {name}`
	HudController.ShowRareDrop(title, line, if isOre then color:Lerp(Color3.new(1, 1, 1), 0.25) else RARE_GOLD)
	SoundController.Play(if isOre then "RareDrop" else "LuckyDrop", at)

	-- Leuchtender Glanz und Funken an der Erzwand
	local anchor = Instance.new("Part")
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one * 0.2
	anchor.CFrame = CFrame.new(at)
	anchor.Parent = workspace
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 14
	light.Brightness = 4
	light.Parent = anchor
	TweenService:Create(light, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Color = ColorSequence.new(color, RARE_GOLD)
	sparks.LightEmission = 1
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	sparks.Lifetime = NumberRange.new(0.6, 1.1)
	sparks.Speed = NumberRange.new(6, 12)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Drag = 2
	sparks.Rate = 0
	sparks.Parent = anchor
	sparks:Emit(if isOre then 40 else 25)
	Debris:AddItem(anchor, 1.6)
end

local function shake()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local h = humanoid :: Humanoid
	task.spawn(function()
		for _ = 1, 3 do
			h.CameraOffset = Vector3.new((math.random() - 0.5) * 0.2, (math.random() - 0.5) * 0.2, 0)
			task.wait(0.03)
		end
		h.CameraOffset = Vector3.zero
	end)
end

local function playSwing(tool: Tool)
	-- Standard-Animate-Script spielt bei "toolanim" = "Slash" die Schlag-Animation
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool
	Debris:AddItem(anim, 1)
end

local function onActivated(tool: Tool)
	local now = os.clock()
	if now < busyUntil then
		return
	end
	local snapshot = StateController.Get()
	local pickaxe = snapshot and Pickaxes.Get(snapshot.EquippedPickaxe)
	if not pickaxe then
		return
	end
	busyUntil = now + 1 / (pickaxe.MiningSpeed * PrestigeLogic.SpeedMultiplier((snapshot :: any).PrestigeCount or 0))

	if not Mines.Get(ElevatorController.GetLocation()) then
		NotificationController.Show("Info", "NOT_IN_MINE")
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	local zone, distance = nearestSlot(root.Position)
	if not zone or distance > GameConfig.Mining.ReachStuds then
		NotificationController.Show("Info", "TOO_FAR")
		return
	end
	local slotIndex = zone:GetAttribute("SlotIndex")
	if typeof(slotIndex) ~= "number" then
		return
	end

	-- Zur Erzwand drehen und zuschlagen
	local target = nearestOrePart(zone, root.Position)
	local lookAt = if target then target.Position else zone.Position
	root.CFrame = CFrame.lookAt(root.Position, Vector3.new(lookAt.X, root.Position.Y, lookAt.Z))
	playSwing(tool)
	task.wait(IMPACT_DELAY)

	local result = Net.invoke("MineHit", slotIndex)
	if result.success then
		local value = result.value
		local ore = Ores.Get(value.OreId)
		local hitAt = if target then target.Position else zone.Position
		spawnDebris(hitAt, if ore then ore.Color else Color3.new(0.2, 0.2, 0.2))
		spawnDust(hitAt)
		SoundController.Play("MineHit", hitAt)
		if value.Rare then
			rareEffect(hitAt, value.Rare)
		end
		floatingText(hitAt, Strings.message("MINED", { Amount = value.Amount, Ore = if ore then ore.DisplayName else "" }))
		shake()
	elseif result.code ~= "COOLDOWN" then
		NotificationController.Show(if result.code == "BACKPACK_FULL" then "Warning" else "Info", result.code)
	end
end

local function watchTool(tool: Instance)
	if tool:IsA("Tool") and tool.Name == PICKAXE_TOOL and not tool:GetAttribute("MiningHooked") then
		tool:SetAttribute("MiningHooked", true)
		tool.Activated:Connect(function()
			onActivated(tool)
		end)
	end
end

local function onCharacter(character: Model)
	for _, child in character:GetChildren() do
		watchTool(child)
	end
	character.ChildAdded:Connect(watchTool)
end

function MiningController.Init()
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
end

function MiningController.Start() end

return MiningController
