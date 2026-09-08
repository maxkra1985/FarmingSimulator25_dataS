-- Local values: SetCruiseControlSpeedEvent_mt
SetCruiseControlSpeedEvent = {}
local SetCruiseControlSpeedEvent_mt = Class(SetCruiseControlSpeedEvent, Event)
InitStaticEventClass(SetCruiseControlSpeedEvent, "SetCruiseControlSpeedEvent")
function SetCruiseControlSpeedEvent.emptyNew()
	-- upvalues: (copy) SetCruiseControlSpeedEvent_mt
	return Event.new(SetCruiseControlSpeedEvent_mt)
end

-- Local values: self
function SetCruiseControlSpeedEvent.new(vehicle, speed, speedReverse)
	local v5_ = SetCruiseControlSpeedEvent.emptyNew()
	v5_.speed = speed
	v5_.speedReverse = speedReverse
	v5_.vehicle = vehicle
	return v5_
end

function SetCruiseControlSpeedEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.speed = streamReadUInt8(streamId)
	self.speedReverse = streamReadUInt8(streamId)
	self:run(connection)
end

function SetCruiseControlSpeedEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUInt8(streamId, self.speed)
	streamWriteUInt8(streamId, self.speedReverse)
end

function SetCruiseControlSpeedEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle)
	end
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setCruiseControlMaxSpeed(self.speed, self.speedReverse)
	end
end
