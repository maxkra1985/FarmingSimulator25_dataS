PricingHistoryEvent = {}
local PricingHistoryEvent_mt = Class(PricingHistoryEvent, Event)
InitStaticEventClass(PricingHistoryEvent, "PricingHistoryEvent")
function PricingHistoryEvent.emptyNew()
	return Event.new(PricingHistoryEvent_mt)
end
function PricingHistoryEvent.new(period)
	local self = PricingHistoryEvent.emptyNew()
	self.period = period
	return self
end
function PricingHistoryEvent:readStream(streamId, connection)
	self.period = SeasonPeriod.readStream(streamId)
	local fillTypes = g_fillTypeManager:getFillTypes()
	for _, fillType in ipairs(fillTypes) do
		if fillType.economy.sychronizeData then
			local history = fillType.economy.history
			history[self.period] = streamReadInt32(streamId) / 1000
		end
	end
end
function PricingHistoryEvent:writeStream(streamId, connection)
	SeasonPeriod.writeStream(streamId, self.period)
	local fillTypes = g_fillTypeManager:getFillTypes()
	for _, fillType in ipairs(fillTypes) do
		if fillType.economy.sychronizeData then
			local history = fillType.economy.history
			streamWriteInt32(streamId, history[self.period] * 1000)
		end
	end
end
function PricingHistoryEvent:run(connection) end
