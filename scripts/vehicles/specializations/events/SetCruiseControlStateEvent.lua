-- Local values: SetCruiseControlStateEvent_mt
SetCruiseControlStateEvent = {}
local SetCruiseControlStateEvent_mt = Class(SetCruiseControlStateEvent, Event)
InitStaticEventClass(SetCruiseControlStateEvent, "SetCruiseControlStateEvent")
function SetCruiseControlStateEvent.emptyNew()
	-- upvalues: (copy) SetCruiseControlStateEvent_mt
	return Event.new(SetCruiseControlStateEvent_mt)
end

-- Local values: self
function SetCruiseControlStateEvent.new(vehicle, state)
	local v4_ = SetCruiseControlStateEvent.emptyNew()
	v4_.state = state
	v4_.vehicle = vehicle
	return v4_
end

function SetCruiseControlStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadUIntN(streamId, 2)
	self:run(connection)
end

function SetCruiseControlStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUIntN(streamId, self.state, 2)
end

function SetCruiseControlStateEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setCruiseControlState(self.state, true)
	end
end
