-- Local values: EnvironmentalScoreEvent_mt
EnvironmentalScoreEvent = {}
local EnvironmentalScoreEvent_mt = Class(EnvironmentalScoreEvent, Event)
InitEventClass(EnvironmentalScoreEvent, "EnvironmentalScoreEvent")
function EnvironmentalScoreEvent.emptyNew()
	-- upvalues: (copy) EnvironmentalScoreEvent_mt
	return Event.new(EnvironmentalScoreEvent_mt)
end

-- Local values: self
function EnvironmentalScoreEvent.new(farmId)
	local v3_ = EnvironmentalScoreEvent.emptyNew()
	v3_.farmId = farmId
	return v3_
end

-- Local values: pfModule
function EnvironmentalScoreEvent:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	local v7_ = g_precisionFarming
	if v7_ ~= nil and v7_.environmentalScore ~= nil then
		v7_.environmentalScore:readStream(streamId, connection, self.farmId)
	end
end

-- Local values: pfModule
function EnvironmentalScoreEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	local v11_ = g_precisionFarming
	if v11_ ~= nil and v11_.environmentalScore ~= nil then
		v11_.environmentalScore:writeStream(streamId, connection, self.farmId)
	end
end
