--!strict
-- Zugriff auf die 3D-Vorlagen aus Felix' Rucksack-Pack (D-074) in ServerStorage.Vendor.Backpacks.
-- Jede Vorlage ist ein Model aus verankerten MeshParts (Body, Trim, Harness, ggf. FX_Emissive).
-- Pivot = Befestigungspunkt am Rücken (Mitte der Rückenplatte), +Z zeigt vom Rücken weg, +Y oben.
-- Fehlt eine Vorlage, geben die Funktionen nil zurück und der Aufrufer nimmt den Platzhalter.

local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")

local Backpacks = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Definitions.Backpacks)

local BackpackModels = {}

local function folder(): Instance?
	local vendor = ServerStorage:FindFirstChild("Vendor")
	return vendor and vendor:FindFirstChild("Backpacks")
end

-- Leuchten (nach Felix' Enable_Glow.luau): FX-Teile Neon, ein schwaches farbiges Licht; ein
-- gemeinsamer BloomEffect nur, wenn die Beleuchtung noch keinen hat. Rucksäcke ohne FX-Teile
-- bleiben unbeleuchtet.
function BackpackModels.applyGlow(model: Model)
	local glow: { MeshPart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("MeshPart") and string.find(d.Name, "FX_Emissive", 1, true) then
			for _, child in d:GetChildren() do
				if child:IsA("SurfaceAppearance") then
					child:Destroy()
				end
			end
			d.TextureID = ""
			d.Material = Enum.Material.Neon
			table.insert(glow, d)
		end
	end
	if #glow == 0 then
		return
	end
	local p = glow[1]
	local light = p:FindFirstChild("BackpackGlowLight") :: PointLight?
	if not light then
		local l = Instance.new("PointLight")
		l.Name = "BackpackGlowLight"
		l.Parent = p
		light = l
	end
	local l = light :: PointLight
	l.Color = p.Color
	l.Range = 5
	l.Brightness = 0.65
	l.Shadows = false
	if not Lighting:FindFirstChildOfClass("BloomEffect") then
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "MiningBackpackBloom"
		bloom.Intensity = 0.35
		bloom.Size = 18
		bloom.Threshold = 1.0
		bloom.Parent = Lighting
	end
end

-- Kopie der Vorlage, verankert, ohne Kollision, Leuchten angewendet. Pivot = Befestigungspunkt.
function BackpackModels.clone(def: Backpacks.BackpackDefinition): Model?
	local f = folder()
	local template = f and f:FindFirstChild(def.Id)
	if not template or not template:IsA("Model") then
		return nil
	end
	local m = template:Clone()
	m.Name = def.Id
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		end
	end
	BackpackModels.applyGlow(m)
	return m
end

-- Kopie, stehend: Pivot auf Mitte der Unterkante, Vorderseite (+Z) zeigt in Richtung cf.LookVector.
-- scale vergrößert gleichmäßig (Ausstellung).
function BackpackModels.standing(def: Backpacks.BackpackDefinition, scale: number?): Model?
	local m = BackpackModels.clone(def)
	if not m then
		return nil
	end
	if scale and scale ~= 1 then
		m:ScaleTo(m:GetScale() * scale)
	end
	local pivot = m:GetPivot()
	local box, size = m:GetBoundingBox()
	local bottom = pivot.Rotation + (box.Position - pivot.UpVector * size.Y / 2)
	-- +Z der Vorlage soll nach vorne (−Z des Pivots) zeigen
	m.WorldPivot = bottom * CFrame.Angles(0, math.pi, 0)
	return m
end

return table.freeze(BackpackModels)
