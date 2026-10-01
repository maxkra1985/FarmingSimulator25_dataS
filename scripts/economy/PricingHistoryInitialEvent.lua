PricingHistoryInitialEvent = {}
local PricingHistoryInitialEvent_mt = Class(PricingHistoryInitialEvent, Event)
InitStaticEventClass(PricingHistoryInitialEvent, "PricingHistoryInitialEvent")
function PricingHistoryInitialEvent.emptyNew()
	return Event.new(PricingHistoryInitialEvent_mt)
end
function PricingHistoryInitialEvent.new()
	local self = PricingHistoryInitialEvent.emptyNew()
	return self
end
function PricingHistoryInitialEvent:readStream(streamId, connection)
	local fillTypes = g_fillTypeManager:getFillTypes()
	for _, fillType in ipairs(fillTypes) do
		if fillType.economy.sychronizeData then
			local history = fillType.economy.history
			for period = 1, 12 do
				history[period] = streamReadInt32(streamId) / 1000
			end
		end
	end
end
function PricingHistoryInitialEvent:writeStream(streamId, connection)
	local fillTypes = g_fillTypeManager:getFillTypes()
	for _, fillType in ipairs(fillTypes) do
		if fillType.economy.sychronizeData then
			local history = fillType.economy.history
			for period = 1, 12 do
				streamWriteInt32(streamId, history[period] * 1000)
			end
		end
	end
end
function PricingHistoryInitialEvent:run(connection) end
