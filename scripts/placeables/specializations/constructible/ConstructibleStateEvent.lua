ConstructibleStateEvent = {}
local ConstructibleStateEvent_mt = Class(ConstructibleStateEvent, Event)
InitStaticEventClass(ConstructibleStateEvent, "ConstructibleStateEvent")
function ConstructibleStateEvent.emptyNew()
	local self = Event.new(ConstructibleStateEvent_mt)
	return self
end
function ConstructibleStateEvent.new(constructible, stateIndex)
	local self = ConstructibleStateEvent.emptyNew()
	self.constructible = constructible
	self.stateIndex = stateIndex
	return self
end
function ConstructibleStateEvent:readStream(streamId, connection)
	self.constructible = NetworkUtil.readNodeObject(streamId)
	self.stateIndex = streamReadUInt8(streamId)
	self:run(connection)
end
function ConstructibleStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.constructible)
	streamWriteUInt8(streamId, self.stateIndex)
end
function ConstructibleStateEvent:run(connection)
	if self.constructible ~= nil and self.constructible:getIsSynchronized() then
		self.constructible:setConstructibleState(self.stateIndex)
	end
end
