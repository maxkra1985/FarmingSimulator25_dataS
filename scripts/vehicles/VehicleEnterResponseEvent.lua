-- Local values: VehicleEnterResponseEvent_mt
VehicleEnterResponseEvent = {}
local VehicleEnterResponseEvent_mt = Class(VehicleEnterResponseEvent, Event)
InitStaticEventClass(VehicleEnterResponseEvent, "VehicleEnterResponseEvent")
function VehicleEnterResponseEvent.emptyNew()
	-- upvalues: (copy) VehicleEnterResponseEvent_mt
	return Event.new(VehicleEnterResponseEvent_mt, NetworkNode.CHANNEL_MAIN)
end

-- Local values: self
function VehicleEnterResponseEvent.new(id, isOwner, playerStyle, farmId, userId)
	local v7_ = VehicleEnterResponseEvent.emptyNew()
	v7_.id = id
	v7_.isOwner = isOwner
	v7_.playerStyle = playerStyle
	v7_.farmId = farmId
	v7_.userId = userId
	return v7_
end

function VehicleEnterResponseEvent:readStream(streamId, connection)
	self.id = NetworkUtil.readNodeObjectId(streamId)
	self.isOwner = streamReadBool(streamId)
	if self.playerStyle == nil then
		self.playerStyle = PlayerStyle.new()
	end
	self.playerStyle:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.userId = User.streamReadUserId(streamId)
	self:run(connection)
end

function VehicleEnterResponseEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObjectId(streamId, self.id)
	streamWriteBool(streamId, self.isOwner)
	self.playerStyle:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	User.streamWriteUserId(streamId, self.userId)
end

-- Local values: vehicle, player
function VehicleEnterResponseEvent:run(connection)
	local v15_ = NetworkUtil.getObject(self.id)
	if v15_ == nil then
		Logging.devWarning("VehicleEnterResponseEvent: Vehicle \'%s\' not found. Skip entering", self.id)
		return
	elseif v15_:getIsSynchronized() then
		local v16_ = g_currentMission.playerSystem:getPlayerByUserId(self.userId)
		if v16_ == nil then
			Logging.devWarning("VehicleEnterResponseEvent: Player \'%s\' not found. Skip entering", self.userId)
		else
			v16_:onEnterVehicle(v15_)
		end
	else
		Logging.devWarning("VehicleEnterResponseEvent: Vehicle \'%s\' not synchronized. Skip entering", v15_.configFileName)
		return
	end
end
