--!strict
-- Direkter Handel zwischen Spielern (docs/13 §5–12, §19–21). Handelbar: Materialien aus dem
-- Firmenlager (Erze, Barren) und unplatzierte Drills. Ablauf:
--   Anfrage (Prompt "Trade" am anderen Spieler) → Annahme → Fenster → beide stellen Angebote
--   → beide sperren (LOCK) → kurze Bestätigungsphase → beide bestätigen → atomarer Tausch.
-- Jede Angebotsänderung setzt Sperren und Bestätigungen beider Seiten zurück (§7).
-- Unmittelbar vor dem Tausch prüft der Server alles erneut (§8). Der Tausch ändert beide
-- Profile ohne Yield dazwischen: ganz oder gar nicht. Kein Mining XP durch Handel (§10).
-- Disconnect vor dem Tausch bricht ab (§20). Jeder Abschluss wird protokolliert (§21).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Materials = require(Shared.Definitions.Materials)
local Types = require(Shared.Types)
local Result = require(Shared.Util.Result)
local Log = require(Shared.Util.Log)

local DataService = require(script.Parent.DataService)
local RemoteService = require(script.Parent.RemoteService)

local TAG = "TradeService"
local CFG = GameConfig.Trade

local TradeService = {}

type Offer = { Materials: { [string]: number }, Drills: { [string]: boolean } }
type Session = {
	id: string,
	a: Player,
	b: Player,
	offers: { [Player]: Offer },
	locked: { [Player]: boolean },
	confirmed: { [Player]: boolean },
	lockedAt: number?,
	closed: boolean,
}

local sessions: { [Player]: Session } = {}
-- offene Anfragen: [requestId] = { from, to, expires }
local requests: { [string]: { from: Player, to: Player, expires: number } } = {}
local lastRequest: { [Player]: { [Player]: number } } = {}

local function distance(a: Player, b: Player): number
	local ra = a.Character and a.Character:FindFirstChild("HumanoidRootPart")
	local rb = b.Character and b.Character:FindFirstChild("HumanoidRootPart")
	if not (ra and rb and ra:IsA("BasePart") and rb:IsA("BasePart")) then
		return math.huge
	end
	return (ra.Position - rb.Position).Magnitude
end

local function other(session: Session, player: Player): Player
	return if session.a == player then session.b else session.a
end

-- Angebot für die Anzeige (Drill-Instanzen mit Typ)
local function offerView(owner: Player, offer: Offer): { Materials: { [string]: number }, Drills: { { Id: string, Type: string } } }
	local data = DataService.Get(owner)
	local drills = {}
	for id in offer.Drills do
		local record = data and data.Machines.Drills[id]
		table.insert(drills, { Id = id, Type = if record then record.Type else "?" })
	end
	return { Materials = table.clone(offer.Materials), Drills = drills }
end

local function push(session: Session)
	local confirmReadyAt = if session.lockedAt then session.lockedAt + CFG.ConfirmDelay else nil
	for _, me in { session.a, session.b } do
		local them = other(session, me)
		RemoteService.FireClient("TradeUpdate", me, {
			TradeId = session.id,
			PartnerName = them.DisplayName,
			Mine = offerView(me, session.offers[me]),
			Theirs = offerView(them, session.offers[them]),
			MyLocked = session.locked[me] == true,
			TheirLocked = session.locked[them] == true,
			MyConfirmed = session.confirmed[me] == true,
			TheirConfirmed = session.confirmed[them] == true,
			ConfirmIn = if confirmReadyAt then math.max(0, confirmReadyAt - os.clock()) else nil,
		})
	end
end

local function close(session: Session, reason: string)
	if session.closed then
		return
	end
	session.closed = true
	for _, p in { session.a, session.b } do
		if sessions[p] == session then
			sessions[p] = nil
		end
		if p.Parent == Players then
			RemoteService.FireClient("TradeClosed", p, { Reason = reason })
		end
	end
end

local function resetLocks(session: Session)
	session.locked = {}
	session.confirmed = {}
	session.lockedAt = nil
end

-- Prüft ein Angebot gegen den aktuellen Bestand (§8)
local function validateOffer(owner: Player, offer: Offer): string?
	local data = DataService.Get(owner)
	if not data then
		return Result.Codes.DATA_NOT_LOADED
	end
	for id, n in offer.Materials do
		if not Materials.Get(id) or n < 1 or n % 1 ~= 0 or (data.Storage.Items[id] or 0) < n then
			return Result.Codes.NOT_OWNED
		end
	end
	for id in offer.Drills do
		local record = data.Machines.Drills[id]
		if not record or record.MineId ~= nil then
			return Result.Codes.NOT_OWNED
		end
	end
	return nil
end

local function sumMaterials(m: { [string]: number }): number
	local total = 0
	for _, n in m do
		total += n
	end
	return total
end

local function storageFree(data: Types.PlayerData): number
	local used = 0
	for _, n in data.Storage.Items do
		used += n
	end
	return data.Storage.Capacity - used
end

-- Atomarer Tausch (§8, §20): alles erneut prüfen, dann beide Profile ohne Yield ändern
local function execute(session: Session): (boolean, string?)
	local a, b = session.a, session.b
	if a.Parent ~= Players or b.Parent ~= Players then
		return false, "Disconnected"
	end
	if distance(a, b) > CFG.CommitDistance then
		return false, Result.Codes.TOO_FAR
	end
	local codeA, codeB = validateOffer(a, session.offers[a]), validateOffer(b, session.offers[b])
	if codeA or codeB then
		return false, codeA or codeB
	end
	local dataA, dataB = DataService.Get(a), DataService.Get(b)
	if not (dataA and dataB) then
		return false, Result.Codes.DATA_NOT_LOADED
	end
	-- Empfänger braucht ein Lager mit Platz für die Materialien
	local toB, toA = sumMaterials(session.offers[a].Materials), sumMaterials(session.offers[b].Materials)
	if toB > 0 and (not dataB.Buildings.build_storage or storageFree(dataB) + toA < toB) then
		return false, Result.Codes.STORAGE_FULL
	end
	if toA > 0 and (not dataA.Buildings.build_storage or storageFree(dataA) + toB < toA) then
		return false, Result.Codes.STORAGE_FULL
	end

	local log = { TradeId = session.id, A = a.UserId, B = b.UserId, Time = os.time(), FromA = {}, FromB = {} }
	local function transfer(from: Player, to: Player, offer: Offer, entry: { [string]: any })
		-- Drills behalten ihren Typ, bekommen beim Empfänger eine neue, dort eindeutige Instanz-ID
		local moved: { { Type: string } } = {}
		DataService.Mutate(from, function(d)
			for id, n in offer.Materials do
				d.Storage.Items[id] -= n
				if d.Storage.Items[id] <= 0 then
					d.Storage.Items[id] = nil
				end
			end
			for id in offer.Drills do
				table.insert(moved, { Type = d.Machines.Drills[id].Type })
				table.insert(entry, `drill {id} ({d.Machines.Drills[id].Type})`)
				d.Machines.Drills[id] = nil
			end
		end)
		DataService.Mutate(to, function(d)
			for id, n in offer.Materials do
				d.Storage.Items[id] = (d.Storage.Items[id] or 0) + n
				table.insert(entry, `{id} x{n}`)
			end
			for _, m in moved do
				d.Machines.Seq += 1
				local newId = `d{d.Machines.Seq}`
				d.Machines.Drills[newId] = { Id = newId, Type = m.Type }
			end
		end)
	end
	-- Beide Richtungen direkt nacheinander, ohne Yield (Mutate ist synchron)
	transfer(a, b, session.offers[a], log.FromA)
	transfer(b, a, session.offers[b], log.FromB)
	DataService.RequestSave(a)
	DataService.RequestSave(b)
	Log.info(TAG, `Trade {log.TradeId} OK: {log.A} ↔ {log.B} | A gibt: {table.concat(log.FromA, ", ")} | B gibt: {table.concat(log.FromB, ", ")}`)
	return true, nil
end

-- Remotes ---------------------------------------------------------------

local function request(player: Player, targetUserId: unknown)
	if typeof(targetUserId) ~= "number" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local target = Players:GetPlayerByUserId(targetUserId :: number)
	if not target or target == player then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	if sessions[player] or sessions[target] then
		return Result.err(Result.Codes.TRADE_BUSY)
	end
	local targetData = DataService.Get(target)
	if not targetData or not DataService.Get(player) then
		return Result.err(Result.Codes.DATA_NOT_LOADED)
	end
	if not targetData.Settings.TradeRequests then
		return Result.err(Result.Codes.TRADE_DISABLED)
	end
	if distance(player, target) > CFG.RequestDistance then
		return Result.err(Result.Codes.TOO_FAR)
	end
	local now = os.clock()
	local last = lastRequest[player] and lastRequest[player][target]
	if last and now - last < CFG.RequestCooldown then
		return Result.err(Result.Codes.COOLDOWN)
	end
	lastRequest[player] = lastRequest[player] or {}
	lastRequest[player][target] = now
	local id = HttpService:GenerateGUID(false)
	requests[id] = { from = player, to = target, expires = now + CFG.RequestTimeout }
	RemoteService.FireClient("TradeRequestReceived", target, { RequestId = id, FromName = player.DisplayName, Timeout = CFG.RequestTimeout })
	return Result.ok(id)
end

local function respond(player: Player, requestId: unknown, accept: unknown)
	if typeof(requestId) ~= "string" or typeof(accept) ~= "boolean" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local req = requests[requestId :: string]
	if not req or req.to ~= player then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	requests[requestId :: string] = nil
	if os.clock() > req.expires or req.from.Parent ~= Players then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	if not accept then
		RemoteService.FireClient("Notify", req.from, { Kind = "Info", Code = "TRADE_DECLINED", Args = { Name = player.DisplayName } })
		return Result.ok(false)
	end
	if sessions[player] or sessions[req.from] then
		return Result.err(Result.Codes.TRADE_BUSY)
	end
	local session: Session = {
		id = HttpService:GenerateGUID(false),
		a = req.from,
		b = player,
		offers = { [req.from] = { Materials = {}, Drills = {} }, [player] = { Materials = {}, Drills = {} } },
		locked = {},
		confirmed = {},
		lockedAt = nil,
		closed = false,
	}
	sessions[req.from] = session
	sessions[player] = session
	push(session)
	return Result.ok(true)
end

-- Komplettes eigenes Angebot setzen: (materials: {[id]=n}, drillIds: {string})
local function setOffer(player: Player, materials: unknown, drillIds: unknown)
	local session = sessions[player]
	if not session then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	if typeof(materials) ~= "table" or typeof(drillIds) ~= "table" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local offer: Offer = { Materials = {}, Drills = {} }
	local count = 0
	for id, n in materials :: { [any]: any } do
		count += 1
		if count > 40 or typeof(id) ~= "string" or typeof(n) ~= "number" or n ~= n or n < 1 or n % 1 ~= 0 or n > 1e9 then
			return Result.err(Result.Codes.INVALID_ARGUMENT)
		end
		offer.Materials[id] = n
	end
	for _, id in drillIds :: { any } do
		count += 1
		if count > 60 or typeof(id) ~= "string" then
			return Result.err(Result.Codes.INVALID_ARGUMENT)
		end
		offer.Drills[id] = true
	end
	local code = validateOffer(player, offer)
	if code then
		return Result.err(code)
	end
	session.offers[player] = offer
	resetLocks(session) -- jede Änderung setzt Bestätigungen zurück (§7)
	push(session)
	return Result.ok(true)
end

local function setLocked(player: Player, locked: unknown)
	local session = sessions[player]
	if not session or typeof(locked) ~= "boolean" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	if locked then
		session.locked[player] = true
		if session.locked[session.a] and session.locked[session.b] then
			session.lockedAt = os.clock()
		end
	else
		resetLocks(session)
	end
	push(session)
	return Result.ok(true)
end

local function confirm(player: Player)
	local session = sessions[player]
	if not session then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	if not (session.lockedAt and session.locked[session.a] and session.locked[session.b]) then
		return Result.err(Result.Codes.NOT_AVAILABLE)
	end
	if os.clock() < session.lockedAt + CFG.ConfirmDelay then
		return Result.err(Result.Codes.COOLDOWN)
	end
	session.confirmed[player] = true
	if session.confirmed[session.a] and session.confirmed[session.b] then
		local ok, code = execute(session)
		if ok then
			close(session, "Completed")
		else
			Log.info(TAG, `Trade {session.id} abgelehnt: {code}`)
			resetLocks(session)
			push(session)
			for _, p in { session.a, session.b } do
				if p.Parent == Players then
					RemoteService.FireClient("Notify", p, { Kind = "Warning", Code = code or Result.Codes.INTERNAL_ERROR })
				end
			end
			if code == "Disconnected" then
				close(session, "Cancelled")
			end
		end
		return Result.ok(ok)
	end
	push(session)
	return Result.ok(false)
end

local function cancel(player: Player)
	local session = sessions[player]
	if session then
		close(session, "Cancelled")
	end
	return Result.ok(true)
end

local function setTradeRequests(player: Player, enabled: unknown)
	if typeof(enabled) ~= "boolean" then
		return Result.err(Result.Codes.INVALID_ARGUMENT)
	end
	local ok = DataService.Mutate(player, function(d)
		d.Settings.TradeRequests = enabled :: boolean
	end)
	return if ok then Result.ok(enabled) else Result.err(Result.Codes.DATA_NOT_LOADED)
end

-- Prompt "Trade" am Charakter jedes Spielers (der eigene wird clientseitig ausgeblendet)
local function addPrompt(player: Player, character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TradePrompt"
	prompt.ActionText = "Trade"
	prompt.ObjectText = player.DisplayName
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.T
	prompt:SetAttribute("TradeUserId", player.UserId)
	prompt.Parent = root
end

function TradeService.Init()
	RemoteService.OnInvoke("TradeRequest", request)
	RemoteService.OnInvoke("TradeRespond", respond)
	RemoteService.OnInvoke("TradeSetOffer", setOffer)
	RemoteService.OnInvoke("TradeLock", setLocked)
	RemoteService.OnInvoke("TradeConfirm", confirm)
	RemoteService.OnInvoke("TradeCancel", cancel)
	RemoteService.OnInvoke("SetTradeRequests", setTradeRequests)
end

function TradeService.Start()
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			addPrompt(player, character)
		end)
		if player.Character then
			task.spawn(addPrompt, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		local targetId = prompt:GetAttribute("TradeUserId")
		if typeof(targetId) ~= "number" or targetId == player.UserId then
			return
		end
		local result = request(player, targetId)
		if result.success then
			RemoteService.FireClient("Notify", player, { Kind = "Info", Code = "TRADE_SENT" })
		else
			RemoteService.FireClient("Notify", player, { Kind = "Warning", Code = result.code })
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local session = sessions[player]
		if session then
			close(session, "Cancelled") -- Disconnect vor Commit: nichts wird übertragen (§20)
		end
		lastRequest[player] = nil
		for id, req in requests do
			if req.from == player or req.to == player then
				requests[id] = nil
			end
		end
	end)
	-- Abgelaufene Anfragen aufräumen
	task.spawn(function()
		while true do
			task.wait(5)
			local now = os.clock()
			for id, req in requests do
				if now > req.expires then
					requests[id] = nil
				end
			end
		end
	end)
end

return TradeService
