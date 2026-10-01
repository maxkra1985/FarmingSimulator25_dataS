ConnectionManager = {}
local ConnectionManager_mt = Class(ConnectionManager)
function ConnectionManager.new()
	local self = setmetatable({}, ConnectionManager_mt)
	self.listeners = {}
	self.defaultListener = nil
	self.startupCount = 0
	self.maxIncomingConnections = 0
	return self
end
function ConnectionManager:packetReceived(packetType, timestamp, streamId)
	g_networkTime = netGetTime()
	local listener = self.listeners[streamId]
	if listener == nil then
		listener = self.defaultListener
	end
	if listener ~= nil then
		listener.func(listener.target, packetType, timestamp, streamId)
	end
end
function ConnectionManager:startupWithWorkingPort(port)
	if 0 < self.startupCount then
		self:startup()
	else
		if not self:startup(port) and not self:startup(port + 1) then
			self:startup()
		end
	end
end
function ConnectionManager:startup(port, address, maxIncomingConnections)
	local ip = Utils.getNoNil(address, "")
	if g_dedicatedServer == nil then
		maxIncomingConnections = g_serverMaxCapacity
	end
	local maxConnections = Utils.getNoNil(maxIncomingConnections, g_serverMaxCapacity) + 1
	if port ~= nil then
		if 0 < self.startupCount then
			printError("Error: Startup with port while already running")
			netShutdown(0, 0)
		end
		if not netStartup(maxConnections, 1, ip, port, "packetReceived", self) then
			return false
		end
		netSetMaximumIncomingConnections(maxConnections)
	elseif self.startupCount == 0 then
		if not netStartup(5, 1, ip, 0, "packetReceived", self) then
			return false
		end
		netSetMaximumIncomingConnections(5)
	end
	self.startupCount = self.startupCount + 1
	return true
end
function ConnectionManager:shutdown()
	self.startupCount = self.startupCount - 1
	if self.startupCount == 0 then
		netShutdown(500, 0)
	end
end
function ConnectionManager:shutdownAll()
	if 0 < self.startupCount then
		self.startupCount = 0
		netShutdown(500, 0)
	end
end
function ConnectionManager:addListener(streamId, func, target)
	self.listeners[streamId] = { func = func, target = target }
end
function ConnectionManager:removeListener(streamId)
	self.listeners[streamId] = nil
end
function ConnectionManager:setDefaultListener(func, target)
	if func ~= nil then
		self.defaultListener = { func = func, target = target }
	else
		self.defaultListener = nil
	end
end
