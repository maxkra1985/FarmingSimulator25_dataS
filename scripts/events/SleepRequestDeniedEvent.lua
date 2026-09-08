-- Local values: SleepRequestDeniedEvent_mt
SleepRequestDeniedEvent = {}
local SleepRequestDeniedEvent_mt = Class(SleepRequestDeniedEvent, Event)
InitStaticEventClass(SleepRequestDeniedEvent, "SleepRequestDeniedEvent")
function SleepRequestDeniedEvent.emptyNew()
	-- upvalues: (copy) SleepRequestDeniedEvent_mt
	return Event.new(SleepRequestDeniedEvent_mt)
end

-- Local values: self
function SleepRequestDeniedEvent.new(userId)
	local v3_ = SleepRequestDeniedEvent.emptyNew()
	v3_.userId = userId or 0
	return v3_
end

function SleepRequestDeniedEvent:readStream(streamId, connection)
	local v7_ = connection:getIsServer()
	assert(v7_, "SleepRequestDeniedEvent is a server to client only event")
	self.userId = User.streamReadUserId(streamId)
	self:run(connection)
end

function SleepRequestDeniedEvent:writeStream(streamId, connection)
	User.streamWriteUserId(streamId, self.userId)
end

function SleepRequestDeniedEvent:run(connection)
	if g_sleepManager ~= nil then
		g_sleepManager:onSleepRequestDenied(self.userId)
	end
end
