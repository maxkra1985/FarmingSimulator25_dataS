-- Local values: PlayerSwitchedFarmEvent_mt
PlayerSwitchedFarmEvent = {}
local PlayerSwitchedFarmEvent_mt = Class(PlayerSwitchedFarmEvent, Event)
InitStaticEventClass(PlayerSwitchedFarmEvent, "PlayerSwitchedFarmEvent")
PlayerSwitchedFarmEvent.NO_FARM = 126
function PlayerSwitchedFarmEvent.emptyNew()
	-- upvalues: (copy) PlayerSwitchedFarmEvent_mt
	return Event.new(PlayerSwitchedFarmEvent_mt)
end

-- Local values: self
function PlayerSwitchedFarmEvent.new(oldFarmId, farmId, userId)
	local v5_ = PlayerSwitchedFarmEvent.emptyNew()
	v5_.farmId = farmId
	v5_.oldFarmId = oldFarmId
	v5_.userId = userId
	return v5_
end

function PlayerSwitchedFarmEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteUIntN(streamId, self.oldFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	User.streamWriteUserId(streamId, self.userId)
end

function PlayerSwitchedFarmEvent:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.oldFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.userId = User.streamReadUserId(streamId)
	self:run(connection)
end

-- Local values: oldFarm, newFarm, player
function PlayerSwitchedFarmEvent:run(connection)
	if connection:getIsServer() then
		if self.oldFarmId ~= FarmManager.INVALID_FARM_ID then
			local v13_ = g_farmManager:getFarmById(self.oldFarmId)
			if v13_ ~= nil then
				v13_:removeUser(self.userId)
			end
		end
		if self.farmId ~= FarmManager.INVALID_FARM_ID then
			local v14_ = g_farmManager:getFarmById(self.farmId)
			if v14_ ~= nil then
				v14_:addUser(self.userId)
			end
		end
		local v15_ = g_currentMission.playerSystem:getPlayerByUserId(self.userId)
		g_messageCenter:publish(MessageType.PLAYER_FARM_CHANGED, v15_)
	else
		g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(self.oldFarmId, self.farmId, self.userId), true)
	end
end
