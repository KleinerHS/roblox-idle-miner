--!strict
-- Hochregal-Blöcke mit Palettenboxen (Phase 13b, Felix D-037): gemeinsam genutzt vom Firmenlager
-- und den beiden Ofen-Lagern. Ein Regal hat 4 Paletten übereinander; jeder Platz ist eine Kiste
-- (CrateSize einer Sorte). Gekaufte/vorhandene Kisten stehen als Gitterboxen im Regal, das Erz
-- ist in Farbe und Füllhöhe sichtbar; nicht vorhandene Plätze bleiben leer.
--
-- build(parent, origin, rows, racksPerRow) → Folder "Racks" + Folder "Crates" (Slot1..SlotN)
--   origin: Mitte des Blocks auf Bodenhöhe, rows: { { Z = lokal, Face = -1 | 1 } } (Face = Seite
--   zum Fahrweg), Reihenfolge der Plätze = Reihenfolge der rows, je Reihe links → rechts, unten → oben.
-- update(cratesFolder, items, owned) → Kisten anzeigen (Sorten nach Stufe, je Sorte ceil(n/Size))

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BalanceConfig = require(Shared.Config.BalanceConfig)
local Materials = require(Shared.Definitions.Materials)

local CrateRackBuilder = {}

local RACK_BAY = 9 -- Breite eines Regals (X)
local RACK_DEPTH = 8.5 -- Tiefe (Z)
local LEVEL_Y = { 0, 7.8, 15.6, 23.4 } -- Unterkante der Palette je Ebene
local RACK_HEIGHT = 31
local BOX = 7.4 -- Gitterbox-Grundfläche
local BOX_H = 5.6 -- Wandhöhe der Gitterbox
local BOX_FRONT_H = 2 -- niedrige Klappe zum Fahrweg, damit das Erz sichtbar ist

CrateRackBuilder.Bay = RACK_BAY
CrateRackBuilder.Depth = RACK_DEPTH
CrateRackBuilder.Levels = #LEVEL_Y

local UPRIGHT = Color3.fromRGB(40, 90, 150)
local BEAM = Color3.fromRGB(226, 150, 40)
local YELLOW = Color3.fromRGB(236, 182, 40)
local PALLET = Color3.fromRGB(140, 100, 58)
local STEEL = Color3.fromRGB(70, 74, 80)
local MESH = Color3.fromRGB(150, 156, 164)

local function part(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanTouch = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

export type Row = { Z: number, Face: number }

function CrateRackBuilder.build(parent: Instance, origin: CFrame, rows: { Row }, racksPerRow: number): (Folder, Folder)
	local o = origin
	local racks = Instance.new("Folder")
	racks.Name = "Racks"
	racks.Parent = parent
	local length = racksPerRow * RACK_BAY
	for r, row in rows do
		local z = row.Z
		for k = 0, racksPerRow do
			local x = length / 2 - k * RACK_BAY
			for _, dz in { -RACK_DEPTH / 2, RACK_DEPTH / 2 } do
				part(racks, `Upright{r}_{k}_{dz}`, Vector3.new(0.5, RACK_HEIGHT, 0.5), o * CFrame.new(x, RACK_HEIGHT / 2, z + dz), UPRIGHT, Enum.Material.Metal)
			end
			for level = 1, #LEVEL_Y - 1 do
				local y0, y1 = LEVEL_Y[level] + 1, LEVEL_Y[level + 1] + 1
				local h = y1 - y0
				local len = math.sqrt(h * h + RACK_DEPTH * RACK_DEPTH)
				part(racks, `Brace{r}_{k}_{level}`, Vector3.new(0.2, 0.2, len), o * CFrame.new(x, (y0 + y1) / 2, z) * CFrame.Angles(math.atan2(h, RACK_DEPTH) * (if level % 2 == 0 then 1 else -1), 0, 0), UPRIGHT, Enum.Material.Metal)
			end
		end
		for level = 2, #LEVEL_Y do
			for _, dz in { -RACK_DEPTH / 2, RACK_DEPTH / 2 } do
				part(racks, `Beam{r}_{level}_{dz}`, Vector3.new(length + 0.5, 0.45, 0.3), o * CFrame.new(0, LEVEL_Y[level] - 0.25, z + dz), BEAM, Enum.Material.Metal)
			end
		end
		for _, dz in { -RACK_DEPTH / 2, RACK_DEPTH / 2 } do
			part(racks, `TopBeam{r}_{dz}`, Vector3.new(length + 0.5, 0.45, 0.3), o * CFrame.new(0, RACK_HEIGHT - 0.3, z + dz), BEAM, Enum.Material.Metal)
		end
		for _, sx in { -1, 1 } do
			part(racks, `Guard{r}_{sx}`, Vector3.new(0.6, 1.2, RACK_DEPTH + 1), o * CFrame.new(sx * (length / 2 + 0.6), 0.6, z), YELLOW, Enum.Material.SmoothPlastic)
		end
	end

	local crates = Instance.new("Folder")
	crates.Name = "Crates"
	crates.Parent = parent
	local index = 0
	for _, row in rows do
		for rack = 0, racksPerRow - 1 do
			for level = 1, #LEVEL_Y do
				index += 1
				local x = (racksPerRow / 2 - rack - 0.5) * RACK_BAY
				local base = o * CFrame.new(x, LEVEL_Y[level], row.Z)
				local slot = Instance.new("Model")
				slot.Name = `Slot{index}`
				part(slot, "Pallet", Vector3.new(BOX + 0.2, 0.5, BOX + 0.2), base * CFrame.new(0, 0.25, 0), PALLET, Enum.Material.WoodPlanks)
				part(slot, "Floor", Vector3.new(BOX, 0.2, BOX), base * CFrame.new(0, 0.6, 0), STEEL, Enum.Material.Metal)
				for _, side in { -1, 1 } do
					part(slot, `WallX{side}`, Vector3.new(0.15, BOX_H, BOX), base * CFrame.new(side * (BOX / 2 - 0.075), 0.7 + BOX_H / 2, 0), MESH, Enum.Material.DiamondPlate)
					local h = if side == row.Face then BOX_FRONT_H else BOX_H
					part(slot, `WallZ{side}`, Vector3.new(BOX - 0.3, h, 0.15), base * CFrame.new(0, 0.7 + h / 2, side * (BOX / 2 - 0.075)), MESH, Enum.Material.DiamondPlate)
				end
				local fill = part(slot, "Fill", Vector3.new(BOX - 0.4, 0.2, BOX - 0.4), base * CFrame.new(0, 0.8, 0), Color3.new(0.2, 0.2, 0.2), Enum.Material.Slate)
				fill.CanCollide = false
				slot.Parent = crates
			end
		end
	end
	return racks, crates
end

function CrateRackBuilder.update(crates: Instance, items: { [string]: number }, owned: number)
	local size = BalanceConfig.Storage.CrateSize
	local ids = {}
	for id, n in items do
		if n > 0 then
			table.insert(ids, id)
		end
	end
	Materials.SortIds(ids)
	local plan: { { color: Color3, fraction: number } } = {}
	for _, id in ids do
		local mat = Materials.Get(id)
		local n = items[id]
		while n > 0 do
			table.insert(plan, { color = if mat then mat.Color else Color3.new(0.3, 0.3, 0.3), fraction = math.min(n, size) / size })
			n -= size
		end
	end
	for _, slot in crates:GetChildren() do
		local index = tonumber(slot.Name:match("%d+")) or 0
		local present = index <= owned
		local entry = if present then plan[index] else nil
		local pallet = slot:FindFirstChild("Pallet")
		for _, p in slot:GetChildren() do
			if p:IsA("BasePart") then
				if p.Name == "Fill" then
					p.Transparency = if entry then 0 else 1
					if entry and pallet and pallet:IsA("BasePart") then
						local h = math.max(0.2, (BOX_H - 0.3) * entry.fraction)
						p.Size = Vector3.new(BOX - 0.4, h, BOX - 0.4)
						p.CFrame = pallet.CFrame * CFrame.new(0, -0.25 + 0.7 + h / 2, 0)
						p.Color = entry.color
					end
				else
					p.Transparency = if present then 0 else 1
					p.CanCollide = present
				end
			end
		end
	end
end

return table.freeze(CrateRackBuilder)
