-- Local values: VehicleSetLightEvent_mt
VehicleSetLightEvent = {}
local VehicleSetLightEvent_mt = Class(VehicleSetLightEvent, Event)
InitStaticEventClass(VehicleSetLightEvent, "VehicleSetLightEvent")
function VehicleSetLightEvent.emptyNew()
	-- upvalues: (copy) VehicleSetLightEvent_mt
	return Event.new(VehicleSetLightEvent_mt)
end

-- Local values: self
function VehicleSetLightEvent.new(object, lightsTypesMask, numBits)
	local v5_ = VehicleSetLightEvent.emptyNew()
	v5_.object = object
	v5_.lightsTypesMask = lightsTypesMask
	v5_.numBits = numBits
	return v5_
end

function VehicleSetLightEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.numBits = streamReadUIntN(streamId, 5)
	self.lightsTypesMask = streamReadUIntN(streamId, self.numBits)
	self:run(connection)
end

function VehicleSetLightEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.numBits, 5)
	streamWriteUIntN(streamId, self.lightsTypesMask, self.numBits)
end

function VehicleSetLightEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setLightsTypesMask(self.lightsTypesMask, true, true)
	end
	if not connection:getIsServer() then
		g_server:broadcastEvent(VehicleSetLightEvent.new(self.object, self.lightsTypesMask, self.numBits), nil, connection, self.object)
	end
end
