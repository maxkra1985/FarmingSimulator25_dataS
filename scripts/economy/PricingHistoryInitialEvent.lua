-- Local values: PricingHistoryInitialEvent_mt
PricingHistoryInitialEvent = {}
local PricingHistoryInitialEvent_mt = Class(PricingHistoryInitialEvent, Event)
InitStaticEventClass(PricingHistoryInitialEvent, "PricingHistoryInitialEvent")
function PricingHistoryInitialEvent.emptyNew()
	-- upvalues: (copy) PricingHistoryInitialEvent_mt
	return Event.new(PricingHistoryInitialEvent_mt)
end
function PricingHistoryInitialEvent.new()
	return PricingHistoryInitialEvent.emptyNew()
end

-- Local values: fillTypes, _, fillType, history, period
function PricingHistoryInitialEvent:readStream(streamId, connection)
	local v3_ = g_fillTypeManager:getFillTypes()
	for _, v4_ in ipairs(v3_) do
		if v4_.economy.sychronizeData then
			local v5_ = v4_.economy.history
			for v6_ = 1, 12 do
				v5_[v6_] = streamReadInt32(streamId) / 1000
			end
		end
	end
end

-- Local values: fillTypes, _, fillType, history, period
function PricingHistoryInitialEvent:writeStream(streamId, connection)
	local v8_ = g_fillTypeManager:getFillTypes()
	for _, v9_ in ipairs(v8_) do
		if v9_.economy.sychronizeData then
			local v10_ = v9_.economy.history
			for v11_ = 1, 12 do
				streamWriteInt32(streamId, v10_[v11_] * 1000)
			end
		end
	end
end

function PricingHistoryInitialEvent:run(connection) end
