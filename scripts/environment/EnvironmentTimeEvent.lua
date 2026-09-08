-- Local values: EnvironmentTimeEvent_mt
EnvironmentTimeEvent = {}
local EnvironmentTimeEvent_mt = Class(EnvironmentTimeEvent, Event)
InitStaticEventClass(EnvironmentTimeEvent, "EnvironmentTimeEvent")
function EnvironmentTimeEvent.emptyNew()
	-- upvalues: (copy) EnvironmentTimeEvent_mt
	return Event.new(EnvironmentTimeEvent_mt)
end

-- Local values: self
function EnvironmentTimeEvent.new(newMonotonicDay, currentDay, dayTime, daysPerPeriod)
	local v6_ = EnvironmentTimeEvent.emptyNew()
	v6_.newMonotonicDay = newMonotonicDay
	v6_.currentDay = currentDay
	v6_.dayTime = dayTime
	v6_.daysPerPeriod = daysPerPeriod
	return v6_
end

function EnvironmentTimeEvent:readStream(streamId, connection)
	self.currentDay = streamReadInt32(streamId)
	self.daysPerPeriod = streamReadUIntN(streamId, 5)
	self.newMonotonicDay = streamReadInt32(streamId)
	self.dayTime = streamReadFloat32(streamId)
	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		g_currentMission.environment:setEnvironmentTime(self.newMonotonicDay, self.currentDay, self.dayTime, self.daysPerPeriod, false)
	end
end

function EnvironmentTimeEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.currentDay)
	streamWriteUIntN(streamId, self.daysPerPeriod, 5)
	streamWriteInt32(streamId, self.newMonotonicDay)
	streamWriteFloat32(streamId, self.dayTime)
end

function EnvironmentTimeEvent:run(connection)
	print("The server should not receive a dayTime update")
end
function EnvironmentTimeEvent.broadcastEvent()
	local v11_ = g_currentMission.environment
	local v12_ = EnvironmentTimeEvent.new(v11_.currentMonotonicDay, v11_.currentDay, v11_.dayTime, v11_.daysPerPeriod)
	g_server:broadcastEvent(v12_)
end
