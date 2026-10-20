--!strict
-- Echte Anhänger für Lastzüge (Phase 18c, D-048, PLANS/ROAD_TRAINS.md T1/T2).
-- Vorlagen: ServerStorage.Vendor.VehicleBodies.<VehicleId>_Trailers.<1..n> (tools/PrepareTrailers.luau),
-- im selben Rahmen wie die Zugmaschinen-Vorlage. Jeder Anhänger wird ein eigenes physikalisches
-- Modell:
--   * "Chassis" (unsichtbar, trägt die Masse), Optik masselos daran verschweißt
--   * je Rad ein Reifen (Zylinder) an einem frei drehenden Scharnier, Radoptik am Reifen
--   * Kupplung als Kugelgelenk am Königszapfen zum vorderen Fahrzeug: Knicken (Gieren) bis
--     MaxArticulation, Kippen/Nicken nur wenig (gegen Einklappen und Umkippen)
-- Die Anhänger liegen neben dem Fahrzeugmodell (nicht darin), damit A-Chassis sie nicht mit
-- verschweißt; sie tragen die Attribute VehicleId, OwnerUserId und TrailerIndex.

local ServerStorage = game:GetService("ServerStorage")

local TrailerBuilder = {}

-- Gelenkgrenzen (Grad). TODO_BALANCE: Feinabstimmung beim Fahrtest
local MAX_ARTICULATION = 75
local MAX_TILT = 12
-- Dichte des Grundkörpers und der Reifen (Roblox-Einheiten). Bewusst leicht (Felix 2026-10-20:
-- „muss nicht komplett realistisch sein, nur gut zu fahren“): schwere Auflieger drückten die
-- Zugmaschine in die Federn und schoben sie in Kurven weg.
local CHASSIS_DENSITY = 0.3
local TIRE_DENSITY = 0.5
local TIRE_FRICTION = 1.1

local function templates(defId: string): Folder?
	local vendor = ServerStorage:FindFirstChild("Vendor")
	local bodies = vendor and vendor:FindFirstChild("VehicleBodies")
	local f = bodies and bodies:FindFirstChild(`{defId}_Trailers`)
	return if f and f:IsA("Folder") then f else nil
end

function TrailerBuilder.HasTrailers(defId: string): boolean
	return templates(defId) ~= nil
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

-- Attachment an einer Weltposition: Hauptachse (X des Attachments) senkrecht nach oben,
-- Nebenachse in Fahrtrichtung. Das Kugelgelenk begrenzt damit Kippen/Nicken (Kegel um die
-- Hochachse) und das Knicken (Verdrehung um die Hochachse) getrennt.
local function upAttachment(parent: BasePart, name: string, worldPos: Vector3, forward: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Name = name
	local flat = Vector3.new(forward.X, 0, forward.Z).Unit
	-- erst einhängen, dann Weltlage setzen (sonst wird WorldCFrame als lokale Lage übernommen)
	a.Parent = parent
	a.WorldCFrame = CFrame.fromMatrix(worldPos, Vector3.yAxis, flat)
	return a
end

-- Baut alle Anhänger hinter der Zugmaschine. `cf` = dieselbe Boden-CFrame wie für die
-- Zugmaschine (Vorlagen-Pivot), `tractorRoot` = Teil der Zugmaschine für die Sattelkupplung.
function TrailerBuilder.build(defId: string, cf: CFrame, tractorRoot: BasePart, parent: Instance, namePrefix: string): { Model }
	local folder = templates(defId)
	if not folder then
		return {}
	end
	local list = folder:GetChildren()
	table.sort(list, function(a, b)
		return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
	end)
	local built: { Model } = {}
	local chassisOf: { [number]: BasePart } = { [0] = tractorRoot }
	for _, t in list do
		if not t:IsA("Model") then
			continue
		end
		local index = tonumber(t.Name) or (#built + 1)
		local origin = t:GetPivot()
		local model = Instance.new("Model")
		model.Name = `{namePrefix}_Trailer{index}`
		model:SetAttribute("TrailerIndex", index)
		local function place(inst: Instance): Instance
			local c = inst:Clone()
			local parts: { BasePart } = {}
			if c:IsA("BasePart") then
				table.insert(parts, c)
			end
			for _, d in c:GetDescendants() do
				if d:IsA("BasePart") then
					table.insert(parts, d)
				end
			end
			for _, p in parts do
				p.CFrame = cf * origin:ToObjectSpace(p.CFrame)
				-- verankert bis zum Ankoppeln (TrailerBuilder.release)
				p.Anchored = true
			end
			c.Parent = model
			return c
		end
		local chassis = place(t:FindFirstChild("Chassis") :: BasePart) :: BasePart
		chassis.CustomPhysicalProperties = PhysicalProperties.new(CHASSIS_DENSITY, 0.3, 0.2)
		model.PrimaryPart = chassis
		-- Optik
		local body = t:FindFirstChild("Body")
		if body then
			local b = place(body)
			for _, d in b:GetDescendants() do
				if d:IsA("BasePart") then
					d.Massless = true
					d.CanCollide = false
					weld(chassis, d)
				end
			end
		end
		local fill = t:FindFirstChild("CargoFill")
		if fill then
			local f = place(fill) :: BasePart
			f.Massless = true
			f.Transparency = 1
			weld(chassis, f)
		end
		-- Räder: Reifen am freien Scharnier, Optik am Reifen
		local count = t:GetAttribute("TireCount")
		for i = 1, (if typeof(count) == "number" then count else 0) do
			local tireT = t:FindFirstChild(`Tire{i}`)
			if not (tireT and tireT:IsA("BasePart")) then
				continue
			end
			local tire = place(tireT) :: BasePart
			tire.Transparency = 1
			tire.CanCollide = true
			tire.CustomPhysicalProperties = PhysicalProperties.new(TIRE_DENSITY, TIRE_FRICTION, 0.1, 1, 1)
			-- Zylinderachse (lokal X) quer zur Fahrtrichtung
			local a0 = Instance.new("Attachment")
			a0.Name = `Axle{i}`
			a0.Parent = chassis
			a0.WorldCFrame = tire.CFrame
			local a1 = Instance.new("Attachment")
			a1.Name = "Axle"
			a1.Parent = tire
			a1.WorldCFrame = tire.CFrame
			local hinge = Instance.new("HingeConstraint")
			hinge.Attachment0 = a0
			hinge.Attachment1 = a1
			hinge.Parent = tire
			local visual = t:FindFirstChild(`Wheel{i}`)
			if visual then
				local v = place(visual)
				for _, d in v:GetDescendants() do
					if d:IsA("BasePart") then
						d.Massless = true
						d.CanCollide = false
						weld(tire, d)
					end
				end
			end
		end
		-- Kupplung zum vorderen Fahrzeug
		local king = t:FindFirstChild("Kingpin")
		local coupleTo = king and king:GetAttribute("CoupleTo")
		local front = if typeof(coupleTo) == "number" then chassisOf[coupleTo] else nil
		if king and king:IsA("BasePart") and front then
			local pos = (cf * origin:ToObjectSpace(king.CFrame)).Position
			local a0 = upAttachment(front, `Hitch{index}`, pos, cf.LookVector)
			local a1 = upAttachment(chassis, "Kingpin", pos, cf.LookVector)
			local joint = Instance.new("BallSocketConstraint")
			joint.Name = "Coupling"
			joint.Attachment0 = a0
			joint.Attachment1 = a1
			joint.LimitsEnabled = true
			joint.UpperAngle = MAX_TILT
			joint.TwistLimitsEnabled = true
			joint.TwistLowerAngle = -MAX_ARTICULATION
			joint.TwistUpperAngle = MAX_ARTICULATION
			joint.Parent = chassis
		end
		chassisOf[index] = chassis
		model.Parent = parent
		table.insert(built, model)
	end
	return built
end

-- Anhänger mit der Zugmaschine mitführen und freigeben. Die Zugmaschine (A-Chassis) richtet sich
-- beim Start noch aus; deshalb werden die Anhänger um dieselbe Verschiebung nachgezogen, die der
-- Kupplungspunkt seit dem Bau gemacht hat, und erst dann losgelassen.
function TrailerBuilder.release(trailers: { Model }, hitchRoot: BasePart, hitchAtBuild: CFrame)
	local delta = hitchRoot.CFrame * hitchAtBuild:Inverse()
	for _, m in trailers do
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.CFrame = delta * d.CFrame
			end
		end
	end
	for _, m in trailers do
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = false
			end
		end
	end
end

-- Netzwerkbesitz aller Anhänger an den Fahrer (sonst ruckelt der Zug)
function TrailerBuilder.setOwner(trailers: { Model }, player: Player?)
	for _, m in trailers do
		for _, d in m:GetDescendants() do
			if d:IsA("BasePart") and not d.Anchored and d:CanSetNetworkOwnership() then
				pcall(function()
					d:SetNetworkOwner(player)
				end)
			end
		end
	end
end

return table.freeze(TrailerBuilder)
