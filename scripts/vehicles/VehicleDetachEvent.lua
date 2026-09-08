-- Local values: VehicleDetachEvent_mt
VehicleDetachEvent = {}
local VehicleDetachEvent_mt = Class(VehicleDetachEvent, Event)
InitStaticEventClass(VehicleDetachEvent, "VehicleDetachEvent")
function VehicleDetachEvent.emptyNew()
	-- upvalues: (copy) VehicleDetachEvent_mt
	return Event.new(VehicleDetachEvent_mt)
end

-- Local values: self
function VehicleDetachEvent.new(vehicle, implement)
	local v4_ = VehicleDetachEvent.emptyNew()
	v4_.implement = implement
	v4_.vehicle = vehicle
	return v4_
end

function VehicleDetachEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.implement = NetworkUtil.readNodeObject(streamId)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		if connection:getIsServer() then
			self.vehicle:detachImplementByObject(self.implement, true)
			return
		end
		self.vehicle:detachImplementByObject(self.implement)
	end
end

function VehicleDetachEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	NetworkUtil.writeNodeObject(streamId, self.implement)
end

function VehicleDetachEvent:run(connection) end
