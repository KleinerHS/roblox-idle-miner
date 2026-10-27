--!strict
-- Zugriff auf die 3D-Vorlagen aus Felix' Pickaxe-Pack (D-071) in ServerStorage.Vendor.Pickaxes.
-- Jede Vorlage ist ein Model aus verankerten MeshParts, Pivot = Mitte der Unterkante, Kopf oben (+Y).
-- Fehlt eine Vorlage (z. B. Place ohne Vendor-Ordner), geben die Funktionen nil zurück und der
-- Aufrufer baut den alten Platzhalter aus Parts.

local ServerStorage = game:GetService("ServerStorage")

local Pickaxes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").Definitions.Pickaxes)

local PickaxeModels = {}

local function folder(): Instance?
	local vendor = ServerStorage:FindFirstChild("Vendor")
	return vendor and vendor:FindFirstChild("Pickaxes")
end

-- Kopie der Vorlage, verankert, ohne Kollision. Pivot unverändert (Unterkante Mitte).
function PickaxeModels.clone(def: Pickaxes.PickaxeDefinition): Model?
	local f = folder()
	local template = f and f:FindFirstChild(def.Model or def.Id)
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
	return m
end

-- Höhe der Vorlage (Bounding Box entlang Y)
function PickaxeModels.height(m: Model): number
	local _, size = m:GetBoundingBox()
	return size.Y
end

-- Kopie auf eine Zielhöhe skaliert und mit der Unterkante an cf gesetzt
function PickaxeModels.place(def: Pickaxes.PickaxeDefinition, parent: Instance, cf: CFrame, height: number): Model?
	local m = PickaxeModels.clone(def)
	if not m then
		return nil
	end
	local h = PickaxeModels.height(m)
	if h > 0 then
		m:ScaleTo(m:GetScale() * height / h)
	end
	m:PivotTo(cf)
	m.Parent = parent
	return m
end

return table.freeze(PickaxeModels)
