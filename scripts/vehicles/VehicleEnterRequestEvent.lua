-- Local values: VehicleEnterRequestEvent_mt
VehicleEnterRequestEvent = {}
local VehicleEnterRequestEvent_mt = Class(VehicleEnterRequestEvent, Event)
InitStaticEventClass(VehicleEnterRequestEvent, "VehicleEnterRequestEvent")
function VehicleEnterRequestEvent.emptyNew()
	-- upvalues: (copy) VehicleEnterRequestEvent_mt
	return Event.new(VehicleEnterRequestEvent_mt, NetworkNode.CHANNEL_MAIN)
end

-- Local values: self
function VehicleEnterRequestEvent.new(object, playerStyle, farmId, force)
	local v6_ = VehicleEnterRequestEvent.emptyNew()
	v6_.object = object
	v6_.objectId = NetworkUtil.getObjectId(v6_.object)
	v6_.farmId = farmId
	v6_.playerStyle = playerStyle
	v6_.force = Utils.getNoNil(force, false)
	return v6_
end

function VehicleEnterRequestEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObjectId(streamId, self.objectId)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.playerStyle:writeStream(streamId, connection)
	streamWriteBool(streamId, self.force)
end

function VehicleEnterRequestEvent:readStream(streamId, connection)
	self.objectId = NetworkUtil.readNodeObjectId(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	if self.playerStyle == nil then
		self.playerStyle = PlayerStyle.new()
	end
	self.playerStyle:readStream(streamId, connection)
	self.force = streamReadBool(streamId)
	self.object = NetworkUtil.getObject(self.objectId)
	self:run(connection)
end

-- Local values: enterableSpec, userId
function VehicleEnterRequestEvent:run(connection)
	if self.object == nil or not self.object:getIsSynchronized() then
		return
	elseif self.force or g_server:hasGhostObject(connection, self.object) then
		local v15_ = self.object.spec_enterable
		if v15_ ~= nil and not v15_.isControlled then
			local v16_ = g_currentMission.userManager:getUserIdByConnection(connection)
			self.object:setOwnerConnection(connection)
			self.object.controllerFarmId = self.farmId
			self.object.controllerUserId = v16_
			g_server:broadcastEvent(VehicleEnterResponseEvent.new(self.objectId, false, self.playerStyle, self.farmId, v16_), true, connection)
			connection:sendEvent(VehicleEnterResponseEvent.new(self.objectId, true, self.playerStyle, self.farmId, v16_))
		end
	else
		Logging.warning("Vehicle %q is not fully synchronized to on client", self.object.configFileName)
		return
	end
end
