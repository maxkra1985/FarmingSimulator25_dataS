-- Local values: WeatherInitEvent_mt
WeatherStateEvent = {}
local WeatherInitEvent_mt = Class(WeatherStateEvent, Event)
InitStaticEventClass(WeatherStateEvent, "WeatherStateEvent")
function WeatherStateEvent.emptyNew()
	-- upvalues: (copy) WeatherInitEvent_mt
	return Event.new(WeatherInitEvent_mt)
end

-- Local values: self
function WeatherStateEvent.new(snowHeight, timeSinceLastRain)
	local v4_ = WeatherStateEvent.emptyNew()
	v4_.snowHeight = snowHeight
	v4_.timeSinceLastRain = timeSinceLastRain
	return v4_
end

function WeatherStateEvent:readStream(streamId, connection)
	self.snowHeight = streamReadFloat32(streamId)
	self.timeSinceLastRain = streamReadFloat32(streamId)
	self:run(connection)
end

function WeatherStateEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.snowHeight)
	streamWriteFloat32(streamId, self.timeSinceLastRain)
end

function WeatherStateEvent:run(connection)
	g_currentMission.environment.weather:setInitialState(self.snowHeight, self.timeSinceLastRain)
end
