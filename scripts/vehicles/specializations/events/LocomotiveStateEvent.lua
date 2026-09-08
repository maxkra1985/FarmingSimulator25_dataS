-- Local values: LocomotiveStateEvent_mt
LocomotiveStateEvent = {}
local LocomotiveStateEvent_mt = Class(LocomotiveStateEvent, Event)
InitStaticEventClass(LocomotiveStateEvent, "LocomotiveStateEvent")
function LocomotiveStateEvent.emptyNew()
	-- upvalues: (copy) LocomotiveStateEvent_mt
	return Event.new(LocomotiveStateEvent_mt)
end

-- Local values: self
function LocomotiveStateEvent.new(object, state)
	local v4_ = LocomotiveStateEvent.emptyNew()
	v4_.object = object
	v4_.state = state
	return v4_
end

function LocomotiveStateEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadUIntN(streamId, Locomotive.NUM_BITS_STATE)
	self:run(connection)
end

function LocomotiveStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.state, Locomotive.NUM_BITS_STATE)
end

function LocomotiveStateEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setLocomotiveState(self.state, true)
	end
end
