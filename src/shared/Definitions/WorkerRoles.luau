--!strict
-- Worker-Rollen (docs/05 §3, §8–9). Werte kommen aus BalanceConfig.Workers.
-- Pro Mine: 2 Mining-Slots (Worker oder Drill). Transport-Worker gibt es seit D-041 nicht mehr
-- (Erz geht direkt in den Elevator); die Rolle bleibt nur für die Migration alter Profile definiert.

local BalanceConfig = require(script.Parent.Parent.Config.BalanceConfig)

export type RoleDefinition = {
	Id: "Mining" | "Transport",
	DisplayName: string,
	Slots: number,
	HireCost: number,
	WagePerMinute: number,
}

local WorkerRoles = {
	SlotsPerRole = 2,
	-- einstellbare Rollen (Laptop, WorkerService)
	Order = { "Mining" } :: { "Mining" | "Transport" },
	ById = table.freeze({
		Mining = table.freeze({
			Id = "Mining",
			DisplayName = "Mining Worker",
			Slots = 2,
			HireCost = BalanceConfig.Workers.Mining.HireCost,
			WagePerMinute = BalanceConfig.Workers.Mining.WagePerMinute,
		}),
		Transport = table.freeze({
			Id = "Transport",
			DisplayName = "Transport Worker",
			Slots = 2,
			HireCost = BalanceConfig.Workers.Transport.HireCost,
			WagePerMinute = BalanceConfig.Workers.Transport.WagePerMinute,
		}),
	}) :: { [string]: RoleDefinition },
}

function WorkerRoles.Get(id: string): RoleDefinition?
	return WorkerRoles.ById[id]
end

return table.freeze(WorkerRoles)
