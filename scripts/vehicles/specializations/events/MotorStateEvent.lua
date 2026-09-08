-- Local values: MotorStateEvent_mt
MotorStateEvent = {}
local MotorStateEvent_mt = Class(MotorStateEvent, Event)
InitStaticEventClass(MotorStateEvent, "MotorStateEvent")
function MotorStateEvent.emptyNew()
	-- upvalues: (copy) MotorStateEvent_mt
	return Event.new(MotorStateEvent_mt)
end

-- Local values: self
function MotorStateEvent.new(vehicle, motorState)
	local v4_ = MotorStateEvent.emptyNew()
	v4_.vehicle = vehicle
	v4_.motorState = motorState
	return v4_
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

-- Local values: vehicle
function MotorStateEvent:run(connection)
	local v12_ = self.vehicle
	if v12_ ~= nil and v12_:getIsSynchronized() then
		v12_:setMotorState(self.motorState, true)
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
