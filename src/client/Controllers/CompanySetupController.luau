--!strict
-- Dialog zur Firmengründung (docs/04 §6–9). Öffnet sich, sobald das Büro gebaut ist und die
-- Firma noch nicht eingerichtet wurde; schließt sich, wenn der Server die Firma bestätigt.
-- Der Client wählt nur aus; Prüfung und Textfilter macht CompanyService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UITheme = require(Shared.Config.UITheme)
local CompanyIdentity = require(Shared.Definitions.CompanyIdentity)
local Types = require(Shared.Types)

local Net = require(script.Parent.Parent.Net)
local Create = require(script.Parent.Parent.UI.Create)
local Strings = require(script.Parent.Parent.UI.Strings)
local Button = require(script.Parent.Parent.UI.Components.Button)
local StateController = require(script.Parent.StateController)

local TEXT = Strings.CompanySetup

local CompanySetupController = {}

local gui: ScreenGui
local nameBox: TextBox
local errorLabel: TextLabel
local previewLabel: TextLabel
local previewAccent: Frame
local confirm: Button.Button
local logoTiles: { [string]: TextButton } = {}
local colorTiles: { [string]: TextButton } = {}

local selectedLogo = CompanyIdentity.Logos[1].Id
local selectedColor = CompanyIdentity.Colors[1].Id
local submitting = false

local function sectionLabel(text: string, order: number, parent: Instance)
	Create("TextLabel", {
		Text = text,
		Size = UDim2.new(1, 0, 0, 18),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 14,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = order,
		Parent = parent,
	})
end

local function refreshSelection()
	local accent = CompanyIdentity.ColorById[selectedColor].Color
	for id, tile in logoTiles do
		local stroke = tile:FindFirstChildOfClass("UIStroke") :: UIStroke
		stroke.Color = if id == selectedLogo then accent else UITheme.Colors.SurfaceRaised
		stroke.Thickness = if id == selectedLogo then 2.5 else 1
	end
	for id, tile in colorTiles do
		local stroke = tile:FindFirstChildOfClass("UIStroke") :: UIStroke
		stroke.Thickness = if id == selectedColor then 3 else 0
	end
	confirm:SetAccent(accent)
	previewAccent.BackgroundColor3 = accent
	local name = nameBox.Text
	previewLabel.Text = `{CompanyIdentity.LogoById[selectedLogo].Glyph}  {if #name > 0 then name else TEXT.NamePlaceholder}`
end

local function build()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	gui = Create("ScreenGui", {
		Name = "CompanySetup",
		ResetOnSpawn = false,
		DisplayOrder = 40,
		Enabled = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = playerGui,
	})

	Create("Frame", {
		Name = "Dim",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		Parent = gui,
	})

	local panel = Create("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.92, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = UITheme.Colors.Background,
		Parent = gui,
	}, {
		Create("UICorner", { CornerRadius = UDim.new(0, 14) }),
		Create("UIStroke", { Color = UITheme.Colors.SurfaceRaised, Thickness = 1 }),
		Create("UIPadding", {
			PaddingTop = UDim.new(0, 24),
			PaddingBottom = UDim.new(0, 24),
			PaddingLeft = UDim.new(0, 28),
			PaddingRight = UDim.new(0, 28),
		}),
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }),
		-- Auf kleinen Bildschirmen schmaler statt abgeschnitten (docs/09 §5–6)
		Create("UISizeConstraint", { MaxSize = Vector2.new(560, math.huge) }),
	})

	Create("TextLabel", {
		Text = TEXT.Title,
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 28,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = panel,
	})
	Create("TextLabel", {
		Text = TEXT.Subtitle,
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.Font,
		TextSize = 16,
		TextColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
		Parent = panel,
	})

	-- Vorschau des Firmenschilds
	local preview = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundColor3 = UITheme.Colors.Surface,
		LayoutOrder = 3,
		Parent = panel,
	}, { Create("UICorner", { CornerRadius = UITheme.CornerRadius }) })
	previewLabel = Create("TextLabel", {
		Size = UDim2.new(1, -24, 1, -8),
		Position = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 22,
		TextColor3 = UITheme.Colors.TextPrimary,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = preview,
	})
	previewAccent = Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 5),
		BorderSizePixel = 0,
		Parent = preview,
	})

	sectionLabel(TEXT.NameLabel, 4, panel)
	nameBox = Create("TextBox", {
		Text = "",
		PlaceholderText = TEXT.NamePlaceholder,
		ClearTextOnFocus = false,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = UITheme.Colors.Surface,
		Font = UITheme.Font,
		TextSize = 20,
		TextColor3 = UITheme.Colors.TextPrimary,
		PlaceholderColor3 = UITheme.Colors.TextSecondary,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 5,
		Parent = panel,
	}, {
		Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
		Create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
	})
	nameBox:GetPropertyChangedSignal("Text"):Connect(function()
		if utf8.len(nameBox.Text) and (utf8.len(nameBox.Text) :: number) > CompanyIdentity.NameMaxLength then
			nameBox.Text = nameBox.Text:sub(1, utf8.offset(nameBox.Text, CompanyIdentity.NameMaxLength + 1) - 1)
		end
		errorLabel.Text = ""
		refreshSelection()
	end)

	sectionLabel(TEXT.LogoLabel, 6, panel)
	local logoGrid = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 72),
		BackgroundTransparency = 1,
		LayoutOrder = 7,
		Parent = panel,
	}, {
		Create("UIGridLayout", { CellSize = UDim2.new(1 / 6, -8, 1, 0), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for index, logo in CompanyIdentity.Logos do
		local tile: TextButton = Create("TextButton", {
			Name = logo.Id,
			LayoutOrder = index,
			Text = logo.Glyph,
			TextSize = 30,
			Font = UITheme.FontBold,
			TextColor3 = UITheme.Colors.TextPrimary,
			BackgroundColor3 = UITheme.Colors.Surface,
			AutoButtonColor = true,
			Parent = logoGrid,
		}, {
			Create("UICorner", { CornerRadius = UITheme.CornerRadius }),
			Create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Thickness = 1 }),
		})
		tile.Activated:Connect(function()
			selectedLogo = logo.Id
			refreshSelection()
		end)
		logoTiles[logo.Id] = tile
	end

	sectionLabel(TEXT.ColorLabel, 8, panel)
	local colorRow = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		LayoutOrder = 9,
		Parent = panel,
	}, {
		Create("UIGridLayout", { CellSize = UDim2.new(1 / 8, -8, 1, 0), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	for index, color in CompanyIdentity.Colors do
		local tile: TextButton = Create("TextButton", {
			Name = color.Id,
			LayoutOrder = index,
			Text = "",
			BackgroundColor3 = color.Color,
			AutoButtonColor = true,
			Parent = colorRow,
		}, {
			Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
			Create("UIStroke", { ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Color = Color3.new(1, 1, 1), Thickness = 0 }),
		})
		tile.Activated:Connect(function()
			selectedColor = color.Id
			refreshSelection()
		end)
		colorTiles[color.Id] = tile
	end

	errorLabel = Create("TextLabel", {
		Text = "",
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = UITheme.FontBold,
		TextSize = 16,
		TextColor3 = UITheme.Colors.Negative,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 10,
		Parent = panel,
	})

	confirm = Button.new({ Text = TEXT.Confirm, Size = UDim2.new(1, 0, 0, 52), Parent = panel })
	confirm.Instance.LayoutOrder = 11
	confirm:OnClick(function()
		if submitting then
			return
		end
		submitting = true
		confirm:SetEnabled(false)
		confirm:SetText(TEXT.Pending)
		errorLabel.Text = ""
		local result = Net.invoke("SubmitCompanySetup", nameBox.Text, selectedLogo, selectedColor)
		submitting = false
		confirm:SetEnabled(true)
		confirm:SetText(TEXT.Confirm)
		if not result.success then
			errorLabel.Text = Strings.message(result.code)
		end
		-- Bei Erfolg schließt der nächste Snapshot den Dialog.
	end)

	refreshSelection()
end

local function onState(snapshot: Types.StateSnapshot)
	local shouldOpen = snapshot.Buildings.build_office == true and not snapshot.Company.Created
	if shouldOpen and not gui.Enabled then
		gui.Enabled = true
		task.defer(function()
			nameBox:CaptureFocus()
		end)
	elseif not shouldOpen and gui.Enabled then
		gui.Enabled = false
		nameBox:ReleaseFocus()
	end
end

function CompanySetupController.Init()
	build()
	StateController.Changed:Connect(onState)
end

function CompanySetupController.Start()
	local snapshot = StateController.Get()
	if snapshot then
		onState(snapshot)
	end
end

return CompanySetupController
