TwisterStopEvent = {}
local TwisterStopEvent_mt = Class(TwisterStopEvent, Event)
InitStaticEventClass(TwisterStopEvent, "TwisterStopEvent")
function TwisterStopEvent.emptyNew()
	return Event.new(TwisterStopEvent_mt)
end
function TwisterStopEvent.new()
	local self = TwisterStopEvent.emptyNew()
	return self
end
function TwisterStopEvent:readStream(streamId, connection)
	self:run(connection)
end
function TwisterStopEvent:writeStream(streamId, connection) end
function TwisterStopEvent:run(connection)
	local weather = g_currentMission.environment.weather
	if weather.twister ~= nil then
		weather.twister:despawn()
	end
end
