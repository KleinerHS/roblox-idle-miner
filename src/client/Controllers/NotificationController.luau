--!strict
-- Zentrale, kurze Meldungen oben mittig (docs/09 §54–56). Gleiche Meldung wird innerhalb
-- von DEDUPE_SECONDS nicht erneut angezeigt (keine Popup-Flut). Maximal MAX_VISIBLE gleichzeitig.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)

local NotificationController = {}

local DEDUPE_SECONDS = 3
local SHOW_SECONDS = 3.5
local MAX_VISIBLE = 3

local KIND_COLORS: { [string]: Color3 } = {
	Info = UITheme.Colors.TextSecondary,
	Success = UITheme.Colors.Positive,
	Warning = UITheme.Colors.Warning,
	Special = Color3.fromRGB(190, 140, 255),
}

local container: Frame
local lastShown: { [string]: number } = {}

local function show(kind: string, text: string)
	local now = os.clock()
	if lastShown[text] and now - lastShown[text] < DEDUPE_SECONDS then
		return
	end
	lastShown[text] = now

	local toasts = {}
	for _, child in container:GetChildren() do
		if child:IsA("Frame") then
			table.insert(toasts, child)
		end
	end
	if #toasts >= MAX_VISIBLE then
		toasts[1]:Destroy()
	end

	local toast: Frame = Create("Frame", {
		Name = "Toast",
		Size = UDim2.fromOffset(0, 44),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = UITheme.Colors.Background,
		BackgroundTransparency = 0.1,
		LayoutOrder = math.floor(now * 1000),
		Parent = container,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18) }),
		Create("UIStroke", { Color = KIND_COLORS[kind] or KIND_COLORS.Info, Thickness = 1.5, Transparency = 0.2 }),
		Create("TextLabel", {
			Name = "Text",
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Font = UITheme.FontBold,
			TextSize = 18,
			TextColor3 = UITheme.Colors.TextPrimary,
			Text = text,
		}),
	})

	task.delay(SHOW_SECONDS, function()
		if toast.Parent then
			local tween = TweenService:Create(toast, TweenInfo.new(0.25), { BackgroundTransparency = 1 })
			tween:Play()
			tween.Completed:Wait()
			toast:Destroy()
		end
	end)
end

function NotificationController.Init()
	local gui = Create("ScreenGui", {
		Name = "Notifications",
		ResetOnSpawn = false,
		DisplayOrder = 50,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	})
	container = Create("Frame", {
		Name = "Stack",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 72),
		Size = UDim2.new(0.6, 0, 0, 200),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Create("UIListLayout", {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	})

	Net.on("Notify", function(payload: any)
		if typeof(payload) ~= "table" or typeof(payload.Code) ~= "string" then
			return
		end
		local kind = if typeof(payload.Kind) == "string" then payload.Kind else "Info"
		show(kind, Strings.message(payload.Code, payload.Args))
	end)
end

-- Für Client-seitige Meldungen (z. B. Fehler aus einem Result).
function NotificationController.Show(kind: string, code: string, args: { [string]: any }?)
	show(kind, Strings.message(code, args))
end

return NotificationController
