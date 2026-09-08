-- Local values: WearableRepairEvent_mt
WearableRepairEvent = {}
local WearableRepairEvent_mt = Class(WearableRepairEvent, Event)
InitStaticEventClass(WearableRepairEvent, "WearableRepairEvent")
function WearableRepairEvent.emptyNew()
	-- upvalues: (copy) WearableRepairEvent_mt
	return Event.new(WearableRepairEvent_mt)
end

-- Local values: self
function WearableRepairEvent.new(vehicle, atSellingPoint)
	local v4_ = WearableRepairEvent.emptyNew()
	v4_.vehicle = vehicle
	v4_.atSellingPoint = atSellingPoint
	return v4_
end

function WearableRepairEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.atSellingPoint = streamReadBool(streamId)
	self:run(connection)
end

function WearableRepairEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.atSellingPoint)
end

function WearableRepairEvent:run(connection)
	if self.vehicle ~= nil and (self.vehicle:getIsSynchronized() and self.vehicle.repairVehicle ~= nil) then
		self.vehicle:repairVehicle(self.atSellingPoint)
		if not connection:getIsServer() then
			g_server:broadcastEvent(self)
		end
		g_messageCenter:publish(MessageType.VEHICLE_REPAIRED, self.vehicle, self.atSellingPoint)
	end
end
