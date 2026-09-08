-- Local values: StopSleepStateEvent_mt
StopSleepStateEvent = {}
local StopSleepStateEvent_mt = Class(StopSleepStateEvent, Event)
InitStaticEventClass(StopSleepStateEvent, "StopSleepStateEvent")
function StopSleepStateEvent.emptyNew()
	-- upvalues: (copy) StopSleepStateEvent_mt
	return Event.new(StopSleepStateEvent_mt)
end
function StopSleepStateEvent.new()
	return StopSleepStateEvent.emptyNew()
end

function StopSleepStateEvent:readStream(streamId, connection)
	local v4_ = connection:getIsServer()
	assert(v4_, "StopSleepStateEvent is a server to client only event")
	self:run(connection)
end

function StopSleepStateEvent:writeStream(streamId, connection) end

function StopSleepStateEvent:run(connection)
	if g_sleepManager ~= nil then
		g_sleepManager:stopSleep()
	end
end
