--!strict
-- Vorlagen für die Podium-Ansicht der Shops (D-070, Felix 2026-10-27): je Kategorie und Item ein
-- verankertes Model in ReplicatedStorage.ShowcaseModels.<Kategorie>.<ItemId>. Der Client klont
-- das Model lokal auf das Podium und dreht es. Pivot = Mitte der Unterkante.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Pickaxes = require(Shared.Definitions.Pickaxes)
local Backpacks = require(Shared.Definitions.Backpacks)
local Vehicles = require(Shared.Definitions.Vehicles)
local Drills = require(Shared.Definitions.Drills)
local Conveyors = require(Shared.Definitions.Conveyors)
local PickaxeModels = require(script.Parent.PickaxeModels)
local BackpackModels = require(script.Parent.BackpackModels)
local VehicleModelBuilder = require(script.Parent.VehicleModelBuilder)
local DrillModelBuilder = require(script.Parent.DrillModelBuilder)

local ShowcaseItems = {}

local WOOD = Color3.fromRGB(150, 106, 66)
local WOOD_DARK = Color3.fromRGB(100, 70, 44)
local METAL = Color3.fromRGB(70, 74, 80)
local LEATHER = Color3.fromRGB(110, 72, 44)
local CANVAS = { Color3.fromRGB(120, 96, 64), Color3.fromRGB(70, 96, 70), Color3.fromRGB(150, 70, 50), Color3.fromRGB(60, 90, 130) }

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

-- Große Spitzhacke, aufrecht, Kopf oben. Stufe macht den Kopf etwas wuchtiger.
local function pickaxe(def: any, tier: number): Model
	local m = Instance.new("Model")
	m.Name = def.Id
	local base = CFrame.new(0, 0, 0)
	local s = 1 + math.min(tier, 10) * 0.03
	part(m, "Handle", Vector3.new(6.4, 0.45, 0.45), base * CFrame.new(0, 3.2, 0) * CFrame.Angles(0, 0, math.rad(90)), WOOD, Enum.Material.Wood, Enum.PartType.Cylinder)
	for k, y in { 1.2, 1.7, 2.2 } do
		part(m, `Grip{k}`, Vector3.new(0.18, 0.52, 0.52), base * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)), LEATHER, Enum.Material.Fabric, Enum.PartType.Cylinder)
	end
	local headY = 6.1
	part(m, "Collar", Vector3.new(0.9, 0.9, 0.9) * s, base * CFrame.new(0, headY, 0), METAL, Enum.Material.Metal)
	part(m, "Head", Vector3.new(4.2, 0.6, 0.6) * s, base * CFrame.new(0, headY, 0), def.HeadColor, Enum.Material.Metal)
	for _, side in { -1, 1 } do
		local tip = Instance.new("WedgePart")
		tip.Name = `Tip{side}`
		tip.Anchored = true
		tip.CanCollide = false
		tip.CanQuery = false
		tip.CanTouch = false
		tip.Size = Vector3.new(0.6 * s, 0.6 * s, 1.4 * s)
		tip.CFrame = base * CFrame.new(side * (2.1 * s + 0.7 * s), headY, 0) * CFrame.Angles(0, math.rad(side * 90), 0)
		tip.Color = def.HeadColor
		tip.Material = Enum.Material.Metal
		tip.Parent = m
	end
	part(m, "Cap", Vector3.new(0.2, 0.55, 0.55), base * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), WOOD_DARK, Enum.Material.Wood, Enum.PartType.Cylinder)
	m.WorldPivot = base
	return m
end

-- Rucksack, Größe wächst mit der Stufe
local function backpack(def: any, tier: number): Model
	local m = Instance.new("Model")
	m.Name = def.Id
	local s = 1.6 + tier * 0.18
	local color = CANVAS[(tier - 1) % #CANVAS + 1]
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.25)
	part(m, "Bag", Vector3.new(1.6, 2, 1) * s, CFrame.new(0, s, 0), color, Enum.Material.Fabric)
	part(m, "Flap", Vector3.new(1.65, 0.6, 1.05) * s, CFrame.new(0, 1.8 * s, 0), dark, Enum.Material.Fabric)
	part(m, "Pocket", Vector3.new(1, 0.7, 0.3) * s, CFrame.new(0, 0.7 * s, -0.55 * s), color:Lerp(Color3.new(0, 0, 0), 0.15), Enum.Material.Fabric)
	for _, x in { -0.5, 0.5 } do
		part(m, `Strap{x}`, Vector3.new(0.18, 1.8, 0.12) * s, CFrame.new(x * s, s, 0.55 * s), LEATHER, Enum.Material.Fabric)
	end
	part(m, "Buckle", Vector3.new(0.3, 0.2, 0.08) * s, CFrame.new(0, 1.55 * s, -0.55 * s), Color3.fromRGB(200, 180, 90), Enum.Material.Metal)
	-- Schlafrolle oben ab Stufe 3
	if tier >= 3 then
		part(m, "Bedroll", Vector3.new(1.7, 0.55, 0.55) * s, CFrame.new(0, 2.25 * s, 0) * CFrame.Angles(0, 0, 0), Color3.fromRGB(70, 96, 70), Enum.Material.Fabric, Enum.PartType.Cylinder)
	end
	m.WorldPivot = CFrame.new()
	return m
end

function ShowcaseItems.build()
	local old = ReplicatedStorage:FindFirstChild("ShowcaseModels")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "ShowcaseModels"
	local function folder(name: string): Folder
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = root
		return f
	end
	local picks = folder("pickaxe")
	for i, def in Pickaxes.List do
		-- 3D-Vorlage aus dem Pack (D-071), Höhe wie in der Vorlage (4–6,4 Studs); sonst Platzhalter
		local m = PickaxeModels.clone(def)
		if m then
			m:ScaleTo(m:GetScale() * 1.6)
			-- Kopf liegt entlang X: Pivot drehen, damit die Kamera zuerst die Breitseite sieht
			m.WorldPivot = m.WorldPivot * CFrame.Angles(0, math.rad(90), 0)
		else
			m = pickaxe(def, i)
			-- groß genug für die Kamera-Ansicht
			m:ScaleTo(1.5)
		end
		m.Parent = picks
	end
	local packs = folder("backpack")
	for i, def in Backpacks.List do
		-- 3D-Vorlage aus dem Pack (D-074), Vorderseite zur Kamera; sonst Platzhalter
		local m = BackpackModels.standing(def, 2.4)
		if not m then
			m = backpack(def, i)
			m:ScaleTo(1.3)
		end
		m.Parent = packs
	end
	-- Autohaus (D-072): alle Fahrzeuge des Autohauses (nicht LKW-Laden), Ausstellungsmodell
	-- ohne Sitz/Gelenke; Pivot = Boden unter der Fahrzeugmitte, Breitseite zur Kamera
	local cars = folder("vehicle")
	for _, def in Vehicles.List do
		if def.Dealer ~= "truck" then
			local ok, m = pcall(VehicleModelBuilder.build, def, CFrame.new(), false)
			if ok and m then
				m.Name = def.Id
				m.WorldPivot = CFrame.Angles(0, math.rad(90), 0)
				for _, d in m:GetDescendants() do
					if d:IsA("BasePart") then
						d.Anchored = true
						d.CanCollide = false
						d.CanTouch = false
						d.CanQuery = false
					elseif d:IsA("Script") or d:IsA("LocalScript") then
						d:Destroy()
					end
				end
				m.Parent = cars
			else
				warn(`[ShowcaseItems] Fahrzeug {def.Id} nicht gebaut: {m}`)
			end
		end
	end
	-- Drill-Shop (D-075): alle Drills als 3D-Modell, Breitseite zur Kamera; Förderbänder als
	-- einfaches Bandstück (Länge wächst mit der Stufe)
	local drills = folder("drill")
	for _, def in Drills.List do
		local ok, m = pcall(DrillModelBuilder.build, def, CFrame.new())
		if ok and m then
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
					d.CanTouch = false
					d.CanQuery = false
				elseif d:IsA("ParticleEmitter") or d:IsA("Light") then
					d:Destroy()
				end
			end
			m.WorldPivot = CFrame.Angles(0, math.rad(90), 0)
			m.Parent = drills
		else
			warn(`[ShowcaseItems] Drill {def.Id} nicht gebaut: {m}`)
		end
	end
	local belts = folder("conveyor")
	for i, def in Conveyors.List do
		local m = Instance.new("Model")
		m.Name = def.Id
		local len = 8 + i * 1.5
		part(m, "Frame", Vector3.new(len, 1.4, 3.4), CFrame.new(0, 1.6, 0), METAL, Enum.Material.Metal)
		part(m, "Belt", Vector3.new(len + 0.2, 0.25, 2.8), CFrame.new(0, 2.4, 0), Color3.fromRGB(40, 40, 44), Enum.Material.Rubber)
		for _, x in { -len / 2 + 0.8, len / 2 - 0.8 } do
			for _, z in { -1.3, 1.3 } do
				part(m, `Leg{x}{z}`, Vector3.new(0.4, 1, 0.4), CFrame.new(x, 0.5, z), METAL, Enum.Material.Metal)
			end
		end
		part(m, "Stripe", Vector3.new(len, 0.3, 0.1), CFrame.new(0, 1.6, -1.75), CANVAS[(i - 1) % #CANVAS + 1], Enum.Material.SmoothPlastic)
		m.WorldPivot = CFrame.new()
		m.Parent = belts
	end
	root.Parent = ReplicatedStorage
end

return table.freeze(ShowcaseItems)
