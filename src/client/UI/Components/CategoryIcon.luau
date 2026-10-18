--!strict
-- Kategorie-Icons (docs/09 §61) im selben 3D-Stil wie die Erz-Icons: kleine Modelle im
-- ViewportFrame, einheitliche Farben (Industrie-Gelb, Stahl, Holz), keine Bild-Assets.
-- Kategorien: Money, Level, XP, Pickaxe, Backpack, Worker, Storage, Elevator, Drill,
-- Conveyor, Smelter, Vehicle, Ore, Settings, Luck, Company, Prestige, Dashboard.

local ModelIcon = require(script.Parent.ModelIcon)
local OreIcon = require(script.Parent.OreIcon)

local CategoryIcon = {}

local YELLOW = Color3.fromRGB(240, 185, 40)
local STEEL = Color3.fromRGB(150, 156, 166)
local STEEL_DARK = Color3.fromRGB(70, 74, 82)
local WOOD = Color3.fromRGB(170, 120, 70)
local GREEN = Color3.fromRGB(88, 196, 120)
local GOLD = Color3.fromRGB(250, 200, 70)
local BLUE = Color3.fromRGB(80, 150, 240)
local ORANGE = Color3.fromRGB(255, 140, 40)

local function part(model: Model, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- Zylinder stehend (Achse Y)
local function disc(model: Model, d: number, h: number, cf: CFrame, color: Color3, material: Enum.Material?): Part
	return part(model, Vector3.new(h, d, d), cf * CFrame.Angles(0, 0, math.rad(90)), color, material, Enum.PartType.Cylinder)
end

local builders: { [string]: (Model) -> () } = {
	Money = function(m)
		for i = 0, 3 do
			disc(m, 1.6, 0.28, CFrame.new(0.35, i * 0.3, 0), GOLD, Enum.Material.Metal)
		end
		for i = 0, 1 do
			disc(m, 1.6, 0.28, CFrame.new(-1.1, i * 0.3, 0.6), GOLD, Enum.Material.Metal)
		end
		part(m, Vector3.new(2.2, 0.08, 1.1), CFrame.new(-0.4, -0.1, -0.9) * CFrame.Angles(0, 0.3, 0), GREEN)
	end,
	Level = function(m)
		-- Stern aus zwei gedrehten Prismen
		for i = 0, 4 do
			part(m, Vector3.new(0.5, 0.35, 1.8), CFrame.Angles(0, math.rad(i * 72), 0) * CFrame.new(0, 0, 0.6), YELLOW)
		end
		disc(m, 1.2, 0.4, CFrame.new(), YELLOW)
	end,
	XP = function(m)
		-- Edelstein: gestreckter, gedrehter Würfel mit leuchtendem Kern
		local gem = CFrame.Angles(math.rad(45), 0, math.rad(45))
		part(m, Vector3.new(1.2, 1.2, 1.2), gem, BLUE, Enum.Material.Glass).Transparency = 0.1
		part(m, Vector3.new(0.6, 0.6, 0.6), gem, Color3.fromRGB(180, 220, 255), Enum.Material.Neon)
	end,
	Pickaxe = function(m)
		-- Blick schräg von vorne: Hacke liegt in der Ebene zur Kamera
		local base = CFrame.lookAt(Vector3.zero, -ModelIcon.View) * CFrame.Angles(0, 0, math.rad(-40))
		part(m, Vector3.new(0.45, 3, 0.45), base, WOOD, Enum.Material.Wood)
		local head = base * CFrame.new(0, 1.35, 0)
		part(m, Vector3.new(2.2, 0.5, 0.5), head, STEEL, Enum.Material.Metal)
		part(m, Vector3.new(0.7, 0.35, 0.4), head * CFrame.new(1.3, -0.18, 0) * CFrame.Angles(0, 0, math.rad(-25)), STEEL, Enum.Material.Metal)
		part(m, Vector3.new(0.7, 0.35, 0.4), head * CFrame.new(-1.3, -0.18, 0) * CFrame.Angles(0, 0, math.rad(25)), STEEL, Enum.Material.Metal)
	end,
	Backpack = function(m)
		part(m, Vector3.new(1.6, 2, 1), CFrame.new(), Color3.fromRGB(160, 110, 60), Enum.Material.Fabric)
		part(m, Vector3.new(1.7, 0.7, 1.1), CFrame.new(0, 0.75, 0.05), Color3.fromRGB(130, 85, 45), Enum.Material.Fabric)
		part(m, Vector3.new(1.1, 0.8, 0.3), CFrame.new(0, -0.3, 0.6), Color3.fromRGB(130, 85, 45), Enum.Material.Fabric)
		part(m, Vector3.new(0.25, 0.25, 0.1), CFrame.new(0, 0.45, 0.62), YELLOW, Enum.Material.Metal)
	end,
	Worker = function(m)
		-- Bauhelm
		part(m, Vector3.new(2, 2, 2), CFrame.new(0, 0, 0), YELLOW, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		disc(m, 2.6, 0.15, CFrame.new(0, -0.15, 0.25), YELLOW)
		part(m, Vector3.new(2.4, 1.2, 2.4), CFrame.new(0, -0.75, 0), Color3.fromRGB(36, 40, 48))
		part(m, Vector3.new(0.3, 0.5, 1.9), CFrame.new(0, 0.85, 0), Color3.fromRGB(255, 210, 80))
	end,
	Storage = function(m)
		part(m, Vector3.new(2, 1.6, 1.6), CFrame.new(), WOOD, Enum.Material.WoodPlanks)
		for _, x in { -0.75, 0.75 } do
			part(m, Vector3.new(0.18, 1.62, 1.62), CFrame.new(x, 0, 0), Color3.fromRGB(120, 80, 45), Enum.Material.Wood)
		end
		part(m, Vector3.new(2.3, 0.2, 1.9), CFrame.new(0, -0.9, 0), STEEL_DARK, Enum.Material.Metal)
	end,
	Elevator = function(m)
		for _, x in { -0.8, 0.8 } do
			for _, z in { -0.8, 0.8 } do
				part(m, Vector3.new(0.15, 2.4, 0.15), CFrame.new(x, 0, z), YELLOW, Enum.Material.Metal)
			end
		end
		part(m, Vector3.new(1.9, 0.18, 1.9), CFrame.new(0, -1.1, 0), STEEL_DARK, Enum.Material.DiamondPlate)
		part(m, Vector3.new(1.9, 0.18, 1.9), CFrame.new(0, 1.1, 0), STEEL_DARK, Enum.Material.Metal)
		part(m, Vector3.new(0.1, 1.2, 0.1), CFrame.new(0, 1.8, 0), STEEL)
		for i = -1, 1 do
			part(m, Vector3.new(1.6, 0.08, 0.08), CFrame.new(0, i * 0.5, 0.82), STEEL, Enum.Material.Metal)
		end
	end,
	Drill = function(m)
		part(m, Vector3.new(1.6, 1.4, 1.6), CFrame.new(0, 0.4, 0), YELLOW, Enum.Material.Metal)
		disc(m, 0.6, 0.6, CFrame.new(0, -0.6, 0), STEEL_DARK, Enum.Material.Metal)
		part(m, Vector3.new(0.5, 1.2, 0.5), CFrame.new(0, -1.3, 0) * CFrame.Angles(0, math.rad(45), 0), STEEL, Enum.Material.Metal)
		part(m, Vector3.new(0.3, 0.4, 0.3), CFrame.new(0, -2, 0) * CFrame.Angles(0, math.rad(45), 0), STEEL)
		part(m, Vector3.new(1.7, 0.2, 0.3), CFrame.new(0, 0.9, 0.82), Color3.fromRGB(30, 30, 34))
	end,
	Conveyor = function(m)
		part(m, Vector3.new(3, 0.15, 1.2), CFrame.new(0, 0.3, 0), Color3.fromRGB(40, 42, 46), Enum.Material.Fabric)
		for i = -1, 1 do
			disc(m, 0.4, 1.25, CFrame.new(i * 1.1, 0.05, 0) * CFrame.Angles(math.rad(90), 0, 0), STEEL, Enum.Material.Metal)
		end
		for _, z in { -0.65, 0.65 } do
			part(m, Vector3.new(3.1, 0.35, 0.12), CFrame.new(0, 0.1, z), YELLOW, Enum.Material.Metal)
		end
		part(m, Vector3.new(0.6, 0.45, 0.6), CFrame.new(0.4, 0.6, 0) * CFrame.Angles(0.4, 0.6, 0.2), Color3.fromRGB(110, 78, 58), Enum.Material.Slate)
	end,
	Smelter = function(m)
		part(m, Vector3.new(2, 2, 1.8), CFrame.new(), Color3.fromRGB(80, 78, 76), Enum.Material.Brick)
		part(m, Vector3.new(1, 0.9, 0.1), CFrame.new(0, -0.3, 0.92), ORANGE, Enum.Material.Neon)
		part(m, Vector3.new(0.5, 1.4, 0.5), CFrame.new(0.5, 1.6, -0.3), STEEL_DARK, Enum.Material.Metal)
		part(m, Vector3.new(2.2, 0.2, 2), CFrame.new(0, 1.05, 0), STEEL_DARK, Enum.Material.Metal)
	end,
	Vehicle = function(m)
		part(m, Vector3.new(3, 0.8, 1.4), CFrame.new(0, 0.2, 0), YELLOW, Enum.Material.Metal)
		part(m, Vector3.new(1, 0.9, 1.3), CFrame.new(1, 0.95, 0), YELLOW, Enum.Material.Metal)
		part(m, Vector3.new(0.05, 0.5, 1.1), CFrame.new(1.5, 1.05, 0), Color3.fromRGB(150, 200, 230), Enum.Material.Glass)
		part(m, Vector3.new(1.7, 0.5, 1.3), CFrame.new(-0.6, 0.85, 0), STEEL_DARK, Enum.Material.Metal)
		for _, x in { -1, 1 } do
			for _, z in { -0.72, 0.72 } do
				disc(m, 0.75, 0.3, CFrame.new(x, -0.25, z) * CFrame.Angles(math.rad(90), 0, 0), Color3.fromRGB(30, 30, 32))
			end
		end
	end,
	Settings = function(m)
		disc(m, 2, 0.45, CFrame.new(), STEEL, Enum.Material.Metal)
		for i = 0, 7 do
			part(m, Vector3.new(0.45, 0.45, 0.5), CFrame.Angles(0, math.rad(i * 45), 0) * CFrame.new(0, 0, 1.1), STEEL, Enum.Material.Metal)
		end
		disc(m, 0.7, 0.5, CFrame.new(0, 0.02, 0), STEEL_DARK, Enum.Material.Metal)
	end,
	Luck = function(m)
		-- Kleeblatt
		for i = 0, 3 do
			disc(m, 1.1, 0.25, CFrame.Angles(0, math.rad(i * 90 + 45), 0) * CFrame.new(0, 0, 0.6), GREEN)
		end
		part(m, Vector3.new(0.18, 1.2, 0.18), CFrame.new(0.3, -0.6, 0.3) * CFrame.Angles(0.4, 0, -0.4), Color3.fromRGB(60, 140, 80))
	end,
	Company = function(m)
		part(m, Vector3.new(2.6, 1.4, 1.6), CFrame.new(0, -0.3, 0), Color3.fromRGB(110, 115, 125), Enum.Material.Concrete)
		part(m, Vector3.new(2.8, 0.15, 1.8), CFrame.new(0, 0.45, 0), STEEL_DARK, Enum.Material.Metal)
		part(m, Vector3.new(0.4, 1.3, 0.4), CFrame.new(0.8, 1.1, -0.3), STEEL_DARK)
		for x = -0.8, 0.8, 0.8 do
			part(m, Vector3.new(0.5, 0.4, 0.05), CFrame.new(x, -0.2, 0.82), Color3.fromRGB(150, 200, 230), Enum.Material.Glass)
		end
	end,
	Prestige = function(m)
		part(m, Vector3.new(1.6, 1.6, 0.4), CFrame.Angles(0, 0, math.rad(45)), GOLD, Enum.Material.Metal)
		part(m, Vector3.new(0.9, 0.9, 0.5), CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(255, 240, 160), Enum.Material.Neon)
	end,
	Dashboard = function(m)
		part(m, Vector3.new(2.6, 1.7, 0.2), CFrame.new(0, 0.3, 0), Color3.fromRGB(36, 40, 48))
		local heights = { 0.4, 0.8, 0.6, 1.1 }
		for i, h in heights do
			part(m, Vector3.new(0.35, h, 0.1), CFrame.new(-1.05 + i * 0.42, -0.4 + h / 2, 0.15), if i == 4 then GREEN else YELLOW)
		end
		part(m, Vector3.new(1, 0.15, 0.8), CFrame.new(0, -0.65, 0.3), STEEL_DARK)
	end,
}

local templates: { [string]: Model } = {}
-- Abstand je Kategorie, falls ein Modell sonst am Rand abgeschnitten wird
local ZOOM: { [string]: number } = { XP = 1.25, Pickaxe = 1.0, Drill = 1.0 }

-- Icon einer Kategorie; unbekannte Namen ergeben ein leeres Icon
function CategoryIcon.create(category: string, size: number): ViewportFrame
	if category == "Ore" then
		return OreIcon.create("ore_copper", size)
	end
	local t = templates[category]
	if not t and builders[category] then
		t = Instance.new("Model")
		builders[category](t)
		templates[category] = t
	end
	return ModelIcon.frame(t, size, "CategoryIcon", ZOOM[category])
end

return CategoryIcon
