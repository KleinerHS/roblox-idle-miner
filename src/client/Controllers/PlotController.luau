--!strict
-- Kennt den eigenen Plot (PlotId) und das zugehörige Workspace-Modell.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Signal = require(Shared.Util.Signal)
local Log = require(Shared.Util.Log)

local Net = require(script.Parent.Parent.Net)

local TAG = "PlotController"

local PlotController = {
	Assigned = Signal.new() :: Signal.Signal<number>,
}

local plotId: number? = nil

local function apply(id: number)
	if plotId == id then
		return
	end
	plotId = id
	Log.debug(TAG, `Eigener Plot: {id}`)
	PlotController.Assigned:Fire(id)
end

function PlotController.Init()
	Net.on("PlotAssigned", function(id: number)
		apply(id)
	end)
end

function PlotController.Start()
	if plotId == nil then
		local result = Net.invoke("GetMyPlot")
		if result.success then
			apply(result.value)
		end
	end
end

function PlotController.GetPlotId(): number?
	return plotId
end

-- Plot-Modell im Workspace. Kann wegen StreamingEnabled kurz nil sein.
function PlotController.GetPlotModel(): Model?
	if not plotId then
		return nil
	end
	local folder = workspace:FindFirstChild("Plots")
	local model = folder and folder:FindFirstChild(`Plot_{plotId}`)
	return if model and model:IsA("Model") then model else nil
end

return PlotController
