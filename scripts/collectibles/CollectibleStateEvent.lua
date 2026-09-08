-- Local values: CollectibleStateEvent_mt
CollectibleStateEvent = {}
local CollectibleStateEvent_mt = Class(CollectibleStateEvent, Event)
InitStaticEventClass(CollectibleStateEvent, "CollectibleStateEvent")
function CollectibleStateEvent.emptyNew()
	-- upvalues: (copy) CollectibleStateEvent_mt
	return Event.new(CollectibleStateEvent_mt)
end

-- Local values: self
function CollectibleStateEvent.new(state)
	local v3_ = CollectibleStateEvent.emptyNew()
	v3_.state = state
	return v3_
end

-- Local values: i
function CollectibleStateEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, #self.state)
	for v6_ = 1, #self.state do
		streamWriteBool(streamId, self.state[v6_])
	end
end

-- Local values: num, i
function CollectibleStateEvent:readStream(streamId, connection)
	self.state = {}
	for v10_ = 1, streamReadUInt8(streamId) do
		self.state[v10_] = streamReadBool(streamId)
	end
	self:run(connection)
end

function CollectibleStateEvent:run(connection)
	if connection:getIsServer() then
		g_currentMission.collectiblesSystem:onStateEvent(self.state)
	end
end
