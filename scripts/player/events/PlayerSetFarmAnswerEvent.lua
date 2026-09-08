-- Local values: PlayerSetFarmAnswerEvent_mt
PlayerSetFarmAnswerEvent = {}
local PlayerSetFarmAnswerEvent_mt = Class(PlayerSetFarmAnswerEvent, Event)
InitStaticEventClass(PlayerSetFarmAnswerEvent, "PlayerSetFarmAnswerEvent")
PlayerSetFarmAnswerEvent.STATE = {
	["OK"] = 1,
	["PASSWORD_REQUIRED"] = 2
}
PlayerSetFarmAnswerEvent.SEND_NUM_BITS = 2
function PlayerSetFarmAnswerEvent.emptyNew()
	-- upvalues: (copy) PlayerSetFarmAnswerEvent_mt
	return Event.new(PlayerSetFarmAnswerEvent_mt)
end

-- Local values: self
function PlayerSetFarmAnswerEvent.new(answerState, farmId, password)
	local v5_ = PlayerSetFarmAnswerEvent.emptyNew()
	v5_.answerState = answerState
	v5_.farmId = farmId
	v5_.password = password
	return v5_
end

-- Local values: passwordCorrect, passwordSet
function PlayerSetFarmAnswerEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.answerState, PlayerSetFarmAnswerEvent.SEND_NUM_BITS)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	local v8_ = self.answerState == PlayerSetFarmAnswerEvent.STATE.OK
	local v9_ = self.password ~= nil
	if streamWriteBool(streamId, v8_ and v9_) then
		streamWriteString(streamId, self.password)
	end
end

function PlayerSetFarmAnswerEvent:readStream(streamId, connection)
	self.answerState = streamReadUIntN(streamId, PlayerSetFarmAnswerEvent.SEND_NUM_BITS)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	if streamReadBool(streamId) then
		self.password = streamReadString(streamId)
	end
	self:run(connection)
end

function PlayerSetFarmAnswerEvent:run(connection)
	if connection:getIsServer() then
		if self.answerState == PlayerSetFarmAnswerEvent.STATE.OK then
			g_messageCenter:publish(PlayerSetFarmAnswerEvent, self.answerState, self.farmId, self.password)
		elseif self.answerState == PlayerSetFarmAnswerEvent.STATE.PASSWORD_REQUIRED then
			g_messageCenter:publish(PlayerSetFarmAnswerEvent, self.answerState, self.farmId)
		end
	else
		Logging.devWarning("PlayerSetFarmAnswerEvent is a server to client only event")
		return
	end
end
