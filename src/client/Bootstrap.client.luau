--!strict
-- Client-Einstiegspunkt. Lädt alle Controller in fester Reihenfolge:
-- erst Init() (Remote-Handler verbinden), dann Start().
-- Neue Controller hier in CONTROLLER_ORDER eintragen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Version = require(Shared.Version)
local Log = require(Shared.Util.Log)

local Controllers = script.Parent:WaitForChild("Controllers")

type Controller = {
	Init: (() -> ())?,
	Start: (() -> ())?,
}

local CONTROLLER_ORDER = {
	"StateController",
	"PlotController",
	"NotificationController",
	"CompanySetupController",
	"ElevatorController",
	"MiningController",
	"BackpackHudController",
	"HudController",
	"SellController",
	"ShopController",
	"StorageController",
	"LaptopController",
}

local loaded: { Controller } = {}

for _, name in CONTROLLER_ORDER do
	local module = Controllers:WaitForChild(name)
	assert(module:IsA("ModuleScript"), `Controller {name} fehlt`)
	table.insert(loaded, (require :: any)(module) :: Controller)
end

for _, controller in loaded do
	if controller.Init then
		controller.Init()
	end
end

for _, controller in loaded do
	if controller.Start then
		task.spawn(controller.Start)
	end
end

Log.info("Bootstrap", `{Version.Game} v{Version.Version} ({Version.Phase}) gestartet – {#loaded} Controller`)
