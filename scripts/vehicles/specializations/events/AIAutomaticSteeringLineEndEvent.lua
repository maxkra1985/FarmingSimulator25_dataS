-- Local values: AIAutomaticSteeringLineEndEvent_mt
AIAutomaticSteeringLineEndEvent = {}
local AIAutomaticSteeringLineEndEvent_mt = Class(AIAutomaticSteeringLineEndEvent, Event)
InitStaticEventClass(AIAutomaticSteeringLineEndEvent, "AIAutomaticSteeringLineEndEvent")
function AIAutomaticSteeringLineEndEvent.emptyNew()
	-- upvalues: (copy) AIAutomaticSteeringLineEndEvent_mt
	return Event.new(AIAutomaticSteeringLineEndEvent_mt)
end

-- Local values: self
function AIAutomaticSteeringLineEndEvent.new(vehicle, state, segmentIndex, segmentIsLeft)
	local v3_ = AIAutomaticSteeringLineEndEvent.emptyNew()
	v3_.vehicle = vehicle
	return v3_
end

function AIAutomaticSteeringLineEndEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function AIAutomaticSteeringLineEndEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end

function AIAutomaticSteeringLineEndEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		SpecializationUtil.raiseEvent(self.vehicle, "onAIAutomaticSteeringLineEnd")
	end
end
