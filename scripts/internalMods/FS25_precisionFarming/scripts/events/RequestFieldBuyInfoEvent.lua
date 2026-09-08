-- Local values: RequestFieldBuyInfoEvent_mt
RequestFieldBuyInfoEvent = {}
local RequestFieldBuyInfoEvent_mt = Class(RequestFieldBuyInfoEvent, Event)
InitEventClass(RequestFieldBuyInfoEvent, "RequestFieldBuyInfoEvent")
function RequestFieldBuyInfoEvent.emptyNew()
	-- upvalues: (copy) RequestFieldBuyInfoEvent_mt
	return Event.new(RequestFieldBuyInfoEvent_mt)
end

-- Local values: self
function RequestFieldBuyInfoEvent.new(farmlandId)
	local v3_ = RequestFieldBuyInfoEvent.emptyNew()
	v3_.farmlandId = farmlandId
	return v3_
end

function RequestFieldBuyInfoEvent:readStream(streamId, connection)
	self.farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
	self:run(connection)
end

function RequestFieldBuyInfoEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
end

function RequestFieldBuyInfoEvent:run(connection)
	if not (connection:getIsServer() or connection:getIsServer()) then
		g_server:broadcastEvent(AdditionalFieldBuyInfoEvent.new(self.farmlandId), false, nil, nil, true, { connection })
	end
end
