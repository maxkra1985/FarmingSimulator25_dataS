SleepRequestTimeoutEvent = {}
local SleepRequestTimeoutEvent_mt = Class(SleepRequestTimeoutEvent, Event)
InitStaticEventClass(SleepRequestTimeoutEvent, "SleepRequestTimeoutEvent")
function SleepRequestTimeoutEvent.emptyNew()
	local self = Event.new(SleepRequestTimeoutEvent_mt)
	return self
end
function SleepRequestTimeoutEvent.new()
	local self = SleepRequestTimeoutEvent.emptyNew()
	return self
end
function SleepRequestTimeoutEvent:readStream(streamId, connection)
	assert(connection:getIsServer(), "SleepRequestTimeoutEvent is a server to client only event")
	self:run(connection)
end
function SleepRequestTimeoutEvent:writeStream(streamId, connection) end
function SleepRequestTimeoutEvent:run(connection)
	if g_sleepManager ~= nil then
		g_sleepManager:onSleepRequestTimeout()
	end
end
