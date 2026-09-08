-- Local values: FarmlandStatisticsResetEvent_mt
FarmlandStatisticsResetEvent = {}
local FarmlandStatisticsResetEvent_mt = Class(FarmlandStatisticsResetEvent, Event)
InitEventClass(FarmlandStatisticsResetEvent, "FarmlandStatisticsResetEvent")
function FarmlandStatisticsResetEvent.emptyNew()
	-- upvalues: (copy) FarmlandStatisticsResetEvent_mt
	return Event.new(FarmlandStatisticsResetEvent_mt)
end

-- Local values: self
function FarmlandStatisticsResetEvent.new(farmlandId)
	local v3_ = FarmlandStatisticsResetEvent.emptyNew()
	v3_.farmlandId = farmlandId
	return v3_
end

-- Local values: pfModule
function FarmlandStatisticsResetEvent:readStream(streamId, connection)
	self.farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
	local v6_ = g_precisionFarming
	if v6_ ~= nil and v6_.farmlandStatistics ~= nil then
		v6_.farmlandStatistics:resetStatistic(self.farmlandId)
	end
end

function FarmlandStatisticsResetEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
end
