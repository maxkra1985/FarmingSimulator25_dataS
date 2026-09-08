-- Local values: NPCConversationStartFailedEvent_mt
NPCConversationStartFailedEvent = {}
local NPCConversationStartFailedEvent_mt = Class(NPCConversationStartFailedEvent, Event)
InitStaticEventClass(NPCConversationStartFailedEvent, "NPCConversationStartFailedEvent")
function NPCConversationStartFailedEvent.emptyNew()
	-- upvalues: (copy) NPCConversationStartFailedEvent_mt
	return Event.new(NPCConversationStartFailedEvent_mt)
end

-- Local values: self
function NPCConversationStartFailedEvent.new(npc, failedState)
	local v4_ = NPCConversationStartFailedEvent.emptyNew()
	v4_.npc = npc
	v4_.failedState = failedState
	return v4_
end

function NPCConversationStartFailedEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.npc)
	NPCConversationFailedState.writeStream(streamId, self.failedState)
end

function NPCConversationStartFailedEvent:readStream(streamId, connection)
	self.npc = NetworkUtil.readNodeObject(streamId)
	self.failedState = NPCConversationFailedState.readStream(streamId)
	self:run(connection)
end

function NPCConversationStartFailedEvent:run(connection)
	if connection:getIsServer() and self.npc ~= nil then
		self.npc:onFailedToStartConversation(self.failedState)
	end
end
