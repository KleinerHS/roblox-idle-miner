--!strict
-- Bereitet die Anhänger eines Lastzugs aus Felix' Modell als Vorlagen vor (Phase 18c, 2026-10-19).
-- Läuft in Studio (Edit) NACH tools/PrepareVehicleBodies.luau für die Zugmaschine. Quelle:
-- ServerStorage._VehicleCandidates.<Source> (komplettes Modell mit Zugmaschine und Anhängern),
-- Ziel: ServerStorage.Vendor.VehicleBodies.<VehicleId>_Trailers (Folder mit Models "1", "2", …).
-- Alle Anhänger liegen im selben Rahmen wie die Zugmaschinen-Vorlage (Pivot = Boden unter der
-- Achsmitte der Zugmaschine, -Z = vorne), damit sie beim Spawnen mit derselben CFrame landen.
-- Aufbau je Anhänger (siehe World/TrailerBuilder.luau):
--   Model "Body" (Optik), Models "Wheel<i>" (Radoptik je Rad), Parts "Tire<i>" (unsichtbar,
--   Mitte/Größe des Rads), Part "Chassis" (Physik-Grundkörper), Part "Kingpin" (Kupplungspunkt
--   zum vorderen Fahrzeug, Attribut CoupleTo = 0 Zugmaschine / n Anhänger n), optional "CargoFill".

type TrailerConfig = {
	Model: string, -- Name des Anhänger-Untermodells in der Quelle
	Kingpin: Vector3, -- Kupplungspunkt im Pivot-Rahmen der Quelle
	CoupleTo: number,
	Cargo: string?, -- Name des Aufbau-Untermodells (Ladung darin)
}
type Config = {
	Source: string,
	VehicleId: string,
	TractorWheels: { string }, -- Radteile der Zugmaschine (für den gemeinsamen Rahmen)
	TractorWheelParent: string,
	Trailers: { TrailerConfig },
	Remove: { string }?,
}

local CONFIG: Config = (_G :: any).TrailerConfig

local SS = game:GetService("ServerStorage")
local bodies = SS:WaitForChild("Vendor"):WaitForChild("VehicleBodies")

local STRIP_CLASSES = {
	"LuaSourceContainer", "LayerCollector", "Sound", "SoundEffect", "ValueBase", "JointInstance", "Constraint",
	"BindableEvent", "BindableFunction", "RemoteEvent", "RemoteFunction", "UnreliableRemoteEvent",
	"ProximityPrompt", "ClickDetector", "ParticleEmitter", "Smoke", "Fire", "Sparkles", "Light",
	"HandleAdornment", "Humanoid", "WeldConstraint", "Attachment",
}

local function strip(root: Instance, remove: { string }?)
	for _, d in root:GetDescendants() do
		if d.Parent == nil then
			continue
		end
		local kill = false
		for _, c in STRIP_CLASSES do
			if d:IsA(c) then
				kill = true
				break
			end
		end
		if not kill and d:IsA("BasePart") and d.Transparency >= 0.98 then
			kill = true
		end
		if not kill and remove then
			local n = d.Name:lower()
			for _, r in remove do
				if n == r then
					kill = true
					break
				end
			end
		end
		if kill then
			d:Destroy()
		end
	end
end

local function invisible(name: string, size: Vector3, cf: CFrame, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Transparency = 1
	p.Parent = parent
	return p
end

local source = SS._VehicleCandidates:FindFirstChild(CONFIG.Source) :: Model
assert(source, `Quelle fehlt: {CONFIG.Source}`)
local srcPivot = source:GetPivot()

-- Gemeinsamer Rahmen wie PrepareVehicleBodies (Zugmaschine): Mitte der Radteile, Boden darunter,
-- Fahrtrichtung des Fahrersitzes
local wheelParent = source:FindFirstChild(CONFIG.TractorWheelParent) :: Instance
local sum, count, radius = Vector3.zero, 0, 0
for _, d in wheelParent:GetDescendants() do
	if d:IsA("BasePart") and table.find(CONFIG.TractorWheels, d.Name) then
		sum += d.Position
		count += 1
		radius = math.max(radius, math.max(d.Size.X, d.Size.Y, d.Size.Z) / 2)
	end
end
assert(count >= 4, "Räder der Zugmaschine fehlen")
local center = sum / count
local seat = source:FindFirstChildWhichIsA("VehicleSeat", true) :: VehicleSeat
local forward = Vector3.new(seat.CFrame.LookVector.X, 0, seat.CFrame.LookVector.Z).Unit
local ground = Vector3.new(center.X, center.Y - radius, center.Z)
local frame = CFrame.lookAt(ground, ground + forward)
-- Ablage wie die Zugmaschine: Pivot bei (0, 500, 0)
local store = CFrame.new(0, 500, 0)
local move = store * frame:Inverse()

local folderName = `{CONFIG.VehicleId}_Trailers`
local old = bodies:FindFirstChild(folderName)
if old then
	old:Destroy()
end
local folder = Instance.new("Folder")
folder.Name = folderName

local out = {}
for index, cfg in CONFIG.Trailers do
	local src = source:FindFirstChild(cfg.Model) :: Model
	assert(src, `Anhänger fehlt: {cfg.Model}`)
	local work = src:Clone()
	local template = Instance.new("Model")
	template.Name = tostring(index)

	-- Räder (vor dem Strippen: Radteile sind unsichtbar)
	local tires: { { cf: CFrame, size: Vector3, visuals: { BasePart } } } = {}
	for _, d in work:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Wheels Left" or d.Name == "Wheels Right") then
			local visuals = {}
			for _, v in d:GetDescendants() do
				if v:IsA("BasePart") and v.Transparency < 0.98 then
					table.insert(visuals, v)
				end
			end
			local r = d.Size.Y / 2
			-- Achse quer zur Fahrtrichtung (lokal X des Rahmens)
			local p = frame:PointToObjectSpace(d.Position)
			table.insert(tires, { cf = frame * CFrame.new(p), size = Vector3.new(1.6, r * 2, r * 2), visuals = visuals })
		end
	end
	assert(#tires >= 2, `{cfg.Model}: keine Räder`)

	local body = Instance.new("Model")
	body.Name = "Body"
	body.Parent = template
	local used: { [BasePart]: boolean } = {}
	for i, t in tires do
		local wm = Instance.new("Model")
		wm.Name = `Wheel{i}`
		for _, v in t.visuals do
			used[v] = true
			v.Parent = wm
		end
		wm.Parent = template
	end
	-- Ladung: Schüttgut-Fläche im Aufbau
	local fillCF: CFrame? = nil
	local fillSize: Vector3? = nil
	if cfg.Cargo then
		local box = work:FindFirstChild(cfg.Cargo, true)
		if box and box:IsA("Model") then
			local bcf, bsize = box:GetBoundingBox()
			local lp = frame:PointToObjectSpace(bcf.Position)
			fillSize = Vector3.new(bsize.X - 1.4, 1.6, bsize.Z - 1.6)
			fillCF = frame * CFrame.new(lp.X, lp.Y + bsize.Y / 2 - 2.6, lp.Z)
		end
	end
	for _, d in work:GetDescendants() do
		if d:IsA("BasePart") and not used[d] then
			d.Parent = body
		end
	end
	strip(template, CONFIG.Remove)
	-- Reifen-Platzhalter (unsichtbar, deshalb erst nach dem Strippen)
	for i, t in tires do
		local tire = invisible(`Tire{i}`, t.size, t.cf, template)
		tire.Shape = Enum.PartType.Cylinder
	end
	for _, d in template:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		end
	end

	-- Physik-Grundkörper: von der Kupplung bis hinter die letzte Achse, auf Achshöhe
	local kp = frame:PointToObjectSpace(srcPivot * cfg.Kingpin)
	local minZ, maxZ, axleY = kp.Z, kp.Z, 0
	for _, t in tires do
		local p = frame:PointToObjectSpace(t.cf.Position)
		minZ = math.min(minZ, p.Z - 2)
		maxZ = math.max(maxZ, p.Z + 2)
		axleY = p.Y
	end
	local chassis = invisible("Chassis", Vector3.new(5, 1, maxZ - minZ), frame * CFrame.new(0, axleY + 1.2, (minZ + maxZ) / 2), template)
	local king = invisible("Kingpin", Vector3.new(1, 1, 1), frame * CFrame.new(kp), template)
	king:SetAttribute("CoupleTo", cfg.CoupleTo)
	if fillCF and fillSize then
		local fill = Instance.new("Part")
		fill.Name = "CargoFill"
		fill.Size = fillSize
		fill.CFrame = fillCF
		fill.Anchored = true
		fill.CanCollide = false
		fill.CanTouch = false
		fill.CanQuery = false
		fill.Material = Enum.Material.Slate
		fill.Color = Color3.fromRGB(70, 66, 62)
		fill.Transparency = 1
		fill.Parent = template
	end
	work:Destroy()

	-- in die Ablage verschieben, Pivot = gemeinsamer Rahmen
	for _, d in template:GetDescendants() do
		if d:IsA("BasePart") then
			d.CFrame = move * d.CFrame
		end
	end
	template.WorldPivot = store
	template:SetAttribute("TireCount", #tires)
	template.Parent = folder
	local _, size = template:GetBoundingBox()
	table.insert(out, string.format("%d %s: Räder %d, Kupplung z %.1f an %d, Chassis %.1f, Größe %.1f×%.1f×%.1f, Ladung %s, Teile %d", index, cfg.Model, #tires, kp.Z, cfg.CoupleTo, chassis.Size.Z, size.X, size.Y, size.Z, tostring(fillSize ~= nil), #template:GetDescendants()))
end
folder.Parent = bodies
return table.concat(out, "\n")
