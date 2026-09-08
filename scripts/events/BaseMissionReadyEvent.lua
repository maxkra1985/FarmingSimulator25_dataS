-- Local values: BaseMissionReadyEvent_mt
BaseMissionReadyEvent = {}
local BaseMissionReadyEvent_mt = Class(BaseMissionReadyEvent, Event)
InitStaticEventClass(BaseMissionReadyEvent, "BaseMissionReadyEvent")
function BaseMissionReadyEvent.emptyNew()
	-- upvalues: (copy) BaseMissionReadyEvent_mt
	return Event.new(BaseMissionReadyEvent_mt)
end
function BaseMissionReadyEvent.new()
	return BaseMissionReadyEvent.emptyNew()
end

function BaseMissionReadyEvent:readStream(streamId, connection)
	self:run(connection)
end

function BaseMissionReadyEvent:writeStream(streamId, connection) end

function BaseMissionReadyEvent:run(connection)
	if connection:getIsServer() then
		g_currentMission:onFinishedReceivingDynamicData(connection)
	else
		g_currentMission:onConnectionReady(connection)
	end
end
