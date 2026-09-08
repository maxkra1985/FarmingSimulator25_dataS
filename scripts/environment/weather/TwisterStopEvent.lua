-- Local values: TwisterStopEvent_mt
TwisterStopEvent = {}
local TwisterStopEvent_mt = Class(TwisterStopEvent, Event)
InitStaticEventClass(TwisterStopEvent, "TwisterStopEvent")
function TwisterStopEvent.emptyNew()
	-- upvalues: (copy) TwisterStopEvent_mt
	return Event.new(TwisterStopEvent_mt)
end
function TwisterStopEvent.new()
	return TwisterStopEvent.emptyNew()
end

function TwisterStopEvent:readStream(streamId, connection)
	self:run(connection)
end

function TwisterStopEvent:writeStream(streamId, connection) end

-- Local values: weather
function TwisterStopEvent:run(connection)
	local v4_ = g_currentMission.environment.weather
	if v4_.twister ~= nil then
		v4_.twister:despawn()
	end
end
