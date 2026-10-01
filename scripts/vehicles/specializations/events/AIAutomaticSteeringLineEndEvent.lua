AIAutomaticSteeringLineEndEvent = {}
local AIAutomaticSteeringLineEndEvent_mt = Class(AIAutomaticSteeringLineEndEvent, Event)
InitStaticEventClass(AIAutomaticSteeringLineEndEvent, "AIAutomaticSteeringLineEndEvent")
function AIAutomaticSteeringLineEndEvent.emptyNew()
	local self = Event.new(AIAutomaticSteeringLineEndEvent_mt)
	return self
end
function AIAutomaticSteeringLineEndEvent.new(vehicle, state, segmentIndex, segmentIsLeft)
	local self = AIAutomaticSteeringLineEndEvent.emptyNew()
	self.vehicle = vehicle
	return self
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
