-- Local values: PlayerSetFarmEvent_mt
source("dataS/scripts/player/events/PlayerSetFarmAnswerEvent.lua")
PlayerSetFarmEvent = {}
local PlayerSetFarmEvent_mt = Class(PlayerSetFarmEvent, Event)
InitStaticEventClass(PlayerSetFarmEvent, "PlayerSetFarmEvent")
function PlayerSetFarmEvent.emptyNew()
	-- upvalues: (copy) PlayerSetFarmEvent_mt
	return Event.new(PlayerSetFarmEvent_mt)
end

-- Local values: self
function PlayerSetFarmEvent.new(player, farmId, password)
	local v5_ = PlayerSetFarmEvent.emptyNew()
	v5_.player = player
	v5_.farmId = farmId
	v5_.password = password
	return v5_
end

function PlayerSetFarmEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	if self.password == nil then
		streamWriteBool(streamId, false)
	else
		streamWriteBool(streamId, true)
		streamWriteString(streamId, self.password)
	end
end

function PlayerSetFarmEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	if streamReadBool(streamId) then
		self.password = streamReadString(streamId)
	end
	self:run(connection)
end

-- Local values: oldFarmId, oldFarm, farm, user
function PlayerSetFarmEvent:run(connection)
	if connection:getIsServer() then
		self.player.farmId = self.farmId
		if self.player.playerHotspot ~= nil then
			self.player.playerHotspot:setOwnerFarmId(self.farmId)
		end
		g_messageCenter:publish(MessageType.PLAYER_FARM_CHANGED, self.player)
	else
		local v13_ = self.player.farmId
		local v14_ = g_farmManager:getFarmById(v13_)
		local v15_ = g_farmManager:getFarmById(self.farmId)
		if v15_ ~= nil then
			local v16_ = g_currentMission.userManager:getUserByUserId(self.player.userId)
			if v16_:getIsMasterUser() or (v15_.password == nil or v15_.password == self.password) then
				v14_:removeUser(v16_:getId())
				self.player:setFarmId(self.farmId)
				v15_:addUser(v16_:getId(), v16_:getUniqueUserId(), v16_:getIsMasterUser())
				if self.player.playerHotspot ~= nil then
					self.player.playerHotspot:setOwnerFarmId(self.farmId)
				end
				g_messageCenter:publish(MessageType.PLAYER_FARM_CHANGED, self.player)
				v16_:setFinancesVersionCounter(0)
				connection:sendEvent(PlayerSetFarmAnswerEvent.new(PlayerSetFarmAnswerEvent.STATE.OK, self.farmId, self.password))
				g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(v13_, self.farmId, v16_:getId()))
			else
				connection:sendEvent(PlayerSetFarmAnswerEvent.new(PlayerSetFarmAnswerEvent.STATE.PASSWORD_REQUIRED, self.farmId))
			end
		end
	end
end

function PlayerSetFarmEvent.sendEvent(player, farmId, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlayerSetFarmEvent.new(player, farmId), nil, nil, player)
			return
		end
		g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(player, farmId))
	end
end
