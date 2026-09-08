-- Local values: VehicleRemoveEvent_mt
VehicleRemoveEvent = {}
local VehicleRemoveEvent_mt = Class(VehicleRemoveEvent, Event)
InitStaticEventClass(VehicleRemoveEvent, "VehicleRemoveEvent")
function VehicleRemoveEvent.emptyNew()
	-- upvalues: (copy) VehicleRemoveEvent_mt
	return Event.new(VehicleRemoveEvent_mt)
end

-- Local values: self
function VehicleRemoveEvent.new(vehicle)
	local v3_ = VehicleRemoveEvent.emptyNew()
	v3_.vehicle = vehicle
	local v4_ = g_server == nil
	assert(v4_, "Client->Server event")
	return v3_
end

function VehicleRemoveEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function VehicleRemoveEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end

function VehicleRemoveEvent:run(connection)
	self.vehicle:delete()
end
