--!strict
-- Minimales Signal für Kommunikation zwischen Services/Controllern ohne BindableEvents.
-- Handler laufen jeweils in eigenem Thread, damit ein Fehler die anderen nicht blockiert.

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, handler: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
}

local Signal = {}

function Signal.new<T...>(): Signal<T...>
	local handlers: { [Connection]: (T...) -> () } = {}

	local self = {} :: Signal<T...>

	function self.Connect(_: Signal<T...>, handler: (T...) -> ()): Connection
		local connection = {} :: Connection
		connection.Connected = true
		function connection.Disconnect(c: Connection)
			c.Connected = false
			handlers[c] = nil
		end
		handlers[connection] = handler
		return connection
	end

	function self.Once(s: Signal<T...>, handler: (T...) -> ()): Connection
		local connection: Connection
		connection = s:Connect(function(...: T...)
			connection:Disconnect()
			handler(...)
		end)
		return connection
	end

	function self.Fire(_: Signal<T...>, ...: T...)
		for _, handler in handlers do
			task.spawn(handler, ...)
		end
	end

	function self.DisconnectAll(_: Signal<T...>)
		for connection in handlers do
			connection.Connected = false
		end
		table.clear(handlers)
	end

	return self
end

return Signal
