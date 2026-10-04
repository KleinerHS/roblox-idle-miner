--!strict
-- Rucksackanzeige (docs/09 §13): klein unten rechts, sichtbar in der Mine oder sobald
-- Erz im Rucksack ist. Bei vollem Rucksack "BACKPACK FULL" mit kurzer Rückmeldung.
-- Werte kommen nur aus dem Server-Snapshot.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local Mines = require(Shared.Definitions.Mines)
local Types = require(Shared.Types)
local NumberFormat = require(Shared.Util.NumberFormat)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local StateController = require(script.Parent.StateController)
local ElevatorController = require(script.Parent.ElevatorController)

local BackpackHudController = {}

local card: Frame
local title: TextLabel
local value: TextLabel
local fill: Frame
local wasFull = false

local function total(snapshot: Types.StateSnapshot): number
	local sum = 0
	for _, amount in snapshot.Backpack do
		sum += amount
	end
	return sum
end

local function refresh()
	local snapshot = StateController.Get()
	if not snapshot then
		card.Visible = false
		return
	end
	local count = total(snapshot)
	local capacity = math.max(snapshot.BackpackCapacity, 1)
	local inMine = Mines.Get(ElevatorController.GetLocation()) ~= nil
	card.Visible = inMine or count > 0

	local full = count >= capacity
	title.Text = if full then "BACKPACK FULL" else "BACKPACK"
	title.TextColor3 = if full then UITheme.Colors.Negative else UITheme.Colors.TextSecondary
	value.Text = `{NumberFormat.withSeparators(count)} / {NumberFormat.withSeparators(capacity)}`
	TweenService:Create(fill, TweenInfo.new(0.2), {
		Size = UDim2.fromScale(math.clamp(count / capacity, 0, 1), 1),
		BackgroundColor3 = if full then UITheme.Colors.Negative else UITheme.Colors.DefaultAccent,
	}):Play()

	-- Kurzes Aufleuchten beim Vollwerden
	if full and not wasFull then
		local stroke = card:FindFirstChildOfClass("UIStroke") :: UIStroke
		stroke.Color = UITheme.Colors.Negative
		stroke.Transparency = 0
		TweenService:Create(stroke, TweenInfo.new(1.2), { Transparency = 0.8 }):Play()
	end
	wasFull = full
end

function BackpackHudController.Init()
	local gui = Create("ScreenGui", {
		Name = "BackpackHud",
		ResetOnSpawn = false,
		DisplayOrder = 10,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	card = Create("Frame", {
		Name = "Card",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(210, 68),
		BackgroundColor3 = UITheme.Colors.Background,
		BackgroundTransparency = 0.15,
		Visible = false,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised, Transparency = 0.8, Thickness = 2 }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10) }),
	})
	title = Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 13,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "BACKPACK",
		Parent = card,
	})
	value = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 16),
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 22,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "0 / 0",
		Parent = card,
	})
	local bar = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = UITheme.Colors.SurfaceRaised,
		Parent = card,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	fill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = UITheme.Colors.DefaultAccent,
		Parent = bar,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	StateController.Changed:Connect(refresh)
	Net.on("LocationChanged", function()
		task.defer(refresh)
	end)
end

function BackpackHudController.Start()
	refresh()
end

return BackpackHudController
