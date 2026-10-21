--!strict
-- Verkaufsrückmeldung (D-056): Der Server verkauft automatisch im grünen Verkaufskreis und
-- meldet { Cash, XP }; hier wird nur "SOLD +$X +Y Mining XP" angezeigt (docs/09 §49).

local Net = require(script.Parent.Parent.Net)
local HudController = require(script.Parent.HudController)

local SellController = {}

function SellController.Init()
	Net.on("Sold", function(payload: any)
		if typeof(payload) == "table" and typeof(payload.Cash) == "number" and typeof(payload.XP) == "number" then
			HudController.ShowSold(payload.Cash, payload.XP)
		end
	end)
end

function SellController.Start() end

return SellController
