-- Local values: SlotSystemUpdateEvent_mt
SlotSystemUpdateEvent = {}
local SlotSystemUpdateEvent_mt = Class(SlotSystemUpdateEvent, Event)
InitStaticEventClass(SlotSystemUpdateEvent, "SlotSystemUpdateEvent")
function SlotSystemUpdateEvent.emptyNew()
	-- upvalues: (copy) SlotSystemUpdateEvent_mt
	return Event.new(SlotSystemUpdateEvent_mt)
end

-- Local values: self
function SlotSystemUpdateEvent.new(slotLimit)
	local v3_ = SlotSystemUpdateEvent.emptyNew()
	v3_.slotLimit = slotLimit
	local v4_ = g_server ~= nil
	assert(v4_, "Server->client event")
	return v3_
end

-- Local values: slotLimit
function SlotSystemUpdateEvent:readStream(streamId, connection)
	local v8_ = streamReadUInt16(streamId)
	self.slotLimit = v8_ == 0 and math.huge or v8_
	self:run(connection)
end

-- Local values: slotLimit
function SlotSystemUpdateEvent:writeStream(streamId, connection)
	local v11_ = self.slotLimit
	local v12_ = v11_ == math.huge and 0 or v11_
	streamWriteUInt16(streamId, v12_)
end

function SlotSystemUpdateEvent:run(connection)
	g_currentMission.slotSystem:setSlotLimit(self.slotLimit)
end
