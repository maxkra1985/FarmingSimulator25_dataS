-- Local values: FellerBuncherReleaseEvent_mt
FellerBuncherReleaseEvent = {}
local FellerBuncherReleaseEvent_mt = Class(FellerBuncherReleaseEvent, Event)
InitStaticEventClass(FellerBuncherReleaseEvent, "FellerBuncherReleaseEvent")
function FellerBuncherReleaseEvent.emptyNew()
	-- upvalues: (copy) FellerBuncherReleaseEvent_mt
	return Event.new(FellerBuncherReleaseEvent_mt)
end

-- Local values: self
function FellerBuncherReleaseEvent.new(object)
	local v3_ = FellerBuncherReleaseEvent.emptyNew()
	v3_.object = object
	return v3_
end

function FellerBuncherReleaseEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function FellerBuncherReleaseEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end

function FellerBuncherReleaseEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:releaseMountedTrees(true)
	end
end

function FellerBuncherReleaseEvent.sendEvent(vehicle, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(FellerBuncherReleaseEvent.new(vehicle), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(FellerBuncherReleaseEvent.new(vehicle))
	end
end
