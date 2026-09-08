-- Local values: PlayerPermissionsEvent_mt
PlayerPermissionsEvent = {}
local PlayerPermissionsEvent_mt = Class(PlayerPermissionsEvent, Event)
InitStaticEventClass(PlayerPermissionsEvent, "PlayerPermissionsEvent")
function PlayerPermissionsEvent.emptyNew()
	-- upvalues: (copy) PlayerPermissionsEvent_mt
	return Event.new(PlayerPermissionsEvent_mt)
end

-- Local values: self
function PlayerPermissionsEvent.new(userId, permissions, isFarmManager)
	local v5_ = PlayerPermissionsEvent.emptyNew()
	v5_.userId = userId
	v5_.permissions = permissions
	v5_.isFarmManager = isFarmManager
	return v5_
end

-- Local values: _, permission
function PlayerPermissionsEvent:writeStream(streamId, connection)
	User.streamWriteUserId(streamId, self.userId)
	for _, v8_ in ipairs(Farm.PERMISSIONS) do
		streamWriteBool(streamId, self.permissions[v8_])
	end
	if streamWriteBool(streamId, self.isFarmManager ~= nil) then
		streamWriteBool(streamId, self.isFarmManager)
	end
end

-- Local values: _, permission
function PlayerPermissionsEvent:readStream(streamId, connection)
	self.userId = User.streamReadUserId(streamId)
	self.permissions = {}
	for _, v12_ in ipairs(Farm.PERMISSIONS) do
		self.permissions[v12_] = streamReadBool(streamId)
	end
	if streamReadBool(streamId) then
		self.isFarmManager = streamReadBool(streamId)
	end
	self:run(connection)
end

-- Local values: farm, player, farm, player
function PlayerPermissionsEvent:run(connection)
	if connection:getIsServer() then
		local v15_ = g_farmManager:getFarmByUserId(self.userId)
		local v16_ = v15_.userIdToPlayer[self.userId]
		if v16_ == nil then
			Logging.devWarning("PlayerPermissionsEvent: Could not resolve user id \'%s\' (farm %d) to player data", self.userId, v15_.farmId)
			return
		end
		v16_.permissions = self.permissions
		if self.isFarmManager ~= nil then
			v16_.isFarmManager = self.isFarmManager
		end
		g_messageCenter:publish(PlayerPermissionsEvent, self.userId)
	else
		local v17_ = g_farmManager:getFarmByUserId(self.userId)
		if g_currentMission:getHasPlayerPermission("manageRights", connection, v17_.farmId) then
			local v18_ = v17_.userIdToPlayer[self.userId]
			if v18_ == nil then
				Logging.devWarning("PlayerPermissionsEvent: Could not resolve user id \'%s\' (farm %d) to player data", self.userId, v17_.farmId)
			else
				v18_.permissions = self.permissions
				if self.isFarmManager ~= nil then
					v18_.isFarmManager = self.isFarmManager
				end
				g_server:broadcastEvent(self)
				g_messageCenter:publish(PlayerPermissionsEvent, self.userId)
			end
		end
	end
end

-- Local values: event, farm, player
function PlayerPermissionsEvent.sendEvent(userId, permissions, isFarmManager, noEventSend)
	if noEventSend == nil or noEventSend == false then
		local v23_ = PlayerPermissionsEvent.new(userId, permissions, isFarmManager)
		if g_server ~= nil then
			local v24_ = g_farmManager:getFarmByUserId(userId).userIdToPlayer[userId]
			g_server:broadcastEvent(v23_, nil, nil, v24_)
			return
		end
		g_client:getServerConnection():sendEvent(v23_)
	end
end
