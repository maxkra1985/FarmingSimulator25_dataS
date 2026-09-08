-- Local values: FarmlandStatisticsEvent_mt
FarmlandStatisticsEvent = {}
local FarmlandStatisticsEvent_mt = Class(FarmlandStatisticsEvent, Event)
InitEventClass(FarmlandStatisticsEvent, "FarmlandStatisticsEvent")
function FarmlandStatisticsEvent.emptyNew()
	-- upvalues: (copy) FarmlandStatisticsEvent_mt
	return Event.new(FarmlandStatisticsEvent_mt)
end

-- Local values: self
function FarmlandStatisticsEvent.new(farmlandId)
	local v3_ = FarmlandStatisticsEvent.emptyNew()
	v3_.farmlandId = farmlandId
	return v3_
end

-- Local values: pfModule
function FarmlandStatisticsEvent:readStream(streamId, connection)
	self.farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
	local v7_ = g_precisionFarming
	if v7_ ~= nil and v7_.farmlandStatistics ~= nil then
		v7_.farmlandStatistics:readStatisticFromStream(self.farmlandId, streamId, connection)
	end
end

-- Local values: pfModule
function FarmlandStatisticsEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
	local v11_ = g_precisionFarming
	if v11_ ~= nil and v11_.farmlandStatistics ~= nil then
		v11_.farmlandStatistics:writeStatisticToStream(self.farmlandId, streamId, connection)
	end
end
