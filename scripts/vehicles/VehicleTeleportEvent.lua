-- Local values: VehicleTeleportEvent_mt
VehicleTeleportEvent = {}
local VehicleTeleportEvent_mt = Class(VehicleTeleportEvent, Event)
InitStaticEventClass(VehicleTeleportEvent, "VehicleTeleportEvent")
function VehicleTeleportEvent.emptyNew()
	-- upvalues: (copy) VehicleTeleportEvent_mt
	return Event.new(VehicleTeleportEvent_mt, NetworkNode.CHANNEL_MAIN)
end

-- Local values: self
function VehicleTeleportEvent.new(vehicle, x, z, rotY)
	local v6_ = VehicleTeleportEvent.emptyNew()
	v6_.vehicle = vehicle
	v6_.x = x
	v6_.z = z
	v6_.rotY = rotY
	return v6_
end

function VehicleTeleportEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteFloat32(streamId, self.x)
	streamWriteFloat32(streamId, self.z)
	streamWriteFloat32(streamId, self.rotY)
end

function VehicleTeleportEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.x = streamReadFloat32(streamId)
	self.z = streamReadFloat32(streamId)
	self.rotY = streamReadFloat32(streamId)
	self:run(connection)
end

function VehicleTeleportEvent:run(connection)
	if not connection:getIsServer() and (self.vehicle ~= nil and self.vehicle:getIsSynchronized()) then
		g_currentMission:teleportVehicle(self.vehicle, self.x, self.z, self.rotY)
	end
end
