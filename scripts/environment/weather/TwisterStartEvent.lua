-- Local values: TwisterStartEvent_mt
TwisterStartEvent = {}
local TwisterStartEvent_mt = Class(TwisterStartEvent, Event)
InitStaticEventClass(TwisterStartEvent, "TwisterStartEvent")
function TwisterStartEvent.emptyNew()
	-- upvalues: (copy) TwisterStartEvent_mt
	return Event.new(TwisterStartEvent_mt)
end

-- Local values: self
function TwisterStartEvent.new(x, z, metersPerHour)
	local v5_ = TwisterStartEvent.emptyNew()
	v5_.x = x
	v5_.z = z
	v5_.metersPerHour = metersPerHour
	return v5_
end

-- Local values: paramsXZ
function TwisterStartEvent:readStream(streamId, connection)
	local v9_ = g_currentMission.vehicleXZPosCompressionParams
	if streamReadBool(streamId) then
		self.x = NetworkUtil.readCompressedWorldPosition(streamId, v9_)
		self.z = NetworkUtil.readCompressedWorldPosition(streamId, v9_)
	end
	self:run(connection)
end

-- Local values: paramsXZ
function TwisterStartEvent:writeStream(streamId, connection)
	local v12_ = g_currentMission.vehicleXZPosCompressionParams
	if streamWriteBool(streamId, self.x ~= nil) then
		NetworkUtil.writeCompressedWorldPosition(streamId, self.x, v12_)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.z, v12_)
	end
end

-- Local values: weather
function TwisterStartEvent:run(connection)
	local v14_ = g_currentMission.environment.weather
	if v14_.twister ~= nil then
		v14_.twister:spawn(self.x, self.z, self.metersPerHour)
	end
end
