-- Local values: NPCConversationItemShowEvent_mt
NPCConversationItemShowEvent = {}
local NPCConversationItemShowEvent_mt = Class(NPCConversationItemShowEvent, Event)
InitStaticEventClass(NPCConversationItemShowEvent, "NPCConversationItemShowEvent")
function NPCConversationItemShowEvent.emptyNew()
	-- upvalues: (copy) NPCConversationItemShowEvent_mt
	return Event.new(NPCConversationItemShowEvent_mt)
end

-- Local values: self
function NPCConversationItemShowEvent.new(npc, conversationItemIndex, disabledOptionIndices)
	local v5_ = NPCConversationItemShowEvent.emptyNew()
	v5_.npc = npc
	v5_.conversationItemIndex = conversationItemIndex
	v5_.disabledOptionIndices = disabledOptionIndices
	return v5_
end

-- Local values: _, index
function NPCConversationItemShowEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.npc)
		streamWriteUIntN(streamId, self.conversationItemIndex, NPC.CONVERSATION_ITEM_INDEX_SEND_NUM_BITS)
		streamWriteUIntN(streamId, #self.disabledOptionIndices, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
		for _, v9_ in ipairs(self.disabledOptionIndices) do
			streamWriteUIntN(streamId, v9_, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
		end
	end
end

-- Local values: numIndices, i, index
function NPCConversationItemShowEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.npc = NetworkUtil.readNodeObject(streamId)
		self.conversationItemIndex = streamReadUIntN(streamId, NPC.CONVERSATION_ITEM_INDEX_SEND_NUM_BITS)
		self.disabledOptionIndices = {}
		for _ = 1, streamReadUIntN(streamId, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS) do
			local v13_ = streamReadUIntN(streamId, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
			local v14_ = self.disabledOptionIndices
			table.insert(v14_, v13_)
		end
	end
	self:run(connection)
end

function NPCConversationItemShowEvent:run(connection)
	if connection:getIsServer() and self.npc ~= nil then
		self.npc:onConversationShowItem(self.conversationItemIndex, self.disabledOptionIndices)
	end
end
