-- Local values: PlayerSetNicknameEvent_mt
PlayerSetNicknameEvent = {}
local PlayerSetNicknameEvent_mt = Class(PlayerSetNicknameEvent, Event)
InitStaticEventClass(PlayerSetNicknameEvent, "PlayerSetNicknameEvent")
function PlayerSetNicknameEvent.emptyNew()
	-- upvalues: (copy) PlayerSetNicknameEvent_mt
	return Event.new(PlayerSetNicknameEvent_mt)
end

-- Local values: self
function PlayerSetNicknameEvent.new(player, nickname, userId)
	local v5_ = PlayerSetNicknameEvent.emptyNew()
	v5_.player = player
	v5_.nickname = nickname
	v5_.userId = userId
	return v5_
end

function PlayerSetNicknameEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteString(streamId, self.nickname)
	User.streamWriteUserId(streamId, self.userId)
end

function PlayerSetNicknameEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.nickname = streamReadString(streamId)
	self.userId = User.streamReadUserId(streamId)
	self:run(connection)
end

function PlayerSetNicknameEvent:run(connection)
	if connection:getIsServer() then
		g_currentMission:setPlayerNickname(self.player, self.nickname, self.userId, true)
	else
		g_currentMission:setPlayerNickname(self.player, self.nickname, self.userId)
	end
end
