-- Local values: ConversationActionResetTriggeredByType_mt
ConversationActionResetTriggeredByType = {}
ConversationActionResetTriggeredByType.NAME = "resetNumTriggeredByType"
local ConversationActionResetTriggeredByType_mt = Class(ConversationActionResetTriggeredByType)

function ConversationActionResetTriggeredByType.registerXMLPaths(schema, basePath)
	NPCConversationType.registerXMLPath(schema, basePath .. "#type", "Type of the conversation", nil, true)
end

-- Upvalues: ConversationActionResetTriggeredByType_mt
-- Local values: self
function ConversationActionResetTriggeredByType.new(conversation, typeId, customMt)
	-- upvalues: (copy) ConversationActionResetTriggeredByType_mt
	local v7_ = customMt or ConversationActionResetTriggeredByType_mt
	local v8_ = setmetatable({}, v7_)
	v8_.conversation = conversation
	v8_.typeId = typeId
	return v8_
end

-- Local values: npc, player
function ConversationActionResetTriggeredByType:run()
	if g_server == nil then
		return true
	else
		local v10_ = self.conversation:getNPC()
		if v10_ == nil then
			Logging.error("ConversationActionResetTriggeredByType.run: No NPC set!")
			return false
		else
			v10_:resetConversationNumTriggeredByType(v10_:getInteractingPlayer(), self.typeId)
			return true
		end
	end
end

-- Local values: typeId
function ConversationActionResetTriggeredByType.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v14_ = NPCConversationType.loadFromXMLFile(xmlFile, key .. "#type")
	if v14_ ~= nil then
		return ConversationActionResetTriggeredByType.new(conversation, v14_)
	end
	Logging.xmlWarning(xmlFile, "NPCConversationType not defined for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationActionClass(ConversationActionResetTriggeredByType.NAME, ConversationActionResetTriggeredByType)
