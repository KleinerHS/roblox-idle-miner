--!strict
-- Einheitliches Bedien-Feedback für alle eigenen Oberflächen (Phase 13e, docs/09 §5, §58, §59).
-- Wirkt auf jede ScreenGui mit Attribut "GameUI" (setzt UI/Create automatisch):
--   * Hover: Button wird leicht heller (nicht bei AutoButtonColor oder eigenem Hover "OwnHover")
--   * Klick: Button drückt sich kurz ein (Skalierung)
--   * Fenster: Menüs öffnen mit kurzer, ruhiger Skalier-Animation (nicht beim HUD)
--   * Responsive: UIScale je ScreenGui nach Bildschirmhöhe (UITheme.Scale)
-- Reine Darstellung; ändert keine Logik der Menüs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local UITheme = require(ReplicatedStorage:WaitForChild("Shared").Config.UITheme)

local UIPolishController = {}

local MOTION = UITheme.Motion
-- Dauerhafte Anzeigen ohne Öffnungsanimation
local HUD_GUIS = {
	MainHud = true,
	BackpackHud = true,
	LocationHud = true,
	Notifications = true,
	DrivingHud = true,
	HudPopup = true,
	ElevatorTransition = true,
	TradeRequest = true,
}

-- Je Fenster (oberste Ebene einer ScreenGui) ein UIScale = Bildschirmfaktor × Öffnungsfaktor.
-- Ein UIScale am Fenster skaliert um dessen Ankerpunkt; rechts/unten verankerte HUD-Teile
-- bleiben so an ihrem Platz.
type Window = { scale: UIScale, open: number }
local windows: { [GuiObject]: Window } = {}
local screenFactor = 1

local function currentScale(): number
	local camera = Workspace.CurrentCamera
	local height = if camera then camera.ViewportSize.Y else UITheme.Scale.ReferenceHeight
	return math.clamp(height / UITheme.Scale.ReferenceHeight, UITheme.Scale.Min, UITheme.Scale.Max)
end

local function apply(w: Window)
	w.scale.Scale = screenFactor * w.open
end

local function windowOf(frame: GuiObject): Window
	local w = windows[frame]
	if not w then
		local s = Instance.new("UIScale")
		s.Name = "PolishScale"
		s.Parent = frame
		w = { scale = s, open = 1 }
		windows[frame] = w
		apply(w)
		frame.Destroying:Connect(function()
			windows[frame] = nil
		end)
	end
	return w
end

local function tween(inst: Instance, seconds: number, goal: { [string]: any }, style: Enum.EasingStyle?)
	TweenService:Create(inst, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal):Play()
end

local function polishButton(button: GuiButton)
	if button:GetAttribute("Polished") then
		return
	end
	button:SetAttribute("Polished", true)

	local press = Instance.new("UIScale")
	press.Name = "PressScale"
	press.Parent = button

	local hovered = false
	local baseColor = button.BackgroundColor3
	local hoverColor = baseColor
	local useHover = not button.AutoButtonColor and not button:GetAttribute("OwnHover") and button.BackgroundTransparency < 1

	button.MouseEnter:Connect(function()
		if not useHover or not button.Active then
			return
		end
		hovered = true
		baseColor = button.BackgroundColor3
		hoverColor = baseColor:Lerp(Color3.new(1, 1, 1), MOTION.HoverLighten)
		tween(button, MOTION.Hover, { BackgroundColor3 = hoverColor })
	end)
	button.MouseLeave:Connect(function()
		tween(press, MOTION.Press, { Scale = 1 })
		if not hovered then
			return
		end
		hovered = false
		-- Nur zurücksetzen, wenn das Menü die Farbe in der Zwischenzeit nicht selbst geändert hat
		local c = button.BackgroundColor3
		local h = hoverColor
		if math.abs(c.R - h.R) + math.abs(c.G - h.G) + math.abs(c.B - h.B) < 0.03 then
			tween(button, MOTION.Hover, { BackgroundColor3 = baseColor })
		end
	end)
	button.MouseButton1Down:Connect(function()
		if button.Active then
			tween(press, MOTION.Press, { Scale = MOTION.PressScale })
		end
	end)
	button.MouseButton1Up:Connect(function()
		tween(press, MOTION.Press * 2, { Scale = 1 })
	end)
end

-- Vollflächige Ebenen (Abdunklung, Überblendung) werden nicht skaliert, sondern die Fenster darin
local function isFullscreen(obj: GuiObject): boolean
	return obj.Size.X.Scale >= 0.99 and obj.Size.Y.Scale >= 0.99
end

local function targets(obj: GuiObject): { GuiObject }
	if not isFullscreen(obj) then
		return { obj }
	end
	local list = {}
	for _, child in obj:GetChildren() do
		if child:IsA("GuiObject") and not isFullscreen(child) then
			table.insert(list, child)
		end
	end
	return list
end

local function register(obj: Instance)
	if not obj:IsA("GuiObject") then
		return
	end
	if isFullscreen(obj) then
		for _, t in targets(obj) do
			windowOf(t)
		end
		obj.ChildAdded:Connect(function(child)
			if child:IsA("GuiObject") and not isFullscreen(child) then
				windowOf(child)
			end
		end)
	else
		windowOf(obj)
	end
end

-- Kurze Öffnungsanimation für ein Fenster
local function popIn(frame: GuiObject)
	local w = windowOf(frame)
	local value = Instance.new("NumberValue")
	value.Value = MOTION.OpenScaleFrom
	value.Changed:Connect(function(v)
		w.open = v
		apply(w)
	end)
	w.open = MOTION.OpenScaleFrom
	apply(w)
	local t = TweenService:Create(value, TweenInfo.new(MOTION.Open, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = 1 })
	t.Completed:Once(function()
		w.open = 1
		apply(w)
		value:Destroy()
	end)
	t:Play()
end

local function watchWindows(gui: ScreenGui)
	if HUD_GUIS[gui.Name] then
		return
	end
	local function topFrames(): { GuiObject }
		local list = {}
		for _, child in gui:GetChildren() do
			if child:IsA("GuiObject") and child.Visible then
				table.insert(list, child)
			end
		end
		return list
	end
	gui:GetPropertyChangedSignal("Enabled"):Connect(function()
		if gui.Enabled then
			for _, frame in topFrames() do
				for _, t in targets(frame) do
					popIn(t)
				end
			end
		end
	end)
	local function watchChild(child: Instance)
		if child:IsA("GuiObject") then
			child:GetPropertyChangedSignal("Visible"):Connect(function()
				if child.Visible and gui.Enabled then
					for _, t in targets(child) do
						popIn(t)
					end
				end
			end)
		end
	end
	for _, child in gui:GetChildren() do
		watchChild(child)
	end
	gui.ChildAdded:Connect(watchChild)
end

local function onGui(gui: Instance)
	if not gui:IsA("ScreenGui") or not gui:GetAttribute("GameUI") or gui:GetAttribute("PolishHooked") then
		return
	end
	gui:SetAttribute("PolishHooked", true)

	-- Bildschirmskalierung für jedes Fenster der obersten Ebene
	for _, child in gui:GetChildren() do
		register(child)
	end
	gui.ChildAdded:Connect(register)

	for _, d in gui:GetDescendants() do
		if d:IsA("GuiButton") then
			polishButton(d)
		end
	end
	gui.DescendantAdded:Connect(function(d)
		if d:IsA("GuiButton") then
			-- Eigenschaften (Farbe, AutoButtonColor) sind beim Einfügen evtl. noch nicht gesetzt
			task.defer(polishButton, d)
		end
	end)
	watchWindows(gui)
end

function UIPolishController.Init() end

function UIPolishController.Start()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, gui in playerGui:GetChildren() do
		onGui(gui)
	end
	playerGui.ChildAdded:Connect(function(gui)
		task.defer(onGui, gui)
	end)

	local function rescale()
		screenFactor = currentScale()
		for _, w in windows do
			apply(w)
		end
	end
	local function watchCamera()
		local camera = Workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
		end
		rescale()
	end
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
	watchCamera()
end

return UIPolishController
