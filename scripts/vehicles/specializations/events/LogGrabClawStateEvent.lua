-- Local values: LogGrabClawStateEvent_mt
LogGrabClawStateEvent = {}
local LogGrabClawStateEvent_mt = Class(LogGrabClawStateEvent, Event)
InitStaticEventClass(LogGrabClawStateEvent, "LogGrabClawStateEvent")
function LogGrabClawStateEvent.emptyNew()
	-- upvalues: (copy) LogGrabClawStateEvent_mt
	return Event.new(LogGrabClawStateEvent_mt)
end

-- Local values: self
function LogGrabClawStateEvent.new(object, state, grabIndex)
	local v5_ = LogGrabClawStateEvent.emptyNew()
	v5_.object = object
	v5_.state = state
	v5_.grabIndex = grabIndex
	return v5_
end

function LogGrabClawStateEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)
	self.grabIndex = streamReadUIntN(streamId, LogGrab.GRAB_INDEX_NUM_BITS)
	self:run(connection)
end

function LogGrabClawStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
	streamWriteUIntN(streamId, self.grabIndex, LogGrab.GRAB_INDEX_NUM_BITS)
end

function LogGrabClawStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setLogGrabClawState(self.grabIndex, self.state, true)
	end
end

function LogGrabClawStateEvent.sendEvent(vehicle, state, grabIndex, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(LogGrabClawStateEvent.new(vehicle, state, grabIndex), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(LogGrabClawStateEvent.new(vehicle, state, grabIndex))
	end
end
