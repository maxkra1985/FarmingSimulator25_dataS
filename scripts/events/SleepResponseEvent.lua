-- Local values: SleepResponseEvent_mt
SleepResponseEvent = {}
local SleepResponseEvent_mt = Class(SleepResponseEvent, Event)
InitStaticEventClass(SleepResponseEvent, "SleepResponseEvent")
function SleepResponseEvent.emptyNew()
	-- upvalues: (copy) SleepResponseEvent_mt
	return Event.new(SleepResponseEvent_mt)
end

-- Local values: self
function SleepResponseEvent.new(answer)
	local v3_ = SleepResponseEvent.emptyNew()
	v3_.answer = answer
	return v3_
end

function SleepResponseEvent:readStream(streamId, connection)
	local v7_ = not connection:getIsServer()
	assert(v7_, "SleepResponseEvent is a client to server only event")
	self.answer = streamReadBool(streamId)
	self:run(connection)
end

function SleepResponseEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.answer)
end

function SleepResponseEvent:run(connection)
	if g_sleepManager ~= nil then
		g_sleepManager:onSleepResponse(connection, self.answer)
	end
end
