--!strict
-- Firmeneinrichtung (docs/04 §6–9, docs/12 §9): Name, Logo, Farbe nach dem Bau des Büros.
-- Der Firmenname läuft immer durch den Roblox-Textfilter, bevor er gespeichert und anderen
-- Spielern angezeigt wird (docs/09 §68). Spätere Änderung gegen Robux folgt mit D-013.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CompanyIdentity = require(Shared.Definitions.CompanyIdentity)
local Result = require(Shared.Util.Result)
local Log = require(Shared.Util.Log)

local Validate = require(script.Parent.Parent.Util.Validate)
local DataService = require(script.Parent.DataService)
local BuildingService = require(script.Parent.BuildingService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "CompanyService"

local CompanyService = {}

-- Spieler, deren Anfrage gerade gefiltert wird (Filter yieldet → Doppelanfragen blocken).
local pending: { [Player]: boolean } = {}

-- Leerzeichen normalisieren, Steuerzeichen ablehnen.
local function normalizeName(raw: string): string?
	if raw:find("[%c]") then
		return nil
	end
	local name = raw:gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+", " ")
	return name
end

local function filterName(player: Player, name: string): (boolean, string?)
	local ok, result = pcall(function()
		local filtered = TextService:FilterStringAsync(name, player.UserId, Enum.TextFilterContext.PublicChat)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)
	if not ok then
		Log.warn(TAG, `Textfilter fehlgeschlagen für {player.Name}: {result}`)
		return false, nil
	end
	return true, result :: string
end

local function submit(player: Player, rawName: unknown, logoId: unknown, colorId: unknown)
	if not Validate.string(rawName, 1, 64) then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	if not Validate.idIn(logoId, CompanyIdentity.LogoById) or not Validate.idIn(colorId, CompanyIdentity.ColorById) then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end

	local data = DataService.Get(player)
	if not data then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	if data.Company.Created then
		return Result.err(Result.Codes.ALREADY_DONE)
	end
	if not data.Buildings.build_office then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end

	local name = normalizeName(rawName :: string)
	if not name or not Validate.string(name, CompanyIdentity.NameMinLength, CompanyIdentity.NameMaxLength) then
		return Result.err(Result.Codes.NAME_INVALID)
	end

	if pending[player] then
		return Result.err(Result.Codes.RATE_LIMITED)
	end
	pending[player] = true
	local filterOk, filtered = filterName(player, name)
	pending[player] = nil

	if not filterOk or not filtered then
		return Result.err(Result.Codes.FILTER_FAILED)
	end
	-- Hat der Filter etwas ersetzt (####), wird der Name abgelehnt statt verstümmelt gespeichert.
	if filtered ~= name then
		return Result.err(Result.Codes.NAME_FILTERED)
	end

	-- Nach dem Yield erneut prüfen (Spieler weg oder parallel schon eingerichtet).
	local applied = DataService.Mutate(player, function(d)
		if d.Company.Created then
			return
		end
		d.Company.Created = true
		d.Company.Name = filtered
		d.Company.LogoId = logoId :: string
		d.Company.ColorId = colorId :: string
	end)
	local current = DataService.Get(player)
	if not applied or not current or current.Company.Name ~= filtered then
		return Result.err(Result.Codes.ALREADY_DONE)
	end

	Log.debug(TAG, `{player.Name} gründet "{filtered}" ({logoId}, {colorId})`)
	BuildingService.Refresh(player)
	DataService.RequestSave(player)
	RemoteService.FireClient("Notify", player, { Kind = "Success", Code = "COMPANY_FOUNDED", Args = { Name = filtered } })
	return Result.ok(filtered)
end

function CompanyService.Init()
	RemoteService.OnInvoke("SubmitCompanySetup", submit)
	Players.PlayerRemoving:Connect(function(player)
		pending[player] = nil
	end)
end

function CompanyService.Start() end

return CompanyService
