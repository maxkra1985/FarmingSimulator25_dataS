-- Local values: VehicleLeaveEvent_mt
VehicleLeaveEvent = {}
local VehicleLeaveEvent_mt = Class(VehicleLeaveEvent, Event)
InitStaticEventClass(VehicleLeaveEvent, "VehicleLeaveEvent")
function VehicleLeaveEvent.emptyNew()
	-- upvalues: (copy) VehicleLeaveEvent_mt
	return Event.new(VehicleLeaveEvent_mt, NetworkNode.CHANNEL_MAIN)
end

-- Local values: self
function VehicleLeaveEvent.new(vehicle, userId)
	local v4_ = VehicleLeaveEvent.emptyNew()
	v4_.vehicle = vehicle
	v4_.userId = userId
	return v4_
end

function VehicleLeaveEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.userId = User.streamReadUserId(streamId)
	self:run(connection)
end

function VehicleLeaveEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	User.streamWriteUserId(streamId, self.userId)
end

-- Local values: player
function VehicleLeaveEvent:run(connection)
	if self.vehicle == nil or not self.vehicle:getIsSynchronized() then
		Logging.devInfo("VehicleLeaveEvent.run: Vehicle not found or not synchronized yet")
	else
		if not connection:getIsServer() then
			if self.vehicle:getOwnerConnection() ~= nil then
				self.vehicle:setOwnerConnection(nil)
				self.vehicle.controllerFarmId = nil
			end
			g_server:broadcastEvent(VehicleLeaveEvent.new(self.vehicle, self.userId), nil, connection, self.vehicle)
		end
		local v12_ = g_currentMission.playerSystem:getPlayerByUserId(self.userId)
		if v12_ ~= nil then
			v12_:leaveVehicle(self.vehicle, true)
		end
	end
end

function VehicleLeaveEvent.sendEvent(vehicle, userId, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(VehicleLeaveEvent.new(vehicle, userId), nil, nil, vehicle)
			return
		end
		g_client:getServerConnection():sendEvent(VehicleLeaveEvent.new(vehicle, userId))
	end
end
