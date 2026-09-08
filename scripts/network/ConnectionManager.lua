-- Local values: ConnectionManager_mt
ConnectionManager = {}
local ConnectionManager_mt = Class(ConnectionManager)
function ConnectionManager.new()
	-- upvalues: (copy) ConnectionManager_mt
	local v2_ = ConnectionManager_mt
	local v3_ = setmetatable({}, v2_)
	v3_.listeners = {}
	v3_.defaultListener = nil
	v3_.startupCount = 0
	v3_.maxIncomingConnections = 0
	return v3_
end

-- Local values: listener
function ConnectionManager:packetReceived(packetType, timestamp, streamId)
	g_networkTime = netGetTime()
	local v8_ = self.listeners[streamId]
	if v8_ == nil then
		v8_ = self.defaultListener
	end
	if v8_ ~= nil then
		v8_.func(v8_.target, packetType, timestamp, streamId)
	end
end

function ConnectionManager:startupWithWorkingPort(port)
	if self.startupCount > 0 then
		self:startup()
	elseif not (self:startup(port) or self:startup(port + 1)) then
		self:startup()
	end
end

-- Local values: ip, maxConnections
function ConnectionManager:startup(port, address, maxIncomingConnections)
	local v15_ = Utils.getNoNil(address, "")
	if g_dedicatedServer == nil then
		maxIncomingConnections = g_serverMaxCapacity
	end
	local v16_ = Utils.getNoNil(maxIncomingConnections, g_serverMaxCapacity) + 1
	if port == nil then
		if self.startupCount == 0 then
			if not netStartup(5, 1, v15_, 0, "packetReceived", self) then
				return false
			end
			netSetMaximumIncomingConnections(5)
		end
	else
		if self.startupCount > 0 then
			printError("Error: Startup with port while already running")
			netShutdown(0, 0)
		end
		if not netStartup(v16_, 1, v15_, port, "packetReceived", self) then
			return false
		end
		netSetMaximumIncomingConnections(v16_)
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
	if self.startupCount > 0 then
		self.startupCount = 0
		netShutdown(500, 0)
	end
end

function ConnectionManager:addListener(streamId, func, target)
	self.listeners[streamId] = {
		["func"] = func,
		["target"] = target
	}
end

function ConnectionManager:removeListener(streamId)
	self.listeners[streamId] = nil
end

function ConnectionManager:setDefaultListener(func, target)
	if func == nil then
		self.defaultListener = nil
	else
		self.defaultListener = {
			["func"] = func,
			["target"] = target
		}
	end
end
