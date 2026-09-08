-- Local values: TensionBeltsRefreshEvent_mt
TensionBeltsRefreshEvent = {}
local TensionBeltsRefreshEvent_mt = Class(TensionBeltsRefreshEvent, Event)
InitStaticEventClass(TensionBeltsRefreshEvent, "TensionBeltsRefreshEvent")
function TensionBeltsRefreshEvent.emptyNew()
	-- upvalues: (copy) TensionBeltsRefreshEvent_mt
	return Event.new(TensionBeltsRefreshEvent_mt)
end

-- Local values: self
function TensionBeltsRefreshEvent.new(object)
	local v3_ = TensionBeltsRefreshEvent.emptyNew()
	v3_.object = object
	return v3_
end

function TensionBeltsRefreshEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function TensionBeltsRefreshEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end

function TensionBeltsRefreshEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:refreshTensionBelts()
	end
end
