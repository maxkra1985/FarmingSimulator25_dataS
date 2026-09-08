-- Local values: PlayerTeleportEvent_mt
PlayerTeleportEvent = {}
local PlayerTeleportEvent_mt = Class(PlayerTeleportEvent, Event)
InitStaticEventClass(PlayerTeleportEvent, "PlayerTeleportEvent")
function PlayerTeleportEvent.emptyNew()
	-- upvalues: (copy) PlayerTeleportEvent_mt
	return Event.new(PlayerTeleportEvent_mt, NetworkNode.CHANNEL_MAIN)
end

-- Local values: self
function PlayerTeleportEvent.new(x, y, z, isAbsolute, isRootNode)
	local v7_ = PlayerTeleportEvent.emptyNew()
	v7_.x = x
	v7_.y = y
	v7_.z = z
	v7_.isAbsolute = isAbsolute
	v7_.isRootNode = isRootNode
	return v7_
end

-- Local values: self
function PlayerTeleportEvent.newExitVehicle(exitVehicle)
	local v9_ = PlayerTeleportEvent.emptyNew()
	v9_.exitVehicle = exitVehicle
	return v9_
end

function PlayerTeleportEvent:readStream(streamId, connection)
	if streamReadBool(streamId) then
		self.exitVehicle = NetworkUtil.readNodeObject(streamId)
	else
		self.x = streamReadFloat32(streamId)
		self.y = streamReadFloat32(streamId)
		self.z = streamReadFloat32(streamId)
		self.isAbsolute = streamReadBool(streamId)
		self.isRootNode = streamReadBool(streamId)
	end
	self:run(connection)
end

function PlayerTeleportEvent:writeStream(streamId, connection)
	if streamWriteBool(streamId, self.exitVehicle ~= nil) then
		NetworkUtil.writeNodeObject(streamId, self.exitVehicle)
	else
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
		streamWriteBool(streamId, self.isAbsolute)
		streamWriteBool(streamId, self.isRootNode)
	end
end

-- Local values: player
function PlayerTeleportEvent:run(connection)
	if not connection:getIsServer() then
		local v17_ = g_currentMission.connectionsToPlayer[connection]
		if v17_ ~= nil then
			if self.exitVehicle ~= nil then
				v17_:teleportToExitPoint(self.exitVehicle, true)
				return
			end
			if self.x ~= nil then
				v17_:teleportTo(self.x, self.y, self.z, true, true)
			end
		end
	end
end
