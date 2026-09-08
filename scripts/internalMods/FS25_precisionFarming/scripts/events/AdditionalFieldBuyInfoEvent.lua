-- Local values: AdditionalFieldBuyInfoEvent_mt
AdditionalFieldBuyInfoEvent = {}
local AdditionalFieldBuyInfoEvent_mt = Class(AdditionalFieldBuyInfoEvent, Event)
InitEventClass(AdditionalFieldBuyInfoEvent, "AdditionalFieldBuyInfoEvent")
function AdditionalFieldBuyInfoEvent.emptyNew()
	-- upvalues: (copy) AdditionalFieldBuyInfoEvent_mt
	return Event.new(AdditionalFieldBuyInfoEvent_mt)
end

-- Local values: self
function AdditionalFieldBuyInfoEvent.new(farmlandId)
	local v3_ = AdditionalFieldBuyInfoEvent.emptyNew()
	v3_.farmlandId = farmlandId
	return v3_
end

-- Local values: pfModule
function AdditionalFieldBuyInfoEvent:readStream(streamId, connection)
	self.farmlandId = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
	local v7_ = g_precisionFarming
	if v7_ ~= nil and v7_.additionalFieldBuyInfo ~= nil then
		v7_.additionalFieldBuyInfo:readInfoFromStream(self.farmlandId, streamId, connection)
	end
end

-- Local values: pfModule
function AdditionalFieldBuyInfoEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmlandId, g_farmlandManager.numberOfBits)
	local v11_ = g_precisionFarming
	if v11_ ~= nil and v11_.additionalFieldBuyInfo ~= nil then
		v11_.additionalFieldBuyInfo:writeInfoToStream(self.farmlandId, streamId, connection)
	end
end
