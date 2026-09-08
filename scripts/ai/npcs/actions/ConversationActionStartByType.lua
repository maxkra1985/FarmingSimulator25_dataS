-- Local values: ConversationActionStartByType_mt
ConversationActionStartByType = {}
ConversationActionStartByType.NAME = "startConversationByType"
local ConversationActionStartByType_mt = Class(ConversationActionStartByType)

function ConversationActionStartByType.registerXMLPaths(schema, basePath)
	NPCConversationType.registerXMLPath(schema, basePath .. "#type", "Type of the conversation", nil, true)
end

-- Upvalues: ConversationActionStartByType_mt
-- Local values: self
function ConversationActionStartByType.new(conversation, typeId, customMt)
	-- upvalues: (copy) ConversationActionStartByType_mt
	local v7_ = customMt or ConversationActionStartByType_mt
	local v8_ = setmetatable({}, v7_)
	v8_.conversation = conversation
	v8_.typeId = typeId
	return v8_
end

-- Local values: npc, player, conversation
function ConversationActionStartByType:run()
	if g_server == nil then
		return true
	end
	local v10_ = self.conversation:getNPC()
	if v10_ == nil then
		Logging.error("ConversationActionStartByType.run: No NPC set!")
		return false
	end
	local v11_ = v10_:getInteractingPlayer()
	if v11_ == nil then
		Logging.error("ConversationActionStartByType.run: No player set!")
		return false
	end
	local v12_ = v10_:getRandomConversation(v11_, self.typeId)
	if v12_ == nil then
		return false
	end
	v10_:setFollowUpConversation(v12_)
	return true
end

-- Local values: typeId
function ConversationActionStartByType.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v16_ = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#type")
	if v16_ ~= nil then
		return ConversationActionStartByType.new(conversation, v16_)
	end
	Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationActionClass(ConversationActionStartByType.NAME, ConversationActionStartByType)
