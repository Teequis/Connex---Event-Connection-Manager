--!strict
--!native
--!optimize 2
-- Connex 1.0.0
-- @Teequis

--[[ 
	Docs Reference

	[ConnexConnection - Class]
		.Name: string
		-> The optional unique identifier of the connection. Defaults to nil if not provided
		
		.Priority: number
		-> The execution priority value. Higher numbers run first (defaults to 0)
		
		.Connected: boolean
		-> Whether the connection is currently active and attached to the wrapper
		
		.Enabled: boolean
		-> Whether the connection is listening (false if paused)
		
		.Async: boolean
		-> Whether the callback executes asynchronously in a separate thread
		
		.Once: boolean
		-> Whether the connection will automatically destroy after firing once
		
		:Fire(...: any): ()
		-> Manually executes the connection's callback with the given arguments
		
		:SetPriority(newPriority: number): ()
		-> Updates execution priority and flags the wrapper for lazy sorting
		
		:Pause(): ()
		-> Temporarily disables the callback from firing without disconnecting
		
		:Resume(): ()
		-> Re-enables a paused connection
		
		:Disconnect(): ()
		-> Deactivates the connection, clears its callback reference, and flags the wrapper for cleanup.
		Automatically unbinds the underlying signal if no active connections remain
		
		:Destroy(): ()
		-> Disconnects and clears all internal table references and metatables for garbage collection

	[Connex - Class]
		.new(event: RBXScriptSignal | table): Connex
		-> Creates a new independent wrapper for the given signal without caching it.
			Each wrapper manages its own connections, allowing it to be cleaned or destroyed
			without affecting other wrappers listening to the same signal.

		.Wrap(event: RBXScriptSignal | table): Connex
		-> Wraps and caches the signal. Returns the existing wrapper if already cached.
			Connections are shared between modules using the same cached wrapper.
		
		:Connect(func: (...any) -> (), name: string?, priority: number?): ConnexConnection
		-> Connects a synchronous listener (protected via pcall). Overwrites existing connection if name matches
		
		:ConnectAsync(func: (...any) -> (), name: string?, priority: number?): ConnexConnection
		-> Connects a listener that executes asynchronously in a new thread via task.spawn
		
		:Once(func: (...any) -> (), name: string, priority: number): ConnexConnection
		-> Connects a one-time listener that automatically destroys after firing
		
		:Wait(): ...any
		-> Yields the current coroutine until the signal fires and returns the arguments
		
		:GetConnection(name: string): ConnexConnection
		-> Retrieves an active connection by its unique name in O(1) time, or nil if not found
		
		:Clean(): ()
		-> Disconnects and destroys all active connections inside this wrapper
		
		:Destroy(): ()
		-> Fully cleans up the wrapper, clears all connections, and removes it from cache
]]--

local ConnexConnection = {
	Name = nil,
	Priority = 0,
	Connected = true,
	Enabled = true,
	Async = false,
	Once = false,
}

ConnexConnection.__index = ConnexConnection

export type ConnexConnection = typeof(setmetatable({} :: {
	Name: string,
	Priority: number,
	Connected: boolean,
	Enabled: boolean,
	Async: boolean, 
	Once: boolean,
	_func: ((...any) -> ()),
	_Connex: Connex,
	_insertId: number,
}, ConnexConnection))

local function connectionComparator(a: ConnexConnection, b: ConnexConnection): boolean
	if a.Priority == b.Priority then
		return a._insertId < b._insertId
	end
	return a.Priority > b.Priority
end

function ConnexConnection.new(connex: Connex, name: string, priority: number, insertId: number, func: (...any) -> (), isAsync: boolean, isOnce: boolean): ConnexConnection
	return setmetatable({
		_func = func,
		_Connex = connex,
		_insertId = insertId,
		Name = name,
		Priority = priority or 0,
		Async = isAsync,	
		Once = isOnce,
	}, ConnexConnection) :: ConnexConnection
end

function ConnexConnection:Fire(...: any)
	if not self.Connected or not self.Enabled then return end

	local callback = self._func
	if not callback then return end

	if self.Once then
		self:Destroy()
	end

	if self.Async then
		task.spawn(callback, ...)
	else
		local ok, err = pcall(callback, ...)
		if not ok then
			task.spawn(error, err)
		end
	end
end

function ConnexConnection:SetPriority(newPriority: number)
	if self.Priority == newPriority then return end
	self.Priority = newPriority
	if self._Connex then
		self._Connex._isDirty = true
	end
end

function ConnexConnection:Pause()
	self.Enabled = false
end

function ConnexConnection:Resume()
	self.Enabled = true
end

function ConnexConnection:Disconnect()
	if not self.Connected then return end
	self.Connected = false
	self._func = nil

	local connex = self._Connex
	if not connex then return end

	connex._activeCount -= 1
	connex._isDirty = true

	if self.Name and connex._byName and connex._byName[self.Name] == self then
		connex._byName[self.Name] = nil
	end

	connex:_checkIdle()
end

function ConnexConnection:Destroy()
	self:Disconnect()
	self._Connex = nil
	table.clear(self)
	setmetatable(self, nil)
end

local Connex = {}
Connex.__index = Connex
Connex.Cache = setmetatable({}, {__mode = "kv"}):: {[any]: Connex}

export type Connex = typeof(setmetatable({} :: {
	_event: any,
	_rbxConnection: any,
	_connections: {ConnexConnection},
	_byName: {[string]: ConnexConnection},
	_counter: number,
	_activeCount: number,
	_isDirty: boolean,
	_isProcessing: boolean,
}, {}))

local function isValidSignal(event: any): boolean
	return typeof(event) == "RBXScriptSignal" or (type(event) == "table" and type(event.Connect) == "function")
end

function Connex.new(event: any): Connex
	assert(isValidSignal(event),"[Connex]: Invalid signal")

	return setmetatable({
		_event = event,
		_rbxConnection = nil,
		_connections = {},
		_byName = nil,
		_counter = 0,
		_activeCount = 0,
		_isDirty = false,
		_isProcessing = false,
	}, Connex)
end

function Connex.Wrap(event: any): Connex
	assert(isValidSignal(event), "[Connex]: Wrap must be called with a RBXScriptSignal or a custom Signal object")
	
	local cached = Connex.Cache[event]
	if cached then
		return cached
	end
	
	for key, connex in pairs(Connex.Cache) do --// Check if the event is already wrapped (This work more better than Connex.Cache[event])
		if key == event then
			return connex
		end
	end

	local self = Connex.new(event)
	Connex.Cache[event] = self

	return self
end

function Connex:_process(...: any)
	if self._isDirty then
		self:_cleanAndSort()
	end

	self._isProcessing = true
	local conns = self._connections

	for i = 1, #conns do
		local conn = conns[i]
		if conn and conn.Connected then
			conn:Fire(...)
		end
	end

	self._isProcessing = false
	self:_checkIdle()
end

function Connex:_cleanAndSort()
	local writeIdx = 1
	local conns = self._connections
	local total = #conns

	for readIdx = 1, total do
		local conn = conns[readIdx]
		if conn.Connected then
			if writeIdx ~= readIdx then
				conns[writeIdx] = conn
			end
			writeIdx += 1
		end
	end

	for i = writeIdx, total do
		conns[i] = nil
	end

	table.sort(conns, connectionComparator)
	self._isDirty = false
end

function Connex:_ensureListening()
	if not self._rbxConnection and self._event then
		self._rbxConnection = self._event:Connect(function(...)
			self:_process(...)
		end)
	end
end

function Connex:_checkIdle()
	if self._isProcessing or self._activeCount > 0 then return end

	if self._rbxConnection then
		if type(self._rbxConnection.Disconnect) == "function" then
			self._rbxConnection:Disconnect()
		end
		self._rbxConnection = nil
	end
	
	table.clear(self._connections)
	if self._byName then
		table.clear(self._byName)
	end
	
	self._isDirty = false
	self._counter = 0
	self._activeCount = 0

	if self._event then
		Connex.Cache[self._event] = nil
	end
end

function Connex:_buildConnection(func: (...any) -> (), name: string, priority: number, isAsync: boolean, isOnce: boolean): ConnexConnection
	assert(type(func) == "function", "[Connex]: Requires a function")

	if name then
		if not self._byName then
			self._byName = {}
		end

		local existing = self._byName[name]
		if existing then
			existing:Disconnect()
			warn(`[Connex]: The connection "{name}" was overwritten.`)
		end
	end

	self._counter += 1
	self._activeCount += 1

	local newConn = ConnexConnection.new(self, name, priority, self._counter, func, isAsync, isOnce)
	table.insert(self._connections, newConn)

	if name and self._byName then
		self._byName[name] = newConn
	end

	self:_ensureListening()
	self._isDirty = true 
	return newConn
end

function Connex:Clean()
	self._isProcessing = true
	for _, conn in ipairs(self._connections) do
		if conn.Destroy then
			conn:Destroy()
		end
	end
	self._isProcessing = false
	self._activeCount = 0

	self:_checkIdle()
end

function Connex:Connect(func: (...any) -> (), name: string?, priority: number?): ConnexConnection
	return self:_buildConnection(func, name, priority, false, false)
end

function Connex:ConnectAsync(func: (...any) -> (), name: string?, priority: number?): ConnexConnection
	return self:_buildConnection(func, name, priority, true, false)
end

function Connex:Once(func: (...any) -> (), name: string, priority: number): ConnexConnection
	return self:_buildConnection(func, name, priority, false, true)
end

function Connex:Wait(): any
	local thread = coroutine.running()

	self:Once(function(...)
		task.spawn(thread, ...)
	end, nil, 9999)

	return coroutine.yield()
end

function Connex:GetConnection(name: string): ConnexConnection
	if not self._byName then return end

	local conn = self._byName[name]
	if conn and conn.Connected then
		return conn
	end
end

function Connex:Destroy()
	local event = self._event

	self:Clean()

	if event and Connex.Cache[event] == self then
		Connex.Cache[event] = nil
	end

	table.clear(self)
	setmetatable(self, nil)
end

return Connex
