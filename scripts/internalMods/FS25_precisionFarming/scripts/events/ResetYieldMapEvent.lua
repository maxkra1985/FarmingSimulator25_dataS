-- Local values: ResetYieldMapEvent_mt
ResetYieldMapEvent = {}
local ResetYieldMapEvent_mt = Class(ResetYieldMapEvent, Event)
InitEventClass(ResetYieldMapEvent, "ResetYieldMapEvent")
function ResetYieldMapEvent.emptyNew()
	-- upvalues: (copy) ResetYieldMapEvent_mt
	return Event.new(ResetYieldMapEvent_mt)
end

-- Local values: self
function ResetYieldMapEvent.new(farmlandId)
	local v3_ = ResetYieldMapEvent.emptyNew()
	v3_.farmlandId = farmlandId
	return v3_
end

function ResetYieldMapEvent:readStream(streamId, connection)
	self.farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
	self:run(connection)
end

function ResetYieldMapEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
end

function ResetYieldMapEvent:run(connection)
	if not connection:getIsServer() and (g_precisionFarming ~= nil and g_precisionFarming.yieldMap ~= nil) then
		g_precisionFarming.yieldMap:resetFarmlandYieldArea(self.farmlandId)
		g_precisionFarming:updatePrecisionFarmingOverlays()
	end
end
