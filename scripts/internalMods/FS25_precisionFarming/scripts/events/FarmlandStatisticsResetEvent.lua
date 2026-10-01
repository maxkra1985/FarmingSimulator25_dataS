FarmlandStatisticsResetEvent = {}
local FarmlandStatisticsResetEvent_mt = Class(FarmlandStatisticsResetEvent, Event)
InitEventClass(FarmlandStatisticsResetEvent, "FarmlandStatisticsResetEvent")
function FarmlandStatisticsResetEvent.emptyNew()
	local self = Event.new(FarmlandStatisticsResetEvent_mt)
	return self
end
function FarmlandStatisticsResetEvent.new(farmlandId)
	local self = FarmlandStatisticsResetEvent.emptyNew()
	self.farmlandId = farmlandId
	return self
end
function FarmlandStatisticsResetEvent:readStream(streamId, connection)
	self.farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
	local pfModule = g_precisionFarming
	if pfModule ~= nil and pfModule.farmlandStatistics ~= nil then
		pfModule.farmlandStatistics:resetStatistic(self.farmlandId)
	end
end
function FarmlandStatisticsResetEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
end
