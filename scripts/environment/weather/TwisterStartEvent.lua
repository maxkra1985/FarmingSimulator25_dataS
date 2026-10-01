TwisterStartEvent = {}
local TwisterStartEvent_mt = Class(TwisterStartEvent, Event)
InitStaticEventClass(TwisterStartEvent, "TwisterStartEvent")
function TwisterStartEvent.emptyNew()
	return Event.new(TwisterStartEvent_mt)
end
function TwisterStartEvent.new(x, z, metersPerHour)
	local self = TwisterStartEvent.emptyNew()
	self.x = x
	self.z = z
	self.metersPerHour = metersPerHour
	return self
end
function TwisterStartEvent:readStream(streamId, connection)
	local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
	if streamReadBool(streamId) then
		self.x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		self.z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
	end
	self:run(connection)
end
function TwisterStartEvent:writeStream(streamId, connection)
	local paramsXZ = g_currentMission.vehicleXZPosCompressionParams
	if streamWriteBool(streamId, self.x ~= nil) then
		NetworkUtil.writeCompressedWorldPosition(streamId, self.x, paramsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, self.z, paramsXZ)
	end
end
function TwisterStartEvent:run(connection)
	local weather = g_currentMission.environment.weather
	if weather.twister ~= nil then
		weather.twister:spawn(self.x, self.z, self.metersPerHour)
	end
end
