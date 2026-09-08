-- Local values: WeatherInitEvent_mt
WeatherAddObjectEvent = {}
local WeatherInitEvent_mt = Class(WeatherAddObjectEvent, Event)
InitStaticEventClass(WeatherAddObjectEvent, "WeatherAddObjectEvent")

-- Upvalues: WeatherInitEvent_mt
function WeatherAddObjectEvent.emptyNew(networkChannel)
	-- upvalues: (copy) WeatherInitEvent_mt
	return Event.new(WeatherInitEvent_mt, networkChannel)
end

-- Local values: networkChannel, self
function WeatherAddObjectEvent.new(instances, isInitialSync, finishTwister)
	local v6_
	if isInitialSync then
		v6_ = NetworkNode.CHANNEL_MAIN
	else
		v6_ = nil
	end
	local v7_ = WeatherAddObjectEvent.emptyNew(v6_)
	v7_.instances = instances
	v7_.isInitialSync = isInitialSync
	v7_.finishTwister = Utils.getNoNil(finishTwister, false)
	return v7_
end

-- Local values: numStates, _, instance, twister, twisterId
function WeatherAddObjectEvent:readStream(streamId, connection)
	self.instances = {}
	self.isInitialSync = streamReadBool(streamId)
	self.finishTwister = streamReadBool(streamId)
	for _ = 1, streamReadUIntN(streamId, Weather.SEND_BITS_NUM_OBJECTS) do
		local v11_ = WeatherInstance.new()
		v11_:readStream(streamId)
		local v12_ = self.instances
		table.insert(v12_, v11_)
	end
	if self.finishTwister then
		local v13_ = g_currentMission.environment.weather.twister
		if v13_ ~= nil then
			local v14_ = NetworkUtil.readNodeObjectId(streamId)
			v13_:readStream(streamId, connection)
			g_client:finishRegisterObject(v13_, v14_)
		end
	end
	self:run(connection)
end

-- Local values: _, instance, twister
function WeatherAddObjectEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.isInitialSync)
	streamWriteBool(streamId, self.finishTwister)
	streamWriteUIntN(streamId, #self.instances, Weather.SEND_BITS_NUM_OBJECTS)
	for _, v18_ in ipairs(self.instances) do
		v18_:writeStream(streamId, connection)
	end
	if self.finishTwister then
		local v19_ = g_currentMission.environment.weather.twister
		if v19_ ~= nil then
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(v19_))
			v19_:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, v19_)
		end
	end
end

-- Local values: weather, _, instance
function WeatherAddObjectEvent:run(connection)
	local v21_ = g_currentMission.environment.weather
	if self.isInitialSync then
		v21_.forecastItems = {}
	end
	for _, v22_ in ipairs(self.instances) do
		v21_:addWeatherForecast(v22_)
	end
	if self.isInitialSync then
		v21_:init()
	end
end
