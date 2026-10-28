--!strict
-- Sichtbarer Rucksack auf dem Rücken (D-074, Felix 2026-10-28). REINE DARSTELLUNG: Kapazität
-- rechnet weiter StorageService/MiningService. Der ausgerüstete Rucksack wird aus der Vorlage
-- (BackpackModels) geklont und starr an UpperTorso.BodyBackAttachment geschweißt (wie Felix'
-- Mount_Backpack.luau), 0,03 Studs vom Rücken weg. Für alle Spieler sichtbar.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Backpacks = require(ReplicatedStorage:WaitForChild("Shared").Definitions.Backpacks)

local BackpackModels = require(script.Parent.Parent.World.BackpackModels)
local DataService = require(script.Parent.DataService)

local BackpackVisualService = {}

local MODEL_NAME = "WornBackpack"
local OFFSET = 0.03

local function mount(player: Player)
	local data = DataService.Get(player)
	local character = player.Character
	if not data or not character then
		return
	end
	local def = Backpacks.Get(data.Equipment.EquippedBackpack)
	local old = character:FindFirstChild(MODEL_NAME)
	if old and def and old:GetAttribute("BackpackId") == def.Id then
		return
	end
	if old then
		old:Destroy()
	end
	if not def then
		return
	end
	local torso = character:FindFirstChild("UpperTorso")
	local back = torso and torso:FindFirstChild("BodyBackAttachment")
	if not (torso and torso:IsA("BasePart") and back and back:IsA("Attachment")) then
		return -- nur R15
	end
	local m = BackpackModels.clone(def)
	if not m then
		return
	end
	m.Name = MODEL_NAME
	m:SetAttribute("BackpackId", def.Id)
	m:PivotTo(back.WorldCFrame * CFrame.new(0, 0, OFFSET))
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = false
			d.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = torso
			weld.Part1 = d
			weld.Parent = d
		end
	end
	m.Parent = character
end

function BackpackVisualService.Refresh(player: Player)
	mount(player)
end

function BackpackVisualService.Start()
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			-- Körperteile und Attachments müssen stehen
			local torso = character:WaitForChild("UpperTorso", 10)
			if torso then
				torso:WaitForChild("BodyBackAttachment", 10)
				task.defer(mount, player)
			end
		end)
		if player.Character then
			task.spawn(mount, player)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	DataService.ProfileLoaded:Connect(function(player)
		mount(player)
	end)
end

return BackpackVisualService
