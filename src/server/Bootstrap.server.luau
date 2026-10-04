--!strict
-- Server-Einstiegspunkt. Lädt alle Services in fester Reihenfolge:
-- erst Init() für alle (Remotes registrieren, nichts starten), dann Start() für alle.
-- Neue Services hier in SERVICE_ORDER eintragen (Abhängigkeiten zuerst).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Version = require(Shared.Version)
local Log = require(Shared.Util.Log)

local Services = script.Parent:WaitForChild("Services")

type Service = {
	Init: (() -> ())?,
	Start: (() -> ())?,
}

local SERVICE_ORDER = {
	"RemoteService",
	"DataService",
	"PlotService",
	"BuildingService",
	"ElevatorService",
	"MiningService",
	"SellingService",
	"ShopService",
	"CompanyService",
	"DevService",
}

local started = os.clock()
local loaded: { { name: string, service: Service } } = {}

for _, name in SERVICE_ORDER do
	local module = Services:FindFirstChild(name)
	assert(module and module:IsA("ModuleScript"), `Service {name} fehlt`)
	local service = (require :: any)(module) :: Service
	table.insert(loaded, { name = name, service = service })
end

for _, entry in loaded do
	if entry.service.Init then
		entry.service.Init()
	end
end

for _, entry in loaded do
	if entry.service.Start then
		entry.service.Start()
	end
end

Log.info(
	"Bootstrap",
	`{Version.Game} v{Version.Version} ({Version.Phase}) gestartet – {#loaded} Services in {string.format("%.0f", (os.clock() - started) * 1000)} ms`
)
