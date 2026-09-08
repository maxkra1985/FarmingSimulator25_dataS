-- Local values: FogStateEvent_mt
FogStateEvent = {}
FogStateEvent.SEND_BITS_FOG_STATE = 6
FogStateEvent.SEND_BITS_FOG_FACTOR = 3
FogStateEvent.SEND_BITS_FOG_DURATION = 4
local FogStateEvent_mt = Class(FogStateEvent, Event)
InitStaticEventClass(FogStateEvent, "FogStateEvent")
function FogStateEvent.emptyNew()
	-- upvalues: (copy) FogStateEvent_mt
	return Event.new(FogStateEvent_mt)
end

-- Local values: self
function FogStateEvent.new(targetValue, lastMieScale, alpha, duration, nightFactor, dayFactor)
	local v8_ = FogStateEvent.emptyNew()
	v8_.targetValue = targetValue
	v8_.lastMieScale = lastMieScale
	v8_.alpha = alpha
	v8_.duration = duration
	v8_.nightFactor = nightFactor
	v8_.dayFactor = dayFactor
	return v8_
end

function FogStateEvent:readStream(streamId, connection)
	local v12_ = streamReadUIntN(streamId, FogStateEvent.SEND_BITS_FOG_STATE)
	local v13_ = FogStateEvent.SEND_BITS_FOG_STATE
	self.targetValue = v12_ * (1 / (math.pow(2, v13_) - 1)) * 200
	local v14_ = streamReadUIntN(streamId, FogStateEvent.SEND_BITS_FOG_STATE)
	local v15_ = FogStateEvent.SEND_BITS_FOG_STATE
	self.lastMieScale = v14_ * (1 / (math.pow(2, v15_) - 1)) * 200
	local v16_ = streamReadUIntN(streamId, FogStateEvent.SEND_BITS_FOG_STATE)
	local v17_ = FogStateEvent.SEND_BITS_FOG_STATE
	self.alpha = v16_ * (1 / (math.pow(2, v17_) - 1))
	self.duration = streamReadUIntN(streamId, FogStateEvent.SEND_BITS_FOG_DURATION)
	self.nightFactor = streamReadUIntN(streamId, FogStateEvent.SEND_BITS_FOG_FACTOR) * 0.25
	self.dayFactor = streamReadUIntN(streamId, FogStateEvent.SEND_BITS_FOG_FACTOR) * 0.25
	self:run(connection)
end

function FogStateEvent:writeStream(streamId, connection)
	local v20_ = streamWriteUIntN
	local v21_ = self.targetValue / 200
	local v22_ = FogStateEvent.SEND_BITS_FOG_STATE
	v20_(streamId, v21_ / (1 / (math.pow(2, v22_) - 1)), FogStateEvent.SEND_BITS_FOG_STATE)
	local v23_ = streamWriteUIntN
	local v24_ = self.lastMieScale / 200
	local v25_ = FogStateEvent.SEND_BITS_FOG_STATE
	v23_(streamId, v24_ / (1 / (math.pow(2, v25_) - 1)), FogStateEvent.SEND_BITS_FOG_STATE)
	local v26_ = streamWriteUIntN
	local v27_ = self.alpha
	local v28_ = FogStateEvent.SEND_BITS_FOG_STATE
	v26_(streamId, v27_ / (1 / (math.pow(2, v28_) - 1)), FogStateEvent.SEND_BITS_FOG_STATE)
	streamWriteUIntN(streamId, MathUtil.msToHours(self.duration), FogStateEvent.SEND_BITS_FOG_DURATION)
	streamWriteUIntN(streamId, self.nightFactor / 0.25, FogStateEvent.SEND_BITS_FOG_FACTOR)
	streamWriteUIntN(streamId, self.dayFactor / 0.25, FogStateEvent.SEND_BITS_FOG_FACTOR)
end

function FogStateEvent:run(connection)
	g_currentMission.environment.weather.fogUpdater:setTargetValues(self.targetValue, MathUtil.hoursToMs(self.duration))
	g_currentMission.environment.weather.fogUpdater.lastMieScale = self.lastMieScale
	g_currentMission.environment.weather.fogUpdater.alpha = self.alpha - 0.001
	g_currentMission.environment.weather.nightFactor = self.nightFactor
	g_currentMission.environment.weather.dayFactor = self.dayFactor
end
