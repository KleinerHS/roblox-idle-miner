--!strict
-- Erz- und Barren-Icons (docs/09 §61–62: „Erze sollen tatsächlich als Erze erkennbar sein,
-- nicht nur ein farbiger Kreis“). Kleines 3D-Modell in einem ViewportFrame, ohne Bild-Assets:
--   * Erz Stufe 1–12:  Gesteinsbrocken mit matten Erzklumpen in der Erzfarbe
--   * Erz Stufe 13–30: Gesteinsbrocken mit metallisch glänzenden Klumpen
--   * Erz ab Stufe 31: Kristallgruppe in der Erzfarbe, seltene Erze wirken auffälliger
--   * Barren:          Barren in der Materialfarbe
-- Jedes Material sieht immer gleich aus (fester Zufall je Stufe). Modelle werden einmal gebaut
-- und für jedes Icon geklont.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Materials = require(ReplicatedStorage:WaitForChild("Shared").Definitions.Materials)

local OreIcon = {}

local ROCK = Color3.fromRGB(92, 88, 84)
local ROCK_DARK = Color3.fromRGB(64, 61, 58)

local templates: { [string]: Model } = {}

local function part(model: Model, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	if shape then
		p.Shape = shape
	end
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function rockBase(model: Model)
	part(model, Vector3.new(2.2, 1.4, 1.9), CFrame.Angles(0.15, 0.4, -0.1), ROCK, Enum.Material.Slate)
	part(model, Vector3.new(1.4, 1.2, 1.3), CFrame.new(-0.6, 0.3, -0.4) * CFrame.Angles(0.5, 1.1, 0.3), ROCK_DARK, Enum.Material.Slate)
end

-- Richtung zur Kamera (siehe create): Erzklumpen sitzen auf der sichtbaren Seite
local VIEW = Vector3.new(0.9, 0.75, 1).Unit

local function build(id: string): Model?
	local info = Materials.Get(id)
	if not info then
		return nil
	end
	local model = Instance.new("Model")
	local rng = Random.new(info.Tier * 97 + (if info.Kind == "Bar" then 7 else 0))
	local color = info.Color

	if info.Kind == "Bar" then
		-- Barren: Grundkörper mit abgeschrägter Oberseite, leicht glänzend
		part(model, Vector3.new(3, 0.7, 1.4), CFrame.Angles(0, 0.5, 0), color, Enum.Material.Metal)
		part(model, Vector3.new(2.5, 0.4, 1.0), CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0.5, 0), color:Lerp(Color3.new(1, 1, 1), 0.15), Enum.Material.Metal)
	elseif info.Tier <= 30 then
		rockBase(model)
		local metallic = info.Tier > 12
		local material = if metallic then Enum.Material.Metal elseif info.Id == "ore_coal" then Enum.Material.Basalt else Enum.Material.Slate
		local right = VIEW:Cross(Vector3.yAxis).Unit
		local up = right:Cross(VIEW).Unit
		for i = 1, 5 do
			local s = rng:NextNumber(0.6, 0.95) * (if i == 1 then 1.3 else 1)
			local spread = right * rng:NextNumber(-0.75, 0.75) + up * rng:NextNumber(-0.45, 0.55)
			local pos = VIEW * 0.75 + spread
			local nugget = part(model, Vector3.new(s, s * 0.8, s), CFrame.new(pos) * CFrame.Angles(rng:NextNumber(0, 3), rng:NextNumber(0, 3), rng:NextNumber(0, 3)), color, material)
			if metallic then
				nugget.Reflectance = 0.15
			end
		end
	else
		-- Kristallgruppe: mehrere spitze Prismen, je seltener desto mehr
		part(model, Vector3.new(2.4, 0.8, 2.0), CFrame.new(0, -0.4, 0) * CFrame.Angles(0, 0.3, 0), ROCK_DARK, Enum.Material.Slate)
		local count = if info.Tier >= 45 then 6 elseif info.Tier >= 38 then 5 else 4
		for i = 1, count do
			local h = rng:NextNumber(1.2, 2.4) * (if i == 1 then 1.25 else 1)
			local w = rng:NextNumber(0.35, 0.6)
			local tilt = CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 6), rng:NextNumber(-0.5, 0.5))
			local base = CFrame.new(rng:NextNumber(-0.7, 0.7), 0, rng:NextNumber(-0.6, 0.6)) * tilt
			local body = part(model, Vector3.new(w, h, w), base * CFrame.new(0, h / 2, 0), color, Enum.Material.Glass)
			body.Transparency = 0.15
			local tip = part(model, Vector3.new(w, w * 1.2, w), base * CFrame.new(0, h + w * 0.55, 0) * CFrame.Angles(0, math.rad(45), 0), color:Lerp(Color3.new(1, 1, 1), 0.3), Enum.Material.Neon)
			if info.Tier >= 45 then
				body.Material = Enum.Material.Neon
			end
		end
	end
	return model
end

local function template(id: string): Model?
	local t = templates[id]
	if t == nil then
		t = build(id)
		if t then
			templates[id] = t
		end
	end
	return t
end

-- Icon für ein Material. `size` in Pixeln (quadratisch).
function OreIcon.create(id: string, size: number): ViewportFrame
	local frame = Instance.new("ViewportFrame")
	frame.Name = "OreIcon"
	frame.Size = UDim2.fromOffset(size, size)
	frame.BackgroundTransparency = 1
	frame.Ambient = Color3.fromRGB(150, 150, 155)
	frame.LightColor = Color3.fromRGB(255, 250, 240)
	frame.LightDirection = Vector3.new(-0.6, -1, -0.4)
	local t = template(id)
	if not t then
		return frame
	end
	local model = t:Clone()
	model.Parent = frame
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	local cf, extents = model:GetBoundingBox()
	local radius = extents.Magnitude / 2
	local distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * 0.82
	camera.CFrame = CFrame.lookAt(cf.Position + VIEW * distance, cf.Position)
	camera.Parent = frame
	frame.CurrentCamera = camera
	return frame
end

return OreIcon
