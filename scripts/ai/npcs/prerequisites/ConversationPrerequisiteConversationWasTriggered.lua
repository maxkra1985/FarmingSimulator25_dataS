-- Local values: ConversationPrerequisiteConversationWasTriggered_mt
ConversationPrerequisiteConversationWasTriggered = {}
ConversationPrerequisiteConversationWasTriggered.NAME = "conversationWasTriggered"
local ConversationPrerequisiteConversationWasTriggered_mt = Class(ConversationPrerequisiteConversationWasTriggered)

function ConversationPrerequisiteConversationWasTriggered.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#uniqueId", "Unique id of the conversation that has to be triggered before", nil, true)
end

-- Upvalues: ConversationPrerequisiteConversationWasTriggered_mt
-- Local values: self
function ConversationPrerequisiteConversationWasTriggered.new(conversation, uniqueId, customMt)
	-- upvalues: (copy) ConversationPrerequisiteConversationWasTriggered_mt
	local v7_ = customMt or ConversationPrerequisiteConversationWasTriggered_mt
	local v8_ = setmetatable({}, v7_)
	v8_.conversation = conversation
	v8_.uniqueId = uniqueId
	return v8_
end

-- Local values: npc, conversation
function ConversationPrerequisiteConversationWasTriggered:getIsValid(player, userData)
	local v11_ = self.conversation:getNPC()
	if v11_ == nil then
		Logging.error("ConversationPrerequisiteConversationWasTriggered.run: No NPC set!")
		return false
	end
	if v11_:getConversationById(self.uniqueId) ~= nil then
		return v11_:getWasConversationTriggered(player, self.uniqueId)
	end
	Logging.error("ConversationPrerequisiteConversationWasTriggered.run: No conversation with unique id \'%s\' defined for npc \'%s\'!", self.uniqueId, v11_:getName())
	return false
end

-- Local values: uniqueId
function ConversationPrerequisiteConversationWasTriggered.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local v15_ = xmlFile:getValue(key .. "#uniqueId")
	if v15_ ~= nil then
		return ConversationPrerequisiteConversationWasTriggered.new(conversation, v15_)
	end
	Logging.xmlWarning(xmlFile, "Missing \'uniqueId\' for \'%s\'", key)
	return nil
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteConversationWasTriggered.NAME, ConversationPrerequisiteConversationWasTriggered)
