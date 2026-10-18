--!strict
-- Bereitet Felix' Fahrzeugmodelle (Creator Store) als Karosserie-Vorlagen vor (2026-10-18).
-- Läuft in Studio (Edit). Quelle: ServerStorage._VehicleCandidates.<Name>, Ziel:
-- ServerStorage.Vendor.VehicleBodies.<Name> (Format siehe VehicleModelBuilder.bodyTemplate).
--   * entfernt alle Skripte, GUIs, Sounds, Sitze, Gelenke, Werte, Lichter-Skripte, unsichtbare Teile
--   * entfernt Markenlogos und Nummernschilder (D-026: keine echten Marken) – je Fahrzeug konfiguriert
--   * bestimmt Räder, Fahrtrichtung und Bodenpunkt, richtet alles am Pivot aus (-Z = vorne)
--   * legt CargoFill (Ladung bzw. Dachluke) und SeatMarker an
-- Konfiguration je Fahrzeug unten in CONFIG; Ergebnis per Bildschirmfoto prüfen.

type Config = {
	Source: string,
	-- Rad-Erkennung: "named" = Teile FL/FR/RL/RR; sonst Namen der Radteile (werden nach Position gruppiert)
	Wheels: "named" | { string },
	-- Fahrtrichtung, falls kein VehicleSeat: Achse der Bounding-Box ("+Z" / "-Z" / "+X" / "-X")
	Forward: string?,
	-- Offene Ladefläche: Mitte/Größe im Fahrzeugrahmen (Studs, Boden = 0); sonst geschlossen
	OpenBed: { Center: Vector3, Size: Vector3 }?,
	-- Teile/Decals, die entfernt werden (Namen, Teilstrings in Kleinbuchstaben)
	Remove: { string }?,
	-- nur diese Untermodelle übernehmen (z. B. Zugmaschine ohne Anhänger)
	Only: { string }?,
	-- Markenlogos: Teile an Position (Fahrzeugrahmen) mit ungefährer Größe, Decals/Texturen nach Bild-ID
	RemoveParts: { { Near: Vector3, Size: Vector3 } }?,
	RemoveImages: { string }?,
	-- Fahrersitz ohne VehicleSeat: Name des Sitzteils (linkes Exemplar) und Höhenkorrektur
	SeatPart: string?,
	SeatDrop: number?,
}

local CONFIG: { [string]: Config } = (_G :: any).VehicleBodyConfig or {}

local SS = game:GetService("ServerStorage")
local vendor = SS:WaitForChild("Vendor")
local bodies = vendor:FindFirstChild("VehicleBodies") or Instance.new("Folder")
bodies.Name = "VehicleBodies"
bodies.Parent = vendor

local STRIP_CLASSES = {
	"LuaSourceContainer", "LayerCollector", "Sound", "SoundEffect", "ValueBase", "JointInstance", "Constraint",
	"BindableEvent", "BindableFunction", "RemoteEvent", "RemoteFunction", "UnreliableRemoteEvent",
	"ProximityPrompt", "ClickDetector", "ParticleEmitter", "Smoke", "Fire", "Sparkles", "Light",
	"HandleAdornment", "Humanoid", "WeldConstraint",
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
				if n:find(r, 1, true) then
					kill = true
					break
				end
			end
		end
		if kill then
			d:Destroy()
		end
	end
	-- Sitze werden zu einfachen Teilen (nur Optik, niemand kann sich hineinsetzen)
	for _, d in root:GetDescendants() do
		if d:IsA("Seat") or d:IsA("VehicleSeat") then
			local p = Instance.new("Part")
			p.Name = d.Name
			p.Size = d.Size
			p.CFrame = d.CFrame
			p.Color = d.Color
			p.Material = d.Material
			p.Transparency = d.Transparency
			for _, c in d:GetChildren() do
				c.Parent = p
			end
			p.Parent = d.Parent
			d:Destroy()
		end
	end
end

local function bboxAxis(model: Model, axis: string): Vector3
	local cf = model:GetBoundingBox()
	local v = if axis:sub(2) == "Z" then cf.LookVector * -1 else cf.RightVector
	return if axis:sub(1, 1) == "-" then -v else v
end

local function prepare(name: string, cfg: Config): string
	local source = SS._VehicleCandidates:FindFirstChild(cfg.Source)
	assert(source, `Quelle fehlt: {cfg.Source}`)
	local work = Instance.new("Model")
	work.Name = name
	if cfg.Only then
		for _, n in cfg.Only do
			local part = source:FindFirstChild(n, true)
			assert(part, `Teil fehlt: {n}`)
			part:Clone().Parent = work
		end
	else
		for _, c in source:GetChildren() do
			c:Clone().Parent = work
		end
	end

	-- Fahrtrichtung vor dem Strippen (VehicleSeat)
	local seat = work:FindFirstChildWhichIsA("VehicleSeat", true)
	local seatPos = seat and seat.Position
	local seatMesh: BasePart? = nil
	if cfg.SeatPart then
		for _, d in work:GetDescendants() do
			if d:IsA("BasePart") and d.Name == cfg.SeatPart then
				seatMesh = if seatMesh == nil then d else seatMesh
				-- linkes Exemplar wird unten nach Fahrzeugrahmen gewählt
				if not seatMesh then
					seatMesh = d
				end
			end
		end
	end
	-- ohne Sitz: Achse der Bounding-Box des Originals (dessen Ausrichtung bleibt beim Klonen gleich)
	local bboxSource: Model = if source:IsA("Model") then source else work
	local forward: Vector3 = if seat then Vector3.new(seat.CFrame.LookVector.X, 0, seat.CFrame.LookVector.Z).Unit else bboxAxis(bboxSource, cfg.Forward or "-Z")

	-- Räder finden
	type Wheel = { pos: Vector3, radius: number, width: number, visuals: { BasePart } }
	local wheels: { Wheel } = {}
	if cfg.Wheels == "named" then
		for _, d in work:GetDescendants() do
			if d:IsA("BasePart") and (d.Name == "FL" or d.Name == "FR" or d.Name == "RL" or d.Name == "RR") then
				local visuals = {}
				for _, v in d:GetDescendants() do
					if v:IsA("BasePart") and v.Transparency < 0.98 then
						table.insert(visuals, v)
					end
				end
				if #visuals == 0 then
					table.insert(visuals, d)
				end
				table.insert(wheels, { pos = d.Position, radius = math.max(d.Size.X, d.Size.Y, d.Size.Z) / 2, width = math.min(d.Size.X, d.Size.Y, d.Size.Z), visuals = visuals })
			end
		end
	else
		-- Radteile nach Position gruppieren
		local names = cfg.Wheels :: { string }
		local groups: { Wheel } = {}
		for _, d in work:GetDescendants() do
			if d:IsA("BasePart") and table.find(names, d.Name) then
				local found: Wheel? = nil
				for _, g in groups do
					if (g.pos - d.Position).Magnitude < 1.6 then
						found = g
					end
				end
				if not found then
					found = { pos = d.Position, radius = 0, width = 0, visuals = {} }
					table.insert(groups, found :: Wheel)
				end
				local g = found :: Wheel
				table.insert(g.visuals, d)
				local r = math.max(d.Size.X, d.Size.Y, d.Size.Z) / 2
				if r > g.radius then
					g.radius = r
					g.pos = d.Position
					g.width = math.min(d.Size.X, d.Size.Y, d.Size.Z)
				end
			end
		end
		wheels = groups
	end
	assert(#wheels >= 4, `{name}: nur {#wheels} Räder gefunden`)

	-- Fahrzeugrahmen: Mitte der Räder auf dem Boden, -Z = vorne
	local sum = Vector3.zero
	for _, w in wheels do
		sum += w.pos
	end
	local center = sum / #wheels
	local radius = 0
	for _, w in wheels do
		radius = math.max(radius, w.radius)
	end
	local ground = Vector3.new(center.X, center.Y - radius, center.Z)
	local frame = CFrame.lookAt(ground, ground + forward)

	-- Räder links/rechts, vorne/hinten zuordnen (vorne = kleinstes Z, äußerste Achsen)
	local minZ, maxZ = math.huge, -math.huge
	for _, w in wheels do
		local p = frame:PointToObjectSpace(w.pos)
		minZ = math.min(minZ, p.Z)
		maxZ = math.max(maxZ, p.Z)
	end
	local slots: { [string]: Wheel } = {}
	local track = 0
	for _, w in wheels do
		local p = frame:PointToObjectSpace(w.pos)
		local front = math.abs(p.Z - minZ) < 0.8
		local rear = math.abs(p.Z - maxZ) < 0.8
		local side = if p.X < 0 then "L" else "R"
		if front then
			slots[`F{side}`] = w
			track = math.max(track, math.abs(p.X))
		elseif rear then
			slots[`R{side}`] = w
		end
	end

	-- Ergebnis-Vorlage
	local template = Instance.new("Model")
	template.Name = name
	local body = Instance.new("Model")
	body.Name = "Body"
	body.Parent = template
	local wheelParts: { [BasePart]: boolean } = {}
	for slot, w in slots do
		local wm = Instance.new("Model")
		wm.Name = `Wheel{slot}`
		for _, v in w.visuals do
			wheelParts[v] = true
			v.Parent = wm
		end
		wm.Parent = template
	end
	-- übrige Teile (auch Räder mittlerer Achsen) gehören zur Karosserie
	for _, d in work:GetDescendants() do
		if d:IsA("BasePart") and not wheelParts[d] then
			d.Parent = body
		end
	end
	strip(template, cfg.Remove)
	for _, d in template:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		end
	end

	-- Markenlogos und Nummernschild-Bilder entfernen (D-026)
	local pivotFrame = frame
	for _, d in template:GetDescendants() do
		if d.Parent == nil then
			continue
		end
		if (d:IsA("Decal") or d:IsA("Texture")) and cfg.RemoveImages then
			for _, id in cfg.RemoveImages do
				if tostring(d.Texture):find(id, 1, true) then
					d:Destroy()
					break
				end
			end
		elseif d:IsA("BasePart") and cfg.RemoveParts then
			local lp = pivotFrame:PointToObjectSpace(d.Position)
			for _, r in cfg.RemoveParts do
				local sizeOk = (Vector3.new(math.abs(d.Size.X - r.Size.X), math.abs(d.Size.Y - r.Size.Y), math.abs(d.Size.Z - r.Size.Z))).Magnitude < 0.1
				if sizeOk and (lp - r.Near).Magnitude < 0.4 then
					d:Destroy()
					break
				end
			end
		end
	end

	-- Ladung / Dachluke
	local fill = Instance.new("Part")
	fill.Name = "CargoFill"
	fill.Anchored = true
	fill.CanCollide = false
	fill.Material = Enum.Material.Slate
	fill.Color = Color3.fromRGB(70, 66, 62)
	if cfg.OpenBed then
		fill.Size = cfg.OpenBed.Size
		fill.CFrame = frame * CFrame.new(cfg.OpenBed.Center)
	else
		-- geschlossen: hinterer Aufbau, Oberkante = Dach
		local _, extents = body:GetBoundingBox()
		local roof = 0
		for _, d in body:GetDescendants() do
			if d:IsA("BasePart") then
				local p = frame:PointToObjectSpace(d.Position)
				if p.Z > 0 then
					roof = math.max(roof, p.Y + d.Size.Y / 2)
				end
			end
		end
		local length = math.max(4, maxZ + radius - 0)
		fill.Size = Vector3.new(4, 0.2, math.min(length, extents.Magnitude))
		fill.CFrame = frame * CFrame.new(0, roof - 0.1, length / 2)
		fill:SetAttribute("CargoHidden", true)
	end
	fill.Parent = template

	-- Sitz
	local marker = Instance.new("Part")
	marker.Name = "SeatMarker"
	marker.Anchored = true
	marker.CanCollide = false
	marker.Transparency = 1
	marker.Size = Vector3.new(2, 1, 2)
	local sp = if seatPos then frame:PointToObjectSpace(seatPos) else Vector3.new(-1.5, radius + 1.5, minZ + 4)
	if cfg.SeatPart then
		-- linker Sitz (Fahrerseite) aus den gleichnamigen Teilen des Originals
		local best: Vector3? = nil
		for _, d in source:GetDescendants() do
			if d:IsA("BasePart") and d.Name == cfg.SeatPart then
				local lp = frame:PointToObjectSpace(d.Position)
				if best == nil or lp.X < (best :: Vector3).X then
					best = lp
				end
			end
		end
		if best then
			sp = (best :: Vector3) - Vector3.new(0, cfg.SeatDrop or 0, 0)
		end
	end
	marker.CFrame = frame * CFrame.new(sp)
	marker.Parent = template

	template.WorldPivot = frame
	template:SetAttribute("WheelRadius", radius)
	template:SetAttribute("WheelWidth", (slots.FL and slots.FL.width) or 1)
	template:SetAttribute("Track", track)
	template:SetAttribute("FrontZ", minZ)
	template:SetAttribute("RearZ", maxZ)
	-- für die Ablage an den Ursprung schieben
	template:PivotTo(CFrame.new(0, 500, 0))
	local old = bodies:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	template.Parent = bodies
	work:Destroy()
	local _, size = template:GetBoundingBox()
	return string.format("%s: Räder %d (Slots %s), r %.2f, Spur %.2f, Achsen %.2f/%.2f, Größe %.1f×%.1f×%.1f, Teile %d", name, #wheels, table.concat((function()
		local t = {}
		for k in slots do
			table.insert(t, k)
		end
		table.sort(t)
		return t
	end)(), ","), radius, track, minZ, maxZ, size.X, size.Y, size.Z, #template:GetDescendants())
end

local out = {}
for name, cfg in CONFIG do
	local ok, r = pcall(prepare, name, cfg)
	table.insert(out, if ok then r else `{name}: FEHLER {r}`)
end
return table.concat(out, "\n")
