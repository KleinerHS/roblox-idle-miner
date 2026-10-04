--!strict
-- Worker-Rollen (docs/05 §3, §8–9). Werte kommen aus BalanceConfig.Workers.
-- Pro Mine: 2 Mining-Slots + 2 Transport-Slots, also max. 4 Worker.

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
	Order = { "Mining", "Transport" } :: { "Mining" | "Transport" },
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
