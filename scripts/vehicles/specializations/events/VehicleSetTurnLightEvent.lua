-- Local values: VehicleSetTurnLightEvent_mt
VehicleSetTurnLightEvent = {}
local VehicleSetTurnLightEvent_mt = Class(VehicleSetTurnLightEvent, Event)
InitStaticEventClass(VehicleSetTurnLightEvent, "VehicleSetTurnLightEvent")
function VehicleSetTurnLightEvent.emptyNew()
	-- upvalues: (copy) VehicleSetTurnLightEvent_mt
	return Event.new(VehicleSetTurnLightEvent_mt)
end

-- Local values: self
function VehicleSetTurnLightEvent.new(object, state)
	local v4_ = VehicleSetTurnLightEvent.emptyNew()
	v4_.object = object
	v4_.state = state
	local v5_
	if state >= 0 then
		v5_ = state <= Lights.TURNLIGHT_HAZARD
	else
		v5_ = false
	end
	assert(v5_)
	return v4_
end

function VehicleSetTurnLightEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadUIntN(streamId, Lights.turnLightSendNumBits)
	self:run(connection)
end

function VehicleSetTurnLightEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.state, Lights.turnLightSendNumBits)
end

function VehicleSetTurnLightEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setTurnLightState(self.state, true, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(VehicleSetTurnLightEvent.new(self.object, self.state), nil, connection, self.object)
	end
end
