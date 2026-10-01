NPCConversationCancelEvent = {}
local NPCConversationCancelEvent_mt = Class(NPCConversationCancelEvent, Event)
InitStaticEventClass(NPCConversationCancelEvent, "NPCConversationCancelEvent")
function NPCConversationCancelEvent.emptyNew()
	local self = Event.new(NPCConversationCancelEvent_mt)
	return self
end
function NPCConversationCancelEvent.new(npc)
	local self = NPCConversationCancelEvent.emptyNew()
	self.npc = npc
	return self
end
function NPCConversationCancelEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.npc)
end
function NPCConversationCancelEvent:readStream(streamId, connection)
	self.npc = NetworkUtil.readNodeObject(streamId)
	self:run(connection)
end
function NPCConversationCancelEvent:run(connection)
	if self.npc ~= nil then
		if connection:getIsServer() then
			self.npc:onCanceledConversation()
			return
		end
		self.npc:cancelConversation(connection)
	end
end
