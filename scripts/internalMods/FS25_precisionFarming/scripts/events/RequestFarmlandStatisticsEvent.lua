-- Local values: RequestFarmlandStatisticsEvent_mt
RequestFarmlandStatisticsEvent = {}
local RequestFarmlandStatisticsEvent_mt = Class(RequestFarmlandStatisticsEvent, Event)
InitEventClass(RequestFarmlandStatisticsEvent, "RequestFarmlandStatisticsEvent")
function RequestFarmlandStatisticsEvent.emptyNew()
	-- upvalues: (copy) RequestFarmlandStatisticsEvent_mt
	return Event.new(RequestFarmlandStatisticsEvent_mt)
end

-- Local values: self
function RequestFarmlandStatisticsEvent.new(farmlandId)
	local v3_ = RequestFarmlandStatisticsEvent.emptyNew()
	v3_.farmlandId = farmlandId
	return v3_
end

function RequestFarmlandStatisticsEvent:readStream(streamId, connection)
	self.farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
	self:run(connection)
end

function RequestFarmlandStatisticsEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
end

function RequestFarmlandStatisticsEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(FarmlandStatisticsEvent.new(self.farmlandId), false, nil, nil, true, { connection })
	end
end
