-- Local values: AnimatedVehicleStopEvent_mt
AnimatedVehicleStopEvent = {}
local AnimatedVehicleStopEvent_mt = Class(AnimatedVehicleStopEvent, Event)
InitStaticEventClass(AnimatedVehicleStopEvent, "AnimatedVehicleStopEvent")
function AnimatedVehicleStopEvent.emptyNew()
	-- upvalues: (copy) AnimatedVehicleStopEvent_mt
	return Event.new(AnimatedVehicleStopEvent_mt)
end

-- Local values: self
function AnimatedVehicleStopEvent.new(object, name)
	local v4_ = AnimatedVehicleStopEvent.emptyNew()
	v4_.name = name
	v4_.object = object
	return v4_
end

function AnimatedVehicleStopEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.name = streamReadString(streamId)
	self:run(connection)
end

function AnimatedVehicleStopEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteString(streamId, self.name)
end

function AnimatedVehicleStopEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:stopAnimation(self.name, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(AnimatedVehicleStopEvent.new(self.object, self.name), nil, connection, self.object)
	end
end
