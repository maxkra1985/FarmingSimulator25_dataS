-- Local values: AnimatedVehicleStartEvent_mt
AnimatedVehicleStartEvent = {}
local AnimatedVehicleStartEvent_mt = Class(AnimatedVehicleStartEvent, Event)
InitStaticEventClass(AnimatedVehicleStartEvent, "AnimatedVehicleStartEvent")
function AnimatedVehicleStartEvent.emptyNew()
	-- upvalues: (copy) AnimatedVehicleStartEvent_mt
	return Event.new(AnimatedVehicleStartEvent_mt)
end

-- Local values: self
function AnimatedVehicleStartEvent.new(object, name, speed, animTime)
	local v6_ = AnimatedVehicleStartEvent.emptyNew()
	v6_.name = name
	v6_.speed = speed
	v6_.animTime = animTime
	v6_.object = object
	return v6_
end

function AnimatedVehicleStartEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.name = streamReadString(streamId)
	self.speed = streamReadFloat32(streamId)
	self.animTime = streamReadFloat32(streamId)
	self:run(connection)
end

function AnimatedVehicleStartEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteString(streamId, self.name)
	streamWriteFloat32(streamId, self.speed)
	streamWriteFloat32(streamId, self.animTime)
end

function AnimatedVehicleStartEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:playAnimation(self.name, self.speed, self.animTime, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(AnimatedVehicleStartEvent.new(self.object, self.name, self.speed, self.animTime), nil, connection, self.object)
	end
end
