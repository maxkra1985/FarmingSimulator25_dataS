-- Local values: WearableRepaintEvent_mt
WearableRepaintEvent = {}
local WearableRepaintEvent_mt = Class(WearableRepaintEvent, Event)
InitStaticEventClass(WearableRepaintEvent, "WearableRepaintEvent")
function WearableRepaintEvent.emptyNew()
	-- upvalues: (copy) WearableRepaintEvent_mt
	return Event.new(WearableRepaintEvent_mt)
end

-- Local values: self
function WearableRepaintEvent.new(vehicle)
	local v3_ = WearableRepaintEvent.emptyNew()
	v3_.vehicle = vehicle
	return v3_
end

function WearableRepaintEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end

function WearableRepaintEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end

function WearableRepaintEvent:run(connection)
	if self.vehicle ~= nil and (self.vehicle:getIsSynchronized() and self.vehicle.repaintVehicle ~= nil) then
		self.vehicle:repaintVehicle()
		if not connection:getIsServer() then
			g_server:broadcastEvent(self)
		end
		g_messageCenter:publish(MessageType.VEHICLE_REPAINTED, self.vehicle)
	end
end
