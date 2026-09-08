-- Local values: RidgeMarkerSetStateEvent_mt
RidgeMarkerSetStateEvent = {}
local RidgeMarkerSetStateEvent_mt = Class(RidgeMarkerSetStateEvent, Event)
InitStaticEventClass(RidgeMarkerSetStateEvent, "RidgeMarkerSetStateEvent")
function RidgeMarkerSetStateEvent.emptyNew()
	-- upvalues: (copy) RidgeMarkerSetStateEvent_mt
	return Event.new(RidgeMarkerSetStateEvent_mt)
end

-- Local values: self
function RidgeMarkerSetStateEvent.new(vehicle, state)
	local v4_ = RidgeMarkerSetStateEvent.emptyNew()
	v4_.vehicle = vehicle
	v4_.state = state
	local v5_
	if state >= 0 then
		v5_ = state < RidgeMarker.MAX_NUM_RIDGEMARKERS
	else
		v5_ = false
	end
	assert(v5_)
	return v4_
end

function RidgeMarkerSetStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadUIntN(streamId, RidgeMarker.SEND_NUM_BITS)
	self:run(connection)
end

function RidgeMarkerSetStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUIntN(streamId, self.state, RidgeMarker.SEND_NUM_BITS)
end

function RidgeMarkerSetStateEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setRidgeMarkerState(self.state, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(RidgeMarkerSetStateEvent.new(self.vehicle, self.state), nil, connection, self.vehicle)
	end
end

function RidgeMarkerSetStateEvent.sendEvent(vehicle, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(RidgeMarkerSetStateEvent.new(vehicle, state), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(RidgeMarkerSetStateEvent.new(vehicle, state))
	end
end
