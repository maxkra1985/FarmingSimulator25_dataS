-- Local values: ConversationPrerequisiteAllConversationsTriggeredByType_mt
ConversationPrerequisiteAllConversationsTriggeredByType = {}
ConversationPrerequisiteAllConversationsTriggeredByType.NAME = "conversationAllTriggeredByType"
local ConversationPrerequisiteAllConversationsTriggeredByType_mt = Class(ConversationPrerequisiteAllConversationsTriggeredByType)

function ConversationPrerequisiteAllConversationsTriggeredByType.registerXMLPaths(schema, basePath)
	NPCConversationType.registerXMLPath(schema, basePath .. "#type", "Type of the conversation", nil, true)
end

-- Upvalues: ConversationPrerequisiteAllConversationsTriggeredByType_mt
-- Local values: self
function ConversationPrerequisiteAllConversationsTriggeredByType.new(conversation, typeId, customMt)
	-- upvalues: (copy) ConversationPrerequisiteAllConversationsTriggeredByType_mt
	local v7_ = customMt or ConversationPrerequisiteAllConversationsTriggeredByType_mt
	local v8_ = setmetatable({}, v7_)
	v8_.conversation = conversation
	v8_.typeId = typeId
	return v8_
end

-- Local values: npc, conversation
function ConversationPrerequisiteAllConversationsTriggeredByType:getIsValid(player, userData)
	local v11_ = self.conversation:getNPC()
	if v11_ ~= nil then
		return v11_:getRandomConversation(player, self.typeId) == nil
	end
	Logging.error("ConversationPrerequisiteAllConversationsTriggeredByType.run: No NPC set!")
	return false
end

-- Local values: typeId
function ConversationPrerequisiteAllConversationsTriggeredByType.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v15_ = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#type")
	if v15_ ~= nil then
		return ConversationPrerequisiteAllConversationsTriggeredByType.new(conversation, v15_)
	end
	Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteAllConversationsTriggeredByType.NAME, ConversationPrerequisiteAllConversationsTriggeredByType)
