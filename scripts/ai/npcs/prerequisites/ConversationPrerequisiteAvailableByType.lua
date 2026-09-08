-- Local values: ConversationPrerequisiteAvailableByType_mt
ConversationPrerequisiteAvailableByType = {}
ConversationPrerequisiteAvailableByType.NAME = "conversationAvailableByType"
local ConversationPrerequisiteAvailableByType_mt = Class(ConversationPrerequisiteAvailableByType)

function ConversationPrerequisiteAvailableByType.registerXMLPaths(schema, basePath)
	NPCConversationType.registerXMLPath(schema, basePath .. "#type", "Type of the conversation", nil, true)
end

-- Upvalues: ConversationPrerequisiteAvailableByType_mt
-- Local values: self
function ConversationPrerequisiteAvailableByType.new(conversation, typeId, customMt)
	-- upvalues: (copy) ConversationPrerequisiteAvailableByType_mt
	local v7_ = customMt or ConversationPrerequisiteAvailableByType_mt
	local v8_ = setmetatable({}, v7_)
	v8_.conversation = conversation
	v8_.typeId = typeId
	return v8_
end

-- Local values: npc, conversation
function ConversationPrerequisiteAvailableByType:getIsValid(player, userData)
	local v11_ = self.conversation:getNPC()
	if v11_ ~= nil then
		return v11_:getRandomConversation(player, self.typeId) ~= nil
	end
	Logging.error("ConversationPrerequisiteAvailableByType.run: No NPC set!")
	return false
end

-- Local values: typeId
function ConversationPrerequisiteAvailableByType.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v15_ = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#type")
	if v15_ ~= nil then
		return ConversationPrerequisiteAvailableByType.new(conversation, v15_)
	end
	Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteAvailableByType.NAME, ConversationPrerequisiteAvailableByType)
