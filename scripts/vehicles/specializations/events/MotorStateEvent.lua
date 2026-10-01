MotorStateEvent = {}
local MotorStateEvent_mt = Class(MotorStateEvent, Event)
InitStaticEventClass(MotorStateEvent, "MotorStateEvent")
function MotorStateEvent.emptyNew()
	local self = Event.new(MotorStateEvent_mt)
	return self
end
function MotorStateEvent.new(vehicle, motorState)
	local self = MotorStateEvent.emptyNew()
	self.vehicle = vehicle
	self.motorState = motorState
	return self
end
function MotorStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.motorState = MotorState.readStream(streamId)
	self:run(connection)
end
function MotorStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	MotorState.writeStream(streamId, self.motorState)
end
function MotorStateEvent:run(connection)
	local vehicle = self.vehicle
	if vehicle ~= nil and vehicle:getIsSynchronized() then
		vehicle:setMotorState(self.motorState, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(MotorStateEvent.new(self.vehicle, self.motorState), nil, connection, self.vehicle)
	end
end
function MotorStateEvent.sendEvent(vehicle, motorState, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(MotorStateEvent.new(vehicle, motorState), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(MotorStateEvent.new(vehicle, motorState))
	end
end
