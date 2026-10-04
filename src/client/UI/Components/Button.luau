--!strict
-- Wiederverwendbarer Button (docs/09 §70) mit Hover-Feedback und Pending-Zustand gegen
-- Mehrfachklicks (docs/09 §66).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UITheme = require(ReplicatedStorage:WaitForChild("Shared").Config.UITheme)
local Create = require(script.Parent.Parent.Create)

export type Button = {
	Instance: TextButton,
	SetText: (self: Button, text: string) -> (),
	SetEnabled: (self: Button, enabled: boolean) -> (),
	SetAccent: (self: Button, color: Color3) -> (),
	OnClick: (self: Button, handler: () -> ()) -> RBXScriptConnection,
}

local Button = {}

local TWEEN = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Button.new(props: { Text: string, Primary: boolean?, Size: UDim2?, Position: UDim2?, AnchorPoint: Vector2?, Parent: Instance? }): Button
	local primary = props.Primary ~= false
	local baseColor = if primary then UITheme.Colors.DefaultAccent else UITheme.Colors.SurfaceRaised
	local enabled = true

	local instance: TextButton = Create("TextButton", {
		Name = "Button",
		Text = props.Text,
		Size = props.Size or UDim2.fromOffset(200, 48),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundColor3 = baseColor,
		TextColor3 = if primary then Color3.fromRGB(24, 27, 33) else UITheme.Colors.TextPrimary,
		Font = UITheme.FontBold,
		TextSize = 18,
		AutoButtonColor = false,
		Parent = props.Parent,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
	})

	local self = {} :: Button
	self.Instance = instance

	local function tint(color: Color3)
		TweenService:Create(instance, TWEEN, { BackgroundColor3 = color }):Play()
	end

	instance.MouseEnter:Connect(function()
		if enabled then
			tint(baseColor:Lerp(Color3.new(1, 1, 1), 0.12))
		end
	end)
	instance.MouseLeave:Connect(function()
		if enabled then
			tint(baseColor)
		end
	end)

	function self.SetText(_: Button, text: string)
		instance.Text = text
	end

	function self.SetEnabled(_: Button, value: boolean)
		enabled = value
		instance.Active = value
		instance.AutoButtonColor = false
		tint(if value then baseColor else baseColor:Lerp(UITheme.Colors.Background, 0.5))
	end

	function self.SetAccent(_: Button, color: Color3)
		baseColor = color
		if enabled then
			tint(color)
		end
	end

	function self.OnClick(_: Button, handler: () -> ()): RBXScriptConnection
		return instance.Activated:Connect(function()
			if enabled then
				handler()
			end
		end)
	end

	return self
end

return Button
