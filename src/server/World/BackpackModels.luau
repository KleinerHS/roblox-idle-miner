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

-- Leuchtstärke je Stufe (Felix 2026-10-28): ab Stufe 9 leuchten, bis Stufe 13 nur ganz leicht,
-- danach immer stärker, gegen Ende ruhig überbelichtet. 0 = aus, 1 = Maximum.
-- (Die Modelle der Stufen 1–9 haben keine Leucht-Teile; sichtbar wird es ab Stufe 10.)
local function glowStrength(tier: number): number
	if tier < 9 then
		return 0
	elseif tier <= 13 then
		return 0.05 + (tier - 9) * 0.04 -- 0,05 … 0,21
	end
	return math.min(1, 0.25 + (tier - 13) / 9 * 0.75) -- Stufe 14 → 0,33 … Stufe 22 → 1
end

-- Leuchten (nach Felix' Enable_Glow.luau): FX-Teile Neon mit einem farbigen Licht, Stärke nach
-- Stufe (glowStrength); ein gemeinsamer BloomEffect nur, wenn die Beleuchtung noch keinen hat.
-- Rucksäcke ohne FX-Teile bleiben unbeleuchtet.
function BackpackModels.applyGlow(model: Model, tier: number)
	local g = glowStrength(tier)
	local glow: { MeshPart } = {}
	for _, d in model:GetDescendants() do
		if d:IsA("MeshPart") and string.find(d.Name, "FX_Emissive", 1, true) then
			for _, child in d:GetChildren() do
				if child:IsA("SurfaceAppearance") then
					child:Destroy()
				end
			end
			d.TextureID = ""
			table.insert(glow, d)
		end
	end
	if #glow == 0 then
		return
	end
	-- Grundfarbe aus der Vorlage merken, damit mehrfaches Anwenden nicht aufhellt
	local base = glow[1]:GetAttribute("FXColor")
	local color: Color3 = if typeof(base) == "Color3" then base else glow[1].Color
	for _, p in glow do
		if p:GetAttribute("FXColor") == nil then
			p:SetAttribute("FXColor", p.Color)
		end
		local own = p:GetAttribute("FXColor")
		local c: Color3 = if typeof(own) == "Color3" then own else color
		if g <= 0 then
			p.Material = Enum.Material.SmoothPlastic
			p.Transparency = 0
			p.Color = c
		else
			p.Material = Enum.Material.Neon
			-- schwach: Neon halb durchsichtig; stark: Farbe Richtung Weiß (überbelichtet)
			p.Transparency = math.max(0, 0.6 - g * 2)
			p.Color = c:Lerp(Color3.new(1, 1, 1), math.max(0, g - 0.5) * 0.9)
		end
	end
	local p = glow[1]
	local light = p:FindFirstChild("BackpackGlowLight") :: PointLight?
	if g <= 0 then
		if light then
			light:Destroy()
		end
		return
	end
	if not light then
		local l = Instance.new("PointLight")
		l.Name = "BackpackGlowLight"
		l.Parent = p
		light = l
	end
	local l = light :: PointLight
	l.Color = color
	l.Range = 3 + g * 9
	l.Brightness = 0.2 + g * g * 3
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
	local tier = table.find(Backpacks.List, def) or 1
	BackpackModels.applyGlow(m, tier)
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
