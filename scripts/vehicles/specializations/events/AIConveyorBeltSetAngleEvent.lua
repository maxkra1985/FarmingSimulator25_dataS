-- Local values: AIConveyorBeltSetAngleEvent_mt
AIConveyorBeltSetAngleEvent = {}
local AIConveyorBeltSetAngleEvent_mt = Class(AIConveyorBeltSetAngleEvent, Event)
InitStaticEventClass(AIConveyorBeltSetAngleEvent, "AIConveyorBeltSetAngleEvent")
function AIConveyorBeltSetAngleEvent.emptyNew()
	-- upvalues: (copy) AIConveyorBeltSetAngleEvent_mt
	return Event.new(AIConveyorBeltSetAngleEvent_mt)
end

-- Local values: self
function AIConveyorBeltSetAngleEvent.new(vehicle, currentAngle)
	local v4_ = AIConveyorBeltSetAngleEvent.emptyNew()
	v4_.currentAngle = currentAngle
	v4_.vehicle = vehicle
	return v4_
end

function AIConveyorBeltSetAngleEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.currentAngle = streamReadInt8(streamId)
	self:run(connection)
end

function AIConveyorBeltSetAngleEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteInt8(streamId, self.currentAngle)
end

function AIConveyorBeltSetAngleEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setAIConveyorBeltAngle(self.currentAngle, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(AIConveyorBeltSetAngleEvent.new(self.vehicle, self.currentAngle), nil, connection, self.vehicle)
	end
end
