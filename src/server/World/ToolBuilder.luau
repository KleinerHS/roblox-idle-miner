--!strict
-- Baut die Spitzhacke als Roblox-Tool (PLATZHALTER aus Parts, docs/19 §18).
-- Das Tool enthält keine Scripts: Eingabe und Animation macht MiningController (Client),
-- Ergebnis und Prüfung MiningService (Server).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Pickaxes = require(ReplicatedStorage:WaitForChild("Shared").Definitions.Pickaxes)

local ToolBuilder = {}

ToolBuilder.PickaxeToolName = "Pickaxe"

local WOOD = Color3.fromRGB(120, 84, 52)
local GRIP = Color3.fromRGB(40, 36, 32)

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

function ToolBuilder.buildPickaxe(def: Pickaxes.PickaxeDefinition): Tool
	local tool = Instance.new("Tool")
	tool.Name = ToolBuilder.PickaxeToolName
	tool.ToolTip = def.DisplayName
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("PickaxeId", def.Id)
	-- Stiel zeigt nach vorne/oben, Kopf vorne (wie eine geschulterte Hacke)
	tool.Grip = CFrame.new(0, -1.3, 0) * CFrame.Angles(math.rad(90), 0, 0)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 4, 0.35)
	handle.Color = WOOD
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local wrap = Instance.new("Part")
	wrap.Name = "GripWrap"
	wrap.Size = Vector3.new(0.42, 1.1, 0.42)
	wrap.Color = GRIP
	wrap.Material = Enum.Material.Fabric
	wrap.CanCollide = false
	wrap.Massless = true
	wrap.CFrame = handle.CFrame * CFrame.new(0, -1.2, 0)
	wrap.Parent = tool
	weld(handle, wrap)

	-- Doppelspitze aus zwei leicht gebogenen Hälften
	local headCF = handle.CFrame * CFrame.new(0, 1.85, 0)
	local socket = Instance.new("Part")
	socket.Name = "HeadSocket"
	socket.Size = Vector3.new(0.6, 0.6, 0.6)
	socket.Color = def.HeadColor
	socket.Material = Enum.Material.Metal
	socket.CanCollide = false
	socket.Massless = true
	socket.CFrame = headCF
	socket.Parent = tool
	weld(handle, socket)
	for _, side in { 1, -1 } do
		local blade = Instance.new("Part")
		blade.Name = if side > 0 then "BladeFront" else "BladeBack"
		blade.Size = Vector3.new(0.3, 0.38, 1.7)
		blade.Color = def.HeadColor
		blade.Material = Enum.Material.Metal
		blade.CanCollide = false
		blade.Massless = true
		blade.CFrame = headCF * CFrame.new(0, -0.15, side * 1.05) * CFrame.Angles(math.rad(side * 14), 0, 0)
		blade.Parent = tool
		weld(handle, blade)
	end

	return tool
end

return table.freeze(ToolBuilder)
