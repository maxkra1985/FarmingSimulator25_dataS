-- Local values: StartSleepStateEvent_mt
StartSleepStateEvent = {}
local StartSleepStateEvent_mt = Class(StartSleepStateEvent, Event)
InitStaticEventClass(StartSleepStateEvent, "StartSleepStateEvent")
function StartSleepStateEvent.emptyNew()
	-- upvalues: (copy) StartSleepStateEvent_mt
	return Event.new(StartSleepStateEvent_mt)
end

-- Local values: self
function StartSleepStateEvent.new(targetTime)
	local v3_ = StartSleepStateEvent.emptyNew()
	v3_.targetTime = targetTime
	return v3_
end

function StartSleepStateEvent:readStream(streamId, connection)
	local v7_ = connection:getIsServer()
	assert(v7_, "StartSleepStateEvent is a server to client only event")
	self.targetTime = streamReadInt32(streamId)
	self:run(connection)
end

function StartSleepStateEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.targetTime)
end

function StartSleepStateEvent:run(connection)
	if g_sleepManager ~= nil then
		g_sleepManager:startSleep(self.targetTime)
	end
end
