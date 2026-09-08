-- Local values: ChatEvent_mt
ChatEvent = {}
local ChatEvent_mt = Class(ChatEvent, Event)
InitStaticEventClass(ChatEvent, "ChatEvent")
function ChatEvent.emptyNew()
	-- upvalues: (copy) ChatEvent_mt
	return Event.new(ChatEvent_mt, NetworkNode.CHANNEL_CHAT)
end

-- Local values: self
function ChatEvent.new(msg, sender, farmId, userId)
	local v6_ = ChatEvent.emptyNew()
	local v7_
	if msg == nil then
		v7_ = false
	else
		v7_ = sender ~= nil
	end
	assert(v7_, "ChatEvent msg and sender not valid")
	v6_.msg = filterText(msg, false, false)
	v6_.sender = sender
	v6_.farmId = farmId
	v6_.userId = userId
	return v6_
end

function ChatEvent:readStream(streamId, connection)
	self.msg = streamReadString(streamId)
	self.sender = streamReadString(streamId)
	self.userId = User.streamReadUserId(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self:run(connection)
end

function ChatEvent:writeStream(streamId, connection)
	streamWriteString(streamId, self.msg)
	streamWriteString(streamId, self.sender)
	User.streamWriteUserId(streamId, self.userId)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

-- Local values: fromUser, _, toUser
function ChatEvent:run(connection)
	g_currentMission:addChatMessage(self.sender, self.msg, self.farmId, self.userId)
	if not connection:getIsServer() then
		local v15_ = g_currentMission.userManager:getUserByUserId(self.userId)
		for _, v16_ in ipairs(g_currentMission.userManager:getUsers()) do
			if connection ~= v16_:getConnection() and not (v16_:getIsBlockedBy(v15_) or v16_:getConnection():getIsLocal()) then
				v16_:getConnection():sendEvent(self, false)
			end
		end
	end
end
