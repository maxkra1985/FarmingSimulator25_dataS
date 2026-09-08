-- Local values: ConstructibleStateEvent_mt
ConstructibleStateEvent = {}
local ConstructibleStateEvent_mt = Class(ConstructibleStateEvent, Event)
InitStaticEventClass(ConstructibleStateEvent, "ConstructibleStateEvent")
function ConstructibleStateEvent.emptyNew()
	-- upvalues: (copy) ConstructibleStateEvent_mt
	return Event.new(ConstructibleStateEvent_mt)
end

-- Local values: self
function ConstructibleStateEvent.new(constructible, stateIndex)
	local v4_ = ConstructibleStateEvent.emptyNew()
	v4_.constructible = constructible
	v4_.stateIndex = stateIndex
	return v4_
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
