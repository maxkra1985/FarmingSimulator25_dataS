-- Local values: PricingHistoryEvent_mt
PricingHistoryEvent = {}
local PricingHistoryEvent_mt = Class(PricingHistoryEvent, Event)
InitStaticEventClass(PricingHistoryEvent, "PricingHistoryEvent")
function PricingHistoryEvent.emptyNew()
	-- upvalues: (copy) PricingHistoryEvent_mt
	return Event.new(PricingHistoryEvent_mt)
end

-- Local values: self
function PricingHistoryEvent.new(period)
	local v3_ = PricingHistoryEvent.emptyNew()
	v3_.period = period
	return v3_
end

-- Local values: fillTypes, _, fillType, history
function PricingHistoryEvent:readStream(streamId, connection)
	self.period = SeasonPeriod.readStream(streamId)
	local v6_ = g_fillTypeManager:getFillTypes()
	for _, v7_ in ipairs(v6_) do
		if v7_.economy.sychronizeData then
			v7_.economy.history[self.period] = streamReadInt32(streamId) / 1000
		end
	end
end

-- Local values: fillTypes, _, fillType, history
function PricingHistoryEvent:writeStream(streamId, connection)
	SeasonPeriod.writeStream(streamId, self.period)
	local v10_ = g_fillTypeManager:getFillTypes()
	for _, v11_ in ipairs(v10_) do
		if v11_.economy.sychronizeData then
			local v12_ = v11_.economy.history
			streamWriteInt32(streamId, v12_[self.period] * 1000)
		end
	end
end

function PricingHistoryEvent:run(connection) end
