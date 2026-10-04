--!strict
-- Main HUD (docs/09 §7–12): Geld oben rechts, Mining Level mit XP-Balken unten mittig
-- (über der Hotbar), kurze Level-Up- und Verkaufs-Rückmeldung. Werte nur aus dem
-- Server-Snapshot; der XP-Balken nutzt die Firmenfarbe als Akzent (docs/09 §4).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local CompanyIdentity = require(Shared.Definitions.CompanyIdentity)
local Types = require(Shared.Types)
local NumberFormat = require(Shared.Util.NumberFormat)

local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local StateController = require(script.Parent.StateController)

local TEXT = Strings.Hud

local HudController = {}

local cashLabel: TextLabel
local levelLabel: TextLabel
local xpLabel: TextLabel
local xpFill: Frame
local popupGui: ScreenGui
local popupTitle: TextLabel
local popupLine1: TextLabel
local popupLine2: TextLabel

local shownCash: number? = nil
local lastLevel: number? = nil
local cashTween: { value: NumberValue }? = nil
-- Solange die Verkaufsmeldung steht, wartet eine Level-Up-Meldung dahinter
local soldActiveUntil = 0

local function accentColor(snapshot: Types.StateSnapshot): Color3
	local color = CompanyIdentity.ColorById[snapshot.Company.ColorId]
	return if color then color.Color else UITheme.Colors.DefaultAccent
end

-- Geldanzeige zählt flüssig zum neuen Wert (docs/09 §49)
local function animateCash(target: number)
	if shownCash == nil then
		shownCash = target
		cashLabel.Text = NumberFormat.cash(target)
		return
	end
	if cashTween then
		cashTween.value:Destroy()
	end
	local value = Instance.new("NumberValue")
	value.Value = shownCash :: number
	value.Changed:Connect(function(v: number)
		shownCash = v
		cashLabel.Text = NumberFormat.cash(math.floor(v + 0.5))
	end)
	cashTween = { value = value }
	TweenService:Create(value, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = target }):Play()
end

local function showPopup(title: string, line1: string, line2: string, color: Color3)
	popupTitle.Text = title
	popupTitle.TextColor3 = color
	popupLine1.Text = line1
	popupLine2.Text = line2
	popupGui.Enabled = true
	local frame = popupTitle.Parent :: Frame
	frame.Size = UDim2.fromOffset(300, 0)
	TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(300, 118) }):Play()
	local token = os.clock()
	popupGui:SetAttribute("Token", token)
	task.delay(2.4, function()
		if popupGui:GetAttribute("Token") == token then
			popupGui.Enabled = false
		end
	end)
end

local function refresh(snapshot: Types.StateSnapshot)
	animateCash(snapshot.Cash)
	levelLabel.Text = string.format(TEXT.MiningLevel, snapshot.MiningLevel)
	xpLabel.Text = string.format(TEXT.XP, NumberFormat.withSeparators(snapshot.MiningXP), NumberFormat.withSeparators(snapshot.MiningXPRequired))
	local ratio = math.clamp(snapshot.MiningXP / math.max(snapshot.MiningXPRequired, 1), 0, 1)
	TweenService:Create(xpFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(ratio, 1),
		BackgroundColor3 = accentColor(snapshot),
	}):Play()

	if lastLevel and snapshot.MiningLevel > lastLevel then
		local level, color = snapshot.MiningLevel, accentColor(snapshot)
		task.delay(0.4, function()
			local waitFor = soldActiveUntil - os.clock()
			if waitFor > 0 then
				task.wait(waitFor)
			end
			showPopup(TEXT.LevelUp, string.format(TEXT.LevelUpSub, level), "", color)
		end)
	end
	lastLevel = snapshot.MiningLevel
end

function HudController.Init()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = Create("ScreenGui", { Name = "MainHud", ResetOnSpawn = false, DisplayOrder = 5, Parent = playerGui })

	-- Geld oben rechts
	local cashCard = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -20, 0, 12),
		Size = UDim2.fromOffset(0, 46),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = UITheme.Colors.Background,
		BackgroundTransparency = 0.15,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
	})
	cashLabel = Create("TextLabel", {
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 26,
		TextColor3 = UITheme.Colors.Positive,
		Text = "$0",
		Parent = cashCard,
	})

	-- Mining Level unten mittig über der Hotbar (docs/09 §8, verbindlich)
	local levelCard = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -82),
		Size = UDim2.fromOffset(380, 48),
		BackgroundColor3 = UITheme.Colors.Background,
		BackgroundTransparency = 0.15,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 8) }),
		Create("UISizeConstraint", { MaxSize = Vector2.new(380, 48) }),
	})
	levelLabel = Create("TextLabel", {
		Size = UDim2.new(0.6, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 17,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "MINING LEVEL 1",
		Parent = levelCard,
	})
	xpLabel = Create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0.4, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 14,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "0 / 0 XP",
		Parent = levelCard,
	})
	local bar = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundColor3 = UITheme.Colors.SurfaceRaised,
		Parent = levelCard,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
	xpFill = Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = UITheme.Colors.DefaultAccent,
		Parent = bar,
	}, { Create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	-- Kurze Rückmeldung (Level-Up, Verkauf) in der Bildschirmmitte oben
	popupGui = Create("ScreenGui", { Name = "HudPopup", ResetOnSpawn = false, DisplayOrder = 60, Enabled = false, Parent = playerGui })
	local popup = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.18, 0),
		Size = UDim2.fromOffset(300, 118),
		BackgroundColor3 = UITheme.Colors.Background,
		BackgroundTransparency = 0.08,
		ClipsDescendants = true,
		Parent = popupGui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
	})
	popupTitle = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 12),
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 34,
		Parent = popup,
	})
	popupLine1 = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 54),
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 22,
		TextColor3 = UITheme.Colors.TextPrimary,
		Parent = popup,
	})
	popupLine2 = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 82),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 18,
		TextColor3 = UITheme.Colors.TextSecondary,
		Parent = popup,
	})

	StateController.Changed:Connect(refresh)
end

function HudController.Start()
	local snapshot = StateController.Get()
	if snapshot then
		refresh(snapshot)
	end
end

-- Verkaufsrückmeldung "SOLD +$X +Y Mining XP" (docs/09 §49)
function HudController.ShowSold(cash: number, xp: number)
	soldActiveUntil = os.clock() + 2.4
	showPopup(Strings.Sell.Sold, `+{NumberFormat.cash(cash)}`, `+{NumberFormat.withSeparators(xp)} Mining XP`, UITheme.Colors.Positive)
end

return HudController
