ConversationPrerequisiteConversationWasTriggered = {}
ConversationPrerequisiteConversationWasTriggered.NAME = "conversationWasTriggered"
local ConversationPrerequisiteConversationWasTriggered_mt = Class(ConversationPrerequisiteConversationWasTriggered)
function ConversationPrerequisiteConversationWasTriggered.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#uniqueId", "Unique id of the conversation that has to be triggered before", nil, true)
end
function ConversationPrerequisiteConversationWasTriggered.new(conversation, uniqueId, customMt)
	local self = setmetatable({}, customMt or ConversationPrerequisiteConversationWasTriggered_mt)
	self.conversation = conversation
	self.uniqueId = uniqueId
	return self
end
function ConversationPrerequisiteConversationWasTriggered:getIsValid(player, userData)
	local npc = self.conversation:getNPC()
	if npc == nil then
		Logging.error("ConversationPrerequisiteConversationWasTriggered.run: No NPC set!")
		return false
	end
	local conversation = npc:getConversationById(self.uniqueId)
	if conversation == nil then
		Logging.error("ConversationPrerequisiteConversationWasTriggered.run: No conversation with unique id '%s' defined for npc '%s'!", self.uniqueId, npc:getName())
		return false
	else
		return npc:getWasConversationTriggered(player, self.uniqueId)
	end
end
function ConversationPrerequisiteConversationWasTriggered.createFromXML(xmlFile, key, conversation, baseDirectory, customEnvironment)
	local uniqueId = xmlFile:getValue(key .. "#uniqueId")
	if uniqueId == nil then
		Logging.xmlWarning(xmlFile, "Missing 'uniqueId' for '%s'", key)
		return nil
	else
		return ConversationPrerequisiteConversationWasTriggered.new(conversation, uniqueId)
	end
end
g_npcManager:registerConversationPrerequisiteClass(ConversationPrerequisiteConversationWasTriggered.NAME, ConversationPrerequisiteConversationWasTriggered)
