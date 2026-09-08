-- Local values: NPCConversationStartEvent_mt
NPCConversationStartEvent = {}
local NPCConversationStartEvent_mt = Class(NPCConversationStartEvent, Event)
InitStaticEventClass(NPCConversationStartEvent, "NPCConversationStartEvent")
function NPCConversationStartEvent.emptyNew()
	-- upvalues: (copy) NPCConversationStartEvent_mt
	return Event.new(NPCConversationStartEvent_mt)
end

-- Local values: self
function NPCConversationStartEvent.new(npc, player, conversationIndex, conversationItemIndex, disabledOptionIndices, useFacialAnimation, isPhoneConversation)
	local v9_ = NPCConversationStartEvent.emptyNew()
	v9_.npc = npc
	v9_.player = player
	v9_.playerNetworkId = NetworkUtil.getObjectId(player)
	v9_.conversationIndex = conversationIndex
	v9_.conversationItemIndex = conversationItemIndex
	v9_.disabledOptionIndices = disabledOptionIndices
	v9_.useFacialAnimation = useFacialAnimation
	v9_.isPhoneConversation = isPhoneConversation
	return v9_
end

-- Local values: _, index
function NPCConversationStartEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.npc)
		NetworkUtil.writeNodeObject(streamId, self.player)
		streamWriteUIntN(streamId, self.conversationIndex, NPC.CONVERSATION_INDEX_SEND_NUM_BITS)
		streamWriteUIntN(streamId, self.conversationItemIndex, NPC.CONVERSATION_ITEM_INDEX_SEND_NUM_BITS)
		streamWriteUIntN(streamId, #self.disabledOptionIndices, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
		for _, v13_ in ipairs(self.disabledOptionIndices) do
			streamWriteUIntN(streamId, v13_, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
		end
		streamWriteBool(streamId, self.useFacialAnimation)
		streamWriteBool(streamId, self.isPhoneConversation)
	end
end

-- Local values: numIndices, i, index
function NPCConversationStartEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.npc = NetworkUtil.readNodeObject(streamId)
		self.playerNetworkId = NetworkUtil.readNodeObjectId(streamId)
		self.conversationIndex = streamReadUIntN(streamId, NPC.CONVERSATION_INDEX_SEND_NUM_BITS)
		self.conversationItemIndex = streamReadUIntN(streamId, NPC.CONVERSATION_ITEM_INDEX_SEND_NUM_BITS)
		self.disabledOptionIndices = {}
		for _ = 1, streamReadUIntN(streamId, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS) do
			local v17_ = streamReadUIntN(streamId, NPC.CONVERSATION_OPTION_INDEX_SEND_NUM_BITS)
			local v18_ = self.disabledOptionIndices
			table.insert(v18_, v17_)
		end
		self.useFacialAnimation = streamReadBool(streamId)
		self.isPhoneConversation = streamReadBool(streamId)
	end
	self:run(connection)
end

function NPCConversationStartEvent:run(connection)
	if self.npc ~= nil and connection:getIsServer() then
		self.npc:onConversationStarted(self.playerNetworkId, self.conversationIndex, self.useFacialAnimation, self.isPhoneConversation)
		self.npc:onConversationShowItem(self.conversationItemIndex, self.disabledOptionIndices)
	end
end
